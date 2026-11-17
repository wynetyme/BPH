# Project rules — Booster-pack tower-defense Roblox game

## Mission
A polished, original/authorized Roblox game closely matching the *systems* and *feel* of Booster Pack Heroes: opening booster packs, rarity/foils, heroes/spells, wave defense, upgrades/Mastery, realms/bosses. Keep the opening experience central. Optional Robux-paid packs must exist **in addition to** earnable packs. Do not reuse copyrighted character art, branding, music or proprietary code without permission.

## Source of truth
Read `docs/PROJECT_STATE.md`, `docs/reference-matrix.md` and `docs/monetization-acceptance.md` when relevant. Mark unmeasured source-game values UNKNOWN and demonstration values DEMO_ONLY. Never falsely present demo odds as final-release odds. One canonical pack reward table must drive both server rolls and detailed player-specific odds disclosures.

## Work process & token budget
One scoped feature per task, with acceptance criteria and evidence. At most 2-4 relevant skills per feature, loaded on demand. Inspect existing code before creating anything; prefer built-in engine APIs and existing modules. Keep code simple without sacrificing validation, safety, receipts, tests, accessibility, or maintainability. Read narrow files and log excerpts; avoid repeated full repo dumps. Respond with file paths changed, tests/results, remaining risks, and next step. Update `docs/PROJECT_STATE.md` after each phase or long chat; use new chats with durable handoffs.

## Implementation guardrails
- `--!strict` Luau and typed data-driven modules; source-controlled Roblox code, using one Rojo/Script Sync workflow; Studio MCP for genuine inspection/testing.
- Server solely owns randomness, currency, inventory, card grants, progression, combat and saves. Remote payloads represent intent only, validated and rate-limited.
- Preserve pack behavior: paid vs earned purchase path cannot secretly change odds. If pack composition differs, name/display that distinct pack and clearly show its odds.
- Paid randomized rewards: show each possible final outcome and its actual numerical percentage before any Robux or paid-currency transaction; account for ownership, pity, guarantees, luck modifiers and bundle slots. Respect `PolicyService:GetPolicyInfoForPlayerAsync().ArePaidRandomItemsRestricted` on UI and server; fail closed if eligibility is unknown, but preserve eligible earnable content.
- Developer Products: purchase by MarketplaceService, use `ProcessReceipt` for grants, durable receipt/idempotent entitlement persistence, safe retries and cross-server behavior. No client-trusted purchase completion, no `PromptProductPurchaseFinished` grant.
- For money, inventory and security logic, require deterministic unit tests, negative tests and actual Studio playtests. Never claim tests were executed unless actual evidence exists.
- Do not enable live monetization before manual policy, odds, refund/retry, player eligibility and save-load QA passes.
