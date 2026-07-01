# M3I Spoke (Prod) - CentralUS
# Locals for naming conventions and configuration

locals {
  org           = "m3i"
  admin_domain  = "spoke"
  env           = "prod"
  location_abbr = "cus"
  
  # Resource Group Names
  rgs = {
    spoke_vnet_rg = { name = "${local.org}-${local.admin_domain}-${local.env}-rg-vnet-${local.location_abbr}" }
    spoke_vm_rg   = { name = "${local.org}-${local.admin_domain}-${local.env}-rg-vm-${local.location_abbr}" }
    spoke_kv_rg   = { name = "${local.org}-${local.admin_domain}-${local.env}-rg-kv-${local.location_abbr}" }
    spoke_db_rg   = { name = "${local.org}-${local.admin_domain}-${local.env}-rg-db-${local.location_abbr}" }
  }

  # VNet Naming
  spoke_vnet_name = "m3i-lz-prod-cus-vnet-01"

  # Hub reference (data source will fetch this)
  hub_vnet_name        = "m3i-hub-prod-cus-vnet-01"
  hub_resource_group   = "m3i-hub-prod-rg-vnet-cus"
  hub_vnet_id          = "/subscriptions/${var.platform_subscription_id}/resourceGroups/${local.hub_resource_group}/providers/Microsoft.Network/virtualNetworks/${local.hub_vnet_name}"

  # VNet Peering
  peering_hub_to_spoke_name = "${local.org}-hub-to-${local.env}-peer-${local.location_abbr}"
  peering_spoke_to_hub_name = "${local.org}-${local.env}-to-hub-peer-${local.location_abbr}"

  # Tags applied only to resource groups
  rg_tags = {
    Application        = "TBD"
    Environment        = "PROD"
    Region             = "CUS"
    Owner              = "TBD"
    CostCenter         = "TBD"
    ManagedBy          = "TBD"
    DataClassification = "TBD"
  }
}