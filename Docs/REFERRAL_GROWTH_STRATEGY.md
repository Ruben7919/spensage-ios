# SpendSage Referral Growth Strategy

Updated: 2026-04-08

## Goal

Grow installs and retained users without colliding with App Store rules or turning the app into a spam loop.

## Guardrails

- Reward referrals, not App Store ratings or reviews.
- Never gate app usage, money, or unlocks behind notification permission.
- Keep the reward tied to in-app value, not cash.

Relevant Apple guidance:

- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
  - avoid incentivized or manipulated reviews
  - avoid forcing permissions in exchange for value

## Recommended v1

- Every authenticated user gets a shareable referral code or deep link.
- The invited user gets a small welcome reward after account creation and first activation milestone.
- The inviter gets a matching reward only after the referred account becomes meaningfully active.

## Activation Milestone

Do not reward on raw install alone. Reward when the referred user does all of this:

- creates or signs into an account;
- completes onboarding;
- creates at least 3 expenses or completes a first budget;
- remains active for at least 24 hours.

## Rewards That Fit SpendSage

Recommended order:

1. `30 days of Pro`
2. `Remove Ads` discount or promo credit
3. `Family` seat or temporary Family upgrade credit

Why:

- these rewards use product value you already control;
- they do not require cash payouts;
- they align with your existing free / pro / family packaging.

## Product Surfaces

- Onboarding completion: soft invite after the user first understands the app.
- Celebration moments: after a budget streak, savings goal, or first successful month close.
- Settings / Premium: persistent `Invitar y ganar` entry.
- Family plan: separate `Invite household` flow, not mixed with viral referral rewards.

## Anti-Abuse Baseline

- one reward per new Cognito `sub`;
- one reward per device fingerprint or APNs token hash where available;
- block self-referrals by identical email domain + account owner heuristics where obvious;
- hold the reward in `pending` state until activation criteria are met;
- add manual review for unusually high invite velocity.

## Backend Shape

Use a lightweight referral model:

- `referralCode`
- `inviterUserId`
- `referredUserId`
- `status`: `created`, `signed_up`, `activated`, `rewarded`, `rejected`
- `rewardType`
- `rewardGrantedAt`

## Suggested Rollout

- Phase 1: manual invite code + backend reward ledger + premium-day rewards
- Phase 2: share sheet deep links + attribution
- Phase 3: family-specific referral campaigns and promo stacking rules

## Do Not Do

- Do not reward App Store reviews.
- Do not promise money or gift cards first.
- Do not reward before activation.
- Do not merge `family invite` and `viral referral` into the same mechanic.
