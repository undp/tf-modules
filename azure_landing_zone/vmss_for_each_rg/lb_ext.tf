# Deploy Public IP for external LB in each regional RG
resource "azurerm_public_ip" "lb_ext" {
  for_each = local.enable_lb_ext ? var.region_rg_map : {}

  name = join("_", compact([
    lower(var.namespace),
    lower(lookup(
      var.conf_common, "name", lookup(lookup(
        var.conf_map, each.key, {}), "name",
        ""
    ))),
    lower(each.key),
    "lb_ext_pip"
  ]))

  resource_group_name = data.azurerm_resource_group.vmss[each.key].name
  location            = data.azurerm_resource_group.vmss[each.key].location

  domain_name_label = lower(replace(join("-", compact([
    var.namespace,
    lookup(var.conf_common, "name", lookup(lookup(
      var.conf_map, each.key, {}), "name",
      ""
    ))
  ])), "_", "-"))

  allocation_method = "Static"

  sku = "Standard"

  zones = local.enable_zone_specific ? [lookup(
    var.conf_common, "availability_zone", lookup(lookup(
      var.conf_map, each.key, {}), "availability_zone",
      1
  ))] : null

  tags = merge(
    { "Namespace" = "${title(var.namespace)}" },
    "${var.tags}"
  )
}

# Deploy LB for VMSS in each regional RG
resource "azurerm_lb" "ext" {
  for_each = local.enable_lb_ext ? var.region_rg_map : {}

  name = join("_", compact([
    lower(var.namespace),
    lower(lookup(
      var.conf_common, "name", lookup(lookup(
        var.conf_map, each.key, {}), "name",
        ""
    ))),
    lower(each.key),
    "lb_ext"
  ]))

  resource_group_name = data.azurerm_resource_group.vmss[each.key].name
  location            = data.azurerm_resource_group.vmss[each.key].location

  sku = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIP"
    public_ip_address_id = azurerm_public_ip.lb_ext[each.key].id
  }

  tags = merge(
    { "Namespace" = "${title(var.namespace)}" },
    "${var.tags}"
  )
}

# Deploy Backend Pool for LB in each regional RG
resource "azurerm_lb_backend_address_pool" "lb_ext" {
  for_each = local.enable_lb_ext ? var.region_rg_map : {}

  name = join("_", compact([
    lower(var.namespace),
    lower(lookup(
      var.conf_common, "name", lookup(lookup(
        var.conf_map, each.key, {}), "name",
        ""
    ))),
    lower(each.key),
    "lb_ext_backend"
  ]))

  resource_group_name = data.azurerm_resource_group.vmss[each.key].name
  loadbalancer_id     = azurerm_lb.ext[each.key].id
}


# Deploy TCP/22(SSH) Health Probe for external LB in each regional RG
resource "azurerm_lb_probe" "lb_ext_ssh" {
  for_each = local.enable_lb_ext ? var.region_rg_map : {}

  name = join("_", compact([
    lower(var.namespace),
    lower(lookup(
      var.conf_common, "name", lookup(lookup(
        var.conf_map, each.key, {}), "name",
        ""
      )
    )),
    lower(each.key),
    "lb_ext_probe_ssh"
  ]))

  resource_group_name = data.azurerm_resource_group.vmss[each.key].name
  loadbalancer_id     = azurerm_lb.ext[each.key].id

  protocol = "Tcp"
  port     = 22

  interval_in_seconds = 5
  number_of_probes    = 2
}

# Deploy TCP/22(SSH) external rule for LB in each regional RG
resource "azurerm_lb_rule" "lb_ext_ssh" {
  for_each = local.enable_lb_ext_rule_ssh ? var.region_rg_map : {}

  name = join("_", compact([
    lower(var.namespace),
    lower(lookup(
      var.conf_common, "name", lookup(lookup(
        var.conf_map, each.key, {}), "name",
        ""
    ))),
    lower(each.key),
    "lb_ext_rule_ssh"
  ]))

  resource_group_name = data.azurerm_resource_group.vmss[each.key].name

  loadbalancer_id         = azurerm_lb.ext[each.key].id
  backend_address_pool_id = azurerm_lb_backend_address_pool.lb_ext[each.key].id
  probe_id                = azurerm_lb_probe.lb_ext_ssh[each.key].id

  protocol      = "Tcp"
  frontend_port = 22
  backend_port  = 22

  frontend_ip_configuration_name = "PublicIP"
}

# Deploy NAT pool for SSH access to VMSS throgh LB in each regional RG
resource "azurerm_lb_nat_pool" "lb_ext_ssh" {
  for_each = local.enable_lb_ext_nat_ssh ? var.region_rg_map : {}

  name = join("_", compact([
    lower(var.namespace),
    lower(lookup(
      var.conf_common, "name", lookup(lookup(
        var.conf_map, each.key, {}), "name",
        ""
    ))),
    lower(each.key),
    "lb_ext_pool_ssh"
  ]))

  resource_group_name = data.azurerm_resource_group.vmss[each.key].name
  loadbalancer_id     = azurerm_lb.ext[each.key].id

  protocol            = "Tcp"
  frontend_port_start = 22000
  frontend_port_end = 22000 - 1 + lookup(
    var.conf_common, "vm_instances", lookup(lookup(
      var.conf_map, each.key, {}), "vm_instances",
      2
  ))

  backend_port = 22

  frontend_ip_configuration_name = "PublicIP"
}
