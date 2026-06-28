# Cross-Platform Release & CI — Design

**Date:** 2026-06-28
**Status:** Approved

## Goal

Every GitHub Release for this project should ship installer artifacts for **all
supported desktop platforms** (macOS, Windows, Linux — the three platform
folders present in the repo). Add a CI workflow that runs quality checks on
regular pushes/PRs.

## Workflows

### `ci.yml` — quality checks
- **Triggers:** `push` and `pull_request` targeting `master`.
- **Runner:** `ubuntu-latest`.
- **Steps:** checkout → setup Flutter 3.x (stable) → `flutter pub get` →
  `flutter analyze` → `flutter test` (guarded: skips gracefully if no
  `*_test.dart` files exist).

### `release.yml` — multi-platform build + publish
- **Trigger:** push of a tag matching `v*` (e.g. `v1.2.0`). Also
  `workflow_dispatch` with a `version` input for manual re-runs.
- **Version:** derived from `github.ref_name` (tag). A numeric form with the
  leading `v` stripped is used where installers require it (Inno Setup
  `AppVersion`).

Three parallel build jobs, each producing artifacts:

| Platform | Runner          | Build command            | Artifacts |
|----------|-----------------|--------------------------|-----------|
| macOS    | `macos-latest`  | `flutter build macos`    | `AndroidFinder-<ver>-macos.dmg` (ad-hoc signed, via `create-dmg`) |
| Windows  | `windows-latest`| `flutter build windows`  | `AndroidFinder-<ver>-windows-setup.exe` (Inno Setup) + `AndroidFinder-<ver>-windows-portable.zip` |
| Linux    | `ubuntu-latest` | `flutter build linux`    | `AndroidFinder-<ver>-linux-x86_64.AppImage` + `AndroidFinder-<ver>-linux-x86_64.tar.gz` |

Each job uploads its files with `actions/upload-artifact@v4`.

A final **`release`** job (`needs: [build-macos, build-windows, build-linux]`)
downloads all artifacts and publishes a single GitHub Release for the tag via
`softprops/action-gh-release@v2` with `generate_release_notes: true`. All three
platforms must succeed for the release to publish (clean, predictable; can be
relaxed to tolerate partial failures later if desired).

## Supporting files

- `windows/packaging/installer.iss` — Inno Setup script. Installs the contents
  of `build/windows/x64/runner/Release/` into Program Files, creates Start-menu
  (and optional desktop) shortcuts, registers an uninstaller. Version injected
  via `iscc /DMyAppVersion=...`.
- `linux/packaging/android_finder.desktop` — Desktop entry for the AppImage.
- `linux/packaging/AppRun` — AppImage entrypoint; sets `LD_LIBRARY_PATH` and
  execs the bundled binary.
- The AppImage icon reuses `macos/.../app_icon_256.png`.

## Platform build details

- **Linux deps** (apt): `clang cmake ninja-build pkg-config libgtk-3-dev
  liblzma-dev`.
- **Linux bundle** lives at `build/linux/x64/release/bundle/` (executable +
  `lib/` + `data/`). The whole bundle is placed under `AppDir/usr/bin/`; `AppRun`
  cds/execs into it. `appimagetool` is run with `--appimage-extract-and-run`
  (no FUSE on runners) and `ARCH=x86_64`.
- **Windows bundle** lives at `build/windows/x64/runner/Release/`. The portable
  zip is that folder zipped; the setup.exe is produced by Inno Setup installed
  via `choco install innosetup`.
- **macOS** keeps the existing `create-dmg` flow (works on CI runners; the
  Finder-AppleScript permission issue only affects local non-interactive runs).

## Binary / app identity (from repo)

- Binary name: `android_finder` (linux + windows)
- Windows exe: `android_finder.exe`
- Linux application id: `com.dee.andriod.finder.android_finder`
- macOS bundle id: `com.dee.andriod.finder.androidFinder`

## Out of scope

- Real code-signing / notarization (macOS) and Authenticode (Windows) — uses
  ad-hoc/unsigned. Can be added later with secrets.
- Mobile (Android/iOS) and web — not configured in the repo.
- `.deb`/`.rpm` Linux packages — AppImage + tar.gz cover broad distribution.
