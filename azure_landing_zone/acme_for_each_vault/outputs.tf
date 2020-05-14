output "cert_name_map" {
  description = "Map of cert names to corresponding KeyVault IDs and Secret IDs."
  value = {
    for key, kv_cert in azurerm_key_vault_certificate.cert : kv_cert.name => {
      key_vault_id = kv_cert.key_vault_id
      secret_id    = trimsuffix(kv_cert.secret_id, "${kv_cert.version}")
    }
  }
}

output "cert_name_map_ver" {
  description = "Map of cert names to corresponding KeyVault IDs and Secret IDs (with version included in the ID)."
  value = {
    for key, kv_cert in azurerm_key_vault_certificate.cert : kv_cert.name => {
      key_vault_id = kv_cert.key_vault_id
      secret_id    = kv_cert.secret_id
    }
  }
}
