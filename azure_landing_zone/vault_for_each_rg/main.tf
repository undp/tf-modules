# Get existing regional RG parameters as data objects
data "azurerm_resource_group" "region_rg" {
  for_each = var.region_rg_map
  name     = each.value
}

# Get current Azure client config
data "azurerm_client_config" "current" {
}

# Deploy Key Vault in each regional RG
resource "azurerm_key_vault" "region_key_vault" {
  for_each = var.region_rg_map

  name = lower(join("-", compact([
    var.namespace,
    lookup(
      var.conf_common, "name", lookup(lookup(
        var.conf_map, each.key, {}), "name",
        ""
    )),
    each.key,
  ])))

  resource_group_name = data.azurerm_resource_group.region_rg[each.key].name
  location            = data.azurerm_resource_group.region_rg[each.key].location

  enabled_for_deployment = lookup(
    var.conf_common, "enabled_for_deployment", lookup(lookup(
      var.conf_map, each.key, {}), "enabled_for_deployment",
      false
  ))
  enabled_for_disk_encryption = lookup(
    var.conf_common, "enabled_for_disk_encryption", lookup(lookup(
      var.conf_map, each.key, {}), "enabled_for_disk_encryption",
      false
  ))
  enabled_for_template_deployment = lookup(
    var.conf_common, "enabled_for_template_deployment", lookup(lookup(
      var.conf_map, each.key, {}), "enabled_for_template_deployment",
      false
  ))

  purge_protection_enabled = lookup(
    var.conf_common, "purge_protection_enabled", lookup(lookup(
      var.conf_map, each.key, {}), "purge_protection_enabled",
      false
  ))

  sku_name = lookup(
    var.conf_common, "sku_name", lookup(lookup(
      var.conf_map, each.key, {}), "sku_name",
      "standard"
  ))

  soft_delete_enabled = lookup(
    var.conf_common, "soft_delete_enabled", lookup(lookup(
      var.conf_map, each.key, {}), "soft_delete_enabled",
      false
  ))

  tenant_id = lookup(
    var.conf_common, "tenant_id", lookup(lookup(
      var.conf_map, each.key, {}), "tenant_id",
      data.azurerm_client_config.current.tenant_id
  ))

  network_acls {
    bypass = lookup(
      var.conf_common, "acls_bypass", lookup(lookup(
        var.conf_map, each.key, {}), "acls_bypass",
        "AzureServices"
    ))

    default_action = lookup(
      var.conf_common, "acls_default_action", lookup(lookup(
        var.conf_map, each.key, {}), "acls_default_action",
        "Allow"
    ))

    ip_rules = lookup(
      var.conf_common, "acls_ip_rules", lookup(lookup(
        var.conf_map, each.key, {}), "acls_ip_rules",
        []
    ))

    virtual_network_subnet_ids = lookup(
      var.conf_common, "acls_subnet_ids", lookup(lookup(
        var.conf_map, each.key, {}), "acls_subnet_ids",
        []
    ))

  }

  tags = merge(
    { "Namespace" = "${title(var.namespace)}" },
    "${var.tags}"
  )
}

# Deploy `azurerm_client_config` access policy for each regional Key Vault
resource "azurerm_key_vault_access_policy" "azurerm_client_config" {
  for_each = var.region_rg_map

  key_vault_id = azurerm_key_vault.region_key_vault[each.key].id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = data.azurerm_client_config.current.object_id

  certificate_permissions = [
    "create",
    "delete",
    "deleteissuers",
    "get",
    "getissuers",
    "import",
    "list",
    "listissuers",
    "managecontacts",
    "manageissuers",
    "setissuers",
    "update",
  ]

  key_permissions = [
  ]

  secret_permissions = [
    "get",
  ]

  storage_permissions = [
  ]
}

# Deploy user assigned identity for `read-only` access to each regional Key Vault
resource "azurerm_user_assigned_identity" "region_identity_reader" {
  for_each = var.region_rg_map

  resource_group_name = data.azurerm_resource_group.region_rg[each.key].name
  location            = data.azurerm_resource_group.region_rg[each.key].location

  name = lower(join("_", compact([
    var.namespace,
    lookup(
      var.conf_common, "name", lookup(lookup(
        var.conf_map, each.key, {}), "name",
        ""
    )),
    each.key,
    "reader_uai"
  ])))
}

# Deploy `read-only` access policy for each regional Key Vault
resource "azurerm_key_vault_access_policy" "reader" {
  for_each = var.region_rg_map

  key_vault_id = azurerm_key_vault.region_key_vault[each.key].id

  tenant_id = lookup(
    var.conf_common, "tenant_id", lookup(lookup(
      var.conf_map, each.key, {}), "tenant_id",
      data.azurerm_client_config.current.tenant_id
  ))
  object_id = azurerm_user_assigned_identity.region_identity_reader[each.key].principal_id

  certificate_permissions = [
    "get",
  ]

  key_permissions = [
    "get",
  ]

  secret_permissions = [
    "get",
  ]

  storage_permissions = [
    "get",
  ]
}

# Deploy user assigned identity for `admin` access to each regional Key Vault
resource "azurerm_user_assigned_identity" "region_identity_admin" {
  for_each = var.region_rg_map

  resource_group_name = data.azurerm_resource_group.region_rg[each.key].name
  location            = data.azurerm_resource_group.region_rg[each.key].location

  name = lower(join("_", compact([
    var.namespace,
    lookup(
      var.conf_common, "name", lookup(lookup(
        var.conf_map, each.key, {}), "name",
        ""
    )),
    each.key,
    "admin_uai"
  ])))
}

# Deploy `admin` access policy for each regional Key Vault
resource "azurerm_key_vault_access_policy" "admin" {
  for_each = var.region_rg_map

  key_vault_id = azurerm_key_vault.region_key_vault[each.key].id

  tenant_id = lookup(
    var.conf_common, "tenant_id", lookup(lookup(
      var.conf_map, each.key, {}), "tenant_id",
      data.azurerm_client_config.current.tenant_id
  ))
  object_id = azurerm_user_assigned_identity.region_identity_admin[each.key].principal_id

  certificate_permissions = [
    "backup",
    "create",
    "delete",
    "deleteissuers",
    "get",
    "getissuers",
    "import",
    "list",
    "listissuers",
    "managecontacts",
    "manageissuers",
    "purge",
    "recover",
    "restore",
    "setissuers",
    "update"
  ]

  key_permissions = [
    "backup",
    "create",
    "decrypt",
    "delete",
    "encrypt",
    "get",
    "import",
    "list",
    "purge",
    "recover",
    "restore",
    "sign",
    "unwrapKey",
    "update",
    "verify",
    "wrapKey",
  ]

  secret_permissions = [
    "backup",
    "delete",
    "get",
    "list",
    "purge",
    "recover",
    "restore",
    "set",
  ]

  storage_permissions = [
    "backup",
    "delete",
    "deletesas",
    "get",
    "getsas",
    "list",
    "listsas",
    "purge",
    "recover",
    "regeneratekey",
    "restore",
    "set",
    "setsas",
    "update",
  ]
}
