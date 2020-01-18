variable "region_map_rgs" {
  description = "Map of locations to RG names where VNETs are deployed for each region."
  type        = map(string)
  default = {
    westeurope  = "rg1"
    northeurope = "rg2"
  }
}

variable "region_map_vnets" {
  description = "Map of locations to VNET address spaces within the region."
  type        = map(map(string))
  default = {
    westeurope = {
      vnet_prod = "10.1.0.0/24"
      vnet_test = "10.1.1.0/24"
    }
    northeurope = {
      vnet_prod = "10.2.0.0/24"
      vnet_test = "10.2.1.0/24"
    }
  }
}

variable "common_subnets" {
  description = "Map of subnet names to address allocations common for all deployed VNETs."
  type = map(object({
    bits          = number,
    index         = number,
    svc_endpoints = list(string),
  }))
  default = {
    dmz = {
      bits          = 1
      index         = 0
      svc_endpoints = []
    }
    workloads = {
      bits          = 1
      index         = 1
      svc_endpoints = []
    }
  }
}

variable "common_nsg_rules" {
  description = "Security rules common for all deployed VNETs."
  type        = any
  default = [
    {
      name                  = "DENY_ANY_TO_QUARANTINE"
      priority              = 100
      access                = "Deny"
      direction             = "Inbound"
      source_address_prefix = "*"
      destination_asg       = "quarantine"
    },
    {
      name                       = "DENY_ANY_FROM_QUARANTINE"
      priority                   = 100
      access                     = "Deny"
      direction                  = "Outbound"
      destination_address_prefix = "*"
      source_asg                 = "quarantine"
    },
  ]
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
