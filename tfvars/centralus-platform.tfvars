platform_subscription_id   = "4d58273c-5176-4f3b-97d5-8d19d8ff74e8"
location                   = "centralus"
hub_vnet_address_space     = "10.100.0.0/22"

subnets = {
  gateway = {
    name             = "GatewaySubnet"
    address_prefixes = ["10.100.0.0/27"]
  }
  cato_lan = {
    name             = "m3i-hub-prod-cus-snet-cato-lan-01"
    address_prefixes = ["10.100.0.32/27"]
  }
  cato_wan = {
    name             = "m3i-hub-prod-cus-snet-cato-wan-01"
    address_prefixes = ["10.100.0.64/27"]
  }
  cato_mgmt = {
    name             = "m3i-hub-prod-cus-snet-cato-mgmt-01"
    address_prefixes = ["10.100.0.96/27"]
  }
  firewall = {
    name             = "AzureFirewallSubnet"
    address_prefixes = ["10.100.0.128/26"]
  }
  private_endpoints = {
    name             = "m3i-hub-prod-cus-snet-pe-01"
    address_prefixes = ["10.100.0.192/26"]
  }
  shared_services = {
    name             = "m3i-hub-prod-cus-snet-shared-services-01"
    address_prefixes = ["10.100.1.0/25"]
    nsg_name         = "m3i-hub-prod-cus-nsg-snet-shared-services-01"
    rt_name          = "m3i-hub-prod-cus-rt-snet-shared-services-01"
  }
}

firewall_config = {
  sku_name                 = "AZFW_VNet"
  sku_tier                 = "Standard"
  threat_intelligence_mode = "Alert"
  enable_dns_proxy         = true
  enable_idps_mode         = "Alert"
}

natgw_config = {
  idle_timeout_minutes = 4
  public_ip_count      = 1
}

enable_log_analytics              = true
log_analytics_retention_days       = 30
enable_backup                      = true
enable_key_vault                   = true
key_vault_sku                      = "standard"

# Domain Controller VM Configuration
enable_dc_vms                      = true
dc_vm_count                        = 2
dc_vm_size                         = "Standard_D2s_v5"
dc_os_image_publisher              = "MicrosoftWindowsServer"
dc_os_image_offer                  = "WindowsServer"
dc_os_image_sku                    = "2025-Datacenter"
dc_os_image_version                = "latest"
admin_password                     = ""  # Leave empty to auto-generate, or provide your own

# Hub-to-Spoke and Hub-to-Hub Peering Configuration
spoke_prod_subscription_id         = "31a0c2bb-b673-4ea4-81c2-335d87ca60f8"      # CentralUS Prod
spoke_nonprod_subscription_id       = "9bdd25f9-1dbe-4784-b629-50d4febb1000"     # CentralUS NonProd
enable_hub_to_spoke_peering        = true
enable_hub_to_hub_peering          = false  # Set to true after CUS hub is deployed
other_region_hub_vnet_name         = ""     # Leave empty until CUS hub is deployed
other_region_hub_resource_group    = ""     # Leave empty until CUS hub is deployed
other_region_hub_subscription_id   = ""     # Leave empty until CUS hub is deployed
