# Booster Pack Heroes — observation and fidelity matrix

Steam release: **2026-11-10**. Unofficial site `boosterpackheroesgame.com` is a **demo v0.33** baseline. Community wiki tables cite playthrough build **v1.0.27D**. This project has **no local capture files** as of 2026-11-17 (`docs/reference-captures/` empty). Full design write-up: `docs/design-spec-reference.md`.

## Evidence tags

`OFFICIAL` · `COMMUNITY_EXTERNAL` · `DEMO_ONLY` · `UNKNOWN` · `LOCAL_REF` (none yet)

Never label DEMO_ONLY or unverified community numbers as shipping paid odds.

## Capture & link log

| ID | Path / URL | Timestamp | Context | Build / date | Confidence |
| --- | --- | --- | --- | --- | --- |
| S1 | https://store.steampowered.com/app/4618570/Booster_Pack_Heroes/ | n/a | Store copy: packs, foil hero example, Mastery, waves, chapter bosses unlock packs/realms | Release page fetched 2026-11-17 | OFFICIAL high |
| S2 | Steam appdetails Chapter 1 complete screenshot (via community citation of store payload) | n/a | Unlocks “Advanced Pack”; one run shows 9 packs, 350 Mastery, 53s, 16 tries | Store imagery; pre/launch marketing | OFFICIAL image; numbers are one frame |
| S3 | https://www.fundaygames.dk/booster-pack-heroes | n/a | Same systems summary; genres auto-battler / incremental / TD | Fetched 2026-11-17 | OFFICIAL high |
| S4 | https://www.fundaygames.dk/bph-support | n/a | Multiple packs/rarities; defend tower; Mastery upgrades; boss unlocks packs | Fetched 2026-11-17 | OFFICIAL high |
| S5 | https://funday-games.itch.io/booster-pack-heroes/devlog/1717236/interloper-demo-update | n/a | Interlopers: small/super-rare chance any pack; full-game hero; chance increases with demo play | Demo update ~Next Fest Oct 2026 | OFFICIAL; % UNKNOWN |
| S6 | https://www.incrementaldb.com/update/2ad06e5d-8ada-44af-b2f5-0ccefb6f3710 | n/a | Foil heroes/tomes; shop resource; revamped shop; improved collection; mobile same price no MTX | Sep 19 2026 demo summary | OFFICIAL paraphrase of demo note |
| D1 | https://www.boosterpackheroesgame.com/packs/ | n/a | Pack index; states only Basic has tooltip % in demo v0.33 | Demo v0.33 DB | DEMO_ONLY |
| D2 | https://www.boosterpackheroesgame.com/packs/basic-pack/ | n/a | 100 Gold, 1 card, +1 Gem claim; 60/30/9/1 Squire/Barbarian/Bowman/wildcard | Demo v0.33 | DEMO_ONLY |
| D3 | https://www.boosterpackheroesgame.com/packs/ (box) | n/a | Basic box 270 Gold, 3 cards, same per-card odds | Demo v0.33 | DEMO_ONLY |
| D4 | Advanced/Blue/Yellow/Red pages on same site | n/a | Pools listed without % | Demo v0.33 community | DEMO_ONLY / low for rates |
| C1 | https://www.youtube.com/watch?v=6Y7l_nVwjB4 | see rows below | FungalBrainRot full playthrough used by community wiki | Claimed v1.0.27D | COMMUNITY_EXTERNAL — not locally re-watched |
| C2 | https://booster-pack-heroes.wiki/packs/pack-drop-rates-and-odds/ | 1:15:16 (`t=4516`) | Basic tooltip: Squire 60 / Barbarian 30 / Ranger 9 / Thunderstorm 1 | v1.0.27D claim | COMMUNITY_EXTERNAL |
| C3 | same + video | 1:36:00 (`t=5760`) | Advanced tooltip: Monk 60 / Knight 30 / Pyromancer 9 / Raise Dead 1 | v1.0.27D claim | COMMUNITY_EXTERNAL |
| C4 | same + video | 2:00:44 (`t=7244`) | Magic tooltip: Witch Doctor 60 / Demon Slayer 30 / Illusionist 9 / Portal 1 | v1.0.27D claim | COMMUNITY_EXTERNAL |
| C5 | same + video | 5:44:02 (`t=20642`) | Royal tooltip: Bannerman 60 / Duelist 30 / Stormcaller 9 / Dragon’s Call 1 | v1.0.27D claim | COMMUNITY_EXTERNAL |
| C6 | https://booster-pack-heroes.wiki/packs/how-to-unlock-nature-pack/ + video | 4:05:17 (`t=14717`) | Nature box: Treant 60 / Raptor 15 / Amazon 15 / Beastmaster 9 / Earthquake 1 | v1.0.27D claim | COMMUNITY_EXTERNAL |
| C7 | Magic unlock page + video | 0:40:35 (`t=2435`) | Chapter 2 clear → Magic Pack access | v1.0.27D claim | COMMUNITY_EXTERNAL |
| C8 | Royal unlock page + video | 1:09:18 (`t=4158`) | Chapter 3 clear → Royal Pack | v1.0.27D claim | COMMUNITY_EXTERNAL |
| C9 | Nature unlock + video | 3:06:28 / 3:05:32 | Act 3 entry / Gate to the Stars; Nature at Chapter 8 entry | v1.0.27D claim | COMMUNITY_EXTERNAL |
| C10 | Mastery guide + video | 0:04:00; 0:08:00; 1:14:53; 1:14:57; 1:09:56; 3:05:32 | Tavern 100 Mastery / 20s Basic; box contents; Foilium; Mastery Interest 25%; act prompts | v1.0.27D claim | COMMUNITY_EXTERNAL |
| C11 | Replay / endless pages + video | 1:28:59; 6:22:45 | Foil boss on chapter replay; end-act preserve prompt | v1.0.27D claim | COMMUNITY_EXTERNAL |
| L0 | `docs/reference-captures/*` | — | Local footage/screenshots | — | **EMPTY** |

