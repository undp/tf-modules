---
page_title: "Terraform :: Modules :: Azure :: gallery_for_each_rg"
tags:
  - Terraform
  - tf_modules
  - SIG
  - Shared Image Gallery
---
# gallery_for_each_rg

Deploys a set of Shared Image Galleries named as `{{prefix}}_{{resource_name}}_{{location}}_sig` into each corresponding Resource Group specified by the values of the `region_rg_map`. Following substitutions and expansions are used in the name template:

* `{{prefix}}` is the value of `namespace`, if defined. Otherwise, `{{prefix}}` is dropped from the name.

* `{{resource_name}}` is the value of `conf_common.name`, if defined. Otherwise, `conf_map[*].name` for each regional resource. If `conf_map[*].name` parameter does not exist for some keys, `{{resource_name}}` is dropped from the name.

* `{{location}}` is the keys of `region_rg_map`.

> IMPORTANT! Keys for `region_rg_map` and `conf_map` must match.

The rest of the resource parameters are defined in the same way by either `conf_common` for all resources at once, or by `conf_map` for each resource individually. Parameters from `conf_common` get precedence over specific ones from `conf_map`. If no parameter is provided in any of the two, `null` is assigned.

## Example Usage

```hcl
module "image_galleries" {
  source = "github.com/undp/tf-modules//azure_landing_zone/gallery_for_each_rg?ref=v0.1.4"

  region_rg_map = {
    westeurope  = "rg1"
    northeurope = "rg2"
  }

  conf_common = {
    description = "Regional Shared Image Gallery"
  }

  conf_map = {
    westeurope  = {
      name = "prod"
    }
    northeurope = {
      name = "dev"
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

* `region_rg_map` - Map of locations to RG names where resources are deployed for each region.

* `conf_common` - (Optional) Common configuration parameters applied for each regional resource.

* `conf_map` - Map of parameters specific to each resource deployed in a region.

* `namespace` - (Optional) Namespace to use as a prefix in resource names and in tags.

* `tags` - (Optional) Tags to be assigned to each deployed resource.

## Output variables

The following attributes are exported:

* `names_list` - List of deployed resource names.

* `ids_list` - List of deployed resource ids.

* `obj_map` - Map of `region_rg_map.key` to deployed resource properties.
