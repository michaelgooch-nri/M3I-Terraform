# M3I Platform Hub - CentralUS
# Main Resource Definitions for Hub Networking, Firewall, and Shared Services

#---------------------------------------
# Data Sources
#---------------------------------------

data "azurerm_client_config" "current" {
  provider = azurerm.platform
}

data "terraform_remote_state" "other_region_hub" {
  count   = var.enable_hub_to_hub_peering && var.other_region_hub_vnet_name != "" ? 1 : 0
  backend = "azurerm"
  config = {
    resource_group_name  = "m3i-hub-prod-rg-tf-eus2"
    storage_account_name = "m3ihubprodstortfeus2"
    container_name       = "tfstate"
    key                  = "m3i-platform-eus2.tfstate"
    subscription_id      = "5f6a8c70-73ff-4df7-88f2-5484fbb14aff"
  }
}

locals {
  other_region_firewall_private_ip_effective = var.other_region_firewall_private_ip != "" ? var.other_region_firewall_private_ip : (length(data.terraform_remote_state.other_region_hub) > 0 ? try(data.terraform_remote_state.other_region_hub[0].outputs.hub_firewall_private_ip, "") : "")
}

#---------------------------------------
# Resource Groups
#---------------------------------------

resource "azurerm_resource_group" "hub_resource_groups" {
  for_each = local.rgs

  name     = each.value.name
  location = var.location
  provider = azurerm.platform
   tags     = local.rg_tags
}

#---------------------------------------
# Virtual Network
#---------------------------------------

resource "azurerm_virtual_network" "hub_vnet" {
  name                = local.hub_vnet_name
  resource_group_name = azurerm_resource_group.hub_resource_groups["hub_vnet_rg"].name
  location            = var.location
  address_space       = [var.hub_vnet_address_space]
  provider            = azurerm.platform

  depends_on = [azurerm_resource_group.hub_resource_groups]
}

resource "azurerm_virtual_network" "bastion_vnet" {
  count               = var.enable_bastion ? 1 : 0
  name                = var.bastion_vnet_name
  resource_group_name = azurerm_resource_group.hub_resource_groups["hub_vnet_rg"].name
  location            = var.location
  address_space       = [var.bastion_vnet_address_space]
  provider            = azurerm.platform

  depends_on = [azurerm_resource_group.hub_resource_groups]
}

resource "azurerm_subnet" "bastion_subnet" {
  count                = var.enable_bastion ? 1 : 0
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.hub_resource_groups["hub_vnet_rg"].name
  virtual_network_name = azurerm_virtual_network.bastion_vnet[0].name
  address_prefixes     = [var.bastion_subnet_address_prefix]
  provider             = azurerm.platform
}

resource "azurerm_public_ip" "bastion_pip" {
  count               = var.enable_bastion ? 1 : 0
  name                = replace(var.bastion_vnet_name, "-vnet-", "-pip-bas-")
  resource_group_name = azurerm_resource_group.hub_resource_groups["hub_vnet_rg"].name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  provider            = azurerm.platform
}

resource "azurerm_bastion_host" "hub_bastion" {
  count               = var.enable_bastion ? 1 : 0
  name                = replace(var.bastion_vnet_name, "-vnet-", "-bas-")
  resource_group_name = azurerm_resource_group.hub_resource_groups["hub_vnet_rg"].name
  location            = var.location
  provider            = azurerm.platform

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion_subnet[0].id
    public_ip_address_id = azurerm_public_ip.bastion_pip[0].id
  }

  depends_on = [azurerm_subnet.bastion_subnet, azurerm_public_ip.bastion_pip]
}

#---------------------------------------
# Subnets
#---------------------------------------

resource "azurerm_subnet" "hub_gateway_subnet" {
  name                 = var.subnets.gateway.name
  resource_group_name  = azurerm_resource_group.hub_resource_groups["hub_vnet_rg"].name
  address_prefixes     = var.subnets.gateway.address_prefixes
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  provider             = azurerm.platform

  depends_on = [azurerm_virtual_network.hub_vnet]
}

