--!strict
-- Serializable profile. Versioned template, no DataStore calls.
-- Future server adapter: UpdateAsync + session lock. Keys must contain the user id.

local Types = require("../contracts/Types")
local Result = require("../contracts/Result")

local PROFILE_VERSION = 1

local PlayerData = {}

local function isSafeInteger(value: unknown): boolean
	if type(value) ~= "number" then
		return false
	end
	local n = value :: number
	return n == n and math.abs(n) ~= math.huge and n % 1 == 0 and n >= 0
end

local function copyProfile(profile: Types.PlayerProfile): Types.PlayerProfile
	local collection: { [string]: number } = {}
	for cardId, count in profile.collection do
		collection[cardId] = count
	end
	local unopened: { Types.UnopenedPack } = {}
	for _, pack in profile.unopenedPacks do
		table.insert(unopened, {
			id = pack.id,
			packId = pack.packId,
			source = pack.source,
			state = pack.state,
		})
	end
	local receipts: { [string]: Types.ReceiptRecord } = {}
	for purchaseId, record in profile.receipts do
		receipts[purchaseId] = {
			purchaseId = record.purchaseId,
			productId = record.productId,
			playerKey = record.playerKey,
			entitlementId = record.entitlementId,
		}
	end
	local ranks: { [string]: number } = {}
	for cardId, rank in profile.ranks do
		ranks[cardId] = rank
	end
	local placement: { Types.Placement } = {}
	for _, slot in profile.placement do
		table.insert(placement, { anchorId = slot.anchorId, cardId = slot.cardId })
	end
	local cleared: { string } = {}
	for _, waveId in profile.clearedWaves do
		table.insert(cleared, waveId)
	end
	local unlocked: { [string]: boolean } = {}
	for packId, open in profile.unlockedPacks do
		unlocked[packId] = open
	end
	return {
		version = profile.version,
		currencies = {
			coins = profile.currencies.coins,
			mastery = profile.currencies.mastery,
		},
		collection = collection,
		unopenedPacks = unopened,
		receipts = receipts,
		nextEntitlementNonce = profile.nextEntitlementNonce,
		starterGrantApplied = profile.starterGrantApplied,
		ranks = ranks,
		placement = placement,
		realmId = profile.realmId,
		clearedWaves = cleared,
		unlockedPacks = unlocked,
	}
end

function PlayerData.createDefault(): Types.PlayerProfile
	return {
		version = PROFILE_VERSION,
		currencies = { coins = 0, mastery = 0 },
		collection = {},
		unopenedPacks = {},
		receipts = {},
		nextEntitlementNonce = 1,
		starterGrantApplied = false,
		ranks = {},
		placement = {},
		realmId = "placeholder.tower",
		clearedWaves = {},
		unlockedPacks = {},
	}
end

function PlayerData.clone(profile: Types.PlayerProfile): Types.PlayerProfile
	return copyProfile(profile)
end

function PlayerData.issueEntitlementId(profile: Types.PlayerProfile, source: "earned" | "receipt", purchaseId: string?): string
	if source == "receipt" then
		return "receipt:" .. (purchaseId or "")
	end
	local id = "earned:" .. tostring(profile.nextEntitlementNonce)
	profile.nextEntitlementNonce += 1
	return id
end

function PlayerData.validate(profile: Types.PlayerProfile): Result.Result<Types.PlayerProfile>
	if profile.version ~= PROFILE_VERSION then
		return Result.err("UnsupportedProfileVersion")
	end
	if not isSafeInteger(profile.currencies.coins) or not isSafeInteger(profile.currencies.mastery) then
		return Result.err("InvalidProfile")
	end
	if not isSafeInteger(profile.nextEntitlementNonce) or profile.nextEntitlementNonce < 1 then
		return Result.err("InvalidProfile")
	end
	if type(profile.starterGrantApplied) ~= "boolean" then
		return Result.err("InvalidProfile")
	end
	if type(profile.realmId) ~= "string" or utf8.len(profile.realmId) == nil or #profile.realmId < 1 or #profile.realmId > 80 then
		return Result.err("InvalidProfile")
	end
	for cardId, rank in profile.ranks do
		if utf8.len(cardId) == nil or not isSafeInteger(rank) or rank > 20 then
			return Result.err("InvalidProfile")
		end
	end
	local seenAnchor: { [string]: boolean } = {}
	local seenCard: { [string]: boolean } = {}
	for _, slot in profile.placement do
		if utf8.len(slot.anchorId) == nil or utf8.len(slot.cardId) == nil or seenAnchor[slot.anchorId] or seenCard[slot.cardId] then
			return Result.err("InvalidProfile")
		end
		seenAnchor[slot.anchorId] = true
		seenCard[slot.cardId] = true
	end
	for _, waveId in profile.clearedWaves do
		if utf8.len(waveId) == nil or #waveId < 1 then
			return Result.err("InvalidProfile")
		end
	end
	for packId, open in profile.unlockedPacks do
		if utf8.len(packId) == nil or open ~= true then
			return Result.err("InvalidProfile")
		end
	end
	for cardId, count in profile.collection do
		if utf8.len(cardId) == nil or not isSafeInteger(count) then
			return Result.err("InvalidProfile")
		end
	end
	for _, pack in profile.unopenedPacks do
		if pack.state ~= "Unopened" or (pack.source ~= "Earned" and pack.source ~= "Receipt") then
			return Result.err("InvalidProfile")
		end
		if utf8.len(pack.id) == nil or #pack.id < 1 then
			return Result.err("InvalidProfile")
		end
	end
	return Result.ok(profile)
