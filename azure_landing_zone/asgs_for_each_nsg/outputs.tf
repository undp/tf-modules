output "asg_names" {
  description = "List of ASG names."
  value       = values(azurerm_application_security_group.asg_init)[*].name
}

output "asg_ids" {
  description = "List of ASG IDs."
  value       = values(azurerm_application_security_group.asg_init)[*].id
}

output "asg_map" {
  description = "Map of input `nsg_map.key` to resulting ASG properties."
  value       = azurerm_application_security_group.asg_init
}
