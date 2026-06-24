# M3I Spoke (Non-Prod) - CentralUS
# Variable Definitions

variable "platform_subscription_id" {
  description = "The subscription ID for the hub/platform landing zone"
  type        = string
  sensitive   = true
}

variable "spoke_subscription_id" {
  description = "The subscription ID for this spoke (Non-Prod)"
  type        = string
  sensitive   = true
}

variable "location" {
  description = "Azure region for resource deployment (CentralUS)"
  type        = string
  default     = "centralus"
}

variable "spoke_vnet_address_space" {
  description = "Address space for the spoke virtual network (Non-Prod)"
  type        = string
  default     = "10.100.8.0/22"
}

variable "subnets" {
  description = "Subnet configuration for spoke networking"
  type = map(object({
    name             = string
    address_prefixes = list(string)
    nsg_name         = optional(string, "")
    rt_name          = optional(string, "")
  }))
  default = {
    private_endpoints = {
      name             = "m3i-lz-nonprod-cus-snet-pe-01"
      address_prefixes = ["10.100.8.0/26"]
      nsg_name         = "m3i-lz-nonprod-cus-nsg-pe-01"
      rt_name          = ""
    }
    vm = {
      name             = "m3i-lz-nonprod-cus-snet-vm-01"
      address_prefixes = ["10.100.8.128/25"]
      nsg_name         = "m3i-lz-nonprod-cus-nsg-vm-01"
      rt_name          = "m3i-lz-nonprod-cus-rt-vm-01"
    }
    db = {
      name             = "m3i-lz-nonprod-cus-snet-db-01"
      address_prefixes = ["10.100.9.0/25"]
      nsg_name         = "m3i-lz-nonprod-cus-nsg-db-01"
      rt_name          = "m3i-lz-nonprod-cus-rt-db-01"
    }
  }
}

variable "enable_vnet_peering" {
  description = "Enable VNet peering between spoke and hub"
  type        = bool
  default     = true
}

variable "hub_firewall_private_ip" {
  description = "Private IP address of the hub firewall (deployed in same region)"
  type        = string
  default     = ""  # User must provide after hub firewall deployment or via tfvars
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

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
