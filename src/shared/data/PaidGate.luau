--!strict

local Types = require("../contracts/Types")
local Result = require("../contracts/Result")

local PaidGate = {}

function PaidGate.evaluate(pack: Types.PackDefinition, policy: Types.PaidPolicy, product: Types.ProductMapping?): Result.Result<Types.ProductMapping>
	if pack.verification ~= "VERIFIED" or product == nil then
		return Result.err("UnverifiedPaidBlocked")
	end
	if product.paidPurchaseAllowed ~= true or product.verification ~= "VERIFIED" or product.packId ~= pack.id then
		return Result.err("UnverifiedPaidBlocked")
	end
	if product.developerProductId < 1 or product.developerProductId % 1 ~= 0 then
		return Result.err("UnverifiedPaidBlocked")
	end
	if not policy.known then
		return Result.err("PolicyUnknown")
	end
	if policy.arePaidRandomItemsRestricted then
		return Result.err("PolicyRestricted")
	end
	return Result.ok(product)
end

return PaidGate
