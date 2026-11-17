--!strict
-- Packvania server. ProcessReceipt is installed. Live Robux charges stay off.
-- Outside Studio the slice stays off so a publish cannot grant or save yet.

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

if not RunService:IsStudio() then
	warn("Packvania stays off outside Studio. No live save and no purchases.")
	return
end

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local dataFolder = sharedFolder:WaitForChild("data")
local serverFolder = sharedFolder:WaitForChild("server")
local uiFolder = sharedFolder:WaitForChild("ui")
local netFolder = sharedFolder:WaitForChild("net")

local PackDefinitions = require(dataFolder:WaitForChild("PackDefinitions"))
local ProductCatalog = require(dataFolder:WaitForChild("ProductCatalog"))
local RemoteContract = require(netFolder:WaitForChild("RemoteContract"))
local Board = require(uiFolder:WaitForChild("Board"))
local PackOpen = require(serverFolder:WaitForChild("PackOpen"))
local PlayerData = require(serverFolder:WaitForChild("PlayerData"))
local ProfileSession = require(serverFolder:WaitForChild("ProfileSession"))
local SeededRoll = require(serverFolder:WaitForChild("SeededRoll"))
local PaidPurchase = require(serverFolder:WaitForChild("PaidPurchase"))
local ReceiptCommit = require(serverFolder:WaitForChild("ReceiptCommit"))
local PurchaseEntitlements = require(serverFolder:WaitForChild("PurchaseEntitlements"))
local RunCombat = require(serverFolder:WaitForChild("RunCombat"))
local Progression = require(serverFolder:WaitForChild("Progression"))

local validated = PackDefinitions.validateShipping()
if not validated.ok then
	error("Shipping pack catalog is invalid: " .. validated.code)
end

local function part(parent: Instance, name: string, size: Vector3, position: Vector3, color: Color3, material: Enum.Material): Part
	local block = Instance.new("Part")
	block.Name = name
	block.Anchored = true
	block.Size = size
	block.Position = position
	block.Color = color
	block.Material = material
	block.TopSurface = Enum.SurfaceType.Smooth
	block.BottomSurface = Enum.SurfaceType.Smooth
	block.Parent = parent
	return block
end

local map = Instance.new("Folder")
map.Name = "Packvania"
map.Parent = Workspace
local ground = part(map, "Courtyard", Vector3.new(140, 2, 140), Vector3.new(0, 0, 0), Color3.fromRGB(28, 24, 48), Enum.Material.Slate)
part(map, "Path", Vector3.new(10, 0.4, 70), Vector3.new(0, 1.2, 8), Color3.fromRGB(72, 64, 102), Enum.Material.Cobblestone)
local tower = part(map, "Tower", Vector3.new(10, 18, 10), Vector3.new(0, 10, -8), Color3.fromRGB(96, 92, 118), Enum.Material.Brick)
part(map, "Roof", Vector3.new(12, 4, 12), Vector3.new(0, 21, -8), Color3.fromRGB(128, 48, 72), Enum.Material.Slate)
part(map, "Door", Vector3.new(3, 5, 0.4), Vector3.new(0, 3.5, -2.8), Color3.fromRGB(214, 176, 92), Enum.Material.Neon)
part(map, "Moon", Vector3.new(8, 8, 8), Vector3.new(-28, 36, -20), Color3.fromRGB(230, 220, 190), Enum.Material.Neon)
for index, spot in { Vector3.new(-24, 6, 16), Vector3.new(22, 6, 18), Vector3.new(-18, 5, -24), Vector3.new(26, 7, -16) } do
	part(map, "Cypress" .. index, Vector3.new(3, 12, 3), spot, Color3.fromRGB(36, 32, 58), Enum.Material.Slate)
end
local pads = { ["lane.back"] = Vector3.new(-8, 1.4, 10), ["lane.mid"] = Vector3.new(0, 1.4, 4), ["lane.front"] = Vector3.new(8, 1.4, -2) }
for name, position in pads do
	part(map, name, Vector3.new(4, 0.4, 4), position, Color3.fromRGB(90, 78, 130), Enum.Material.Neon)
end
part(map, "PackPedestal", Vector3.new(4, 2, 4), Vector3.new(16, 2, 14), Color3.fromRGB(92, 64, 48), Enum.Material.Wood)
Lighting.ClockTime = 20.5
Lighting.Ambient = Color3.fromRGB(48, 42, 78)
Lighting.OutdoorAmbient = Color3.fromRGB(36, 32, 64)
Lighting.Brightness = 1.4
ground.Name = "Courtyard"
tower.Name = "Tower"

local starter = game:GetService("StarterPlayer")
starter.CharacterAutoLoads = false

