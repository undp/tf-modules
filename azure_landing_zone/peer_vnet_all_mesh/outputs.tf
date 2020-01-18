output "peering_names" {
  description = "List of VNET peering names."
  value       = values(azurerm_virtual_network_peering.peered_mesh)[*].name
}

output "peering_ids" {
  description = "List of VNET peering IDs."
  value       = values(azurerm_virtual_network_peering.peered_mesh)[*].id
}
