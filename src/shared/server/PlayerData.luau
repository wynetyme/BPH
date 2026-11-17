--!strict

local Types = require("../contracts/Types")
local Result = require("../contracts/Result")
local CombatTables = require("../data/CombatTables")

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
		table.insert(unopened, { id = pack.id, packId = pack.packId, source = pack.source, state = pack.state })
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
	local relics: { [string]: boolean } = {}
	for relicId, known in profile.relics do
		relics[relicId] = known
	end
	local equipped: { string } = {}
	for _, relicId in profile.equippedRelics do
		table.insert(equipped, relicId)
	end
	local bestiary: { [string]: boolean } = {}
	for enemyId, seen in profile.bestiary do
		bestiary[enemyId] = seen
	end
	return {
		version = profile.version,
		currencies = { coins = profile.currencies.coins, mastery = profile.currencies.mastery },
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
		relics = relics,
		equippedRelics = equipped,
		bestiary = bestiary,
		packsOpened = profile.packsOpened,
		damageDealt = profile.damageDealt,
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
		realmId = CombatTables.startRealm(),
		clearedWaves = {},
		unlockedPacks = {},
		relics = {},
		equippedRelics = {},
		bestiary = {},
		packsOpened = 0,
		damageDealt = 0,
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
	if not isSafeInteger(profile.packsOpened) or not isSafeInteger(profile.damageDealt) then
		return Result.err("InvalidProfile")
	end
	if type(profile.starterGrantApplied) ~= "boolean" or type(profile.realmId) ~= "string" or #profile.realmId < 1 then
		return Result.err("InvalidProfile")
	end
	if #profile.equippedRelics > 3 then
		return Result.err("InvalidProfile")
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
	if isSafeInteger(saved.packsOpened) then
		profile.packsOpened = saved.packsOpened :: number
	end
	if isSafeInteger(saved.damageDealt) then
		profile.damageDealt = saved.damageDealt :: number
	end
	if type(saved.realmId) == "string" and #saved.realmId >= 1 and #saved.realmId <= 80 then
		profile.realmId = saved.realmId
	end
	local unopened = saved.unopenedPacks
	if type(unopened) == "table" then
		for _, entry in unopened :: { unknown } do
			if type(entry) == "table" then
				local row = entry :: { [string]: unknown }
				local source = row.source
				if type(row.id) == "string" and type(row.packId) == "string" and row.state == "Unopened" and (source == "Earned" or source == "Receipt") then
					table.insert(profile.unopenedPacks, { id = row.id, packId = row.packId, source = source, state = "Unopened" })
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
		for _, entry in placement :: { unknown } do
			if type(entry) == "table" then
				local row = entry :: { [string]: unknown }
				if type(row.anchorId) == "string" and type(row.cardId) == "string" then
					table.insert(profile.placement, { anchorId = row.anchorId, cardId = row.cardId })
				end
			end
		end
	end
	local cleared = saved.clearedWaves
	if type(cleared) == "table" then
		for _, waveId in cleared :: { unknown } do
			if type(waveId) == "string" and #waveId >= 1 then
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
	local relics = saved.relics
	if type(relics) == "table" then
		for relicId, known in relics :: { [string]: unknown } do
			if type(relicId) == "string" and known == true then
				profile.relics[relicId] = true
			end
		end
	end
	local equipped = saved.equippedRelics
	if type(equipped) == "table" then
		for _, relicId in equipped :: { unknown } do
			if type(relicId) == "string" and #profile.equippedRelics < 3 then
				table.insert(profile.equippedRelics, relicId)
			end
		end
	end
	local bestiary = saved.bestiary
	if type(bestiary) == "table" then
		for enemyId, seen in bestiary :: { [string]: unknown } do
			if type(enemyId) == "string" and seen == true then
				profile.bestiary[enemyId] = true
			end
		end
	end
	return PlayerData.validate(profile)
end

return PlayerData
