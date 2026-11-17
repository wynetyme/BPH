# Booster Pack Heroes — evidence-based design specification (Phase 01)

Status: documentation only. No gameplay implementation.
Audit date: 2026-11-17.
Local captures present: **none** (`docs/reference-captures/` is empty).

## Evidence classes

| Tag | Meaning |
| --- | --- |
| OFFICIAL | Steam store, Funday pages, Jordy/Funday demo announcements |
| COMMUNITY_EXTERNAL | Third-party wiki / playthrough claims, not yet re-verified from files in this repo |
| DEMO_ONLY | Unofficial demo v0.33 database transcription |
| UNKNOWN | Not evidenced; do not invent |
| LOCAL_REF | Files under `docs/reference-captures/` — currently empty |

Do not treat DEMO_ONLY or COMMUNITY_EXTERNAL numbers as November 2026 release-final values for paid disclosure until locally re-verified on a dated build.

## Core loop (OFFICIAL)

Sources: Steam store app `4618570`; Funday product/support pages.

1. Open booster packs; each pack has its own pool of heroes and spells.
2. Hunt rare cards; Steam short copy highlights foil heroes as a desirable pull.
3. Defend a tower against waves of monsters (auto-battler / incremental tower defense).
4. Survive to earn Mastery; spend Mastery to upgrade heroes/spells and unlock abilities.
5. Defeat each chapter’s boss to unlock new packs, heroes, spells, and challenges.
6. Travel between realms / planes beyond the tower (high-level only; details UNKNOWN).

Official sources publish **no pack prices, slot counts, or numerical odds**.

## Pack editions

### A. Officially named / pictured packs

| Pack / edition | Unlock | Cost (earned) | Slots | Distribution | Confidence |
| --- | --- | --- | --- | --- | --- |
| Multiple unnamed packs | Defeat chapter bosses unlock new packs (OFFICIAL) | UNKNOWN | UNKNOWN | Per-pack pools exist; odds unpublished (OFFICIAL) | High systems, numbers UNKNOWN |
| Advanced Pack | Pictured on Steam Chapter 1 complete screenshot as unlocked reward (OFFICIAL image, one run) | UNKNOWN | UNKNOWN | UNKNOWN | Name confirmed on promo frame only |

Steam Chapter 1 complete frame also shows one pictured run: packs opened 9, Mastery 350, time survived 53s, “COMPLETED IN 16 TRIES.” That is one promotional observation, not an unlock requirement formula.

### B. COMMUNITY_EXTERNAL launch observations (build claimed: v1.0.27D)

Source playthrough: FungalBrainRot, *I Played 100% Of Booster Pack Heroes*, YouTube `https://www.youtube.com/watch?v=6Y7l_nVwjB4`, observed v1.0.27D per community wiki. Timestamps below are those wiki-linked seconds; **not re-watched from local files in this audit**.

| Pack | Unlock (community) | Ordinary identity table (community) | Timestamp | Paid-ready? |
| --- | --- | --- | --- | --- |
| Basic | Early / default (assumed; exact gate UNKNOWN) | Squire 60%, Barbarian 30%, Ranger 9%, Thunderstorm 1% | `t=4516` → 1:15:16 tooltip | NO — missing foil/Giant/Interloper final outcomes; not locally verified |
| Advanced | After Chapter 1 (official picture + community route) | Monk 60%, Knight 30%, Pyromancer 9%, Raise Dead 1% | `t=5760` → 1:36:00 tooltip | NO |
| Magic | After clearing Chapter 2 | Witch Doctor 60%, Demon Slayer 30%, Illusionist 9%, Portal 1% | unlock result `t=2435` → 0:40:35; tooltip `t=7244` → 2:00:44 | NO |
| Royal | After clearing Chapter 3 | Bannerman 60%, Duelist 30%, Stormcaller 9%, Dragon’s Call 1% | unlock `t=4158` → 1:09:18; tooltip `t=20642` → 5:44:02 | NO |
| Nature | Entry Chapter 8 after Act Two | Treant 60%, Raptor 15%, Amazon 15%, Beastmaster 9%, Earthquake 1% (five outcomes) | Act 3 entry `t=11188` → 3:06:28; Nature box `t=14717` → 4:05:17 | NO |

Community notes also claim:

- Basic pack tooltip shows **1 card + 1 Mastery**; Basic box shows **3 packs + 3 Mastery** (`t=480` → 0:08:00 box; Basic single around 1:15:16). Exact Gold/coin prices: UNKNOWN in these citations.
- Pattern of 60/30/9/1 is **not universal** (Nature is five-way).
- No pity timer verified in that footage set.
- Blacksmith can convert an available pack into Royal during battle (separate from campaign unlock). Timing/conditions: UNKNOWN beyond existence claim.
- Later patches exist (e.g. Steam news for 1.0.30D, 1.0.35D). Community tables are pinned to **v1.0.27D** and may be stale.

