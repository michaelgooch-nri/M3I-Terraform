# M3I Platform Hub - EastUS2
# Backend Configuration for Remote State Storage

# This file configures Terraform to store state in Azure Blob Storage
# Update the placeholders with your actual values:
# - subscription_id: Your platform subscription ID
# - storage_account_name: Pre-created storage account name (must be globally unique)
# - resource_group_name: Resource group containing the storage account

# NOTE: The storage account, container, and resource group must be created manually beforehand
# Storage account name must be lowercase, globally unique, and 3-24 characters
# Example creation:
#   az group create --name m3i-hub-prod-rg-tf-eus2 --location EastUS2
#   az storage account create --name m3ihubprodstortfeus2 --resource-group m3i-hub-prod-rg-tf-eus2 --location EastUS2 --sku Standard_LRS
#   az storage container create --name tfstate --account-name m3ihubprodstortfeus2