local remotes = ReplicatedStorage:FindFirstChild("PackvaniaRemotes")
if remotes == nil then
	remotes = Instance.new("Folder")
	remotes.Name = "PackvaniaRemotes"
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
local relicRemote = remote(RemoteContract.names.ToggleRelic)
local resultRemote = remote("PackOpenResult")
local gate = RemoteContract.createRateGate(PackOpen.interval())
local nextInteger = SeededRoll.integer((DateTime.now().UnixTimestampMillis % 2147483646) + 1)

local dataStore = nil
local storeOk, storeOrErr = pcall(function()
	return DataStoreService:GetDataStore(ProfileSession.studioStoreName())
end)
if storeOk then
	dataStore = storeOrErr
	print("Packvania persistence: Studio DataStore", ProfileSession.studioStoreName())
else
	warn("Packvania persistence: DataStore unavailable, memory only. " .. tostring(storeOrErr))
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

type Session = { token: string, key: string, profile: any }
type PaidPolicy = { known: boolean, arePaidRandomItemsRestricted: boolean }
local sessions: { [Player]: Session } = {}
local policies: { [Player]: PaidPolicy } = {}

local function readPolicy(player: Player): PaidPolicy
	local ok, info = pcall(function()
		return PolicyService:GetPolicyInfoForPlayerAsync(player)
	end)
	if not ok or type(info) ~= "table" or type((info :: any).ArePaidRandomItemsRestricted) ~= "boolean" then
		return { known = false, arePaidRandomItemsRestricted = true }
	end
	return { known = true, arePaidRandomItemsRestricted = (info :: any).ArePaidRandomItemsRestricted }
end

local function send(player: Player, body: { [string]: any })
	resultRemote:FireClient(player, body)
end

local function loadPlayer(player: Player)
	local token = HttpService:GenerateGUID(false)
	local key = ProfileSession.playerKey(player.UserId)
	local loaded = ProfileSession.load(adapter, key, token, os.time())
	if not loaded.ok then
		warn("Packvania load failed", player.UserId, loaded.code)
		send(player, { ok = false, code = loaded.code })
		return
	end
	local policy = readPolicy(player)
	policies[player] = policy
	sessions[player] = { token = token, key = key, profile = loaded.value }
	send(player, { ok = true, snapshot = Board.snapshot(loaded.value, policy) })
	print("Packvania loaded", player.UserId, "coins", loaded.value.currencies.coins, "policyKnown", policy.known)
end

local function releasePlayer(player: Player)
	local session = sessions[player]
	policies[player] = nil
	sessions[player] = nil
	if session == nil then
		return
	end
	local saved = ProfileSession.save(adapter, session.key, session.token, session.profile, os.time(), true)
	if saved.ok then
		print("Packvania saved", player.UserId)
	else
		warn("Packvania save failed", player.UserId, saved.code)
	end
end

local function policyOf(player: Player): PaidPolicy
	return policies[player] or { known = false, arePaidRandomItemsRestricted = true }
end

local function commit(session: Session): boolean
	local saved = ProfileSession.save(adapter, session.key, session.token, session.profile, os.time(), false)
	if not saved.ok then
		return false
	end
	session.profile = saved.value
	return true
end

openRemote.OnServerEvent:Connect(function(player: Player, payload: unknown)
	local session = sessions[player]
	if session == nil then
		send(player, { ok = false, code = "ProfileNotLoaded" })
		return
	end
	local before = PlayerData.clone(session.profile)
	local opened = PackOpen.request(session.profile, payload, tostring(player.UserId), os.clock(), gate, nextInteger)
	if not commit(session) then
		session.profile = before
		send(player, { ok = false, code = "StoreFailed", snapshot = Board.snapshot(session.profile, policyOf(player)) })
		return
	end
	local policy = policyOf(player)
	if opened.ok then
		send(player, { ok = true, reveal = opened.value, snapshot = Board.snapshot(session.profile, policy) })
	else
		send(player, { ok = false, code = opened.code, snapshot = Board.snapshot(session.profile, policy) })
	end
end)

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
	if not commit(session) then
		session.profile = before
		send(player, { ok = false, code = "StoreFailed", snapshot = Board.snapshot(session.profile, policy) })
		return
	end
	if opened.ok then
		send(player, { ok = true, reveal = opened.value, snapshot = Board.snapshot(session.profile, policy) })
	else
		send(player, { ok = false, code = opened.code, snapshot = Board.snapshot(session.profile, policy) })
	end
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
	send(player, {
		ok = false,
		kind = "paid",
		code = if decision.ok then "LiveChargesDisabled" else decision.code,
		allowPrompt = false,
		snapshot = Board.snapshot(session.profile, policy),
	})
end)

