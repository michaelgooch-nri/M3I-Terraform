# M3I Azure Infrastructure - Terraform IaC

This repository contains Terraform code for a multi-region Azure hub-and-spoke landing zone across CentralUS and EastUS2, with separate subscriptions for platform, production spoke, and non-production spoke per region.

## Current Topology

- Regions: `centralus`, `eastus2`
- Subscription model per region:
  - `platform` (hub)
  - `spoke-prod`
  - `spoke-nonprod`
- Architecture pattern: hub-and-spoke with centralized Azure Firewall in each regional hub
- Cross-subscription peering:
  - Spoke to hub (all spokes)
  - Hub to spoke (from hub side)
  - Hub to hub (cross-region)

## Address Space Plan

### Hubs
- CentralUS hub: `10.100.0.0/22`
- EastUS2 hub: `10.101.0.0/22`

### Spokes
- CentralUS spoke-prod: `10.100.4.0/22`
- CentralUS spoke-nonprod: `10.100.8.0/22`
- EastUS2 spoke-prod: `10.101.4.0/22`
- EastUS2 spoke-nonprod: `10.101.8.0/22`

See `IP-SPACE-PLANNING.md` for detailed subnet allocation.

## Resource Group Layout

### Platform (Hub) RGs per region
- VNet RG: `m3i-hub-prod-rg-vnet-<region_abbr>`
- VM RG: `m3i-hub-prod-rg-vm-<region_abbr>`
- Key Vault RG: `m3i-hub-prod-rg-kv-<region_abbr>`
- Firewall RG: `m3i-hub-prod-rg-fw-<region_abbr>`
- Log Analytics RG: `m3i-hub-prod-rg-laws-<region_abbr>`
- Recovery Services Vault RG: `m3i-hub-prod-rg-rsv-<region_abbr>`

### Spoke RGs per region/environment
- VNet RG: `m3i-spoke-<env>-rg-vnet-<region_abbr>`
- VM RG: `m3i-spoke-<env>-rg-vm-<region_abbr>`
- Key Vault RG: `m3i-spoke-<env>-rg-kv-<region_abbr>`
- DB RG: `m3i-spoke-<env>-rg-db-<region_abbr>`

## Spoke Subnet CIDR Plan (Current)

- CentralUS spoke-prod
  - private-endpoints: `10.100.4.0/26`
  - vm: `10.100.4.128/25`
  - db: `10.100.5.0/25`
- CentralUS spoke-nonprod
  - private-endpoints: `10.100.8.0/26`
  - vm: `10.100.8.128/25`
  - db: `10.100.9.0/25`
- EastUS2 spoke-prod
  - private-endpoints: `10.101.4.0/26`
  - vm: `10.101.4.128/25`
  - db: `10.101.5.0/25`
- EastUS2 spoke-nonprod
  - private-endpoints: `10.101.8.0/26`
  - vm: `10.101.8.128/25`
  - db: `10.101.9.0/25`

## What Is Implemented

### Hub (Platform) Deployments
- Hub VNet and subnets:
  - `GatewaySubnet`
  - `cato-lan`
  - `cato-wan`
  - `cato-mgmt`
  - `AzureFirewallSubnet`
  - `private-endpoints`
  - `shared-services`
- Azure Firewall with policy and rule collection groups
- NAT Gateway and public IP for egress
- Log Analytics workspace and firewall diagnostic settings
- Recovery Services Vault (GRS, cross-region restore enabled) and VM backup policy
- Backup protection for all hub DC VMs in both regions (4 total with current defaults)
- Key Vault per hub
- Hub-to-spoke and hub-to-hub peering resources
- Active Directory VM foundations in each hub:
  - CentralUS: `AZ-CUS-DC01`, `AZ-CUS-DC02`
  - EastUS2: `AZ-EUS2-DC01`, `AZ-EUS2-DC02`
  - Size default: `Standard_D2s_v5` (2-core D-series)
  - OS default: Windows Server 2025 Datacenter
  - Admin password stored in hub Key Vault secret `dc-admin-password`
  - Base monitoring enabled via Azure Monitor Agent + Data Collection Rule to regional Log Analytics workspace
    - Windows Event logs: Application, System, Security (audit)
    - Performance counters: CPU, memory, disk free space/latency, network throughput (60s)

### Spoke Deployments
- Spoke VNet and subnets (`private-endpoints`, `vm`, `db`)
- NSGs and subnet associations
- Route tables and associations for VM/DB/Private Endpoints subnets
- Default route `0.0.0.0/0` to hub firewall (auto-resolved from hub remote state; optional override with `hub_firewall_private_ip`)
- Spoke-to-hub peering
- Key Vault per spoke (optional via flag)

