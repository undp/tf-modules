---
page_title: "Terraform :: Modules :: Azure :: peer_vnet_pair_one_way"
tags:
  - Terraform
  - tf_modules
  - VNET
  - Virtual Network
  - 1-to-1 Peering
  - Peering
---
# peer_vnet_pair_one_way

Establishes a one-way peering between all pairs of Virtual Networks from `vnet_map_src` to `vnet_map_dst` with matching keys and names peering objects as `{{namespace}}_{{name_prefix_src}}_to_{{name_prefix_dst}}_{{key}}_peering`.

> Note: Module expects `vnet_map_src.key` to match the Virtual Network names of the format `{{namespace}}_{{key}}_vnet` and `vnet_map_dst.key` to match `{{namespace}}_{{key}}_vnet`. Virtual Networks are imported as `data` and thus, MUST exist prior to invocation of this module.

## Example Usage

```hcl
module "vnets_peered" {
  source = "./modules/peer_vnet_pair_one_way"

  vnet_map_src  = {
    key_A = {
      vnet_rg_name  = "A_1_rg"
    }
    key_B = {
      vnet_rg_name  = "B_1_rg"
    }
  }

  vnet_map_dst  = {
    key_A = {
      vnet_rg_name  = "A_2_rg"
    }
    key_B = {
      vnet_rg_name  = "B_2_rg"
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

* `vnet_map_src` - (Required) Map of src VNET names to establish peering from into RGs containing those VNETs.

* `vnet_map_dst` - (Required) Map of dst VNET names to establish peering to into RGs containing those VNETs.

* `namespace` - (Optional) Namespace to use as a prefix in resource names and in tags.

* `tags` - (Optional) Tags to be assigned to each deployed resource.

## Output variables

The following attributes are exported:

* `peering_names` - List of VNET peering names.

* `peering_ids` - List of VNET peering ids.
