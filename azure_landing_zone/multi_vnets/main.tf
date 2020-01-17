# Get existing networking RG parameters as data objects
data "azurerm_resource_group" "multi_rgs" {
  for_each = var.region_map_rgs
  name     = each.value
}

# Mix-in networking RG names as well as common hub
# subnetting config into the original `region_map`.
locals {
  vnet_list = flatten([
    for loc_key, vnet_map in var.region_map_vnets : [
      for vnet_key, vnet_space in vnet_map : {
        vnet_name     = "${vnet_key}_${loc_key}"
        vnet_rg_name  = data.azurerm_resource_group.multi_rgs[loc_key].name
        address_space = vnet_space
        subnets       = var.common_subnets
      }
    ]
  ])

  vnet_map = {
    for vnet in local.vnet_list : "${lower(vnet.vnet_name)}" => vnet
  }
}

# Create VNET and split it into subnets for each regional location.
module "vnets" {
  source = "../vnet_for_each_rg"

  vnet_map = local.vnet_map

  namespace = var.namespace
  tags      = var.tags
}
