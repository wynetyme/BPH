--!strict
-- The earned starter table is UNVERIFIED_PLACEHOLDER. It is not demo 60/30/9/1 and not release odds.
-- legendary.booster uses the same weights on two slots. That is a designed balance, not measured release odds.

local Types = require("../contracts/Types")
local CardDefinitions = require("./CardDefinitions")
local Result = require("../contracts/Result")

export type PackDefinition = Types.PackDefinition

local EARNED: { PackDefinition } = {
	{
		id = "placeholder.starter",
		displayName = "Placeholder Starter Pack",
		verification = "UNVERIFIED_PLACEHOLDER",
		slots = 1,
		earnedCost = {
			status = "UNVERIFIED_PLACEHOLDER",
			currency = "coins",
			amount = 10,
		},
		outcomes = {
			{ cardId = "placeholder.frontline", weight = 1 },
			{ cardId = "placeholder.bolt", weight = 1 },
		},
	},
}

-- Free pack: 1 slot, weights 1 and 1, expected 0.50 Frontline and 0.50 Bolt.
-- Legendary: those same weights on 2 independent slots, expected 1.00 and 1.00.
local LEGENDARY: PackDefinition = {
	id = "legendary.booster",
	displayName = "Legendary Booster Pack",
	verification = "UNVERIFIED_PLACEHOLDER",
	slots = 2,
	earnedCost = {
		status = "UNVERIFIED_PLACEHOLDER",
		currency = "coins",
		amount = 1,
	},
	outcomes = {
		{ cardId = "placeholder.frontline", weight = 1 },
		{ cardId = "placeholder.bolt", weight = 1 },
	},
}

-- Same weights as the free starter. Locked until a placeholder realm clear. Not a measured pack.
local GATE: PackDefinition = {
	id = "placeholder.gate",
	displayName = "Placeholder Gate Pack",
	verification = "UNVERIFIED_PLACEHOLDER",
	slots = 1,
	earnedCost = {
		status = "UNVERIFIED_PLACEHOLDER",
		currency = "coins",
		amount = 10,
	},
	outcomes = EARNED[1].outcomes,
}

local byId: { [string]: PackDefinition } = {}
for _, pack in EARNED do
	byId[pack.id] = pack
end
byId[LEGENDARY.id] = LEGENDARY
byId[GATE.id] = GATE

local PackDefinitions = {}

function PackDefinitions.list(): { PackDefinition }
	return EARNED
end

function PackDefinitions.paidPack(): PackDefinition
	return LEGENDARY
end

function PackDefinitions.gatePack(): PackDefinition
	return GATE
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
	if pack.earnedCost.currency ~= "coins" then
		return Result.err("InvalidPack")
	end
	if not PackDefinitions.isInteger(pack.earnedCost.amount) or pack.earnedCost.amount < 1 then
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
	for _, pack in EARNED do
		local validated = PackDefinitions.validate(pack)
		if not validated.ok then
			return validated
		end
		if pack.verification ~= "UNVERIFIED_PLACEHOLDER" then
			return Result.err("ShippingPackMustStayUnverified")
		end
	end
	return Result.ok(EARNED)
end

return PackDefinitions
