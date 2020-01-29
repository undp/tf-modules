variable "nsg_map" {
  description = "Map of VNET names to corresponding NSG names and RGs."
  type = map(object({
    nsg_name    = string,
    nsg_rg_name = string,
  }))
  default = {
    vnet_A = {
      nsg_name    = "vnet_A_nsg"
      nsg_rg_name = "security_A"
    }
    vnet_B = {
      nsg_name    = "vnet_B_nsg"
      nsg_rg_name = "security_B"
    }
  }
}

variable "common_nsg_rules" {
  description = "Security rules to be deployed for all NSGs."
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
