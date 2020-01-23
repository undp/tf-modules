---
page_title: "Terraform :: Modules :: Azure :: nsg_for_each_vnet"
tags:
  - Terraform
  - tf_modules
  - NSG
  - Network Security Group
---
# nsg_for_each_vnet

 In each `nsg_rg_map[key]` Resource Group, module creates one Network Security Groups named `{{namespace}}_{{vnet_map.key}}_nsg`.

> Note: Module expects `vnet_map.key` to match the Virtual Network name of the following format `{{namespace}}_{{vnet_map.key}}_vnet`

Associates each deployed Network Security Group with all the subnets of the corresponding Virtual Network identified by the `vnet_map[key].vnet_rg_name`.

> Note: Resource Groups and Virtual Networks are imported as `data` and thus, MUST exist prior to invocation of this module.

## Example Usage

```hcl
module "vnets_peered" {
  source = "github.com/undp/tf-modules//azure_landing_zone/nsg_for_each_vnet?ref=v0.1.0"

  nsg_rg_map = {
    westeurope  = "security_A"
    northeurope = "security_B"
  }

  vnet_map  = {
    vnet_name_A = {
      vnet_rg_name = "rg1"
    }
    vnet_name_B = {
      vnet_rg_name = "rg2"
    }
  }

  namespace = "deep"

  tags = {
    "BU"    = "Enterprise"
    "Owner" = "Security"
  }
}
```

## Input variables

The following arguments are supported:

* `nsg_rg_map` - (Required) Map of locations to RG names where VNETs are deployed for each region.

* `vnet_map` - (Required) Map of VNET name keys to configuration parameters for NSG.

* `namespace` - (Optional) Namespace to use as a prefix in resource names and in tags.

* `tags` - (Optional) Tags to be assigned to each deployed resource.

## Output variables

The following attributes are exported:

* `nsg_names` - List of created NSG names.

* `nsg_ids` - List of created NSG ids.

* `nsg_map` - Map of input `vnet_map.key` to NSG properties.
