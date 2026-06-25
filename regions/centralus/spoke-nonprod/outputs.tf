# M3I Spoke (Non-Prod) - CentralUS
# Output Values

output "spoke_vnet_id" {
  description = "Resource ID of the spoke virtual network"
  value       = azurerm_virtual_network.spoke_vnet.id
}

output "spoke_vnet_name" {
  description = "Name of the spoke virtual network"
  value       = azurerm_virtual_network.spoke_vnet.name
}

output "spoke_vnet_address_space" {
  description = "Address space of the spoke virtual network"
  value       = azurerm_virtual_network.spoke_vnet.address_space
}

output "spoke_resource_group_name" {
  description = "Name of the spoke resource group"
  value       = azurerm_resource_group.spoke_resource_groups["spoke_vnet_rg"].name
}

output "spoke_vm_subnet_id" {
  description = "Resource ID of the VM subnet"
  value       = azurerm_subnet.spoke_vm_subnet.id
}

output "spoke_db_subnet_id" {
  description = "Resource ID of the database subnet"
  value       = azurerm_subnet.spoke_db_subnet.id
}

output "hub_vnet_id" {
  description = "Resource ID of the hub virtual network"
  value       = local.hub_vnet_id
  sensitive   = true
}
