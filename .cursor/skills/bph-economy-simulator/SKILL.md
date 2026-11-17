---
name: bph-economy-simulator
description: Use for booster pack probabilities, duplicate protection, hero rarity, Mastery upgrades, enemy rewards, inflation, progression balance or softlocks in an incremental tower-defense game.
---
# Reproducible economy verification

Model game balance as pure Luau data and functions. Keep pack pools, weighted rarity, reward amounts, mastery gains, and costs in versioned config. If real reference numbers are unknown, clearly label simulation presets as placeholders. Write a reproducible simulation with explicit seeds across at least 1,000 and preferably 100,000 pulls for rarity distribution and high-variance edge cases. Simulate progression at different player activity levels; detect infinite reward loops, negative balances, impossible unlocks, overly long droughts, and unsafe integer ranges. Keep all economy writes server-authoritative. Report sample sizes, confidence limits and assumptions. Validate any paid random item implementation against Roblox's latest policies.
