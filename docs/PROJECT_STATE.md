# Durable project state

Last verified update: 2026-11-18
Current phase: Placeholder graphics on `main`. Live charges off. Do not publish.
Project status: Night Pack, Moonlit Booster (blocked), courtyard and chapel waves, relics, bestiary, and a side-view stage are the game on `main`. The older placeholder panel is in `legacy/placeholder-panel/` and is not synced. It remains in git history at `183bf50`.
Source-of-truth sync: `default.project.json` (Rojo). Client scripts map to `StarterPlayer.StarterPlayerScripts`. `lune` 0.10.1 is installed through Aftman for this machine.

## What plays
- Field: flat side-view stage. Tower on the left, spawn on the right, lane pads across the middle, a distant chapel, and a Night Pack prop. Camera stays locked level at 8°. A 1° lens drew only sky in Studio. Exact source FOV is UNKNOWN.
- Stage, heroes, enemies, the pack prop, card faces, shot beams, and hit sparks are original PLACEHOLDER art. Source-game illustrations are UNKNOWN. The spark texture is Roblox's built-in sparkle, not a shipped source asset.
- Placed heroes stand on their pads. Combat playback follows the server tick record: enemies move on the same path, shots use the server targets, and reduced motion skips shake, sparks, and the wait. Playback does not grant coins or change damage.
- Earn 30 coins, open the Night Pack (Grave Warden, Moon Bolt, Bat Keeper, Chapel Gargoyle; weights 2/2/1/1).
- Place on lane.back, lane.mid, or lane.front. Battle the Moon Courtyard, then the Chapel Gate.
- Clear once for Mastery, coins, the Chapel Pack, and the next relic. A repeat clear does not pay again.
- Goals, roster, bestiary, relics, Odds / Details, a placeholder card face, and a cleared/defeated panel. The result panel waits until the combat playback finishes.
- Moonlit Booster uses the same weights on 2 slots. Prompts stay off. Product `3732907303`. Odds, receipts, and live-charge behavior were not changed.

## Decisions
- Designed numbers are `UNVERIFIED_DESIGNED`. They are not measured Booster Pack Heroes stats and not demo 60/30/9/1.
- One outcome table feeds rolls and the odds text. Relics do not change odds. Foil is not rolled.
- `ProcessReceipt` is the only grant path. A failed DataStore write is not acknowledged. A stale save keeps a receipt pack.
- The server returns immediately outside Studio.

## Tests actually run
- `lune run tests/run.luau` with lune 0.10.1 on 2026-11-18: **56 passed, 0 failed**. That includes the older pack, receipt, and combat checks plus placeholder art, shake decay, and combat-preview checks.
- Studio play of this graphics pass: NOT TESTED. No Studio session was started from this run.

## Still missing
- Phone, gamepad, and a restricted-account playtest.
- Measured source-game odds, wave stats, camera FOV, and illustrated card art. The current faces are placeholders.
- Licensed sound, custom particle textures, and flipbooks.
- Creator Hub: set product `3732907303` not for sale. It was on sale at 10 Robux in the last Studio check.

## Next exact action
Serve this folder with Rojo and play one courtyard clear in Studio. Confirm the side camera, placeholder silhouettes, pack card, and that reduced motion skips the shake. A new profile uses `Packvania_PlayerData_Studio_v1` and starts with 30 coins. Leave live charges off. Do not publish.

## 2026-11-18 pack reveal handoff
The earned-pack reveal keeps the granted card's StageArt figure in a lit ViewportFrame and stays open until dismissed. The card is labeled PLACEHOLDER, and the foil line says this pack does not roll foil. `lune run tests/run.luau` with lune 0.10.1: 56 passed, 0 failed. Studio visual play of the new stage and reveal: NOT TESTED on this push. A separate check found Packvania in Edit mode after a Rojo build, and that reveal was not played. Next: sync this folder to place `140088569290998` and play one Night Pack open plus one courtyard clear on desktop and phone. Leave live charges off. Do not publish.
