output "vnet_names" {
  description = "List of VNET names."
  value       = values(azurerm_virtual_network.vnet_init)[*].name
}

output "vnet_ids" {
  description = "List of VNET IDs."
  value       = values(azurerm_virtual_network.vnet_init)[*].id
}
