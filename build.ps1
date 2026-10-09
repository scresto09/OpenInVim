<#
  OpenInVim - Windows 11 File Explorer context menu for Vim
  Copyright (C) 2026 Sylvain Cresto
  SPDX-License-Identifier: GPL-3.0-or-later

.SYNOPSIS
  Build OpenInVim and create its MSIX package, in one step.

.DESCRIPTION
  1. Finds Visual Studio (vswhere) and sets up its build environment for the
     target architecture: no Developer Command Prompt needed.
  2. Builds OpenInVim.dll and OpenInVim.exe (nmake -f Make_mvc.mak).
  3. Creates out\OpenInVim_<version>_<arch>.msix, signed with a new test
     certificate (out\OpenInVim-test_<arch>.cer), see make_package.ps1.
  4. With -Install: trusts the test certificate (asks for administrator
     rights) and installs the package for the current user.

  Without -Version, the version is the one in the VERSION file plus a local
  build number, increased at each build (kept in out\.buildnumber), so that
  a new build can always be installed over the previous one.

.EXAMPLE
  .\build.ps1                   # build and package for this computer
  .\build.ps1 -Install          # ... and install it
  .\build.ps1 -Arch arm64       # package for Windows on ARM
#>
param(
  [ValidateSet("x64", "arm64")] [string] $Arch,
  [string] $Version,
  [switch] $Install
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$hostArch = if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { "arm64" } else { "x64" }
if (-not $Arch) { $Arch = $hostArch }

# Version: VERSION file (X.Y.Z) + local build number.
if (-not $Version) {
  $base = (Get-Content -Raw VERSION).Trim()
  if ($base -notmatch '^\d+\.\d+\.\d+$') { throw "VERSION must be X.Y.Z, not '$base'" }
  New-Item -ItemType Directory -Force out | Out-Null
  $counter = "out\.buildnumber"
  $build = if (Test-Path $counter) { [int](Get-Content $counter) + 1 } else { 1 }
  Set-Content -Path $counter -Value $build
  $Version = "$base.$build"
}
Write-Host "OpenInVim $Version ($Arch)" -ForegroundColor Cyan

# 1. Visual Studio build environment.
if ($env:VSCMD_ARG_TGT_ARCH -eq $Arch -and (Get-Command nmake -ErrorAction SilentlyContinue)) {
  # Already in a Developer Command Prompt for this architecture.
  Write-Host "Using the current Visual Studio environment"
} else {
  $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
  if (-not (Test-Path $vswhere)) {
    throw "Visual Studio not found (no $vswhere).  Install Visual Studio or the Build Tools with `"Desktop development with C++`", or run this script from a Developer Command Prompt."
  }
  # Any Visual Studio or Build Tools, including previews, that has the C++
  # build environment (vcvarsall.bat); the most recent first.
  $installs = & $vswhere -all -prerelease -products * -sort -property installationPath
  $vcvars = $installs |
    ForEach-Object { Join-Path $_ "VC\Auxiliary\Build\vcvarsall.bat" } |
    Where-Object { Test-Path $_ } | Select-Object -First 1
  if (-not $vcvars) {
    Write-Host "Visual Studio installations found:"
    & $vswhere -all -prerelease -products * -format text |
      Select-String '^(displayName|installationPath|installationVersion):'
    throw "No Visual Studio installation with the C++ tools (vcvarsall.bat).  Add the `"Desktop development with C++`" workload, or run this script from a Developer Command Prompt."
  }
  $vcvarsArch = if ($Arch -eq $hostArch) { $hostArch } else { "${hostArch}_$Arch" }
  Write-Host "Using $vcvars $vcvarsArch"
  # Run vcvarsall.bat and import the environment it sets.
  $envLines = cmd /c "`"$vcvars`" $vcvarsArch >nul && set"
  if ($LASTEXITCODE -ne 0) { throw "vcvarsall.bat $vcvarsArch failed" }
  $envLines | ForEach-Object {
    if ($_ -match '^([^=]+)=(.*)$') { Set-Item "env:$($Matches[1])" $Matches[2] }
  }
}

# 2. Build.
Write-Host "Building..." -ForegroundColor Cyan
nmake /nologo -f Make_mvc.mak clean all
if ($LASTEXITCODE -ne 0) { throw "Build failed" }

# 3. Package, signed with a test certificate.
Write-Host "Packaging..." -ForegroundColor Cyan
& .\make_package.ps1 -Version $Version -Arch $Arch -TestCert
$msix = Resolve-Path "out\OpenInVim_${Version}_$Arch.msix"
$cer = Resolve-Path "out\OpenInVim-test_$Arch.cer"

# 4. Install.
if ($Install) {
  Write-Host "Trusting the test certificate (administrator rights)..." -ForegroundColor Cyan
  $import = "Import-Certificate -FilePath '$cer' -CertStoreLocation Cert:\LocalMachine\TrustedPeople | Out-Null"
  $p = Start-Process powershell -Verb RunAs -Wait -PassThru -WindowStyle Hidden `
         -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", $import
  if ($p.ExitCode -ne 0) { throw "Could not trust the test certificate" }

  Write-Host "Installing..." -ForegroundColor Cyan
  # -ForceApplicationShutdown: close the processes of the previous version,
  # e.g. the COM surrogate (dllhost.exe) that Explorer keeps for a while
  # after showing the menu, or an open settings window.
  Add-AppxPackage -Path $msix -ForceUpdateFromAnyVersion -ForceApplicationShutdown
  Write-Host "Installed OpenInVim $Version." -ForegroundColor Green
} else {
  Write-Host "Created $msix" -ForegroundColor Green
  Write-Host "Install it with: .\build.ps1 -Install, or trust $cer and open the .msix."
}