### C. DEMO_ONLY historical baseline (unofficial demo v0.33 database)

Source: `https://www.boosterpackheroesgame.com/packs/` and `/packs/basic-pack/`.

| Pack | Cost | Slots | Pool / odds | Notes |
| --- | --- | --- | --- | --- |
| Basic Pack | 100 Gold; page also claims +1 Gem | 1 card | Squire 60%, Barbarian 30%, Bowman 9%, Secret/wildcard group 1% | Only demo pack with tooltip-verified percentages per that site |
| Basic Pack Box | 270 Gold | 3 cards | Same 60/30/9/1 per card | 10% savings claim is site text |
| Advanced Pack | Mid-game Gold + Gems (unspecified) | 2 cards | Barbarian, Bowman, Illusionist, Fire Mage, Monk — rates unlisted | Community observation on that site |
| Blue Rare Specialty | Gems + Gold (unspecified) | 2 cards | Illusionist, Fire Mage, Monk, Witch Doctor — rates unlisted | Unlisted weights |
| Yellow / Gold Specialty | Premium Gold + Gems | 2 cards | Witch Doctor, Elf Ranger — rates unlisted | Unlisted weights |
| Red / Crimson | High tier milestones | 3 cards | Unpublished | Site labels unconfirmed |

**Name collisions:** demo “Bowman” vs community retail “Ranger”; demo Advanced pool differs from community Advanced pool. Treat as different baselines, not a merge.

## Wildcard / secret / foil / Giant / Interloper

| Mechanic | What is known | What is unknown | Paid disclosure status |
| --- | --- | --- | --- |
| Demo 1% wildcard group | Demo tooltip shows a 1% bucket that may contain rare heroes/spells (DEMO_ONLY) | Constituent final outcomes and weights | **Blocked** — group odds are not item-level |
| Foil heroes/tomes | Official demo update (Sep 2026): chance to find foil versions of heroes and tomes | Whether foil is separate card vs variant; base rate; stacking; effect on stats | **Blocked** |
| Interlopers | Official itch/Steam Next Fest demo note (Oct 2026): super-rare / small chance on any pack to get a random full-game hero; chance increases the more you play the demo | Exact %, eligible hero list in retail, whether retail still uses “play more increases chance” | **Blocked** |
| Giant | Community: Barracks Efficiency shows Barracks-only +10% Giant modifier | Base Giant rate and final stacking | **Blocked** |
| Foil modifier | Community: Temple Efficiency shows Temple-only +10% Foil modifier | Base foil rate and stacking | **Blocked** |

## Reveal animation sequence

UNKNOWN. Official copy says “rip open booster packs.” No timing chart, input steps, skip rules, or SFX/VFX sequence is evidenced without local footage.

Required future capture: open → peel/flip → rarity telegraph → card settle → duplicate/new badge → collection update.

## Duplicates and collection

| Topic | Evidence | Status |
| --- | --- | --- |
| Duplicates possible | Collection implies repeated pulls; promo party counts show multiple Squire/Barbarian/Ranger | Likely, but conversion/protection rules UNKNOWN |
| Collection screen | Official Sep demo update: “improved collection screen” | Layout/filters/sort UNKNOWN |
| Bestiary | Community Act 3 prompt retains Collection and Bestiary | Existence claimed; UI UNKNOWN |
| Spell vs hero | OFFICIAL: heroes and spells both in packs; spells/tomes upgradeable | Combat roles and upgrade trees UNKNOWN in detail |
| Foil in collection | Foils exist (OFFICIAL); display rules UNKNOWN | |

## Stats, upgrades, Mastery

OFFICIAL:

- Survive → earn Mastery.
- Spend Mastery to upgrade heroes/spells and unlock abilities.
- Boss HP bars were divided to show mastery thresholds in an early demo patch note (thresholds themselves unpublished).

COMMUNITY_EXTERNAL (v1.0.27D footage citations):

| Observation | Timestamp | Confidence for this project |
| --- | --- | --- |
| Currencies treated separately: Coins (shop), Mastery (ordinary upgrades), Foilium (retained tree) | Foilium tree `t=4493` → 1:14:53 | External only |
| Early Tavern: 100 Mastery; produces Basic Pack every 20s (timer later upgrades) | `t=240` → 0:04:00 | External only |
| Mastery Interest: 25% of stored Mastery at start of Improvements; purchase shown as 10 Foilium | `t=4497` → 1:14:57 | External only |
| Begin Act Two prompt exists | `t=4196` → 1:09:56 | External only |
| Begin Act 3 / Gate to the Stars at Chapter 7 Act 2: ordinary skill tree resets; Foilium upgrades, Foilium balance, Collection, Bestiary retained | `t=11132` → 3:05:32 | External only |
| Chapter Select: completed chapters replayable; boss returns in Foil form; quest progress limited to that chapter’s monsters | `t=5339` → 1:28:59 | External only |
| End-of-act completion prompt preserves progress (wording on screen) | `t=22965` → 6:22:45 | External only |

