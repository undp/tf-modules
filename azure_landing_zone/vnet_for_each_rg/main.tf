# Get existing networking RG parameters as data objects
data "azurerm_resource_group" "vnet_init" {
  for_each = var.vnet_map
  name     = each.value.vnet_rg_name
}

# Deploy VNET in each RG
resource "azurerm_virtual_network" "vnet_init" {
  for_each            = var.vnet_map
  name                = "${lower(var.namespace)}_${lower(each.key)}_vnet"
  resource_group_name = data.azurerm_resource_group.vnet_init[each.key].name
  location            = data.azurerm_resource_group.vnet_init[each.key].location
  address_space       = [each.value.address_space]
  tags                = merge({ "Namespace" = "${title(var.namespace)}" }, "${var.tags}")
}

# Generate a flat list of parameters for each subnet and then convert the flat subnet
# list into the map with unique keys `subnet_name@vnet_name` to ensure that subnets
# are not destroyed/recreated due to insertion of elements into the middle of the list
# when subnets added/removed in the the `vnet_map`.
locals {
  subnets_list = flatten([
    for vnet_key, vnet in var.vnet_map : [
      for subnet_key, subnet in vnet.subnets : {
        subnet_name = subnet_key
        subnet_prefix = cidrsubnet(
          vnet.address_space,
          subnet.bits,
          subnet.index,
        )
        svc_endpoints = subnet.svc_endpoints
        # TODO:20191230:01: Seems to be a leftover. Remove if nothing breaks.
        # nsg_key       = vnet_key
        vnet_name     = azurerm_virtual_network.vnet_init[vnet_key].name
        vnet_location = azurerm_virtual_network.vnet_init[vnet_key].location
        vnet_rg_name  = azurerm_virtual_network.vnet_init[vnet_key].resource_group_name
      }
    ]
  ])

  vnet_subnet_map = {
    for subnet in local.subnets_list : "${lower(subnet.subnet_name)}@${lower(subnet.vnet_name)}" => subnet
  }
}

# Allocate subnets for each VNET
resource "azurerm_subnet" "vnet_init" {
  # Remove when azurerm 2.0 provider is released. See [issue #2918][1] for more details.
  #
  # [1]: https://github.com/terraform-providers/terraform-provider-azurerm/issues/2918
  #
  lifecycle {
    ignore_changes = [network_security_group_id]
  }

  for_each             = local.vnet_subnet_map
  name                 = each.value.subnet_name
  address_prefix       = each.value.subnet_prefix
  virtual_network_name = each.value.vnet_name
  resource_group_name  = each.value.vnet_rg_name
  service_endpoints    = each.value.svc_endpoints
}
