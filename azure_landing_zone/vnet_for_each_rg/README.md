---
page_title: "Terraform :: Modules :: Azure :: vnet_for_each_rg"
tags:
  - Terraform
  - tf_modules
  - VNET
  - Virtual Network
---
# vnet_for_each_rg

Creates a set of Virtual Networks named as `{{namespace}}_{{vnet_map.key}}_vnet` in each Resource Group specified by the `vnet_map[key].vnet_rg_name`.

> Note: Resource Groups are imported as `data` and thus, MUST exist prior to invocation of this module.

Configures each Virtual Network with the IP address space defined by the corresponding `vnet_map[key].address_space`. Each Virtual Network is compartmentalized further into subnets based on the values in the `vnet_map[key].subnets` map.

Each subnet is configured to use a subset of the VNET address space as defined by `vnet_map[key].subnets[i].bits` and `vnet_map[key].subnets[i].index` (see documentation for [cidrsubnet][1] function). Also Service Endpoints are enabled for each subnet based on the `vnet_map[key].subnets[i].svc_endpoints`.

[1]: https://www.terraform.io/docs/configuration/functions/cidrsubnet.html

## Example Usage

```hcl
module "vnets_init" {
  source = "github.com/undp/tf-modules//azure_landing_zone/vnet_for_each_rg?ref=v0.1.0"

  vnet_map  = {
    vnet_name_A = {
      vnet_rg_name  = "rg1"
      address_space = "10.1.0.0/24"
      subnets = {
        dmz = {
          bits          = 1
          index         = 0
          svc_endpoints = []
        }
        management = {
          bits  = 1
          index = 1
          svc_endpoints = [
            "Microsoft.AzureActiveDirectory",
          ]
        }
      }
    }
    vnet_name_B = {
      vnet_rg_name  = "rg2"
      address_space = "10.2.0.0/24"
      subnets = {
        dmz = {
          bits          = 1
          index         = 0
          svc_endpoints = []
        }
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

The following arguments are supported:

* `vnet_map` - (Required) Map of VNET names to configurations to deploy in each RG.

* `namespace` - (Optional) Namespace to use as a prefix in resource names and in tags.

* `tags` - (Optional) Tags to be assigned to each deployed resource.

## Output variables

The following attributes are exported:

* `vnet_names` - List of VNET names.

* `vnet_ids` - List of VNET ids.
