/*
 * OpenInVim - Windows 11 File Explorer context menu for Vim
 * Copyright (C) 2026 Sylvain Cresto
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Settings shared by OpenInVim.dll (the menu entry) and OpenInVim.exe (the
 * settings window), and the lookup of gvim.exe.
 *
 * The settings are stored in HKEY_CURRENT_USER\Software\OpenInVim.  Both
 * programs run in the MSIX package, so they see the same (virtualized) view
 * of the registry, and Windows deletes the settings with the package.
 */

#ifndef OPENINVIM_GVIMPATH_H
#define OPENINVIM_GVIMPATH_H

#include <windows.h>

#define SETTINGS_KEY            L"Software\\OpenInVim"
#define SETTING_GVIM_PATH       L"GvimPath"     // REG_SZ, empty: automatic
#define SETTING_USE_TABS        L"UseTabs"      // REG_DWORD, default 1

static inline BOOL file_exists(PCWSTR path)
{
    return *path != 0 && GetFileAttributesW(path) != INVALID_FILE_ATTRIBUTES;
}

/*
 * Locate gvim.exe through the registry value written by the Vim installer
 * "path" in Software\Vim\Gvim", per-user installation first.
 * Returns TRUE and fills "buf" when gvim.exe exists.
 */
static inline BOOL get_auto_gvim_path(WCHAR *buf, DWORD len)
{
    static const HKEY   roots[] = {
        HKEY_CURRENT_USER, HKEY_LOCAL_MACHINE
    };

    for (int i = 0; i < 2; i++)
    {
        DWORD   size = len * sizeof(WCHAR);

        if (RegGetValueW(roots[i], L"Software\\Vim\\Gvim", L"path",
                            RRF_RT_REG_SZ, NULL, buf, &size) == ERROR_SUCCESS
                && file_exists(buf))
            return TRUE;
    }
    *buf = 0;
    return FALSE;
}

/*
 * The gvim.exe chosen in the settings window, or an empty string.
 */
static inline void get_custom_gvim_path(WCHAR *buf, DWORD len)
{
    DWORD   size = len * sizeof(WCHAR);

    if (RegGetValueW(HKEY_CURRENT_USER, SETTINGS_KEY, SETTING_GVIM_PATH,
                            RRF_RT_REG_SZ, NULL, buf, &size) != ERROR_SUCCESS)
        *buf = 0;
}

/*
 * Whether to open each file in a new tab page (default: yes).
 */
static inline BOOL get_use_tabs(void)
{
    DWORD   value;
    DWORD   size = sizeof(value);
    LSTATUS err;

    err = RegGetValueW(HKEY_CURRENT_USER, SETTINGS_KEY, SETTING_USE_TABS,
                                    RRF_RT_REG_DWORD, NULL, &value, &size);
    return err != ERROR_SUCCESS || value != 0;
}

#endif // OPENINVIM_GVIMPATH_H
