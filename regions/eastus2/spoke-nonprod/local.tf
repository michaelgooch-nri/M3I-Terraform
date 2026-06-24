# M3I Spoke (Non-Prod) - EastUS2
# Locals for naming conventions and configuration

locals {
  org           = "m3i"
  admin_domain  = "spoke"
  env           = "nonprod"
  location_abbr = "eus2"
  
  # Resource Group Names
  rgs = {
    spoke_vnet_rg = { name = "${local.org}-${local.admin_domain}-${local.env}-rg-vnet-${local.location_abbr}" }
    spoke_vm_rg   = { name = "${local.org}-${local.admin_domain}-${local.env}-rg-vm-${local.location_abbr}" }
    spoke_app_rg  = { name = "${local.org}-${local.admin_domain}-${local.env}-rg-app-${local.location_abbr}" }
  }

  # VNet Naming
  spoke_vnet_name = "m3i-lz-nonprod-eus2-vnet-01"

  # Hub reference (data source will fetch this)
  hub_vnet_name        = "m3i-hub-prod-vnet-eus2"
  hub_resource_group   = "m3i-hub-prod-rg-vnet-eus2"

  # VNet Peering
  peering_hub_to_spoke_name = "${local.org}-hub-to-${local.env}-peer-${local.location_abbr}"
  peering_spoke_to_hub_name = "${local.org}-${local.env}-to-hub-peer-${local.location_abbr}"

  # Tags
  tags = {
    environment = "nonprod"
    project     = "m3i-azure-platform"
    region      = "EastUS2"
    spoke_type  = "workload"
    managed_by  = "terraform"
  }
}

