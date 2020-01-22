variable "vnet_map" {
  description = "Map of VNET names to RG names."
  type = map(object({
    vnet_rg_name = string,
  }))
  default = {
    vnet_hub_A = {
      vnet_rg_name = "rg1"
    }
    vnet_hub_B = {
      vnet_rg_name = "rg2"
    }
  }
}

variable "zone_suffix" {
  description = "Suffix for the Private Zone FQDN."
  type        = string
  default     = "space.link"
}

variable "zone_name" {
  description = "Zone name used before the `namespace` in the Private Zone FQDN."
  type        = string
  default     = ""
}

variable "registration_enabled" {
  description = "Is auto-registration of virtual machine records in the virtual network in the Private DNS zone enabled? Defaults to `false`."
  type        = bool
  default     = false
}

variable "namespace" {
  description = "Namespace used before the `zone_suffix` in the  Private Zone FQDN."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to be assigned to each deployed resource."
  type        = map(string)
  default     = {}
}
