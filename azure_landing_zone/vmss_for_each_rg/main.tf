# Ensure all module-wide options are properly defiened
locals {
  enable_const_capacity  = lookup(var.conf_module, "enable_const_capacity", false)
  enable_lb_ext          = lookup(var.conf_module, "enable_lb_ext", false)
  enable_lb_ext_nat_ssh  = local.enable_lb_ext ? lookup(var.conf_module, "enable_lb_ext_nat_ssh", false) : false
  enable_lb_ext_rule_ssh = local.enable_lb_ext && ! local.enable_lb_ext_nat_ssh
  enable_lb_int_rule_ha  = lookup(var.conf_module, "enable_lb_int_rule_ha", false)
  enable_pip_per_vm      = lookup(var.conf_module, "enable_pip_per_vm", false)
  enable_pip_prefix      = local.enable_pip_per_vm ? lookup(var.conf_module, "enable_pip_prefix", false) : false
  enable_zone_redundant  = lookup(var.conf_module, "enable_zone_redundant", false)
  enable_zone_specific   = local.enable_zone_redundant ? false : lookup(var.conf_module, "enable_zone_specific", false)
}

# Get existing regional RGs
data "azurerm_resource_group" "vmss" {
  for_each = var.region_rg_map
  name     = each.value
}

# Get existing subnets
data "azurerm_subnet" "vmss" {
  for_each = var.region_rg_map

  name = lookup(
    var.conf_common, "subnet_name", lookup(lookup(
      var.conf_map, each.key, {}), "subnet_name",
      null
  ))

  resource_group_name = join("_", compact([
    lower(var.namespace),
    lower(lookup(
      var.conf_common, "vnet_rg_name", lookup(lookup(
        var.conf_map, each.key, {}), "vnet_rg_name",
        null
    ))),
    lower(each.key)
  ]))

  virtual_network_name = join("_", compact([
    lower(var.namespace),
    lower(lookup(
      var.conf_common, "vnet_name", lookup(lookup(
        var.conf_map, each.key, {}), "vnet_name",
        null
    ))),
    lower(each.key),
    "vnet"
  ]))
}

# Generate flat map of ASGs to be assigned to VMSS instances
locals {
  region_asg_map = {
    for region in keys(var.region_rg_map) : region => {
      asg_list = lookup(
        var.conf_common, "asg_list", lookup(lookup(
          var.conf_map, region, {}), "asg_list",
          []
        )
      )
      asg_rg = lookup(
        var.conf_common, "asg_rg", lookup(lookup(
          var.conf_map, region, {}), "asg_rg",
          null
        )
      )
    }
  }

  region_asg_list = flatten([
    for asg_key, asg_set in local.region_asg_map : [
      for asg_name in asg_set.asg_list : {
        key     = lower("${asg_key}_${asg_set.asg_rg}_${asg_name}")
        rg_name = asg_set.asg_rg
        name    = asg_name
        region  = asg_key
      }
    ]
  ])

  asg_map = {
    for asg in local.region_asg_list : asg.key => asg
  }
}

# Get existing ASGs
data "azurerm_application_security_group" "vmss" {
  for_each = local.asg_map

  name = each.value.name

  resource_group_name = join("_", compact([
    lower(var.namespace),
    lower(each.value.rg_name),
    lower(each.value.region)
  ]))
}

# Generate map of existing ASG IDs by region
locals {
  region_asg_ids = {
    for asg_key, asg in data.azurerm_application_security_group.vmss :
    local.asg_map[asg_key].region => asg.id...
  }
}

# Deploy Public IP prefix for direct use by VMSS in each regional RG
resource "azurerm_public_ip_prefix" "vmss" {
  for_each = local.enable_pip_prefix ? var.region_rg_map : {}

  name = join("_", compact([
    lower(var.namespace),
    lower(lookup(
      var.conf_common, "name", lookup(lookup(
        var.conf_map, each.key, {}), "name",
        ""
    ))),
    lower(each.key),
    "prefix"
  ]))

  resource_group_name = data.azurerm_resource_group.vmss[each.key].name
  location            = data.azurerm_resource_group.vmss[each.key].location

  sku = "Standard"

  zones = local.enable_zone_specific ? [lookup(
    var.conf_common, "availability_zone", lookup(lookup(
      var.conf_map, each.key, {}), "availability_zone",
      1
    )
  )] : null

  prefix_length = 32 - ceil(log(lookup(
    var.conf_common, "vm_instances", lookup(lookup(
      var.conf_map, each.key, {}), "vm_instances",
      2
  )), 2))

  tags = merge(
    { "Namespace" = "${title(var.namespace)}" },
    "${var.tags}"
  )
}

