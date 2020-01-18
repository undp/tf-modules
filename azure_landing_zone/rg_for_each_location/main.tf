# Deploy RG in each location
resource "azurerm_resource_group" "rg_set" {
  for_each = {
    for loc in var.locations :
    loc => "${upper(var.namespace)}_${upper(var.name_prefix)}_${upper(loc)}"
  }
  name     = each.value
  location = each.key
  tags     = merge({ "Namespace" = "${title(var.namespace)}" }, "${var.tags}")
}
