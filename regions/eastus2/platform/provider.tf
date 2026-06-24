# Azure Provider Configuration for M3I Platform Hub - EastUS2
# This file configures the Azure provider for the platform (hub) subscription

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  
  # Remote state will be stored in Azure Blob Storage
  # Note: Backend configuration will be set separately with -backend-config flags or init command
  backend "azurerm" {
    resource_group_name  = "m3i-hub-prod-rg-tf-eus2"
    storage_account_name = "m3ihubprodstortfcus"
    container_name       = "tfstate"
    key                  = "m3i-platform-eus2.tfstate"
    subscription_id      = "PLATFORM-SUBSCRIPTION-ID-HERE"
  }
}

# Primary provider for platform subscription
provider "azurerm" {
  features {}
  subscription_id = var.platform_subscription_id
}

# Aliased provider for explicit platform context
provider "azurerm" {
  features {}
  subscription_id                 = var.platform_subscription_id
  resource_provider_registrations = "core"
  alias                           = "platform"
}

# Provider for Prod spoke subscription (for hub-to-spoke peering data sources)
provider "azurerm" {
  features {}
  subscription_id = var.spoke_prod_subscription_id != "" ? var.spoke_prod_subscription_id : var.platform_subscription_id
  alias           = "spoke_prod"
}

# Provider for NonProd spoke subscription (for hub-to-spoke peering data sources)
provider "azurerm" {
  features {}
  subscription_id = var.spoke_nonprod_subscription_id != "" ? var.spoke_nonprod_subscription_id : var.platform_subscription_id
  alias           = "spoke_nonprod"
}
