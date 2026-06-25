platform_subscription_id   = "5f6a8c70-73ff-4df7-88f2-5484fbb14aff"
spoke_subscription_id       = "e0f7a316-07ce-4882-b779-61329fa5c350"
location                    = "eastus2"
spoke_vnet_address_space    = "10.101.8.0/22"

subnets = {
  private_endpoints = {
    name             = "m3i-lz-nonprod-eus2-snet-pe-01"
    address_prefixes = ["10.101.8.0/26"]
    nsg_name         = "m3i-lz-nonprod-eus2-nsg-pe-01"
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
hub_firewall_private_ip = "10.101.0.132"
enable_key_vault        = true
key_vault_sku           = "standard"

enable_vnet_peering = true
