# M3I Spoke (Non-Prod) - EastUS2
# Main Resource Definitions for Spoke Networking and Subnets

#---------------------------------------
# Data Source: Hub Virtual Network
#---------------------------------------

data "azurerm_client_config" "current" {
  provider = azurerm.spoke
}

data "azurerm_virtual_network" "hub_vnet" {
  name                = local.hub_vnet_name
  resource_group_name = local.hub_resource_group
  provider            = azurerm.platform
}

#---------------------------------------
# Resource Groups
#---------------------------------------

resource "azurerm_resource_group" "spoke_resource_groups" {
  for_each = local.rgs

  name     = each.value.name
  location = var.location
  provider = azurerm.spoke
  tags     = merge(local.tags, var.common_tags)
}

#---------------------------------------
# Spoke Virtual Network
#---------------------------------------

resource "azurerm_virtual_network" "spoke_vnet" {
  name                = local.spoke_vnet_name
  resource_group_name = azurerm_resource_group.spoke_resource_groups["spoke_vnet_rg"].name
  location            = var.location
  address_space       = [var.spoke_vnet_address_space]
  provider            = azurerm.spoke
  tags                = merge(local.tags, var.common_tags)

  depends_on = [azurerm_resource_group.spoke_resource_groups]
}

#---------------------------------------
# Subnets
#---------------------------------------

resource "azurerm_subnet" "spoke_vm_subnet" {
  name                 = var.subnets.vm.name
  resource_group_name  = azurerm_resource_group.spoke_resource_groups["spoke_vnet_rg"].name
  address_prefixes     = var.subnets.vm.address_prefixes
  virtual_network_name = azurerm_virtual_network.spoke_vnet.name
  provider             = azurerm.spoke

  depends_on = [azurerm_virtual_network.spoke_vnet]
}

resource "azurerm_subnet" "spoke_app_subnet" {
  name                 = var.subnets.app.name
  resource_group_name  = azurerm_resource_group.spoke_resource_groups["spoke_vnet_rg"].name
  address_prefixes     = var.subnets.app.address_prefixes
  virtual_network_name = azurerm_virtual_network.spoke_vnet.name
  provider             = azurerm.spoke

  depends_on = [azurerm_virtual_network.spoke_vnet]
}

resource "azurerm_subnet" "spoke_db_subnet" {
  name                 = var.subnets.db.name
  resource_group_name  = azurerm_resource_group.spoke_resource_groups["spoke_vnet_rg"].name
  address_prefixes     = var.subnets.db.address_prefixes
  virtual_network_name = azurerm_virtual_network.spoke_vnet.name
  provider             = azurerm.spoke

  depends_on = [azurerm_virtual_network.spoke_vnet]
}

resource "azurerm_subnet" "spoke_private_endpoints_subnet" {
  name                 = var.subnets.private_endpoints.name
  resource_group_name  = azurerm_resource_group.spoke_resource_groups["spoke_vnet_rg"].name
  address_prefixes     = var.subnets.private_endpoints.address_prefixes
  virtual_network_name = azurerm_virtual_network.spoke_vnet.name
  provider             = azurerm.spoke

  depends_on = [azurerm_virtual_network.spoke_vnet]
}

#---------------------------------------
# Network Security Groups (NSG)
#---------------------------------------

resource "azurerm_network_security_group" "spoke_vm_nsg" {
  name                = var.subnets.vm.nsg_name
  resource_group_name = azurerm_resource_group.spoke_resource_groups["spoke_vnet_rg"].name
  location            = var.location
  provider            = azurerm.spoke
  tags                = merge(local.tags, var.common_tags)
}

resource "azurerm_subnet_network_security_group_association" "spoke_vm_nsg_assoc" {
  subnet_id                 = azurerm_subnet.spoke_vm_subnet.id
  network_security_group_id = azurerm_network_security_group.spoke_vm_nsg.id
  provider                  = azurerm.spoke
}

resource "azurerm_network_security_group" "spoke_app_nsg" {
  name                = var.subnets.app.nsg_name
  resource_group_name = azurerm_resource_group.spoke_resource_groups["spoke_vnet_rg"].name
  location            = var.location
  provider            = azurerm.spoke
  tags                = merge(local.tags, var.common_tags)
}

resource "azurerm_subnet_network_security_group_association" "spoke_app_nsg_assoc" {
  subnet_id                 = azurerm_subnet.spoke_app_subnet.id
  network_security_group_id = azurerm_network_security_group.spoke_app_nsg.id
  provider                  = azurerm.spoke
}

resource "azurerm_network_security_group" "spoke_db_nsg" {
  name                = var.subnets.db.nsg_name
  resource_group_name = azurerm_resource_group.spoke_resource_groups["spoke_vnet_rg"].name
  location            = var.location
  provider            = azurerm.spoke
  tags                = merge(local.tags, var.common_tags)
}

resource "azurerm_subnet_network_security_group_association" "spoke_db_nsg_assoc" {
  subnet_id                 = azurerm_subnet.spoke_db_subnet.id
  network_security_group_id = azurerm_network_security_group.spoke_db_nsg.id
  provider                  = azurerm.spoke
}

#---------------------------------------
# Route Tables (UDRs) - Point to Hub Firewall
#---------------------------------------