## Repository Layout

```text
M3I-Terraform/
|- example.tfvars
|- IP-SPACE-PLANNING.md
|- README.md
|- modules/
|  |- hub-networking/
|  |- spoke-networking/
|  '- vnet-peering/
'- regions/
   |- centralus/
   |  |- platform/
   |  |- spoke-prod/
   |  '- spoke-nonprod/
   '- eastus2/
      |- platform/
      |- spoke-prod/
      '- spoke-nonprod/
```

## Deployment Order

Run Terraform per root module (each directory is independent state):

1. `regions/centralus/platform`
2. `regions/centralus/spoke-prod`
3. `regions/centralus/spoke-nonprod`
4. `regions/eastus2/platform`
5. `regions/eastus2/spoke-prod`
6. `regions/eastus2/spoke-nonprod`

Notes:
- Deploy both hubs first to obtain firewall private IP outputs.
- Spokes auto-read regional hub firewall IP from hub remote state (manual `hub_firewall_private_ip` remains as optional override).
- Keep `enable_hub_to_hub_peering` false in CentralUS until EastUS2 hub exists (or follow your staged plan).

## Core Variables to Review

In each deployment directory, verify:
- Subscription IDs (`platform_subscription_id`, `spoke_subscription_id` where applicable)
- Address spaces and subnet CIDRs
- Feature flags:
  - `enable_log_analytics`
  - `enable_backup`
  - `enable_key_vault`
  - `enable_dc_vms` (hub)
- DC settings (hub):
  - `dc_vm_count` (default `2`)
  - `dc_vm_size` (default `Standard_D2s_v5`)
  - `dc_os_image_*`
  - `admin_password` (blank = generated and stored in Key Vault)
- Inter-region firewall routing (hub):
  - `other_region_firewall_private_ip` (optional override; default behavior auto-resolves from other hub remote state)

## Tagging Strategy

All tagged resources use this pattern:

- `tags = merge(local.tags, var.common_tags)`

This means:

- `local.tags` provides module defaults.
- `common_tags` can add new keys and override existing defaults when keys overlap.

### Default Tags By Root Module

| Root Module | Default Tags |
|---|---|
| centralus/platform | environment=prod, project=m3i-azure-platform, region=centralus, managed_by=terraform |
| eastus2/platform | environment=prod, project=m3i-azure-platform, region=eastus2, managed_by=terraform |
| centralus/spoke-prod | environment=prod, project=m3i-azure-platform, region=centralus, spoke_type=workload, managed_by=terraform |
| centralus/spoke-nonprod | environment=nonprod, project=m3i-azure-platform, region=centralus, spoke_type=workload, managed_by=terraform |
| eastus2/spoke-prod | environment=prod, project=m3i-azure-platform, region=eastus2, spoke_type=workload, managed_by=terraform |
| eastus2/spoke-nonprod | environment=nonprod, project=m3i-azure-platform, region=eastus2, spoke_type=workload, managed_by=terraform |

### Where To Maintain Tag Defaults

- Update per-module defaults in each `local.tf`.
- Use each module's `common_tags` variable for environment-specific extensions.
- Keep the table above in sync whenever tag keys or values change in any `local.tf`.

## Route Table Matrix

