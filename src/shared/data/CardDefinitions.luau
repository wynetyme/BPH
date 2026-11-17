--!strict
-- Original Packvania roster. Not Booster Pack Heroes characters.

local Types = require("../contracts/Types")

local CARDS: { Types.CardDefinition } = {
	{ id = "packvania.warden", displayName = "Grave Warden", kind = "Hero", motif = "shield" },
	{ id = "packvania.bolt", displayName = "Moon Bolt", kind = "Spell", motif = "chevron" },
	{ id = "packvania.keeper", displayName = "Bat Keeper", kind = "Hero", motif = "wing" },
	{ id = "packvania.gargoyle", displayName = "Chapel Gargoyle", kind = "Hero", motif = "stone" },
}

local byId: { [string]: Types.CardDefinition } = {}
for _, card in CARDS do
	byId[card.id] = card
end

local CardDefinitions = {}

function CardDefinitions.list(): { Types.CardDefinition }
	return CARDS
end

function CardDefinitions.get(cardId: string): Types.CardDefinition?
	return byId[cardId]
end

return CardDefinitions
