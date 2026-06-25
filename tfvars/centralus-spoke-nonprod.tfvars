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

hub_firewall_private_ip = "10.100.0.132"
enable_key_vault        = true
key_vault_sku           = "standard"

enable_vnet_peering = true
