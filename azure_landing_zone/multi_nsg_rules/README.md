---
page_title: "Terraform :: Modules :: Azure :: multi_nsg_rules"
tags:
  - Terraform
  - tf_modules
  - NSG
  - Network Security Group
---
# multi_nsg_rules

Works as a wrapper for `rules_for_each_nsg` module allowing to define the same set of rules in one place for all NSGs created.

## Example Usage

```hcl
module "vnets_peered" {
  source = "./modules/multi_nsg_rules"

  nsg_map = {
    vnet_A = {
      nsg_name    = "vnet_A_nsg"
      nsg_rg_name = "security_A"
    }
    vnet_B = {
      nsg_name    = "vnet_B_nsg"
      nsg_rg_name = "security_B"
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

* `nsg_map` - (Required) Map of VNET names to corresponding NSG names and RGs.

* `common_nsg_rules` - (Required) Security rules to be deployed for all NSGs.

* `namespace` - (Optional) Namespace to use as a prefix in resource names and in tags.

* `tags` - (Optional) Tags to be assigned to each deployed resource.

## Output variables

No attributes are exported.
