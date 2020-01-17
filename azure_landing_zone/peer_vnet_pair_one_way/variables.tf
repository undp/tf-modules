variable "vnet_map_src" {
  description = "Map of src VNET names to establish peering from into RGs containing those VNETs."
  type = map(object({
    vnet_rg_name = string,
  }))
  default = {
    key_A = {
      vnet_rg_name = "A_1_rg"
    }
    key_B = {
      vnet_rg_name = "B_1_rg"
    }
  }
}

variable "vnet_map_dst" {
  description = "Map of dst VNET names to establish peering to into RGs containing those VNETs."
  type = map(object({
    vnet_rg_name = string,
  }))
  default = {
    key_A = {
      vnet_rg_name = "A_2_rg"
    }
    key_B = {
      vnet_rg_name = "B_2_rg"
    }
  }
}

variable "name_prefix_src" {
  description = "Prefix to use for discovery of src VNET names."
  type        = string
  default     = "spoke"
}

variable "name_prefix_dst" {
  description = "Prefix to use for discovery of dst VNET names."
  type        = string
  default     = "hub"
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
