# M3I Platform Hub - CentralUS
# Azure Provider Versioning and Remote State Backend Configuration

locals {
  # Organization and naming conventions
  org           = "m3i"
  admin_domain  = "hub"
  env           = "prod"
  location_abbr = "cus"  # Central US abbreviation
  
  # Resource Group Names
  rgs = {
    hub_vnet_rg   = { name = "${local.org}-${local.admin_domain}-${local.env}-rg-vnet-${local.location_abbr}" }
    hub_vm_rg     = { name = "${local.org}-${local.admin_domain}-${local.env}-rg-vm-${local.location_abbr}" }
    hub_kv_rg     = { name = "${local.org}-${local.admin_domain}-${local.env}-rg-kv-${local.location_abbr}" }
    hub_fw_rg     = { name = "${local.org}-${local.admin_domain}-${local.env}-rg-fw-${local.location_abbr}" }
    hub_laws_rg   = { name = "${local.org}-${local.admin_domain}-${local.env}-rg-laws-${local.location_abbr}" }
    hub_rsv_rg    = { name = "${local.org}-${local.admin_domain}-${local.env}-rg-rsv-${local.location_abbr}" }
  }

  # VNet Naming
  hub_vnet_name = "m3i-hub-prod-cus-vnet-01"

  # Spoke VNet references (used for cross-subscription peering)
  spoke_prod_vnet_name      = "m3i-lz-prod-cus-vnet-01"
  spoke_prod_vnet_rg        = "m3i-spoke-prod-rg-vnet-cus"
  spoke_nonprod_vnet_name   = "m3i-lz-nonprod-cus-vnet-01"
  spoke_nonprod_vnet_rg     = "m3i-spoke-nonprod-rg-vnet-cus"
  spoke_prod_vnet_id        = "/subscriptions/${var.spoke_prod_subscription_id}/resourceGroups/${local.spoke_prod_vnet_rg}/providers/Microsoft.Network/virtualNetworks/${local.spoke_prod_vnet_name}"
  spoke_nonprod_vnet_id     = "/subscriptions/${var.spoke_nonprod_subscription_id}/resourceGroups/${local.spoke_nonprod_vnet_rg}/providers/Microsoft.Network/virtualNetworks/${local.spoke_nonprod_vnet_name}"
  other_region_hub_vnet_id  = "/subscriptions/${var.other_region_hub_subscription_id}/resourceGroups/${var.other_region_hub_resource_group}/providers/Microsoft.Network/virtualNetworks/${var.other_region_hub_vnet_name}"

  # Firewall Naming
  hub_fw_name        = "${local.org}-${local.admin_domain}-${local.env}-fw-${local.location_abbr}"
  hub_fw_pip_name    = "${local.org}-${local.admin_domain}-${local.env}-pip-fw-${local.location_abbr}"
  hub_fw_policy_name = "${local.org}-${local.admin_domain}-${local.env}-fw-policy-${local.location_abbr}"

  # NAT Gateway Naming
  hub_natgw_name     = "${local.org}-${local.admin_domain}-${local.env}-natgw-${local.location_abbr}"
  hub_natgw_pip_name = "${local.org}-${local.admin_domain}-${local.env}-pip-natgw-${local.location_abbr}"

  # Log Analytics Workspace
  hub_laws_name = "${local.org}-${local.admin_domain}-${local.env}-laws-${local.location_abbr}"
  hub_dcr_name  = "${local.org}-${local.admin_domain}-${local.env}-dcr-windows-${local.location_abbr}"

  # Recovery Services Vault
  hub_rsv_name              = "${local.org}-${local.admin_domain}-${local.env}-rsv-${local.location_abbr}"
  hub_rsv_backup_policy_name = "${local.org}-${local.admin_domain}-${local.env}-rsv-bp-daily-${local.location_abbr}"

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