| Scope | Route Table Name | Routes In Table | Applied To Subnet |
|---|---|---|---|
| CentralUS Hub | m3i-hub-prod-cus-rt-snet-shared-services-01 | m3i-cus-shared-to-hub-firewall: 0.0.0.0/0 -> VirtualAppliance (hub firewall private IP) | m3i-hub-prod-cus-snet-shared-services-01 |
| CentralUS Hub | m3i-hub-prod-cus-rt-snet-pe-01 | m3i-cus-pe-to-hub-firewall: 0.0.0.0/0 -> VirtualAppliance (hub firewall private IP) | m3i-hub-prod-cus-snet-pe-01 |
| CentralUS Hub | m3i-hub-prod-cus-rt-snet-azfw-01 | m3i-cus-default-to-cato-vsocket: 0.0.0.0/0 -> VirtualAppliance (Cato LAN reserved IP); m3i-cus-to-eus2-firewall: 10.101.0.0/16 -> VirtualAppliance (other_region_firewall_private_ip, conditional) | AzureFirewallSubnet |
| EastUS2 Hub | m3i-hub-prod-eus2-rt-snet-shared-services-01 | m3i-eus2-shared-to-hub-firewall: 0.0.0.0/0 -> VirtualAppliance (hub firewall private IP) | m3i-hub-prod-eus2-snet-shared-services-01 |
| EastUS2 Hub | m3i-hub-prod-eus2-rt-snet-pe-01 | m3i-eus2-pe-to-hub-firewall: 0.0.0.0/0 -> VirtualAppliance (hub firewall private IP) | m3i-hub-prod-eus2-snet-pe-01 |
| EastUS2 Hub | m3i-hub-prod-eus2-rt-snet-azfw-01 | m3i-eus2-default-to-cato-vsocket: 0.0.0.0/0 -> VirtualAppliance (Cato LAN reserved IP); m3i-eus2-to-cus-firewall: 10.100.0.0/16 -> VirtualAppliance (other_region_firewall_private_ip, conditional) | AzureFirewallSubnet |
| CentralUS Spoke Prod | m3i-lz-prod-cus-rt-vm-01 | m3i-cus-default-to-hub-firewall: 0.0.0.0/0 -> VirtualAppliance (hub_firewall_private_ip) | m3i-lz-prod-cus-snet-vm-01 |
| CentralUS Spoke Prod | m3i-lz-prod-cus-rt-db-01 | m3i-cus-default-to-hub-firewall: 0.0.0.0/0 -> VirtualAppliance (hub_firewall_private_ip) | m3i-lz-prod-cus-snet-db-01 |
| CentralUS Spoke Prod | m3i-lz-prod-cus-rt-pe-01 | m3i-cus-default-to-hub-firewall: 0.0.0.0/0 -> VirtualAppliance (hub_firewall_private_ip) | m3i-lz-prod-cus-snet-pe-01 |
| CentralUS Spoke NonProd | m3i-lz-nonprod-cus-rt-vm-01 | m3i-cus-default-to-hub-firewall: 0.0.0.0/0 -> VirtualAppliance (hub_firewall_private_ip) | m3i-lz-nonprod-cus-snet-vm-01 |
| CentralUS Spoke NonProd | m3i-lz-nonprod-cus-rt-db-01 | m3i-cus-default-to-hub-firewall: 0.0.0.0/0 -> VirtualAppliance (hub_firewall_private_ip) | m3i-lz-nonprod-cus-snet-db-01 |
| CentralUS Spoke NonProd | m3i-lz-nonprod-cus-rt-pe-01 | m3i-cus-default-to-hub-firewall: 0.0.0.0/0 -> VirtualAppliance (hub_firewall_private_ip) | m3i-lz-nonprod-cus-snet-pe-01 |
| EastUS2 Spoke Prod | m3i-lz-prod-eus2-rt-vm-01 | m3i-eus2-default-to-hub-firewall: 0.0.0.0/0 -> VirtualAppliance (hub_firewall_private_ip) | m3i-lz-prod-eus2-snet-vm-01 |
| EastUS2 Spoke Prod | m3i-lz-prod-eus2-rt-db-01 | m3i-eus2-default-to-hub-firewall: 0.0.0.0/0 -> VirtualAppliance (hub_firewall_private_ip) | m3i-lz-prod-eus2-snet-db-01 |
| EastUS2 Spoke Prod | m3i-lz-prod-eus2-rt-pe-01 | m3i-eus2-default-to-hub-firewall: 0.0.0.0/0 -> VirtualAppliance (hub_firewall_private_ip) | m3i-lz-prod-eus2-snet-pe-01 |
| EastUS2 Spoke NonProd | m3i-lz-nonprod-eus2-rt-vm-01 | m3i-eus2-default-to-hub-firewall: 0.0.0.0/0 -> VirtualAppliance (hub_firewall_private_ip) | m3i-lz-nonprod-eus2-snet-vm-01 |
| EastUS2 Spoke NonProd | m3i-lz-nonprod-eus2-rt-db-01 | m3i-eus2-default-to-hub-firewall: 0.0.0.0/0 -> VirtualAppliance (hub_firewall_private_ip) | m3i-lz-nonprod-eus2-snet-db-01 |
| EastUS2 Spoke NonProd | m3i-lz-nonprod-eus2-rt-pe-01 | m3i-eus2-default-to-hub-firewall: 0.0.0.0/0 -> VirtualAppliance (hub_firewall_private_ip) | m3i-lz-nonprod-eus2-snet-pe-01 |

## Typical Commands

```powershell
# Example: CentralUS platform
Set-Location regions/centralus/platform
terraform init
terraform validate
terraform plan -var-file="../../../example.tfvars"
terraform apply -var-file="../../../example.tfvars"
```

## Git and State Safety

- Do not commit `.tfstate`, `.terraform`, or secret files.
- Keep one state file per root module/subscription.
- Use PR reviews before production apply.

## References

- Terraform AzureRM Provider: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
- Azure Firewall: https://learn.microsoft.com/azure/firewall/
- VNet Peering: https://learn.microsoft.com/azure/virtual-network/virtual-network-peering-overview
