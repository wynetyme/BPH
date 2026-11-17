# Durable project state

Last verified update: 2026-11-17
Current phase: playable Packvania loop in this repo. Live charges off. Do not publish.
Project status: Night Pack, Moonlit Booster (blocked), courtyard and chapel waves, relics, bestiary, and a Studio courtyard are in source. This GitHub repo previously had no game code. The older local Studio place is not in this commit.
Source-of-truth sync: `default.project.json` (Rojo). Studio was not connected here.

## What plays
- Field: moon courtyard, tower, path, pads, pack pedestal. Camera looks at the tower.
- Earn 30 coins, open the Night Pack (Grave Warden, Moon Bolt, Bat Keeper, Chapel Gargoyle; weights 2/2/1/1).
- Place on lane.back, lane.mid, or lane.front. Battle the Moon Courtyard, then the Chapel Gate.
- Clear once for Mastery, coins, the Chapel Pack, and the next relic. A repeat clear does not pay again.
- Goals, roster, bestiary, relics, Odds / Details, and a cleared/defeated panel.
- Moonlit Booster uses the same weights on 2 slots. Prompts stay off. Product `3732907303`.

## Decisions
- Designed numbers are `UNVERIFIED_DESIGNED`. They are not measured Booster Pack Heroes stats and not demo 60/30/9/1.
- One outcome table feeds rolls and the odds text. Relics do not change odds. Foil is not rolled.
- `ProcessReceipt` is the only grant path. A failed DataStore write is not acknowledged. A stale save keeps a receipt pack.
- The server returns immediately outside Studio.

## Tests actually run
- Command: `lune run tests/run.luau`
- Tool: lune 0.10.1
- Result: **41 passed, 0 failed**
- Studio play: UNTESTED in this environment. No Studio MCP session was available.

## Still missing
- Phone, gamepad, and a restricted-account playtest.
- Measured source-game odds and wave stats.
- Illustrated card art and licensed sound. Faces and the courtyard are original blocks.
- Creator Hub: set product `3732907303` not for sale. It was on sale at 10 Robux in the last Studio check.

## Next exact action
Sync with Rojo and play one courtyard clear in Studio. Leave live charges off. Do not publish.
