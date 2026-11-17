--!strict

local Types = require("../contracts/Types")
local Result = require("../contracts/Result")
local CardDefinitions = require("../data/CardDefinitions")

local HeroCollection = {}

function HeroCollection.count(profile: Types.PlayerProfile, cardId: string): number
	return profile.collection[cardId] or 0
end

function HeroCollection.grant(profile: Types.PlayerProfile, cardId: string, amount: number): Result.Result<number>
	if CardDefinitions.get(cardId) == nil then
		return Result.err("UnknownCard")
	end
	if amount ~= amount or math.abs(amount) == math.huge or amount < 1 or amount % 1 ~= 0 then
		return Result.err("InvalidAmount")
	end
	local nextCount = HeroCollection.count(profile, cardId) + amount
	profile.collection[cardId] = nextCount
	return Result.ok(nextCount)
end

return HeroCollection
