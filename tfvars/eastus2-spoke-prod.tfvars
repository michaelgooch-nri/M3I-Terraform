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
hub_firewall_private_ip = "10.101.0.132"
enable_key_vault        = true
key_vault_sku           = "standard"

enable_vnet_peering = true
