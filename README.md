# Booster Pack Heroes-inspired Roblox game: Cursor + Claude v2 starter kit

**Version:** 2026-11-17. **Platform:** Windows PowerShell, Roblox Studio, Cursor using Claude.

Purpose: faithful gameplay reference with an original/authorized presentation, complete pack-opening experience, **free and optional Robux packs**, outcome-level odds disclosures, and a token-conscious agent workflow.

## Exact order

1. Install/update **Cursor**, **Roblox Studio**, **Git**, **Node.js 22.20+**; optionally **Rokit**, **Rojo**, **Wally**, **Selene**, **StyLua**, **Luau LSP**, **Lune**. Open an EMPTY local project folder.
2. Extract **this zip's contents** into that folder; open folder with Cursor. Read/review `AGENTS.md`, `setup-cursor-skills.ps1`, and upstream skill repositories. Third-party agent skills and hooks can execute scripts.
3. In a PowerShell window within the project folder, run:
   `powershell -ExecutionPolicy Bypass -File .\setup-cursor-skills.ps1`
   This installs the selected skills, including **Ponytail's project-level Cursor hooks**. Hooks are scripts: inspect before execution. The script backs up an existing `.cursor/hooks.json` where present. Do not separately copy the Ponytail Cursor rule, to avoid duplicate instruction injection.
4. Restart Cursor. In Roblox Studio enable **Assistant → ... → Manage MCP Servers → Studio as MCP server → Quick connect → Cursor**. Check tool connectivity. Use **Rojo or Script Sync**, not both writing to the same scripts.
5. Open Cursor **Agent** and select a Claude model. Paste the **ENTIRE TEXT** of each file below in order into a **new message**, one phase at a time. **Do not paste all prompts at once**. Review the resulting evidence before moving to the next phase:
   - `prompts/00-verify-environment.txt`
   - `prompts/01-reference-audit.txt`
   - `prompts/02-architecture.txt`
   - `prompts/03-pack-free-vertical-slice.txt`
   - `prompts/04-robux-pack-monetization.txt`
   - `prompts/05-combat-progression.txt`
   - `prompts/06-polish-mobile.txt`
   - `prompts/07-prepublish-qa.txt`
6. For a fresh chat or when context becomes long, use `prompts/08-new-chat-handoff.txt`; the `docs/PROJECT_STATE.md` file is the durable context. Ask the agent to write a precise handoff after each phase and read it at the start of the next. Never let handoffs override current code or tests.

## Short summary of exact requirements
- Keep the reference-style booster-opening loop, different earnable packs and themed pools, card reveals, duplicates, upgrades, rare/foil feedback, heroes, spells, tower-defense runs, Mastery, and realms; **do not omit opening packs**.
- Add optional **Robux purchase options** using Developer Products and Roblox receipt processing, but keep the free progression path. Both purchase modes should reference the **same pack outcome tables** unless the UI clearly identifies an intentionally different pack.
- For any paid randomized outcome, **display every final result and its correct numerical probability before purchase**. Show per-card and, when appropriate, per-pack probabilities. Luck/pity/guarantees/ownership restrictions must be accounted for in dynamic per-player odds. Block restricted paid-item interactions under `PolicyService` in both client UI and server path, with a non-random alternative or accessible earned path when applicable.
- Developer Product purchase fulfillment must be **idempotent** and durably recorded; `ProcessReceipt` cannot acknowledge a receipt before its entitlement has been safely committed. Never grant from `PromptProductPurchaseFinished`.
- Public release should use original or licensed name, cards, character art, music, audio, UI assets, and lore unless permission is granted.

## Skills installed by the script (selected, not everything)
- `TabooHarmony/roblox-brain`: selective architecture, Luau types, networking, security, data, performance, UI, design, monetization, VFX, AI.
- `EL4CTEO/roblox-skills`: additional Roblox testing, code review, Luau and Studio MCP coverage.
- `gamedev-skills/awesome-gamedev-agent-skills`: `tower-defense`, `card-game`, `roblox-simulator-economy`, `game-feel`, `game-ui-ux`.
- `scenario-labs/skills`: specialist Roblox review, performance, tooling.
- `zriptic/roclicks-skills`: Roblox UI maker and VFX (copies only two skills).
- `muratcankoylan/Agent-Skills-for-Context-Engineering`: `context-optimization`, `context-compression`, `filesystem-context`.
- `bm629/agent-skills`: `token-optimization`.
- `DietrichGebert/ponytail`: Cursor project hooks, optimized code workflow. Native Cursor does NOT run all Claude Code `/ponytail-*` command/band features.
- `nextlevelbuilder/ui-ux-pro-max-skill`: optional additional UI design toolkit.
- Included custom skills: `bph-reference-audit`, `bph-economy-simulator`, `bph-studio-qa`, `bph-paid-pack-policy`, `bph-context-handoff`.

## Token conservation and safe context
- **Ponytail**: inspect and reuse first; minimal necessary implementation, never cut tests, security, monetary safety or accessibility. Measured reductions from Claude Code are NOT a promise for Cursor.
- Load only the **2-4 relevant skills** per phase, not every installed skill.
- Read narrow code spans rather than dumping entire files, logs, and Studio hierarchy. Summarize noisy outputs in `docs/PROJECT_STATE.md`.
- Keep `AGENTS.md` short and stable. Put detailed instructions in topical docs and skills.
- Request small diffs and terse change summaries, not repeated 1000-line code pastes.
- Use fresh chats by phase, grounded in project files and tests; do not rely solely on remembered conversation.
- Optional external memory (not auto-installed because it adds hooks/MCP and privacy considerations): `npx claude-mem install --ide cursor`. Check https://github.com/thedotmack/claude-mem first.

## Key authoritative references
- https://create.roblox.com/docs/studio/mcp
- https://create.roblox.com/docs/projects/file-based-workflows
- https://create.roblox.com/docs/production/monetization/paid-random-items
- https://create.roblox.com/docs/production/monetization/developer-products
- https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud-services/data-stores/player-data-purchasing.md
- https://store.steampowered.com/app/4618570/Booster_Pack_Heroes/
- https://www.boosterpackheroesgame.com/packs/ (UNOFFICIAL DEMO BASELINE only)

**Not prevalidated on your Windows machine:** installations, current upstream layout, and local Studio connection. If an installer step fails, inspect the error rather than treating setup as completed.
