--!strict
-- Session lock around a serialized profile. No DataStore calls.

local Types = require("../contracts/Types")
local Result = require("../contracts/Result")
local PlayerData = require("./PlayerData")
local Economy = require("./Economy")

export type Blob = {
	sessionToken: string,
	sessionAt: number,
	profile: Types.PlayerProfile,
}

export type Store = {
	UpdateAsync: (self: Store, key: string, transform: (Blob?) -> Blob?) -> Blob?,
	GetAsync: (self: Store, key: string) -> Blob?,
}

local ProfileSession = {}

local STALE_SECONDS = 30

function ProfileSession.staleSeconds(): number
	return STALE_SECONDS
end

function ProfileSession.studioStoreName(): string
	return "BPH_PlayerData_Studio_v1"
end

function ProfileSession.playerKey(userId: number): string
	return "player_" .. tostring(userId)
end

function ProfileSession.claim(previous: Blob?, token: string, now: number): Result.Result<Blob>
	if previous ~= nil and previous.sessionToken ~= "" and previous.sessionToken ~= token then
		if now - previous.sessionAt < STALE_SECONDS then
			return Result.err("SessionLocked")
		end
	end
	local profile = PlayerData.createDefault()
	if previous ~= nil then
		local reconciled = PlayerData.reconcile(previous.profile :: { [string]: unknown })
		if reconciled.ok then
			profile = reconciled.value
		end
	end
	Economy.applyStarterGrant(profile)
	return Result.ok({
		sessionToken = token,
		sessionAt = now,
		profile = profile,
	})
end

function ProfileSession.write(blob: Blob, token: string, profile: Types.PlayerProfile, now: number): Result.Result<Blob>
	if blob.sessionToken ~= token then
		return Result.err("SessionMismatch")
	end
	-- A stale session must not delete a receipt the store already committed.
	local merged = PlayerData.clone(profile)
	for purchaseId, record in blob.profile.receipts do
		if merged.receipts[purchaseId] == nil then
			merged.receipts[purchaseId] = {
				purchaseId = record.purchaseId,
				productId = record.productId,
				playerKey = record.playerKey,
				entitlementId = record.entitlementId,
			}
			for _, pack in blob.profile.unopenedPacks do
				if pack.id == record.entitlementId then
					local present = false
					for _, held in merged.unopenedPacks do
						if held.id == pack.id then
							present = true
							break
						end
					end
					if not present then
						table.insert(merged.unopenedPacks, {
							id = pack.id,
							packId = pack.packId,
							source = pack.source,
							state = pack.state,
						})
					end
				end
			end
		end
	end
	local validated = PlayerData.validate(merged)
	if not validated.ok then
		return validated
	end
	return Result.ok({
		sessionToken = token,
		sessionAt = now,
		profile = PlayerData.clone(validated.value),
	})
end

function ProfileSession.release(blob: Blob, token: string, profile: Types.PlayerProfile, now: number): Result.Result<Blob>
	local written = ProfileSession.write(blob, token, profile, now)
	if not written.ok then
		return written
	end
	written.value.sessionToken = ""
	return written
end

local function runUpdate(store: Store, key: string, transform: (Blob?) -> Blob?): (boolean, Result.Result<Blob>)
	local held: Result.Result<Blob> = Result.err("StoreFailed")
	local ok = pcall(function()
		store:UpdateAsync(key, function(previous: Blob?): Blob?
			local step = transform(previous)
			if step == nil then
				return previous
			end
			held = Result.ok(step)
			return step
		end)
	end)
	if not ok then
		return false, Result.err("StoreFailed")
	end
	return true, held
end

function ProfileSession.load(store: Store, key: string, token: string, now: number): Result.Result<Types.PlayerProfile>
	local ran, held = runUpdate(store, key, function(previous: Blob?): Blob?
		local claimed = ProfileSession.claim(previous, token, now)
		if not claimed.ok then
			return nil
		end
		return claimed.value
	end)
	if not ran then
		return Result.err("StoreFailed")
	end
	if not held.ok then
		return Result.err("SessionLocked")
	end
	return Result.ok(PlayerData.clone(held.value.profile))
end

function ProfileSession.save(store: Store, key: string, token: string, profile: Types.PlayerProfile, now: number, releaseLock: boolean): Result.Result<Types.PlayerProfile>
	local ran, held = runUpdate(store, key, function(previous: Blob?): Blob?
		local base = previous
		if base == nil then
			base = { sessionToken = token, sessionAt = now, profile = profile }
		end
		local written = if releaseLock
			then ProfileSession.release(base, token, profile, now)
			else ProfileSession.write(base, token, profile, now)
		if not written.ok then
			return nil
		end
		return written.value
	end)
	if not ran or not held.ok then
		return Result.err("StoreFailed")
	end
	return Result.ok(PlayerData.clone(held.value.profile))
end

function ProfileSession.callStore(primary: Store?, fallback: Store, key: string, transform: (Blob?) -> Blob?): (boolean, Blob?)
	local store = if primary ~= nil then primary else fallback
	local ok, result = pcall(function()
		return store:UpdateAsync(key, transform)
	end)
	if not ok then
		return false, nil
	end
	return true, result
end

function ProfileSession.createMemoryStore(): Store
	local rows: { [string]: Blob } = {}
	local store = {} :: Store
	function store:UpdateAsync(key: string, transform: (Blob?) -> Blob?): Blob?
		local nextBlob = transform(rows[key])
		if nextBlob ~= nil then
			rows[key] = nextBlob
		end
		return rows[key]
	end
	function store:GetAsync(key: string): Blob?
		return rows[key]
	end
	return store
end

return ProfileSession
