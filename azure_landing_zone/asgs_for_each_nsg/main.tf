data "azurerm_resource_group" "asg_init" {
  for_each = var.nsg_map
  name     = each.value.nsg_rg_name
}

locals {
  rough_asg_set = {
    for nsg_key, nsg in var.nsg_map : nsg_key => {
      source_asg_list      = [for rule in nsg.nsg_rules : lookup(rule, "source_asg", "")]
      destination_asg_list = [for rule in nsg.nsg_rules : lookup(rule, "destination_asg", "")]
    }
  }

  clean_asg_set = {
    for nsg_key, nsg in local.rough_asg_set : nsg_key => distinct(compact(concat(nsg.source_asg_list, nsg.destination_asg_list)))
  }

  asg_list = flatten([
    for nsg_key, asg_list in local.clean_asg_set : [
      for asg_name in asg_list : {
        key      = "${nsg_key}_${asg_name}"
        name     = asg_name
        location = data.azurerm_resource_group.asg_init[nsg_key].location
        rg_name  = data.azurerm_resource_group.asg_init[nsg_key].name
      }
    ]
  ])

  asg_map = {
    for asg in local.asg_list : asg.key => asg
  }
}

resource "azurerm_application_security_group" "asg_init" {
  for_each            = local.asg_map
  name                = each.value.name
  location            = each.value.location
  resource_group_name = each.value.rg_name

  tags = merge({ "Namespace" = "${title(var.namespace)}" }, "${var.tags}")
}
