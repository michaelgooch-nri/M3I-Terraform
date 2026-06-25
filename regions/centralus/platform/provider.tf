# Azure Provider Configuration for M3I Platform Hub - CentralUS
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
    resource_group_name  = "m3i-hub-prod-rg-tf-cus"
    storage_account_name = "m3ihubprodstortfcus"
    container_name       = "tfstate"
    key                  = "m3i-platform-cus.tfstate"
    subscription_id      = "4d58273c-5176-4f3b-97d5-8d19d8ff74e8"
    tenant_id            = "29fe76f0-0a1f-4673-9d42-3f8dafc342a4"
  }
}

# Primary provider for platform subscription
provider "azurerm" {
  features {}
  subscription_id = var.platform_subscription_id
  tenant_id       = "29fe76f0-0a1f-4673-9d42-3f8dafc342a4"
}

# Aliased provider for explicit platform context
provider "azurerm" {
  features {}
  subscription_id                 = var.platform_subscription_id
  tenant_id                       = "29fe76f0-0a1f-4673-9d42-3f8dafc342a4"
  resource_provider_registrations = "core"
  alias                           = "platform"
}

# Provider for Prod spoke subscription (for hub-to-spoke peering data sources)
provider "azurerm" {
  features {}
  subscription_id = var.spoke_prod_subscription_id != "" ? var.spoke_prod_subscription_id : var.platform_subscription_id
  tenant_id       = "29fe76f0-0a1f-4673-9d42-3f8dafc342a4"
  alias           = "spoke_prod"
}

# Provider for NonProd spoke subscription (for hub-to-spoke peering data sources)
provider "azurerm" {
  features {}
  subscription_id = var.spoke_nonprod_subscription_id != "" ? var.spoke_nonprod_subscription_id : var.platform_subscription_id
  tenant_id       = "29fe76f0-0a1f-4673-9d42-3f8dafc342a4"
  alias           = "spoke_nonprod"
}
