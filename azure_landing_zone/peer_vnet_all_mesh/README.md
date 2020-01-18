---
page_title: "Terraform :: Modules :: Azure :: peer_vnet_all_mesh"
tags:
  - Terraform
  - tf_modules
  - VNET
  - Virtual Network
  - Mesh Peering
  - Peering
---
# peer_vnet_all_mesh

Establishes a peering named as `{{namespace}}_{{vnet_name_A}}_to_{{vnet_name_B}}_peering` between all pairs of Virtual Networks defined by the `vnet_map.key` name and `vnet_map[key].vnet_rg_name` Resource Group. Effectively, builds a meshed peering between all the Virtual Networks in the `vnet_map`.

> Note: Module expects `vnet_map.key` to match the Virtual Network name of the following format `{{namespace}}_{{vnet_map.key}}_vnet`. Virtual Networks are imported as `data` and thus, MUST exist prior to invocation of this module.

## Example Usage

```hcl
module "vnets_peered" {
  source = "./modules/peer_vnet_all_mesh"

  vnet_map  = {
    vnet_name_A = {
      vnet_rg_name  = "rg1"
    }
    vnet_name_B = {
      vnet_rg_name  = "rg2"
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

The following arguments are supported:

* `vnet_map` - (Required) Map of VNET names to RG names.

* `namespace` - (Optional) Namespace to use as a prefix in resource names and in tags.

* `tags` - (Optional) Tags to be assigned to each deployed resource.

## Output variables

The following attributes are exported:

* `peering_names` - List of VNET peering names.

* `peering_ids` - List of VNET peering ids.
