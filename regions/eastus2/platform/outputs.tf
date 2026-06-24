# M3I Platform Hub - EastUS2
# Output Values for Cross-Module Reference (for spoke peering)

output "hub_vnet_id" {
  description = "Resource ID of the hub virtual network"
  value       = azurerm_virtual_network.hub_vnet.id
}

output "hub_vnet_name" {
  description = "Name of the hub virtual network"
  value       = azurerm_virtual_network.hub_vnet.name
}

output "hub_vnet_address_space" {
  description = "Address space of the hub virtual network"
  value       = azurerm_virtual_network.hub_vnet.address_space
}

output "hub_resource_group_name" {
  description = "Name of the hub resource group"
  value       = azurerm_resource_group.hub_resource_groups["hub_vnet_rg"].name
}

output "hub_firewall_id" {
  description = "Resource ID of the Azure Firewall"
  value       = azurerm_firewall.hub_firewall.id
}

output "hub_firewall_private_ip" {
  description = "Private IP address of the Azure Firewall"
  value       = azurerm_firewall.hub_firewall.ip_configuration[0].private_ip_address
}

output "hub_shared_services_subnet_id" {
  description = "Resource ID of the shared services subnet"
  value       = azurerm_subnet.hub_shared_services_subnet.id
}

output "hub_firewall_subnet_id" {
  description = "Resource ID of the firewall subnet"
  value       = azurerm_subnet.hub_firewall_subnet.id
}

output "hub_firewall_policy_id" {
  description = "Resource ID of the firewall policy"
  value       = azurerm_firewall_policy.hub_firewall_policy.id
}

output "hub_laws_workspace_id" {
  description = "Resource ID of the Log Analytics Workspace"
  value       = var.enable_log_analytics ? azurerm_log_analytics_workspace.hub_laws[0].id : null
}

output "hub_rsv_id" {
  description = "Resource ID of the Recovery Services Vault"
  value       = var.enable_backup ? azurerm_recovery_services_vault.hub_rsv[0].id : null
}

output "hub_keyvault_id" {
  description = "Resource ID of the Key Vault"
  value       = var.enable_key_vault ? azurerm_key_vault.hub_keyvault[0].id : null
}

output "dc_vm_ids" {
  description = "Resource IDs of the Domain Controller VMs"
  value       = var.enable_dc_vms ? azurerm_windows_virtual_machine.dc_vm[*].id : []
}

output "dc_vm_names" {
  description = "Names of the Domain Controller VMs"
  value       = var.enable_dc_vms ? azurerm_windows_virtual_machine.dc_vm[*].name : []
}

output "dc_vm_private_ips" {
  description = "Private IP addresses of the Domain Controller VMs"
  value       = var.enable_dc_vms ? azurerm_network_interface.dc_nic[*].private_ip_address : []
}

output "dc_admin_password_secret_name" {
  description = "Name of the Key Vault secret containing the DC admin password"
  value       = var.enable_dc_vms && var.enable_key_vault ? azurerm_key_vault_secret.dc_admin_password[0].name : null
  sensitive   = true
}

