# SpendSage Native iOS Migration Plan

## Phase 1

- native app shell with a reusable design system foundation
- polished onboarding that feels intentional on first launch
- auth UI shell, but no backend dependency yet
- guest local mode as the default first-run path
- dashboard with local sample data and clear empty states

### Phase 1 exit criteria

- onboarding hands off cleanly into auth or guest mode
- first-run screens share a consistent visual language instead of one-off styling
- no flow requires backend availability to explain the product
- shell components are reusable enough to support later screens without copy/paste
- release builds stay green on the native track

## Phase 2

- local ledger and recurring bills
- categories, rules, and accounts
- native design system hardening beyond the shell
- app storage and persistence

## Phase 3

- Cognito Hosted UI integration
- RevenueCat native purchases
- AdMob native banners
- legal/support/account settings

## Phase 4

- backend sync
- spaces/family sharing
- OCR/import flows
- notifications and review loops

## Rules

- Keep contracts aligned with the backend repo.
- Prefer local-first UX and optimistic UI.
- Only move a flow when its analytics, copy, and legal surface are understood.
- Do not pull backend-only capabilities into phase 1 just to complete a screen.
