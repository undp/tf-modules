output "vault_id_map" {
  description = "Map of Key Vault IDs to corresponding name and resource group."
  value = {
    for key, key_vault in azurerm_key_vault.region_key_vault : key_vault.id => {
      name                = key_vault.name
      resource_group_name = key_vault.resource_group_name
    }
  }
}

output "vault_obj_map" {
  description = "Map of `region_rg_map.key` to all Key Vault properties."
  value       = azurerm_key_vault.region_key_vault
}

output "admin_uai_id_map" {
  description = "Map of `admin` user assigned identity IDs to corresponding name and resource group."
  value = {
    for key, identity in azurerm_user_assigned_identity.region_identity_admin : identity.id => {
      name                = identity.name
      resource_group_name = identity.resource_group_name
    }
  }
}

output "admin_uai_obj_map" {
  description = "Map of `region_rg_map.key` to `admin` user assigned identity properties."
  value       = azurerm_user_assigned_identity.region_identity_admin
}

output "reader_uai_id_map" {
  description = "Map of `reader` user assigned identity IDs to corresponding name and resource group."
  value = {
    for key, identity in azurerm_user_assigned_identity.region_identity_reader : identity.id => {
      name                = identity.name
      resource_group_name = identity.resource_group_name
    }
  }
}

output "reader_uai_obj_map" {
  description = "Map of `region_rg_map.key` to `reader` user assigned identity properties."
  value       = azurerm_user_assigned_identity.region_identity_reader
}
