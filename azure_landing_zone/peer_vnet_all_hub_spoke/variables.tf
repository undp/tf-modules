variable "vnet_map_hub" {
  description = "Map of hub VNET names to RG names."
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

variable "vnet_map_spoke" {
  description = "Map of spoke VNET names to RG names."
  type = map(object({
    vnet_rg_name = string,
  }))
  default = {
    vnet_spoke_A = {
      vnet_rg_name = "rg1"
    }
    vnet_spoke_B = {
      vnet_rg_name = "rg2"
    }
  }
}

variable "namespace" {
  description = "Namespace to use in resource names and tags."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to be assigned to each deployed resource."
  type        = map(string)
  default     = {}
}
