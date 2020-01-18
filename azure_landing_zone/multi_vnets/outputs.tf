output "vnet_map" {
  description = "Map of VNET names to RGs"
  value = {
    for vnet_key, vnet in local.vnet_map : vnet_key => {
      vnet_rg_name = vnet.vnet_rg_name
    }
  }
}
