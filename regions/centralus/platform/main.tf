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
    storage_account_name = "m3ihubprodstortfcus"
    container_name       = "tfstate"
    key                  = "m3i-platform-eus2.tfstate"
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
  tags     = merge(local.tags, var.common_tags)
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
  tags                = merge(local.tags, var.common_tags)

  depends_on = [azurerm_resource_group.hub_resource_groups]
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
  tags                = merge(local.tags, var.common_tags)

  # Add ingress/egress rules as needed for your environment
  # Example: allow inter-vnet communication, DNS, etc.
}

resource "azurerm_subnet_network_security_group_association" "hub_shared_services_nsg_assoc" {
  subnet_id                 = azurerm_subnet.hub_shared_services_subnet.id
  network_security_group_id = azurerm_network_security_group.hub_shared_services_nsg.id
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
  tags                = merge(local.tags, var.common_tags)

  route {
    name                   = "m3i-cus-shared-to-hub-firewall"
    address_prefix         = "0.0.0.0/0"
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
  tags                = merge(local.tags, var.common_tags)

  route {
    name                   = "m3i-cus-pe-to-hub-firewall"
    address_prefix         = "0.0.0.0/0"
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
  tags                = merge(local.tags, var.common_tags)

  # Force all Azure Firewall egress to Cato vSocket LAN IP.
  route {
    name                   = "m3i-cus-default-to-cato-vsocket"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = cidrhost(var.subnets.cato_lan.address_prefixes[0], 4)
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
  tags                = merge(local.tags, var.common_tags)
}

resource "azurerm_firewall_policy" "hub_firewall_policy" {
  name                     = local.hub_fw_policy_name
  location                 = var.location
  resource_group_name      = azurerm_resource_group.hub_resource_groups["hub_vnet_rg"].name
  provider                 = azurerm.platform
  sku                      = var.firewall_config.sku_tier
  threat_intelligence_mode = var.firewall_config.threat_intelligence_mode
  tags                     = merge(local.tags, var.common_tags)

  depends_on = [azurerm_resource_group.hub_resource_groups]
}

resource "azurerm_firewall" "hub_firewall" {
  name                = local.hub_fw_name
  resource_group_name = azurerm_resource_group.hub_resource_groups["hub_vnet_rg"].name
  location            = var.location
  sku_name            = var.firewall_config.sku_name
  sku_tier            = var.firewall_config.sku_tier
  provider            = azurerm.platform
  tags                = merge(local.tags, var.common_tags)

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

# Reserve first usable IP in Cato LAN subnet for future vSocket VM.
resource "azurerm_network_interface" "cato_vsocket_lan_nic" {
  name                = "m3i-hub-prod-cus-nic-cato-lan-01"
  location            = var.location
  resource_group_name = azurerm_resource_group.hub_resource_groups["hub_vnet_rg"].name
  provider            = azurerm.platform
  ip_forwarding_enabled = true
  tags                = merge(local.tags, var.common_tags)

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.hub_cato_lan_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(var.subnets.cato_lan.address_prefixes[0], 4)
  }

  depends_on = [azurerm_subnet.hub_cato_lan_subnet]
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

    # Placeholder: Allow hub to spoke traffic (update with actual IP ranges)
    rule {
      name                  = "allow-hub-to-spokes"
      description           = "Allow hub to spoke VNet traffic"
      protocols             = ["TCP", "UDP", "ICMP"]
      source_addresses      = [var.hub_vnet_address_space]
      destination_ports     = ["*"]
      destination_addresses = ["10.0.0.0/8"]  # Placeholder for spoke ranges
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
  tags                = merge(local.tags, var.common_tags)
}

resource "azurerm_nat_gateway" "hub_natgw" {
  name                = local.hub_natgw_name
  resource_group_name = azurerm_resource_group.hub_resource_groups["hub_vnet_rg"].name
  location            = var.location
  provider            = azurerm.platform
  tags                = merge(local.tags, var.common_tags)

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
  tags                = merge(local.tags, var.common_tags)
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
  tags                = merge(local.tags, var.common_tags)

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.hub_laws[0].id
      name                  = "dc-laws-destination"
    }
  }

  data_flow {
    streams      = ["Microsoft-WindowsEvent", "Microsoft-Perf"]
    destinations = ["dc-laws-destination"]
  }

  data_sources {
    windows_event_log {
      name           = "dc-windows-events"
      streams        = ["Microsoft-WindowsEvent"]
      x_path_queries = [
        "Application!*[System[(Level=1 or Level=2 or Level=3)]]",
        "System!*[System[(Level=1 or Level=2 or Level=3)]]",
        "Security!*[System[(band(Keywords,4503599627370496))]]"
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
  tags                = merge(local.tags, var.common_tags)

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
  tags                = merge(local.tags, var.common_tags)

  enabled_for_deployment          = true
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true
  purge_protection_enabled        = true
  soft_delete_retention_days      = 7

  depends_on = [azurerm_resource_group.hub_resource_groups]
}

resource "azurerm_key_vault_access_policy" "hub_keyvault_policy" {
  count       = var.enable_key_vault ? 1 : 0
  key_vault_id = azurerm_key_vault.hub_keyvault[0].id
  tenant_id   = data.azurerm_client_config.current.tenant_id
  object_id   = data.azurerm_client_config.current.object_id
  provider    = azurerm.platform

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
}

# Network Interfaces for DC VMs
resource "azurerm_network_interface" "dc_nic" {
  count               = var.enable_dc_vms ? var.dc_vm_count : 0
  name                = "az-cus-dc0${count.index + 1}-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.hub_resource_groups["hub_vm_rg"].name
  provider            = azurerm.platform
  tags                = merge(local.tags, var.common_tags)

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
  tags                = merge(local.tags, var.common_tags)

  admin_username = "azureuser"
  admin_password = var.admin_password != "" ? var.admin_password : random_password.dc_admin_password[0].result

  size = var.dc_vm_size

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

# Data source to lookup Prod spoke VNet
data "azurerm_virtual_network" "spoke_prod_vnet" {
  count               = var.enable_hub_to_spoke_peering && var.spoke_prod_subscription_id != "" ? 1 : 0
  name                = "m3i-lz-prod-cus-vnet-01"
  resource_group_name = "m3i-lz-prod-cus-rg-vnet"
  provider            = azurerm.spoke_prod
}

# Data source to lookup NonProd spoke VNet
data "azurerm_virtual_network" "spoke_nonprod_vnet" {
  count               = var.enable_hub_to_spoke_peering && var.spoke_nonprod_subscription_id != "" ? 1 : 0
  name                = "m3i-lz-nonprod-cus-vnet-01"
  resource_group_name = "m3i-lz-nonprod-cus-rg-vnet"
  provider            = azurerm.spoke_nonprod
}

# Hub to Spoke Prod peering
resource "azurerm_virtual_network_peering" "hub_to_spoke_prod" {
  count                     = var.enable_hub_to_spoke_peering && var.spoke_prod_subscription_id != "" ? 1 : 0
  name                      = "m3i-hub-prod-cus-peering-to-lz-prod"
  resource_group_name       = azurerm_resource_group.hub_resource_groups["hub_vnet_rg"].name
  virtual_network_name      = azurerm_virtual_network.hub_vnet.name
  remote_virtual_network_id = data.azurerm_virtual_network.spoke_prod_vnet[0].id
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
  remote_virtual_network_id = data.azurerm_virtual_network.spoke_nonprod_vnet[0].id
  provider                  = azurerm.platform

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false

  depends_on = [azurerm_virtual_network.hub_vnet]
}