placeRemote.OnServerEvent:Connect(function(player: Player, payload: unknown)
	local session = sessions[player]
	if session == nil then
		send(player, { ok = false, code = "ProfileNotLoaded" })
		return
	end
	local parsed = RemoteContract.validatePlaceHero(payload)
	if not parsed.ok then
		send(player, { ok = false, code = parsed.code, snapshot = Board.snapshot(session.profile, policyOf(player)) })
		return
	end
	local before = PlayerData.clone(session.profile)
	local placed = Progression.place(session.profile, parsed.value.cardId, parsed.value.anchorId)
	if not placed.ok then
		session.profile = before
		send(player, { ok = false, code = placed.code, snapshot = Board.snapshot(session.profile, policyOf(player)) })
		return
	end
	if not commit(session) then
		session.profile = before
		send(player, { ok = false, code = "StoreFailed", snapshot = Board.snapshot(session.profile, policyOf(player)) })
		return
	end
	send(player, { ok = true, code = "Placed", snapshot = Board.snapshot(session.profile, policyOf(player)) })
end)

waveRemote.OnServerEvent:Connect(function(player: Player, payload: unknown)
	local session = sessions[player]
	if session == nil then
		send(player, { ok = false, code = "ProfileNotLoaded" })
		return
	end
	local parsed = RemoteContract.validateStartWave(payload)
	if not parsed.ok then
		send(player, { ok = false, code = parsed.code, snapshot = Board.snapshot(session.profile, policyOf(player)) })
		return
	end
	local before = PlayerData.clone(session.profile)
	local fought = RunCombat.fight(session.profile, parsed.value.waveId, 20261117)
	if not fought.ok then
		session.profile = before
		send(player, { ok = false, code = fought.code, snapshot = Board.snapshot(session.profile, policyOf(player)) })
		return
	end
	if not commit(session) then
		session.profile = before
		send(player, { ok = false, code = "StoreFailed", snapshot = Board.snapshot(session.profile, policyOf(player)) })
		return
	end
	local report = fought.value
	print("Packvania combat", report.waveId, "ticks", report.ticks, "survived", report.survived)
	send(player, {
		ok = report.survived,
		kind = "combat",
		code = if report.survived then "TowerSurvived" else "TowerFell",
		resultLines = Board.resultLines(session.profile, report),
		snapshot = Board.snapshot(session.profile, policyOf(player)),
	})
end)

upgradeRemote.OnServerEvent:Connect(function(player: Player, payload: unknown)
	local session = sessions[player]
	if session == nil then
		send(player, { ok = false, code = "ProfileNotLoaded" })
		return
	end
	local parsed = RemoteContract.validateBuyUpgrade(payload)
	if not parsed.ok then
		send(player, { ok = false, code = parsed.code, snapshot = Board.snapshot(session.profile, policyOf(player)) })
		return
	end
	local before = PlayerData.clone(session.profile)
	local ranked = Progression.upgrade(session.profile, parsed.value.cardId)
	if not ranked.ok then
		session.profile = before
		send(player, { ok = false, code = ranked.code, snapshot = Board.snapshot(session.profile, policyOf(player)) })
		return
	end
	if not commit(session) then
		session.profile = before
		send(player, { ok = false, code = "StoreFailed", snapshot = Board.snapshot(session.profile, policyOf(player)) })
		return
	end
	send(player, { ok = true, code = "Upgraded", snapshot = Board.snapshot(session.profile, policyOf(player)) })
end)

relicRemote.OnServerEvent:Connect(function(player: Player, payload: unknown)
	local session = sessions[player]
	if session == nil then
		send(player, { ok = false, code = "ProfileNotLoaded" })
		return
	end
	local parsed = RemoteContract.validateToggleRelic(payload)
	if not parsed.ok then
		send(player, { ok = false, code = parsed.code, snapshot = Board.snapshot(session.profile, policyOf(player)) })
		return
	end
	local before = PlayerData.clone(session.profile)
	local toggled = Progression.toggleRelic(session.profile, parsed.value.relicId)
	if not toggled.ok then
		session.profile = before
		send(player, { ok = false, code = toggled.code, snapshot = Board.snapshot(session.profile, policyOf(player)) })
		return
	end
	if not commit(session) then
		session.profile = before
		send(player, { ok = false, code = "StoreFailed", snapshot = Board.snapshot(session.profile, policyOf(player)) })
		return
	end
	send(player, { ok = true, code = "Relic", snapshot = Board.snapshot(session.profile, policyOf(player)) })
end)

MarketplaceService.ProcessReceipt = function(receiptInfo)
	if durable == nil then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if player == nil or sessions[player] == nil then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local session = sessions[player]
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
		send(player, { ok = true, kind = "receipt", snapshot = Board.snapshot(session.profile, policyOf(player)) })
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

MarketplaceService.PromptProductPurchaseFinished:Connect(function()
	PurchaseEntitlements.onPromptFinished()
end)

print("Packvania ProcessReceipt installed. Live charges", ProductCatalog.liveChargesEnabled())
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
