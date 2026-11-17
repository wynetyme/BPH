--!strict
-- Battle copy. It does not grant cards, coins, or Mastery.

local Types = require("../contracts/Types")
local CardDefinitions = require("../data/CardDefinitions")
local CardOdds = require("../data/CardOdds")
local CombatTables = require("../data/CombatTables")
local PackDefinitions = require("../data/PackDefinitions")

export type CombatSummary = {
	seed: number,
	ticks: number,
	damageDealt: number,
	survived: boolean,
	towerHp: number?,
}

export type Meter = {
	name: string,
	label: string,
	fill: number,
}

local CombatUI = {}

local function nextWaveId(profile: Types.PlayerProfile): string
	for _, cleared in profile.clearedWaves do
		if cleared == "placeholder.wave.1" then
			return "placeholder.wave.2"
		end
	end
	return "placeholder.wave.1"
end

function CombatUI.describe(profile: Types.PlayerProfile, report: CombatSummary?): string
	local lines = {
		"UNVERIFIED_PLACEHOLDER combat. Source-game stats, path, and timing are unknown.",
		"Targeting is first along the path. That is a tower-defense default, not a measured rule.",
		"Realm: " .. CombatTables.realmName(profile.realmId) .. " (" .. profile.realmId .. ").",
		"Mastery: " .. tostring(profile.currencies.mastery) .. ". Coins: " .. tostring(profile.currencies.coins) .. ".",
		"Upgrade cost: " .. tostring(CombatTables.upgradeCost) .. " Mastery. Placeholder amount.",
	}
	local roster = {}
	for _, card in CardDefinitions.list() do
		local count = profile.collection[card.id] or 0
		if count > 0 then
			table.insert(roster, card.displayName .. " x" .. tostring(count) .. " rank " .. tostring(profile.ranks[card.id] or 0))
		end
	end
	table.insert(lines, "Roster: " .. (if #roster > 0 then table.concat(roster, ", ") else "empty"))
	if #profile.placement == 0 then
		table.insert(lines, "Placement: empty. Place a hero before the wave.")
	else
		for _, slot in profile.placement do
			local card = CardDefinitions.get(slot.cardId)
			local name = if card ~= nil then card.displayName else slot.cardId
			table.insert(lines, "Placed " .. name .. " at " .. slot.anchorId .. ".")
		end
	end
	local upcoming = nextWaveId(profile)
	local nextWave = CombatTables.wave(upcoming)
	table.insert(lines, "Next wave: " .. (if nextWave ~= nil then nextWave.displayName else upcoming) .. ".")
	local gate = PackDefinitions.gatePack()
	local odds = CardOdds.listFinalOutcomes(gate)
	if profile.unlockedPacks[gate.id] == true then
		table.insert(lines, gate.displayName .. " is unlocked. It uses the free starter weights. Cost " .. tostring(gate.earnedCost.amount) .. " coins.")
	else
		table.insert(lines, gate.displayName .. " unlocks after the first survival. It uses the free starter weights.")
	end
	if odds.ok then
		for _, row in odds.value do
			local card = CardDefinitions.get(row.cardId)
			local name = if card ~= nil then card.displayName else row.cardId
			table.insert(lines, string.format("%.2f", row.basisPoints / 100) .. "% (" .. tostring(row.basisPoints) .. "/10000) " .. name)
		end
	end
	if report ~= nil then
		table.insert(lines, "Seed " .. tostring(report.seed) .. " ticks " .. tostring(report.ticks) .. " damage " .. tostring(report.damageDealt) .. ".")
		table.insert(lines, if report.survived then "Tower survived." else "Tower fell. No Mastery and no coins.")
	end
	return table.concat(lines, "\n")
end

local function whole(value: number, fallback: number): number
	if value ~= value or value == math.huge or value == -math.huge then
		return fallback
	end
	return math.max(0, math.floor(value))
end

function CombatUI.meters(report: CombatSummary?): { Meter }
	local maxHp = CombatTables.towerMaxHp
	local hp = maxHp
	local ticks = 0
	local damage = 0
	local waveLabel = "No wave yet"
	local waveFill = 0
	if report ~= nil then
		hp = if report.towerHp ~= nil then math.clamp(whole(report.towerHp, maxHp), 0, maxHp) else maxHp
		ticks = whole(report.ticks, 0)
		damage = whole(report.damageDealt, 0)
		if report.survived then
			waveLabel = "Cleared in " .. tostring(ticks) .. " ticks. Damage " .. tostring(damage) .. "."
			waveFill = 1
		else
			waveLabel = "Fell at " .. tostring(ticks) .. " ticks. Damage " .. tostring(damage) .. ". No Mastery and no coins."
			waveFill = math.clamp(ticks / CombatTables.maxTicks, 0, 1)
		end
	end
	return {
		{
			name = "Tower",
			label = "Tower " .. tostring(hp) .. "/" .. tostring(maxHp),
			fill = if maxHp > 0 then hp / maxHp else 0,
		},
		{
			name = "Wave",
			label = waveLabel,
			fill = waveFill,
		},
	}
end

return CombatUI
