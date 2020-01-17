variable "nsg_map" {
  description = "Map of NSG parameters."
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
      nsg_rules = [
        # TODO:20200103:001
        #   If uncommented, crashes Terraform v0.12.18 run through Terragrunt v0.21.10
        #
        # {
        #   name                   = "DENY_ANY_TO_QUARANTINE"
        #   priority               = 100
        #   access                 = "Deny"
        #   direction              = "Inbound"
        #   source_address_prefix  = "*"
        #   destination_asg        = "quarantine"
        # },
      ]
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
