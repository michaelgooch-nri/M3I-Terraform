# M3I Spoke (Non-Prod) - CentralUS
# Locals for naming conventions and configuration

locals {
  org           = "m3i"
  admin_domain  = "spoke"
  env           = "nonprod"
  location_abbr = "cus"
  
  # Resource Group Names
  rgs = {
    spoke_vnet_rg = { name = "${local.org}-${local.admin_domain}-${local.env}-rg-vnet-${local.location_abbr}" }
    spoke_vm_rg   = { name = "${local.org}-${local.admin_domain}-${local.env}-rg-vm-${local.location_abbr}" }
    spoke_kv_rg   = { name = "${local.org}-${local.admin_domain}-${local.env}-rg-kv-${local.location_abbr}" }
    spoke_db_rg   = { name = "${local.org}-${local.admin_domain}-${local.env}-rg-db-${local.location_abbr}" }
  }

  # VNet Naming
  spoke_vnet_name = "m3i-lz-nonprod-cus-vnet-01"

  # Hub reference (data source will fetch this)
  hub_vnet_name        = "m3i-hub-prod-vnet-cus"
  hub_resource_group   = "m3i-hub-prod-rg-vnet-cus"

  # VNet Peering
  peering_hub_to_spoke_name = "${local.org}-hub-to-${local.env}-peer-${local.location_abbr}"
  peering_spoke_to_hub_name = "${local.org}-${local.env}-to-hub-peer-${local.location_abbr}"

  # Tags
  tags = {
    environment = "nonprod"
    project     = "m3i-azure-platform"
    region      = "centralus"
    spoke_type  = "workload"
    managed_by  = "terraform"
  }
}
