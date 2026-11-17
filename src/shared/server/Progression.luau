--!strict
-- Roster, placement, and Mastery ranks. Rewards stay in RunCombat.

local Types = require("../contracts/Types")
local Result = require("../contracts/Result")
local CardDefinitions = require("../data/CardDefinitions")
local CombatTables = require("../data/CombatTables")
local HeroCollection = require("./HeroCollection")
local PackDefinitions = require("../data/PackDefinitions")

local Progression = {}

function Progression.rank(profile: Types.PlayerProfile, cardId: string): number
	return profile.ranks[cardId] or 0
end

function Progression.place(profile: Types.PlayerProfile, cardId: string, anchorId: string): Result.Result<Types.Placement>
	local card = CardDefinitions.get(cardId)
	if card == nil or CombatTables.unit(cardId) == nil then
		return Result.err("UnknownCard")
	end
	if card.kind ~= "Hero" then
		return Result.err("NotAHero")
	end
	if HeroCollection.count(profile, cardId) < 1 then
		return Result.err("NotOwned")
	end
	if CombatTables.anchor(anchorId) == nil then
		return Result.err("UnknownAnchor")
	end
	local kept: { Types.Placement } = {}
	for _, slot in profile.placement do
		if slot.anchorId ~= anchorId and slot.cardId ~= cardId then
			table.insert(kept, slot)
		end
	end
	local slot = { anchorId = anchorId, cardId = cardId }
	table.insert(kept, slot)
	profile.placement = kept
	return Result.ok(slot)
end

function Progression.upgrade(profile: Types.PlayerProfile, cardId: string): Result.Result<number>
	local card = CardDefinitions.get(cardId)
	if card == nil or CombatTables.unit(cardId) == nil then
		return Result.err("UnknownCard")
	end
	if HeroCollection.count(profile, cardId) < 1 then
		return Result.err("NotOwned")
	end
	local rank = Progression.rank(profile, cardId)
	if rank >= CombatTables.maxRank then
		return Result.err("RankCapped")
	end
	if profile.currencies.mastery < CombatTables.upgradeCost then
		return Result.err("InsufficientMastery")
	end
	profile.currencies.mastery -= CombatTables.upgradeCost
	profile.ranks[cardId] = rank + 1
	return Result.ok(rank + 1)
end

function Progression.recordClear(profile: Types.PlayerProfile, waveId: string)
	for _, cleared in profile.clearedWaves do
		if cleared == waveId then
			profile.realmId = CombatTables.clearedRealm()
			profile.unlockedPacks[PackDefinitions.gatePack().id] = true
			return
		end
	end
	table.insert(profile.clearedWaves, waveId)
	profile.realmId = CombatTables.clearedRealm()
	profile.unlockedPacks[PackDefinitions.gatePack().id] = true
end

function Progression.nextWaveId(profile: Types.PlayerProfile): string
	for _, cleared in profile.clearedWaves do
		if cleared == "placeholder.wave.1" then
			return "placeholder.wave.2"
		end
	end
	return "placeholder.wave.1"
end

return Progression
