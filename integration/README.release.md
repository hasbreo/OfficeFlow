# OfficeFlow 0.5.0

Five independent Windows apps with one installer:

- **WordFlow:** documents, styles, page layout, tables, pictures, comments and revision tools.
- **CellFlow:** spreadsheets, cell and cross-sheet formulas, charts, sorting, filters and print layouts.
- **SlideFlow:** slide layouts, text, pictures, shapes, presentations and PDF export.
- **MailFlow:** Gmail sign-in, local message and attachment downloads, search, labels, drafts and backups.
- **PDFFlow:** PDF reading, annotations, page operations and text editing.

The three document apps now use the full local Collabora desktop engine and interface. MailFlow and PDFFlow retain their existing profile and archive locations. OfficeFlow does not require a document server or a subscription.

## Install or update

Close OfficeFlow programs and run `OfficeFlow-Setup-0.5.0.exe`. Install over the existing location to update. Each Start-menu shortcut opens its own app. Older pinned shortcuts are forwarded to the matching native editor.

Windows 10/11, 64-bit. Setup installs Microsoft WebView2 if it is missing; that dependency installation needs internet access.

Use **File → Check for updates** in a document app, or the existing update command in MailFlow and PDFFlow. Startup checks respect the shared automatic-update preference. An update is offered for installation; open apps must be closed first. Downloads are checked against the publisher's existing release-signing key and SHA-256.

The installer preserves documents, downloaded mail and user profiles. Uninstall removes program files and registered shortcuts, while keeping user data. The installer is not Authenticode-signed.

## Files

New documents use DOCX, XLSX and PPTX. The native document engine supports additional Office and OpenDocument formats. Use its File menu to print or export PDF. The bundled printing helper includes its .NET runtime.

Keep original copies of important Microsoft Office files. OfficeFlow uses a different engine; fonts, macros, advanced features and exact layout can differ from Microsoft Office. This is not a promise of perfect formatting compatibility.

## Mail

MailFlow continues to use the publisher's registered Google desktop client. Google's restricted-scope verification is separate from this engine migration. Offline archives and imported mail remain available independently of Google sign-in. Complete downloaded messages and attachments are retained locally; choose a separate backup location for additional protection.

## Source and licences

Shared MailFlow/PDFFlow application source and the native build recipe are included in the source distribution. The exact Collabora source revision and native modifications are published at https://github.com/hasbreo/OfficeFlow. Component notices and licences are retained. The shared application is AGPL-3.0-or-later; Collabora's modified native source retains MPL-2.0 notices. Private signing keys are excluded.
