# Durable project state

Last verified update: 2026-11-17
Current phase: Packvania courtyard merged onto local `main` (`97d34bb`). Live charges off. Do not publish.
Project status: Night Pack, Moonlit Booster (blocked), courtyard and chapel waves, relics, bestiary, and a Studio courtyard are the game on `main`. The older placeholder panel is in `legacy/placeholder-panel/` and is not synced. It remains in git history at `183bf50`.
Source-of-truth sync: `default.project.json` (Rojo). Client scripts map to `StarterPlayer.StarterPlayerScripts`. This laptop has no `lune` or `rojo` on PATH. Unit tests were not re-run after the merge.

## What plays
- Field: flat side-view stage. Tower on the left, spawn on the right, lane markers across the middle. Camera is locked level at 8°. A 1° lens drew only sky in Studio. Exact source FOV is UNKNOWN.
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
- On the Packvania branch, before this merge: `lune run tests/run.luau` with lune 0.10.1, **41 passed, 0 failed**.
- After the merge onto this laptop: not re-run. `lune` is not installed here.
- Studio play of this merge: not started. Place `140088569290998` was already in Play on the previously synced source.

## Still missing
- Phone, gamepad, and a restricted-account playtest.
- Measured source-game odds and wave stats.
- Illustrated card art and licensed sound. Faces and the courtyard are original blocks.
- Creator Hub: set product `3732907303` not for sale. It was on sale at 10 Robux in the last Studio check.

## Next exact action
Stop the current Studio play. Serve this folder with Rojo and connect. Delete leftover `ReplicatedStorage.Client` from the old sync, then play one courtyard clear by hand. A new profile uses `Packvania_PlayerData_Studio_v1` and starts with 30 coins. Leave live charges off. Do not publish. This merge is local only until it is pushed.
