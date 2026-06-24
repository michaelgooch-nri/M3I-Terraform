# M3I Spoke (Non-Prod) - EastUS2
# Backend Configuration for Remote State Storage

# NOTE: Create the storage account and container manually beforehand:
#   az group create --name m3i-spoke-nonprod-rg-tf-eus2 --location EastUS2
#   az storage account create --name m3ispokenonprodstortfcus --resource-group m3i-spoke-nonprod-rg-tf-eus2 --location EastUS2 --sku Standard_LRS
#   az storage container create --name tfstate --account-name m3ispokenonprodstortfcus

