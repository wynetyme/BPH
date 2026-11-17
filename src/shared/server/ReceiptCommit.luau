--!strict

local Types = require("../contracts/Types")
local Result = require("../contracts/Result")
local PlayerData = require("./PlayerData")
local ProfileSession = require("./ProfileSession")
local PurchaseEntitlements = require("./PurchaseEntitlements")

export type CommitResult = {
	decision: "PurchaseGranted" | "NotProcessedYet",
	reason: string,
	profile: Types.PlayerProfile?,
}

local ReceiptCommit = {}

local function notProcessed(reason: string): CommitResult
	return { decision = "NotProcessedYet", reason = reason, profile = nil }
end

function ReceiptCommit.process(
	store: ProfileSession.Store,
	key: string,
	token: string,
	receipt: Types.Receipt,
	products: { Types.ProductMapping },
	packsById: { [string]: Types.PackDefinition }?,
	now: number,
	playerPresent: boolean
): Result.Result<CommitResult>
	if not playerPresent then
		return Result.ok(notProcessed("PlayerAbsent"))
	end
	local held: CommitResult = notProcessed("StoreFailed")
	local ran = pcall(function()
		store:UpdateAsync(key, function(previous: ProfileSession.Blob?): ProfileSession.Blob?
			if previous == nil then
				held = notProcessed("NoProfile")
				return nil
			end
			local locked = previous.sessionToken ~= "" and previous.sessionToken ~= token
			if locked and now - previous.sessionAt < ProfileSession.staleSeconds() then
				held = notProcessed("SessionLocked")
				return nil
			end
			local profile = PlayerData.clone(previous.profile)
			local applied = PurchaseEntitlements.applyReceipt(profile, receipt, products, packsById)
			if not applied.ok then
				held = notProcessed(applied.code)
				return nil
			end
			if applied.value.decision ~= "PurchaseGranted" then
				held = { decision = "NotProcessedYet", reason = applied.value.reason, profile = nil }
				return nil
			end
			held = { decision = "PurchaseGranted", reason = applied.value.reason, profile = PlayerData.clone(profile) }
			if applied.value.reason == "Duplicate" then
				return nil
			end
			local validated = PlayerData.validate(profile)
			if not validated.ok then
				held = notProcessed(validated.code)
				return nil
			end
			return { sessionToken = token, sessionAt = now, profile = validated.value }
		end)
	end)
	if not ran then
		return Result.ok(notProcessed("StoreFailed"))
	end
	return Result.ok(held)
end

return ReceiptCommit
