param(
  [string]$VarFile = "",
  [ValidateSet("plan", "apply", "validate-only")]
  [string]$Mode = "plan",
  [switch]$AutoApprove
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$varFilePath = $null
if ($VarFile -ne "") {
  $varFilePath = if ([System.IO.Path]::IsPathRooted($VarFile)) { $VarFile } else { Join-Path $repoRoot $VarFile }
  if (-not (Test-Path $varFilePath)) {
    throw "Var file not found: $varFilePath"
  }
}

$phase1PlatformDirs = @(
  "regions/centralus/platform",
  "regions/eastus2/platform"
)

$spokeDirs = @(
  "regions/centralus/spoke-prod",
  "regions/centralus/spoke-nonprod",
  "regions/eastus2/spoke-prod",
  "regions/eastus2/spoke-nonprod"
)

$phase2PlatformDirs = @(
  "regions/centralus/platform",
  "regions/eastus2/platform"
)

$validateOnlyDirs = @(
  "regions/centralus/platform",
  "regions/centralus/spoke-prod",
  "regions/centralus/spoke-nonprod",
  "regions/eastus2/platform",
  "regions/eastus2/spoke-prod",
  "regions/eastus2/spoke-nonprod"
)

$rootVarFiles = @{
  "regions/centralus/platform"      = "tfvars/centralus-platform.tfvars"
  "regions/centralus/spoke-prod"    = "tfvars/centralus-spoke-prod.tfvars"
  "regions/centralus/spoke-nonprod" = "tfvars/centralus-spoke-nonprod.tfvars"
  "regions/eastus2/platform"        = "tfvars/eastus2-platform.tfvars"
  "regions/eastus2/spoke-prod"      = "tfvars/eastus2-spoke-prod.tfvars"
  "regions/eastus2/spoke-nonprod"   = "tfvars/eastus2-spoke-nonprod.tfvars"
}

function Get-RootVarFilePath {
  param(
    [string]$RelativeDir
  )

  if (-not $rootVarFiles.ContainsKey($RelativeDir)) {
    throw "No per-root tfvars mapping found for '$RelativeDir'"
  }

  $relativeVarFile = $rootVarFiles[$RelativeDir]
  $fullVarFilePath = Join-Path $repoRoot $relativeVarFile

  if (-not (Test-Path $fullVarFilePath)) {
    throw "Missing per-root tfvars file: $fullVarFilePath"
  }

  return $fullVarFilePath
}

function Get-BackendConfig {
  param(
    [string]$RelativeDir
  )

  $dir = Join-Path $repoRoot $RelativeDir
  $backendFile = Join-Path $dir "backend.tf"
  $providerFile = Join-Path $dir "provider.tf"

  $content = $null
  $sourceFile = $null

  if (Test-Path $backendFile) {
    $backendContent = Get-Content -Path $backendFile -Raw
    if ($backendContent -match 'backend\s+"azurerm"\s*\{') {
      $content = $backendContent
      $sourceFile = $backendFile
    }
  }

  if (-not $content -and (Test-Path $providerFile)) {
    $providerContent = Get-Content -Path $providerFile -Raw
    if ($providerContent -match 'backend\s+"azurerm"\s*\{') {
      $content = $providerContent
      $sourceFile = $providerFile
    }
  }

  if (-not $content) {
    throw "Unable to locate azurerm backend block in $backendFile or $providerFile"
  }

  $extract = {
    param([string]$Pattern, [string]$FieldName)
    $match = [regex]::Match($content, $Pattern)
    if (-not $match.Success) {
      throw "Unable to parse '$FieldName' from $sourceFile"
    }
    return $match.Groups[1].Value
  }

  [pscustomobject]@{
    RelativeDir         = $RelativeDir
    SubscriptionId      = & $extract 'subscription_id\s*=\s*"([^"]+)"' 'subscription_id'
    ResourceGroupName   = & $extract 'resource_group_name\s*=\s*"([^"]+)"' 'resource_group_name'
    StorageAccountName  = & $extract 'storage_account_name\s*=\s*"([^"]+)"' 'storage_account_name'
    ContainerName       = & $extract 'container_name\s*=\s*"([^"]+)"' 'container_name'
    StateKey            = & $extract 'key\s*=\s*"([^"]+)"' 'key'
  }
}

function Test-AzureCliReady {
  if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    throw "Azure CLI ('az') is required for backend preflight checks. Install Azure CLI or run -Mode validate-only."
  }

  & az account show --only-show-errors | Out-Null
  if ($LASTEXITCODE -ne 0) {
    throw "Azure CLI is not authenticated. Run 'az login' before running plan/apply modes."
  }
}

