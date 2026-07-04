# Fastlane for Baskit

Automates Google Play Store builds and uploads using Fastlane.

## Prerequisites

1. **Install Fastlane** (macOS/Linux):
   ```bash
   gem install fastlane -NV
   ```

2. **Google Play Console Service Account**:
   - Create a service account in Google Cloud Console with the **Service Account User** role.
   - In Google Play Console → Users and permissions, invite the service account email with **Release Manager** (or higher) permissions.
   - Download the JSON key and save it securely.

3. **Environment Variables**:
   Set the following environment variables (or add them to your CI secrets):

   | Variable                  | Description                                    |
   |---------------------------|------------------------------------------------|
   | `PLAY_CONFIG_JSON`        | Path to the Google Play service account JSON   |
   | `RELEASE_KEYSTORE_BASE64` | Base64-encoded release keystore file           |
   | `KEYSTORE_PASSWORD`       | Keystore password                              |
   | `KEY_PASSWORD`            | Key password                                   |
   | `KEY_ALIAS`               | Key alias                                      |

## Lanes

### `internal`
Build a signed, obfuscated AAB and upload to the **Internal testing** track.
```bash
cd app
fastlane internal
```

### `beta`
Build and upload to the **Closed testing (beta)** track.
```bash
cd app
fastlane beta
```

### `production`
Promote to **Production** with a 10% staged rollout. Requires **manual confirmation** before proceeding.
```bash
cd app
fastlane production
```

> **Approval Gate**: The `production` lane uses `UI.confirm` to prompt for manual approval. When run in CI via `FASTLANE_SKIP_UPDATE_PROMPT`, the `publish-play.yml` workflow enforces an additional **GitHub Environment** approval gate before the production job runs.

### `upload_symbols`
Upload native debug symbols for an existing release.
```bash
cd app
fastlane upload_symbols
```

### `build`
Build the release AAB and APK locally without uploading.
```bash
cd app
fastlane build
```

## CI Integration

The `.github/workflows/publish-play.yml` workflow wraps these lanes:
- Triggered manually via `workflow_dispatch` with a track selector.
- The **production** track requires approval through the `play-production` GitHub Environment protection rule.

## Notes

- This directory (`app/fastlane/`) must be run from the `app/` directory since that's where the Flutter project root lives.
- Release artifacts are obfuscated (`--obfuscate`) and debug symbols are split to `build/app/outputs/symbols/`.
- Production rollouts start at 10%. Increase the percentage manually in Play Console after monitoring.
