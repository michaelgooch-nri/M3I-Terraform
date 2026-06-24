# M3I Platform Hub - EastUS2
# Variable Definitions

variable "platform_subscription_id" {
  description = "The subscription ID for the hub/platform landing zone (EastUS2)"
  type        = string
  sensitive   = true
}

variable "location" {
  description = "Azure region for resource deployment (EastUS2)"
  type        = string
  default     = "eastus2"
}

variable "hub_vnet_address_space" {
  description = "Address space for the hub virtual network"
  type        = string
  default     = "10.101.0.0/22"
}

variable "subnets" {
  description = "Subnet configuration for hub networking"
  type = map(object({
    name             = string
    address_prefixes = list(string)
    nsg_name         = optional(string, "")
    rt_name          = optional(string, "")
  }))
  default = {
    gateway = {
      name             = "GatewaySubnet"
      address_prefixes = ["10.101.0.0/27"]
      nsg_name         = ""
      rt_name          = ""
    }
    cato_lan = {
      name             = "m3i-hub-prod-eus2-snet-cato-lan-01"
      address_prefixes = ["10.101.0.32/27"]
      nsg_name         = ""
      rt_name          = ""
    }
    cato_wan = {
      name             = "m3i-hub-prod-eus2-snet-cato-wan-01"
      address_prefixes = ["10.101.0.64/27"]
      nsg_name         = ""
      rt_name          = ""
    }
    cato_mgmt = {
      name             = "m3i-hub-prod-eus2-snet-cato-mgmt-01"
      address_prefixes = ["10.101.0.96/27"]
      nsg_name         = ""
      rt_name          = ""
    }
    firewall = {
      name             = "AzureFirewallSubnet"
      address_prefixes = ["10.101.0.128/26"]
      nsg_name         = ""
      rt_name          = ""
    }
    private_endpoints = {
      name             = "m3i-hub-prod-eus2-snet-pe-01"
      address_prefixes = ["10.101.0.192/26"]
      nsg_name         = ""
      rt_name          = ""
    }
    shared_services = {
      name             = "m3i-hub-prod-eus2-snet-shared-services-01"
      address_prefixes = ["10.101.1.0/25"]
      nsg_name         = "m3i-hub-prod-eus2-nsg-snet-shared-services-01"
      rt_name          = "m3i-hub-prod-eus2-rt-snet-shared-services-01"
    }
  }
}

variable "firewall_config" {
  description = "Azure Firewall configuration"
  type = object({
    sku_name                    = string
    sku_tier                    = string
    threat_intelligence_mode    = string
    enable_dns_proxy            = bool
    enable_idps_mode            = optional(string, "Alert")
  })
  default = {
    sku_name                 = "AZFW_VNet"
    sku_tier                 = "Standard"
    threat_intelligence_mode = "Alert"
    enable_dns_proxy         = true
    enable_idps_mode         = "Alert"
  }
}

variable "natgw_config" {
  description = "NAT Gateway configuration"
  type = object({
    idle_timeout_minutes = number
    public_ip_count      = number
  })
  default = {
    idle_timeout_minutes = 4
    public_ip_count      = 1
  }
}

variable "enable_log_analytics" {
  description = "Enable Log Analytics Workspace and diagnostic settings"
  type        = bool
  default     = true
}

variable "log_analytics_retention_days" {
  description = "Log Analytics retention in days"
  type        = number
  default     = 30
}

variable "enable_backup" {
  description = "Enable Recovery Services Vault for backups"
  type        = bool
  default     = true
}

variable "enable_key_vault" {
  description = "Enable Azure Key Vault"
  type        = bool
  default     = true
}

variable "key_vault_sku" {
  description = "SKU for Azure Key Vault"
  type        = string
  default     = "standard"
}

variable "admin_password" {
  description = "Admin password for any management VMs (if deployed)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "enable_dc_vms" {
  description = "Enable Active Directory Domain Controller VMs"
  type        = bool
  default     = true
}

variable "dc_vm_count" {
  description = "Number of Domain Controller VMs to create"
  type        = number
  default     = 2
}

variable "dc_vm_size" {
  description = "VM size for Domain Controller VMs"
  type        = string
  default     = "Standard_D2s_v5"
}

variable "dc_os_image_publisher" {
  description = "OS image publisher for DCs"
  type        = string
  default     = "MicrosoftWindowsServer"
}

variable "dc_os_image_offer" {
  description = "OS image offer for DCs"
  type        = string
  default     = "WindowsServer"
}

variable "dc_os_image_sku" {
  description = "OS image SKU for DCs"
  type        = string
  default     = "2025-Datacenter"
}

variable "dc_os_image_version" {
  description = "OS image version for DCs"
  type        = string
  default     = "latest"
}

variable "spoke_prod_subscription_id" {
  description = "Subscription ID for the Prod spoke VNet (for hub-to-spoke peering)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "spoke_nonprod_subscription_id" {
  description = "Subscription ID for the NonProd spoke VNet (for hub-to-spoke peering)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "enable_hub_to_spoke_peering" {
  description = "Enable hub-to-spoke VNet peering"
  type        = bool
  default     = true
}

variable "enable_hub_to_hub_peering" {
  description = "Enable hub-to-hub cross-region VNet peering"
  type        = bool
  default     = true
}

variable "other_region_hub_vnet_name" {
  description = "Name of the hub VNet in the other region for cross-region peering"
  type        = string
  default     = ""
}

variable "other_region_hub_resource_group" {
  description = "Resource group name of the hub in the other region for cross-region peering"
  type        = string
  default     = ""
}

variable "other_region_firewall_private_ip" {
  description = "Private IP of the other region Azure Firewall for inter-region routing"
  type        = string
  default     = ""
}

variable "common_tags" {
  description = "Common tags to apply to all resources (overrides locals if provided)"
  type        = map(string)
  default     = {}
}

