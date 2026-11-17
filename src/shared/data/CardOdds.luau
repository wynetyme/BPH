--!strict
-- Display rows and PackRoller both read pack.outcomes. There is no second weight table.

local Types = require("../contracts/Types")
local PackDefinitions = require("./PackDefinitions")
local Result = require("../contracts/Result")

export type OddsRow = {
	cardId: string,
	weight: number,
	totalWeight: number,
	basisPoints: number,
}

export type OddsModifiers = {
	pityCharges: number,
	luckMultiplier: number,
	excludeOwned: boolean,
}

export type PaidDisclosure = {
	status: "Blocked",
	reason: string,
} | {
	status: "Ready",
	rows: { OddsRow },
	slots: number,
	note: "PerSlotIndependent",
}

local CardOdds = {}

function CardOdds.totalWeight(pack: Types.PackDefinition): number
	local total = 0
	for _, outcome in pack.outcomes do
		total += outcome.weight
	end
	return total
end

function CardOdds.pickIndex(pack: Types.PackDefinition, roll: number): number
	local cursor = 0
	for index, outcome in pack.outcomes do
		cursor += outcome.weight
		if roll <= cursor then
			return index
		end
	end
	error("roll out of range")
end

function CardOdds.basisPoints(pack: Types.PackDefinition): { number }
	local total = CardOdds.totalWeight(pack)
	local ranked: { { index: number, frac: number, base: number } } = {}
	local assigned = 0
	for index, outcome in pack.outcomes do
		local exact = (outcome.weight * 10000) / total
		local base = math.floor(exact)
		assigned += base
		table.insert(ranked, { index = index, frac = exact - base, base = base })
	end
	table.sort(ranked, function(a, b)
		if a.frac ~= b.frac then
			return a.frac > b.frac
		end
		return a.index < b.index
	end)
	local remainder = 10000 - assigned
	for step = 1, remainder do
		ranked[step].base += 1
	end
	local points = table.create(#pack.outcomes, 0)
	for _, row in ranked do
		points[row.index] = row.base
	end
	return points
end

function CardOdds.identityModifiers(): OddsModifiers
	return { pityCharges = 0, luckMultiplier = 1, excludeOwned = false }
end

function CardOdds.playerFinalOutcomes(pack: Types.PackDefinition, modifiers: OddsModifiers): Result.Result<{ OddsRow }>
	if modifiers.pityCharges ~= 0 or modifiers.luckMultiplier ~= 1 or modifiers.excludeOwned ~= false then
		return Result.err("ModifierNotConfigured")
	end
	return CardOdds.listFinalOutcomes(pack)
end

function CardOdds.listFinalOutcomes(pack: Types.PackDefinition): Result.Result<{ OddsRow }>
	local validated = PackDefinitions.validate(pack)
	if not validated.ok then
		return validated
	end
	local total = CardOdds.totalWeight(pack)
	local points = CardOdds.basisPoints(pack)
	local rows: { OddsRow } = {}
	for index, outcome in pack.outcomes do
		table.insert(rows, {
			cardId = outcome.cardId,
			weight = outcome.weight,
			totalWeight = total,
			basisPoints = points[index],
		})
	end
	return Result.ok(rows)
end

function CardOdds.sumBasisPoints(rows: { OddsRow }): number
	local sum = 0
	for _, row in rows do
		sum += row.basisPoints
	end
	return sum
end

function CardOdds.listPaidEligibleOutcomes(pack: Types.PackDefinition, paidPurchaseAllowed: boolean): PaidDisclosure
	if pack.verification ~= "VERIFIED" or paidPurchaseAllowed ~= true then
		return { status = "Blocked", reason = "UnverifiedPaidBlocked" }
	end
	local listed = CardOdds.listFinalOutcomes(pack)
	if not listed.ok then
		return { status = "Blocked", reason = listed.code }
	end
	return { status = "Ready", rows = listed.value, slots = pack.slots, note = "PerSlotIndependent" }
end

return CardOdds
