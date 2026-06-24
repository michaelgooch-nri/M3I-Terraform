# M3I Spoke (Non-Prod) - EastUS2
# Azure Provider Configuration

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
  
  backend "azurerm" {
    resource_group_name  = "m3i-spoke-nonprod-rg-tf-eus2"
    storage_account_name = "m3ispokenonprodstortfcus"
    container_name       = "tfstate"
    key                  = "m3i-spoke-nonprod-eus2.tfstate"
    subscription_id      = "SPOKE-NONPROD-SUBSCRIPTION-ID-HERE"
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

