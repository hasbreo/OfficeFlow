# OfficeFlow source licensing

Original OfficeFlow files in this repository are licensed under the Mozilla Public License 2.0, unless a file states another licence. The full licence is in `LICENSE`. Upstream reference files retain their existing notices.

The shared MailFlow/PDFFlow application obtained through `integration/source.lock.json` remains **AGPL-3.0-or-later**. Its source distribution includes its own licence, dependency notices and corresponding MuPDF source. Integrating the native document apps does not remove those requirements.

The document engine and interface use the exact Collabora source revision recorded in `collabora/upstream.lock.json`. Native modifications and branding are included here. Build outputs retain `LICENSE.html`, `NOTICE` and component copyright/licence notices, and include a pointer to the corresponding source.

The public release uses a source-built engine and OfficeFlow product branding. The official Collabora preview package used by isolated Windows test workflows is a test fixture and is not distributed as OfficeFlow.

Third-party dependencies retain their respective licences. OfficeFlow does not include a Collabora subscription, commercial support entitlement or Microsoft Office licence.
