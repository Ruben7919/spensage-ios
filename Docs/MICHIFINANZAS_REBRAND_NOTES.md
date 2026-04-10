# MichiFinanzas Rebrand Notes

## Product-facing name

The user-facing iOS name is `MichiFinanzas`.

Public App Store metadata, public URLs, legal copy, support copy, marketing scripts, growth assets, tutorial copy, launch copy, and art prompts should use `MichiFinanzas` and `https://michifinanzas.com`.

## Technical identifiers intentionally unchanged

These identifiers still use `SpendSage` or `spendsage` because changing them is destructive and requires coordinated migration across Apple, Cognito, StoreKit, backend, and installed beta clients:

- Xcode project, scheme, and target names: `SpendSage`.
- Bundle identifier: `com.spendsage.ai`.
- URL scheme and Cognito redirects: `spendsage://auth-callback` and `spendsage://auth-logout`.
- Cognito config keys and native config keys prefixed with `SpendSage`.
- StoreKit product identifiers: `spendsage.remove_ads`, `spendsage.pro.monthly`, `spendsage.pro.annual`, `spendsage.family.monthly`, `spendsage.family.annual`.
- Backend dev stack names, API paths, and internal docs that describe existing deployed resources.

Rename these only in a dedicated migration with App Store Connect product replacement/mapping, Cognito callback updates, backend environment migration, and compatibility handling for already installed TestFlight builds.

## TestFlight upload note

Build upload should use App Store Connect API key authentication instead of relying on the local Xcode account token:

```sh
ASC_KEY_PATH=/Users/rubenlazaro/.appstoreconnect/private_keys/AuthKey_995J6BAYP2.p8 \
ASC_KEY_ID=995J6BAYP2 \
ASC_ISSUER_ID=79692cb7-2085-4a35-afc8-1ca4a4c5a4d0 \
scripts/app_store/archive_and_upload.sh external
```

On 2026-04-10, the local machine could export/upload with API auth, but a fresh archive with App Store-compliant app icon assets was blocked by CoreSimulator/`actool`: `xcrun simctl list runtimes` timed out and `actool` hung while generating `Assets.car`.

The remaining local fix is to restore/install an iOS simulator runtime or run the archive on a clean macOS/Xcode runner. A reboot of macOS/Xcode is recommended before reinstalling the runtime because `CoreSimulatorService` was not reachable from `simctl`.
