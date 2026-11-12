# OfficeFlow

Five independent Windows applications with one installer and signed updates:
WordFlow, CellFlow, SlideFlow, MailFlow and PDFFlow.

The document apps use the full local Collabora / LibreOffice engine and tabbed
interface, with OfficeFlow branding. MailFlow and PDFFlow keep the existing
shared application and its user data. No document server is required.

Downloads and release notes: https://hasbreo.com/officeflow/

## Build and release

- `collabora/upstream.lock.json` pins the native source revision.
- `collabora/prepare.py` applies guarded native identity, start-page, Office-format
  template and updater patches. Editor commands and the document model remain upstream.
- `.github/workflows/collabora-build.yml` builds the native Windows payload and
  caches the completed engine before assembling the interface.
- `.github/workflows/suite-package.yml` tests the actual native apps, assembles
  the installer, verifies upgrade/uninstall and publishes a verified candidate.
- `integration/README.release.md` describes installation and features.

See [native build instructions](collabora/BUILD.md),
[verification gates](collabora/STATUS.md) and [component licensing](LICENSING.md).
The official preview package is used only as an isolated test fixture; it is
not included in the OfficeFlow release.

Shared application source is obtained from the checksum-pinned existing source
distribution. No user mail, profiles or private release-signing keys belong in
this repository. Microsoft Office's exact layout and advanced feature behaviour
can differ; OfficeFlow does not promise perfect compatibility.
