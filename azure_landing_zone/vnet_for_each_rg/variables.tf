variable "vnet_map" {
  description = "Map of VNET names to configurations to deploy in each RG."
  type = map(object({
    vnet_rg_name  = string, # RG name to deploy VNET into (defines VNET location)
    address_space = string, # Single CIDR prefix to use as VNET address space
    subnets = map(object({  # Map of objects describing subnet address spaces, [see cidrsubnet function][1] for more details
      bits  = number,       #   number of additional bits with which to extend the VNET's `address_space` CIDR prefix
      index = number,       #   subnet index number within `address_space + bits` CIDR prefix
      # [1]: https://www.terraform.io/docs/configuration/functions/cidrsubnet.html
      svc_endpoints = list(string), # list of Service Endpoints to associate with the subnet
    }))
  }))
  default = {
    vnet_name_A = {
      vnet_rg_name  = "rg1"
      address_space = "10.1.0.0/24"
      subnets = {
        dmz = {
          bits          = 1
          index         = 0
          svc_endpoints = []
        }
        management = {
          bits  = 1
          index = 1
          svc_endpoints = [
            "Microsoft.AzureActiveDirectory",
          ]
        }
      }
    }
    vnet_name_B = {
      vnet_rg_name  = "rg2"
      address_space = "10.2.0.0/24"
      subnets = {
        dmz = {
          bits          = 1
          index         = 0
          svc_endpoints = []
        }
      }
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
