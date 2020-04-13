# Get existing regional RG parameters as data objects
data "azurerm_resource_group" "region_rg" {
  for_each = var.region_rg_map
  name     = each.value
}

# Get current Azure client config
data "azurerm_client_config" "current" {
}

# Deploy Shared Image Gallery in each regional RG
resource "azurerm_shared_image_gallery" "region_image_gallery" {
  for_each = var.region_rg_map

  name = join("_", compact([
    lower(var.namespace),
    lower(lookup(
      var.conf_common, "name", lookup(lookup(
        var.conf_map, each.key, {}), "name",
        ""
    ))),
    lower(each.key),
    "sig"
  ]))

  resource_group_name = data.azurerm_resource_group.region_rg[each.key].name
  location            = data.azurerm_resource_group.region_rg[each.key].location

  description = lookup(
    var.conf_common, "description", lookup(lookup(
      var.conf_map, each.key, {}), "description",
      null
  ))

  tags = merge(
    { "Namespace" = "${title(var.namespace)}" },
    "${var.tags}"
  )
}

# Generate flat map of Shared Image Definitions
locals {
  region_image_map = {
    for region in keys(var.region_rg_map) : region => lookup(
      var.conf_common, "image_definitions", lookup(lookup(
        var.conf_map, region, {}), "image_definitions",
        {}
      )
    )
  }

  region_image_list = flatten([
    for region, images in local.region_image_map : [
      for image in images : {
        key       = lower("${region}_${image.publisher}_${image.offer}_${image.sku}")
        region    = region
        publisher = image.publisher
        offer     = image.offer
        sku       = image.sku
        options   = lookup(image, "options", {})
      }
    ]
  ])

  image_map = {
    for image in local.region_image_list : image.key => image
  }
}

# Deploy Shared Image Definitions in each regional SIG
resource "azurerm_shared_image" "region_image" {
  for_each = local.image_map

  name = lower(join("_", compact([
    each.value.publisher,
    each.value.offer,
    each.value.sku,
    "sid"
  ])))

  gallery_name = azurerm_shared_image_gallery.region_image_gallery[each.value.region].name

  resource_group_name = data.azurerm_resource_group.region_rg[each.value.region].name
  location            = data.azurerm_resource_group.region_rg[each.value.region].location

  identifier {
    publisher = each.value.publisher
    offer     = each.value.offer
    sku       = each.value.sku
  }

  os_type               = lookup(each.value.options, "os_type", "Linux")
  description           = lookup(each.value.options, "description", null)
  eula                  = lookup(each.value.options, "eula", null)
  privacy_statement_uri = lookup(each.value.options, "privacy_statement_uri", null)
  release_note_uri      = lookup(each.value.options, "release_note_uri", null)

  tags = merge(
    { "Namespace" = "${title(var.namespace)}" },
    var.tags,
    lookup(each.value.options, "tags", {})
  )

  provisioner "local-exec" {
    command = lookup(
      var.conf_common, "build_images", lookup(lookup(
        var.conf_map, each.value.region, {}), "build_images",
        false
        )) ? join("/", compact([
          lookup(
            var.conf_common, "build_dir", lookup(lookup(
              var.conf_map, each.value.region, {}), "build_dir",
              ""
          )),
          lookup(each.value.options, "build_script", "build.sh"),
    ])) : "echo build_images = false"

    environment = {
      # Ensure build script has the same Tenant, Client and Subscription IDs in ENV
      # **NOTE:** `ARM_CLIENT_SECRET` must be defined outside of this module (e.g. CI/CD pipeline)
      ARM_TENANT_ID       = data.azurerm_client_config.current.tenant_id
      ARM_CLIENT_ID       = data.azurerm_client_config.current.client_id
      ARM_SUBSCRIPTION_ID = data.azurerm_client_config.current.subscription_id

      # Pass SIG parameters to publish image into
      BUILD_GALLERY_LOCATION = self.location
      BUILD_GALLERY_NAME     = self.gallery_name
      BUILD_GALLERY_RG       = self.resource_group_name
      BUILD_GALLERY_SID      = self.name

      # Pass parameters of the result image
      BUILD_RESULT_IMAGE_OS = self.os_type
    }

    on_failure = continue
  }
}
