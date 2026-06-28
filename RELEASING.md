# Releasing

AndroidFinder ships installers for macOS, Windows, and Linux. Releases are
fully automated: **pushing a `v*` tag builds all three platforms and publishes
a single GitHub Release** with every installer attached.

## Cut a release

1. **Bump the version** in `pubspec.yaml` (this is baked into the app):

   ```yaml
   version: 1.0.1+2      # bump both the name and the +build number
   ```

   Commit and push to `master`:

   ```bash
   git add pubspec.yaml
   git commit -m "chore: bump version to 1.0.1"
   git push origin master
   ```

2. **Tag and push** — this is what triggers the build:

   ```bash
   git tag v1.0.1
   git push origin v1.0.1
   ```

3. **Wait ~10 minutes.** The `Build & Release` workflow builds all platforms and
   publishes **AndroidFinder v1.0.1** with the installers below attached. Watch
   progress under the repo's **Actions** tab.

## What gets published

| Platform | Files |
|----------|-------|
| macOS    | `AndroidFinder-<tag>-macos.dmg` (ad-hoc signed) |
| Windows  | `AndroidFinder-<tag>-windows-setup.exe` (Inno Setup) + `-windows-portable.zip` |
| Linux    | `AndroidFinder-<tag>-linux-x86_64.AppImage` + `-linux-x86_64.tar.gz` |

## Notes

- **Tag = release.** A tag matching `v*` is the only trigger. The tag name
  becomes the release name and the installer filenames. Keep it in sync with the
  `pubspec.yaml` version.
- **Pre-releases:** use a `-` suffix, e.g. `v1.1.0-rc.1` or `v1.1.0-beta`. The
  workflow auto-marks anything containing `-` as a *prerelease* (it won't show as
  "latest").
- **Redoing a version:** tags are immutable once published. Delete first, then
  re-tag — or just bump to the next number:

  ```bash
  git push origin :refs/tags/v1.0.1   # delete remote tag
  git tag -d v1.0.1                    # delete local tag
  ```

- **Manual run:** Actions tab → *Build & Release* → *Run workflow* → enter a
  version. Re-runs the build without creating a new tag.
- **CI:** `flutter analyze` + `flutter test` run on every push/PR to `master`.
  Fix any failures there before tagging.

## Pinned toolchain

Builds use **Flutter 3.19.6** (matches the project's dev SDK), and the Windows
job runs on the **`windows-2022`** runner. Both are pinned in
`.github/workflows/release.yml` and `ci.yml` for reproducibility — update them
together if you upgrade Flutter.

## Signing (not configured)

Installers are **unsigned / ad-hoc**, so users see Gatekeeper (macOS) and
SmartScreen (Windows) warnings. Proper code-signing/notarization requires
certificates stored as repository secrets and additional workflow steps — add
when needed.
