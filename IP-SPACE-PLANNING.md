# M3I Terraform IaC - IP Space Planning

## Current Status

✅ **Complete:** 
- Terraform infrastructure code scaffolding for all 6 subscriptions (2 regions × 3 subscriptions)
- Hub (platform) subscriptions for each region
- Spoke (prod & nonprod) subscriptions for each region
- All resource definitions: VNets, subnets, NSGs, route tables, Azure Firewall, NAT Gateway, etc.
- Remote state backend configuration (manual storage account creation required)
- Comprehensive README with deployment guide
- **IP Address Spaces: ACTUAL allocation implemented** ✅
- **Growth placeholder subnets removed** ✅

---

## IP Address Spaces - ACTUAL Allocation

### CentralUS Region

| Subscription | VNet Name | IP Space | Subnets |
|---|---|---|---|
| **Platform (Hub)** | `m3i-hub-prod-cus-vnet-01` | `10.100.0.0/22` | 7 subnets |
| **Spoke (Prod)** | `m3i-lz-prod-cus-vnet-01` | `10.100.4.0/22` | 3 subnets |
| **Spoke (Non-Prod)** | `m3i-lz-nonprod-cus-vnet-01` | `10.100.8.0/22` | 3 subnets |

### EastUS2 Region

| Subscription | VNet Name | IP Space | Subnets |
|---|---|---|---|
| **Platform (Hub)** | `m3i-hub-prod-eus2-vnet-01` | `10.101.0.0/22` | 7 subnets |
| **Spoke (Prod)** | `m3i-lz-prod-eus2-vnet-01` | `10.101.4.0/22` | 3 subnets |
| **Spoke (Non-Prod)** | `m3i-lz-nonprod-eus2-vnet-01` | `10.101.8.0/22` | 3 subnets |

---

## Detailed Subnet Breakdown

### Hub (Platform) Subnets - 8 subnets per region

#### CentralUS Hub (10.100.0.0/22)
| Tier | Subnet Name | CIDR | IPs | Purpose |
|---|---|---|---|---|
| 1 | GatewaySubnet | `10.100.0.0/27` | 32 | VPN/ExpressRoute gateway |
| 2 | m3i-hub-prod-cus-snet-cato-lan-01 | `10.100.0.32/27` | 32 | Cato LAN |
| 3 | m3i-hub-prod-cus-snet-cato-wan-01 | `10.100.0.64/27` | 32 | Cato WAN |
| 4 | m3i-hub-prod-cus-snet-cato-mgmt-01 | `10.100.0.96/27` | 32 | Cato Management |
| 5 | AzureFirewallSubnet | `10.100.0.128/26` | 64 | Azure Firewall (required name) |
| 6 | m3i-hub-prod-cus-snet-pe-01 | `10.100.0.192/26` | 64 | Private Endpoints |
| 7 | m3i-hub-prod-cus-snet-shared-services-01 | `10.100.1.0/25` | 128 | Shared Services |

#### EastUS2 Hub (10.101.0.0/22)
| Tier | Subnet Name | CIDR | IPs | Purpose |
|---|---|---|---|---|
| 1 | GatewaySubnet | `10.101.0.0/27` | 32 | VPN/ExpressRoute gateway |
| 2 | m3i-hub-prod-eus2-snet-cato-lan-01 | `10.101.0.32/27` | 32 | Cato LAN |
| 3 | m3i-hub-prod-eus2-snet-cato-wan-01 | `10.101.0.64/27` | 32 | Cato WAN |
| 4 | m3i-hub-prod-eus2-snet-cato-mgmt-01 | `10.101.0.96/27` | 32 | Cato Management |
| 5 | AzureFirewallSubnet | `10.101.0.128/26` | 64 | Azure Firewall (required name) |
| 6 | m3i-hub-prod-eus2-snet-pe-01 | `10.101.0.192/26` | 64 | Private Endpoints |
| 7 | m3i-hub-prod-eus2-snet-shared-services-01 | `10.101.1.0/25` | 128 | Shared Services |

### Spoke (Prod & Non-Prod) Subnets - 4 subnets per spoke

#### CentralUS Spoke-Prod (10.100.4.0/22)
| Tier | Subnet Name | CIDR | IPs | Purpose |
|---|---|---|---|---|
| 1 | m3i-lz-prod-cus-snet-pe-01 | `10.100.4.0/26` | 64 | Private Endpoints |
| 2 | m3i-lz-prod-cus-snet-vm-01 | `10.100.4.128/25` | 128 | Compute/VMs |
| 3 | m3i-lz-prod-cus-snet-db-01 | `10.100.5.0/25` | 128 | Database tier |

