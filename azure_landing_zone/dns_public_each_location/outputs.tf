output "zone_main_fqdn" {
  description = "FQDN for the main Public Zone deployed."
  value       = azurerm_dns_zone.main.name
}

output "zone_main_ns_list" {
  description = "List of NS IPs for the Public Zone deployed."
  value       = azurerm_dns_zone.main.name_servers
}

output "zone_main_map" {
  description = "Map of the Public Zone FQDN into the list of NS IPs for it."
  value = {
    "${azurerm_dns_zone.main.name}" = azurerm_dns_zone.main.name_servers
  }
}

output "zone_sub_fqdn_list" {
  description = "List of FQDNs for all regional subdomains of the main Public Zone deployed."
  value       = values(azurerm_dns_zone.sub)[*].name
}

output "zone_sub_map" {
  description = "Map of FQDNs for all regional subdomains into the list of NS IPs for each."
  value = {
    for zone in values(azurerm_dns_zone.sub) : zone.name => zone.name_servers
  }
}

output "zone_main_obj" {
  description = "Complete object for the Public Zone deployed."
  value       = azurerm_dns_zone.main
}

output "zone_sub_obj_map" {
  description = "List of complete objects for all regional subdomains of the main Public Zone deployed."
  value       = azurerm_dns_zone.sub
}