end

function PlayerData.reconcile(saved: { [string]: unknown }?): Result.Result<Types.PlayerProfile>
	local profile = PlayerData.createDefault()
	if saved == nil then
		return Result.ok(profile)
	end
	if type(saved) ~= "table" then
		return Result.err("InvalidProfile")
	end
	local currencies = saved.currencies
	if type(currencies) == "table" then
		local coins = (currencies :: { [string]: unknown }).coins
		local mastery = (currencies :: { [string]: unknown }).mastery
		if isSafeInteger(coins) then
			profile.currencies.coins = coins :: number
		end
		if isSafeInteger(mastery) then
			profile.currencies.mastery = mastery :: number
		end
	end
	local collection = saved.collection
	if type(collection) == "table" then
		for cardId, count in collection :: { [string]: unknown } do
			if type(cardId) == "string" and isSafeInteger(count) then
				profile.collection[cardId] = count :: number
			end
		end
	end
	if saved.starterGrantApplied == true then
		profile.starterGrantApplied = true
	end
	local nonce = saved.nextEntitlementNonce
	if isSafeInteger(nonce) and (nonce :: number) >= 1 then
		profile.nextEntitlementNonce = nonce :: number
	end
	local unopened = saved.unopenedPacks
	if type(unopened) == "table" then
		for _, entry in unopened :: { unknown } do
			if type(entry) == "table" then
				local row = entry :: { [string]: unknown }
				local source = row.source
				if type(row.id) == "string" and type(row.packId) == "string" and row.state == "Unopened" and (source == "Earned" or source == "Receipt") then
					table.insert(profile.unopenedPacks, {
						id = row.id,
						packId = row.packId,
						source = source,
						state = "Unopened",
					})
				end
			end
		end
	end
	local receipts = saved.receipts
	if type(receipts) == "table" then
		for purchaseId, entry in receipts :: { [string]: unknown } do
			if type(purchaseId) == "string" and type(entry) == "table" then
				local row = entry :: { [string]: unknown }
				if row.purchaseId == purchaseId and type(row.playerKey) == "string" and type(row.entitlementId) == "string" and isSafeInteger(row.productId) then
					profile.receipts[purchaseId] = {
						purchaseId = purchaseId,
						productId = row.productId :: number,
						playerKey = row.playerKey,
						entitlementId = row.entitlementId,
					}
				end
			end
		end
	end
	local ranks = saved.ranks
	if type(ranks) == "table" then
		for cardId, rank in ranks :: { [string]: unknown } do
			if type(cardId) == "string" and isSafeInteger(rank) and (rank :: number) <= 20 then
				profile.ranks[cardId] = rank :: number
			end
		end
	end
	local placement = saved.placement
	if type(placement) == "table" then
		local seenAnchor: { [string]: boolean } = {}
		local seenCard: { [string]: boolean } = {}
		for _, entry in placement :: { unknown } do
			if type(entry) == "table" then
				local row = entry :: { [string]: unknown }
				if type(row.anchorId) == "string" and type(row.cardId) == "string" and not seenAnchor[row.anchorId] and not seenCard[row.cardId] then
					seenAnchor[row.anchorId] = true
					seenCard[row.cardId] = true
					table.insert(profile.placement, { anchorId = row.anchorId, cardId = row.cardId })
				end
			end
		end
	end
	if type(saved.realmId) == "string" and #saved.realmId >= 1 and #saved.realmId <= 80 then
		profile.realmId = saved.realmId
	end
	local cleared = saved.clearedWaves
	if type(cleared) == "table" then
		for _, waveId in cleared :: { unknown } do
			if type(waveId) == "string" and #waveId >= 1 and #waveId <= 80 then
				table.insert(profile.clearedWaves, waveId)
			end
		end
	end
	local unlocked = saved.unlockedPacks
	if type(unlocked) == "table" then
		for packId, open in unlocked :: { [string]: unknown } do
			if type(packId) == "string" and open == true then
				profile.unlockedPacks[packId] = true
			end
		end
	end
	return PlayerData.validate(profile)
end

export type MemoryStore = {
	load: (self: MemoryStore, userId: string) -> Result.Result<Types.PlayerProfile>,
	save: (self: MemoryStore, userId: string, profile: Types.PlayerProfile) -> Result.Result<nil>,
}

function PlayerData.createMemoryStore(): MemoryStore
	local rows: { [string]: Types.PlayerProfile } = {}
	local store = {} :: MemoryStore
	function store:load(userId: string)
		local row = rows[userId]
		if row == nil then
			return Result.ok(PlayerData.createDefault())
		end
		return Result.ok(copyProfile(row))
	end
	function store:save(userId: string, profile: Types.PlayerProfile)
		local validated = PlayerData.validate(profile)
		if not validated.ok then
			return validated
		end
		rows[userId] = copyProfile(profile)
		return Result.ok(nil)
	end
	return store
end

return PlayerData
