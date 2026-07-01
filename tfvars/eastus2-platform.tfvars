platform_subscription_id   = "5f6a8c70-73ff-4df7-88f2-5484fbb14aff"
location                   = "eastus2"
hub_vnet_address_space     = "10.101.0.0/22"

subnets = {
  gateway = {
    name             = "GatewaySubnet"
    address_prefixes = ["10.101.0.0/27"]
  }
  cato_lan = {
    name             = "m3i-hub-prod-eus2-snet-cato-lan-01"
    address_prefixes = ["10.101.0.32/27"]
    nsg_name         = "m3i-hub-prod-eus2-nsg-snet-cato-lan-01"
  }
  cato_wan = {
    name             = "m3i-hub-prod-eus2-snet-cato-wan-01"
    address_prefixes = ["10.101.0.64/27"]
    nsg_name         = "m3i-hub-prod-eus2-nsg-snet-cato-wan-01"
  }
  cato_mgmt = {
    name             = "m3i-hub-prod-eus2-snet-cato-mgmt-01"
    address_prefixes = ["10.101.0.96/27"]
    nsg_name         = "m3i-hub-prod-eus2-nsg-snet-cato-mgmt-01"
  }
  firewall = {
    name             = "AzureFirewallSubnet"
    address_prefixes = ["10.101.0.128/26"]
  }
  private_endpoints = {
    name             = "m3i-hub-prod-eus2-snet-pe-01"
    address_prefixes = ["10.101.0.192/26"]
    nsg_name         = "m3i-hub-prod-eus2-nsg-snet-pe-01"
  }
  shared_services = {
    name             = "m3i-hub-prod-eus2-snet-shared-services-01"
    address_prefixes = ["10.101.1.0/25"]
    nsg_name         = "m3i-hub-prod-eus2-nsg-snet-shared-services-01"
    rt_name          = "m3i-hub-prod-eus2-rt-snet-shared-services-01"
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
dc_os_image_sku                    = "2022-Datacenter"
dc_os_image_version                = "latest"
admin_password                     = ""  # Leave empty to auto-generate, or provide your own

# Hub-to-Spoke and Hub-to-Hub Peering Configuration
spoke_prod_subscription_id         = "6ab13db0-ee2a-4a60-8a42-f79fd75fe06c"      # EastUS2 Prod
spoke_nonprod_subscription_id       = "e0f7a316-07ce-4882-b779-61329fa5c350"     # EastUS2 NonProd
enable_hub_to_spoke_peering        = true
enable_hub_to_hub_peering          = true   # Enabled after CUS hub is deployed
other_region_hub_vnet_name         = "m3i-hub-prod-cus-vnet-01"   # CentralUS hub VNet name
other_region_hub_resource_group    = "m3i-hub-prod-rg-vnet-cus"   # CentralUS hub resource group
other_region_hub_subscription_id   = "4d58273c-5176-4f3b-97d5-8d19d8ff74e8"   # CentralUS hub subscription
