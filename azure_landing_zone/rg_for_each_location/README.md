---
page_title: "Terraform :: Modules :: Azure :: rg_for_each_location"
tags:
  - Terraform
  - tf_modules
  - RG
  - Resource Group
---
# rg_for_each_location

Creates a set of Azure Resource Groups named as `{{NAMESPACE}}_{{NAME_PREFIX}}_{{LOCATION}}` in each location specified by the `locations` input variable.

## Example Usage

```hcl
module "resource_groups" {
  source = "./modules/rg_for_each_location"

  locations  = [
    "northeurope",
    "westeurope"
  ]

  name_prefix = "space"

  namespace = "deep"

  tags = {
    BU    = "Enterprise"
    Owner = "Cybersecurity"
  }
}
```

## Input variables

The following arguments are supported:

* `locations` - (Required) List of Azure locations to deploy RGs. Use only one-word names (e.g. `westeurope` and not `West Europe`).

* `name_prefix` - (Required) Prefix to add to all resource names.

* `namespace` - (Optional) Namespace to use as a prefix in resource names and in tags.

* `tags` - (Optional) Tags to be assigned to each deployed resource.

## Output variables

The following attributes are exported:

* `rg_names` - List of RG names.

* `rg_ids` - List of RG ids.

* `rg_map` - Map of locations to RG names.
