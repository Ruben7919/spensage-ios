# SpendSage External Beta Readiness

Updated: 2026-04-08

## Status Legend

- `[x]` ready now
- `[-]` workable for external beta, but still not production-grade
- `[ ]` pending before external beta confidence is acceptable

## Build and Environment

- [x] Native auth is mandatory for all users.
- [x] Apple / Google / email auth paths exist in the shipping app.
- [x] Native StoreKit 2 purchase, restore, and manage flows exist.
- [x] Release builds now hide internal tester billing overrides.
- [-] Release builds still point to the live `dev` backend and `dev` Cognito stack.
- [ ] Dedicated `beta` or `prod` backend target for Release/TestFlight.

## Backend and Feature Alignment

- [x] Authenticated finance bootstrap is live.
- [x] Bidirectional authenticated sync now exists for core finance entities: expenses, accounts, bills, rules, budgets, and native profile.
- [x] Family/shared-space backend primitives exist.
- [x] Native shared-space browsing and invite acceptance UI now exist.
- [x] APNs registration is live in the backend.
- [x] Manual authenticated test-push route now exists: `POST /devices/test-push`.
- [x] SNS/APNs endpoint re-registration now re-enables disabled endpoints on the backend.
- [x] WAF, API throttling, and per-user rate limiting exist.
- [-] Conflict UX and durable offline replay journal are still beta-grade, not production-grade.
- [ ] RevenueCat or App Store Server backend reconciliation.
- [x] Low-cost first-party analytics sink now exists through `/me/telemetry`.
- [x] Low-cost first-party crash/performance diagnostics now exist via MetricKit + backend telemetry.
- [x] Release-health dashboards and native telemetry alarms now exist in CloudWatch.

## App Review / TestFlight Readiness

- [x] App Store metadata source of truth exists locally.
- [x] Pricing source of truth exists locally.
- [x] Review contact values exist locally.
- [x] App Store Connect sync was re-run on 2026-04-08 and all five monetization SKUs are now `READY_TO_SUBMIT`.
- [x] App Privacy source-of-truth now reflects authenticated cloud sync, push token upload, and first-party telemetry.
- [x] Reviewer path exists: create a fresh account or use Sign in with Apple / Google from the first screen.
- [x] Build `1.0 (22)` is uploaded to App Store Connect and `VALID`.
- [x] External TestFlight beta review for build `22` is now in `WAITING_FOR_REVIEW`.
- [x] Internal testers can use the same App Store eligible build automatically after processing.

## Push Validation

- [x] iOS can request permission and upload the APNs token.
- [x] Backend can create SNS endpoints for iOS devices.
- [x] The app can now trigger a manual test push after registration.
- [x] Authenticated backend push smoke passed against `dev`: `18/18`, including register, test-push, and unregister.
- [x] Physical iPhone delivery is now confirmed end-to-end on the latest build.

## Current Decision

- [x] SpendSage is external-beta ready as an authenticated, dev-backed TestFlight build for core flows.
- [x] SpendSage paid subscriptions are now positioned as reviewable for the current external-beta submission pack.
- [ ] SpendSage is not yet production-launch ready.

## Remaining Gate Before Public Launch

1. Decide whether external testers will stay on `dev` or whether a dedicated `beta` backend is required first.
2. Freeze the privacy answers for the exact build that will be uploaded.
3. Wire Android/FCM and optional RevenueCat server reconciliation when those secrets/accounts exist.
