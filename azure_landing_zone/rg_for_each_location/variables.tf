variable "locations" {
  description = "List of Azure locations to deploy RGs. Use only one-word names (e.g. `westeurope` and not `West Europe`)"
  type        = list(string)
  default     = []
}

variable "name_prefix" {
  description = "Prefix to add to all RG names."
  type        = string
  default     = "space"
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
