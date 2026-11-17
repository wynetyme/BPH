--!strict

local Types = require("../contracts/Types")
local Result = require("../contracts/Result")
local CardDefinitions = require("../data/CardDefinitions")
local RemoteContract = require("../net/RemoteContract")
local Economy = require("./Economy")
local PurchaseEntitlements = require("./PurchaseEntitlements")

export type OpenGrant = {
	cardId: string,
	displayName: string,
	kind: Types.CardKind,
	foil: false,
	provisional: true,
	coins: number,
}

local PackOpen = {}

function PackOpen.interval(): number
	return 1.5
end

local function present(profile: Types.PlayerProfile, rolls: { any }): Result.Result<OpenGrant>
	local cardId = rolls[1].cardId
	local card = CardDefinitions.get(cardId)
	if card == nil then
		return Result.err("UnknownCard")
	end
	return Result.ok({
		cardId = cardId,
		displayName = card.displayName,
		kind = card.kind,
		foil = false,
		provisional = true,
		coins = profile.currencies.coins,
	})
end

function PackOpen.request(profile: Types.PlayerProfile, payload: unknown, playerKey: string, now: number, gate: RemoteContract.RateGate, nextInteger: (number) -> number): Result.Result<OpenGrant>
	local parsed = RemoteContract.validateOpenEarnedPack(payload)
	if not parsed.ok then
		return parsed
	end
	if not gate:allow(playerKey, RemoteContract.names.OpenEarnedPack, now) then
		return Result.err("RateLimited")
	end
	local bought = Economy.buyEarnedPack(profile, parsed.value.packId)
	if not bought.ok then
		return bought
	end
	local opened = PurchaseEntitlements.openEntitlement(profile, bought.value.id, nextInteger)
	if not opened.ok then
		return opened
	end
	return present(profile, opened.value)
end

function PackOpen.openOwned(
	profile: Types.PlayerProfile,
	payload: unknown,
	playerKey: string,
	now: number,
	gate: RemoteContract.RateGate,
	nextInteger: (number) -> number,
	policy: Types.PaidPolicy
): Result.Result<OpenGrant>
	local parsed = RemoteContract.validateOpenEntitlement(payload)
	if not parsed.ok then
		return parsed
	end
	if not gate:allow(playerKey, RemoteContract.names.OpenEntitlement, now) then
		return Result.err("RateLimited")
	end
	local owned = nil
	for _, entitlement in profile.unopenedPacks do
		if entitlement.id == parsed.value.entitlementId then
			owned = entitlement
			break
		end
	end
	if owned ~= nil and owned.source == "Receipt" then
		if not policy.known then
			return Result.err("PolicyUnknown")
		end
		if policy.arePaidRandomItemsRestricted then
			return Result.err("PolicyRestricted")
		end
	end
	local opened = PurchaseEntitlements.openEntitlement(profile, parsed.value.entitlementId, nextInteger)
	if not opened.ok then
		return opened
	end
	return present(profile, opened.value)
end

return PackOpen
