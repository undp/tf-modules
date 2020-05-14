# Ensure all module-wide options are properly defined
locals {
  enable_staging_api = lookup(var.conf_module, "enable_staging_api", false)
  acme_server        = local.enable_staging_api ? "acme-staging" : "acme"
  acme_url           = "https://${local.acme_server}-v02.api.letsencrypt.org/directory"
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

# Generate map of certificates to be generated
locals {
  certs_list = flatten([
    for location, rg in var.region_rg_map : [
      for cert_name, target_list in lookup(var.conf_common, "certs", lookup(lookup(
      var.conf_map, location, {}), "certs", {})) :
      {
        fqdns = [
          for target in target_list :
          lower(join(".", compact([
            target,
            location,
            lookup(
              var.conf_common, "zone_name", lookup(lookup(
                var.conf_map, location, {}), "zone_name",
                ""
            )),
            var.namespace,
            lookup(
              var.conf_common, "zone_suffix", lookup(lookup(
                var.conf_map, location, {}), "zone_suffix",
                ""
            )),
          ])))
        ]
        keyvault_id = data.azurerm_key_vault.region_kv[location].id
        location    = location
        name        = cert_name
        zone_rg = lower(join("_", compact([
          var.namespace,
          lookup(
            var.conf_common, "zone_rg_name", lookup(lookup(
              var.conf_map, location, {}), "zone_rg_name",
              ""
          )),
          location,
        ])))
      }
    ]
  ])

  certs_map = {
    for cert in local.certs_list : "${lower(cert.name)}-${lower(cert.location)}" => cert
  }
}

# Generate Let's Encrypt certificates for each region
resource "acme_certificate" "cert" {
  for_each = local.certs_map

  account_key_pem = acme_registration.reg.account_key_pem

  common_name = each.value.fqdns[0]

  subject_alternative_names = slice(each.value.fqdns, 1, length(each.value.fqdns))

  key_type = lookup(
    var.conf_common, "key_type", lookup(lookup(
      var.conf_map, each.value.location, {}), "key_type",
      4096
  ))

  certificate_p12_password = lookup(
    var.conf_common, "cert_password", lookup(lookup(
      var.conf_map, each.value.location, {}), "cert_password",
      null
  ))

  min_days_remaining = lookup(
    var.conf_common, "min_days_remaining", lookup(lookup(
      var.conf_map, each.value.location, {}), "min_days_remaining",
      30
  ))

  must_staple = lookup(
    var.conf_common, "must_staple", lookup(lookup(
      var.conf_map, each.value.location, {}), "must_staple",
      false
  ))

  dns_challenge {
    provider = "azure"
    config = {
      ARM_RESOURCE_GROUP = each.value.zone_rg
    }
  }
}

# Import Let's Encrypt certificates to each regional Key Vault
resource "azurerm_key_vault_certificate" "cert" {
  for_each = local.certs_map

  name         = each.key
  key_vault_id = each.value.keyvault_id

  certificate {
    contents = acme_certificate.cert[each.key].certificate_p12
    password = lookup(
      var.conf_common, "cert_password", lookup(lookup(
        var.conf_map, each.value.location, {}), "cert_password",
        null
    ))
  }

  certificate_policy {
    issuer_parameters {
      name = "Unknown"
    }

    key_properties {
      exportable = true
      key_size = lookup(
        var.conf_common, "key_type", lookup(lookup(
          var.conf_map, each.value.location, {}), "key_type",
          4096
      ))
      key_type  = "RSA"
      reuse_key = false
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }
  }

  tags = merge(
    { "Namespace" = "${title(var.namespace)}" },
    "${var.tags}"
  )
}
