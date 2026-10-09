#
# OpenInVim - Windows 11 File Explorer context menu for Vim
# Copyright (C) 2026 Sylvain Cresto
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Run "nmake -f Make_mvc.mak" in a Visual Studio Developer Command Prompt for
# the target architecture (x64 or ARM64).  Outputs go to the "build"
# directory.
#

OUT=build

CFLAGS=/nologo /c /O2 /W4 /EHsc /MT /utf-8 /DUNICODE /D_UNICODE
LDFLAGS=/nologo

all: $(OUT)\OpenInVim.dll $(OUT)\OpenInVim.exe

$(OUT):
        @if not exist $(OUT) mkdir $(OUT)

$(OUT)\OpenInVim.dll: $(OUT) $(OUT)\openinvim.obj $(OUT)\openinvim.res \
                src\openinvim.def
        link $(LDFLAGS) /DLL /DEF:src\openinvim.def /out:$@ \
                $(OUT)\openinvim.obj $(OUT)\openinvim.res \
                kernel32.lib advapi32.lib user32.lib ole32.lib shlwapi.lib

$(OUT)\OpenInVim.exe: $(OUT) $(OUT)\openinvim_app.obj $(OUT)\openinvim_app.res
        link $(LDFLAGS) /SUBSYSTEM:WINDOWS /out:$@ \
                $(OUT)\openinvim_app.obj $(OUT)\openinvim_app.res \
                kernel32.lib advapi32.lib user32.lib gdi32.lib comdlg32.lib \
                comctl32.lib shell32.lib

$(OUT)\openinvim.obj: $(OUT) src\openinvim.cpp src\gvimpath.h src\strings.h
        $(CC) $(CFLAGS) /Fo$@ src\openinvim.cpp

$(OUT)\openinvim_app.obj: $(OUT) src\openinvim_app.cpp src\gvimpath.h \
                src\resource.h src\strings.h
        $(CC) $(CFLAGS) /Fo$@ src\openinvim_app.cpp

# Translated texts, included by both resource files.
LANG_FILES=src\strings.h src\lang\en.rc src\lang\fr.rc

$(OUT)\openinvim.res: $(OUT) src\openinvim.rc $(LANG_FILES)
        $(RC) /nologo /i src /fo $@ src\openinvim.rc

$(OUT)\openinvim_app.res: $(OUT) src\openinvim_app.rc src\resource.h \
                src\openinvim.ico src\openinvim_app.manifest $(LANG_FILES)
        $(RC) /nologo /i src /fo $@ src\openinvim_app.rc

clean:
        -if exist $(OUT) rmdir /s /q $(OUT)
