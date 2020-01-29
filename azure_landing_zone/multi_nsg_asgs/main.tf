# Mix-in common security rules into the original `nsg_map`.
locals {
  nsg_map = {
    for nsg_key, nsg in var.nsg_map : nsg_key => merge(
      nsg,
      { nsg_rules = var.common_nsg_rules }
    )
  }
}

# Create common ASGs for each NSG.
module "common_asgs" {
  source = "../asgs_for_each_nsg"

  nsg_map = local.nsg_map

  namespace = var.namespace
  tags      = var.tags
}
