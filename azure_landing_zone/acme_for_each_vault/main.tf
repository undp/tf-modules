# Ensure all module-wide options are properly defined
locals {
  enable_staging_api = lookup(var.conf_module, "enable_staging_api", false)
  acme_server        = local.enable_staging_api ? "acme-staging" : "acme"
  acme_url           = "https://${local.acme_server}-v02.api.letsencrypt.org/directory"

  enable_exec_dns_challenge = lookup(var.conf_module, "enable_exec_dns_challenge", false)
  enable_common_certs = lookup(var.conf_module, "enable_common_certs", false)
  enable_fqdn_target  = local.enable_common_certs || lookup(var.conf_module, "enable_fqdn_target", false)
  enable_full_rg_name = local.enable_common_certs || lookup(var.conf_module, "enable_full_rg_name", false)
}

# Use TLS provider to generate a private key for ACME account
provider "tls" {
  version = ">= 2.1.1"
}

# Use ACME provider with pre-configured API URL
provider "acme" {
  server_url = local.acme_url
  version    = ">= 1.5.0"
}

# Get existing regional RG parameters as data objects
data "azurerm_resource_group" "region_rg" {
  for_each = var.region_rg_map
  name     = each.value
}

# Get existing regional Key Vault parameters as data objects
data "azurerm_key_vault" "region_kv" {
  for_each = var.region_rg_map
  name = lower(join("-", compact([
    var.namespace,
    lookup(
      var.conf_common, "kv_name", lookup(lookup(
        var.conf_map, each.key, {}), "kv_name",
        ""
    )),
    each.key,
  ])))
  resource_group_name = each.value
}

# Generate private key for ACME account
resource "tls_private_key" "acme_private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Register ACME account
resource "acme_registration" "reg" {
  account_key_pem = tls_private_key.acme_private_key.private_key_pem
  email_address   = var.conf_module.account_email
}
