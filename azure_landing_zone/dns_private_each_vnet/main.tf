# Get existing VNET parameters as data objects
data "azurerm_virtual_network" "vnets" {
  for_each            = var.vnet_map
  name                = "${lower(var.namespace)}_${lower(each.key)}_vnet"
  resource_group_name = lower(each.value.vnet_rg_name)
}

# Deploy Private DNS Zone for each VNET
resource "azurerm_private_dns_zone" "dns_private" {
  for_each            = var.vnet_map
  name                = "${join(".", reverse(split("_", each.key)))}.${lower(var.zone_name)}.${lower(var.namespace)}"
  resource_group_name = lower(each.value.vnet_rg_name)

  tags = merge({ "Namespace" = "${title(var.namespace)}" }, "${var.tags}")
}

# Link private DNS Zone with each VNET
resource "azurerm_private_dns_zone_virtual_network_link" "dns_private_link" {
  for_each              = azurerm_private_dns_zone.dns_private
  name                  = "${lower(var.namespace)}_${lower(each.key)}_dnslink"
  resource_group_name   = each.value.resource_group_name
  private_dns_zone_name = each.value.name
  registration_enabled  = true
  virtual_network_id    = data.azurerm_virtual_network.vnets[each.key].id
}
