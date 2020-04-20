---
page_title: "Terraform :: Modules :: Azure :: gallery_for_each_rg"
tags:
  - Terraform
  - tf_modules
  - SIG
  - Shared Image Gallery
---
# gallery_for_each_rg

Deploys a set of Shared Image Galleries (SIGs) into each corresponding regional Resource Group (RG) specified by the values of the `region_rg_map`. Creates a set of Shared Image Definitions (SIDs) in each regional SIG to group multiple image versions. Allows to execute a build script with `local-exec` provisioner for each newly deployed definition.

## Example Usage

```hcl
module "image_galleries" {
  source = "github.com/undp/tf-modules//azure_landing_zone/gallery_for_each_rg?ref=v0.1.4"

  region_rg_map = {
    eastus        = "rg1"
    canadacentral = "rg2"
  }

  conf_common = {
    description = "Regional Shared Image Gallery"
    build_dir = "../images"
  }

  conf_map = {
    westeurope  = {
      name = "prod"
      image_definitions = yamldecode(file("images_prod.yaml"))
    }
    northeurope = {
      name = "dev"
      image_definitions = yamldecode(file("images_dev.yaml"))
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

The following module arguments are supported:

* `region_rg_map` - Map of locations to RG names where resources are deployed for each region.

* `conf_module` - Map of parameters defining module-wide functionality.

* `conf_common` - Common configuration parameters applied to all regions.

* `conf_map` - (Optional) Map of locations to region-specific configuration parameters applied to each individual region.

* `namespace` - (Optional) Namespace to use as a prefix in resource names and in tags.

* `tags` - (Optional) Tags to be assigned to each deployed resource.

## Configuration Parameters

### Module Functionality

A `conf_module` parameter supports the following options:

> **NOTE:** No module-wide options. Parameter is a placeholder for future development.

### Resource Options

SIG parameters are defined by either parameters in the `conf_common` map for all regions at once, or by `conf_map` for each region individually. Common parameters from `conf_common` get precedence over region-specific ones from `conf_map`. If no parameter is provided in any of the two, default value is assigned.

  > **IMPORTANT!** Keys for `region_rg_map` and `conf_map` must match.

Both `conf_common` and `conf_map` parameters support the following options:

* `name` - (Required) Constant part of a resource name. Module generates regional resource names following the template `{{prefix}}_{{resource_name}}_{{location}}_{{suffix}}` with the substitutions below:

  * `{{prefix}}` is the value of `namespace`, if defined. Otherwise, `{{prefix}}` is dropped from the name.

  * `{{resource_name}}` is the value of `conf_common.name`, if defined. Otherwise, `conf_map[*].name` for each regional resource. If `conf_map[*].name` parameter does not exist for some keys, `{{resource_name}}` is dropped from the name.

  * `{{location}}` is the keys of `region_rg_map`.

  * `{{suffix}}` is defined based on the type of the resource and follows this mapping:

    * `sid` for the Shared Image Definition

    * `sig` for the Shared Image Gallery

* `build_dir` - (Optional) Directory with build scripts mentioned in `image_definitions[*].options.build_script` to generate initial image versions after initial deployment of each SID (done only once for newly created resources). If unspecified, module uses current directory as a default.

  > **NOTE:** This parameter is considered only if `build_images` is set to `true`.

* `build_images` - (Optional) Whether or not initial image versions should be built for SIDs in each SIG. If unspecified, module uses `false` as a default.

* `description` - (Optional) A description for the SIG.

* `image_definitions` - (Required) A list of SIDs of the following structure:

  * `publisher` - (Required) The Publisher name for the SID.

  * `offer` - (Required) The Offer name for the SID.

  * `sku` - (Required) The the Stock-Keeping Unit name for the SID.

  * `options` - (Optional) Map of options for the Shared Image of the following structure:

    * `build_script` - (Optional) Script to be executed with `local-exec` provisioner to build and publish an initial image version for this SID. If unspecified, module uses `build.sh` as a default.

      > **NOTE:** This parameter is considered only if `build_images` is set to `true`

      The build script is provided with the input through the following ENV variables:

      * `BUILD_GALLERY_LOCATION` - Azure region of the destination SIG
      * `BUILD_GALLERY_NAME` - Name of the destination SIG
      * `BUILD_GALLERY_RG` - Name of the RG containing the destination SIG
      * `BUILD_GALLERY_SID` - Name of the SID
      * `BUILD_RESULT_IMAGE_OS` - OS type defined for the SID

      To ensure that build tools use the same Azure credentials, module sets up the ENV variables below to the values from the current AzureRM client.

      * `ARM_TENANT_ID`
      * `ARM_CLIENT_ID`
      * `ARM_SUBSCRIPTION_ID`

      > **NOTE:** `ARM_CLIENT_SECRET` must be defined separately for the runtime environment (e.g. CI/CD pipeline).

      Also, `local-exec` executes the script from the current working directory of Terraform. So, if the build script is referencing other executables, scripts or files, ensure that those paths are either absolute, or all relative paths are anchored to script's actual full path.

    * `description` - (Optional) A description of the SID. If unspecified, module uses `null` as a default.

    * `eula` - (Optional) The End User Licence Agreement for the SID. If unspecified, module uses `null` as a default.

    * `os_type` - (Optional) The type of Operating System present in the SID. Possible values are `Linux` and `Windows`. If unspecified, module uses `Linux` as a default.

    * `privacy_statement_uri` - (Optional) The URI containing the Privacy Statement associated with the SID. If unspecified, module uses `null` as a default.

    * `release_note_uri` - (Optional) The URI containing the Release Notes associated with the SID. If unspecified, module uses `null` as a default.

    * `tags` - (Optional) A mapping of tags to assign to the specific SID in addition to `tags` defined at the module level.

## Output variables

The following attributes are exported:

* `sig_id_map` - Map of SIG IDs to corresponding name and resource group.

* `sig_obj_map` - Map of `region_rg_map.key` to all SIG properties.

* `sid_id_map` - Map of SID IDs to corresponding image name, SIG name and resource group.

* `sid_obj_map` - Map of `region_rg_map.key` to all SID properties.
