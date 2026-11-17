---
name: bph-paid-pack-policy
description: Use when adding or auditing Robux-paid booster packs, random reward tables, per-player restrictions, Developer Products, numerical odds disclosures, or purchase receipt reliability for this Roblox project.
---
# Paid pack policy and reliability
Consult `docs/monetization-acceptance.md` and current official Creator Hub pages. The player must see all final item-level percentages before spending, including dynamic modifiers, not merely tier odds. Bundle odds require per-slot disclosures and correctly explained guarantees. `ArePaidRandomItemsRestricted` must gate all paid RNG paths; `IsPaidItemTradingAllowed` is a separate potential concern. Use server-owned roll tables; no client-supplied outcomes. Fulfill developer products ONLY through `ProcessReceipt` with durable idempotent receipt accounting; give durable unopened packs or a safe ledgered award, and consume in an atomic transaction. Never enable purchasing on incomplete odds or placeholder IDs. Test restricted users, forged remotes, repeated receipts, crashes, reconnects and multi-server races. Don't equate Demo v0.33 percentages with verified current-release values.