#### CentralUS Spoke-NonProd (10.100.8.0/22)
| Tier | Subnet Name | CIDR | IPs | Purpose |
|---|---|---|---|---|
| 1 | m3i-lz-nonprod-cus-snet-pe-01 | `10.100.8.0/26` | 64 | Private Endpoints |
| 2 | m3i-lz-nonprod-cus-snet-vm-01 | `10.100.8.128/25` | 128 | Compute/VMs |
| 3 | m3i-lz-nonprod-cus-snet-db-01 | `10.100.9.0/25` | 128 | Database tier |

#### EastUS2 Spoke-Prod (10.101.4.0/22)
| Tier | Subnet Name | CIDR | IPs | Purpose |
|---|---|---|---|---|
| 1 | m3i-lz-prod-eus2-snet-pe-01 | `10.101.4.0/26` | 64 | Private Endpoints |
| 2 | m3i-lz-prod-eus2-snet-vm-01 | `10.101.4.128/25` | 128 | Compute/VMs |
| 3 | m3i-lz-prod-eus2-snet-db-01 | `10.101.5.0/25` | 128 | Database tier |

#### EastUS2 Spoke-NonProd (10.101.8.0/22)
| Tier | Subnet Name | CIDR | IPs | Purpose |
|---|---|---|---|---|
| 1 | m3i-lz-nonprod-eus2-snet-pe-01 | `10.101.8.0/26` | 64 | Private Endpoints |
| 2 | m3i-lz-nonprod-eus2-snet-vm-01 | `10.101.8.128/25` | 128 | Compute/VMs |
| 3 | m3i-lz-nonprod-eus2-snet-db-01 | `10.101.9.0/25` | 128 | Database tier |

---

## Example: If Using 10.x.x.x/16 Space

If M3I's corporate IP space is allocated as `10.x.0.0/16`, here's a suggested allocation:

### Option A: Per-Region /18 blocks

**CentralUS: 10.0.0.0/18**
- Hub: `10.0.0.0/20` → 10.0.0.0/23, 10.0.2.0/23, 10.0.4.0/23 for subnets
- Spoke-Prod: `10.0.16.0/20`
- Spoke-NonProd: `10.0.32.0/20`

**EastUS2: 10.0.64.0/18**
- Hub: `10.0.64.0/20`
- Spoke-Prod: `10.0.80.0/20`
- Spoke-NonProd: `10.0.96.0/20`

### Option B: Distributed across /16

**CentralUS:**
- Hub: `10.0.0.0/23`
- Spoke-Prod: `10.1.0.0/23`
- Spoke-NonProd: `10.2.0.0/23`

**EastUS2:**
- Hub: `10.3.0.0/23`
- Spoke-Prod: `10.4.0.0/23`
- Spoke-NonProd: `10.5.0.0/23`

---

## How to Update IP Spaces in Terraform

Once you provide the actual IP ranges, update the files:

1. **Regional tfvars files:**
   ```bash
   regions/centralus/platform/terraform.tfvars
   regions/centralus/spoke-prod/terraform.tfvars
   regions/centralus/spoke-nonprod/terraform.tfvars
   regions/eastus2/platform/terraform.tfvars
   regions/eastus2/spoke-prod/terraform.tfvars
   regions/eastus2/spoke-nonprod/terraform.tfvars
   ```

2. **Key variables to update:**
   - `hub_vnet_address_space` or `spoke_vnet_address_space`
   - `subnets.<subnet_name>.address_prefixes`
   - Firewall route table entries (`next_hop_in_ip_address`)

3. **Firewall rules:** Update CIDR ranges in `main.tf` firewall policy rules once all IPs are finalized.

---

## Next Steps

1. **Provide your IP space allocation** (email/message the actual /23 or /24 ranges for each VNet)
2. **I'll update all Terraform files** with the actual IP ranges
3. **Create storage accounts** for remote state (documented in README)
4. **Deploy** following the deployment workflow in README

---

## Notes

- All VNets currently use `/23` CIDR blocks (512 IPs each) — easily adjustable to `/22`, `/21`, etc.
- Firewall rules reference hub firewall private IP `10.0.0.68` (placeholder) — will be adjusted when hub is deployed
- Subnets use placeholder IPs; firewall route tables point to `next_hop_in_ip_address = "10.0.0.68"` — update after firewall deployment
- VNet peering is one-directional from spoke→hub; hub→spoke peering can be added in platform `main.tf` once spokes are known

---

**Ready to proceed?** Please provide the IP address spaces for all 6 VNets, and I'll finalize the Terraform configuration!
