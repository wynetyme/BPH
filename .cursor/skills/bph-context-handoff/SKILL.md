---
name: bph-context-handoff
description: Use after long sessions or between development phases to preserve hard-won decisions and test evidence while saving Cursor and Claude tokens.
---
# Durable context checkpoint
Update `docs/PROJECT_STATE.md` in under ~100 lines. Record verified facts, pending unknowns, acceptance status, exact files changed, tests actually run (pass/fail/unknown, command and key error), and ONE next action. Keep long logs and generated screenshots in referenced files rather than pasting them into context. Do not summarize speculation as a tested fact. Start the next conversation with `prompts/08-new-chat-handoff.txt` and inspect only files relevant to the next step. Let tests and current source code override stale memory.
