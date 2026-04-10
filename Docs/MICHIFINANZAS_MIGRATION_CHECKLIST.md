# MichiFinanzas Migration Checklist

This checklist separates safe public-brand migration from destructive technical
identifier migration.

## Phase 1: non-destructive repo and public-name alignment

- Use `MichiFinanzas` as the public product name in README, public docs, App
  Store metadata, TestFlight metadata, marketing copy, legal copy, and support
  copy.
- Rename the GitHub iOS repository from `spensage-ios` to
  `michifinanzas-ios` and update the local `origin` remote.
- Move the legacy static public-site draft from `PublicSite/spendsage.ai` to
  `PublicSite/michifinanzas.com` and update its visible copy/domains.
- Move the legacy legal static draft from `PublicSite/legal.spendsage.ai` to
  `PublicSite/michifinanzas.com/legal` and update visible legal/support copy.
- Keep the Xcode project, scheme, target, module, source folders, and test
  target names as `SpendSage`.
- Keep the bundle identifier as `com.spendsage.ai`.
- Keep the `spendsage://` URL scheme and Cognito callback/logout URLs.
- Keep StoreKit and RevenueCat product identifiers under `spendsage.*`.
- Keep API and Cognito dev configuration pointed at the existing deployed
  backend until a parallel backend stack is validated.
- Verify repository state, remotes, whitespace, and the local TestFlight build
  gate before upload.

## Phase 2: parallel backend and web cutover

- Create or deploy a parallel backend environment only after deciding whether
  to keep the existing data plane or migrate to a new `michifinanzas` appName.
- Keep the current iOS app pointed at the existing API until the new environment
  has Cognito, SES, invite links, custom domain, legal pages, and smoke tests
  passing.
- Attach `michifinanzas.com` to the landing page through the CDK-managed
  Amplify hosting path or the documented manual fallback.
- Keep `support@michifinanzas.com` out of app copy until receiving mail is
  configured and tested end to end.

## Phase 3: app identifier migration, only if still needed

- Plan a separate App Store/Cognito migration before changing bundle ID, URL
  scheme, callback URLs, or StoreKit product identifiers.
- Support both old and new deep links during a transition window.
- Update backend invite/email links only after old installed beta builds remain
  compatible or are intentionally retired.

## Phase 4: cleanup

- Remove legacy `SpendSage` names from code only after all Apple, Cognito,
  RevenueCat, App Store Connect, backend, SES, and web deployment dependencies
  have been migrated.
- Keep a rollback path for at least one TestFlight build before deleting old
  identifiers or resources.

## TestFlight gate

Use App Store Connect API key authentication for uploads:

```sh
ASC_KEY_PATH=/Users/rubenlazaro/.appstoreconnect/private_keys/AuthKey_995J6BAYP2.p8 \
ASC_KEY_ID=995J6BAYP2 \
ASC_ISSUER_ID=79692cb7-2085-4a35-afc8-1ca4a4c5a4d0 \
scripts/app_store/archive_and_upload.sh external
```

Do not start a full archive if `xcrun simctl list runtimes` hangs locally,
because the asset catalog compiler depends on CoreSimulator and can hang during
`CompileAssetCatalogVariant`.
