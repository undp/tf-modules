# Generate map of certificates to be generated
locals {
  certs_list_common = ! local.enable_common_certs ? [] : [
      for cert_name, target_list in lookup(var.conf_common, "certs", {}) :
      {
        fqdns   = target_list
        name    = lower(cert_name)
        zone_rg = lookup(var.conf_common, "zone_rg_name", "")
      }
  ]

  certs_map_common = {
    for cert in local.certs_list_common : "${lower(cert.name)}-common" => cert
  }
}

# Generate Let's Encrypt certificates for each region
resource "acme_certificate" "cert_common" {
  for_each = local.enable_common_certs ? local.certs_map_common : {}

  account_key_pem = acme_registration.reg.account_key_pem

  common_name = each.value.fqdns[0]

  subject_alternative_names = slice(each.value.fqdns, 1, length(each.value.fqdns))

  key_type = lookup(var.conf_common, "key_type", 4096)

  certificate_p12_password = lookup(var.conf_common, "cert_password", null)

  min_days_remaining = lookup(var.conf_common, "min_days_remaining", 30)

  must_staple = lookup(var.conf_common, "must_staple", false)

  recursive_nameservers = lookup(var.conf_common, "recursive_nameservers", null)

  dynamic "dns_challenge" {
    for_each = local.enable_exec_dns_challenge ?  {} : { 1 = 1 }

    content {
      provider = "azure"
      config = {
        ARM_RESOURCE_GROUP = each.value.zone_rg
      }
    }
  }

  dynamic "dns_challenge" {
    for_each = local.enable_exec_dns_challenge ?  { 1 = 1 } : {}

    content {
      provider = "exec"
      config = {
        EXEC_PATH = lookup(var.conf_common, "acme_challenge_script", null)
      }
    }
  }
}

# Import Let's Encrypt certificates to each regional Key Vault
resource "azurerm_key_vault_certificate" "cert_common" {
  for_each =  local.enable_common_certs ? {
    for record in setproduct(keys(local.certs_map_common), keys(var.region_rg_map)) : "${record[0]}-${record[1]}" => {
      cert_map_key = record[0]
      region_key = record[1]
    }
  } : {}

  name         = local.certs_map_common[each.value.cert_map_key].name
  key_vault_id = data.azurerm_key_vault.region_kv[each.value.region_key].id

  certificate {
    contents = acme_certificate.cert_common[each.value.cert_map_key].certificate_p12
    password = lookup(var.conf_common, "cert_password", null)
  }

  certificate_policy {
    issuer_parameters {
      name = "Unknown"
    }

    key_properties {
      exportable = true
      key_size = lookup( var.conf_common, "key_type", 4096)
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
