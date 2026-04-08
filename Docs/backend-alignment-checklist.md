# SpendSage Native Backend Alignment Checklist

Updated: 2026-04-08

## Verified now

- [x] `spendsage` backend tests passed locally on 2026-04-07: `26/26`, `76/76`.
- [x] Authenticated smoke checks passed against current dev API: `18/18` on `https://cz2vxbcze4.execute-api.us-east-1.amazonaws.com/dev/` with push register/test/unregister included.
- [x] Native iOS app bundle now includes explicit backend config for the current dev API.
- [x] Native iOS app now reads backend capabilities and billing entitlements when Cognito Hosted UI tokens are available.
- [x] Native iOS settings/premium flows now expose cloud status for faster QA alignment.
- [x] Backend repo now includes a launch billing catalog, pricing fallback for non-prod, a public billing catalog endpoint, and `/me/cloud-bootstrap`.
- [x] Current `dev` stack is deployed and now exposes CloudWatch ops dashboard `spendsage-dev-operations`.
- [x] APNs `dev` key is stored in AWS Secrets Manager and `spendsage-dev-stack` now exposes `IosPushPlatformApplicationArn`.
- [x] Authenticated `/devices/register` validation passed against `dev` with Cognito + SNS endpoint creation.
- [x] Authenticated `/devices/test-push` route now exists for device-level delivery validation without waiting on budget alerts.
- [x] Device re-registration against SNS now re-enables previously disabled APNs endpoints in `dev`.
- [x] Authenticated finance bootstrap smoke passed against `dev` on 2026-04-07, including `/me/finance-bootstrap`, `/me/native-profile`, expense creation with `locationLabel`, and tester-plan overrides.
- [x] App Store Connect monetization metadata now clears reviewability for all five SKUs, and version `1.0` includes them in `Compras dentro de la app y suscripciones`.

## Backend state by feature

- [x] Cognito + Hosted UI + Apple/Google provider wiring exists in CDK/backend.
- [x] WAF exists in CDK with managed rules + IP rate limiting.
- [x] API Gateway throttling exists.
- [x] Per-user rate limiting exists in backend domain/security layer.
- [x] RevenueCat entitlements + family role sync exist.
- [x] Family spaces, invites, members and role updates exist.
- [x] Device registration endpoint exists for push.
- [x] Shared-space data model exists in DynamoDB.
- [x] Async workers exist for invoice OCR, CSV import, outbound webhooks and account deletion.
- [x] Updated pricing fallback/catalog changes are deployed to the current dev environment.
- [x] APNs-backed iOS push registration is enabled in the current dev backend.
- [x] Authenticated manual test-push dispatch exists in the backend and native iOS app.
- [x] Pricing and launch promo data are seeded in the current dev environment.
- [x] Push delivery is now validated on physical iPhone for the current TestFlight/dev-backed path.
- [x] Native iOS app now consumes authenticated cloud finance bootstrap and native-profile state beyond auth/capabilities.
- [x] Low-cost first-party crash/performance telemetry is wired end-to-end through MetricKit + `/me/telemetry`.
- [x] Backend rollback-friendly API deployment retention and CloudWatch operational alarms exist in `dev`.
- [x] Low-cost first-party analytics sink exists beyond local event buffering through `/me/telemetry`.
- [x] Native telemetry now feeds CloudWatch release-health graphs and a MetricKit diagnostic alarm in backend infra.

## Native iOS gaps still open

- [x] Remote bootstrap plus first-write sync exist for expenses, accounts, bills, rules, and native profile in authenticated sessions.
- [x] Core bidirectional sync coverage now exists for expenses, accounts, bills, rules, and native profile.
- [-] Explicit conflict UX and durable replay journal are still open.
- [x] Shared family space browsing and invite acceptance UI now exist.
- [x] Push permission flow and token registration now exist for iOS.
- [x] Release builds now hide internal tester billing overrides.
- [x] Native StoreKit 2 purchase and restore flows exist.
- [x] Offline-first bootstrap merge now aligns local ledger and cloud state per authenticated session.
- [x] Remote notification delivery is validated end-to-end on physical iPhone.
- [ ] RevenueCat server sync remains optional and is not wired yet.
- [ ] Full mutation journal / replay strategy is still open for resilient offline conflict recovery.
- [ ] Cloud legal/support screens fed directly from backend/public endpoints.

## Infra and deploy blockers

- [x] Current dev API is reachable publicly.
- [x] AWS credentials are available on this machine.
- [x] Safe deploy path exists from this machine with `npx aws-cdk` plus exported live Cognito env.
- [x] Pricing table has active plans in DynamoDB for `dev`.
- [x] APNs credentials are loaded for iOS push in `dev`.
- [ ] FCM credentials are loaded for Android push.
- [ ] RevenueCat secrets are loaded for server sync.
- [x] CloudWatch alarms/dashboards/release rollback policy are configured at backend infra level.

## Recommended next implementations

- [x] Add a native authenticated API layer for finance bootstrap, native profile, and first-write sync.
- [x] Extend the native API layer to shared spaces, invites, and core finance mutation coverage.
- [ ] Move the local ledger into a fuller sync engine with conflict policy per entity and replay journal.
- [x] Wire APNs permission + token upload to `/devices/register`.
- [ ] Add RevenueCat native SDK flow and map Cognito `sub` to `appUserId`.
- [x] Add richer release-health dashboards on top of the current first-party telemetry pipeline.
- [-] Add CloudWatch alarms, synthetic smoke gate and rollback runbook. Full automated canary rollback remains open.
- [ ] Consume `/public/billing-catalog` from native iOS so plan copy and entitlement IDs stop drifting.
- [ ] Add feature flags so `dev`, `staging` and `prod` can diverge safely without recompiling.
- [x] Add optional calendar reminder sync for recurring bills and optional expense location tagging with updated privacy copy.

## Nice to have

- [ ] App Attest / DeviceCheck hardening for abuse-sensitive mutations.
- [ ] Background refresh for billing and shared-space invite state.
- [ ] Audit event export to SIEM / security lake.
- [ ] Bank connector abstraction beyond mock provider.
- [ ] Explainable AI insight traces for premium support/debugging.
