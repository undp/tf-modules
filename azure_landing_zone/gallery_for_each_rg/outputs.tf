output "names_list" {
  description = "List of deployed resource names."
  value       = values(azurerm_shared_image_gallery.region_image_gallery)[*].name
}

output "ids_list" {
  description = "List of deployed resource ids."
  value       = values(azurerm_shared_image_gallery.region_image_gallery)[*].id
}

output "obj_map" {
  description = "Map of `region_rg_map.key` to deployed resource properties."
  value = {
    for key in keys(var.region_rg_map) :
    key => azurerm_shared_image_gallery.region_image_gallery[key]
  }
}
