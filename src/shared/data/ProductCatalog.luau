--!strict
-- Creator Hub product for Moonlit Booster. No Robux price is stored.
-- liveChargesEnabled stays false until verified odds and launch QA exist.

local Types = require("../contracts/Types")

local MOONLIT: Types.ProductMapping = {
	developerProductId = 3732907303,
	packId = "packvania.moonlit",
	displayName = "Moonlit Booster",
	verification = "UNVERIFIED_PLACEHOLDER",
	paidPurchaseAllowed = false,
}

local ProductCatalog = {}

function ProductCatalog.liveChargesEnabled(): boolean
	return false
end

function ProductCatalog.list(): { Types.ProductMapping }
	return { MOONLIT }
end

function ProductCatalog.configurationGap(): string
	return "Live Robux purchase is blocked until launch QA. Moonlit weights match the Night Pack on 2 independent slots. These are designed weights, not measured release odds. Take product 3732907303 off sale in Creator Hub."
end

return ProductCatalog
