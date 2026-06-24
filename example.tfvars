#============================================================
# M3I-Terraform: Example TFVARS Configuration
#============================================================
# Copy this file and customize with your actual subscription IDs,
# IP address spaces, and other environment-specific values.
#
# File naming convention: <env>.<region>.tfvars
# Examples:
#   - platform.centralus.tfvars
#   - prod.centralus.tfvars
#   - nonprod.centralus.tfvars
#   - platform.eastus2.tfvars
#   - prod.eastus2.tfvars
#   - nonprod.eastus2.tfvars
#============================================================

#============================================================
# CENTRALUS REGION - HUB (PLATFORM)
#============================================================

# regions/centralus/platform/terraform.tfvars
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

#============================================================
# CENTRALUS REGION - SPOKE PROD
#============================================================

# regions/centralus/spoke-prod/terraform.tfvars
platform_subscription_id   = "4d58273c-5176-4f3b-97d5-8d19d8ff74e8"
spoke_subscription_id       = "31a0c2bb-b673-4ea4-81c2-335d87ca60f8"
location                    = "centralus"
spoke_vnet_address_space    = "10.100.4.0/22"

subnets = {
  private_endpoints = {
    name             = "m3i-lz-prod-cus-snet-pe-01"
    address_prefixes = ["10.100.4.0/26"]
  }
  vm = {
    name             = "m3i-lz-prod-cus-snet-vm-01"
    address_prefixes = ["10.100.4.128/25"]
    nsg_name         = "m3i-lz-prod-cus-nsg-vm-01"
    rt_name          = "m3i-lz-prod-cus-rt-vm-01"
  }
  db = {
    name             = "m3i-lz-prod-cus-snet-db-01"
    address_prefixes = ["10.100.5.0/25"]
    nsg_name         = "m3i-lz-prod-cus-nsg-db-01"
    rt_name          = "m3i-lz-prod-cus-rt-db-01"
  }
}

hub_firewall_private_ip = ""  # Update with hub firewall IP after deployment
enable_key_vault        = true
key_vault_sku           = "standard"

enable_vnet_peering = true

#============================================================
# CENTRALUS REGION - SPOKE NON-PROD
#============================================================

# regions/centralus/spoke-nonprod/terraform.tfvars
platform_subscription_id   = "4d58273c-5176-4f3b-97d5-8d19d8ff74e8"
spoke_subscription_id       = "9bdd25f9-1dbe-4784-b629-50d4febb1000"
location                    = "centralus"
spoke_vnet_address_space    = "10.100.8.0/22"

subnets = {
  private_endpoints = {
    name             = "m3i-lz-nonprod-cus-snet-pe-01"
    address_prefixes = ["10.100.8.0/26"]
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

hub_firewall_private_ip = ""  # Update with hub firewall IP after deployment
enable_key_vault        = true
key_vault_sku           = "standard"

enable_vnet_peering = true

#============================================================
# EASTUS2 REGION - HUB (PLATFORM)
#============================================================

# regions/eastus2/platform/terraform.tfvars
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
  }
  cato_wan = {
    name             = "m3i-hub-prod-eus2-snet-cato-wan-01"
    address_prefixes = ["10.101.0.64/27"]
  }
  cato_mgmt = {
    name             = "m3i-hub-prod-eus2-snet-cato-mgmt-01"
    address_prefixes = ["10.101.0.96/27"]
  }
  firewall = {
    name             = "AzureFirewallSubnet"
    address_prefixes = ["10.101.0.128/26"]
  }
  private_endpoints = {
    name             = "m3i-hub-prod-eus2-snet-pe-01"
    address_prefixes = ["10.101.0.192/26"]
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
dc_os_image_sku                    = "2025-Datacenter"
dc_os_image_version                = "latest"
admin_password                     = ""  # Leave empty to auto-generate, or provide your own

# Hub-to-Spoke and Hub-to-Hub Peering Configuration
spoke_prod_subscription_id         = "6ab13db0-ee2a-4a60-8a42-f79fd75fe06c"      # EastUS2 Prod
spoke_nonprod_subscription_id       = "e0f7a316-07ce-4882-b779-61329fa5c350"     # EastUS2 NonProd
enable_hub_to_spoke_peering        = true
enable_hub_to_hub_peering          = true   # Enabled after CUS hub is deployed
other_region_hub_vnet_name         = "m3i-hub-prod-cus-vnet-01"   # CentralUS hub VNet name
other_region_hub_resource_group    = "m3i-hub-prod-cus-rg-vnet"   # CentralUS hub resource group

#============================================================
# EASTUS2 REGION - SPOKE PROD
#============================================================

# regions/eastus2/spoke-prod/terraform.tfvars
platform_subscription_id   = "5f6a8c70-73ff-4df7-88f2-5484fbb14aff"
spoke_subscription_id       = "6ab13db0-ee2a-4a60-8a42-f79fd75fe06c"
location                    = "eastus2"
spoke_vnet_address_space    = "10.101.4.0/22"

subnets = {
  private_endpoints = {
    name             = "m3i-lz-prod-eus2-snet-pe-01"
    address_prefixes = ["10.101.4.0/26"]
  }
  vm = {
    name             = "m3i-lz-prod-eus2-snet-vm-01"
    address_prefixes = ["10.101.4.128/25"]
    nsg_name         = "m3i-lz-prod-eus2-nsg-vm-01"
    rt_name          = "m3i-lz-prod-eus2-rt-vm-01"
  }
  db = {
    name             = "m3i-lz-prod-eus2-snet-db-01"
    address_prefixes = ["10.101.5.0/25"]
    nsg_name         = "m3i-lz-prod-eus2-nsg-db-01"
    rt_name          = "m3i-lz-prod-eus2-rt-db-01"
  }
}
hub_firewall_private_ip = ""  # Update with hub firewall IP after deployment
enable_key_vault        = true
key_vault_sku           = "standard"

enable_vnet_peering = true

#============================================================
# EASTUS2 REGION - SPOKE NON-PROD
#============================================================

# regions/eastus2/spoke-nonprod/terraform.tfvars
platform_subscription_id   = "5f6a8c70-73ff-4df7-88f2-5484fbb14aff"
spoke_subscription_id       = "e0f7a316-07ce-4882-b779-61329fa5c350"
location                    = "eastus2"
spoke_vnet_address_space    = "10.101.8.0/22"

subnets = {
  private_endpoints = {
    name             = "m3i-lz-nonprod-eus2-snet-pe-01"
    address_prefixes = ["10.101.8.0/26"]
  }
  vm = {
    name             = "m3i-lz-nonprod-eus2-snet-vm-01"
    address_prefixes = ["10.101.8.128/25"]
    nsg_name         = "m3i-lz-nonprod-eus2-nsg-vm-01"
    rt_name          = "m3i-lz-nonprod-eus2-rt-vm-01"
  }
  db = {
    name             = "m3i-lz-nonprod-eus2-snet-db-01"
    address_prefixes = ["10.101.9.0/25"]
    nsg_name         = "m3i-lz-nonprod-eus2-nsg-db-01"
    rt_name          = "m3i-lz-nonprod-eus2-rt-db-01"
  }
}
hub_firewall_private_ip = ""  # Update with hub firewall IP after deployment
enable_key_vault        = true
key_vault_sku           = "standard"

enable_vnet_peering = true
