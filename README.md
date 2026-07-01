# M3I Azure Infrastructure - Terraform IaC

This repository contains Terraform code for a multi-region Azure hub-and-spoke landing zone across CentralUS and EastUS2, with separate subscriptions for platform, production spoke, and non-production spoke per region.

## Prerequisites

- Terraform CLI installed (version compatible with `~> 4.x` AzureRM provider workflow in this repo)
- Azure access to platform + spoke subscriptions
- Backend storage accounts/containers already created for each root state
- `m3i-platform.tfvars` copied and updated with your subscription IDs and environment values

Optional but recommended:
- PowerShell 7+ for running `scripts/deploy-two-pass.ps1`

## Current Topology

- Regions: `centralus`, `eastus2`
- Subscription model per region:
  - `platform` (hub)
  - `spoke-prod`
  - `spoke-nonprod`
- Architecture pattern: hub-and-spoke with preserved UDR next-hop framework in each regional hub (Azure Firewall resources decommissioned)
- Cross-subscription peering:
  - Spoke to hub (all spokes)
  - Hub to spoke (from hub side)
  - Hub to hub (cross-region)

## Address Space Plan

### Hubs
- CentralUS hub: `10.100.0.0/22`
- EastUS2 hub: `10.101.0.0/22`

### Bastion VNets
- CentralUS bastion: `10.99.0.0/26` (`m3i-hub-bastion-cus-vnet-01`)
- EastUS2 bastion: `10.99.0.64/26` (`m3i-hub-bastion-eus2-vnet-01`)

Note:
- EastUS2 was implemented with `10.99.0.64/26` because `/26` network boundaries must align on increments of 64.

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
- AzureFirewallSubnet and associated route table framework retained for future virtual appliance/NVA cutover
- Azure Firewall, firewall policy/rule collection groups, and NAT Gateway resources decommissioned from both hubs (2026-07-01)
- Azure Bastion host per region in dedicated Bastion VNet/subnet (`AzureBastionSubnet`)
- Bastion VNet peering model per region:
  - Bastion <-> Hub
  - Bastion <-> Spoke Prod
  - Bastion <-> Spoke NonProd
- Log Analytics workspace retained
- Recovery Services Vault (GRS, cross-region restore enabled) and VM backup policy
- Backup protection for all hub DC VMs in both regions (4 total with current defaults)
- Key Vault per hub
  - Azure RBAC authorization enabled (`rbac_authorization_enabled = true`)
  - Terraform access policy resources replaced by RBAC role assignments (`Key Vault Secrets Officer`) for deployment identity
- Hub-to-spoke and hub-to-hub peering resources
- Active Directory VM foundations in each hub:
  - CentralUS: `AZ-CUS-DC01`, `AZ-CUS-DC02`
  - EastUS2: `AZ-EUS2-DC01`, `AZ-EUS2-DC02`
  - Size default: `Standard_D2s_v5` (2-core D-series)
  - OS default: Windows Server 2022 Datacenter
  - Admin password stored in hub Key Vault secret `dc-admin-password`
  - Base monitoring enabled via Azure Monitor Agent + Data Collection Rule to regional Log Analytics workspace
    - Windows Event logs: Application, System
    - Performance counters: CPU, memory, disk free space/latency, network throughput (60s)

### Spoke Deployments
- Spoke VNet and subnets (`private-endpoints`, `vm`, `db`)
- NSGs and subnet associations
- Route tables and associations for VM/DB/Private Endpoints subnets
- Default route `0.0.0.0/0` to the configured hub virtual-appliance next hop (auto-resolved from hub remote state output `hub_firewall_private_ip`; optional override with `hub_firewall_private_ip`)
- Spoke-to-hub peering
  - `use_remote_gateways = false` (hub VPN gateway is not deployed in current baseline)
- Key Vault per spoke (optional via flag)
  - Azure RBAC authorization enabled (`rbac_authorization_enabled = true`)
  - Terraform access policy resources replaced by RBAC role assignments (`Key Vault Secrets Officer`) for deployment identity

## Latest Operations Notes

