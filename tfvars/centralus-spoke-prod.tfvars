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

hub_firewall_private_ip = "10.100.0.132"
enable_key_vault        = true
key_vault_sku           = "standard"

enable_vnet_peering = true
