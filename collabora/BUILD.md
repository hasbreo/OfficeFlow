# Native Windows build

The supported build recipe is `.github/workflows/collabora-build.yml`, using a
Windows VS 2026 runner. The full engine compiled successfully in run
[43141296679](https://github.com/hasbreo/OfficeFlow/actions/runs/43141296679).

The exact source repository and commit are recorded in `upstream.lock.json`.
`prepare.py` checks that revision and refuses unexpected source edits. It patches
native identities, independent document-family start pages, blank Office file
templates, editable local files, signed update commands and the native NASM path
rule. Full editor commands and the document model remain upstream.

## Reproduce the native payload

Use **Build Collabora native editors → Run workflow** in GitHub Actions. The
workflow installs checksum-verified native dependencies, sets up MSYS2, validates
the source patches and runs these commands from the OfficeFlow repository:

```bash
bash collabora/ci-build.sh engine
bash collabora/ci-build.sh desktop
```

For a local Windows build, reproduce the workflow's VS 2026 Desktop C++/.NET,
ClangCL, Git Bash and MSYS2 environment first. The recipe deliberately uses fixed
paths `C:/of-source`, `C:/of-build`, `C:/of-tools` and `C:/of-downloads`; the
dependency setup is in `collabora/ci-dependencies.ps1`. Keep those directories
dedicated to this build. `MSYS2_ROOT` must identify the installed MSYS2 tree.
The upstream [Windows build guide](https://www.collaboraoffice.org/post/build-co-windows/)
explains the underlying toolchain.

The first engine build takes several hours. A successful engine is cached with
its SDK before the interface and native hosts compile. Subsequent builds can
reuse it. `native-checkpoint.yml` provides bounded stages with saved source and
objects if a hosted runner reaches its time limit.

The `officeflow-native-development` artifact contains the complete native
payload. Its name identifies a build input, not a finished installer.

## Assemble and verify the installer

The successful native workflow triggers **Package and verify OfficeFlow suite**.
That workflow can also be dispatched with a successful native run ID. It obtains
the checksum-pinned shared source, applies integration, builds the installer and
runs the release gates in `STATUS.md`. Only passing candidates are published as
GitHub prerelease assets. Promotion to Hasbreo.com's signed updater feed follows
verification of those exact assets.

The source archive includes the shared application's source, its third-party
notices and corresponding MuPDF source, together with this exact native build
recipe. The native upstream source remains available at the pinned public
revision. Private release keys are excluded.
