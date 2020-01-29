output "rule_names" {
  description = "List of NSG rule names."
  value       = values(azurerm_network_security_rule.nsg_rules)[*].name
}

output "rule_ids" {
  description = "List of NSG rule IDs."
  value       = values(azurerm_network_security_rule.nsg_rules)[*].id
}

output "rule_map" {
  description = "Map of input `nsg_map` keys to list of NSG rule objects."
  value = {
    for rule_key, rule in azurerm_network_security_rule.nsg_rules : local.rules_map[rule_key].nsg_key => rule...
  }
}
