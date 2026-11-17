# Durable project state (keep short; update after each Cursor phase)

Last verified update: 2026-11-17
Current phase: 07 release audit. Live charges still off. Do not publish.
Project status: earnable packs, the unverified Robux product, and placeholder combat remain. Two economy holes found in the audit were fixed and retested.
Source-of-truth sync: `default.project.json`. Studio checksums matched disk for ProfileSession 5509/471234, Main 17359/1536246, RunCombat 1902/166316.

## Audit result
Not publishable. `lune run tests/run.luau`: **135 passed, 0 failed**. Studio play on place `140088569290998`, user `225716006`, DataStore `BPH_PlayerData_Studio_v1`.

| Check | Result |
| --- | --- |
| One roll table, basis points sum 10000, display matches it | PASS |
| 20,000-seed legendary run near 50/50 slots and 75% at-least-one | PASS |
| Pity, luck, and ownership filters block instead of changing odds | PASS |
| Odds / Details, 50.00%, no 60.00, foil not rolled | PASS in play |
| Live price from MarketplaceService | PASS. Product `3732907303` "Legendary Booster Pack", 10 Robux |
| In-game prompt | PASS off. Status `LiveChargesDisabled`. Buy button `Live purchase blocked` |
| Forged wave `damage` field | PASS. Status `Combat: InvalidPayload` |
| Restricted player, policy lookup failure | PASS in unit tests. Live restricted account UNTESTED. This account was not restricted |
| Duplicate, absent, locked session, shutdown, failed write, rejoin | PASS in unit tests. Live receipt UNTESTED |
| Stale save cannot delete a committed receipt pack | PASS |
| DataStore error does not acknowledge a memory-only grant | PASS |
| Prompt close is not a grant | PASS in unit tests. No live prompt was opened |
| Cleared wave pays once | PASS. Live replay survived, coins stayed 0, mastery stayed 10 |
| Old save shape gains the new fields | PASS in unit tests |
| Desktop play, FPS 60, server memory about 2001 MB | PASS. That memory is Studio, not a phone |
| Phone viewport, controller, MicroProfiler | UNTESTED this session. 0 gamepads connected |
| Source-game odds | UNTESTED. Tables stay `UNVERIFIED_PLACEHOLDER` |
| Purchase from outside a published server | FAIL. See blockers |

## Blockers
- Creator Hub product `3732907303` is `IsForSale = true` at 10 Robux. A purchase would charge the player. The grant stays `NotProcessedYet` because the pack is unverified, and a published server never installs `ProcessReceipt`.
- `src/server/Main.server.luau` returns immediately unless `RunService:IsStudio()`. A published place has no save and no receipt handler. Leave that guard in place until the manual steps below are done.

## Fixes this phase
- A failed DataStore write is no longer stored in memory and acknowledged.
- A later save keeps a receipt and its unopened pack that the stale session did not know about. A consumed pack stays consumed.
- A failed save rolls the session back and does not tell the client the open succeeded.
- Replaying a cleared wave no longer grants Mastery or coins.

## Save left in Studio
User `225716006`: coins 0, Mastery 10, 4 Bolt, 3 Frontline, 0 unopened packs, 0 receipts. The replay did not change it.

## Manual steps before any publish
1. In Creator Hub, set Developer Product `3732907303` not for sale.
2. Keep `ProductCatalog.liveChargesEnabled` false.
3. Do not remove the Studio-only server guard, and do not put a production DataStore name in the repo, until odds are verified and this table has no FAIL or UNTESTED launch row.
4. Play a PolicyService-restricted account, a gamepad, and a phone viewport. Run one real receipt only after the product is verified and the published handler exists.
5. Fetch the price with MarketplaceService again after any Creator Hub price change.

## Next exact action
Leave live charges off. Take product `3732907303` off sale, then rerun the UNTESTED rows above. Do not replace `CombatTables` without a local capture.
