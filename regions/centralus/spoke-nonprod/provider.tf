# M3I Spoke (Non-Prod) - CentralUS
# Azure Provider Configuration

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
  
  backend "azurerm" {
    resource_group_name  = "m3i-spoke-nonprod-rg-tf-cus"
    storage_account_name = "m3ispokenonprodstortfcus"
    container_name       = "tfstate"
    key                  = "m3i-spoke-nonprod-cus.tfstate"
    subscription_id      = "9bdd25f9-1dbe-4784-b629-50d4febb1000"
    tenant_id            = "29fe76f0-0a1f-4673-9d42-3f8dafc342a4"
  }
}

# Primary provider for spoke subscription
provider "azurerm" {
  features {}
  subscription_id = var.spoke_subscription_id
  tenant_id       = "29fe76f0-0a1f-4673-9d42-3f8dafc342a4"
}

# Aliased provider for spoke context
provider "azurerm" {
  features {}
  subscription_id                 = var.spoke_subscription_id
  tenant_id                       = "29fe76f0-0a1f-4673-9d42-3f8dafc342a4"
  resource_provider_registrations = "core"
  alias                           = "spoke"
}

# Platform provider for data source references
provider "azurerm" {
  features {}
  subscription_id                 = var.platform_subscription_id
  tenant_id                       = "29fe76f0-0a1f-4673-9d42-3f8dafc342a4"
  resource_provider_registrations = "core"
  alias                           = "platform"
}
