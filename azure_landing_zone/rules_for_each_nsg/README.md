---
page_title: "Terraform :: Modules :: Azure :: rules_for_each_nsg"
tags:
  - Terraform
  - tf_modules
  - NSG
  - Network Security Group
  - Security Rules
---
# rules_for_each_nsg

Each `nsg_map[key].nsg_name` Network Security Group is populated with the security rules from the `nsg_map[key].nsg_rules` list.

> Note: Application Security Groups used in `nsg_map[key].nsg_rules` are imported as `data` and thus, MUST exist prior to invocation of this module.

## Example Usage

```hcl
module "vnets_peered" {
  source = "github.com/undp/tf-modules//azure_landing_zone/rules_for_each_nsg?ref=v0.1.0"

  nsg_map = {
    vnet_A = {
      nsg_name    = "vnet_A_nsg"
      nsg_rg_name = "security_A"
      nsg_rules = [
        {
          name                   = "DENY_ANY_TO_QUARANTINE"
          priority               = 100
          access                 = "Deny"
          direction              = "Inbound"
          source_address_prefix  = "*"
          destination_asg        = "quarantine"
        },
      ]
    }
    vnet_B = {
      nsg_name    = "vnet_B_nsg"
      nsg_rg_name = "securityB"
      nsg_rules = [
        {
          name                   = "ALLOW_SSH_FROM_INET_TO_MANAGEMENT"
          priority               = 1000
          access                 = "Allow"
          direction              = "Inbound"
          protocol               = "Tcp"
          source_port_range      = "*"
          destination_port_range = "22"
          source_address_prefix  = "Internet"
          destination_asg        = "management"
        },
      ]
    }
  }

  asg_auto_create = false

  namespace = "deep"

  tags = {
    BU    = "Enterprise"
    Owner = "Security"
  }
}
```

## Input variables

The following arguments are supported:

* `nsg_map` - (Required) Map of NSG parameters.

* `namespace` - (Optional) Namespace to use as a prefix in resource names and in tags.

* `tags` - (Optional) Tags to be assigned to each deployed resource.

## Output variables

The following attributes are exported:

* `rule_names` - List of NSG rule names.

* `rule_ids` - List of NSG rule IDs.

* `rule_map` - Map of input `nsg_map` keys to list of NSG rule objects.
