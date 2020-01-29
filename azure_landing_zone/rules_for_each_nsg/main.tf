data "azurerm_resource_group" "nsg_rules" {
  for_each = var.nsg_map
  name     = each.value.nsg_rg_name
}

data "azurerm_network_security_group" "nsg_rules" {
  for_each            = var.nsg_map
  name                = each.value.nsg_name
  resource_group_name = each.value.nsg_rg_name
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
        location = data.azurerm_resource_group.nsg_rules[nsg_key].location
        rg_name  = data.azurerm_resource_group.nsg_rules[nsg_key].name
      }
    ]
  ])

  asg_map = {
    for asg in local.asg_list : asg.key => asg
  }
}

data "azurerm_application_security_group" "nsg_rules" {
  for_each            = local.asg_map
  name                = each.value.name
  resource_group_name = each.value.rg_name
}

locals {
  rules_list = flatten([
    for nsg_key, nsg in var.nsg_map : [
      for rule in nsg.nsg_rules : merge(
        rule,
        { nsg_key = nsg_key },
        { nsg_name = nsg.nsg_name },
        { nsg_rg_name = nsg.nsg_rg_name },
      )
    ]
  ])

  rules_map = {
    for rule in local.rules_list : "${lower(rule.nsg_name)}_${lower(rule.direction)}_${lower(rule.priority)}" => rule
  }
}

resource "azurerm_network_security_rule" "nsg_rules" {
  for_each = local.rules_map

  priority    = each.value.priority
  name        = "${upper(each.value.nsg_key)}_${upper(each.value.name)}_${each.value.priority}"
  description = lookup(each.value, "description", null)

  access    = each.value.access
  direction = each.value.direction
  protocol  = lookup(each.value, "protocol", "*")

  source_port_range      = lookup(each.value, "source_port_range", "*")
  destination_port_range = lookup(each.value, "destination_port_range", "*")

  source_address_prefix      = lookup(each.value, "source_address_prefix", null)
  destination_address_prefix = lookup(each.value, "destination_address_prefix", null)

  source_application_security_group_ids      = lookup(each.value, "source_asg", null) == null ? [] : [data.azurerm_application_security_group.nsg_rules["${lower(each.value.nsg_key)}_${each.value.source_asg}"].id]
  destination_application_security_group_ids = lookup(each.value, "destination_asg", null) == null ? [] : [data.azurerm_application_security_group.nsg_rules["${lower(each.value.nsg_key)}_${each.value.destination_asg}"].id]

  resource_group_name         = each.value.nsg_rg_name
  network_security_group_name = each.value.nsg_name
}