## System matrix

| System | Observed or published | Numbers | Source IDs | Confidence / target |
| --- | --- | --- | --- | --- |
| Core loop | Packs → collection → tower defense → Mastery → chapter bosses → new packs/realms | UNKNOWN costs/odds | S1 S3 S4 | Official systems high |
| Pack editions (retail names) | Basic, Advanced, Magic, Royal, Nature claimed in footage; Advanced named on Steam frame | Slot/price UNKNOWN | S2 C2–C6 | Names: mixed; rates: external only |
| Basic pack — DEMO v0.33 | Squire/Barbarian/Bowman/wildcard group | 60/30/9/1; 100 Gold; 1 card; +1 Gem claim | D1 D2 | DEMO_ONLY |
| Basic box — DEMO | 3-card bundle | 270 Gold | D3 | DEMO_ONLY |
| Advanced/Blue/Yellow/Red — DEMO | Different pools | Individual odds UNKNOWN | D4 | DEMO_ONLY pools; rates unknown |
| Retail ordinary pools | Four-column 60/30/9/1 for Basic/Advanced/Magic/Royal; Nature five-way | See C2–C6 | C1–C6 | COMMUNITY_EXTERNAL; verify locally |
| Unlock requirements | Boss/chapter unlocks packs (official). Community: Magic Ch2, Royal Ch3, Nature Ch8 entry | Exact HQ requirements UNKNOWN | S1 S4 C7–C9 | Official rule high; chapter numbers external |
| Wildcard / secret | Demo 1% is a **group** | Final constituents UNKNOWN | D2 | Cannot power paid packs |
| Foil | Official demo chance for foil heroes/tomes; Steam highlights foil hero | Base % UNKNOWN | S1 S6 | Systems known; rates UNKNOWN |
| Interloper | Official: rare any-pack full-game hero; demo chance grows with play | % UNKNOWN | S5 | Systems known; rates UNKNOWN |
| Giant / Foil modifiers | Community Temple +10% Foil, Barracks +10% Giant | Base rates UNKNOWN | community wiki (same C2 page) | External; incomplete for paid |
| Reveal animation | “Rip open” marketing only | Timings UNKNOWN | S1 | Need LOCAL_REF |
| Duplicates | Implied by counts on promo/collection | Protection/convert rules UNKNOWN | S2 | Need LOCAL_REF |
| Collection display | Improved collection (official); Bestiary retained at Act 3 (community) | UI UNKNOWN | S6 C10 | Partial |
| Spell vs hero | Both in pools; tomes/spells upgrade; foil tomes exist | Combat rules UNKNOWN | S1 S6 | Need LOCAL_REF |
| Stats / upgrades | Mastery spends on upgrades/abilities | Per-node costs UNKNOWN | S1 C10 | Need LOCAL_REF |
| Combat | Waves threaten tower; bosses end chapters | Wave/enemy tables UNKNOWN. 2026-11-17 loop uses `CombatTables` `UNVERIFIED_PLACEHOLDER` stats, not source-game numbers. Targeting "first" is a tower-defense default. | S1 S4 | Need LOCAL_REF |
| Mastery | Earned by surviving; spent on power | Thresholds UNKNOWN; Interest 25% community | S1 C10 | Partial |
| Robux paid packs | Roblox extension; same named-pack tables as earnable | Product IDs/prices UNKNOWN | AGENTS / monetization-acceptance | **Blocked** until full final-outcome tables are LOCAL_REF |

## Tiny acceptance tests (audit phase)

| # | Test | Result |
| --- | --- | --- |
| 1 | Local captures exist for current pack tooltips | FAIL — folder empty |
| 2 | Official sources list systems without inventing odds | PASS |
| 3 | Demo odds labeled DEMO_ONLY, not release | PASS |
| 4 | Community launch tables labeled external + timestamps recorded | PASS (via wiki-linked video times) |
| 5 | Paid packs have complete item-level probabilities | FAIL / blocked |
| 6 | Reveal timings measured | FAIL — UNKNOWN |
| 7 | Placeholder loop keeps source combat numbers unknown | PASS — labelled `UNVERIFIED_PLACEHOLDER` |

## Ranked remaining observations

1. Local Basic–Nature tooltip captures with build watermark  
2. Shop prices and single vs box contents  
3. Full open/reveal timing capture  
4. Foil / Giant / Interloper rate or modifier panels  
5. Duplicate + collection/Bestiary UX  
6. Hero vs spell combat + one upgrade purchase  
7. Wave/boss clear + pack unlock screen  
8. Diff pools on builds newer than v1.0.27D  
9. Only then author paid-ready canonical tables  

## MVP acceptance (concise)

See `docs/design-spec-reference.md` § MVP. Short form: earnable pack-open loop + shared canonical table + Mastery combat stub + second pack unlock gate; Robux disabled until item-level odds are locally proven; no invented Nov 2026 weights; original/licensed presentation only.