Per-hero stats, exact upgrade costs, and enemy reward tables: UNKNOWN for project use.

## Combat / tower defense

OFFICIAL:

- Monsters march toward the tower; player must defend it.
- Increasingly dangerous waves; chapter bosses gate progression.
- Spells/abilities can be unleashed during survival.

UNKNOWN without local capture: lane/path rules, spawn tables, wave timing, targeting, tower HP values, enemy stats, boss phases, auto-place vs manual place, spell casting UX.

COMMUNITY notes that some upgrades have strict triggers (e.g. kill-triggered or block-triggered abilities). Treat as design risk: upgrades are often conditional, not flat DPS.

## Roblox Robux pack extension (project decision, not source-game feature)

Intent (locked by AGENTS.md / monetization acceptance):

1. Keep a full earnable Gold/Coin path for every named pack the Roblox game ships.
2. Optional Robux Developer Product may purchase the **same named pack entitlement**.
3. Paid and earned paths for the same named pack MUST share one canonical reward table.
4. Before any Robux spend, UI must list every final outcome and its actual percentage for that player (ownership, pity, guarantees, luck, foil/Giant/Interloper if present).
5. Server-only rolls; `ProcessReceipt` grants durable unopened pack entitlement or completed open after durable commit; never grant from client purchase-finished signals.
6. Respect `ArePaidRandomItemsRestricted`; fail closed on unknown policy.

### Current paid-pack readiness

| Named pack | Full item-level table known in this repo? | Foil/Giant/Interloper disaggregated? | Robux OK? |
| --- | --- | --- | --- |
| Any DEMO_ONLY Basic 60/30/9/1 | No — 1% is a group | No | **NO** |
| Any COMMUNITY_EXTERNAL 60/30/9/1 identity tables | Not locally verified; also incomplete as final outcomes | No | **NO** |
| Nature five-way community table | Not locally verified; incomplete modifiers | No | **NO** |

Until a dated local capture proves a complete final-outcome table, Robux packs remain **design-only**. Earnable packs may later use clearly labeled `DEMO_ONLY` or `PLACEHOLDER` configs for vertical-slice prototyping, never presented as shipping paid odds.

## Concise MVP acceptance (documentation → later free slice)

1. Pack opening is a first-class loop: buy/earn → open → reveal → collection update.
2. At least one earnable named pack with a **canonical** server table; UI odds come from that same table.
3. Heroes and at least one spell/tome type exist as distinct card kinds.
4. Simple tower-defense survival loop awards Mastery; Mastery spends on at least one upgrade.
5. Chapter/boss gate unlocks a second pack edition (even if second pack is locked content stub).
6. Robux path is stubbed in design only until full individual-outcome probabilities are measured; paid UI/server remain disabled or fail-closed.
7. No copyrighted source art/names/audio shipped without permission; presentation original/licensed.
8. All UNKNOWN values remain UNKNOWN or explicitly labeled placeholders — never silently filled from demo.

## Ranked remaining observations (do these next)

1. Add local screenshots/clips of **current retail** Basic/Advanced/Magic/Royal/Nature tooltips with build number visible.
2. Capture full pack shop prices (coins/gems), single vs box contents, and any Mastery-on-open grants.
3. Capture one complete pack-open animation with wall-clock timings and skip behavior.
4. Capture foil, Giant, and Interloper reveals **and** any UI that states their rates or modifiers; photograph Temple/Barracks efficiency panels.
5. Capture duplicate pull behavior and collection/Bestiary screens.
6. Capture hero vs spell combat usage and one upgrade purchase showing cost + effect text.
7. Capture wave spawn / tower damage / boss clear and the chapter unlock screen for the next pack.
8. Re-check after patches newer than v1.0.27D (1.0.30D+, 1.0.35D+) whether pools changed.
9. Only then assemble paid-ready tables; until then keep Robux packs blocked.

## Source index (primary)

- Steam: `https://store.steampowered.com/app/4618570/Booster_Pack_Heroes/`
- Funday: `https://www.fundaygames.dk/booster-pack-heroes`, `https://www.fundaygames.dk/bph-support`
- Official Interloper demo note: `https://funday-games.itch.io/booster-pack-heroes/devlog/1717236/interloper-demo-update`
- Sep 2026 foil/collection demo summary (repost): `https://www.incrementaldb.com/update/2ad06e5d-8ada-44af-b2f5-0ccefb6f3710`
- DEMO_ONLY DB: `https://www.boosterpackheroesgame.com/packs/`
- Community matrix: `https://booster-pack-heroes.wiki/packs/pack-drop-rates-and-odds/`
- Community video: `https://www.youtube.com/watch?v=6Y7l_nVwjB4`