- Current state converged across all six roots (`centralus/eastus2` platform + prod/nonprod spokes): no-change plans after final remediation.
- Domain Controller image baseline updated from Windows Server 2025 Datacenter to Windows Server 2022 Datacenter in both platform roots.
- DC rebuild outcome (2026-07-01): both CentralUS and EastUS2 hub DC pairs were torn down and recreated successfully on the 2022 image, followed by no-change validation plans on both platform subscriptions.
- Hub firewall stack decommission outcome (2026-07-01): Azure Firewall, Firewall Policy, rule collection groups, diagnostics, firewall public IP, and NAT Gateway stack were removed in both platform roots.
- Post-decommission validation (2026-07-01): both `centralus/platform` and `eastus2/platform` plans return `No changes`.
- Spoke roots intentionally unchanged: spoke UDRs still reference legacy hub next-hop IPs (`10.100.0.132` / `10.101.0.132`) via remote-state output fallback to preserve routing structure for staged NVA cutover.
- Historical note: prior two-pass orchestration could fail with `RemotePeeringIsDisconnected` if spoke-side remote peerings became stale after peering toggles.
- Proven recovery pattern used in this repo:
  1. Recreate spoke-side `spoke_to_hub` peering in affected spoke root(s) with `-replace`.
  2. Re-run platform apply for affected region with `enable_hub_to_spoke_peering=true` (and `enable_hub_to_hub_peering=true` where required).
  3. Re-validate all six roots with `terraform plan` expecting no changes.
- Deferred change decision (2026-07-01):
  - Forced tunneling on Azure Firewall and SNAT disable are approved as the target design, but implementation is intentionally paused.
  - Current checkpoint keeps that work in planning state so it can be applied in a controlled change window.

## Repository Layout

```text
M3I-Terraform/
|- m3i-platform.tfvars
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
2. `regions/eastus2/platform`
3. `regions/centralus/spoke-prod`
4. `regions/centralus/spoke-nonprod`
5. `regions/eastus2/spoke-prod`
6. `regions/eastus2/spoke-nonprod`

Notes:
- Spokes use `hub_firewall_private_ip` from per-root tfvars; remote-state hub firewall output remains as fallback.
- Platform peering is implemented with deterministic VNet IDs (subscription + resource group + VNet name), avoiding live cross-subscription data lookups during `plan`.

### Automated Deployment

You can run a full single-pass orchestration from repository root:

```powershell
# Plan across all roots in required order
./scripts/deploy-two-pass.ps1 -Mode plan -VarFile m3i-platform.tfvars

# Apply across all roots in required order
./scripts/deploy-two-pass.ps1 -Mode apply -VarFile m3i-platform.tfvars -AutoApprove

# Run only roots that belong to a specific backend subscription
./scripts/deploy-two-pass.ps1 -Mode plan -TargetSubscriptionIds 4d58273c-5176-4f3b-97d5-8d19d8ff74e8

# Run multiple subscriptions in one command
./scripts/deploy-two-pass.ps1 -Mode apply -AutoApprove -TargetSubscriptionIds `
  4d58273c-5176-4f3b-97d5-8d19d8ff74e8,31a0c2bb-b673-4ea4-81c2-335d87ca60f8
```

What the script does:
- Runs selected roots one time each in deterministic order (platform roots first, then spoke roots)
- Supports optional filtering by backend subscription via `-TargetSubscriptionIds`

Script location: `scripts/deploy-two-pass.ps1`

Note:
- The script name is retained for backward compatibility, but behavior is now single-pass.

Behavior details:
- In `plan` and `apply` modes, the script runs backend preflight checks first (Azure subscription context, `Microsoft.Storage` availability, backend RG, storage account, and `tfstate` container).
- Before each root run, the script explicitly selects that root's backend subscription (`az account set`) prior to `terraform init`.
- The script runs `terraform init` and `terraform validate` in every root before `plan` or `apply`.
- Use `-Mode validate-only` for quick dry checks without backend/state access (`terraform init -backend=false` + `terraform validate` across selected roots).
- Use `-Mode plan` for dry run across selected roots.
- Use `-Mode apply -AutoApprove` for non-interactive apply.
- Errors are grouped by operation/root in output (for example: `[FAILURE] [Deployment: selected roots (single pass)][regions/eastus2/spoke-prod] ...`).
- If one root fails, execution stops so you can fix before continuing.

## Core Variables to Review

