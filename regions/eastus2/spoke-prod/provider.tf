# M3I Spoke (Prod) - EastUS2
# Azure Provider Configuration

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
  
  backend "azurerm" {
    resource_group_name  = "m3i-spoke-prod-rg-tf-eus2"
    storage_account_name = "m3ispokeprodstortfeus2"
    container_name       = "tfstate"
    key                  = "m3i-spoke-prod-eus2.tfstate"
    subscription_id      = "6ab13db0-ee2a-4a60-8a42-f79fd75fe06c"
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
