--!strict
-- Studio-only host. ProcessReceipt is installed. Live Robux charges stay off.
-- No production DataStore name and no grant from PromptProductPurchaseFinished.

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

if not RunService:IsStudio() then
	warn("BPH pack slice stays off outside Studio. No live save and no purchases.")
	return
end

local sharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
assert(sharedFolder, "ReplicatedStorage.Shared missing")
local dataFolder = sharedFolder:WaitForChild("data", 10)
local serverFolder = sharedFolder:WaitForChild("server", 10)
local uiFolder = sharedFolder:WaitForChild("ui", 10)
local netFolder = sharedFolder:WaitForChild("net", 10)
assert(dataFolder and serverFolder and uiFolder and netFolder, "Shared folders missing")

local PackDefinitions = require(dataFolder:WaitForChild("PackDefinitions"))
local CardDefinitions = require(dataFolder:WaitForChild("CardDefinitions"))
local PackUI = require(uiFolder:WaitForChild("PackUI"))
local RemoteContract = require(netFolder:WaitForChild("RemoteContract"))
local PackOpen = require(serverFolder:WaitForChild("PackOpen"))
local PlayerData = require(serverFolder:WaitForChild("PlayerData"))
local ProfileSession = require(serverFolder:WaitForChild("ProfileSession"))
local SeededRoll = require(serverFolder:WaitForChild("SeededRoll"))
local ProductCatalog = require(dataFolder:WaitForChild("ProductCatalog"))
local PaidPurchase = require(serverFolder:WaitForChild("PaidPurchase"))
local ReceiptCommit = require(serverFolder:WaitForChild("ReceiptCommit"))
local PurchaseEntitlements = require(serverFolder:WaitForChild("PurchaseEntitlements"))
local RunCombat = require(serverFolder:WaitForChild("RunCombat"))
local Progression = require(serverFolder:WaitForChild("Progression"))
local CombatUI = require(uiFolder:WaitForChild("CombatUI"))

local validated = PackDefinitions.validateShipping()
if not validated.ok then
	error("Shipping pack catalog is invalid: " .. validated.code)
end

local remotes = ReplicatedStorage:FindFirstChild("BPHRemotes")
if remotes == nil then
	remotes = Instance.new("Folder")
	remotes.Name = "BPHRemotes"
	remotes.Parent = ReplicatedStorage
end

local function remote(name: string): RemoteEvent
	local existing = remotes:FindFirstChild(name)
	if existing ~= nil and existing:IsA("RemoteEvent") then
		return existing
	end
	if existing ~= nil then
		existing:Destroy()
	end
	local created = Instance.new("RemoteEvent")
	created.Name = name
	created.Parent = remotes
	return created
end

local openRemote = remote(RemoteContract.names.OpenEarnedPack)
local entitlementRemote = remote(RemoteContract.names.OpenEntitlement)
local paidRemote = remote(RemoteContract.names.RequestPaidPack)
local placeRemote = remote(RemoteContract.names.PlaceHero)
local waveRemote = remote(RemoteContract.names.StartWave)
local upgradeRemote = remote(RemoteContract.names.BuyUpgrade)
local resultRemote = remote("PackOpenResult")
local gate = RemoteContract.createRateGate(PackOpen.interval())
local nextInteger = SeededRoll.integer((DateTime.now().UnixTimestampMillis % 2147483646) + 1)

local storeName = ProfileSession.studioStoreName()
local dataStore = nil
local storeOk, storeOrErr = pcall(function()
	return DataStoreService:GetDataStore(storeName)
end)
if storeOk then
	dataStore = storeOrErr
	print("BPH persistence: Studio DataStore", storeName)
else
	warn("BPH persistence: DataStore unavailable, memory only. Rejoin will not keep cards. " .. tostring(storeOrErr))
end

local memory = ProfileSession.createMemoryStore()

local durable: ProfileSession.Store? = nil
if dataStore ~= nil then
	local live = dataStore
	durable = {
		UpdateAsync = function(_self, key: string, transform)
			return live:UpdateAsync(key, transform)
		end,
		GetAsync = function(_self, key: string)
			return live:GetAsync(key)
		end,
	}
end

local adapter = {
	UpdateAsync = function(_self, key: string, transform)
		local ok, result = ProfileSession.callStore(durable, memory, key, transform)
		if not ok then
			error("StoreFailed")
		end
		return result
	end,
	GetAsync = function(_self, key: string)
		if durable ~= nil then
			return durable:GetAsync(key)
		end
		return memory:GetAsync(key)
	end,
}

