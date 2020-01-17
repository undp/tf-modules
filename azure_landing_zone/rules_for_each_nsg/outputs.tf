output "asg_names" {
  description = "List of ASG names."
  value       = values(azurerm_application_security_group.nsg_rules)[*].name
}

output "asg_ids" {
  description = "List of ASG IDs."
  value       = values(azurerm_application_security_group.nsg_rules)[*].id
}

output "asg_map" {
  description = "Map of input `nsg_map.key` to resulting ASG properties."
  value       = local.clean_asg_set
}
