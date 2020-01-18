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

For each `nsg_map[key].nsg_rg_name` Resource Group, module creates all Application Security Groups mentioned as either the source or destination in the `nsg_map[key].nsg_rules` list following the naming convention `{{[source|destination]_asg}}_{{nsg_map.key}}`. Each `nsg_map[key].nsg_name` Network Security Group is populated with the security rules from the `nsg_map[key].nsg_rules` list.

## Example Usage

```hcl
module "vnets_peered" {
  source = "./modules/rules_for_each_nsg"

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

* `asg_names` - List of ASG names.

* `asg_ids` - List of ASG IDs.

* `asg_map` - Map of input `nsg_map` keys to ASG properties.
