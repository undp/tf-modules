---
page_title: "Terraform :: Modules :: Azure :: multi_vnets"
tags:
  - Terraform
  - tf_modules
  - VNET
  - Virtual Network
---
# multi_vnets

Deploys VNETs specified by `region_map_vnets[key]` map into each corresponding Resource Group defined by the `region_map_rgs[key]` using subnet definitions in `common_subnets`.

## Example Usage

```hcl
module "vnets_peered" {
  source = "./modules/multi_vnets"

  region_map_rgs = {
    westeurope  = "rg1"
    northeurope = "rg2"
  }

  region_map_vnets = {
    westeurope = {
      vnet_prod = "10.1.0.0/24"
      vnet_test = "10.1.1.0/24"
    }
    northeurope = {
      vnet_prod = "10.2.0.0/24"
      vnet_test = "10.2.1.0/24"
    }
  }

  common_subnets = {
    dmz = {
      bits          = 1
      index         = 0
      svc_endpoints = []
    }
    workloads = {
      bits          = 1
      index         = 1
      svc_endpoints = []
    }
  }

  common_nsg_rules = [
    {
      name                  = "DENY_ANY_TO_QUARANTINE"
      priority              = 100
      access                = "Deny"
      direction             = "Inbound"
      source_address_prefix = "*"
      destination_asg       = "quarantine"
    },
    {
      name                       = "DENY_ANY_FROM_QUARANTINE"
      priority                   = 100
      access                     = "Deny"
      direction                  = "Outbound"
      destination_address_prefix = "*"
      source_asg                 = "quarantine"
    },
  ]

  namespace = "deep"

  tags = {
    BU    = "Enterprise"
    Owner = "Security"
  }
}
```

## Input variables

The following arguments are supported:

* `region_map_rgs` - (Required) Map of locations to RG names where VNETs are deployed for each region.

* `region_map_vnets` - (Required) Map of locations to VNET address spaces within the region.

* `common_subnets` - (Required) Map of subnet names to address allocations common for all deployed VNETs.

* `namespace` - (Optional) Namespace to use as a prefix in resource names and in tags.

* `tags` - (Optional) Tags to be assigned to each deployed resource.

## Output variables

The following attributes are exported:

* `vnet_map` - Map of VNET names to RGs.
