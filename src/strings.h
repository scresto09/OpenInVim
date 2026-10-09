/*
 * OpenInVim - Windows 11 File Explorer context menu for Vim
 * Copyright (C) 2026 Sylvain Cresto
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Identifiers of the translated texts (string tables in lang/*.rc) and the
 * function to load them.  Windows picks the language of the user, and
 * falls back to the neutral (English) table.
 */

#ifndef OPENINVIM_STRINGS_H
#define OPENINVIM_STRINGS_H

// Context menu entry (OpenInVim.dll)
#define IDS_EDIT_IN_VIM         100
#define IDS_OPEN_IN_VIM         101

// Settings window (OpenInVim.exe)
#define IDS_SETTINGS_TITLE      200
#define IDS_GROUP_GVIM          201
#define IDS_GVIM_LABEL          202
#define IDS_GVIM_CUE            203
#define IDS_BROWSE              204
#define IDS_STATUS_AUTO         205
#define IDS_STATUS_NOT_FOUND    206
#define IDS_STATUS_MISSING      207
#define IDS_GROUP_OPEN          208
#define IDS_USE_TABS            209
#define IDS_CANCEL              210
#define IDS_VERSION             211
#define IDS_LICENSE             212
#define IDS_BROWSE_TITLE        213
#define IDS_BROWSE_FILTER       214
#define IDS_ERROR_MISSING       215
#define IDS_ERROR_SAVE          216

#ifndef RC_INVOKED
#include <windows.h>
#include <string>

/*
 * Text "id" from the string table of module "inst".
 */
static inline std::wstring load_string(HINSTANCE inst, UINT id)
{
    const WCHAR *text;
    int         len;

    // With a zero size, LoadStringW returns a pointer to the resource
    // itself, which is not NUL terminated.
    len = LoadStringW(inst, id, (LPWSTR)&text, 0);
    return len > 0 ? std::wstring(text, len) : std::wstring();
}
#endif

#endif // OPENINVIM_STRINGS_H
