# M3I Spoke (Prod) - CentralUS
# Backend Configuration for Remote State Storage

# NOTE: Create the storage account and container manually beforehand:
#   az group create --name m3i-spoke-prod-rg-tf-cus --location centralus
#   az storage account create --name m3ispokeprodstortfcus --resource-group m3i-spoke-prod-rg-tf-cus --location centralus --sku Standard_LRS
#   az storage container create --name tfstate --account-name m3ispokeprodstortfcus