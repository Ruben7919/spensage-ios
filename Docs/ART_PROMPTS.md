# SpendSage Art Status and Prompt Library

Last updated: 2026-04-05

## Purpose

This document records the shipped core art status plus the prompt direction used to regenerate or extend the art library when needed.

Status:
- 2026-04-04: Matching guide scenes were generated locally from the official mascot sprite library and integrated into the app.
- 2026-04-04: Seasonal sprite packs for Halloween, Holiday, and New Year were generated and wired into runtime asset resolution.
- 2026-04-05: The release icon was rebuilt as a three-mascot peeking composition and the app now ships with core guide, splash, loading, badge, icon, and seasonal art coverage.

Current release-critical art status:
- Core release art is present in the repository and registered in `asset_manifest.json`.
- The current remaining art work is backlog expansion, not missing launch-blocking art.
- Future prompt work should focus on new events, new badge families, or extra mascot poses beyond the shipped pack.

In the current codebase:
- `Ludo` maps to the `mei_*` asset family
- `Tikki` maps to the `tikki_*` asset family
- `Manchas` maps to the `manchas_*` asset family

## Shared Art Direction

- Mobile-first composition with clear negative space for cards and copy overlays
- B2C finance game tone: warm, optimistic, trustworthy, playful but not childish
- Clean teal, mint, cream, and soft graphite palette with a bright premium polish
- Soft rounded shapes, subtle glow accents, low clutter, no desktop dashboard density
- Character should be the focal guide, not a tiny corner sticker
- Avoid realistic banking UI, spreadsheets, or enterprise admin vibes
- Output as high-resolution PNG with transparent-safe edges where possible

## Character Guardrails

- Keep each mascot anatomically consistent with exactly four paws total; never add a duplicate arm, hand, or extra paw to sell emotion
- Preserve transparent backgrounds; no solid white or baked scene background inside character sprite exports
- Use emotion cues like blush, sparkles, yarn, coins, or floating hearts before changing the limb count or silhouette
- Keep each mascot readable as the same character family already used in `Brand/v2/characters`

## Historical Guide Prompt Set

These were the hero prompts used to fill the surfaces that previously relied on placeholders.

## Scene 1: Profile Hero

- Surface: `Profile`
- Character: `Ludo`
- Suggested asset key: `guide_21_profile_identity_ludo`
- Suggested file: `guide_21_profile_identity_ludo_v2.png`

Prompt:

```text
Create a warm profile management hero scene for SpendSage, a mobile-first savings game app. Ludo stands beside a clean identity card panel that suggests personal profile details like full name, household label, and email without looking like a dense settings form. The composition should feel trustworthy, personal, and export-ready, with clear room for UI overlays. Use a bright teal, mint, cream, and soft graphite palette, rounded shapes, soft lighting, and a premium B2C fintech-game tone. Keep the interface elements minimal and mobile-sized. No desktop layout, no spreadsheet energy, no generic corporate support art.
```

## Scene 2: Help Center Hero

- Surface: `Help`
- Character: `Ludo`
- Suggested asset key: `guide_22_help_center_ludo`
- Suggested file: `guide_22_help_center_ludo_v2.png`

Prompt:

```text
Create a mobile help center hero illustration for SpendSage, a playful savings game app. Ludo welcomes the user in a bright, spacious scene with three short FAQ cards and one simple route to support. The mood should feel calm, reassuring, and quick to understand, like a friendly coach helping the user solve one question fast. Use a teal, mint, cream, and soft graphite palette with subtle glow accents and rounded shapes. Keep it uncluttered, mobile-first, and polished. Avoid desktop helpdesk layouts, long documents, or enterprise support visuals.
```

## Scene 3: Rules Automation Hero

- Surface: `Rules`
- Character: `Ludo`
- Suggested asset key: `guide_23_rules_automation_ludo`
- Suggested file: `guide_23_rules_automation_ludo_v2.png`

Prompt:

```text
Create a finance-game automation rules hero scene for SpendSage on mobile. Ludo reviews a small set of merchant chips and clean category tags over a simple glowing control board, showing that repeated expenses can be auto-organized without complexity. The scene should communicate smart automation in a friendly way, not a power-user admin console. Use a bright teal, mint, cream, and graphite palette, soft shadows, rounded UI pieces, and clear negative space for cards and text. Keep it playful, trustworthy, and premium. Avoid dense dashboards, coding metaphors, or enterprise workflow visuals.
```

## Scene 4: Advanced Settings Hero

- Surface: `Advanced`
- Character: `Manchas`
- Suggested asset key: `guide_24_advanced_tools_manchas`
- Suggested file: `guide_24_advanced_tools_manchas_v2.png`

Prompt:

```text
Create an advanced settings hero scene for SpendSage, a mobile-first savings game app. Manchas stands inside a tidy control room with three clear advanced modules representing export, diagnostics, and device tools. The scene should feel more technical than the rest of the app, but still approachable and visually clean for a consumer audience. Use a teal and soft graphite palette with mint highlights, subtle glow, rounded panels, and strong mobile composition. Keep the mood controlled, capable, and trustworthy. Avoid hacker tropes, server rooms, code screens, or enterprise admin clutter.
```

## Integration Notes

1. Add each exported PNG into `SpendSage/Resources/Brand/v2/`.
2. Register the asset keys in `SpendSage/Resources/Brand/v2/asset_manifest.json`.
3. Update `SpendSage/Sources/Core/Brand/BrandStory.swift` to swap each `scenePrompt` placeholder for the new `sceneSource`.

## Remaining Art Backlog

- New event packs beyond Halloween, Holiday, and New Year
- More functional poses such as pointing, holding receipt, family hug, and protect-wallet
- Optional social-share celebration backgrounds for special badge campaigns
