--!strict

local Types = require("../contracts/Types")
local Result = require("../contracts/Result")

export type CardDefinition = Types.CardDefinition

local CARDS: { CardDefinition } = {
	{
		id = "placeholder.frontline",
		kind = "Hero",
		displayName = "Placeholder Frontline",
	},
	{
		id = "placeholder.bolt",
		kind = "Spell",
		displayName = "Placeholder Bolt",
	},
}

local byId: { [string]: CardDefinition } = {}
for _, card in CARDS do
	byId[card.id] = card
end

local CardDefinitions = {}

function CardDefinitions.list(): { CardDefinition }
	return CARDS
end

function CardDefinitions.get(cardId: string): CardDefinition?
	return byId[cardId]
end

function CardDefinitions.requireKnown(cardId: string): Result.Result<CardDefinition>
	local card = byId[cardId]
	if card == nil then
		return Result.err("UnknownCard")
	end
	return Result.ok(card)
end

return CardDefinitions
