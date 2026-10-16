# Releasing (fork)

This fork publishes its own Android builds. Everything fork-specific lives in new files so pulling
from upstream stays conflict-free:

| File | Purpose |
|---|---|
| `.github/workflows/fork-release.yml` | builds signed APKs and publishes a GitHub release |
| `.github/fork/version.sh` | version name from the latest `v*` tag |
| `.github/fork/changelog.sh` | release notes from `FORK_CHANGELOG.md` |
| `FORK_CHANGELOG.md` | one `## <version>` section per release |

The only edited upstream line is `applicationId = "io.nuc134r.chameleon"` in
`chameleonultragui/android/app/build.gradle`. The Kotlin namespace stays `io.chameleon.ultra`
on purpose (renaming it would move `MainActivity.kt` and conflict with every upstream change there).

## One-time setup

### 1. Turn off upstream's workflows

Upstream's workflows run in forks too. **Build APP** creates its own release for *every* tag
(including ours) and force-pushes a `dev` tag on `main`; **Publish APP** tries to upload to the
Play Store / App Store. Disable them instead of editing them (edits would conflict on every merge):

Repo **Actions** tab → select the workflow → **⋯ → Disable workflow** for:

- Build APP
- Publish APP
- Update translations, Add Crowdin keys (need upstream's Crowdin secrets)
- Test Apple publishing

### 2. Create an upload keystore

Android only installs an update if it is signed with the **same key** as the installed app, so
create one key and keep it forever. Back up the `.jks` file and its passwords (password manager);
if you lose them, the app must be uninstalled to get new versions.

Run this **outside the repo**:

```bash
keytool -genkeypair -v -keystore C:\Users\chelm\keys\chameleon-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias chameleon
```

`keytool` comes with any JDK. It asks for a keystore password, a name (anything) and a key
password (press Enter to reuse the keystore password).

### 3. Add repository secrets

Repo **Settings → Secrets and variables → Actions → New repository secret**:

| Secret | Value |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | the `.jks` file, base64-encoded (see below) |
| `ANDROID_KEYSTORE_PASSWORD` | keystore password |
| `ANDROID_KEY_ALIAS` | `chameleon` (the `-alias` above) |
| `ANDROID_KEY_PASSWORD` | key password |

Base64-encode the keystore to the clipboard (PowerShell):

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\Users\chelm\keys\chameleon-upload.jks")) | Set-Clipboard
```

Without these secrets the workflow still runs but signs with a throwaway debug key and warns —
fine for testing, not for real releases.

## Making a release

1. Add a `## <version>` section to `FORK_CHANGELOG.md` (rename `## Unreleased`).
2. Tag and push:

   ```bash
   git tag v2.0.0
   git push origin v2.0.0
   ```

   Or, without git: **Actions → Fork release APK → Run workflow** with *version* `2.0.0` — the
   workflow tags the commit it built and publishes the release.

3. The release *Chameleon 2.0.0* gets:
   - `chameleon-2.0.0.apk` — universal, any phone (largest)
   - `chameleon-2.0.0-arm64-v8a.apk` — most modern phones (smallest)
   - `chameleon-2.0.0-armeabi-v7a.apk`, `chameleon-2.0.0-x86_64.apk` — older phones / emulators

The version name comes from the tag (`v1.2.3` → `1.2.3`); the version code is the workflow run
number, so it always increases. Tags with a suffix (`v2.0.0-beta.1`) become pre-releases. Only tags
starting with `v` and a digit trigger the workflow, so upstream tags pulled into the fork don't.

To build APKs **without** releasing, run the workflow with an empty version; the APKs are attached
to the run as an artifact.

## Pulling from upstream

```bash
git remote add upstream https://github.com/GameTec-live/ChameleonUltraGUI.git   # once
git fetch upstream --no-tags
git merge upstream/main
```

`--no-tags` keeps upstream's tags (e.g. its `dev` tag) out of the fork.

## Installing on the phone

Download the APK from the release page on the phone and open it; allow "Install unknown apps" for
the browser when asked. The app id is `io.nuc134r.chameleon`, so it installs next to the upstream
app (`io.chameleon.ultra`).
