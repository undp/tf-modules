# Generate map of certificates to be generated
locals {
  certs_list_common = ! local.enable_common_certs ? [] : [
    for cert_name, cert_params in lookup(var.conf_common, "certs", {}) :
    {
      common_name               = lookup(cert_params, "common_name", "")
      subject_alternative_names = lookup(cert_params, "subject_alternative_names", [])
      key_type                  = lookup(cert_params, "key_type", lookup(var.conf_common, "key_type", 4096))
      cert_password             = lookup(cert_params, "cert_password", lookup(var.conf_common, "cert_password", null))
      min_days_remaining        = lookup(cert_params, "min_days_remaining", lookup(var.conf_common, "min_days_remaining", 30))
      must_staple               = lookup(cert_params, "must_staple", lookup(var.conf_common, "must_staple", false))
      recursive_nameservers     = lookup(cert_params, "recursive_nameservers", lookup(var.conf_common, "recursive_nameservers", null))

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

  common_name = each.value.common_name

  subject_alternative_names = each.value.subject_alternative_names

  key_type = lookup(each.value, "key_type")

  certificate_p12_password = lookup(each.value, "cert_password", null)

  min_days_remaining = lookup(each.value, "min_days_remaining")

  must_staple = lookup(each.value, "must_staple")

  recursive_nameservers = lookup(each.value, "recursive_nameservers", null)

  dynamic "dns_challenge" {
    for_each = local.enable_exec_dns_challenge ? {} : { 1 = 1 }

    content {
      provider = "azure"
      config = {
        ARM_RESOURCE_GROUP = each.value.zone_rg
      }
    }
  }

  dynamic "dns_challenge" {
    for_each = local.enable_exec_dns_challenge ? { 1 = 1 } : {}

    content {
      provider = "exec"
      config = {
        EXEC_PATH = lookup(var.conf_common, "acme_challenge_script", null)
      }
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Import Let's Encrypt certificates to each regional Key Vault
resource "azurerm_key_vault_certificate" "cert_common" {
  for_each = local.enable_common_certs ? {
    for record in setproduct(keys(local.certs_map_common), keys(var.region_rg_map)) : "${record[0]}-${record[1]}" => {
      cert_map_key = record[0]
      region_key   = record[1]
    }
  } : {}

  name         = local.certs_map_common[each.value.cert_map_key].name
  key_vault_id = data.azurerm_key_vault.region_kv[each.value.region_key].id

  certificate {
    contents = acme_certificate.cert_common[each.value.cert_map_key].certificate_p12
    password = local.certs_map_common[each.value.cert_map_key].cert_password
  }

  certificate_policy {
    issuer_parameters {
      name = "Unknown"
    }

    key_properties {
      exportable = true
      key_size   = local.certs_map_common[each.value.cert_map_key].key_type
      key_type   = "RSA"
      reuse_key  = false
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
