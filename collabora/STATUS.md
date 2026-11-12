# Native migration and release verification

WordFlow, CellFlow and SlideFlow use the full source-built native Collabora
engine. Their executable names select independent Windows titles, taskbar IDs,
profiles and document-family start pages. New files use DOCX, XLSX and PPTX.
OfficeFlow branding leaves the complete native interface and commands intact.

MailFlow and PDFFlow retain the existing shared application, downloaded archives
and profiles. Native document apps invoke the same signed update service through
a fixed installed helper. The updater requires open apps to be closed by the
user before installing.

The native engine build passed on 12 November 2026. Build and test evidence is
recorded in the repository's GitHub Actions runs. A complete engine cache allows
interface and installer fixes without repeating its compilation.

## Mandatory release gates

`.github/workflows/suite-package.yml` runs these checks against the actual
source-built Windows payload and installed suite:

1. Edit and save real DOCX, XLSX and PPTX files, export PDFs, close normally and
   reopen the resulting files. Rich fixtures check document tables, images and
   headers; exact cell references, cross-sheet calculations and charts; and
   presentation images and slide creation.
2. Assemble one installer with independent native document executables and the
   shared MailFlow/PDFFlow executables, product identities and icons.
3. Install over OfficeFlow 0.4.3 in a path containing spaces and Unicode. Check
   shortcut targets, executable metadata and retention of a synthetic local email.
4. Start each document app without arguments, check its own start page, create
   the correct blank Office format, verify ready-to-edit mode and close normally.
5. Repeat native edit/save/PDF/close/reopen checks after installation. Open and
   cancel the actual Windows Print dialog through the bundled printing helper.
6. Start installed MailFlow and PDFFlow, then verify uninstall and rollback keep
   local user data. Package corresponding source without keys, profiles or caches.

Only a passing workflow publishes verified candidate assets. Hasbreo's signed
release information is promoted after inspecting those exact assets. The
official vendor preview is an isolated test fixture and is never shipped as
OfficeFlow.

Physical printers and arbitrary Microsoft Office documents require local
testing. Fonts, macros, advanced layouts and animations can behave differently
from Microsoft Office; the migration does not promise perfect format fidelity.
