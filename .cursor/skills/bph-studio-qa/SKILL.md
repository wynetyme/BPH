---
name: bph-studio-qa
description: Use after modifying Roblox tower-defense combat, card reveal interfaces, Mastery upgrades, persistence, or performance. Requires concrete Studio MCP playtest evidence before declaring work finished.
---
# Studio verification gate

Use the official built-in Roblox Studio MCP server, target the correct Studio session, inspect the DataModel and current play mode, start an actual playtest, and read console output. Test a full loop: open pack -> reward grant -> equip/activate effect -> survive or fail wave -> earn and spend mastery -> save and rejoin. Simulate inputs when possible and capture screenshots of UI states. Explicitly check mobile safe area, text clipping, buttons, card reveal timing, and skip behavior; check controller focus if supported. For multiplayer/shared servers, verify client-initiated reward and damage requests cannot bypass authority. If a tool or test is unavailable, report NOT TESTED, never PASS. Record the run, console errors, evidence, changes, and next blocker.
