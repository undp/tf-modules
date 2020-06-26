# Generate map of certificates to be generated
locals {
  certs_list_region = local.enable_common_certs ? [] : flatten([
    for location, rg in var.region_rg_map : [
      for cert_name, target_list in lookup(var.conf_common, "certs", lookup(lookup(
      var.conf_map, location, {}), "certs", {})) :
      {
        fqdns = [
          for target in target_list :
            local.enable_fqdn_target ? target : lower(join(".", compact([
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
        name        = lower(cert_name)
        zone_rg = local.enable_full_rg_name ? lookup(
            var.conf_common, "zone_rg_name", lookup(lookup(
              var.conf_map, location, {}), "zone_rg_name",
              ""
          )) : lower(join("_", compact([
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

  certs_map_region = {
    for cert in local.certs_list_region : "${lower(cert.name)}-${lower(cert.location)}" => cert
  }
}

# Generate Let's Encrypt certificates for each region
resource "acme_certificate" "cert_region" {
  for_each = local.enable_common_certs ? {} : local.certs_map_region

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

  recursive_nameservers = lookup(
    var.conf_common, "recursive_nameservers", lookup(lookup(
      var.conf_map, each.value.location, {}), "recursive_nameservers",
      null
  ))

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
        EXEC_PATH = lookup(
          var.conf_common, "acme_challenge_script", lookup(lookup(
            var.conf_map, each.value.location, {}), "acme_challenge_script",
            null
        ))
      }
    }
  }
}

# Import Let's Encrypt certificates to each regional Key Vault
resource "azurerm_key_vault_certificate" "cert_region" {
  for_each = local.enable_common_certs ? {} : local.certs_map_region

  name         = each.key
  key_vault_id = each.value.keyvault_id

  certificate {
    contents = acme_certificate.cert_region[each.key].certificate_p12
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
