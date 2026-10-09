<#
  OpenInVim - Windows 11 File Explorer context menu for Vim
  Copyright (C) 2026 Sylvain Cresto
  SPDX-License-Identifier: GPL-3.0-or-later

.SYNOPSIS
  Create the OpenInVim MSIX package from the build directory.

.DESCRIPTION
  Fills package\AppxManifest.xml.in, packs build\OpenInVim.dll, build\OpenInVim.exe
  and package\Assets with makeappx.exe, and signs the package.

  The package must be signed by a certificate whose subject is exactly
  -Publisher, trusted by the machine where it is installed:
  - with -PfxPath (and -PfxPassword), the package is signed with that
    certificate, and -Publisher must be its subject;
  - with -TestCert, a self-signed certificate is created for -Publisher and
    its public part (OpenInVim-test_<arch>.cer) is written next to the package;
  - otherwise the package is left unsigned (e.g. for the Microsoft Store,
    which signs it, or for a signing service).

.EXAMPLE
  .\make_package.ps1 -Version 0.1.0.0 -Arch x64 -TestCert
#>
param(
  [Parameter(Mandatory = $true)] [string] $Version,
  [ValidateSet("x64", "arm64")] [string] $Arch = "x64",
  [string] $Publisher = "CN=OpenInVim Test",
  [string] $OutDir = "out",
  [string] $PfxPath,
  [string] $PfxPassword,
  [switch] $TestCert
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

function Invoke-SignTool([string] $msix, [string] $pfx, [string] $password) {
  & (Find-SdkTool signtool.exe) sign /fd SHA256 /f $pfx /p $password $msix
  if ($LASTEXITCODE -ne 0) { throw "signtool failed" }
}

foreach ($f in "build\OpenInVim.dll", "build\OpenInVim.exe") {
  if (-not (Test-Path $f)) { throw "$f not found, run nmake -f Make_mvc.mak first" }
}

# Stage the package content.
$staging = Join-Path $PSScriptRoot "build\package-$Arch"
if (Test-Path $staging) { Remove-Item -Recurse -Force $staging }
New-Item -ItemType Directory -Force "$staging\Assets" | Out-Null
Copy-Item package\Assets\*.png "$staging\Assets"
Copy-Item build\OpenInVim.dll, build\OpenInVim.exe, COPYING $staging

$manifest = Get-Content -Raw -Encoding UTF8 package\AppxManifest.xml.in
$manifest = $manifest.Replace("@VERSION@", $Version)
$manifest = $manifest.Replace("@ARCH@", $Arch)
$manifest = $manifest.Replace("@PUBLISHER@", [Security.SecurityElement]::Escape($Publisher))
Set-Content -Encoding UTF8 -Path "$staging\AppxManifest.xml" -Value $manifest

New-Item -ItemType Directory -Force $OutDir | Out-Null
$msix = Join-Path (Resolve-Path $OutDir) "OpenInVim_${Version}_$Arch.msix"
& (Find-SdkTool makeappx.exe) pack /o /d $staging /p $msix
if ($LASTEXITCODE -ne 0) { throw "makeappx failed" }

if ($PfxPath) {
  Invoke-SignTool $msix $PfxPath $PfxPassword
} elseif ($TestCert) {
  $cert = New-SelfSignedCertificate -Type Custom -Subject $Publisher `
    -KeyUsage DigitalSignature -FriendlyName "OpenInVim Test" `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.3", "2.5.29.19={text}")
  $password = "openinvim-test"
  $pfx = Join-Path $env:TEMP "OpenInVim-test.pfx"
  Export-PfxCertificate -Cert $cert -FilePath $pfx `
    -Password (ConvertTo-SecureString -String $password -Force -AsPlainText) | Out-Null
  Export-Certificate -Cert $cert -FilePath (Join-Path $OutDir "OpenInVim-test_$Arch.cer") | Out-Null
  try {
    Invoke-SignTool $msix $pfx $password
  } finally {
    Remove-Item $pfx
    Remove-Item "Cert:\CurrentUser\My\$($cert.Thumbprint)"
  }
} else {
  Write-Warning "The package is not signed."
}

Write-Host "Created $msix"
