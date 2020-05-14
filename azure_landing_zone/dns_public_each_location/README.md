---
page_title: "Terraform :: Modules :: Azure :: dns_public_each_location"
tags:
  - Terraform
  - tf_modules
  - DNS
  - Public Zone
---
# dns_public_each_location

Deploys one Azure DNS Public Zone with the FQDN `{{zone_name}}.{{namespace}}.{{zone_suffix}}` into the Resource Group `zone_rg`. Then, deploys Azure DNS Public Zones `{{location}}.{{zone_name}}.{{namespace}}.{{zone_suffix}}` into each corresponding Resource Group defined by the `region_map_rgs[key]`, where `key` corresponds to the region of each Resource Group. Subsequently, creates NS records in the main Public Zone pointing to NS IPs for each of the regional subdomains deployed.

## Example Usage

```hcl
module "dns_zone_public" {
  source = "github.com/undp/tf-modules//azure_landing_zone/dns_public_each_location?ref=v0.1.0"

  zone_rg = "bootstrap"

  region_map_rgs = {
    westeurope  = "rg1"
    northeurope = "rg2"
  }

  zone_suffix = "space.link"

  zone_name = "base"

  namespace = "deep"

  tags = {
    "BU"    = "Enterprise"
    "Owner" = "Security"
  }
}
```

## Input variables

The following arguments are supported:

* `zone_rg` - (Required) RG name to deploy the main Public Zone.

* `region_map_rgs` - (Required) Map of locations to RG names where regional subdomains of the main Public Zone are deployed.

* `zone_suffix` - (Required) Suffix for the Public Zone FQDN.

* `zone_name` - (Optional) Zone name used before the `namespace` in the Public Zone FQDN.

* `namespace` - (Optional) Namespace used before the `zone_suffix` in the Public Zone FQDN.

* `tags` - (Optional) Tags to be assigned to each deployed resource.

## Output variables

The following attributes are exported:

* `zone_main_fqdn` - FQDN for the main Public Zone deployed.

* `zone_main_ns_list` - List of NS IPs for the Public Zone deployed.

* `zone_main_map` - Map of the Public Zone FQDN into the list of NS IPs for it.

* `zone_sub_fqdn_list` - List of FQDNs for all regional subdomains of the main Public Zone deployed.

* `zone_sub_map` - Map of FQDNs for all regional subdomains into the list of NS IPs for each.

* `zone_main_obj` - Complete object for the Public Zone deployed.

* `zone_sub_obj_list` - List of complete objects for all regional subdomains of the main Public Zone deployed.
