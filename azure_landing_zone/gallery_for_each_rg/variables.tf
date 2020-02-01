variable "region_rg_map" {
  description = "Map of locations to RG names where resoures are deployed for each region."
  type        = map(string)
  default = {
    westeurope  = "rg1"
    northeurope = "rg2"
  }
}

variable "conf_common" {
  description = "Common configuration parameters applied for each regional resource."
  type        = any
  default     = {}
}

variable "conf_map" {
  description = "Map of parameters specific to each resource deployed in a region."
  type        = any
  default     = {}
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
