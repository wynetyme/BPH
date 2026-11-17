--!strict

local Types = require("../contracts/Types")
local Result = require("../contracts/Result")
local CardDefinitions = require("../data/CardDefinitions")
local CombatTables = require("../data/CombatTables")
local PackDefinitions = require("../data/PackDefinitions")
local HeroCollection = require("./HeroCollection")

local Progression = {}

function Progression.place(profile: Types.PlayerProfile, cardId: string, anchorId: string): Result.Result<nil>
	if CardDefinitions.get(cardId) == nil or CombatTables.anchor(anchorId) == nil then
		return Result.err("UnknownCard")
	end
	if HeroCollection.count(profile, cardId) < 1 then
		return Result.err("NotOwned")
	end
	for _, slot in profile.placement do
		if slot.anchorId == anchorId or slot.cardId == cardId then
			return Result.err("AnchorTaken")
		end
	end
	table.insert(profile.placement, { anchorId = anchorId, cardId = cardId })
	return Result.ok(nil)
end

function Progression.upgrade(profile: Types.PlayerProfile, cardId: string): Result.Result<number>
	if CardDefinitions.get(cardId) == nil then
		return Result.err("UnknownCard")
	end
	if HeroCollection.count(profile, cardId) < 1 then
		return Result.err("NotOwned")
	end
	local cost = CombatTables.upgradeCost()
	if profile.currencies.mastery < cost then
		return Result.err("InsufficientMastery")
	end
	local rank = profile.ranks[cardId] or 0
	if rank >= 5 then
		return Result.err("RankCapped")
	end
	profile.currencies.mastery -= cost
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
	for _, relic in CombatTables.relics() do
		if profile.relics[relic.id] ~= true then
			profile.relics[relic.id] = true
			break
		end
	end
end

function Progression.noteBestiary(profile: Types.PlayerProfile, waveId: string)
	local wave = CombatTables.wave(waveId)
	if wave == nil then
		return
	end
	for _, group in wave.groups do
		profile.bestiary[group.enemyId] = true
	end
end

function Progression.toggleRelic(profile: Types.PlayerProfile, relicId: string): Result.Result<nil>
	if profile.relics[relicId] ~= true then
		return Result.err("RelicLocked")
	end
	for index, equipped in profile.equippedRelics do
		if equipped == relicId then
			table.remove(profile.equippedRelics, index)
			return Result.ok(nil)
		end
	end
	if #profile.equippedRelics >= 3 then
		return Result.err("RelicSlotsFull")
	end
	table.insert(profile.equippedRelics, relicId)
	return Result.ok(nil)
end

function Progression.nextWaveId(profile: Types.PlayerProfile): string
	for _, cleared in profile.clearedWaves do
		if cleared == "packvania.wave.courtyard" then
			return "packvania.wave.chapel"
		end
	end
	return "packvania.wave.courtyard"
end

return Progression
