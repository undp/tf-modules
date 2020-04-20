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

# Deploy Health Probe for internal LB in each regional RG
resource "azurerm_lb_probe" "lb_int" {
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
    "lb_int_probe"
  ]))

  resource_group_name = data.azurerm_resource_group.vmss[each.key].name
  loadbalancer_id     = azurerm_lb.int[each.key].id

  protocol = lookup(
    var.conf_common, "probe_protocol", lookup(lookup(
      var.conf_map, each.key, {}), "probe_protocol",
      "Tcp"
  ))
  port = lookup(
    var.conf_common, "probe_port", lookup(lookup(
      var.conf_map, each.key, {}), "probe_port",
      22
  ))
  request_path = lower(lookup(
    var.conf_common, "probe_protocol", lookup(lookup(
      var.conf_map, each.key, {}), "probe_protocol",
      "Tcp"
    ))) != "tcp" ? lookup(
    var.conf_common, "probe_request_path", lookup(lookup(
      var.conf_map, each.key, {}), "probe_request_path",
      "/"
  )) : null

  interval_in_seconds = lookup(
    var.conf_common, "probe_interval", lookup(lookup(
      var.conf_map, each.key, {}), "probe_interval",
      15
  ))
  number_of_probes = lookup(
    var.conf_common, "probe_number", lookup(lookup(
      var.conf_map, each.key, {}), "probe_number",
      2
  ))
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
  probe_id                = azurerm_lb_probe.lb_int[each.key].id

  protocol                       = local.enable_lb_int_rule_ha ? "All" : "Tcp"
  frontend_ip_configuration_name = "InternalIP"
  frontend_port                  = local.enable_lb_int_rule_ha ? 0 : 22
  backend_port                   = local.enable_lb_int_rule_ha ? 0 : 22
}
