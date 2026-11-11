# Native Collabora migration — development only

The production OfficeFlow 0.4.3 remains unchanged. This is a migration checkpoint,
not an installable release. No claim of Windows compilation or UI validation.

Use the exact repository and commit in upstream.lock.json. The corresponding
CODA.cpp and project file are retained under upstream-reference for review;
they retain their upstream licensing. prepare.py changes native identities only.
It does not replace the editor, remove any ribbon commands, change file formats,
or modify the document model. Renaming the built hosts selects WordFlow,
CellFlow or SlideFlow; upstream's appName-based profile and taskbar ID isolate them.

## Required native build environment

Official guide: https://www.collaboraoffice.org/post/build-co-windows/

1. Use a Windows x64 machine with VS 2026 Desktop C++/.NET workloads, ClangCL,
   Git Bash, MSYS2 and the dependencies listed by windows/.config in the source.
2. Clone the repository in upstream.lock.json and checkout its exact commit.
3. Build engine/ with --with-distro=CODAWindows and the correct local tool paths.
   Use a Release engine for the Release native host; follow the official guide.
4. In a VS developer environment exposed to Git Bash, run:
   `bash collabora/build-windows.sh CHECKOUT STAGING_DIRECTORY`.

The script deliberately refuses Linux. Wine or a repackaged upstream preview is
not a replacement for this native build and its validation.

The first native build is only a development payload. Application-specific
start/new/open flows, icons, OfficeFlow updater integration, legal/source
distribution and the shared installer remain release gates (STATUS.md).