type Session = {
	token: string,
	key: string,
	profile: any,
}
type PaidPolicy = {
	known: boolean,
	arePaidRandomItemsRestricted: boolean,
}
local sessions: { [Player]: Session } = {}
local policies: { [Player]: PaidPolicy } = {}

local function readPolicy(player: Player): PaidPolicy
	local ok, info = pcall(function()
		return PolicyService:GetPolicyInfoForPlayerAsync(player)
	end)
	if not ok or type(info) ~= "table" then
		return { known = false, arePaidRandomItemsRestricted = true }
	end
	local restricted = (info :: { [string]: any }).ArePaidRandomItemsRestricted
	if type(restricted) ~= "boolean" then
		return { known = false, arePaidRandomItemsRestricted = true }
	end
	return { known = true, arePaidRandomItemsRestricted = restricted }
end

local function snapshot(profile, policy: PaidPolicy): { [string]: any }
	local pack = PackDefinitions.get("placeholder.starter")
	local cards = {}
	for cardId, count in profile.collection do
		local card = CardDefinitions.get(cardId)
		table.insert(cards, {
			cardId = cardId,
			displayName = if card ~= nil then card.displayName else cardId,
			kind = if card ~= nil then card.kind else "Hero",
			count = count,
			rank = profile.ranks[cardId] or 0,
		})
	end
	table.sort(cards, function(a, b)
		return a.displayName < b.displayName
	end)
	local unopened = {}
	for _, entitlement in profile.unopenedPacks do
		local named = PackDefinitions.get(entitlement.packId)
		table.insert(unopened, {
			id = entitlement.id,
			packId = entitlement.packId,
			displayName = if named ~= nil then named.displayName else entitlement.packId,
		})
	end
	return {
		coins = profile.currencies.coins,
		cards = cards,
		unopened = unopened,
		oddsLines = if pack ~= nil then PackUI.oddsLines(pack) else {},
		paidOddsLines = PackUI.paidOddsLines(),
		shopText = PackUI.shopText(policy),
		paidPackId = ProductCatalog.list()[1].packId,
		developerProductId = ProductCatalog.list()[1].developerProductId,
		notice = PackUI.PROVISIONAL_NOTICE,
		paidEnabled = false,
		allowPrompt = false,
		mastery = profile.currencies.mastery,
		combatText = CombatUI.describe(profile, nil),
		nextWaveId = Progression.nextWaveId(profile),
		gatePackId = PackDefinitions.gatePack().id,
		gateUnlocked = profile.unlockedPacks[PackDefinitions.gatePack().id] == true,
	}
end

local function send(player: Player, body: { [string]: any })
	resultRemote:FireClient(player, body)
end

local function loadPlayer(player: Player)
	local token = HttpService:GenerateGUID(false)
	local key = ProfileSession.playerKey(player.UserId)
	local loaded = ProfileSession.load(adapter, key, token, os.time())
	if not loaded.ok then
		warn("BPH load failed", player.UserId, loaded.code)
		send(player, { ok = false, code = loaded.code })
		return
	end
	local policy = readPolicy(player)
	policies[player] = policy
	sessions[player] = { token = token, key = key, profile = loaded.value }
	send(player, { ok = true, snapshot = snapshot(loaded.value, policy) })
	print("BPH loaded", player.UserId, "coins", loaded.value.currencies.coins, "policyKnown", policy.known)
end

