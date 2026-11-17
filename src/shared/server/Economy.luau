--!strict
-- Earned-currency purchase creates an unopened entitlement. It does not roll cards.

local Types = require("../contracts/Types")
local Result = require("../contracts/Result")
local PackDefinitions = require("../data/PackDefinitions")
local PlayerData = require("./PlayerData")

local Economy = {}

-- Studio slice only. Not a measured release grant.
local STARTER_COINS = 30

function Economy.starterCoins(): number
	return STARTER_COINS
end

function Economy.applyStarterGrant(profile: Types.PlayerProfile): Result.Result<number>
	if profile.starterGrantApplied then
		return Result.ok(profile.currencies.coins)
	end
	local granted = Economy.grantCoins(profile, STARTER_COINS)
	if not granted.ok then
		return granted
	end
	profile.starterGrantApplied = true
	return granted
end

function Economy.grantCoins(profile: Types.PlayerProfile, amount: number): Result.Result<number>
	if amount ~= amount or math.abs(amount) == math.huge or amount < 1 or amount % 1 ~= 0 then
		return Result.err("InvalidAmount")
	end
	profile.currencies.coins += amount
	return Result.ok(profile.currencies.coins)
end

function Economy.buyEarnedPack(profile: Types.PlayerProfile, packId: string): Result.Result<Types.UnopenedPack>
	local pack = nil
	for _, candidate in PackDefinitions.list() do
		if candidate.id == packId then
			pack = candidate
			break
		end
	end
	local gate = PackDefinitions.gatePack()
	if pack == nil and gate.id == packId and profile.unlockedPacks[packId] == true then
		pack = gate
	end
	if pack == nil then
		return Result.err("UnknownPack")
	end
	local validated = PackDefinitions.validate(pack)
	if not validated.ok then
		return validated
	end
	local cost = pack.earnedCost.amount
	if profile.currencies.coins < cost then
		return Result.err("InsufficientCurrency")
	end
	profile.currencies.coins -= cost
	local entitlement: Types.UnopenedPack = {
		id = PlayerData.issueEntitlementId(profile, "earned"),
		packId = pack.id,
		source = "Earned",
		state = "Unopened",
	}
	table.insert(profile.unopenedPacks, entitlement)
	return Result.ok(entitlement)
end

return Economy
