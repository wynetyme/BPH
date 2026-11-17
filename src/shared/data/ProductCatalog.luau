--!strict
-- Creator Hub product id for Legendary Booster Pack. No Robux price is stored.
-- liveChargesEnabled stays false until verified per-card odds and launch QA exist.

local Types = require("../contracts/Types")

local LEGENDARY: Types.ProductMapping = {
	developerProductId = 3732907303,
	packId = "legendary.booster",
	displayName = "Legendary Booster Pack",
	verification = "UNVERIFIED_PLACEHOLDER",
	paidPurchaseAllowed = false,
}

local ProductCatalog = {}

function ProductCatalog.liveChargesEnabled(): boolean
	return false
end

function ProductCatalog.list(): { Types.ProductMapping }
	return { LEGENDARY }
end

function ProductCatalog.configurationGap(): string
	return "Live Robux purchase is blocked until launch QA. Legendary weights are 1 and 1, the same as the free pack, on 2 independent slots. These are designed balance weights, not measured release odds. The 1% wildcard is not a product."
end

return ProductCatalog
