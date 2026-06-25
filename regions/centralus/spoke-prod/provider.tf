# M3I Spoke (Prod) - CentralUS
# Azure Provider Configuration

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
  
  backend "azurerm" {
    resource_group_name  = "m3i-spoke-prod-rg-tf-cus"
    storage_account_name = "m3ispokeprodstortfcus"
    container_name       = "tfstate"
    key                  = "m3i-spoke-prod-cus.tfstate"
    subscription_id      = "31a0c2bb-b673-4ea4-81c2-335d87ca60f8"
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