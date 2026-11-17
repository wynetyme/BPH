--!strict
-- View models for the field, quests, collection, bestiary, relics, and result panel.

local Types = require("../contracts/Types")
local CardDefinitions = require("../data/CardDefinitions")
local CombatTables = require("../data/CombatTables")
local PackDefinitions = require("../data/PackDefinitions")
local ProductCatalog = require("../data/ProductCatalog")
local PackUI = require("./PackUI")
local HeroCollection = require("../server/HeroCollection")
local Progression = require("../server/Progression")

export type Quest = { label: string, progress: number, goal: number, done: boolean }
export type CombatReport = {
	waveId: string,
	ticks: number,
	damageDealt: number,
	survived: boolean,
	towerHp: number,
	killed: number,
	leaked: number,
	mastery: number,
	coins: number,
}

local Board = {}

function Board.quests(profile: Types.PlayerProfile): { Quest }
	local wardens = HeroCollection.count(profile, "packvania.warden")
	local opened = profile.packsOpened
	local cleared = false
	for _, waveId in profile.clearedWaves do
		if waveId == "packvania.wave.courtyard" then
			cleared = true
		end
	end
	return {
		{ label = "Recruit Grave Wardens", progress = wardens, goal = 2, done = wardens >= 2 },
		{ label = "Open Night packs", progress = opened, goal = 3, done = opened >= 3 },
		{ label = "Clear the Moon Courtyard", progress = if cleared then 1 else 0, goal = 1, done = cleared },
	}
end

function Board.resultLines(profile: Types.PlayerProfile, report: CombatReport): { string }
	local title = if report.survived then "CLEARED" else "DEFEATED"
	local lines = {
		title,
		"Packvania",
		"Time survived: " .. tostring(report.ticks) .. " ticks",
		"Damage dealt: " .. tostring(report.damageDealt),
		"Packs opened: " .. tostring(profile.packsOpened),
		"Mastery this wave: " .. tostring(report.mastery),
		"Coins this wave: " .. tostring(report.coins),
		"Tower " .. tostring(report.towerHp) .. "/" .. tostring(CombatTables.towerMaxHp()),
		"Killed " .. tostring(report.killed) .. " · Leaked " .. tostring(report.leaked),
	}
	for _, slot in profile.placement do
		local card = CardDefinitions.get(slot.cardId)
		local name = if card ~= nil then card.displayName else slot.cardId
		table.insert(lines, name .. " rank " .. tostring(profile.ranks[slot.cardId] or 0))
	end
	if not report.survived then
		table.insert(lines, "No Mastery and no coins.")
	end
	return lines
end

function Board.snapshot(profile: Types.PlayerProfile, policy: Types.PaidPolicy)
	local pack = PackDefinitions.get("packvania.night")
	local cards = {}
	for _, card in CardDefinitions.list() do
		table.insert(cards, {
			cardId = card.id,
			displayName = card.displayName,
			kind = card.kind,
			motif = card.motif,
			count = HeroCollection.count(profile, card.id),
			rank = profile.ranks[card.id] or 0,
		})
	end
	local relics = {}
	local equippedCount = 0
	for _, relic in CombatTables.relics() do
		local equipped = false
		for _, id in profile.equippedRelics do
			if id == relic.id then
				equipped = true
				equippedCount += 1
			end
		end
		table.insert(relics, {
			id = relic.id,
			displayName = relic.displayName,
			discovered = profile.relics[relic.id] == true,
			equipped = equipped,
		})
	end
	local bestiary = {}
	for _, enemy in CombatTables.enemies() do
		table.insert(bestiary, {
			id = enemy.id,
			displayName = enemy.displayName,
			known = profile.bestiary[enemy.id] == true,
		})
	end
	local product = ProductCatalog.list()[1]
	return {
		title = "Packvania",
		coins = profile.currencies.coins,
		mastery = profile.currencies.mastery,
		realmName = CombatTables.realmName(profile.realmId),
		cards = cards,
		quests = Board.quests(profile),
		relics = relics,
		equippedLabel = "Equipped " .. tostring(equippedCount) .. "/3",
		bestiary = bestiary,
		oddsLines = if pack ~= nil then PackUI.oddsLines(pack) else {},
		shopText = PackUI.shopText(policy),
		paidEnabled = false,
		allowPrompt = false,
		developerProductId = product.developerProductId,
		earnedPackId = "packvania.night",
		gatePackId = PackDefinitions.gatePack().id,
		gateUnlocked = profile.unlockedPacks[PackDefinitions.gatePack().id] == true,
		nextWaveId = Progression.nextWaveId(profile),
		packsOpened = profile.packsOpened,
		notice = PackUI.PROVISIONAL_NOTICE,
		oddsButtonLabel = "Odds / Details",
	}
end

return Board