# Cato LAN Subnet
resource "azurerm_subnet" "hub_cato_lan_subnet" {
  name                 = var.subnets.cato_lan.name
  resource_group_name  = azurerm_resource_group.hub_resource_groups["hub_vnet_rg"].name
  address_prefixes     = var.subnets.cato_lan.address_prefixes
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  provider             = azurerm.platform

  depends_on = [azurerm_virtual_network.hub_vnet]
}

# Cato WAN Subnet
resource "azurerm_subnet" "hub_cato_wan_subnet" {
  name                 = var.subnets.cato_wan.name
  resource_group_name  = azurerm_resource_group.hub_resource_groups["hub_vnet_rg"].name
  address_prefixes     = var.subnets.cato_wan.address_prefixes
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  provider             = azurerm.platform

  depends_on = [azurerm_virtual_network.hub_vnet]
}

# Cato MGMT Subnet
resource "azurerm_subnet" "hub_cato_mgmt_subnet" {
  name                 = var.subnets.cato_mgmt.name
  resource_group_name  = azurerm_resource_group.hub_resource_groups["hub_vnet_rg"].name
  address_prefixes     = var.subnets.cato_mgmt.address_prefixes
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  provider             = azurerm.platform

  depends_on = [azurerm_virtual_network.hub_vnet]
}

# Azure Firewall Subnet (required specific name)
resource "azurerm_subnet" "hub_firewall_subnet" {
  name                 = var.subnets.firewall.name
  resource_group_name  = azurerm_resource_group.hub_resource_groups["hub_vnet_rg"].name
  address_prefixes     = var.subnets.firewall.address_prefixes
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  provider             = azurerm.platform

  depends_on = [azurerm_virtual_network.hub_vnet]
}

# Shared Services Subnet
resource "azurerm_subnet" "hub_shared_services_subnet" {
  name                 = var.subnets.shared_services.name
  resource_group_name  = azurerm_resource_group.hub_resource_groups["hub_vnet_rg"].name
  address_prefixes     = var.subnets.shared_services.address_prefixes
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  provider             = azurerm.platform

  depends_on = [azurerm_virtual_network.hub_vnet]
}

# Private Endpoints Subnet
resource "azurerm_subnet" "hub_private_endpoints_subnet" {
  name                 = var.subnets.private_endpoints.name
  resource_group_name  = azurerm_resource_group.hub_resource_groups["hub_vnet_rg"].name
  address_prefixes     = var.subnets.private_endpoints.address_prefixes
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  provider             = azurerm.platform

  depends_on = [azurerm_virtual_network.hub_vnet]
}

#---------------------------------------
# Network Security Groups (NSG)
#---------------------------------------

