--!strict
-- Packvania presentation. The server owns cards, coins, combat, and receipts.

local GuiService = game:GetService("GuiService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- Side-on, level, base on the left. A 1° lens is past Studio's draw distance and shows only sky.
local SIDE_FOV = 8

local function lockSideCamera()
	local cam = Workspace.CurrentCamera
	if cam == nil then
		return
	end
	camera = cam
	local center = Vector3.new(0, 22, 0)
	local viewWidth = 100
	local viewHeight = 54
	local map = Workspace:FindFirstChild("Packvania")
	if map ~= nil then
		local centerX = map:GetAttribute("ViewCenterX")
		local centerY = map:GetAttribute("ViewCenterY")
		local width = map:GetAttribute("ViewWidth")
		local height = map:GetAttribute("ViewHeight")
		if typeof(centerX) == "number" and typeof(centerY) == "number" then
			center = Vector3.new(centerX, centerY, 0)
		end
		if typeof(width) == "number" and width > 1 then
			viewWidth = width
		end
		if typeof(height) == "number" and height > 1 then
			viewHeight = height
		end
	end
	cam.CameraType = Enum.CameraType.Scriptable
	cam.FieldOfView = SIDE_FOV
	local half = math.tan(math.rad(cam.FieldOfView * 0.5))
	local aspect = cam.ViewportSize.X / math.max(cam.ViewportSize.Y, 1)
	if aspect ~= aspect or aspect <= 0 then
		aspect = 1
	end
	local distance = math.max((viewHeight * 0.5) / half, (viewWidth * 0.5) / (half * aspect))
	if distance ~= distance or distance > 2000 then
		return
	end
	cam.CFrame = CFrame.lookAt(center + Vector3.new(0, 0, distance), center, Vector3.new(0, 1, 0))
	cam.Focus = CFrame.new(center)
end

RunService:BindToRenderStep("PackvaniaSideCamera", Enum.RenderPriority.Camera.Value + 1, lockSideCamera)
lockSideCamera()

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Presentation = require(Shared:WaitForChild("ui"):WaitForChild("Presentation"))
local ProductPrice = require(Shared:WaitForChild("data"):WaitForChild("ProductPrice"))

local remotes = ReplicatedStorage:WaitForChild("PackvaniaRemotes")
local resultRemote = remotes:WaitForChild("PackOpenResult") :: RemoteEvent

local function fire(name: string, payload: { [string]: string })
	local remote = remotes:WaitForChild(name) :: RemoteEvent
	remote:FireServer(payload)
end

local screen = Instance.new("ScreenGui")
screen.Name = "Packvania"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = false
screen.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
screen.Parent = player:WaitForChild("PlayerGui")

local ink = Color3.fromRGB(236, 230, 214)
local gold = Color3.fromRGB(214, 176, 92)
local panelColor = Color3.fromRGB(22, 18, 38)
local buttonColor = Color3.fromRGB(70, 54, 120)

local function corner(parent: Instance, radius: number)
	local ui = Instance.new("UICorner")
	ui.CornerRadius = UDim.new(0, radius)
	ui.Parent = parent
end

local function label(parent: Instance, text: string, size: number, height: number): TextLabel
	local item = Instance.new("TextLabel")
	item.BackgroundTransparency = 1
	item.Font = Enum.Font.GothamMedium
	item.TextColor3 = ink
	item.TextSize = size
	item.TextXAlignment = Enum.TextXAlignment.Left
	item.TextWrapped = true
	item.Text = text
	item.Size = UDim2.new(1, -16, 0, height)
	item.Parent = parent
	return item
end

local function button(parent: Instance, text: string, width: number): TextButton
	local item = Instance.new("TextButton")
	item.AutoButtonColor = true
	item.Font = Enum.Font.GothamBold
	item.TextSize = 18
	item.TextColor3 = Color3.new(1, 1, 1)
	item.BackgroundColor3 = buttonColor
	item.Text = text
	item.Size = UDim2.fromOffset(width, 48)
	item.Parent = parent
	corner(item, 8)
	return item
end

local hud = Instance.new("Frame")
hud.Name = "Hud"
hud.BackgroundTransparency = 1
hud.Size = UDim2.fromScale(1, 1)
hud.Parent = screen

local top = Instance.new("Frame")
top.Name = "Top"
top.BackgroundColor3 = panelColor
top.BackgroundTransparency = 0.15
top.Size = UDim2.new(1, -24, 0, 78)
top.Position = UDim2.fromOffset(12, 12)
top.Parent = hud
corner(top, 12)
local title = label(top, "Packvania", 28, 32)
title.Position = UDim2.fromOffset(12, 6)
title.Font = Enum.Font.GothamBlack
local coins = label(top, "Coins 0", 18, 24)
coins.Position = UDim2.fromOffset(12, 40)
local realm = label(top, "Moon Courtyard", 18, 24)
realm.Position = UDim2.new(0.45, 0, 0, 40)
realm.TextXAlignment = Enum.TextXAlignment.Right
realm.Size = UDim2.new(0.5, -16, 0, 24)

local quests = Instance.new("Frame")
quests.Name = "Quests"
quests.BackgroundColor3 = panelColor
quests.BackgroundTransparency = 0.12
quests.Size = UDim2.fromOffset(280, 150)
quests.Position = UDim2.new(0, 12, 1, -230)
quests.Parent = hud
corner(quests, 12)
local questLayout = Instance.new("UIListLayout")
questLayout.Padding = UDim.new(0, 4)
questLayout.Parent = quests
local questPad = Instance.new("UIPadding")
questPad.PaddingTop = UDim.new(0, 8)
questPad.PaddingLeft = UDim.new(0, 8)
questPad.Parent = quests

local roster = Instance.new("Frame")
roster.Name = "Roster"
roster.BackgroundColor3 = panelColor
roster.BackgroundTransparency = 0.12
roster.Size = UDim2.fromOffset(240, 180)
roster.Position = UDim2.new(1, -252, 0, 100)
roster.Parent = hud
corner(roster, 12)
local rosterLayout = Instance.new("UIListLayout")
rosterLayout.Padding = UDim.new(0, 4)
rosterLayout.Parent = roster

local bar = Instance.new("ScrollingFrame")
bar.Name = "Actions"
bar.BackgroundTransparency = 1
bar.BorderSizePixel = 0
bar.ScrollBarThickness = 6
bar.ScrollingDirection = Enum.ScrollingDirection.X
bar.AutomaticCanvasSize = Enum.AutomaticSize.X
bar.CanvasSize = UDim2.new()
bar.Size = UDim2.new(1, -24, 0, 64)
bar.Position = UDim2.new(0, 12, 1, -76)
bar.Parent = hud
local barLayout = Instance.new("UIListLayout")
barLayout.FillDirection = Enum.FillDirection.Horizontal
barLayout.Padding = UDim.new(0, 8)
barLayout.Parent = bar

local function action(text: string, callback: () -> ())
	local item = button(bar, text, 180)
	item.Activated:Connect(callback)
	return item
end

local modal = Instance.new("Frame")
modal.Name = "Modal"
modal.Visible = false
modal.BackgroundColor3 = Color3.fromRGB(10, 8, 18)
modal.BackgroundTransparency = 0.08
modal.Size = UDim2.fromScale(1, 1)
modal.Parent = screen
local modalTitle = label(modal, "", 28, 36)
modalTitle.Position = UDim2.fromOffset(20, 16)
modalTitle.Font = Enum.Font.GothamBlack
local body = Instance.new("ScrollingFrame")
body.Name = "Body"
body.BackgroundTransparency = 1
body.BorderSizePixel = 0
body.ScrollBarThickness = 8
body.Size = UDim2.new(1, -40, 1, -140)
body.Position = UDim2.fromOffset(20, 60)
body.CanvasSize = UDim2.new()
body.AutomaticCanvasSize = Enum.AutomaticSize.Y
body.Parent = modal
local bodyLayout = Instance.new("UIListLayout")
bodyLayout.Padding = UDim.new(0, 8)
bodyLayout.Parent = body
local close = button(modal, "Close", 160)
close.Position = UDim2.new(1, -180, 1, -72)
close.Activated:Connect(function()
	modal.Visible = false
end)

local function clear(frame: Instance)
	for _, child in frame:GetChildren() do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
end

local function showLines(heading: string, lines: { string })
	modal.Visible = true
	modalTitle.Text = heading
	clear(body)
	for _, line in lines do
		local row = label(body, line, 18, 28)
		row.Size = UDim2.new(1, -8, 0, 28)
	end
	GuiService.SelectedObject = close
end

local latest: any = nil
local priceLine = "Robux price: unavailable from MarketplaceService"

local openButton = action("Open Night Pack", function()
	fire("OpenEarnedPack", { packId = "packvania.night" })
end)
local oddsButton = action("Odds / Details", function()
	if latest ~= nil then
		showLines("Odds / Details", latest.oddsLines)
	end
end)
local shopButton = action("Robux shop", function()
	if latest ~= nil then
		local lines = {}
		for line in string.gmatch(latest.shopText, "[^\n]+") do
			table.insert(lines, line)
		end
		table.insert(lines, priceLine)
		table.insert(lines, "Live purchase blocked")
		showLines("Moonlit Booster", lines)
	end
end)
local battleButton = action("Battle", function()
	if latest ~= nil then
		fire("StartWave", { waveId = latest.nextWaveId })
	end
end)
local prepareButton = action("Prepare", function()
	if latest == nil then
		return
	end
	local lines = { latest.equippedLabel, latest.realmName }
	for _, card in latest.cards do
		table.insert(lines, card.displayName .. " x" .. tostring(card.count) .. " rank " .. tostring(card.rank))
	end
	table.insert(lines, "Use the roster buttons to place and upgrade.")
	showLines("Prepare", lines)
end)
local motionButton = action("Motion: Full", function()
	local nextMotion = Presentation.cycle(Presentation.parse(player:GetAttribute("PackvaniaMotion")))
	player:SetAttribute("PackvaniaMotion", nextMotion)
	motionButton.Text = Presentation.motionLabel(nextMotion)
end)

local status = label(hud, "Enter the courtyard.", 18, 24)
status.Position = UDim2.new(0, 16, 0, 98)
status.Size = UDim2.new(0.5, 0, 0, 24)

local function paint(snapshot)
	latest = snapshot
	title.Text = snapshot.title
	coins.Text = "Coins " .. tostring(snapshot.coins) .. "   Mastery " .. tostring(snapshot.mastery)
	realm.Text = snapshot.realmName
	clear(quests)
	label(quests, "Goals", 18, 22).Font = Enum.Font.GothamBold
	for _, quest in snapshot.quests do
		local mark = if quest.done then "Done" else tostring(quest.progress) .. "/" .. tostring(quest.goal)
		label(quests, quest.label .. "  " .. mark, 16, 22)
	end
	clear(roster)
	label(roster, "Roster", 18, 22).Font = Enum.Font.GothamBold
	for _, card in snapshot.cards do
		if card.count > 0 then
			local row = button(roster, card.displayName .. " x" .. tostring(card.count), 220)
			row.Size = UDim2.new(1, -8, 0, 36)
			row.TextSize = 14
			row.Activated:Connect(function()
				fire("PlaceHero", { cardId = card.cardId, anchorId = "lane.mid" })
			end)
		end
	end
end

local function fit()
	local viewport = if camera ~= nil then camera.ViewportSize.Y else 800
	local height = Presentation.buttonHeight(viewport)
	local textSize = Presentation.bodyText(viewport)
	for _, child in bar:GetChildren() do
		if child:IsA("TextButton") then
			child.Size = UDim2.fromOffset(190, height)
			child.TextSize = math.min(textSize, 22)
		end
	end
end
if camera ~= nil then
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
end
fit()

local function reveal(cardName: string, kind: string)
	local motion = Presentation.parse(player:GetAttribute("PackvaniaMotion"))
	showLines("Packvania", { "PACK", cardName, kind .. " · provisional", "Foil is a preview. This pack does not roll foil." })
	if Presentation.revealSeconds(motion) > 0 then
		task.delay(Presentation.revealSeconds(motion), function()
			if modalTitle.Text == "Packvania" then
				modal.Visible = false
			end
		end)
	end
end

resultRemote.OnClientEvent:Connect(function(body)
	if type(body) ~= "table" then
		return
	end
	if body.snapshot ~= nil then
		paint(body.snapshot)
	end
	if body.reveal ~= nil then
		reveal(body.reveal.displayName, body.reveal.kind)
		status.Text = "Opened " .. body.reveal.displayName
		return
	end
	if body.kind == "combat" and body.resultLines ~= nil then
		showLines(if body.ok then "CLEARED" else "DEFEATED", body.resultLines)
		status.Text = if body.ok then "The tower held." else "The tower fell."
		return
	end
	if body.kind == "paid" then
		status.Text = "Paid purchase blocked: " .. tostring(body.code)
		return
	end
	if body.ok == false and body.code ~= nil then
		status.Text = tostring(body.code)
	elseif body.code == "Placed" then
		status.Text = "Placed on the middle pad."
	elseif body.code == "Upgraded" then
		status.Text = "Rank increased."
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB then
		modal.Visible = false
	end
end)

task.spawn(function()
	local productId = 3732907303
	local ok, info = pcall(function()
		return MarketplaceService:GetProductInfoAsync(productId, Enum.InfoType.Product)
	end)
	if ok then
		priceLine = ProductPrice.line(ProductPrice.fromInfo(info))
	end
end)

local upgradeButton = action("Upgrade Warden", function()
	fire("BuyUpgrade", { cardId = "packvania.warden" })
end)
local relicButton = action("Relics", function()
	if latest == nil then
		return
	end
	local lines = { latest.equippedLabel }
	for _, relic in latest.relics do
		local state = if not relic.discovered then "Hidden" elseif relic.equipped then "Equipped" else "Owned"
		table.insert(lines, relic.displayName .. " — " .. state)
	end
	showLines("Relics", lines)
end)
local bestiaryButton = action("Bestiary", function()
	if latest == nil then
		return
	end
	local lines = {}
	for _, enemy in latest.bestiary do
		table.insert(lines, if enemy.known then enemy.displayName else "???")
	end
	showLines("Bestiary", lines)
end)
local placeFront = action("Place Front", function()
	if latest == nil then
		return
	end
	for _, card in latest.cards do
		if card.count > 0 and card.kind == "Hero" then
			fire("PlaceHero", { cardId = card.cardId, anchorId = "lane.front" })
			return
		end
	end
end)
local placeBack = action("Place Spell", function()
	if latest == nil then
		return
	end
	for _, card in latest.cards do
		if card.count > 0 and card.kind == "Spell" then
			fire("PlaceHero", { cardId = card.cardId, anchorId = "lane.back" })
			return
		end
	end
end)
local chapelButton = action("Open Chapel", function()
	fire("OpenEarnedPack", { packId = "packvania.chapel" })
end)
local equipButton = action("Equip Cloak", function()
	fire("ToggleRelic", { relicId = "packvania.cloak" })
end)

oddsButton.Text = "Odds / Details"
shopButton.Text = "Robux shop"
upgradeButton.Text = "Upgrade Warden"

status.Text = "Open a Night Pack, place the Grave Warden, then battle."
