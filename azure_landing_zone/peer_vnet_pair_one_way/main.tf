# Get existing src VNET parameters as data objects
data "azurerm_virtual_network" "vnet_src" {
  for_each            = var.vnet_map_src
  name                = "${lower(var.namespace)}_${lower(each.key)}_vnet"
  resource_group_name = each.value.vnet_rg_name
}

# Get existing dst VNET parameters as data objects
data "azurerm_virtual_network" "vnet_dst" {
  for_each            = var.vnet_map_dst
  name                = "${lower(var.namespace)}_${lower(each.key)}_vnet"
  resource_group_name = each.value.vnet_rg_name
}

# Generate config map for peerings from `vnet_map_src` to `vnet_map_dst`
locals {
  perring_src_to_dst = {
    for key in keys(var.vnet_map_src) : "${var.name_prefix_src}_to_${var.name_prefix_dst}_${key}" => {
      remote_vnet_id = data.azurerm_virtual_network.vnet_dst[key].id
      vnet_name      = data.azurerm_virtual_network.vnet_src[key].name
      vnet_rg_name   = data.azurerm_virtual_network.vnet_src[key].resource_group_name
    }
  }
}

# Establish one-way VNET peerings src -> dst
resource "azurerm_virtual_network_peering" "perring_src_to_dst" {
  for_each                  = local.perring_src_to_dst
  name                      = "${lower(var.namespace)}_${lower(each.key)}_peering"
  resource_group_name       = each.value.vnet_rg_name
  virtual_network_name      = each.value.vnet_name
  remote_virtual_network_id = each.value.remote_vnet_id

  # Controls if the VMs in the remote VNET can access VMs in the local
  # VNET. Defaults to false.
  allow_virtual_network_access = true

  # Controls if forwarded traffic from VMs in the remote VNET is allowed
  # into the local VNET. Defaults to false.
  allow_forwarded_traffic = true

  # Gateway transit enables one virtual network to use the VPN gateway in the peered
  # virtual network for cross-premises or VNet-to-VNet connectivity. To use this setting,
  # only one of the virtual network in the peering can have a gateway configured.
  # Must be set to false for Global Peering
  allow_gateway_transit = false
}
