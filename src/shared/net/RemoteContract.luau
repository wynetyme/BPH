--!strict

local Result = require("../contracts/Result")

local RemoteContract = {}

RemoteContract.names = {
	OpenEarnedPack = "OpenEarnedPack",
	OpenEntitlement = "OpenEntitlement",
	RequestPaidPack = "RequestPaidPack",
	PlaceHero = "PlaceHero",
	StartWave = "StartWave",
	BuyUpgrade = "BuyUpgrade",
	ToggleRelic = "ToggleRelic",
}

local function isShortString(value: unknown): boolean
	return type(value) == "string" and #value >= 1 and #value <= 80
end

local function exactFields(payload: unknown, fields: { string }): Result.Result<{ [string]: string }>
	if type(payload) ~= "table" then
		return Result.err("InvalidPayload")
	end
	local record = payload :: { [unknown]: unknown }
	local count = 0
	for key in record do
		count += 1
		if type(key) ~= "string" then
			return Result.err("InvalidPayload")
		end
	end
	if count ~= #fields then
		return Result.err("InvalidPayload")
	end
	local parsed: { [string]: string } = {}
	for _, field in fields do
		if not isShortString(record[field]) then
			return Result.err("InvalidPayload")
		end
		parsed[field] = record[field] :: string
	end
	return Result.ok(parsed)
end

function RemoteContract.validateOpenEarnedPack(payload: unknown)
	local parsed = exactFields(payload, { "packId" })
	if not parsed.ok then
		return parsed
	end
	return Result.ok({ packId = parsed.value.packId })
end

function RemoteContract.validateOpenEntitlement(payload: unknown)
	local parsed = exactFields(payload, { "entitlementId" })
	if not parsed.ok then
		return parsed
	end
	return Result.ok({ entitlementId = parsed.value.entitlementId })
end

function RemoteContract.validateRequestPaidPack(payload: unknown)
	local parsed = exactFields(payload, { "packId" })
	if not parsed.ok then
		return parsed
	end
	return Result.ok({ packId = parsed.value.packId })
end

function RemoteContract.validatePlaceHero(payload: unknown)
	local parsed = exactFields(payload, { "anchorId", "cardId" })
	if not parsed.ok then
		return parsed
	end
	return Result.ok({ cardId = parsed.value.cardId, anchorId = parsed.value.anchorId })
end

function RemoteContract.validateStartWave(payload: unknown)
	local parsed = exactFields(payload, { "waveId" })
	if not parsed.ok then
		return parsed
	end
	return Result.ok({ waveId = parsed.value.waveId })
end

function RemoteContract.validateBuyUpgrade(payload: unknown)
	local parsed = exactFields(payload, { "cardId" })
	if not parsed.ok then
		return parsed
	end
	return Result.ok({ cardId = parsed.value.cardId })
end

function RemoteContract.validateToggleRelic(payload: unknown)
	local parsed = exactFields(payload, { "relicId" })
	if not parsed.ok then
		return parsed
	end
	return Result.ok({ relicId = parsed.value.relicId })
end

export type RateGate = {
	allow: (self: RateGate, playerKey: string, action: string, now: number) -> boolean,
}

function RemoteContract.createRateGate(minInterval: number): RateGate
	local last: { [string]: number } = {}
	local gate = {} :: RateGate
	function gate:allow(playerKey: string, action: string, now: number): boolean
		if now ~= now or math.abs(now) == math.huge then
			return false
		end
		local key = playerKey .. "\0" .. action
		local previous = last[key]
		if previous ~= nil and now - previous < minInterval then
			return false
		end
		last[key] = now
		return true
	end
	return gate
end

return RemoteContract
