# Architecture (phase 02)

Pure rules live in `src/shared` and are the only code the Lune tests load. Studio entry scripts under `src/server` and `src/client` call those rules. They do not own a second copy of odds, prices, or grants.

## Ownership

| Mutation | Owner | Callers |
| --- | --- | --- |
| Card and pack tables | `shared/data/CardDefinitions`, `PackDefinitions` | Odds, roller, UI quote |
| Displayed odds | `shared/data/CardOdds` | PackUI and paid disclosure |
| Paid prompt allow/deny | `shared/data/PaidGate` | PackUI and server before `PromptProductPurchase` |
| Profile shape | `shared/server/PlayerData` | Server save adapter (not written yet) |
| Coins and earned unopened packs | `shared/server/Economy` | Server remote handler |
| Card counts | `shared/server/HeroCollection` | Server open path |
| Slot rolls | `shared/server/PackRoller` | Server open path |
| Receipt ledger and entitlement consume | `shared/server/PurchaseEntitlements`, `ReceiptCommit` | `MarketplaceService.ProcessReceipt` only |
| Mastery from a run | `shared/server/RunCombat` | Server wave handler |
| Lane stats | `shared/data/CombatTables` | Combat sim and battle copy. Numbers are `UNVERIFIED_PLACEHOLDER`. |
| Damage, movement, targeting | `shared/server/CombatSim` | `RunCombat.fight` |
| Placement, ranks, unlocks | `shared/server/Progression` | Server place and upgrade handlers |
| Screen quote | `shared/ui/PackUI` | Client host. No grants |

The client may read definitions and quotes. It cannot commit coins, cards, mastery, or receipts. Remotes carry intent only.

## Acquisition paths

1. **Earned currency.** `Economy.buyEarnedPack` spends coins and appends an unopened entitlement. It does not roll.
2. **Optional Robux Developer Product.** `ProductCatalog` lists Legendary Booster Pack, developer product `3732907303`, pack id `legendary.booster`. Its weights are `1` and `1`, the same as the free pack, on 2 slots. `liveChargesEnabled()` is false. The Robux price is read with client `GetProductInfoAsync` and is not stored. `ProcessReceipt` grants only a `VERIFIED` product after `UpdateAsync` commits, so this product returns `NotProcessedYet`. `PromptProductPurchaseFinished` does not grant. Receipt packs re-check policy before they roll. The product is not traded or gifted.
3. **Unopened entitlement.** `PurchaseEntitlements.openEntitlement` rolls once, grants cards, then removes the entitlement. The same function opens earned and receipt packs.

Placeholder weights are `1` and `1` on `placeholder.starter`. They are labelled `UNVERIFIED_PLACEHOLDER`. They are not the demo 60/30/9/1 table and not a release table.

`placeholder.gate` is the same weight table, locked until the first placeholder wave survival. Coin purchase still goes through `Economy.buyEarnedPack` and `PackOpen`. It does not change the legendary product or receipt path.

## Combat

The server simulates a fixed lane. Heroes act only from server-accepted placement. Placeholder Bolt auto-casts when owned, because spell placement is UNKNOWN. Targeting is furthest path progress. Survival pays the placeholder Mastery and coin amounts, then unlocks realm `placeholder.gate` and the gate pack. A loss pays nothing. Clients send `PlaceHero`, `StartWave`, and `BuyUpgrade` with no damage or reward fields.

## Canonical odds

`pack.outcomes[].weight` is the only weight list. `CardOdds.listFinalOutcomes` and `CardOdds.pickIndex` both read it. `PackRoller.rollPack` calls `pickIndex`. Basis points use the largest-remainder method and sum to 10000.

`CardOdds.listPaidEligibleOutcomes` returns rows only when `verification == "VERIFIED"` and paid purchase is allowed. Otherwise status is `Blocked` / `UnverifiedPaidBlocked`. A group wildcard is not representable: every outcome is one card id with a positive integer weight.

## Remotes (names only; instances are not created yet)

