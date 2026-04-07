# SpendSage Native Backend Alignment Checklist

Updated: 2026-04-07

## Verified now

- [x] `spendsage` monorepo tests passed locally: backend `25/25`, `73/73`; mobile `16/16`; web `1/1`.
- [x] Authenticated smoke checks passed against current dev API: `15/15` on `https://cz2vxbcze4.execute-api.us-east-1.amazonaws.com/dev/`.
- [x] Native iOS app bundle now includes explicit backend config for the current dev API.
- [x] Native iOS app now reads backend capabilities and billing entitlements when Cognito Hosted UI tokens are available.
- [x] Native iOS settings/premium flows now expose cloud status for faster QA alignment.
- [x] Backend repo now includes a launch billing catalog, pricing fallback for non-prod, a public billing catalog endpoint, and `/me/cloud-bootstrap`.
- [x] Current `dev` stack is deployed and now exposes CloudWatch ops dashboard `spendsage-dev-operations`.
- [x] APNs `dev` key is stored in AWS Secrets Manager and `spendsage-dev-stack` now exposes `IosPushPlatformApplicationArn`.
- [x] Authenticated `/devices/register` validation passed against `dev` with Cognito + SNS endpoint creation.

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
- [ ] Pricing data is seeded in the current dev environment.
- [ ] Push delivery is enabled in the mobile clients.
- [ ] Native iOS app consumes shared cloud data beyond auth/capabilities.
- [ ] Crash telemetry is wired end-to-end.
- [x] Backend rollback-friendly API deployment retention and CloudWatch operational alarms exist in `dev`.
- [ ] Real analytics pipeline exists beyond local event buffering.

## Native iOS gaps still open

- [ ] Remote expense/budget/account/bill/rule sync.
- [ ] Shared family space browsing and invite acceptance UI.
- [ ] Push permission flow, token registration and notification routing.
- [ ] RevenueCat/App Store billing bridge.
- [ ] Offline-first merge strategy between local ledger and shared cloud state.
- [ ] Cloud legal/support screens fed directly from backend/public endpoints.

## Infra and deploy blockers

- [x] Current dev API is reachable publicly.
- [x] AWS credentials are available on this machine.
- [x] Safe deploy path exists from this machine with `npx aws-cdk` plus exported live Cognito env.
- [ ] Pricing table has active plans in DynamoDB for `dev` (`0` live rows today; API currently uses fallback bootstrap).
- [x] APNs credentials are loaded for iOS push in `dev`.
- [ ] FCM credentials are loaded for Android push.
- [ ] RevenueCat secrets are loaded for server sync.
- [x] CloudWatch alarms/dashboards/release rollback policy are configured at backend infra level.

## Recommended next implementations

- [ ] Add a native `SpendSageAPI` layer for expenses, budgets, spaces, invites and billing.
- [ ] Move the local ledger into a sync engine with conflict policy per entity.
- [x] Wire APNs permission + token upload to `/devices/register`.
- [ ] Add RevenueCat native SDK flow and map Cognito `sub` to `appUserId`.
- [ ] Add Sentry or Crashlytics plus release health dashboards.
- [ ] Add CloudWatch alarms, synthetic smoke gate and canary rollback strategy.
- [ ] Consume `/public/billing-catalog` from native iOS so plan copy and entitlement IDs stop drifting.
- [ ] Add feature flags so `dev`, `staging` and `prod` can diverge safely without recompiling.

## Nice to have

- [ ] App Attest / DeviceCheck hardening for abuse-sensitive mutations.
- [ ] Background refresh for billing and shared-space invite state.
- [ ] Audit event export to SIEM / security lake.
- [ ] Bank connector abstraction beyond mock provider.
- [ ] Explainable AI insight traces for premium support/debugging.