In each deployment directory, verify:
- Subscription IDs (`platform_subscription_id`, `spoke_subscription_id` where applicable)
- Address spaces and subnet CIDRs
- Feature flags:
  - `enable_bastion`
  - `enable_log_analytics`
  - `enable_backup`
  - `enable_key_vault`
  - `enable_dc_vms` (hub)
  - `enable_hub_to_spoke_peering`
  - `enable_hub_to_hub_peering`
- DC settings (hub):
  - `dc_vm_count` (default `2`)
  - `dc_vm_size` (default `Standard_D2s_v5`)
  - `dc_os_image_*`
  - `admin_password` (blank = generated and stored in Key Vault)
- Inter-region firewall routing (hub):
  - `other_region_firewall_private_ip` (optional override; default behavior auto-resolves from other hub remote state)
- Cross-region hub peering (hub):
  - `other_region_hub_vnet_name`
  - `other_region_hub_resource_group`
  - `other_region_hub_subscription_id`

## Validation Workflow

Per root, run in this order:
1. `terraform init`
2. `terraform validate`
3. `terraform plan -var-file=...`
4. `terraform apply -var-file=...`

For full-stack orchestration, prefer `scripts/deploy-two-pass.ps1`.

## State Storage Accounts

| Root Module | Resource Group | Storage Account | State Key | Subscription ID |
|---|---|---|---|---|
| CentralUS Platform | m3i-hub-prod-rg-tf-cus | m3ihubprodstortfcus | m3i-platform-cus.tfstate | 4d58273c-5176-4f3b-97d5-8d19d8ff74e8 |
| CentralUS Spoke Prod | m3i-spoke-prod-rg-tf-cus | m3ispokeprodstortfcus | m3i-spoke-prod-cus.tfstate | 31a0c2bb-b673-4ea4-81c2-335d87ca60f8 |
| CentralUS Spoke NonProd | m3i-spoke-nonprod-rg-tf-cus | m3ispokenonprodstortfcus | m3i-spoke-nonprod-cus.tfstate | 9bdd25f9-1dbe-4784-b629-50d4febb1000 |
| EastUS2 Platform | m3i-hub-prod-rg-tf-eus2 | m3ihubprodstortfeus2 | m3i-platform-eus2.tfstate | 5f6a8c70-73ff-4df7-88f2-5484fbb14aff |
| EastUS2 Spoke Prod | m3i-spoke-prod-rg-tf-eus2 | m3ispokeprodstortfeus2 | m3i-spoke-prod-eus2.tfstate | 6ab13db0-ee2a-4a60-8a42-f79fd75fe06c |
| EastUS2 Spoke NonProd | m3i-spoke-nonprod-rg-tf-eus2 | m3ispokenonprodstortfe2 | m3i-spoke-nonprod-eus2.tfstate | e0f7a316-07ce-4882-b779-61329fa5c350 |

Note:
- EastUS2 NonProd uses `m3ispokenonprodstortfe2` to remain within Azure Storage account name length limits.

## Tagging Strategy

Current tagging model:

- Only Resource Groups are tagged via `local.rg_tags`.
- Non-RG resources are intentionally untagged in Terraform.

Resource Group tag schema:

- `Application` = `TBD`
- `Environment` = `PROD` or `NONPROD` (by root/subscription role)
- `Region` = `CUS` or `EUS2` (by region)
- `Owner` = `TBD`
- `CostCenter` = `TBD`
- `ManagedBy` = `TBD`
- `DataClassification` = `TBD`

### Resource Group Tag Values By Root Module

| Root Module | Environment | Region |
|---|---|
| centralus/platform | PROD | CUS |
| eastus2/platform | PROD | EUS2 |
| centralus/spoke-prod | PROD | CUS |
| centralus/spoke-nonprod | NONPROD | CUS |
| eastus2/spoke-prod | PROD | EUS2 |
| eastus2/spoke-nonprod | NONPROD | EUS2 |

### Notes

- Existing legacy tags on VM OS disks were removed directly in Azure after apply.
- Validation query confirms zero tagged VM OS disks in the managed VM resource groups.

## Route Table Matrix

