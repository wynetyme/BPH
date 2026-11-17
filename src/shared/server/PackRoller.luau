--!strict
-- Same outcome rows as CardOdds. Caller supplies integers in 1..totalWeight.

local Types = require("../contracts/Types")
local Result = require("../contracts/Result")
local CardOdds = require("../data/CardOdds")
local PackDefinitions = require("../data/PackDefinitions")

export type Roll = {
	slot: number,
	cardId: string,
	roll: number,
	totalWeight: number,
}

local PackRoller = {}

function PackRoller.rollPack(pack: Types.PackDefinition, nextInteger: (totalWeight: number) -> number): Result.Result<{ Roll }>
	local validated = PackDefinitions.validate(pack)
	if not validated.ok then
		return validated
	end
	local total = CardOdds.totalWeight(pack)
	local rolls: { Roll } = {}
	for slot = 1, pack.slots do
		local roll = nextInteger(total)
		if roll ~= roll or roll < 1 or roll > total or roll % 1 ~= 0 then
			return Result.err("InvalidRoll")
		end
		local index = CardOdds.pickIndex(pack, roll)
		table.insert(rolls, {
			slot = slot,
			cardId = pack.outcomes[index].cardId,
			roll = roll,
			totalWeight = total,
		})
	end
	return Result.ok(rolls)
end

return PackRoller
