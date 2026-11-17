--!strict
-- Paid prompt request. This never grants a pack and never reads a purchase dialog.

local Types = require("../contracts/Types")
local Result = require("../contracts/Result")
local RemoteContract = require("../net/RemoteContract")
local PurchaseEntitlements = require("./PurchaseEntitlements")

local PaidPurchase = {}

function PaidPurchase.request(payload: unknown, policy: Types.PaidPolicy, liveChargesEnabled: boolean): Result.Result<Types.ProductMapping>
	local parsed = RemoteContract.validateRequestPaidPack(payload)
	if not parsed.ok then
		return parsed
	end
	if not policy.known then
		return Result.err("PolicyUnknown")
	end
	if policy.arePaidRandomItemsRestricted then
		return Result.err("PolicyRestricted")
	end
	if liveChargesEnabled ~= true then
		return Result.err("LiveChargesDisabled")
	end
	return PurchaseEntitlements.evaluatePaidPurchase(parsed.value.packId, policy, PurchaseEntitlements.shippingProducts())
end

return PaidPurchase