| Scope | Route Table Name | Routes In Table | Applied To Subnet |
|---|---|---|---|
| CentralUS Hub | m3i-hub-prod-cus-rt-snet-shared-services-01 | m3i-cus-shared-to-hub-firewall: 0.0.0.0/0 -> VirtualAppliance (hub firewall private IP); m3i-cus-shared-to-eus2-via-hub-firewall: 10.101.0.0/16 -> VirtualAppliance (hub firewall private IP) | m3i-hub-prod-cus-snet-shared-services-01 |
| CentralUS Hub | m3i-hub-prod-cus-rt-snet-pe-01 | m3i-cus-pe-to-hub-firewall: 0.0.0.0/0 -> VirtualAppliance (hub firewall private IP); m3i-cus-pe-to-eus2-via-hub-firewall: 10.101.0.0/16 -> VirtualAppliance (hub firewall private IP) | m3i-hub-prod-cus-snet-pe-01 |
| CentralUS Hub | m3i-hub-prod-cus-rt-snet-azfw-01 | Default route handling on AzureFirewallSubnet is constrained by Azure platform rules and not managed as an explicit Terraform route resource; m3i-cus-to-eus2-firewall: 10.101.0.0/16 -> VirtualAppliance (other_region_firewall_private_ip, conditional) | AzureFirewallSubnet |
| EastUS2 Hub | m3i-hub-prod-eus2-rt-snet-shared-services-01 | m3i-eus2-shared-to-hub-firewall: 0.0.0.0/0 -> VirtualAppliance (hub firewall private IP); m3i-eus2-shared-to-cus-via-hub-firewall: 10.100.0.0/16 -> VirtualAppliance (hub firewall private IP) | m3i-hub-prod-eus2-snet-shared-services-01 |
| EastUS2 Hub | m3i-hub-prod-eus2-rt-snet-pe-01 | m3i-eus2-pe-to-hub-firewall: 0.0.0.0/0 -> VirtualAppliance (hub firewall private IP); m3i-eus2-pe-to-cus-via-hub-firewall: 10.100.0.0/16 -> VirtualAppliance (hub firewall private IP) | m3i-hub-prod-eus2-snet-pe-01 |
| EastUS2 Hub | m3i-hub-prod-eus2-rt-snet-azfw-01 | Default route handling on AzureFirewallSubnet is constrained by Azure platform rules and not managed as an explicit Terraform route resource; m3i-eus2-to-cus-firewall: 10.100.0.0/16 -> VirtualAppliance (other_region_firewall_private_ip, conditional) | AzureFirewallSubnet |
| CentralUS Spoke Prod | m3i-lz-prod-cus-rt-vm-01 | m3i-cus-default-to-hub-firewall: 0.0.0.0/0 -> VirtualAppliance (hub_firewall_private_ip); m3i-cus-to-eus2-via-hub-firewall: 10.101.0.0/16 -> VirtualAppliance (hub_firewall_private_ip) | m3i-lz-prod-cus-snet-vm-01 |
| CentralUS Spoke Prod | m3i-lz-prod-cus-rt-db-01 | m3i-cus-default-to-hub-firewall: 0.0.0.0/0 -> VirtualAppliance (hub_firewall_private_ip); m3i-cus-to-eus2-via-hub-firewall: 10.101.0.0/16 -> VirtualAppliance (hub_firewall_private_ip) | m3i-lz-prod-cus-snet-db-01 |
| CentralUS Spoke Prod | m3i-lz-prod-cus-rt-pe-01 | m3i-cus-default-to-hub-firewall: 0.0.0.0/0 -> VirtualAppliance (hub_firewall_private_ip); m3i-cus-to-eus2-via-hub-firewall: 10.101.0.0/16 -> VirtualAppliance (hub_firewall_private_ip) | m3i-lz-prod-cus-snet-pe-01 |
| CentralUS Spoke NonProd | m3i-lz-nonprod-cus-rt-vm-01 | m3i-cus-default-to-hub-firewall: 0.0.0.0/0 -> VirtualAppliance (hub_firewall_private_ip); m3i-cus-to-eus2-via-hub-firewall: 10.101.0.0/16 -> VirtualAppliance (hub_firewall_private_ip) | m3i-lz-nonprod-cus-snet-vm-01 |
| CentralUS Spoke NonProd | m3i-lz-nonprod-cus-rt-db-01 | m3i-cus-default-to-hub-firewall: 0.0.0.0/0 -> VirtualAppliance (hub_firewall_private_ip); m3i-cus-to-eus2-via-hub-firewall: 10.101.0.0/16 -> VirtualAppliance (hub_firewall_private_ip) | m3i-lz-nonprod-cus-snet-db-01 |
| CentralUS Spoke NonProd | m3i-lz-nonprod-cus-rt-pe-01 | m3i-cus-default-to-hub-firewall: 0.0.0.0/0 -> VirtualAppliance (hub_firewall_private_ip); m3i-cus-to-eus2-via-hub-firewall: 10.101.0.0/16 -> VirtualAppliance (hub_firewall_private_ip) | m3i-lz-nonprod-cus-snet-pe-01 |
| EastUS2 Spoke Prod | m3i-lz-prod-eus2-rt-vm-01 | m3i-eus2-default-to-hub-firewall: 0.0.0.0/0 -> VirtualAppliance (hub_firewall_private_ip); m3i-eus2-to-cus-via-hub-firewall: 10.100.0.0/16 -> VirtualAppliance (hub_firewall_private_ip) | m3i-lz-prod-eus2-snet-vm-01 |
| EastUS2 Spoke Prod | m3i-lz-prod-eus2-rt-db-01 | m3i-eus2-default-to-hub-firewall: 0.0.0.0/0 -> VirtualAppliance (hub_firewall_private_ip); m3i-eus2-to-cus-via-hub-firewall: 10.100.0.0/16 -> VirtualAppliance (hub_firewall_private_ip) | m3i-lz-prod-eus2-snet-db-01 |
| EastUS2 Spoke Prod | m3i-lz-prod-eus2-rt-pe-01 | m3i-eus2-default-to-hub-firewall: 0.0.0.0/0 -> VirtualAppliance (hub_firewall_private_ip); m3i-eus2-to-cus-via-hub-firewall: 10.100.0.0/16 -> VirtualAppliance (hub_firewall_private_ip) | m3i-lz-prod-eus2-snet-pe-01 |
| EastUS2 Spoke NonProd | m3i-lz-nonprod-eus2-rt-vm-01 | m3i-eus2-default-to-hub-firewall: 0.0.0.0/0 -> VirtualAppliance (hub_firewall_private_ip); m3i-eus2-to-cus-via-hub-firewall: 10.100.0.0/16 -> VirtualAppliance (hub_firewall_private_ip) | m3i-lz-nonprod-eus2-snet-vm-01 |
| EastUS2 Spoke NonProd | m3i-lz-nonprod-eus2-rt-db-01 | m3i-eus2-default-to-hub-firewall: 0.0.0.0/0 -> VirtualAppliance (hub_firewall_private_ip); m3i-eus2-to-cus-via-hub-firewall: 10.100.0.0/16 -> VirtualAppliance (hub_firewall_private_ip) | m3i-lz-nonprod-eus2-snet-db-01 |
| EastUS2 Spoke NonProd | m3i-lz-nonprod-eus2-rt-pe-01 | m3i-eus2-default-to-hub-firewall: 0.0.0.0/0 -> VirtualAppliance (hub_firewall_private_ip); m3i-eus2-to-cus-via-hub-firewall: 10.100.0.0/16 -> VirtualAppliance (hub_firewall_private_ip) | m3i-lz-nonprod-eus2-snet-pe-01 |

