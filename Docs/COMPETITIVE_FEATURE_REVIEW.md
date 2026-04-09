# Competitive Feature Review

Updated: 2026-04-09

## Principle

SpendSage should not copy every competitor surface. The product direction is to keep the daily loop simple: one clear money number, one next action, optional deeper tools behind progressive disclosure, and family collaboration only when it helps a household.

## Competitor Signals

| Competitor | Strong signals | SpendSage response |
| --- | --- | --- |
| [YNAB](https://www.ynab.com/features) | Bank import, multi-device sync, subscription sharing up to close groups, targets, loan planner, reports. | Keep goals/missions and family simple; defer bank import until security/support are ready. |
| [Monarch](https://help.monarch.com/hc/en-us/articles/360048393272-Getting-Started-Guide) | Category/flex budgeting, goals, net worth, household collaboration. | Keep `Family` focused on household budget, not social sharing; add simple flex/pace guidance before deeper reporting. |
| [Monarch Investments](https://help.monarch.com/hc/en-us/articles/41855507661076-Investments-in-Monarch) | Portfolio, asset allocation, net worth widgets, manual holdings. | Defer investments; add manual net-worth later only after budgeting retention is healthy. |
| [Copilot Money](https://www.copilot.money) | Automatic categorization, rollovers, cash flow, subscriptions, net worth/investments, no ads. | Prioritize automatic rules, recurring subscriptions/bills, and clean Pro experience before complex investment screens. |
| [PocketGuard](https://pocketguard.com/help/) | Leftover, cash-flow pace, debt payoff, recurring bills/subscriptions, bill negotiation, budget notifications. | Add a simple daily/weekly money pace card; defer bill negotiation and debt payoff until core data quality is strong. |

## Implemented In This Pass

- Added `Ritmo de ahorro` on the Dashboard: a compact daily/weekly spending pace and one recommendation, inspired by PocketGuard Leftover/Pace and Monarch flex budgeting.
- Centralized iOS plan/limit fallback data in `LaunchMonetizationCatalog`.
- Kept the card read-only and simple: no extra forms, no new tab, no new onboarding branch.

## Recommended Next Bets

1. Rollovers: unused budget moves into a future goal bucket, but only after budget categories are stable.
2. Subscription detector: infer recurring merchants from repeated transactions and ask the user to confirm.
3. Debt payoff mini-plan: manual debt entry plus one payoff strategy, not a full loan product at launch.
4. Net worth lite: manual assets/liabilities only, behind Pro, no bank/investment connection until compliance/support are ready.
5. Family digest: weekly household summary email/push for Family admins, not a noisy shared activity feed.
