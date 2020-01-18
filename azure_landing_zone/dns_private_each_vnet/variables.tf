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



variable "zone_name" {
  description = "Domain name for the Private DNS Zone."
  type        = string
  default     = ""
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
