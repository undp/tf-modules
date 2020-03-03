# Get existing regional RG parameters as data objects.
data "azurerm_resource_group" "region_rg" {
  for_each = var.region_rg_map
  name     = each.value
}

# Deploy Shared Image Gallery in each regional RG.
resource "azurerm_shared_image_gallery" "region_image_gallery" {
  for_each = var.region_rg_map

  name = join("_", compact([
    lower(var.namespace),
    lower(lookup(var.conf_common, "name", lookup(lookup(var.conf_map, each.key, {}), "name", ""))),
    lower(each.key),
    "sig"
  ]))

  description = lookup(var.conf_common, "description", lookup(lookup(var.conf_map, each.key, {}), "description", null))

  resource_group_name = data.azurerm_resource_group.region_rg[each.key].name
  location            = data.azurerm_resource_group.region_rg[each.key].location

  tags = merge(
    { "Namespace" = "${title(var.namespace)}" },
    "${var.tags}"
  )
}
