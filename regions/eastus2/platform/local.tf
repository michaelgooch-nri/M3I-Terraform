# M3I Platform Hub - EastUS2
# Azure Provider Versioning and Remote State Backend Configuration

locals {
  # Organization and naming conventions
  org           = "m3i"
  admin_domain  = "hub"
  env           = "prod"
  location_abbr = "eus2"  # East US 2 abbreviation
  
  # Resource Group Names
  rgs = {
    hub_vnet_rg   = { name = "${local.org}-${local.admin_domain}-${local.env}-rg-vnet-${local.location_abbr}" }
    hub_fw_rg     = { name = "${local.org}-${local.admin_domain}-${local.env}-rg-fw-${local.location_abbr}" }
    hub_laws_rg   = { name = "${local.org}-${local.admin_domain}-${local.env}-rg-laws-${local.location_abbr}" }
    hub_rsv_rg    = { name = "${local.org}-${local.admin_domain}-${local.env}-rg-rsv-${local.location_abbr}" }
  }

  # VNet Naming
  hub_vnet_name = "m3i-hub-prod-eus2-vnet-01"

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

  # Tags applied to all resources
  tags = {
    environment = "prod"
    project     = "m3i-azure-platform"
    region      = "eastus2"
    managed_by  = "terraform"
  }
}

