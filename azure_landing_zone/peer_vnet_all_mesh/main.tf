# Get existing VNET parameters as data objects
data "azurerm_virtual_network" "peered_mesh" {
  for_each            = var.vnet_map
  name                = "${lower(var.namespace)}_${lower(each.key)}_vnet"
  resource_group_name = each.value.vnet_rg_name
}

# Generate a map of `origin_vnet_name` <-> `remote_vnet_name` perring pairs
# excluding pering to self
locals {
  perring_vnets = {
    for pair in setproduct(keys(var.vnet_map), keys(var.vnet_map)) : "${pair[0]}_to_${pair[1]}" => {
      origin_key     = pair[0]
      remote_key     = pair[1]
      vnet_rg_name   = data.azurerm_virtual_network.peered_mesh[pair[0]].resource_group_name
      vnet_name      = data.azurerm_virtual_network.peered_mesh[pair[0]].name
      remote_vnet_id = data.azurerm_virtual_network.peered_mesh[pair[1]].id
    } if pair[0] != pair[1]
  }
}

# Establish meshed VNET peerings
resource "azurerm_virtual_network_peering" "peered_mesh" {
  for_each                  = local.perring_vnets
  name                      = "${lower(var.namespace)}_${lower(each.key)}_peering"
  resource_group_name       = local.perring_vnets[each.key].vnet_rg_name
  virtual_network_name      = local.perring_vnets[each.key].vnet_name
  remote_virtual_network_id = local.perring_vnets[each.key].remote_vnet_id

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