## NSG Inventory and Associations

Current model:
- Total NSGs: `22`
- Total NSG subnet associations: `22`
- All defined NSGs are intentionally wide open right now:
  - Inbound: `allow-all-inbound` (priority `100`, protocol `*`, source/destination `*`, ports `*`)
  - Outbound: `allow-all-outbound` (priority `110`, protocol `*`, source/destination `*`, ports `*`)

### CentralUS Hub

| NSG Name | Associated Subnet |
|---|---|
| m3i-hub-prod-cus-nsg-snet-shared-services-01 | m3i-hub-prod-cus-snet-shared-services-01 |
| m3i-hub-prod-cus-nsg-snet-cato-lan-01 | m3i-hub-prod-cus-snet-cato-lan-01 |
| m3i-hub-prod-cus-nsg-snet-cato-wan-01 | m3i-hub-prod-cus-snet-cato-wan-01 |
| m3i-hub-prod-cus-nsg-snet-cato-mgmt-01 | m3i-hub-prod-cus-snet-cato-mgmt-01 |
| m3i-hub-prod-cus-nsg-snet-pe-01 | m3i-hub-prod-cus-snet-pe-01 |

### EastUS2 Hub

| NSG Name | Associated Subnet |
|---|---|
| m3i-hub-prod-eus2-nsg-snet-shared-services-01 | m3i-hub-prod-eus2-snet-shared-services-01 |
| m3i-hub-prod-eus2-nsg-snet-cato-lan-01 | m3i-hub-prod-eus2-snet-cato-lan-01 |
| m3i-hub-prod-eus2-nsg-snet-cato-wan-01 | m3i-hub-prod-eus2-snet-cato-wan-01 |
| m3i-hub-prod-eus2-nsg-snet-cato-mgmt-01 | m3i-hub-prod-eus2-snet-cato-mgmt-01 |
| m3i-hub-prod-eus2-nsg-snet-pe-01 | m3i-hub-prod-eus2-snet-pe-01 |

