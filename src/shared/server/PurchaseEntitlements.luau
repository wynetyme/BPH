--!strict
-- Receipts grant an unopened pack. Opening is a later server step.
-- PromptProductPurchaseFinished is not a receipt.

local Types = require("../contracts/Types")
local Result = require("../contracts/Result")
local PaidGate = require("../data/PaidGate")
local PackDefinitions = require("../data/PackDefinitions")
local ProductCatalog = require("../data/ProductCatalog")
local PlayerData = require("./PlayerData")
local HeroCollection = require("./HeroCollection")
local PackRoller = require("./PackRoller")

export type ReceiptResult = {
	decision: "PurchaseGranted" | "NotProcessedYet",
	reason: string,
	entitlementId: string?,
}

local PurchaseEntitlements = {}

local function findProduct(products: { Types.ProductMapping }, productId: number): Types.ProductMapping?
	for _, product in products do
		if product.developerProductId == productId then
			return product
		end
	end
	return nil
end

function PurchaseEntitlements.shippingProducts(): { Types.ProductMapping }
	return ProductCatalog.list()
end

function PurchaseEntitlements.onPromptFinished(): Result.Result<nil>
	return Result.err("PromptIsNotReceipt")
end

function PurchaseEntitlements.evaluatePaidPurchase(packId: string, policy: Types.PaidPolicy, products: { Types.ProductMapping }): Result.Result<Types.ProductMapping>
	local pack = PackDefinitions.get(packId)
	if pack == nil then
		return Result.err("UnknownPack")
	end
	local product = nil
	for _, candidate in products do
		if candidate.packId == packId then
			product = candidate
			break
		end
	end
	return PaidGate.evaluate(pack, policy, product)
end

function PurchaseEntitlements.applyReceipt(
	profile: Types.PlayerProfile,
	receipt: Types.Receipt,
	products: { Types.ProductMapping },
	packsById: { [string]: Types.PackDefinition }?
): Result.Result<ReceiptResult>
	if #receipt.purchaseId < 1 or #receipt.playerKey < 1 then
		return Result.err("InvalidReceipt")
	end
	local existing = profile.receipts[receipt.purchaseId]
	if existing ~= nil then
		if existing.productId ~= receipt.productId or existing.playerKey ~= receipt.playerKey then
			return Result.err("ReceiptConflict")
		end
		return Result.ok({ decision = "PurchaseGranted", reason = "Duplicate", entitlementId = existing.entitlementId })
	end
	local product = findProduct(products, receipt.productId)
	local pack = nil
	if product ~= nil then
		pack = if packsById ~= nil then packsById[product.packId] else PackDefinitions.get(product.packId)
	end
	if product == nil or pack == nil or product.paidPurchaseAllowed ~= true or product.verification ~= "VERIFIED" or pack.verification ~= "VERIFIED" then
		return Result.ok({ decision = "NotProcessedYet", reason = "UnverifiedProduct", entitlementId = nil })
	end
	local entitlementId = PlayerData.issueEntitlementId(profile, "receipt", receipt.purchaseId)
	profile.receipts[receipt.purchaseId] = {
		purchaseId = receipt.purchaseId,
		productId = receipt.productId,
		playerKey = receipt.playerKey,
		entitlementId = entitlementId,
	}
	table.insert(profile.unopenedPacks, { id = entitlementId, packId = pack.id, source = "Receipt", state = "Unopened" })
	return Result.ok({ decision = "PurchaseGranted", reason = "Granted", entitlementId = entitlementId })
end

function PurchaseEntitlements.openEntitlement(
	profile: Types.PlayerProfile,
	entitlementId: string,
	nextInteger: (number) -> number,
	packsById: { [string]: Types.PackDefinition }?
): Result.Result<{ PackRoller.Roll }>
	local index = nil
	local entitlement = nil
	for i, pack in profile.unopenedPacks do
		if pack.id == entitlementId then
			index = i
			entitlement = pack
			break
		end
	end
	if entitlement == nil or index == nil then
		return Result.err("UnknownEntitlement")
	end
	local pack = if packsById ~= nil then packsById[entitlement.packId] else PackDefinitions.get(entitlement.packId)
	if pack == nil then
		return Result.err("UnknownPack")
	end
	local rolled = PackRoller.rollPack(pack, nextInteger)
	if not rolled.ok then
		return Result.err(rolled.code)
	end
	for _, roll in rolled.value do
		local granted = HeroCollection.grant(profile, roll.cardId, 1)
		if not granted.ok then
			return Result.err(granted.code)
		end
	end
	table.remove(profile.unopenedPacks, index)
	profile.packsOpened += 1
	return Result.ok(rolled.value)
end

return PurchaseEntitlements
