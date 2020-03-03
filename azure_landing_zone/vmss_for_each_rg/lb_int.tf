# Deploy internal LB for VMSS in each regional RG
resource "azurerm_lb" "int" {
  for_each = var.region_rg_map

  name = join("_", compact([
    lower(var.namespace),
    lower(lookup(
      var.conf_common, "name", lookup(lookup(
        var.conf_map, each.key, {}), "name",
        ""
    ))),
    lower(each.key),
    "lb_int"
  ]))

  resource_group_name = data.azurerm_resource_group.vmss[each.key].name
  location            = data.azurerm_resource_group.vmss[each.key].location

  sku = "Standard"

  frontend_ip_configuration {
    name      = "InternalIP"
    subnet_id = data.azurerm_subnet.vmss[each.key].id

    private_ip_address_allocation = "Dynamic"

    zones = local.enable_zone_specific ? [lookup(
      var.conf_common, "availability_zone", lookup(lookup(
        var.conf_map, each.key, {}), "availability_zone",
        1
    ))] : null
  }

  tags = merge(
    { "Namespace" = "${title(var.namespace)}" },
    "${var.tags}"
  )
}

# Deploy Backend Pool for internal LB in each regional RG
resource "azurerm_lb_backend_address_pool" "lb_int" {
  for_each = var.region_rg_map

  name = join("_", compact([
    lower(var.namespace),
    lower(lookup(
      var.conf_common, "name", lookup(lookup(
        var.conf_map, each.key, {}), "name",
        ""
    ))),
    lower(each.key),
    "lb_int_backend"
  ]))

  resource_group_name = data.azurerm_resource_group.vmss[each.key].name
  loadbalancer_id     = azurerm_lb.int[each.key].id
}

# Deploy TCP/22(SSH) Health Probe for internal LB in each regional RG
resource "azurerm_lb_probe" "lb_int_ssh" {
  for_each = var.region_rg_map

  name = join("_", compact([
    lower(var.namespace),
    lower(lookup(
      var.conf_common, "name", lookup(lookup(
        var.conf_map, each.key, {}), "name",
        ""
      )
    )),
    lower(each.key),
    "lb_int_probe_ssh"
  ]))

  resource_group_name = data.azurerm_resource_group.vmss[each.key].name
  loadbalancer_id     = azurerm_lb.int[each.key].id

  protocol = "Tcp"
  port     = 22

  interval_in_seconds = 5
  number_of_probes    = 2
}

# Deploy rule for internal LB in each regional RG
# to either balance TCP/22(SSH) or implement HA Ports
resource "azurerm_lb_rule" "lb_int" {
  for_each = var.region_rg_map

  name = join("_", compact([
    lower(var.namespace),
    lower(lookup(
      var.conf_common, "name", lookup(lookup(
        var.conf_map, each.key, {}), "name",
        ""
    ))),
    lower(each.key),
    local.enable_lb_int_rule_ha ? "lb_int_rule_ha" : "lb_int_rule_ssh"
  ]))

  resource_group_name = data.azurerm_resource_group.vmss[each.key].name

  loadbalancer_id         = azurerm_lb.int[each.key].id
  backend_address_pool_id = azurerm_lb_backend_address_pool.lb_int[each.key].id
  probe_id                = azurerm_lb_probe.lb_int_ssh[each.key].id

  protocol                       = local.enable_lb_int_rule_ha ? "All" : "Tcp"
  frontend_ip_configuration_name = "InternalIP"
  frontend_port                  = local.enable_lb_int_rule_ha ? 0 : 22
  backend_port                   = local.enable_lb_int_rule_ha ? 0 : 22
}
