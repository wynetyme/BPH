--!strict

local Result = require("../contracts/Result")

export type OpenEarnedPack = { packId: string }
export type OpenEntitlement = { entitlementId: string }
export type RequestPaidPack = { packId: string }

local RemoteContract = {}

RemoteContract.names = {
	OpenEarnedPack = "OpenEarnedPack",
	OpenEntitlement = "OpenEntitlement",
	RequestPaidPack = "RequestPaidPack",
	PlaceHero = "PlaceHero",
	StartWave = "StartWave",
	BuyUpgrade = "BuyUpgrade",
	PackOpened = "PackOpened",
	ProfileSnapshot = "ProfileSnapshot",
}

local function isShortString(value: unknown): boolean
	if type(value) ~= "string" then
		return false
	end
	if utf8.len(value) == nil then
		return false
	end
	return #value >= 1 and #value <= 80
end

local function exactStringField(payload: unknown, field: string): Result.Result<{ [string]: string }>
	if type(payload) ~= "table" then
		return Result.err("InvalidPayload")
	end
	local record = payload :: { [unknown]: unknown }
	for key in record do
		if key ~= field then
			return Result.err("InvalidPayload")
		end
	end
	if not isShortString(record[field]) then
		return Result.err("InvalidPayload")
	end
	return Result.ok({ [field] = record[field] :: string })
end

function RemoteContract.validateOpenEarnedPack(payload: unknown): Result.Result<OpenEarnedPack>
	local parsed = exactStringField(payload, "packId")
	if not parsed.ok then
		return parsed
	end
	return Result.ok({ packId = parsed.value.packId })
end

function RemoteContract.validateOpenEntitlement(payload: unknown): Result.Result<OpenEntitlement>
	local parsed = exactStringField(payload, "entitlementId")
	if not parsed.ok then
		return parsed
	end
	return Result.ok({ entitlementId = parsed.value.entitlementId })
end

local function exactFields(payload: unknown, fields: { string }): Result.Result<{ [string]: string }>
	if type(payload) ~= "table" then
		return Result.err("InvalidPayload")
	end
	local record = payload :: { [unknown]: unknown }
	local seen: { [string]: boolean } = {}
	local count = 0
	for key in record do
		count += 1
		if type(key) ~= "string" then
			return Result.err("InvalidPayload")
		end
		seen[key] = true
	end
	if count ~= #fields then
		return Result.err("InvalidPayload")
	end
	local parsed: { [string]: string } = {}
	for _, field in fields do
		if not seen[field] or not isShortString(record[field]) then
			return Result.err("InvalidPayload")
		end
		parsed[field] = record[field] :: string
	end
	return Result.ok(parsed)
end

function RemoteContract.validatePlaceHero(payload: unknown): Result.Result<{ cardId: string, anchorId: string }>
	local parsed = exactFields(payload, { "anchorId", "cardId" })
	if not parsed.ok then
		return parsed
	end
	return Result.ok({ cardId = parsed.value.cardId, anchorId = parsed.value.anchorId })
end

function RemoteContract.validateStartWave(payload: unknown): Result.Result<{ waveId: string }>
	local parsed = exactFields(payload, { "waveId" })
	if not parsed.ok then
		return parsed
	end
	return Result.ok({ waveId = parsed.value.waveId })
end

function RemoteContract.validateBuyUpgrade(payload: unknown): Result.Result<{ cardId: string }>
	local parsed = exactFields(payload, { "cardId" })
	if not parsed.ok then
		return parsed
	end
	return Result.ok({ cardId = parsed.value.cardId })
end

function RemoteContract.validateRequestPaidPack(payload: unknown): Result.Result<RequestPaidPack>
	local parsed = exactStringField(payload, "packId")
	if not parsed.ok then
		return parsed
	end
	return Result.ok({ packId = parsed.value.packId })
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