local function stamp(profile): string
	local cards = 0
	for _, count in profile.collection do
		cards += count
	end
	local ranks = 0
	for _, rank in profile.ranks do
		ranks += rank
	end
	local unlocks = 0
	for _, open in profile.unlockedPacks do
		if open then
			unlocks += 1
		end
	end
	return table.concat({
		tostring(profile.currencies.coins),
		tostring(profile.currencies.mastery),
		tostring(profile.nextEntitlementNonce),
		tostring(#profile.unopenedPacks),
		tostring(#profile.placement),
		tostring(#profile.clearedWaves),
		tostring(cards),
		tostring(ranks),
		tostring(unlocks),
		profile.realmId,
	}, ":")
end

local function commitMutation(session: Session, before): boolean
	if stamp(before) == stamp(session.profile) then
		return true
	end
	local saved = ProfileSession.save(adapter, session.key, session.token, session.profile, os.time(), false)
	if not saved.ok then
		session.profile = before
		warn("BPH save failed", session.key, saved.code)
		return false
	end
	session.profile = saved.value
	return true
end

local function releasePlayer(player: Player)
	local session = sessions[player]
	policies[player] = nil
	if session == nil then
		return
	end
	sessions[player] = nil
	local saved = ProfileSession.save(adapter, session.key, session.token, session.profile, os.time(), true)
	if not saved.ok then
		warn("BPH save failed", player.UserId, saved.code)
	else
		print("BPH saved", player.UserId)
	end
end

openRemote.OnServerEvent:Connect(function(player: Player, payload: unknown)
	local session = sessions[player]
	if session == nil then
		send(player, { ok = false, code = "ProfileNotLoaded" })
		return
	end
	local before = PlayerData.clone(session.profile)
	local opened = PackOpen.request(session.profile, payload, tostring(player.UserId), os.clock(), gate, nextInteger)
	if not commitMutation(session, before) then
		send(player, { ok = false, code = "StoreFailed", snapshot = snapshot(session.profile, policies[player] or readPolicy(player)) })
		return
	end
	if opened.ok then
		send(player, { ok = true, reveal = opened.value, snapshot = snapshot(session.profile, policies[player] or readPolicy(player)) })
		return
	end
	send(player, { ok = false, code = opened.code, snapshot = snapshot(session.profile, policies[player] or readPolicy(player)) })
end)

local function playerPolicy(player: Player): PaidPolicy
	return policies[player] or { known = false, arePaidRandomItemsRestricted = true }
end

entitlementRemote.OnServerEvent:Connect(function(player: Player, payload: unknown)
	local session = sessions[player]
	if session == nil then
		send(player, { ok = false, code = "ProfileNotLoaded" })
		return
	end
	local policy = readPolicy(player)
	policies[player] = policy
	local before = PlayerData.clone(session.profile)
	local opened = PackOpen.openOwned(session.profile, payload, tostring(player.UserId), os.clock(), gate, nextInteger, policy)
	if not commitMutation(session, before) then
		send(player, { ok = false, code = "StoreFailed", snapshot = snapshot(session.profile, policy) })
		return
	end
	if opened.ok then
		send(player, { ok = true, reveal = opened.value, snapshot = snapshot(session.profile, policy) })
		return
	end
	send(player, { ok = false, code = opened.code, snapshot = snapshot(session.profile, policy) })
end)

paidRemote.OnServerEvent:Connect(function(player: Player, payload: unknown)
	local session = sessions[player]
	if session == nil then
		send(player, { ok = false, code = "ProfileNotLoaded", kind = "paid", allowPrompt = false })
		return
	end
	local policy = readPolicy(player)
	policies[player] = policy
	local decision = PaidPurchase.request(payload, policy, ProductCatalog.liveChargesEnabled())
	local promptedId = 0
	if decision.ok and ProductCatalog.liveChargesEnabled() and decision.value.developerProductId >= 1 then
		promptedId = decision.value.developerProductId
	end
	send(player, {
		ok = false,
		kind = "paid",
		code = if decision.ok then "LiveChargesDisabled" else decision.code,
		allowPrompt = promptedId >= 1,
		productId = promptedId,
		snapshot = snapshot(session.profile, policy),
	})
end)

local function combatReply(player: Player, session: Session, ok: boolean, code: string, summary: string?, combat: CombatUI.CombatSummary?)
	local policy = policies[player] or readPolicy(player)
	send(player, {
		ok = ok,
		kind = "combat",
		code = code,
		summary = summary,
		combat = combat,
		snapshot = snapshot(session.profile, policy),
	})
end

placeRemote.OnServerEvent:Connect(function(player: Player, payload: unknown)
	local session = sessions[player]
	if session == nil then
		send(player, { ok = false, kind = "combat", code = "ProfileNotLoaded" })
		return
	end
	local parsed = RemoteContract.validatePlaceHero(payload)
	if not parsed.ok then
		combatReply(player, session, false, parsed.code, nil)
		return
	end
	if not gate:allow(tostring(player.UserId), RemoteContract.names.PlaceHero, os.clock()) then
		combatReply(player, session, false, "RateLimited", nil)
		return
	end
	local before = PlayerData.clone(session.profile)
	local placed = Progression.place(session.profile, parsed.value.cardId, parsed.value.anchorId)
	if not placed.ok then
		session.profile = before
		combatReply(player, session, false, placed.code, nil)
		return
	end
	if not commitMutation(session, before) then
		combatReply(player, session, false, "StoreFailed", nil)
		return
	end
	combatReply(player, session, true, "Placed", CombatUI.describe(session.profile, nil))
end)

waveRemote.OnServerEvent:Connect(function(player: Player, payload: unknown)
	local session = sessions[player]
	if session == nil then
		send(player, { ok = false, kind = "combat", code = "ProfileNotLoaded" })
		return
	end
	local parsed = RemoteContract.validateStartWave(payload)
	if not parsed.ok then
		combatReply(player, session, false, parsed.code, nil)
		return
	end
	if not gate:allow(tostring(player.UserId), RemoteContract.names.StartWave, os.clock()) then
		combatReply(player, session, false, "RateLimited", nil)
		return
	end
	local before = PlayerData.clone(session.profile)
	local fought = RunCombat.fight(session.profile, parsed.value.waveId, 20261117)
	if not fought.ok then
		session.profile = before
		combatReply(player, session, false, fought.code, nil)
		return
	end
	print("BPH combat", fought.value.waveId, "ticks", fought.value.ticks, "survived", fought.value.survived, "damage", fought.value.damageDealt)
	if not commitMutation(session, before) then
		combatReply(player, session, false, "StoreFailed", nil)
		return
	end
	combatReply(player, session, fought.value.survived, if fought.value.survived then "TowerSurvived" else "TowerFell", CombatUI.describe(session.profile, fought.value), {
		seed = fought.value.seed,
		ticks = fought.value.ticks,
		damageDealt = fought.value.damageDealt,
		survived = fought.value.survived,
		towerHp = fought.value.towerHp,
	})
end)

upgradeRemote.OnServerEvent:Connect(function(player: Player, payload: unknown)
	local session = sessions[player]
	if session == nil then
		send(player, { ok = false, kind = "combat", code = "ProfileNotLoaded" })
		return
	end
	local parsed = RemoteContract.validateBuyUpgrade(payload)
	if not parsed.ok then
		combatReply(player, session, false, parsed.code, nil)
		return
	end
	if not gate:allow(tostring(player.UserId), RemoteContract.names.BuyUpgrade, os.clock()) then
		combatReply(player, session, false, "RateLimited", nil)
		return
	end
	local before = PlayerData.clone(session.profile)
	local ranked = Progression.upgrade(session.profile, parsed.value.cardId)
	if not ranked.ok then
		session.profile = before
		combatReply(player, session, false, ranked.code, nil)
		return
	end
	if not commitMutation(session, before) then
		combatReply(player, session, false, "StoreFailed", nil)
		return
	end
	combatReply(player, session, true, "Upgraded", CombatUI.describe(session.profile, nil))
end)

MarketplaceService.ProcessReceipt = function(receiptInfo)
	if durable == nil then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if player == nil then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local session = sessions[player]
	if session == nil then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local before = PlayerData.clone(session.profile)
	local flushed = ProfileSession.save(adapter, session.key, session.token, session.profile, os.time(), false)
	if not flushed.ok then
		session.profile = before
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	session.profile = flushed.value
	local products = PurchaseEntitlements.shippingProducts()
	local receipt = {
		purchaseId = receiptInfo.PurchaseId,
		productId = receiptInfo.ProductId,
		playerKey = ProfileSession.playerKey(player.UserId),
	}
	local committed = ReceiptCommit.process(adapter, session.key, session.token, receipt, products, nil, os.time(), true)
	if committed.ok and committed.value.decision == "PurchaseGranted" then
		PurchaseEntitlements.applyReceipt(session.profile, receipt, products, nil)
		send(player, { ok = true, kind = "receipt", snapshot = snapshot(session.profile, playerPolicy(player)) })
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

MarketplaceService.PromptProductPurchaseFinished:Connect(function()
	PurchaseEntitlements.onPromptFinished()
end)

print("BPH ProcessReceipt installed. Live charges", ProductCatalog.liveChargesEnabled())

Players.PlayerAdded:Connect(loadPlayer)
for _, player in Players:GetPlayers() do
	task.spawn(loadPlayer, player)
end
Players.PlayerRemoving:Connect(releasePlayer)
game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		releasePlayer(player)
	end
end)
