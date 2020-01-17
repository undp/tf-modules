output "private_dns_zones" {
  description = "List of private DNS zones deployed."
  value       = azurerm_private_dns_zone.dns_private
}
