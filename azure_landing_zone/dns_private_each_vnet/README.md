---
page_title: "Terraform :: Modules :: Azure :: dns_private_each_vnet"
tags:
  - Terraform
  - tf_modules
  - DNS
  - Private Zone
---
# dns_private_each_vnet

Deploys unique Azure DNS Private Zone named `{{local_vnet_prefix}}.{{zone_name}}.{{namespace}}.{{zone_suffix}}` into each Resource Group `vnet_map[key].vnet_rg_name` and links the zone with the corresponding Virtual Network `vnet_map.key`. Auto-registration of DNS records for VMs deployed within the linked VNETs is enabled if `registration_enabled` is `true` (default: `false`). Name prefix `{{local_vnet_prefix}}` is calculated from `vnet_map.key` value by splitting it along the `_(underscore)`, reversing order and joining with the `.(dot)`.

> Note: Module expects `vnet_map.key` to match the Virtual Network name of the following format `{{namespace}}_{{vnet_map.key}}_vnet`.

## Example Usage

```hcl
module "dns_zones_private" {
  source = "github.com/undp/tf-modules//azure_landing_zone/dns_private_each_vnet?ref=v0.1.0"

  vnet_map  = {
    vnet_name_A = {
      vnet_rg_name = "rg1"
    }
    vnet_name_B = {
      vnet_rg_name = "rg2"
    }
  }

  zone_suffix = "space.link"

  zone_name = "base"

  registration_enabled = true

  namespace = "deep"

  tags = {
    "BU"    = "Enterprise"
    "Owner" = "Security"
  }
}
```

## Input variables

The following arguments are supported:

* `vnet_map` - (Required) Map of VNET name keys to configuration parameters for NSG.

* `zone_suffix` - (Required) Suffix for the Private Zone FQDN.

* `zone_name` - (Optional) Zone name used before the `namespace` in the Private Zone FQDN.

* `registration_enabled` - (Optional) Is auto-registration of virtual machine records in the virtual network in the Private DNS zone enabled? Defaults to `false`.

* `namespace` - (Optional) Namespace used before the `zone_suffix` in the Private Zone FQDN.

* `tags` - (Optional) Tags to be assigned to each deployed resource.

## Output variables

The following attributes are exported:

* `private_dns_zones` - List of private DNS zones deployed.
