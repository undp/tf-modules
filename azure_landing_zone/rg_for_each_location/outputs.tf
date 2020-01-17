output "rg_names" {
  description = "List of RG names."
  value       = values(azurerm_resource_group.rg_set)[*].name
}

output "rg_ids" {
  description = "List of RG ids."
  value       = values(azurerm_resource_group.rg_set)[*].id
}

output "rg_map" {
  description = "Map of locations to RG names."
  value       = { for rg in azurerm_resource_group.rg_set : rg.location => rg.name }
}
