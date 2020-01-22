# Get existing main Public Zone RG
data "azurerm_resource_group" "zone_rg" {
  name = var.zone_rg
}

# Get existing subdomain RGs
data "azurerm_resource_group" "sub_rgs" {
  for_each = var.region_map_rgs
  name     = each.value
}

# Deploy main Public Zone
resource "azurerm_dns_zone" "main" {
  name                = join(".", compact([lower(var.zone_name), lower(var.namespace), lower(var.zone_suffix)]))
  resource_group_name = data.azurerm_resource_group.zone_rg.name

  tags = merge({ "Namespace" = "${title(var.namespace)}" }, "${var.tags}")
}

# Deploy regional Public Zones
resource "azurerm_dns_zone" "sub" {
  for_each            = var.region_map_rgs
  name                = join(".", [data.azurerm_resource_group.sub_rgs[each.key].location, azurerm_dns_zone.main.name])
  resource_group_name = data.azurerm_resource_group.sub_rgs[each.key].name

  tags = merge({ "Namespace" = "${title(var.namespace)}" }, "${var.tags}")
}

# Create NS records for regional subdomains
resource "azurerm_dns_ns_record" "sub" {
  for_each            = azurerm_dns_zone.sub
  name                = each.key
  zone_name           = azurerm_dns_zone.main.name
  resource_group_name = data.azurerm_resource_group.zone_rg.name
  ttl                 = 300
  records             = each.value.name_servers

  tags = merge({ "Namespace" = "${title(var.namespace)}" }, "${var.tags}")
}