| Name | Direction | Payload |
| --- | --- | --- |
| `OpenEarnedPack` | client → server | `{ packId: string }` |
| `OpenEntitlement` | client → server | `{ entitlementId: string }` |
| `RequestPaidPack` | client → server | `{ packId: string }` |
| `PlaceHero` | client → server | `{ cardId, anchorId }` |
| `StartWave` | client → server | `{ waveId }` |
| `BuyUpgrade` | client → server | `{ cardId }` |
| `PackOpened` | server → client | server-built roll snapshot |
| `ProfileSnapshot` | server → client | server-built profile snapshot |

`RemoteContract` rejects non-tables, extra keys, and strings that are empty, longer than 80 bytes, or invalid UTF-8. `createRateGate` is a per-player interval. Validation failure is a reject, not a punishment.

`RequestPaidPack` may later call `PromptProductPurchase` only after `PaidGate.evaluate` returns ok. Closing the prompt grants nothing.

## Errors

Results are `{ ok: true, value: T }` or `{ ok: false, code: string }`. Stable codes include `UnknownPack`, `UnknownCard`, `InvalidPack`, `InvalidPayload`, `InsufficientCurrency`, `UnverifiedPaidBlocked`, `PolicyUnknown`, `PolicyRestricted`, `InvalidReceipt`, `ReceiptConflict`, `UnknownEntitlement`, `InvalidRoll`, `RunInactive`.

## Receipts and PolicyService

`applyReceipt` is pure. The future server wrapper must `UpdateAsync` the profile (session-locked) and only then return `PurchaseGranted`. Otherwise return `NotProcessedYet`.

- Same `purchaseId`, product, and player: `PurchaseGranted` / `Duplicate`, no second entitlement.
- Same `purchaseId` with a different player or product: `ReceiptConflict`, no extra grant.
- Unknown or unverified product: `NotProcessedYet`, receipt not stored, so a later configured retry can still grant.
- Grant appends an unopened entitlement. It does not roll.

Policy gating applies to **starting** a paid purchase, not to fulfilling a receipt Roblox already charged.

- `policy.known == false` → `PolicyUnknown` (fail closed).
- `arePaidRandomItemsRestricted == true` → `PolicyRestricted`.
- Placeholder pack or missing product → `UnverifiedPaidBlocked`.

Earned packs stay available in those cases. There is no paid-currency random path.

## Persistence

`PlayerData` version is `1`. `reconcile` fills missing coins, mastery, collection, entitlements, receipts, and `starterGrantApplied`. `validate` rejects NaN, infinity, fractional currency, and a non-boolean starter flag.

`ProfileSession` claims a session token through `UpdateAsync`, writes the profile, and clears the token on leave. A different token is `SessionLocked` for 30 seconds. The Studio store name is `BPH_PlayerData_Studio_v1` and the key is `player_<UserId>`. `Main.server.luau` runs only when `RunService:IsStudio()`. If `UpdateAsync` fails, that play session falls back to memory and warns that the next play session will not keep the card.

`createMemoryStore` is the Lune double. Its rejoin test keeps the granted card and the coins left after the open. The 2026-11-17 Studio stop/start did not, because Studio API access is off (`StudioAccessToApisNotAllowed`). Do not ack a receipt before a durable save succeeds. This slice grants no receipts.

## Tests

`lune run tests/run.luau` from the repo root. Tests cover the shared rules only. `src/server/Main.server.luau` and `src/client/ui/PackUIHost.client.luau` use `game` and are not part of that command.

## Source / Studio sync

`default.project.json` is the only sync map:

- `src/shared` → `ReplicatedStorage.Shared`
- `src/server` → `ServerScriptService.Server`
- `src/client` → `ReplicatedStorage.Client`

`tests/` is not mapped. Do not also Script Sync these folders. Rojo CLI is still not installed, so `rojo serve` and `rojo build` were not run. The open Studio place was filled by setting `Source` for a playtest. Disk files remain the source of truth.
