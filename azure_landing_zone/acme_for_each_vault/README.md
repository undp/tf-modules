---
page_title: "Terraform :: Modules :: Azure :: acme_for_each_vault"
tags:
  - Terraform
  - tf_modules
  - ACME
  - Let's Encrypt
---
# acme_for_each_vault

Module registers single `ACME` account that is used in all interactions with Let's Encrypt. Then it obtains certificates over `ACME` protocol from Let's Encrypt and saves those into each corresponding Key Vault present in the regional Resource Group (RG) specified by the values of the `region_rg_map`.

  > **IMPORTANT!** Private key for the `ACME` account will be stored in the `Terraform` state. You must ensure access to state storage is adequately controlled.

Module configures `ACME` provider to perform `DNS-01` verification against Azure DNS zones for certificate FQDNs. It assumes that runtime environment has a Service Pricipal configured through the following ENV variables

* `ARM_CLIENT_ID` - Azure Client ID of the Service Principal used by `Terraform`
* `ARM_CLIENT_SECRET` - Azure Client secret of the Service Principal used by `Terraform`
* `ARM_TENANT_ID` - Azure Tenant ID of the Service Principal used by `Terraform`
* `ARM_SUBSCRIPTION_ID` - Azure Subscription of the Service Principal used by `Terraform`

> **NOTE:** Service Principal must have correct permissions assigned to allow `ACME` provider to temporary modify Azure DNS zones that correspond to `Common Name` and `Subject Alternative Names` of each certificate.

## Example Usage

```hcl
module "acme_certs" {
  source = "github.com/undp/tf-modules//azure_landing_zone/acme_for_each_vault?ref=develop"

  region_rg_map = {
    eastus        = "rg1"
    canadacentral = "rg2"
  }

  conf_module = {
    account_email = "foo@bar.com"
    enable_staging_api = true
  }

  conf_common = {
    key_type = 4096

    kv_name = "kv"

    zone_name = "base"

    zone_suffix = "space.link"

    zone_rg_name = "dns"
  }

  conf_map = {
    eastus  = {
      certs = {
        VPN = {
          common_name = "vpn",
          subject_alternative_names = [
            "vm0.vpn",
            "vm1.vpn",
            "vm2.vpn",
          ]
        }
      }
    }
    canadacentral = {
      certs = {
        WEB-APPS = {
          common_name = "*.web-apps",
          subject_alternative_names = [
            "vm0.web-apps",
            "vm1.web-apps",
            "vm2.web-apps",
          ]
      }
    }
  }

  namespace = "deep"

  tags = {
    BU    = "Enterprise"
    Owner = "Security"
  }
}
```

## Input variables

The following module arguments are supported:

* `region_rg_map` - Map of locations to RG names where resources are deployed for each region.

* `conf_module` - Map of parameters defining module-wide functionality.

* `conf_common` - Common configuration parameters applied to all regions.

* `conf_map` - (Optional) Map of locations to region-specific configuration parameters applied to each individual region.

* `namespace` - (Optional) Namespace to use as a prefix in resource names and in tags.

* `tags` - (Optional) Tags to be assigned to each deployed resource.

## Configuration Parameters

### Module Functionality

A `conf_module` parameter aggregate module-wide feature flags and supports the following options:

* `account_email` - (Required) - The contact email address for the ACME account.

* `enable_staging_api` - (Optional) If enabled, uses staging Let's Encrypt endpoint instead of production. If unspecified, module uses `false` as a default.

  > **NOTE:** If you deployed module with some value (e.g. `true` for testing) of this parameter and then want to change it to an opposite one (e.g. `false` for production certs), `apply` operation would fail because your plan would use Let's Encrypt API endpoint (URL) that corresponds to new parameter value to revoke old certificates registered with API endpoint (URL) that corresponds to the old parameter value. Perform `destroy` operation with the old value first, then re-deploy module with the new value.

* `enable_exec_dns_challenge` - (Optional) If enabled, module uses an external executable to publish all ACME challenges for corresponding domain names used in certificates. This allows to rely on DNS providers other than Azure DNS. If unspecified, module uses `false` as a default resulting in `azure` DNS challenge provider being used for ACME.

  > **NOTE:** This approach also allows to dedicate a single DNS zone for all ACME challenges. This approach improves security, since access credentials for automated changes could be scoped only to a single DNS zone instead of all possible zones used in certificates. The downside is that this requires a pre-configured `CNAME` to point `_acme-challenge` for all FQDNs used in certificates to such dedicated zone. Specifically, if `tls.your.org` is dedicated for ACME challenges and certificate is generated for `foo.bar.net`, a `CNAME` for `_acme-challenge.foo.bar.net` pointing to `_acme-challenge.foo.bar.net.tls.your.org` would be required.

* `enable_common_certs` - (Optional) If enabled, instead of generating regional certificates, module generates a set of common certificates that are replicated across all regional Key Vaults. If unspecified, module uses `false` as a default.

  > **NOTE:** This parameter sets `enable_fqdn_target` and `enable_full_rg_name` to `true` and makes the module to utilize cert settings only from `conf_common` parameter map.

* `enable_fqdn_target` - (Optional) If enabled, treats strings from `certs` parameter as FQDNs and uses them as-is for `Common Name` and `Subject Alternative Names` fields of corresponding certificate. Otherwise, follows the convention of `{{target}}.{{location}}.{{zone_name}}.{{namespace}}.{{zone_suffix}}` where the `{{target}}` portion is defined by the strings corresponding `certs` parameter. If unspecified, module uses `false` as a default.

