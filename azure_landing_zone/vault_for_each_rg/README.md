---
page_title: "Terraform :: Modules :: Azure :: vault_for_each_rg"
tags:
  - Terraform
  - tf_modules
  - Key Vault
---
# vault_for_each_rg

Deploys a set of Key Vault resources into each corresponding regional Resource Group (RG) specified by the values of the `region_rg_map`. Also, deploys a set of user assigned identities into the same RG with Key Vault. One identity (`admin`) is assigned full access to all operations in the Key Vault, while the other (`reader`) has a read-only access. Also an additional access policy is created in each deployed Key Vault for the credentials used by the module for the `AzureRM` provider. This allows to use the same credentials later to import certificates, secrets, etc into deployed Key Vaults as part of the common CI/CD pipeline.

## Example Usage

```hcl
module "key_vaults" {
  source = "github.com/undp/tf-modules//azure_landing_zone/vault_for_each_rg?ref=develop"

  region_rg_map = {
    eastus        = "rg1"
    canadacentral = "rg2"
  }

  conf_module = {
    # placeholder for future development
  }

  conf_common = {
    sku_name = "premium"
    soft_delete_enabled = true
  }

  conf_map = {
    eastus  = {
      name = "prod"
      acls_bypass = "None"
    }
    canadacentral = {
      name = "dev"
      acls_bypass = "AzureServices"
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

> **NOTE:** No module-wide options. Parameter is a placeholder for future development.

### Resource Options

Resource options are defined by either parameters in the `conf_common` map for all regions at once, or by `conf_map` for each region individually. Common parameters from `conf_common` get precedence over region-specific ones from `conf_map`. If no parameter is provided in any of the two, default value is assigned.

  > **IMPORTANT!** Keys for `region_rg_map` and `conf_map` must match.

Both `conf_common` and `conf_map` parameters support the following options:

* `acls_bypass` - (Optional) Specifies which traffic can bypass the network rules. Possible values are `AzureServices` and `None`. If unspecified, module uses `None` as a default.

* `acls_default_action` - (Optional) The Default Action to use when no rules match from `acls_ip_rules` / `acls_subnet_ids`. Possible values are `Allow` and `Deny`. If unspecified, module uses `Deny` as a default.

* `acls_ip_rules` - (Optional) One or more IP Addresses, or CIDR Blocks which should be able to access the Key Vault. If unspecified, module uses `null` as a value.

* `acls_subnet_ids` - (Optional) One or more Subnet ID's which should be able to access this Key Vault. If unspecified, module uses `null` as a value.

* `enabled_for_deployment` - (Optional) Boolean flag to specify whether VMs are permitted to retrieve certificates stored as secrets from the Key Vault. If unspecified, module uses `false` as a default.

* `enabled_for_disk_encryption` - (Optional) Boolean flag to specify whether Azure Disk Encryption is permitted to retrieve secrets from the vault and unwrap keys. If unspecified, module uses `false` as a default.

* `enabled_for_template_deployment` - (Optional) Boolean flag to specify whether Azure Resource Manager is permitted to retrieve secrets from the Key Vault. If unspecified, module uses `false` as a default.

* `name` - (Required) Constant part of a resource name. Module generates regional resource names following the template `{{prefix}}_{{resource_name}}_{{location}}_{{suffix}}` with the substitutions below:

  * `{{prefix}}` is the value of `namespace`, if defined. Otherwise, `{{prefix}}` is dropped from the name.

  * `{{resource_name}}` is the value of `conf_common.name`, if defined. Otherwise, `conf_map[*].name` for each regional resource. If `conf_map[*].name` parameter does not exist for some keys, `{{resource_name}}` is dropped from the name.

  * `{{location}}` is the keys of `region_rg_map`.

  * `{{suffix}}` is defined based on the type of the resource and follows this mapping:

    * **no suffix** for the Azure Key Vault due to the limitations below.

      > **IMPORTANT!**  Because the URL to access a Key Vault contains the `name` parameter (e.g. `https://{{name}}.vault.azure.net/`), following limitations apply to the parameter and the way it is used in generated Key Vault names. It may only contain alphanumeric characters and dashes and must be between 3-24 chars. Thus, naming convention for Key Vault resource uses `-` in place of `_` and does not have `{{suffix}}` (e.g. `{{prefix}}-{{resource_name}}-{{location}}`). Also, be careful for the full name not to exceed 24 chars or Terraform would throw an error during `plan` action.

    * `admin_uai` for user assigned identity with  `admin` access to the Key Vault

    * `reader_uai` for user assigned identity with  `read-only` access to the Key Vault

* `purge_protection_enabled` - (Optional) Is Purge Protection enabled for this Key Vault? If unspecified, module uses `false` as a default.

  > **NOTE:** Once Purge Protection has been Enabled it's not possible to Disable it. Deleting the Key Vault with Purge Protection Enabled is also problematic. Azure will schedule the Key Vault to be deleted in 90 days.

* `sku_name` - (Required) The Name of the SKU used for this Key Vault. Possible values are `standard` and `premium`. If unspecified, module uses `standard` as a default.

* `soft_delete_enabled` - (Optional) Should Soft Delete be enabled for this Key Vault? If unspecified, module uses `false` as a default.

  > **NOTE:** Once Soft Delete has been Enabled it's not possible to Disable it.

* `tenant_id` - (Required) The Azure Active Directory tenant ID that should be used for authenticating requests to the Key Vault.  If unspecified, module uses tenant ID available in the current Terraform configuration (e.g. ARM_TENANT_ID env var).

## Output variables

The following attributes are exported:

* `vault_id_map` - Map of Key Vault IDs to corresponding name and resource group.

* `vault_obj_map` - Map of `region_rg_map.key` to all Key Vault properties.

* `admin_uai_id_map` - Map of `admin` user assigned identity IDs to corresponding name and resource group.

* `admin_uai_obj_map` - Map of `region_rg_map.key` to `admin` user assigned identity properties.

* `reader_uai_id_map` - Map of `reader` user assigned identity IDs to corresponding name and resource group.

* `reader_uai_obj_map` - Map of `region_rg_map.key` to `reader` user assigned identity properties.
