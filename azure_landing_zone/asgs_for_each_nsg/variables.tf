variable "nsg_map" {
  description = "Map of VNETs to NSG rules and corresponding RGs where they should be deployed."
  type = map(object({
    nsg_name    = string,
    nsg_rg_name = string,

    # should be `nsg_rules = list(any)` but elements are not uniformed
    # as required for `list()` since some rule poperties could be omitted
    # and in this case `list(any)` causes type check error
    nsg_rules = any,
  }))
  default = {
    vnet_A = {
      nsg_name    = "vnet_A_nsg"
      nsg_rg_name = "security_A"
      nsg_rules   = []
    }
    vnet_B = {
      nsg_name    = "vnet_B_nsg"
      nsg_rg_name = "securityB"
      nsg_rules   = []
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