# Deploy VMSS in each regional RG
resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
  for_each = var.region_rg_map

  name = join("_", compact([
    lower(var.namespace),
    lower(lookup(
      var.conf_common, "name", lookup(lookup(
        var.conf_map, each.key, {}), "name",
        ""
    ))),
    lower(each.key),
    "vmss"
  ]))

  resource_group_name = data.azurerm_resource_group.vmss[each.key].name
  location            = data.azurerm_resource_group.vmss[each.key].location

  custom_data = lookup(
    var.conf_common, "custom_data", lookup(lookup(
      var.conf_map, each.key, {}), "custom_data",
      null
  ))

  computer_name_prefix = lookup(
    var.conf_common, "computer_name_prefix", lookup(lookup(
      var.conf_map, each.key, {}), "computer_name_prefix",
      null
  ))

  sku = lookup(
    var.conf_common, "vm_size", lookup(lookup(
      var.conf_map, each.key, {}), "vm_size",
      null
  ))

  zones = local.enable_zone_redundant && ! local.enable_pip_prefix ? lookup(
    var.conf_common, "zones", lookup(lookup(
      var.conf_map, each.key, {}), "zones",
      []
      )) : local.enable_zone_specific && ! local.enable_pip_prefix ? [lookup(
      var.conf_common, "availability_zone", lookup(lookup(
        var.conf_map, each.key, {}), "availability_zone",
        1
  ))] : null

  zone_balance = local.enable_zone_redundant ? lookup(
    var.conf_common, "zone_balance", lookup(lookup(
      var.conf_map, each.key, {}), "zone_balance",
      true
  )) : null

  instances = lookup(
    var.conf_common, "vm_instances", lookup(lookup(
      var.conf_map, each.key, {}), "vm_instances",
      2
  ))

  overprovision = lookup(
    var.conf_common, "overprovision", lookup(lookup(
      var.conf_map, each.key, {}), "overprovision",
      false
  ))

  priority = lookup(
    var.conf_common, "priority", lookup(lookup(
      var.conf_map, each.key, {}), "priority",
      "Regular"
  ))
  eviction_policy = lookup(
    var.conf_common, "priority", lookup(lookup(
      var.conf_map, each.key, {}), "priority",
      "Regular"
    )) == "Spot" ? lookup(
    var.conf_common, "eviction_policy", lookup(lookup(
      var.conf_map, each.key, {}), "eviction_policy",
      "Delete"
  )) : null

  admin_username = lookup(
    var.conf_common, "admin_username", lookup(lookup(
      var.conf_map, each.key, {}), "admin_username",
      "vmssadmin"
  ))

  admin_password                  = null
  disable_password_authentication = true

  admin_ssh_key {
    username = lookup(
      var.conf_common, "admin_username", lookup(lookup(
        var.conf_map, each.key, {}), "admin_username",
        "vmssadmin"
    ))
    public_key = lookup(
      var.conf_common, "public_key", lookup(lookup(
        var.conf_map, each.key, {}), "public_key",
        null
    ))
  }

  provision_vm_agent = lookup(
    var.conf_common, "provision_vm_agent", lookup(lookup(
      var.conf_map, each.key, {}), "provision_vm_agent",
      true
  ))

  source_image_id = lookup(
    var.conf_common, "image_id", lookup(lookup(
      var.conf_map, each.key, {}), "image_id",
      null
  ))

  dynamic "source_image_reference" {
    for_each = lookup(
      var.conf_common, "image_id", lookup(lookup(
        var.conf_map, each.key, {}), "image_id",
        null
    )) == null ? { 1 = 1 } : {}

    content {
      publisher = lookup(
        var.conf_common, "image_publisher", lookup(lookup(
          var.conf_map, each.key, {}), "image_publisher",
          null
      ))
      offer = lookup(
        var.conf_common, "image_offer", lookup(lookup(
          var.conf_map, each.key, {}), "image_offer",
          null
      ))
      sku = lookup(
        var.conf_common, "image_sku", lookup(lookup(
          var.conf_map, each.key, {}), "image_sku",
          null
      ))
      version = lookup(
        var.conf_common, "image_version", lookup(lookup(
          var.conf_map, each.key, {}), "image_version",
          null
      ))
    }
  }

  os_disk {
    caching = lookup(
      var.conf_common, "os_disk_ephemeral", lookup(lookup(
        var.conf_map, each.key, {}), "os_disk_ephemeral",
        false
      )) ? "ReadOnly" : lookup(
      var.conf_common, "os_disk_caching", lookup(lookup(
        var.conf_map, each.key, {}), "os_disk_caching",
        "None"
    ))
    storage_account_type = lookup(
      var.conf_common, "os_disk_ephemeral", lookup(lookup(
        var.conf_map, each.key, {}), "os_disk_ephemeral",
        false
      )) ? "Standard_LRS" : lookup(
      var.conf_common, "os_disk_type", lookup(lookup(
        var.conf_map, each.key, {}), "os_disk_type",
        "Standard_LRS"
    ))

    dynamic "diff_disk_settings" {
      for_each = lookup(
        var.conf_common, "os_disk_ephemeral", lookup(lookup(
          var.conf_map, each.key, {}), "os_disk_ephemeral",
          false
      )) ? { 1 = 1 } : {}

      content {
        option = "Local"
      }
    }
  }

  dynamic "data_disk" {
    for_each = zipmap(
      range(lookup(
        var.conf_common, "data_disk_disk_count", lookup(lookup(
          var.conf_map, each.key, {}), "data_disk_disk_count",
          0
      ))),
      range(lookup(
        var.conf_common, "data_disk_disk_count", lookup(lookup(
          var.conf_map, each.key, {}), "data_disk_disk_count",
          0
      )))
    )
    content {
      lun = data_disk.key
      caching = lookup(
        var.conf_common, "data_disk_caching", lookup(lookup(
          var.conf_map, each.key, {}), "data_disk_caching",
          "None"
      ))
      storage_account_type = lookup(
        var.conf_common, "data_disk_type", lookup(lookup(
          var.conf_map, each.key, {}), "data_disk_type",
          "Standard_LRS"
      ))
      disk_size_gb = lookup(
        var.conf_common, "data_disk_disk_size_gb", lookup(lookup(
          var.conf_map, each.key, {}), "data_disk_disk_size_gb",
          10
      ))
    }
  }

  network_interface {
    name    = "primary_nic"
    primary = true

    enable_ip_forwarding = lookup(
      var.conf_common, "enable_ip_forwarding", lookup(lookup(
        var.conf_map, each.key, {}), "enable_ip_forwarding",
        false
    ))

    ip_configuration {
      name      = "primary_ip_config"
      primary   = true
      subnet_id = data.azurerm_subnet.vmss[each.key].id

      load_balancer_backend_address_pool_ids = concat(
        [azurerm_lb_backend_address_pool.lb_int[each.key].id],
        local.enable_lb_ext ? [azurerm_lb_backend_address_pool.lb_ext[each.key].id] : [],
      )

      load_balancer_inbound_nat_rules_ids = concat(
        local.enable_lb_ext_nat_ssh ? [azurerm_lb_nat_pool.lb_ext_ssh[each.key].id] : [],
      )

      application_security_group_ids = lookup(local.region_asg_ids, each.key, [])

      dynamic "public_ip_address" {
        for_each = local.enable_pip_per_vm ? { 1 = 1 } : {}

        content {
          name = local.enable_pip_prefix ? "pip_prefix" : "pip_direct"

          domain_name_label = lower(replace(join("-", compact([
            var.namespace,
            lookup(var.conf_common, "name", lookup(lookup(
              var.conf_map, each.key, {}), "name",
              ""
            )),
            "vmss"
          ])), "_", "-"))

          public_ip_prefix_id = local.enable_pip_prefix ? azurerm_public_ip_prefix.vmss[each.key].id : null
        }
      }
    }
  }

  upgrade_mode = lookup(
    var.conf_common, "upgrade_mode", lookup(lookup(
      var.conf_map, each.key, {}), "upgrade_mode",
      "Automatic"
  ))

  health_probe_id = lookup(
    var.conf_common, "upgrade_mode", lookup(lookup(
      var.conf_map, each.key, {}), "upgrade_mode",
      "Automatic"
  )) != "Manual" ? azurerm_lb_probe.lb_int_ssh[each.key].id : null

  dynamic "automatic_os_upgrade_policy" {
    for_each = lookup(
      var.conf_common, "upgrade_mode", lookup(lookup(
        var.conf_map, each.key, {}), "upgrade_mode",
        "Automatic"
    )) != "Manual" ? { 1 = 1 } : {}

    content {
      disable_automatic_rollback  = false
      enable_automatic_os_upgrade = true
    }
  }

  dynamic "rolling_upgrade_policy" {
    for_each = lookup(
      var.conf_common, "upgrade_mode", lookup(lookup(
        var.conf_map, each.key, {}), "upgrade_mode",
        "Automatic"
    )) != "Manual" ? { 1 = 1 } : {}

    content {
      max_batch_instance_percent = lookup(
        var.conf_common, "rolling_upgrade_max_batch", lookup(lookup(
          var.conf_map, each.key, {}), "rolling_upgrade_max_batch",
          20
      ))
      max_unhealthy_instance_percent = lookup(
        var.conf_common, "rolling_upgrade_max_unhealthy", lookup(lookup(
          var.conf_map, each.key, {}), "rolling_upgrade_max_unhealthy",
          20
      ))
      max_unhealthy_upgraded_instance_percent = lookup(
        var.conf_common, "rolling_upgrade_max_unhealthy_upgraded", lookup(lookup(
          var.conf_map, each.key, {}), "rolling_upgrade_max_unhealthy_upgraded",
          20
      ))
      pause_time_between_batches = lookup(
        var.conf_common, "rolling_upgrade_pause_time", lookup(lookup(
          var.conf_map, each.key, {}), "rolling_upgrade_pause_time",
          "PT30S"
      ))
    }
  }

  tags = merge(
    { "Namespace" = "${title(var.namespace)}" },
    "${var.tags}"
  )

  # Since these can change via auto-scaling outside of Terraform,
  # let's ignore any changes to the number of instances
  lifecycle {
    ignore_changes = [
      instances
    ]
  }

  # VMSS requires health probe that is used by some LB rule.
  # This creates implicity dependency on the LB rule that must
  # be identified explicitly.
  depends_on = [
    azurerm_lb_rule.lb_int
  ]
}

# Deploy auto-scaling profile to keep constant # of instances  in each regional RG
resource "azurerm_monitor_autoscale_setting" "vmss" {
  for_each = local.enable_const_capacity ? var.region_rg_map : {}

  name = join("_", compact([
    lower(var.namespace),
    lower(lookup(
      var.conf_common, "name", lookup(lookup(
        var.conf_map, each.key, {}), "name",
        ""
    ))),
    lower(each.key),
    "autoscale"
  ]))

  resource_group_name = data.azurerm_resource_group.vmss[each.key].name
  location            = data.azurerm_resource_group.vmss[each.key].location

  target_resource_id = azurerm_linux_virtual_machine_scale_set.vmss[each.key].id

  profile {
    name = "ConstantCapacity"

    capacity {
      default = lookup(
        var.conf_common, "vm_instances", lookup(lookup(
          var.conf_map, each.key, {}), "vm_instances",
          2
      ))
      minimum = lookup(
        var.conf_common, "vm_instances", lookup(lookup(
          var.conf_map, each.key, {}), "vm_instances",
          2
      ))
      maximum = lookup(
        var.conf_common, "vm_instances", lookup(lookup(
          var.conf_map, each.key, {}), "vm_instances",
          2
      ))
    }
  }
}
