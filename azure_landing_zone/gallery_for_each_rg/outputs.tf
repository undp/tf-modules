output "sig_id_map" {
  description = "Map of SIG IDs to corresponding name and resource group."
  value = {
    for key, sig in azurerm_shared_image_gallery.region_image_gallery : sig.id => {
      name                = sig.name
      resource_group_name = sig.resource_group_name
    }
  }
}

output "sig_obj_map" {
  description = "Map of `region_rg_map.key` to all SIG properties."
  value       = azurerm_shared_image_gallery.region_image_gallery
}

output "sid_id_map" {
  description = "Map of SID IDs to corresponding image name, SIG name and resource group."
  value = {
    for key, sid in azurerm_shared_image.region_image : sid.id => {
      name                = sid.name
      gallery_name        = sid.gallery_name
      resource_group_name = sid.resource_group_name
    }
  }
}

output "sid_obj_map" {
  description = "Map of `region_rg_map.key` to all SID properties."
  value       = azurerm_shared_image.region_image
}
