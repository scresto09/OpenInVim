<#
  OpenInVim - Windows 11 File Explorer context menu for Vim
  Copyright (C) 2026 Sylvain Cresto
  SPDX-License-Identifier: GPL-3.0-or-later

.SYNOPSIS
  Bundle the OpenInVim MSIX packages of all architectures for the Store.

.DESCRIPTION
  Packs every .msix of -InDir (one per architecture, same version, made by
  make_package.ps1 without signing and with the Store publisher) into
  <OutDir>\OpenInVim_<version>.msixbundle, to upload to Partner Center.
  The Store signs the bundle itself.

.EXAMPLE
  .\make_bundle.ps1 -Version 0.1.0.0 -InDir out\store
#>
param(
  [Parameter(Mandatory = $true)] [string] $Version,
  [Parameter(Mandatory = $true)] [string] $InDir,
  [string] $OutDir = "out"
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

# Find a Windows SDK tool, from PATH (Developer Command Prompt) or the SDK.
function Find-SdkTool([string] $name) {
  $cmd = Get-Command $name -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  $hostArch = if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { "arm64" } else { "x64" }
  $found = Get-ChildItem "${env:ProgramFiles(x86)}\Windows Kits\10\bin\*\$hostArch\$name" `
             -ErrorAction SilentlyContinue | Sort-Object FullName | Select-Object -Last 1
  if (-not $found) { throw "$name not found" }
  return $found.FullName
}

if (-not (Get-ChildItem "$InDir\*.msix")) { throw "No .msix in $InDir" }

New-Item -ItemType Directory -Force $OutDir | Out-Null
$bundle = Join-Path (Resolve-Path $OutDir) "OpenInVim_$Version.msixbundle"
& (Find-SdkTool makeappx.exe) bundle /o /d $InDir /bv $Version /p $bundle
if ($LASTEXITCODE -ne 0) { throw "makeappx bundle failed" }

Write-Host "Created $bundle"
