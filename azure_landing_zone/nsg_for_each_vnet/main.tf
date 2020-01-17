# Get existing security RG parameters as data objects
data "azurerm_resource_group" "nsg_init" {
  for_each = var.nsg_rg_map
  name     = each.value
}

# Get existing VNET parameters as data objects
data "azurerm_virtual_network" "nsg_init" {
  for_each            = var.vnet_map
  name                = "${lower(var.namespace)}_${lower(each.key)}_vnet"
  resource_group_name = each.value.vnet_rg_name
}

# Prepare a map of existing subnets and their relations to VNETs
locals {
  subnets_list = flatten([
    for vnet_key, vnet in var.vnet_map : [
      for subnet_name in data.azurerm_virtual_network.nsg_init[vnet_key].subnets : {
        subnet_name  = subnet_name
        vnet_key     = vnet_key
        vnet_name    = data.azurerm_virtual_network.nsg_init[vnet_key].name
        vnet_rg_name = data.azurerm_virtual_network.nsg_init[vnet_key].resource_group_name
      }
    ]
  ])

  subnets_map = {
    for subnet in local.subnets_list : "${lower(subnet.subnet_name)}@${lower(subnet.vnet_name)}" => subnet
  }
}

# Get existing subnet parameters as data objects
data "azurerm_subnet" "nsg_init" {
  for_each             = local.subnets_map
  name                 = each.value.subnet_name
  virtual_network_name = each.value.vnet_name
  resource_group_name  = each.value.vnet_rg_name
}

# Deploy NSGs in each RG
resource "azurerm_network_security_group" "nsg_init" {
  for_each            = var.vnet_map
  name                = "${lower(var.namespace)}_${lower(each.key)}_nsg"
  resource_group_name = data.azurerm_resource_group.nsg_init[data.azurerm_virtual_network.nsg_init[each.key].location].name
  location            = data.azurerm_resource_group.nsg_init[data.azurerm_virtual_network.nsg_init[each.key].location].location

  tags = merge({ "Namespace" = "${title(var.namespace)}" }, "${var.tags}")
}

# Prepare a map of association parameters between subnets and corresponding VNET-wide NSGs
locals {
  nsg_subnet_association_map = {
    for subnet in local.subnets_list : "${lower(subnet.subnet_name)}@${lower(subnet.vnet_name)}" => merge(
      { nsg_id = azurerm_network_security_group.nsg_init[subnet.vnet_key].id },
      { subnet_id = data.azurerm_subnet.nsg_init["${lower(subnet.subnet_name)}@${lower(subnet.vnet_name)}"].id },
    )
  }
}

# Associate NSGs with all corresponding subnets in each VNET
resource "azurerm_subnet_network_security_group_association" "nsg_init" {
  for_each                  = local.nsg_subnet_association_map
  subnet_id                 = each.value.subnet_id
  network_security_group_id = each.value.nsg_id
}
