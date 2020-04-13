# All modules require Terraform 0.12+ and store remote state in Azure
terraform {
  backend "azurerm" {}

  required_version = ">= 0.12.0"
}

# Pinning Azure provider to specific version
provider "azurerm" {
  version = ">= 2.3.0"
  features {}
}
