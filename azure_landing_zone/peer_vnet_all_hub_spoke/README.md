---
page_title: "Terraform :: Modules :: Azure :: peer_vnet_all_hub_spoke"
tags:
  - Terraform
  - tf_modules
  - VNET
  - Virtual Network
  - Hub-Spoke Peering
  - Peering
---
# peer_vnet_all_hub_spoke

Establishes forward peering named `{{namespace}}_{{vnet_hub_A}}_to_{{vnet_spoke_B}}_peering` and reverse peering named `{{namespace}}_{{vnet_spoke_B}}_to_{{vnet_hub_A}}_peering` between each HUB Virtual Network defined by the `vnet_map_hub.key` and all SPOKE Virtual Networks defined by the `vnet_map_spoke.key` located in the same region with the HUB. Effectively, builds a multi-layer HUB-SPOKE topology. Module expects there is at least one hub for N spokes in the region.

> Note: Module expects `vnet_map_[hub|spoke].key` to match the Virtual Network names of the following format `{{namespace}}_{{vnet_map_[hub|spoke].key}}_vnet`. Virtual Networks are imported as `data` and thus, MUST exist prior to invocation of this module.

## Example Usage

```hcl
module "vnets_peered" {
  source = "./modules/peer_vnet_all_hub_spoke"

  vnet_map_hub = {
    vnet_hub_A = {
      vnet_rg_name = "rg1"
    }
    vnet_hub_B = {
      vnet_rg_name = "rg2"
    }
  }

  vnet_map_spoke = {
    vnet_spoke_A = {
      vnet_rg_name = "rg1"
    }
    vnet_spoke_B = {
      vnet_rg_name = "rg2"
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

* `vnet_map_hub` - (Required) Map of hub VNET names to RG names.

* `vnet_map_spoke` - (Required) Map of spoke VNET names to RG names.

* `namespace` - (Optional) Namespace to use as a prefix in resource names and in tags.

* `tags` - (Optional) Tags to be assigned to each deployed resource.

## Output variables

The following attributes are exported:

* `peering_names` - List of VNET peering names.

* `peering_ids` - List of VNET peering ids.
