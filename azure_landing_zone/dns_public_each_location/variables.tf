variable "zone_rg" {
  description = "RG name to deploy the main Public Zone."
  type        = string
  default     = "bootstrap"
}

variable "region_map_rgs" {
  description = "Map of locations to RG names where regional subdomains of the main Public Zone are deployed."
  type        = map(string)
  default = {
    westeurope  = "rg1"
    northeurope = "rg2"
  }
}

variable "zone_suffix" {
  description = "Suffix for the Public Zone FQDN."
  type        = string
  default     = "space.link"
}

variable "zone_name" {
  description = "Zone name used before the `namespace` in the Public Zone FQDN."
  type        = string
  default     = ""
}

variable "namespace" {
  description = "Namespace used before the `zone_suffix` in the Public Zone FQDN."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to be assigned to each deployed resource."
  type        = map(string)
  default     = {}
}
