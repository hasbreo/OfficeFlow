# Migration status — 12 November 2026

## Completed

- Recovered production OfficeFlow 0.4.3 source; MailFlow and PDFFlow untouched.
- Inspected official Collabora 26.04.6.1-122 Windows preview, including its
  bundled native engine, browser UI, templates, licence and native host layout.
- Verified source support for local desktop editing, native printing and a
  complete Collabora interface. Did not run the Windows preview on this host.
- Pinned current Collabora source and prepared a guarded native-host identity
  patch for WordFlow, CellFlow and SlideFlow.
- Added Windows build entry point; source-level patch tests are distinct from
  compilation and application tests.

## Blocker

This executor is Linux with no native Windows/Visual Studio build runner.
The official Windows host and engine require native MSBuild/ClangCL plus MSYS2.
No accessible Windows runner has been established. A complete custom Windows
installer has therefore NOT been built or published.

## Work required before release

- Obtain Windows build execution; build pinned engine and native host.
- Give each app its own start page and New/Open document type flows. The current
  development patch fixes identities only; upstream starter remains generic.
- Apply mint theme with full native controls retained, including dialogs,
  contextual menus and accessibility. Test both light and dark appearance.
- Integrate manual/startup signed update checks with native apps, using the
  existing production verification key (private signing key is not in source).
- Stage native payload beside unchanged MailFlow/PDFFlow; update shared installer
  shortcuts/associations and test upgrade, uninstall and rollback.
- Audit exact component licences/branding; publish corresponding modified source.
- Test real Word-like document layout, images/tables/styles, XLSX formulas,
  references/filtering/charts, slide creation/layouts/objects/presentation mode,
  save/reopen/export PDF and Windows printer dialogs on the actual native apps.
- Confirm old document/mail/profile data survives upgrade; no migration of mail
  to a new profile, no opening originals for destructive conversion.

Do not publish a release feed entry until these checks are complete. The
downloaded upstream snapshot is an inspection fixture, not an OfficeFlow build.
