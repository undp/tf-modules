output "lb_ext_id_map" {
  description = "Map of external LB IDs to corresponding name and resource group."
  value = {
    for key, lb_ext in azurerm_lb.int : lb_ext.id => {
      name                = lb_ext.name
      resource_group_name = lb_ext.resource_group_name
    }
  }
}

output "lb_ext_obj_map" {
  description = "Map of `region_rg_map.key` to all external LB resource properties."
  value       = azurerm_lb.ext
}

output "lb_ext_backend_id_map" {
  description = "Map of external LB Backend IDs to corresponding name and LB ID."
  value = {
    for key, lb_ext_backend in azurerm_lb_backend_address_pool.lb_ext : lb_ext_backend.id => {
      name            = lb_ext_backend.name
      loadbalancer_id = lb_ext_backend.loadbalancer_id
    }
  }
}

output "lb_ext_backend_obj_map" {
  description = "Map of `region_rg_map.key` to all external LB Backend resource properties."
  value       = azurerm_lb_backend_address_pool.lb_ext
}

output "lb_int_id_map" {
  description = "Map of internal LB IDs to corresponding name and resource group."
  value = {
    for key, lb_int in azurerm_lb.int : lb_int.id => {
      name                = lb_int.name
      resource_group_name = lb_int.resource_group_name
    }
  }
}

output "lb_int_obj_map" {
  description = "Map of `region_rg_map.key` to all internal LB resource properties."
  value       = azurerm_lb.int
}

output "lb_int_backend_id_map" {
  description = "Map of internal LB Backend IDs to corresponding name and LB ID."
  value = {
    for key, lb_int_backend in azurerm_lb_backend_address_pool.lb_int : lb_int_backend.id => {
      name            = lb_int_backend.name
      loadbalancer_id = lb_int_backend.loadbalancer_id
    }
  }
}

output "lb_int_backend_obj_map" {
  description = "Map of `region_rg_map.key` to all internal LB Backend resource properties."
  value       = azurerm_lb_backend_address_pool.lb_int
}

output "prefix_id_map" {
  description = "Map of PIP Prefix IDs to corresponding name and resource group."
  value = {
    for key, prefix in azurerm_public_ip_prefix.vmss : prefix.id => {
      name                = prefix.name
      resource_group_name = prefix.resource_group_name
    }
  }
}

output "prefix_obj_map" {
  description = "Map of `region_rg_map.key` to all PIP Prefix resource properties."
  value       = azurerm_public_ip_prefix.vmss
}

output "vmss_id_map" {
  description = "Map of VMSS IDs to corresponding name and resource group."
  value = {
    for key, vmss in azurerm_linux_virtual_machine_scale_set.vmss : vmss.id => {
      name                = vmss.name
      resource_group_name = vmss.resource_group_name
    }
  }
}

output "vmss_obj_map" {
  description = "Map of `region_rg_map.key` to all VMSS resource properties."
  value       = azurerm_linux_virtual_machine_scale_set.vmss
}
