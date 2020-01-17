# Get existing hub VNET parameters as data objects
data "azurerm_virtual_network" "hub_vnets" {
  for_each            = var.vnet_map_hub
  name                = "${lower(var.namespace)}_${lower(each.key)}_vnet"
  resource_group_name = each.value.vnet_rg_name
}

# Get existing spoke VNET parameters as data objects
data "azurerm_virtual_network" "spoke_vnets" {
  for_each            = var.vnet_map_spoke
  name                = "${lower(var.namespace)}_${lower(each.key)}_vnet"
  resource_group_name = each.value.vnet_rg_name
}

locals {
  # Aggregate hub VNET keys by region
  hub_loc_map = {
    for key, vnet in data.azurerm_virtual_network.hub_vnets : vnet.location => key...
  }

  # Aggregate spoke VNET keys by region
  spoke_loc_map = {
    for key, vnet in data.azurerm_virtual_network.spoke_vnets : vnet.location => key...
  }

  # Generate a list of one-way VNET perring pairs HUB -> SPOKE
  hub_to_spoke_perring_list = flatten([
    for key in keys(local.hub_loc_map) : [
      for pair in setproduct(local.hub_loc_map[key], local.spoke_loc_map[key]) : {
        map_key        = "${pair[0]}_to_${pair[1]}"
        origin_key     = pair[0]
        remote_key     = pair[1]
        vnet_rg_name   = data.azurerm_virtual_network.hub_vnets[pair[0]].resource_group_name
        vnet_name      = data.azurerm_virtual_network.hub_vnets[pair[0]].name
        remote_vnet_id = data.azurerm_virtual_network.spoke_vnets[pair[1]].id
      }
    ]
  ])

  # Convert HUB -> SPOKE peering list to map
  hub_to_spoke_perring_map = {
    for peering in local.hub_to_spoke_perring_list : peering.map_key => peering
  }

  # Generate a list of one-way VNET perring pairs SPOKE -> HUB
  spoke_to_hub_perring_list = flatten([
    for key in keys(local.spoke_loc_map) : [
      for pair in setproduct(local.spoke_loc_map[key], local.hub_loc_map[key]) : {
        map_key        = "${pair[0]}_to_${pair[1]}"
        origin_key     = pair[0]
        remote_key     = pair[1]
        vnet_rg_name   = data.azurerm_virtual_network.spoke_vnets[pair[0]].resource_group_name
        vnet_name      = data.azurerm_virtual_network.spoke_vnets[pair[0]].name
        remote_vnet_id = data.azurerm_virtual_network.hub_vnets[pair[1]].id
      }
    ]
  ])

  # Convert SPOKE -> HUB peering list to map
  spoke_to_hub_perring_map = {
    for peering in local.spoke_to_hub_perring_list : peering.map_key => peering
  }

  # Merge HUB -> SPOKE and SPOKE -> HUB maps into one common HUB <-> SPOKE map
  bidirectional_peering = merge(
    local.hub_to_spoke_perring_map,
    local.spoke_to_hub_perring_map,
  )
}

# Establish HUB <-> SPOKE peerings
resource "azurerm_virtual_network_peering" "bidirectional_hub_spoke_peering" {
  for_each                  = local.bidirectional_peering
  name                      = "${lower(var.namespace)}_${lower(each.key)}_peering"
  resource_group_name       = local.bidirectional_peering[each.key].vnet_rg_name
  virtual_network_name      = local.bidirectional_peering[each.key].vnet_name
  remote_virtual_network_id = local.bidirectional_peering[each.key].remote_vnet_id

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