### CentralUS Spoke Prod

| NSG Name | Associated Subnet |
|---|---|
| m3i-lz-prod-cus-nsg-vm-01 | m3i-lz-prod-cus-snet-vm-01 |
| m3i-lz-prod-cus-nsg-db-01 | m3i-lz-prod-cus-snet-db-01 |
| m3i-lz-prod-cus-nsg-pe-01 | m3i-lz-prod-cus-snet-pe-01 |

### CentralUS Spoke NonProd

| NSG Name | Associated Subnet |
|---|---|
| m3i-lz-nonprod-cus-nsg-vm-01 | m3i-lz-nonprod-cus-snet-vm-01 |
| m3i-lz-nonprod-cus-nsg-db-01 | m3i-lz-nonprod-cus-snet-db-01 |
| m3i-lz-nonprod-cus-nsg-pe-01 | m3i-lz-nonprod-cus-snet-pe-01 |

### EastUS2 Spoke Prod

| NSG Name | Associated Subnet |
|---|---|
| m3i-lz-prod-eus2-nsg-vm-01 | m3i-lz-prod-eus2-snet-vm-01 |
| m3i-lz-prod-eus2-nsg-db-01 | m3i-lz-prod-eus2-snet-db-01 |
| m3i-lz-prod-eus2-nsg-pe-01 | m3i-lz-prod-eus2-snet-pe-01 |

### EastUS2 Spoke NonProd

| NSG Name | Associated Subnet |
|---|---|
| m3i-lz-nonprod-eus2-nsg-vm-01 | m3i-lz-nonprod-eus2-snet-vm-01 |
| m3i-lz-nonprod-eus2-nsg-db-01 | m3i-lz-nonprod-eus2-snet-db-01 |
| m3i-lz-nonprod-eus2-nsg-pe-01 | m3i-lz-nonprod-eus2-snet-pe-01 |

By design, there are no NSGs associated to:
- `AzureBastionSubnet`
- `GatewaySubnet`
- `AzureFirewallSubnet`

## Firewall and NAT Status (Current)

Current state after 2026-07-01 decommission:

- Azure Firewall resources are removed from both platform roots.
- Azure Firewall Policy and rule collection groups are removed from both platform roots.
- NAT Gateway resources on AzureFirewallSubnet are removed from both platform roots.
- Hub and spoke route tables are intentionally retained.
- Platform outputs still publish `hub_firewall_private_ip` as static legacy next-hop values:
  - CentralUS: `10.100.0.132`
  - EastUS2: `10.101.0.132`

### Effective Behavior and Caveat

- Terraform state is converged for the current design.
- UDRs that still reference the legacy next-hop IPs will point to a non-existent appliance until a replacement NVA/CATO target is deployed and route next hops are repointed.
- This was an intentional staged approach to preserve routing structure while decommissioning the managed firewall stack.

## Typical Commands

```powershell
# Example: CentralUS platform
Set-Location regions/centralus/platform
terraform init
terraform validate
terraform plan -var-file="../../../m3i-platform.tfvars"
terraform apply -var-file="../../../m3i-platform.tfvars"
```

## Git and State Safety

- Do not commit `.tfstate`, `.terraform`, or secret files.
- Keep one state file per root module/subscription.
- Use PR reviews before production apply.
- Keep backend values (`backend.tf`) aligned with the subscription/state account for each root.
- Prefer small, region-scoped changes and validate both regional platform roots when shared patterns are modified.

## References

- Terraform AzureRM Provider: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
- Azure Firewall: https://learn.microsoft.com/azure/firewall/
- VNet Peering: https://learn.microsoft.com/azure/virtual-network/virtual-network-peering-overview
