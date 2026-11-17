# Exact copy-and-paste order for Cursor

First extract the ZIP, open the project in Cursor, and run in PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup-cursor-skills.ps1
```

Then restart Cursor; enable official Roblox Studio MCP Quick Connect for Cursor. In Cursor Agent with Claude selected, paste **one prompt per completed phase**, review evidence before next phase. Use AGENTS.md and the docs automatically; DO NOT paste all phases in one agent message.

## 00-verify-environment.txt

```text
Read AGENTS.md and docs/PROJECT_STATE.md, and list only the tools/skills needed for THIS phase. I want a Roblox game with Booster Pack Heroes-style booster opening and optional Robux packs. First verify, don't assume:
1. Which Roblox Studio MCP capabilities actually connect from this Cursor Agent session? Use a harmless read-only Studio inspection and show the result.
2. Whether Rojo or Script Sync is present; if neither exists, propose the least-friction source-controlled setup with exact commands. Do NOT enable two conflicting writers.
3. Whether `--!strict` Luau tooling, Git, Node, Rojo, testing support and installed Cursor skills are working. Report versions/errors, avoid giant logs.
4. Establish folders in source control for shared data, server gameplay/economy, client UI and tests only where needed. Do not code game systems yet.
5. Report PASS/FAIL/UNKNOWN for each connection, exact blockers, and update docs/PROJECT_STATE.md. Fix low-risk local setup issues that are already authorized by the existing installer, but never install unrelated dependencies or modify live monetization.
Use Ponytail's minimal-necessary-solution practice. Avoid repetitive outputs; no giant repo dumps.
```

## 01-reference-audit.txt

```text
Read AGENTS.md, docs/reference-matrix.md, docs/PROJECT_STATE.md. Invoke the reference-audit and context-optimization skills. Build an evidence-based, detailed design specification of Booster Pack Heroes' pack-opening, collection, combat and progression mechanics. Prioritize reference gameplay footage/screenshots I add to the project, plus official developer material; use the unofficial demo v0.33 database as historical evidence only. DO NOT invent November 2026 release values.
Specifically document every known/unknown pack edition, unlocking requirements, per-pack cost (earned currency), number of card slots, distribution, individual item pools, foil/secret handling, reveal animation sequence, possible duplicates, collection display, spell vs hero behavior, stats/upgrades, combat and Mastery.
Document a Robux pack extension for Roblox with the SAME probability tables for the corresponding named pack and optional payment method. Note where FULL individual-outcome probabilities are not known and cannot yet be used for paid packs.
Record exact video timestamps, screenshots and links in docs/reference-matrix.md. Produce a ranked list of remaining observations required, a concise MVP acceptance list, and update docs/PROJECT_STATE.md. Do not implement yet.
```

## 02-architecture.txt

```text
Read AGENTS.md, docs/reference-matrix.md, docs/monetization-acceptance.md, docs/PROJECT_STATE.md. Use relevant Roblox architecture, typed Luau, networking, persistence and tower-defense/card-system skills (at most four).
Design a minimal production-safe architecture with data-driven CardDefinitions, PackDefinitions, CardOdds, PackRoller, HeroCollection, PlayerData, Economy, Run/Combat, PackUI and PurchaseEntitlements. Define service ownership, remotes, typed APIs, error handling, test interfaces and source/Studio sync. Keep server authoritative for all rewards, money and progression. Ensure pack odds are computed from THE SAME canonical tables as reward selection and expose all paid-eligible final outcomes.
Separate free earned-currency packs, optional Robux Developer Products, and unopened durable pack entitlements. Document receipt idempotency and PolicyService gating. Do not hard-code unverified current-release probabilities, product IDs or prices: use explicit placeholders labelled unverified and don't allow live paid purchase on placeholders.
Implement only project structure + deterministic pure Luau data contracts and tests needed for the next phase; prove toolchain and test command works. Update docs/PROJECT_STATE.md with exact modules and evidence.
```

## 03-pack-free-vertical-slice.txt

```text
Implement and VERIFY the first fully playable vertical slice: open one free/earnable Basic-style booster pack from a working responsive Roblox ScreenGui; run its weighted reward roll SERVER-SIDE; show a satisfying card-opening, reveal and optional foil feedback; put the card into an inventory; save, leave and rejoin with card intact. Also show an Odds/Details panel that displays all known individual final outcomes, and explicitly marks any not-yet-verified reference numbers as provisional. No Robux purchase yet.
If historical demo odds are used for prototyping, label `DEMO_ONLY` and use an illustrative local configuration; DO NOT pretend the 1% wildcard group has fully measured constituent odds. Do not launch a paid roll on it.
Include strict Luau types, deterministic seeded pack-roll unit tests, pack-opening rate limits and exploit tests. Use Roblox Studio MCP to inspect/playtest and capture actual Output errors and UI screenshots; don't claim success without evidence. Test persistence/rejoin safely with Studio test data and no real user purchases. Update docs/PROJECT_STATE.md; list exact changed files and test results tersely.
```

## 04-robux-pack-monetization.txt

```text
Implement the OPTIONAL Robux pack architecture as a production-ready feature, but do not enable live charges until manual Creator Hub IDs/prices, full outcome odds and policy QA are complete. Preserve the working free-opening flow and make identical named packs use identical reward tables.
Use Roblox's current official paid random item rules and docs/monetization-acceptance.md as hard acceptance requirements. Build a shop UI with native Robux Developer Products, player-specific pre-purchase odds details listing every final card/spell outcome with numerical percent (not just rarity), any multipack guarantees, pity, luck or ownership modifiers. Odds MUST originate from the exact roll configuration used by the server. If individual 1%-wildcard outcomes or any pack probabilities are unknown, block live paid purchase and expose a clear configuration/test gap; never invent them or claim a launch-ready shop.
Add PolicyService:GetPolicyInfoForPlayerAsync, use ArePaidRandomItemsRestricted for client discovery AND SERVER-SIDE transaction flow; fail closed for paid RNG when policy unknown, preserve earned gameplay. Use a single server-owned MarketplaceService.ProcessReceipt handler; durable atomic receipt ledger and entitlement grants; safe retries; no duplicated or lost packs; grant durable *unopened pack entitlements*, and consume them atomically on a separate server-verified open. Never trust PromptProductPurchaseFinished as proof.
Use TEST/PLACEHOLDER developer product IDs until the Creator Hub IDs are provided; do not silently create real paid products. Test forged remote, restricted user, duplicate receipt, rejoin, network failures, shutdown and multi-server races. Run Studio tests and report evidence and exact remaining manual tasks. Update docs/PROJECT_STATE.md.
```

## 05-combat-progression.txt

```text
Now implement the smallest complete repeatable gameplay loop while preserving tested pack-opening and purchased-pack entitlements: collected hero -> hero roster/placement -> auto-battle vs enemy waves -> tower survival -> earn mastery/free pack resources -> upgrade hero/spell -> unlock more packs and realms. Use observed reference mechanics; put unknowns behind clearly labelled configurable placeholders. Keep stats data-driven; server calculates damage, movement, targeting, rewards and progression. Build deterministic combat and economy simulations for test seeds plus actual Studio playtests. Don't overwrite pack/receipt systems. Log bugs, profiling observations, changed files and remaining unknowns concisely; update docs/PROJECT_STATE.md.
```

## 06-polish-mobile.txt

```text
Polish the game to a high Roblox quality bar without breaking economy, free packs or Robux eligibility: design original consistent card art/UI inspired by the *functional hierarchy* (not a direct asset copy); polished tactile pack rip/open/reveal animation with rare/foil variants; card hover and tap details; fast/reduced-motion option; sound cues; combat impact VFX; readable progress bars; screen scaling and touch/controller interaction. Apply `roblox-ui-maker`, `roblox-vfx`, `game-feel` and/or UI/UX skill selectively. No unreviewed dependencies, stolen art or music. Compare before-and-after Studio screenshots, run playtests with viewport emulation, profile mobile performance and check UI Odds/Details and purchase gating on every device. Write results into docs/PROJECT_STATE.md and avoid wall-of-text reports.
```

## 07-prepublish-qa.txt

```text
Perform a release-blocking audit. Use docs/monetization-acceptance.md as a checklist, no exceptions. Audit actual pack tables vs all displayed odds, every individual final outcome and multi-card interpretation; run long-seed simulations; test paid/random-policy restricted users, policy failures, session reconnects, duplicate receipts, delayed receipts, shutdowns, receipt write failures, ownership constraints, malicious remotes and purchases initiated outside the game. Check how purchased unopened packs are atomically saved and consumed. Ensure paid products remain OFF until manual prices/Product IDs and policy checks are complete. Test desktop/mobile/controller, inventory save migration, performance, combat loop and crash regression. Capture real Roblox Studio MCP/playtest evidence; mark each criterion PASS/FAIL/UNTESTED. Fix high-priority defects, do not claim complete if tests unavailable. Summarize only critical issues, modified files and exact manual publish steps. Update docs/PROJECT_STATE.md.
```

## 08-new-chat-handoff.txt

```text
This is a fresh Cursor Agent conversation for the Booster-Pack Roblox project. Read AGENTS.md, docs/PROJECT_STATE.md, docs/reference-matrix.md and docs/monetization-acceptance.md. Inspect only code files directly relevant to the NEXT ACTION in PROJECT_STATE; confirm tools and tests, do not replay old chats or dump the whole repository. Preserve all existing systems, especially earnable and Robux packs, one authoritative odds engine, individual outcome disclosures, PolicyService restrictions and idempotent receipts. Use Ponytail minimalism without ever omitting safety/tests. State in at most 10 lines what is complete, what is unknown, what you will do next; then perform ONLY the next scoped phase and update PROJECT_STATE with concrete evidence and new next action.
```
