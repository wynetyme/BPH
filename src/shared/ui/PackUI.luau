--!strict

local Types = require("../contracts/Types")
local CardOdds = require("../data/CardOdds")
local CardDefinitions = require("../data/CardDefinitions")
local PackDefinitions = require("../data/PackDefinitions")
local PaidGate = require("../data/PaidGate")
local ProductCatalog = require("../data/ProductCatalog")

local PackUI = {}

PackUI.PROVISIONAL_NOTICE = "PROVISIONAL — designed Packvania weights, not verified release odds. Demo 60/30/9/1 is not used. Paid rolls are off."
PackUI.MODIFIER_NOTICE = "No pity, luck, ownership exclusion, or extra guarantee is configured. Relics do not change pack odds. Each percent is that card's chance on one roll."

local function percentLine(row: CardOdds.OddsRow): string
	local found = CardDefinitions.get(row.cardId)
	local name = if found ~= nil then found.displayName else row.cardId
	local kind = if found ~= nil then found.kind .. " - " else ""
	local percent = string.format("%.2f", row.basisPoints / 100)
	return percent .. "% (" .. tostring(row.basisPoints) .. "/10000) " .. kind .. name
end

local function expectedCount(pack: Types.PackDefinition, cardId: string): number
	local total = CardOdds.totalWeight(pack)
	for _, outcome in pack.outcomes do
		if outcome.cardId == cardId then
			return pack.slots * outcome.weight / total
		end
	end
	return 0
end

function PackUI.paidOddsLines(): { string }
	local product = ProductCatalog.list()[1]
	local pack = PackDefinitions.get(product.packId)
	local free = PackDefinitions.get("packvania.night")
	local lines = {
		product.displayName,
		"Developer product " .. tostring(product.developerProductId) .. ".",
		"This pack is separate from the earned Night Pack.",
		"Designed balance: the same card weights as the Night Pack, with 2 slots instead of 1.",
		"This product cannot be traded or gifted.",
	}
	if free ~= nil and pack ~= nil then
		local listed = CardOdds.playerFinalOutcomes(pack, CardOdds.identityModifiers())
		table.insert(lines, PackUI.MODIFIER_NOTICE)
		if listed.ok then
			table.insert(lines, "Slots: " .. tostring(pack.slots) .. ". Each slot rolls this list independently.")
			for _, row in listed.value do
				table.insert(lines, percentLine(row))
				local found = CardDefinitions.get(row.cardId)
				local name = if found ~= nil then found.displayName else row.cardId
				local miss = (10000 - row.basisPoints) / 10000
				local atLeast = (1 - miss ^ pack.slots) * 100
				table.insert(lines, "At least one " .. name .. ": " .. string.format("%.2f", atLeast) .. "%. That is not the per-slot percent.")
				table.insert(lines, "A Night Pack expects " .. string.format("%.2f", expectedCount(free, row.cardId)) .. " " .. name .. ". This pack expects " .. string.format("%.2f", expectedCount(pack, row.cardId)) .. ".")
			end
			table.insert(lines, "Displayed basis points sum to " .. tostring(CardOdds.sumBasisPoints(listed.value)) .. "/10000.")
		end
	end
	table.insert(lines, ProductCatalog.configurationGap())
	table.insert(lines, "Live charges: " .. (if ProductCatalog.liveChargesEnabled() then "ON" else "OFF"))
	return lines
end

function PackUI.shopText(policy: Types.PaidPolicy): string
	local lines = PackUI.paidOddsLines()
	if not policy.known then
		table.insert(lines, "Policy unknown. Paid purchase and paid opening stay off. Earned packs stay available.")
	elseif policy.arePaidRandomItemsRestricted then
		table.insert(lines, "Paid random items are restricted for this account. Earned packs stay available.")
	else
		table.insert(lines, "Policy loaded. A paid prompt stays off until verified odds and launch QA exist.")
	end
	table.insert(lines, "Robux price is read on this device from MarketplaceService. It is not stored in the catalog.")
	return table.concat(lines, "\n")
end

function PackUI.oddsLines(pack: Types.PackDefinition): { string }
	local listed = CardOdds.listFinalOutcomes(pack)
	local lines = { PackUI.PROVISIONAL_NOTICE }
	if not listed.ok then
		table.insert(lines, listed.code)
		return lines
	end
	table.insert(lines, "Per card, one slot. Weights are provisional.")
	for _, row in listed.value do
		local found = CardDefinitions.get(row.cardId)
		local name = if found ~= nil then found.displayName else row.cardId
		local kind = if found ~= nil then found.kind .. " · " else ""
		local percent = string.format("%.2f", row.basisPoints / 100)
		table.insert(lines, percent .. "% " .. kind .. name)
	end
	table.insert(lines, "Foil rate UNKNOWN. This pack does not roll foil.")
	return lines
end

function PackUI.quote(pack: Types.PackDefinition, coins: number, policy: Types.PaidPolicy, product: Types.ProductMapping?)
	local listed = CardOdds.listFinalOutcomes(pack)
	local paid = PaidGate.evaluate(pack, policy, product)
	return {
		earnedPurchaseEnabled = listed.ok and coins >= pack.earnedCost.amount,
		robuxPurchaseEnabled = paid.ok,
		oddsButtonLabel = "Odds / Details" :: "Odds / Details",
	}
end

return PackUI
