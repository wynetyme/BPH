--!strict
-- Designed Packvania weights. Not demo 60/30/9/1 and not measured release odds.

local Types = require("../contracts/Types")
local CardDefinitions = require("./CardDefinitions")
local Result = require("../contracts/Result")

export type PackDefinition = Types.PackDefinition

local NIGHT: PackDefinition = {
	id = "packvania.night",
	displayName = "Night Pack",
	verification = "UNVERIFIED_PLACEHOLDER",
	slots = 1,
	earnedCost = { status = "UNVERIFIED_PLACEHOLDER", currency = "coins", amount = 10 },
	outcomes = {
		{ cardId = "packvania.warden", weight = 2 },
		{ cardId = "packvania.bolt", weight = 2 },
		{ cardId = "packvania.keeper", weight = 1 },
		{ cardId = "packvania.gargoyle", weight = 1 },
	},
}

-- Same weights, two independent slots. A distinct pack edition.
local MOONLIT: PackDefinition = {
	id = "packvania.moonlit",
	displayName = "Moonlit Booster",
	verification = "UNVERIFIED_PLACEHOLDER",
	slots = 2,
	earnedCost = { status = "UNVERIFIED_PLACEHOLDER", currency = "coins", amount = 1 },
	outcomes = NIGHT.outcomes,
}

local CHAPEL: PackDefinition = {
	id = "packvania.chapel",
	displayName = "Chapel Pack",
	verification = "UNVERIFIED_PLACEHOLDER",
	slots = 1,
	earnedCost = { status = "UNVERIFIED_PLACEHOLDER", currency = "coins", amount = 10 },
	outcomes = NIGHT.outcomes,
}

local byId: { [string]: PackDefinition } = {
	[NIGHT.id] = NIGHT,
	[MOONLIT.id] = MOONLIT,
	[CHAPEL.id] = CHAPEL,
}

local PackDefinitions = {}

function PackDefinitions.list(): { PackDefinition }
	return { NIGHT }
end

function PackDefinitions.paidPack(): PackDefinition
	return MOONLIT
end

function PackDefinitions.gatePack(): PackDefinition
	return CHAPEL
end

function PackDefinitions.get(packId: string): PackDefinition?
	return byId[packId]
end

function PackDefinitions.isInteger(value: number): boolean
	return value == value and math.abs(value) ~= math.huge and value % 1 == 0
end

function PackDefinitions.validate(pack: PackDefinition): Result.Result<PackDefinition>
	if pack.slots < 1 or not PackDefinitions.isInteger(pack.slots) then
		return Result.err("InvalidPack")
	end
	if pack.earnedCost.currency ~= "coins" or not PackDefinitions.isInteger(pack.earnedCost.amount) or pack.earnedCost.amount < 1 then
		return Result.err("InvalidPack")
	end
	if #pack.outcomes < 1 then
		return Result.err("InvalidPack")
	end
	local seen: { [string]: boolean } = {}
	for _, outcome in pack.outcomes do
		if seen[outcome.cardId] or CardDefinitions.get(outcome.cardId) == nil then
			return Result.err("InvalidPack")
		end
		if not PackDefinitions.isInteger(outcome.weight) or outcome.weight < 1 then
			return Result.err("InvalidPack")
		end
		seen[outcome.cardId] = true
	end
	return Result.ok(pack)
end

function PackDefinitions.validateShipping(): Result.Result<{ PackDefinition }>
	local validated = PackDefinitions.validate(NIGHT)
	if not validated.ok then
		return validated
	end
	if NIGHT.verification ~= "UNVERIFIED_PLACEHOLDER" then
		return Result.err("ShippingPackMustStayUnverified")
	end
	return Result.ok({ NIGHT })
end

return PackDefinitions
