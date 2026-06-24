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
    subscription_id      = "SPOKE-PROD-SUBSCRIPTION-ID-HERE"
  }
}

# Primary provider for spoke subscription
provider "azurerm" {
  features {}
  subscription_id = var.spoke_subscription_id
}

# Aliased provider for spoke context
provider "azurerm" {
  features {}
  subscription_id                 = var.spoke_subscription_id
  resource_provider_registrations = "core"
  alias                           = "spoke"
}

# Platform provider for data source references
provider "azurerm" {
  features {}
  subscription_id                 = var.platform_subscription_id
  resource_provider_registrations = "core"
  alias                           = "platform"
}