function Test-BackendPreflight {
  param(
    [string[]]$RelativeDirs
  )

  Write-Host ""
  Write-Host "Preflight: validating backend resources for all roots" -ForegroundColor Yellow
  Test-AzureCliReady

  foreach ($relativeDir in $RelativeDirs) {
    $cfg = Get-BackendConfig -RelativeDir $relativeDir
    Write-Host "[Preflight] $($cfg.RelativeDir)" -ForegroundColor Cyan

    & az account set --subscription $cfg.SubscriptionId --only-show-errors
    if ($LASTEXITCODE -ne 0) {
      throw "[Preflight][$($cfg.RelativeDir)] Failed to select subscription $($cfg.SubscriptionId)."
    }

    & az group show --name $cfg.ResourceGroupName --only-show-errors | Out-Null
    if ($LASTEXITCODE -ne 0) {
      throw "[Preflight][$($cfg.RelativeDir)] Resource group not found: $($cfg.ResourceGroupName)"
    }

    & az storage account show --name $cfg.StorageAccountName --resource-group $cfg.ResourceGroupName --only-show-errors | Out-Null
    if ($LASTEXITCODE -ne 0) {
      throw "[Preflight][$($cfg.RelativeDir)] Storage account not found: $($cfg.StorageAccountName)"
    }

    & az storage container show --name $cfg.ContainerName --account-name $cfg.StorageAccountName --auth-mode login --only-show-errors | Out-Null
    if ($LASTEXITCODE -ne 0) {
      throw "[Preflight][$($cfg.RelativeDir)] Storage container not found or inaccessible: $($cfg.ContainerName)"
    }
  }
}

function Invoke-Terraform {
  param(
    [string]$RelativeDir,
    [string]$Phase,
    [string]$EffectiveMode,
    [string[]]$ExtraVars = @()
  )

  $dir = Join-Path $repoRoot $RelativeDir
  Write-Host ""
  Write-Host "=== $Phase :: $EffectiveMode :: $RelativeDir ===" -ForegroundColor Cyan

  Push-Location $dir
  try {
    if ($EffectiveMode -eq "validate-only") {
      terraform init -backend=false
      if ($LASTEXITCODE -ne 0) {
        throw "[$Phase][$RelativeDir] terraform init -backend=false failed"
      }

      terraform validate
      if ($LASTEXITCODE -ne 0) {
        throw "[$Phase][$RelativeDir] terraform validate failed"
      }

      return
    }

    $backendCfg = Get-BackendConfig -RelativeDir $RelativeDir
    & az account set --subscription $backendCfg.SubscriptionId --only-show-errors
    if ($LASTEXITCODE -ne 0) {
      throw "[$Phase][$RelativeDir] failed to select subscription $($backendCfg.SubscriptionId) before terraform operations"
    }

    terraform init
    if ($LASTEXITCODE -ne 0) {
      throw "[$Phase][$RelativeDir] terraform init failed"
    }

    terraform validate
    if ($LASTEXITCODE -ne 0) {
      throw "[$Phase][$RelativeDir] terraform validate failed"
    }

    $rootVarFilePath = Get-RootVarFilePath -RelativeDir $RelativeDir

    $cmd = @($EffectiveMode, "-var-file=$rootVarFilePath")
    if ($varFilePath) {
      $cmd += "-var-file=$varFilePath"
    }
    foreach ($extraVar in $ExtraVars) {
      $cmd += "-var=$extraVar"
    }

    if ($EffectiveMode -eq "apply" -and $AutoApprove) {
      $cmd += "-auto-approve"
    }

    & terraform @cmd
    if ($LASTEXITCODE -ne 0) {
      throw "[$Phase][$RelativeDir] terraform $EffectiveMode failed"
    }
  }
  finally {
    Pop-Location
  }
}

function Invoke-Phase {
  param(
    [string]$Phase,
    [string[]]$RelativeDirs,
    [string[]]$ExtraVars = @()
  )

  Write-Host ""
  Write-Host $Phase -ForegroundColor Yellow

  foreach ($dir in $RelativeDirs) {
    try {
      Invoke-Terraform -RelativeDir $dir -Phase $Phase -EffectiveMode $Mode -ExtraVars $ExtraVars
    }
    catch {
      throw "[FAILURE] $($_.Exception.Message)"
    }
  }
}

Write-Host "Starting two-pass deployment orchestration..." -ForegroundColor Green
if ($varFilePath) {
  Write-Host "Optional override var file: $varFilePath" -ForegroundColor DarkGray
}
Write-Host "Per-root var files: tfvars/*.tfvars" -ForegroundColor DarkGray
Write-Host "Mode: $Mode" -ForegroundColor DarkGray

if ($Mode -eq "validate-only") {
  Invoke-Phase -Phase "Validate-Only: all roots (init -backend=false + validate)" -RelativeDirs $validateOnlyDirs

  Write-Host ""
  Write-Host "Validate-only orchestration complete." -ForegroundColor Green
  exit 0
}

$allRoots = @(
  $phase1PlatformDirs +
  $spokeDirs
)

Test-BackendPreflight -RelativeDirs $allRoots

Invoke-Phase -Phase "Phase 1: Platform (hub-to-spoke and hub-to-hub peering disabled)" -RelativeDirs $phase1PlatformDirs -ExtraVars @("enable_hub_to_spoke_peering=false", "enable_hub_to_hub_peering=false")
Invoke-Phase -Phase "Phase 2: Spokes" -RelativeDirs $spokeDirs
Invoke-Phase -Phase "Phase 3: Platform (hub-to-spoke peering enabled)" -RelativeDirs $phase2PlatformDirs -ExtraVars @("enable_hub_to_spoke_peering=true")

Write-Host ""
Write-Host "Two-pass deployment orchestration complete." -ForegroundColor Green
