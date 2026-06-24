param(
  [string]$VarFile = "example.tfvars",
  [ValidateSet("plan", "apply")]
  [string]$Mode = "plan",
  [switch]$AutoApprove
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$varFilePath = if ([System.IO.Path]::IsPathRooted($VarFile)) { $VarFile } else { Join-Path $repoRoot $VarFile }

if (-not (Test-Path $varFilePath)) {
  throw "Var file not found: $varFilePath"
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

function Invoke-Terraform {
  param(
    [string]$RelativeDir,
    [string[]]$ExtraVars = @()
  )

  $dir = Join-Path $repoRoot $RelativeDir
  Write-Host ""
  Write-Host "=== $Mode :: $RelativeDir ===" -ForegroundColor Cyan

  Push-Location $dir
  try {
    terraform init
    terraform validate

    $cmd = @($Mode, "-var-file=$varFilePath")
    foreach ($extraVar in $ExtraVars) {
      $cmd += "-var=$extraVar"
    }

    if ($Mode -eq "apply" -and $AutoApprove) {
      $cmd += "-auto-approve"
    }

    & terraform @cmd
    if ($LASTEXITCODE -ne 0) {
      throw "terraform $Mode failed in $RelativeDir"
    }
  }
  finally {
    Pop-Location
  }
}

Write-Host "Starting two-pass deployment orchestration..." -ForegroundColor Green
Write-Host "Var file: $varFilePath" -ForegroundColor DarkGray
Write-Host "Mode: $Mode" -ForegroundColor DarkGray

Write-Host "" 
Write-Host "Phase 1: Platform (hub-to-spoke peering disabled)" -ForegroundColor Yellow
foreach ($dir in $phase1PlatformDirs) {
  Invoke-Terraform -RelativeDir $dir -ExtraVars @("enable_hub_to_spoke_peering=false")
}

Write-Host ""
Write-Host "Phase 2: Spokes" -ForegroundColor Yellow
foreach ($dir in $spokeDirs) {
  Invoke-Terraform -RelativeDir $dir
}

Write-Host ""
Write-Host "Phase 3: Platform (hub-to-spoke peering enabled)" -ForegroundColor Yellow
foreach ($dir in $phase2PlatformDirs) {
  Invoke-Terraform -RelativeDir $dir -ExtraVars @("enable_hub_to_spoke_peering=true")
}

Write-Host ""
Write-Host "Two-pass deployment orchestration complete." -ForegroundColor Green
