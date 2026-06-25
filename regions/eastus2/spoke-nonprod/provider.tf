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
    storage_account_name = "m3ispokenonprodstortfe2"
    container_name       = "tfstate"
    key                  = "m3i-spoke-nonprod-eus2.tfstate"
    subscription_id      = "e0f7a316-07ce-4882-b779-61329fa5c350"
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

