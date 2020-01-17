output "nsg_names" {
  description = "List of NSG names."
  value       = values(azurerm_network_security_group.nsg_init)[*].name
}

output "nsg_ids" {
  description = "List of NSG IDs."
  value       = values(azurerm_network_security_group.nsg_init)[*].id
}

output "nsg_map" {
  description = "Map of input `vnet_map.key` to resulting NSG properties."
  value = {
    for vnet_key, nsg in azurerm_network_security_group.nsg_init : vnet_key => {
      nsg_id       = nsg.id
      nsg_location = nsg.location
      nsg_name     = nsg.name
      nsg_rg_name  = nsg.resource_group_name
    }
  }
}