* `enable_full_rg_name` - (Optional) If enabled, treats the value from `zone_rg_name` parameter as a full Resource Group name and uses it as-is bypassing standard name convention expansion.

### Resource Options

Resource options are defined by either parameters in the `conf_common` map for all regions at once, or by `conf_map` for each region individually. Common parameters from `conf_common` get precedence over region-specific ones from `conf_map`. If no parameter is provided in any of the two, default value is assigned.

  > **IMPORTANT!** Keys for `region_rg_map` and `conf_map` must match.

Both `conf_common` and `conf_map` parameters support the following options:

* `acme_challenge_script` - (Optional) An executable to be called during `DNS-01` verification to publish all ACME challenges for corresponding domain names used in certificates. The executable is passed the string of parameters `<ACTION> <FQDN> <TOKEN>` where:
  * `<ACTION>` - either `present` to publish challenge token or `cleanup` to remove it
  * `<FQDN>` - FQDN for which `DNS-01` verification is being executed
  * `<TOKEN>` - challenge token value to be published

  > **NOTE:** This option is only used if `enable_exec_dns_challenge` is `true`.

* `certs` - (Required) Map of certificate IDs (used to name corresponding records in the Key Vault) to nested dictionary structure describing parameters for each certificate. All, but `common_name` and `subject_alternative_names` parameters could also be defined in `conf_common` making them common for all certificates. These parameters include the following:
  * `common_name` - (Required) The certificate's common name, the primary domain that the certificate will be recognized for.

    > **NOTE:** If feature flag `enable_fqdn_target` is `true`, FQDN for this parameter is generated following the template `{{target}}.{{location}}.{{zone_name}}.{{namespace}}.{{zone_suffix}}` where `{{target}}` is defined by parameter's value and `{{location}}` is defined with `region_rg_map` keys.

  * `subject_alternative_names` - (Required) The certificate's subject alternative names, domains that this certificate will also be recognized for.

    > **NOTE:** If feature flag `enable_fqdn_target` is `true`, FQDNs for this parameter are generated following the template `{{target}}.{{location}}.{{zone_name}}.{{namespace}}.{{zone_suffix}}` where `{{target}}` is defined by parameter's values and `{{location}}` is defined with `region_rg_map` keys.

  * `cert_password` - (Optional) Password to be used when generating the PFX file stored in `certificate_p12`. If unspecified, module uses `null` as a default.

  * `key_type` - (Optional) The key type for the certificate's private key. Accepted values are `2048`, `4096`, and `8192` (for `RSA` keys of respective length). If unspecified, module uses `4096` as a default.

    > **NOTE:** Original option for `acme_certificate` resource also accepts `P256` and `P384` for `ECDSA` keys of respective length. However, the module uses this parameter also in `key_properties.key_size` of the `azurerm_key_vault_certificate` resource and assumes keys are only of type `RSA`.

  * `min_days_remaining` - (Optional) - The minimum amount of days remaining on the expiration of a certificate before a renewal is attempted. A value of less than `0` means that the certificate will never be renewed. If unspecified, module uses `30` as a default.

  * `must_staple` - (Optional) Enables the OCSP Stapling Required TLS Security Policy extension. Certificates with this extension must include a valid OCSP Staple in the TLS handshake for the connection to succeed. If unspecified, module uses `false` as a default.

    > **NOTE:** Option has no effect when using an external CSR, it must be enabled in the CSR itself.

  * `recursive_nameservers` - (Optional) A list of recursive nameservers that will be used to check for propagation of the challenge record. If unspecified, module uses system-configured DNS resolvers of the runtime environment.

* `kv_name` - (Required) Constant part of the Key Vault name. Module expects Key Vault names to follow the template `{{prefix}}-{{resource_name}}-{{location}}` with the following substitutions:

  * `{{prefix}}` is the value of `namespace`, if defined. Otherwise, `{{prefix}}` is dropped from the name.

  * `{{resource_name}}` is the value of `kv_name`.

  * `{{location}}` is the keys of `region_rg_map`.

* `zone_name` - (Optional) Zone name used before the `namespace` in the certificate FQDNs (`{{target}}.{{location}}.{{zone_name}}.{{namespace}}.{{zone_suffix}}`). If unspecified, module uses empty string as a default, effectively dropping it from the FQDN template.

* `zone_suffix` - (Required) Suffix for the certificate FQDNs (`{{target}}.{{location}}.{{zone_name}}.{{namespace}}.{{zone_suffix}}`).

* `zone_rg_name` - (Required) Constant part of the Resource Group name containing DNS Public Zones referenced in domains for certificates to be issues. Module expects RG names to follow the standard name convention template `{{prefix}}_{{name}}_{{location}}` with the following substitutions:

  * `{{prefix}}` is the value of `namespace`, if defined. Otherwise, `{{prefix}}` is dropped from the name.

  * `{{name}}` is the value of `zone_rg`.

  * `{{location}}` is the keys of `region_rg_map`.

  > **NOTE:** If `enable_full_rg_name` is `true`, module bypasses the standard name convention expansion. Instead, it treats the value from this parameter as a full name and uses it as-is.

## Output variables

The following attributes are exported:

* `cert_name_map` - Map of cert names to corresponding KeyVault IDs and Secret IDs.

* `cert_name_map_ver` - Map of cert names to corresponding KeyVault IDs and Secret IDs (with specific version included in the ID).
