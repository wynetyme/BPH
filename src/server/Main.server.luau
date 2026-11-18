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

-- This Studio build keeps the flag on Players. StarterPlayer.CharacterAutoLoads errors and stops the server.
Players.CharacterAutoLoads = false

local function parkCharacter(character: Model)
	local root = character:FindFirstChild("HumanoidRootPart")
	if root ~= nil and root:IsA("BasePart") then
		root.Anchored = true
		root.CFrame = CFrame.new(0, -400, 0)
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid ~= nil then
		humanoid.PlatformStand = true
	end
end

local function watchPlayer(player: Player)
	player.CharacterAdded:Connect(parkCharacter)
	if player.Character ~= nil then
		parkCharacter(player.Character)
	end
end

for _, player in Players:GetPlayers() do
	watchPlayer(player)
end
Players.PlayerAdded:Connect(watchPlayer)

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
local StageArt = require(uiFolder:WaitForChild("StageArt"))

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
	block.CastShadow = false
	block.TopSurface = Enum.SurfaceType.Smooth
	block.BottomSurface = Enum.SurfaceType.Smooth
	block.Parent = parent
	return block
end

local function hidePlaceFloor()
	for _, name in { "Baseplate", "SpawnLocation" } do
		local item = Workspace:FindFirstChild(name)
		if item ~= nil and item:IsA("BasePart") then
			item.Transparency = 1
			item.CastShadow = false
		end
	end
end

-- Side-on stage. X is the lane, Y is up, and the camera looks straight along Z.
-- Art is original placeholder geometry. Source-game illustrations are UNKNOWN.
hidePlaceFloor()
local view = StageArt.view()
local map = Instance.new("Folder")
map.Name = "Packvania"
map:SetAttribute("ViewCenterX", view.centerX)
map:SetAttribute("ViewCenterY", view.centerY)
map:SetAttribute("ViewWidth", view.width)
map:SetAttribute("ViewHeight", view.height)
map:SetAttribute("ArtStatus", StageArt.status())
map:SetAttribute("SourceArt", "UNKNOWN")
map.Parent = Workspace

local function color3(channels: { number }): Color3
	return Color3.fromRGB(channels[1], channels[2], channels[3])
end

local function placePiece(parent: Instance, spec, ox: number, oy: number, oz: number): Part
	local pos = Vector3.new(spec.x + ox, spec.y + oy, spec.z + oz)
	local material = Enum.Material.SmoothPlastic
	if spec.material == "Neon" then
		material = Enum.Material.Neon
	elseif spec.material == "Slate" then
		material = Enum.Material.Slate
	end
	local block = part(parent, spec.name, Vector3.new(spec.sx, spec.sy, spec.sz), pos, Color3.fromRGB(spec.r, spec.g, spec.b), material)
	block.Transparency = spec.transparency
	block.CanCollide = false
	block.CanQuery = false
	block.CanTouch = false
	if spec.shape == "Cylinder" then
		block.Shape = Enum.PartType.Cylinder
	elseif spec.shape == "Ball" then
		block.Shape = Enum.PartType.Ball
	end
	if spec.shape ~= "Block" or spec.ry ~= 0 then
		block.CFrame = CFrame.new(pos) * CFrame.Angles(0, math.rad(spec.ry), 0)
	end
	if spec.light ~= nil then
		local glow = Instance.new("PointLight")
		glow.Brightness = spec.light.brightness
		glow.Range = spec.light.range
		glow.Color = Color3.fromRGB(spec.light.r, spec.light.g, spec.light.b)
		glow.Parent = block
	end
	block:SetAttribute("ArtStatus", StageArt.status())
	block:SetAttribute("SourceArt", "UNKNOWN")
	return block
end

for _, spec in StageArt.scenery() do
	placePiece(map, spec, 0, 0, 0)
end

local actors = Instance.new("Folder")
actors.Name = "Actors"
actors.Parent = map

local function refreshActors(player: Player, profile: any)
	for _, child in actors:GetChildren() do
		if child:GetAttribute("UserId") == player.UserId then
			child:Destroy()
		end
	end
	local holder = Instance.new("Model")
	holder.Name = "Roster"
	holder:SetAttribute("UserId", player.UserId)
	holder:SetAttribute("ArtStatus", StageArt.status())
	holder.Parent = actors
	for _, slot in profile.placement do
		local x = StageArt.anchorX(slot.anchorId)
		if x ~= nil then
			for _, spec in StageArt.figure("card", slot.cardId) do
				placePiece(holder, spec, x, StageArt.feetY(), 0)
			end
			local rank = profile.ranks[slot.cardId] or 0
			for _, spec in StageArt.rankPips(rank) do
				placePiece(holder, spec, x, StageArt.feetY(), 0)
			end
		end
	end
end

local lit = StageArt.lighting()
Lighting.GlobalShadows = lit.globalShadows
Lighting.Brightness = lit.brightness
Lighting.ClockTime = lit.clockTime
Lighting.FogStart = lit.fogStart
Lighting.FogEnd = lit.fogEnd
Lighting.FogColor = color3(lit.fog)
Lighting.Ambient = color3(lit.ambient)
Lighting.OutdoorAmbient = color3(lit.outdoor)
Lighting.EnvironmentDiffuseScale = 0
Lighting.EnvironmentSpecularScale = 0

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
	refreshActors(player, loaded.value)
	send(player, { ok = true, snapshot = Board.snapshot(loaded.value, policy) })
	print("Packvania loaded", player.UserId, "coins", loaded.value.currencies.coins, "policyKnown", policy.known)
end

local function releasePlayer(player: Player)
	local session = sessions[player]
	policies[player] = nil
	sessions[player] = nil
	for _, child in actors:GetChildren() do
		if child:GetAttribute("UserId") == player.UserId then
			child:Destroy()
		end
	end
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
	refreshActors(player, session.profile)
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
		preview = report.frames,
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
	refreshActors(player, session.profile)
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