resource "azurerm_network_security_group" "hub_shared_services_nsg" {
  name                = var.subnets.shared_services.nsg_name
  resource_group_name = azurerm_resource_group.hub_resource_groups["hub_vnet_rg"].name
  location            = var.location
  provider            = azurerm.platform

  security_rule {
    name                       = "allow-all-inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-all-outbound"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "hub_cato_lan_nsg" {
  name                = var.subnets.cato_lan.nsg_name
  resource_group_name = azurerm_resource_group.hub_resource_groups["hub_vnet_rg"].name
  location            = var.location
  provider            = azurerm.platform

  security_rule {
    name                       = "allow-all-inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-all-outbound"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "hub_cato_wan_nsg" {
  name                = var.subnets.cato_wan.nsg_name
  resource_group_name = azurerm_resource_group.hub_resource_groups["hub_vnet_rg"].name
  location            = var.location
  provider            = azurerm.platform

  security_rule {
    name                       = "allow-all-inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-all-outbound"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "hub_cato_mgmt_nsg" {
  name                = var.subnets.cato_mgmt.nsg_name
  resource_group_name = azurerm_resource_group.hub_resource_groups["hub_vnet_rg"].name
  location            = var.location
  provider            = azurerm.platform

  security_rule {
    name                       = "allow-all-inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-all-outbound"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "hub_private_endpoints_nsg" {
  name                = var.subnets.private_endpoints.nsg_name
  resource_group_name = azurerm_resource_group.hub_resource_groups["hub_vnet_rg"].name
  location            = var.location
  provider            = azurerm.platform

  security_rule {
    name                       = "allow-all-inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-all-outbound"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "hub_shared_services_nsg_assoc" {
  subnet_id                 = azurerm_subnet.hub_shared_services_subnet.id
  network_security_group_id = azurerm_network_security_group.hub_shared_services_nsg.id
  provider                  = azurerm.platform
}

resource "azurerm_subnet_network_security_group_association" "hub_cato_lan_nsg_assoc" {
  subnet_id                 = azurerm_subnet.hub_cato_lan_subnet.id
  network_security_group_id = azurerm_network_security_group.hub_cato_lan_nsg.id
  provider                  = azurerm.platform
}

resource "azurerm_subnet_network_security_group_association" "hub_cato_wan_nsg_assoc" {
  subnet_id                 = azurerm_subnet.hub_cato_wan_subnet.id
  network_security_group_id = azurerm_network_security_group.hub_cato_wan_nsg.id
  provider                  = azurerm.platform
}

resource "azurerm_subnet_network_security_group_association" "hub_cato_mgmt_nsg_assoc" {
  subnet_id                 = azurerm_subnet.hub_cato_mgmt_subnet.id
  network_security_group_id = azurerm_network_security_group.hub_cato_mgmt_nsg.id
  provider                  = azurerm.platform
}

resource "azurerm_subnet_network_security_group_association" "hub_private_endpoints_nsg_assoc" {
  subnet_id                 = azurerm_subnet.hub_private_endpoints_subnet.id
  network_security_group_id = azurerm_network_security_group.hub_private_endpoints_nsg.id
  provider                  = azurerm.platform
}

#---------------------------------------
# Route Tables (UDRs)
#---------------------------------------

resource "azurerm_route_table" "hub_shared_services_rt" {
  name                = var.subnets.shared_services.rt_name
  resource_group_name = azurerm_resource_group.hub_resource_groups["hub_vnet_rg"].name
  location            = var.location
  provider            = azurerm.platform

  route {
    name                   = "m3i-cus-shared-to-hub-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.hub_firewall.ip_configuration[0].private_ip_address
  }

  route {
    name                   = "m3i-cus-shared-to-eus2-via-hub-firewall"
    address_prefix         = "10.101.0.0/16"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.hub_firewall.ip_configuration[0].private_ip_address
  }

  depends_on = [azurerm_resource_group.hub_resource_groups]
}

resource "azurerm_subnet_route_table_association" "hub_shared_services_rt_assoc" {
  subnet_id      = azurerm_subnet.hub_shared_services_subnet.id
  route_table_id = azurerm_route_table.hub_shared_services_rt.id
  provider       = azurerm.platform
}

resource "azurerm_route_table" "hub_private_endpoints_rt" {
  name                = "m3i-hub-prod-cus-rt-snet-pe-01"
  resource_group_name = azurerm_resource_group.hub_resource_groups["hub_vnet_rg"].name
  location            = var.location
  provider            = azurerm.platform

  route {
    name                   = "m3i-cus-pe-to-hub-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.hub_firewall.ip_configuration[0].private_ip_address
  }

  route {
    name                   = "m3i-cus-pe-to-eus2-via-hub-firewall"
    address_prefix         = "10.101.0.0/16"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.hub_firewall.ip_configuration[0].private_ip_address
  }

  depends_on = [azurerm_resource_group.hub_resource_groups]
}

resource "azurerm_subnet_route_table_association" "hub_private_endpoints_rt_assoc" {
  subnet_id      = azurerm_subnet.hub_private_endpoints_subnet.id
  route_table_id = azurerm_route_table.hub_private_endpoints_rt.id
  provider       = azurerm.platform
}

resource "azurerm_route_table" "hub_firewall_rt" {
  name                = "m3i-hub-prod-cus-rt-snet-azfw-01"
  resource_group_name = azurerm_resource_group.hub_resource_groups["hub_vnet_rg"].name
  location            = var.location
  provider            = azurerm.platform

  lifecycle {
    # Additional routes are managed via azurerm_route resources.
    ignore_changes = [route]
  }

  depends_on = [azurerm_resource_group.hub_resource_groups]
}

resource "azurerm_route" "hub_firewall_to_other_region" {
  count               = local.other_region_firewall_private_ip_effective != "" ? 1 : 0
  name                = "m3i-cus-to-eus2-firewall"
  resource_group_name = azurerm_resource_group.hub_resource_groups["hub_vnet_rg"].name
  route_table_name    = azurerm_route_table.hub_firewall_rt.name
  address_prefix      = "10.101.0.0/16"
  next_hop_type       = "VirtualAppliance"
  next_hop_in_ip_address = local.other_region_firewall_private_ip_effective
  provider            = azurerm.platform
}

resource "azurerm_subnet_route_table_association" "hub_firewall_rt_assoc" {
  subnet_id      = azurerm_subnet.hub_firewall_subnet.id
  route_table_id = azurerm_route_table.hub_firewall_rt.id
  provider       = azurerm.platform
}

#---------------------------------------
# Azure Firewall
#---------------------------------------

resource "azurerm_public_ip" "hub_firewall_pip" {
  name                = local.hub_fw_pip_name
  resource_group_name = azurerm_resource_group.hub_resource_groups["hub_vnet_rg"].name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  provider            = azurerm.platform
}

resource "azurerm_firewall_policy" "hub_firewall_policy" {
  name                     = local.hub_fw_policy_name
  location                 = var.location
  resource_group_name      = azurerm_resource_group.hub_resource_groups["hub_vnet_rg"].name
  provider                 = azurerm.platform
  sku                      = var.firewall_config.sku_tier
  threat_intelligence_mode = var.firewall_config.threat_intelligence_mode

  depends_on = [azurerm_resource_group.hub_resource_groups]
}

resource "azurerm_firewall" "hub_firewall" {
  name                = local.hub_fw_name
  resource_group_name = azurerm_resource_group.hub_resource_groups["hub_vnet_rg"].name
  location            = var.location
  sku_name            = var.firewall_config.sku_name
  sku_tier            = var.firewall_config.sku_tier
  provider            = azurerm.platform

  ip_configuration {
    name                 = "fw-ipconfig"
    subnet_id            = azurerm_subnet.hub_firewall_subnet.id
    public_ip_address_id = azurerm_public_ip.hub_firewall_pip.id
  }

  firewall_policy_id = azurerm_firewall_policy.hub_firewall_policy.id

  depends_on = [
    azurerm_firewall_policy.hub_firewall_policy,
    azurerm_subnet.hub_firewall_subnet
  ]
}

#---------------------------------------
# Firewall Policy Rules
#---------------------------------------

resource "azurerm_firewall_policy_rule_collection_group" "hub_network_rules" {
  name               = "DefaultNetworkRuleCollectionGroup"
  firewall_policy_id = azurerm_firewall_policy.hub_firewall_policy.id
  priority           = 200
  provider           = azurerm.platform

  network_rule_collection {
    name     = "DefaultNetworkRuleCollection"
    action   = "Allow"
    priority = 150
    
    rule {
      name                  = "allow-dns"
      description           = "Allow DNS traffic"
      protocols             = ["UDP"]
      source_addresses      = ["*"]
      destination_ports     = ["53"]
      destination_addresses = ["*"]
    }

    rule {
      name                  = "allow-hub-to-spokes"
      description           = "Allow hub to spoke VNet traffic"
      protocols             = ["TCP", "UDP", "ICMP"]
      source_addresses      = [
        "10.100.0.0/16",
        "10.101.0.0/16"
      ]
      destination_ports     = ["*"]
      destination_addresses = [
        "10.100.0.0/16",
        "10.101.0.0/16"
      ]
    }
  }

  depends_on = [azurerm_firewall_policy.hub_firewall_policy]
}

resource "azurerm_firewall_policy_rule_collection_group" "hub_app_rules" {
  name               = "DefaultApplicationRuleCollectionGroup"
  firewall_policy_id = azurerm_firewall_policy.hub_firewall_policy.id
  priority           = 300
  provider           = azurerm.platform

  application_rule_collection {
    name     = "DefaultApplicationRuleCollection"
    action   = "Allow"
    priority = 100
    
    rule {
      name        = "allow-internet"
      description = "Allow outbound internet traffic"
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
      destination_fqdns = ["*"]
      source_addresses  = ["*"]
    }
  }

  depends_on = [azurerm_firewall_policy.hub_firewall_policy]
}

#---------------------------------------
# NAT Gateway (for outbound internet access)
#---------------------------------------

resource "azurerm_public_ip" "hub_natgw_pip" {
  name                = local.hub_natgw_pip_name
  resource_group_name = azurerm_resource_group.hub_resource_groups["hub_vnet_rg"].name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  provider            = azurerm.platform
}

resource "azurerm_nat_gateway" "hub_natgw" {
  name                = local.hub_natgw_name
  resource_group_name = azurerm_resource_group.hub_resource_groups["hub_vnet_rg"].name
  location            = var.location
  provider            = azurerm.platform

  depends_on = [azurerm_public_ip.hub_natgw_pip]
}

resource "azurerm_nat_gateway_public_ip_association" "hub_natgw_pip_assoc" {
  nat_gateway_id       = azurerm_nat_gateway.hub_natgw.id
  public_ip_address_id = azurerm_public_ip.hub_natgw_pip.id
  provider             = azurerm.platform
}

resource "azurerm_subnet_nat_gateway_association" "hub_firewall_subnet_natgw" {
  subnet_id      = azurerm_subnet.hub_firewall_subnet.id
  nat_gateway_id = azurerm_nat_gateway.hub_natgw.id
  provider       = azurerm.platform
}

#---------------------------------------
# Log Analytics Workspace
#---------------------------------------

resource "azurerm_log_analytics_workspace" "hub_laws" {
  count               = var.enable_log_analytics ? 1 : 0
  name                = local.hub_laws_name
  resource_group_name = azurerm_resource_group.hub_resource_groups["hub_laws_rg"].name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = var.log_analytics_retention_days
  provider            = azurerm.platform
}

resource "azurerm_monitor_diagnostic_setting" "hub_firewall_diagnostics" {
  count                      = var.enable_log_analytics ? 1 : 0
  name                       = "fw-diagnostics"
  target_resource_id         = azurerm_firewall.hub_firewall.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.hub_laws[0].id
  provider                   = azurerm.platform

  enabled_log {
    category = "AzureFirewallNetworkRule"
  }

  enabled_log {
    category = "AzureFirewallApplicationRule"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_data_collection_rule" "dc_base_monitoring" {
  count               = var.enable_log_analytics && var.enable_dc_vms ? 1 : 0
  name                = local.hub_dcr_name
  resource_group_name = azurerm_resource_group.hub_resource_groups["hub_laws_rg"].name
  location            = var.location
  provider            = azurerm.platform

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.hub_laws[0].id
      name                  = "dc-laws-destination"
    }
  }

  data_flow {
    streams      = ["Microsoft-Event", "Microsoft-Perf"]
    destinations = ["dc-laws-destination"]
  }

  data_sources {
    windows_event_log {
      name           = "dc-windows-events"
      streams        = ["Microsoft-Event"]
      x_path_queries = [
        "Application!*[System[(Level=1 or Level=2 or Level=3)]]",
        "System!*[System[(Level=1 or Level=2 or Level=3)]]"
      ]
    }

    performance_counter {
      name                          = "dc-core-perf"
      streams                       = ["Microsoft-Perf"]
      sampling_frequency_in_seconds = 60
      counter_specifiers = [
        "\\Processor Information(_Total)\\% Processor Time",
        "\\Memory\\% Committed Bytes In Use",
        "\\LogicalDisk(_Total)\\% Free Space",
        "\\LogicalDisk(_Total)\\Avg. Disk sec/Transfer",
        "\\Network Interface(*)\\Bytes Total/sec"
      ]
    }
  }
}

#---------------------------------------
# Recovery Services Vault
#---------------------------------------

resource "azurerm_recovery_services_vault" "hub_rsv" {
  count               = var.enable_backup ? 1 : 0
  name                = local.hub_rsv_name
  resource_group_name = azurerm_resource_group.hub_resource_groups["hub_rsv_rg"].name
  location            = var.location
  sku                 = "Standard"
  storage_mode_type   = "GeoRedundant"
  provider            = azurerm.platform

  cross_region_restore_enabled  = true
  public_network_access_enabled = true
}

resource "azurerm_backup_policy_vm" "hub_backup_policy" {
  count               = var.enable_backup ? 1 : 0
  name                = local.hub_rsv_backup_policy_name
  resource_group_name = azurerm_resource_group.hub_resource_groups["hub_rsv_rg"].name
  recovery_vault_name = azurerm_recovery_services_vault.hub_rsv[0].name
  provider            = azurerm.platform

  timezone = "UTC"

  backup {
    frequency = "Daily"
    time      = "03:00"
  }

  retention_daily {
    count = 7
  }
}

resource "azurerm_backup_protected_vm" "dc_vm_backup" {
  count               = var.enable_backup && var.enable_dc_vms ? var.dc_vm_count : 0
  resource_group_name = azurerm_resource_group.hub_resource_groups["hub_rsv_rg"].name
  recovery_vault_name = azurerm_recovery_services_vault.hub_rsv[0].name
  source_vm_id        = azurerm_windows_virtual_machine.dc_vm[count.index].id
  backup_policy_id    = azurerm_backup_policy_vm.hub_backup_policy[0].id
  provider            = azurerm.platform
}

#---------------------------------------
# Azure Key Vault
#---------------------------------------

resource "azurerm_key_vault" "hub_keyvault" {
  count               = var.enable_key_vault ? 1 : 0
  name                = "m3i-hub-prod-cus-kv"
  location            = var.location
  resource_group_name = azurerm_resource_group.hub_resource_groups["hub_kv_rg"].name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = var.key_vault_sku
  provider            = azurerm.platform

  enabled_for_deployment          = true
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true
  rbac_authorization_enabled      = true
  purge_protection_enabled        = true
  soft_delete_retention_days      = 7

  depends_on = [azurerm_resource_group.hub_resource_groups]
}

resource "azurerm_role_assignment" "hub_keyvault_secrets_officer" {
  count                = var.enable_key_vault ? 1 : 0
  scope                = azurerm_key_vault.hub_keyvault[0].id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
  provider             = azurerm.platform
}

#---------------------------------------
# Domain Controller VMs
#---------------------------------------

# Generate random password for DCs if not provided
resource "random_password" "dc_admin_password" {
  count       = var.enable_dc_vms && var.admin_password == "" ? 1 : 0
  length      = 20
  special     = true
  override_special = "!@#$%^&*()_+-=[]{}|:;<>?,./"
}

# Store DC admin password in Key Vault
resource "azurerm_key_vault_secret" "dc_admin_password" {
  count           = var.enable_key_vault && var.enable_dc_vms ? 1 : 0
  name            = "dc-admin-password"
  value           = var.admin_password != "" ? var.admin_password : random_password.dc_admin_password[0].result
  key_vault_id    = azurerm_key_vault.hub_keyvault[0].id
  provider        = azurerm.platform

  depends_on = [
    azurerm_role_assignment.hub_keyvault_secrets_officer
  ]
}

resource "azurerm_availability_set" "dc_vm_as" {
  count               = var.enable_dc_vms ? 1 : 0
  name                = "m3i-hub-prod-cus-as-dc-01"
  location            = var.location
  resource_group_name = azurerm_resource_group.hub_resource_groups["hub_vm_rg"].name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 5
  managed             = true
  provider            = azurerm.platform
}

# Network Interfaces for DC VMs
resource "azurerm_network_interface" "dc_nic" {
  count               = var.enable_dc_vms ? var.dc_vm_count : 0
  name                = "az-cus-dc0${count.index + 1}-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.hub_resource_groups["hub_vm_rg"].name
  provider            = azurerm.platform

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.hub_shared_services_subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  depends_on = [azurerm_subnet.hub_shared_services_subnet]
}

# Associate NSG with DC NICs
resource "azurerm_network_interface_security_group_association" "dc_nsg_assoc" {
  count                    = var.enable_dc_vms ? var.dc_vm_count : 0
  network_interface_id      = azurerm_network_interface.dc_nic[count.index].id
  network_security_group_id = azurerm_network_security_group.hub_shared_services_nsg.id
  provider                  = azurerm.platform
}

# Domain Controller VMs
resource "azurerm_windows_virtual_machine" "dc_vm" {
  count               = var.enable_dc_vms ? var.dc_vm_count : 0
  name                = "az-cus-dc0${count.index + 1}"
  location            = var.location
  resource_group_name = azurerm_resource_group.hub_resource_groups["hub_vm_rg"].name
  provider            = azurerm.platform

  admin_username = "azureuser"
  admin_password = var.admin_password != "" ? var.admin_password : random_password.dc_admin_password[0].result

  size = var.dc_vm_size

  availability_set_id = azurerm_availability_set.dc_vm_as[0].id

  network_interface_ids = [azurerm_network_interface.dc_nic[count.index].id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = var.dc_os_image_publisher
    offer     = var.dc_os_image_offer
    sku       = var.dc_os_image_sku
    version   = var.dc_os_image_version
  }

  depends_on = [
    azurerm_availability_set.dc_vm_as,
    azurerm_network_interface.dc_nic,
    azurerm_network_interface_security_group_association.dc_nsg_assoc
  ]
}

resource "azurerm_virtual_machine_extension" "dc_ama" {
  count                = var.enable_log_analytics && var.enable_dc_vms ? var.dc_vm_count : 0
  name                 = "AzureMonitorWindowsAgent"
  virtual_machine_id   = azurerm_windows_virtual_machine.dc_vm[count.index].id
  publisher            = "Microsoft.Azure.Monitor"
  type                 = "AzureMonitorWindowsAgent"
  type_handler_version = "1.0"
  provider             = azurerm.platform

  auto_upgrade_minor_version = true
}

resource "azurerm_monitor_data_collection_rule_association" "dc_base_monitoring_assoc" {
  count                   = var.enable_log_analytics && var.enable_dc_vms ? var.dc_vm_count : 0
  name                    = "dc-base-monitoring-assoc-${count.index + 1}"
  target_resource_id      = azurerm_windows_virtual_machine.dc_vm[count.index].id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.dc_base_monitoring[0].id
  provider                = azurerm.platform

  depends_on = [azurerm_virtual_machine_extension.dc_ama]
}

#---------------------------------------
# VNet Peering: Hub to Spokes (Prod and NonProd)
#---------------------------------------

resource "azurerm_virtual_network_peering" "bastion_to_hub" {
  count                     = var.enable_bastion ? 1 : 0
  name                      = "m3i-hub-bastion-cus-peering-to-hub-cus"
  resource_group_name       = azurerm_resource_group.hub_resource_groups["hub_vnet_rg"].name
  virtual_network_name      = azurerm_virtual_network.bastion_vnet[0].name
  remote_virtual_network_id = azurerm_virtual_network.hub_vnet.id
  provider                  = azurerm.platform

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "hub_to_bastion" {
  count                     = var.enable_bastion ? 1 : 0
  name                      = "m3i-hub-prod-cus-peering-to-bastion-cus"
  resource_group_name       = azurerm_resource_group.hub_resource_groups["hub_vnet_rg"].name
  virtual_network_name      = azurerm_virtual_network.hub_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.bastion_vnet[0].id
  provider                  = azurerm.platform

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "bastion_to_spoke_prod" {
  count                     = var.enable_bastion && var.enable_hub_to_spoke_peering && var.spoke_prod_subscription_id != "" ? 1 : 0
  name                      = "m3i-hub-bastion-cus-peering-to-lz-prod"
  resource_group_name       = azurerm_resource_group.hub_resource_groups["hub_vnet_rg"].name
  virtual_network_name      = azurerm_virtual_network.bastion_vnet[0].name
  remote_virtual_network_id = local.spoke_prod_vnet_id
  provider                  = azurerm.platform

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "spoke_prod_to_bastion" {
  count                     = var.enable_bastion && var.enable_hub_to_spoke_peering && var.spoke_prod_subscription_id != "" ? 1 : 0
  name                      = "m3i-lz-prod-cus-peering-to-bastion-cus"
  resource_group_name       = local.spoke_prod_vnet_rg
  virtual_network_name      = local.spoke_prod_vnet_name
  remote_virtual_network_id = azurerm_virtual_network.bastion_vnet[0].id
  provider                  = azurerm.spoke_prod

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "bastion_to_spoke_nonprod" {
  count                     = var.enable_bastion && var.enable_hub_to_spoke_peering && var.spoke_nonprod_subscription_id != "" ? 1 : 0
  name                      = "m3i-hub-bastion-cus-peering-to-lz-nonprod"
  resource_group_name       = azurerm_resource_group.hub_resource_groups["hub_vnet_rg"].name
  virtual_network_name      = azurerm_virtual_network.bastion_vnet[0].name
  remote_virtual_network_id = local.spoke_nonprod_vnet_id
  provider                  = azurerm.platform

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "spoke_nonprod_to_bastion" {
  count                     = var.enable_bastion && var.enable_hub_to_spoke_peering && var.spoke_nonprod_subscription_id != "" ? 1 : 0
  name                      = "m3i-lz-nonprod-cus-peering-to-bastion-cus"
  resource_group_name       = local.spoke_nonprod_vnet_rg
  virtual_network_name      = local.spoke_nonprod_vnet_name
  remote_virtual_network_id = azurerm_virtual_network.bastion_vnet[0].id
  provider                  = azurerm.spoke_nonprod

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# Hub to Spoke Prod peering
resource "azurerm_virtual_network_peering" "hub_to_spoke_prod" {
  count                     = var.enable_hub_to_spoke_peering && var.spoke_prod_subscription_id != "" ? 1 : 0
  name                      = "m3i-hub-prod-cus-peering-to-lz-prod"
  resource_group_name       = azurerm_resource_group.hub_resource_groups["hub_vnet_rg"].name
  virtual_network_name      = azurerm_virtual_network.hub_vnet.name
  remote_virtual_network_id = local.spoke_prod_vnet_id
  provider                  = azurerm.platform

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false

  depends_on = [azurerm_virtual_network.hub_vnet]
}

# Hub to Spoke NonProd peering
resource "azurerm_virtual_network_peering" "hub_to_spoke_nonprod" {
  count                     = var.enable_hub_to_spoke_peering && var.spoke_nonprod_subscription_id != "" ? 1 : 0
  name                      = "m3i-hub-prod-cus-peering-to-lz-nonprod"
  resource_group_name       = azurerm_resource_group.hub_resource_groups["hub_vnet_rg"].name
  virtual_network_name      = azurerm_virtual_network.hub_vnet.name
  remote_virtual_network_id = local.spoke_nonprod_vnet_id
  provider                  = azurerm.platform

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false

  depends_on = [azurerm_virtual_network.hub_vnet]
}

# CentralUS Hub to EastUS2 Hub peering
resource "azurerm_virtual_network_peering" "hub_to_hub_eus2" {
  count                     = var.enable_hub_to_hub_peering && var.other_region_hub_vnet_name != "" && var.other_region_hub_resource_group != "" && var.other_region_hub_subscription_id != "" ? 1 : 0
  name                      = "m3i-hub-prod-cus-peering-to-hub-eus2"
  resource_group_name       = azurerm_resource_group.hub_resource_groups["hub_vnet_rg"].name
  virtual_network_name      = azurerm_virtual_network.hub_vnet.name
  remote_virtual_network_id = local.other_region_hub_vnet_id
  provider                  = azurerm.platform

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false

  depends_on = [azurerm_virtual_network.hub_vnet]
}

