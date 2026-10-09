# OpenInVim

**Open files and folders with Vim from the Windows 11 context menu.**

OpenInVim adds **Edit in Vim** (files) and **Open in Vim** (folders) at the
root of the Windows 11 File Explorer context menu, without going through
"Show more options".  Files are opened in the running gVim if there is one,
each in a new tab page by default.

Requires Vim, installed with the official installer from
<https://www.vim.org/download.php>.
OpenInVim is just a fun project I made for fun and is not affiliated with the Vim project.
For any issues or questions, you can reach me at scresto [at] gmail [dot] com.

## Settings

Run **OpenInVim** from the Start menu to choose the `gvim.exe` to use
(detected automatically by default) and whether to open files in new tab
pages.


## Install

Double-click the `.msix` package.  To install it for all users, in an
administrator PowerShell:

    Add-AppxProvisionedPackage -Online -SkipLicense -PackagePath OpenInVim_<version>_x64.msix

A test build must first have its certificate trusted, in an administrator
PowerShell:

    Import-Certificate -FilePath OpenInVim-test_x64.cer -CertStoreLocation Cert:\LocalMachine\TrustedPeople

Uninstall from Settings > Apps.


## Build

Requires Visual Studio 2022 with "Desktop development with C++".

    build               build and create out\OpenInVim_<version>_<arch>.msix
    build -Install      ... and install it (with a test certificate)
    build -Arch arm64   for Windows on ARM

Translations are in `src/lang/*.rc`.


## License

Copyright (C) 2026 Sylvain Cresto.  GNU General Public License version 3 or
later, see [COPYING](COPYING).
