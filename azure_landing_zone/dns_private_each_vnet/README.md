---
page_title: "Terraform :: Modules :: Azure :: dns_private_each_vnet"
tags:
  - WIP
  - Terraform
  - tf_modules
  - DNS
  - Private DNS Zone
---
# dns_private_each_vnet

Deploys unique Private DNS Zone named `{{local_vnet_prefix}}.{{zone_name}}.{{namespace}}` into each Resource Group `vnet_map[key].vnet_rg_name` and links the zone with the corresponding Virtual Network `vnet_map.key`. Auto-registration of DNS records for VMs deployed within the linked VNETs is enabled. Name prefix `{{local_vnet_prefix}}` is calculated from `vnet_map.key` value by splitting it along the `_(underscore)`, reversing order and joining with the `.(dot)`.

> Note: Module expects `vnet_map.key` to match the Virtual Network name of the following format `{{namespace}}_{{vnet_map.key}}_vnet`.

## Example Usage

```hcl
module "dns_zones_private" {
  source = "./modules/dns_private_each_vnet"

  vnet_map  = {
    vnet_name_A = {
      vnet_rg_name = "rg1"
    }
    vnet_name_B = {
      vnet_rg_name = "rg2"
    }
  }

  zone_name = "space"

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

* `zone_name` - (Required) Domain name for the Private DNS Zone.

* `namespace` - (Optional) Namespace to use as a prefix in resource names and in tags.

* `tags` - (Optional) Tags to be assigned to each deployed resource.

## Output variables

The following attributes are exported:

* `private_dns_zones` - List of private DNS zones deployed.