# VM Subnet Route Table
resource "azurerm_route_table" "spoke_vm_rt" {
  name                = var.subnets.vm.rt_name
  resource_group_name = azurerm_resource_group.spoke_resource_groups["spoke_vnet_rg"].name
  location            = var.location
  provider            = azurerm.spoke
  tags                = merge(local.tags, var.common_tags)

  # Default route to hub firewall
  route {
    name           = "m3i-eus2-default-to-hub-firewall"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = var.hub_firewall_private_ip
  }
}

resource "azurerm_subnet_route_table_association" "spoke_vm_rt_assoc" {
  subnet_id      = azurerm_subnet.spoke_vm_subnet.id
  route_table_id = azurerm_route_table.spoke_vm_rt.id
  provider       = azurerm.spoke
}

# App Subnet Route Table
resource "azurerm_route_table" "spoke_app_rt" {
  name                = var.subnets.app.rt_name
  resource_group_name = azurerm_resource_group.spoke_resource_groups["spoke_vnet_rg"].name
  location            = var.location
  provider            = azurerm.spoke
  tags                = merge(local.tags, var.common_tags)

  route {
    name           = "m3i-eus2-default-to-hub-firewall"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = var.hub_firewall_private_ip
  }
}

resource "azurerm_subnet_route_table_association" "spoke_app_rt_assoc" {
  subnet_id      = azurerm_subnet.spoke_app_subnet.id
  route_table_id = azurerm_route_table.spoke_app_rt.id
  provider       = azurerm.spoke
}

# DB Subnet Route Table
resource "azurerm_route_table" "spoke_db_rt" {
  name                = var.subnets.db.rt_name
  resource_group_name = azurerm_resource_group.spoke_resource_groups["spoke_vnet_rg"].name
  location            = var.location
  provider            = azurerm.spoke
  tags                = merge(local.tags, var.common_tags)

  route {
    name           = "m3i-eus2-default-to-hub-firewall"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = var.hub_firewall_private_ip
  }
}

resource "azurerm_subnet_route_table_association" "spoke_db_rt_assoc" {
  subnet_id      = azurerm_subnet.spoke_db_subnet.id
  route_table_id = azurerm_route_table.spoke_db_rt.id
  provider       = azurerm.spoke
}

# Private Endpoints Subnet Route Table
resource "azurerm_route_table" "spoke_pe_rt" {
  name                = "m3i-lz-nonprod-eus2-rt-pe-01"
  resource_group_name = azurerm_resource_group.spoke_resource_groups["spoke_vnet_rg"].name
  location            = var.location
  provider            = azurerm.spoke
  tags                = merge(local.tags, var.common_tags)

  route {
    name                   = "m3i-eus2-default-to-hub-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.hub_firewall_private_ip
  }
}

resource "azurerm_subnet_route_table_association" "spoke_pe_rt_assoc" {
  subnet_id      = azurerm_subnet.spoke_private_endpoints_subnet.id
  route_table_id = azurerm_route_table.spoke_pe_rt.id
  provider       = azurerm.spoke
}

#---------------------------------------
# Azure Key Vault
#---------------------------------------

resource "azurerm_key_vault" "spoke_keyvault" {
  count               = var.enable_key_vault ? 1 : 0
  name                = "m3i-lz-nonprod-eus2-kv"
  location            = var.location
  resource_group_name = azurerm_resource_group.spoke_resource_groups["spoke_vnet_rg"].name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = var.key_vault_sku
  provider            = azurerm.spoke
  tags                = merge(local.tags, var.common_tags)

  enabled_for_deployment          = true
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true
  purge_protection_enabled        = true
  soft_delete_retention_days      = 7

  depends_on = [azurerm_resource_group.spoke_resource_groups]
}

resource "azurerm_key_vault_access_policy" "spoke_keyvault_policy" {
  count       = var.enable_key_vault ? 1 : 0
  key_vault_id = azurerm_key_vault.spoke_keyvault[0].id
  tenant_id   = data.azurerm_client_config.current.tenant_id
  object_id   = data.azurerm_client_config.current.object_id
  provider    = azurerm.spoke

  key_permissions = [
    "Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import", "List", "Purge", "Recover", "Restore", "Sign", "UnwrapKey", "Update", "Verify", "WrapKey"
  ]

  secret_permissions = [
    "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"
  ]

  certificate_permissions = [
    "Backup", "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers", "Import", "List", "ListIssuers", "Purge", "Recover", "Restore", "SetIssuers", "Update"
  ]
}

#---------------------------------------
# VNet Peering (Spoke to Hub)
#---------------------------------------

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  count                     = var.enable_vnet_peering ? 1 : 0
  name                      = local.peering_spoke_to_hub_name
  resource_group_name       = azurerm_resource_group.spoke_resource_groups["spoke_vnet_rg"].name
  virtual_network_name      = azurerm_virtual_network.spoke_vnet.name
  remote_virtual_network_id = data.azurerm_virtual_network.hub_vnet.id
  provider                  = azurerm.spoke

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = true

  depends_on = [azurerm_virtual_network.spoke_vnet]
}

# Hub to Spoke peering (cross-subscription)
# Note: This requires a separate Terraform run in the platform subscription
# OR use a module/data source to reference the hub peering resource

