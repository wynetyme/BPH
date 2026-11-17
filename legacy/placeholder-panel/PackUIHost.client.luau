--!strict
-- Responsive pack ScreenGui. It asks the server to open. It never grants cards.

local GuiService = game:GetService("GuiService")
local HapticService = game:GetService("HapticService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local sharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
assert(sharedFolder, "Shared missing")
local uiFolder = sharedFolder:WaitForChild("ui", 10)
local dataFolder = sharedFolder:WaitForChild("data", 10)
local Reveal = require(uiFolder:WaitForChild("Reveal"))
local Presentation = require(uiFolder:WaitForChild("Presentation"))
local CombatUI = require(uiFolder:WaitForChild("CombatUI"))
local ProductPrice = require(dataFolder:WaitForChild("ProductPrice"))

local remotes = ReplicatedStorage:WaitForChild("BPHRemotes", 15)
assert(remotes, "BPHRemotes missing")
local openRemote = remotes:WaitForChild("OpenEarnedPack", 10) :: RemoteEvent
local entitlementRemote = remotes:WaitForChild("OpenEntitlement", 10) :: RemoteEvent
local paidRemote = remotes:WaitForChild("RequestPaidPack", 10) :: RemoteEvent
local placeRemote = remotes:WaitForChild("PlaceHero", 10) :: RemoteEvent
local waveRemote = remotes:WaitForChild("StartWave", 10) :: RemoteEvent
local upgradeRemote = remotes:WaitForChild("BuyUpgrade", 10) :: RemoteEvent
local resultRemote = remotes:WaitForChild("PackOpenResult", 10) :: RemoteEvent

local screen = Instance.new("ScreenGui")
screen.Name = "PackSlice"
screen.ResetOnSpawn = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
screen.Parent = playerGui

local root = Instance.new("ScrollingFrame")
root.Name = "Root"
root.Size = UDim2.fromScale(1, 1)
root.BackgroundColor3 = Color3.fromRGB(14, 18, 28)
root.BorderSizePixel = 0
root.ScrollBarThickness = 8
root.AutomaticCanvasSize = Enum.AutomaticSize.Y
root.CanvasSize = UDim2.new()
root.ScrollingDirection = Enum.ScrollingDirection.Y
root.Parent = screen

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 12)
padding.PaddingBottom = UDim.new(0, 12)
padding.PaddingLeft = UDim.new(0, 12)
padding.PaddingRight = UDim.new(0, 12)
padding.Parent = root

local column = Instance.new("UIListLayout")
column.FillDirection = Enum.FillDirection.Vertical
column.Padding = UDim.new(0, 8)
column.SortOrder = Enum.SortOrder.LayoutOrder
column.Parent = root

local function label(name: string, text: string, height: number, order: number): TextLabel
	local item = Instance.new("TextLabel")
	item.Name = name
	item.BackgroundTransparency = 1
	item.Size = UDim2.new(1, 0, 0, height)
	item.Font = Enum.Font.GothamMedium
	item.TextSize = 18
	item.TextColor3 = Color3.fromRGB(236, 232, 220)
	item.TextXAlignment = Enum.TextXAlignment.Left
	item.TextYAlignment = Enum.TextYAlignment.Top
	item.TextWrapped = true
	item.Text = text
	item.LayoutOrder = order
	item.Parent = root
	local limit = Instance.new("UITextSizeConstraint")
	limit.MinTextSize = 14
	limit.MaxTextSize = 22
	limit.Parent = item
	return item
end

local function button(name: string, text: string, order: number): TextButton
	local item = Instance.new("TextButton")
	item.Name = name
	item.Size = UDim2.new(1, 0, 0, 48)
	item.BackgroundColor3 = Color3.fromRGB(48, 78, 120)
	item.BorderSizePixel = 0
	item.Font = Enum.Font.GothamBold
	item.TextSize = 18
	item.TextColor3 = Color3.fromRGB(255, 255, 255)
	item.TextWrapped = true
	item.Text = text
	item.AutoButtonColor = true
	item.Active = true
	item.Selectable = true
	item.LayoutOrder = order
	item.Parent = root
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = item
	local limit = Instance.new("UITextSizeConstraint")
	limit.MinTextSize = 14
	limit.MaxTextSize = 22
	limit.Parent = item
	return item
end

label("Title", "Placeholder Starter Pack", 28, 1)
local coins = label("Coins", "Coins: …", 24, 2)
local status = label("Status", "Loading studio profile…", 44, 3)
local inventory = label("Inventory", "Inventory: empty", 72, 4)
local openButton = button("OpenPack", "Open earned pack", 6)
local oddsButton = button("OddsDetails", "Odds / Details", 7)
local foilButton = button("FoilPreview", "Preview foil (not a reward)", 8)
foilButton.BackgroundColor3 = Color3.fromRGB(92, 72, 28)
local shopButton = button("RobuxShop", "Robux shop", 9)
local battleButton = button("Battle", "Battle", 12)
local motionButton = button("Motion", "Motion: Full", 13)
motionButton.BackgroundColor3 = Color3.fromRGB(42, 58, 52)
local entitledButton = button("OpenEntitled", "Open entitled pack", 10)
entitledButton.Visible = false
local policyLabel = label("ClientPolicy", "Checking paid-random policy...", 48, 11)
local entitledId: string? = nil
local paidPackId: string? = nil
local nextWaveId = "placeholder.wave.1"
local gatePackId = "placeholder.gate"
local gateUnlocked = false
local listedProductId = 0
local freeOddsText = ""
local paidOddsText = ""
local priceRequest = 0
local motion: Presentation.Motion = Presentation.parse(player:GetAttribute("BPHMotion"))
motionButton.Text = Presentation.motionLabel(motion)

local cardRow = Instance.new("ScrollingFrame")
cardRow.Name = "CardRow"
cardRow.Size = UDim2.new(1, 0, 0, 148)
cardRow.BackgroundTransparency = 1
cardRow.BorderSizePixel = 0
cardRow.ScrollBarThickness = 6
cardRow.ScrollingDirection = Enum.ScrollingDirection.X
cardRow.AutomaticCanvasSize = Enum.AutomaticSize.X
cardRow.CanvasSize = UDim2.new()
cardRow.LayoutOrder = 5
cardRow.Parent = root
local cardLayout = Instance.new("UIListLayout")
cardLayout.FillDirection = Enum.FillDirection.Horizontal
cardLayout.Padding = UDim.new(0, 8)
cardLayout.SortOrder = Enum.SortOrder.LayoutOrder
cardLayout.Parent = cardRow

local detail = Instance.new("Frame")
detail.Name = "CardDetail"
detail.Visible = false
detail.AnchorPoint = Vector2.new(0.5, 1)
detail.Position = UDim2.new(0.5, 0, 1, -8)
detail.Size = UDim2.new(0.94, 0, 0, 156)
detail.BackgroundColor3 = Color3.fromRGB(22, 28, 40)
detail.BorderSizePixel = 0
detail.ZIndex = 4
detail.SelectionGroup = true
detail.Parent = screen
local detailCorner = Instance.new("UICorner")
detailCorner.CornerRadius = UDim.new(0, 10)
detailCorner.Parent = detail
local detailText = Instance.new("TextLabel")
detailText.Name = "DetailText"
detailText.BackgroundTransparency = 1
detailText.Position = UDim2.fromOffset(12, 10)
detailText.Size = UDim2.new(1, -24, 1, -64)
detailText.Font = Enum.Font.Gotham
detailText.TextSize = 18
detailText.TextColor3 = Color3.fromRGB(236, 232, 220)
detailText.TextWrapped = true
detailText.TextXAlignment = Enum.TextXAlignment.Left
detailText.TextYAlignment = Enum.TextYAlignment.Top
detailText.Text = ""
detailText.ZIndex = 4
detailText.Parent = detail
local detailClose = Instance.new("TextButton")
detailClose.Name = "CloseDetail"
detailClose.AnchorPoint = Vector2.new(0.5, 1)
detailClose.Position = UDim2.new(0.5, 0, 1, -8)
detailClose.Size = UDim2.new(0.92, 0, 0, 44)
detailClose.BackgroundColor3 = Color3.fromRGB(48, 78, 120)
detailClose.Font = Enum.Font.GothamBold
detailClose.TextSize = 18
detailClose.TextColor3 = Color3.fromRGB(255, 255, 255)
detailClose.Text = "Close"
detailClose.Selectable = true
detailClose.ZIndex = 4
detailClose.Parent = detail
local detailCloseCorner = Instance.new("UICorner")
detailCloseCorner.CornerRadius = UDim.new(0, 8)
detailCloseCorner.Parent = detailClose

local odds = Instance.new("Frame")
odds.Name = "OddsPanel"
odds.Visible = false
odds.Size = UDim2.fromScale(1, 1)
odds.BackgroundColor3 = Color3.fromRGB(10, 12, 18)
odds.BackgroundTransparency = 0.04
odds.BorderSizePixel = 0
odds.ZIndex = 5
odds.SelectionGroup = true
odds.Parent = screen

local oddsScroll = Instance.new("ScrollingFrame")
oddsScroll.Name = "OddsScroll"
oddsScroll.Size = UDim2.new(1, -24, 1, -80)
oddsScroll.Position = UDim2.fromOffset(12, 12)
oddsScroll.BackgroundTransparency = 1
oddsScroll.BorderSizePixel = 0
oddsScroll.ScrollBarThickness = 8
oddsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
oddsScroll.CanvasSize = UDim2.new()
oddsScroll.ZIndex = 6
oddsScroll.Parent = odds

local oddsText = Instance.new("TextLabel")
oddsText.Name = "OddsText"
oddsText.Size = UDim2.new(1, -8, 0, 0)
oddsText.AutomaticSize = Enum.AutomaticSize.Y
oddsText.BackgroundTransparency = 1
oddsText.Font = Enum.Font.Gotham
oddsText.TextSize = 16
oddsText.TextColor3 = Color3.fromRGB(236, 232, 220)
oddsText.TextWrapped = true
oddsText.TextXAlignment = Enum.TextXAlignment.Left
oddsText.TextYAlignment = Enum.TextYAlignment.Top
oddsText.Text = ""
oddsText.ZIndex = 6
oddsText.Parent = oddsScroll

local shop = Instance.new("Frame")
shop.Name = "ShopPanel"
shop.Visible = false
shop.Size = UDim2.fromScale(1, 1)
shop.BackgroundColor3 = Color3.fromRGB(10, 12, 18)
shop.BackgroundTransparency = 0.04
shop.BorderSizePixel = 0
shop.ZIndex = 5
shop.SelectionGroup = true
shop.Parent = screen

local shopScroll = Instance.new("ScrollingFrame")
shopScroll.Name = "ShopScroll"
shopScroll.Size = UDim2.new(1, -24, 1, -184)
shopScroll.Position = UDim2.fromOffset(12, 12)
shopScroll.BackgroundTransparency = 1
shopScroll.BorderSizePixel = 0
shopScroll.ScrollBarThickness = 8
shopScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
shopScroll.CanvasSize = UDim2.new()
shopScroll.ZIndex = 6
shopScroll.Parent = shop

local shopText = Instance.new("TextLabel")
shopText.Name = "ShopText"
shopText.Size = UDim2.new(1, -8, 0, 0)
shopText.AutomaticSize = Enum.AutomaticSize.Y
shopText.BackgroundTransparency = 1
shopText.Font = Enum.Font.Gotham
shopText.TextSize = 16
shopText.TextColor3 = Color3.fromRGB(236, 232, 220)
shopText.TextWrapped = true
shopText.TextXAlignment = Enum.TextXAlignment.Left
shopText.TextYAlignment = Enum.TextYAlignment.Top
shopText.Text = ""
shopText.LayoutOrder = 1
shopText.ZIndex = 6
shopText.Parent = shopScroll
local shopLayout = Instance.new("UIListLayout")
shopLayout.SortOrder = Enum.SortOrder.LayoutOrder
shopLayout.Padding = UDim.new(0, 8)
shopLayout.Parent = shopScroll

local shopPrice = Instance.new("TextLabel")
shopPrice.Name = "ShopPrice"
shopPrice.Size = UDim2.new(1, -8, 0, 0)
shopPrice.AutomaticSize = Enum.AutomaticSize.Y
shopPrice.BackgroundTransparency = 1
shopPrice.Font = Enum.Font.GothamBold
shopPrice.TextSize = 18
shopPrice.TextColor3 = Color3.fromRGB(255, 248, 230)
shopPrice.TextWrapped = true
shopPrice.TextXAlignment = Enum.TextXAlignment.Left
shopPrice.TextYAlignment = Enum.TextYAlignment.Top
shopPrice.Text = "Robux price: waiting for MarketplaceService"
shopPrice.LayoutOrder = 2
shopPrice.ZIndex = 6
shopPrice.Parent = shopScroll

local paidOddsButton = Instance.new("TextButton")
paidOddsButton.Name = "PaidOdds"
paidOddsButton.Size = UDim2.new(1, -24, 0, 48)
paidOddsButton.Position = UDim2.new(0, 12, 1, -172)
paidOddsButton.BackgroundColor3 = Color3.fromRGB(48, 78, 120)
paidOddsButton.Font = Enum.Font.GothamBold
paidOddsButton.TextSize = 18
paidOddsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
paidOddsButton.Text = "Odds / Details"
paidOddsButton.Selectable = true
paidOddsButton.ZIndex = 6
paidOddsButton.Parent = shop

local buyRobux = Instance.new("TextButton")
buyRobux.Name = "BuyRobux"
buyRobux.Size = UDim2.new(1, -24, 0, 48)
buyRobux.Position = UDim2.new(0, 12, 1, -116)
buyRobux.BackgroundColor3 = Color3.fromRGB(92, 72, 28)
buyRobux.Font = Enum.Font.GothamBold
buyRobux.TextSize = 18
buyRobux.TextColor3 = Color3.fromRGB(255, 255, 255)
buyRobux.TextWrapped = true
buyRobux.Text = "Live purchase blocked"
buyRobux.AutoButtonColor = false
buyRobux.Selectable = true
buyRobux.ZIndex = 6
buyRobux.Parent = shop

local closeShop = Instance.new("TextButton")
closeShop.Name = "CloseShop"
closeShop.Size = UDim2.new(1, -24, 0, 48)
closeShop.Position = UDim2.new(0, 12, 1, -60)
closeShop.BackgroundColor3 = Color3.fromRGB(48, 78, 120)
closeShop.Font = Enum.Font.GothamBold
closeShop.TextSize = 18
closeShop.TextColor3 = Color3.fromRGB(255, 255, 255)
closeShop.Text = "Close"
closeShop.Selectable = true
closeShop.ZIndex = 6
closeShop.Parent = shop

local closeOdds = Instance.new("TextButton")
closeOdds.Name = "CloseOdds"
closeOdds.Size = UDim2.new(1, -24, 0, 48)
closeOdds.Position = UDim2.new(0, 12, 1, -60)
closeOdds.BackgroundColor3 = Color3.fromRGB(48, 78, 120)
closeOdds.Font = Enum.Font.GothamBold
closeOdds.TextSize = 18
closeOdds.TextColor3 = Color3.fromRGB(255, 255, 255)
closeOdds.Text = "Close"
closeOdds.Selectable = true
closeOdds.ZIndex = 6
closeOdds.Parent = odds

local battle = Instance.new("Frame")
battle.Name = "BattlePanel"
battle.Visible = false
battle.Size = UDim2.fromScale(1, 1)
battle.BackgroundColor3 = Color3.fromRGB(10, 12, 18)
battle.BackgroundTransparency = 0.04
battle.BorderSizePixel = 0
battle.ZIndex = 6
battle.SelectionGroup = true
battle.Parent = screen

local meterHeader = Instance.new("Frame")
meterHeader.Name = "Meters"
meterHeader.Position = UDim2.fromOffset(12, 12)
meterHeader.Size = UDim2.new(1, -24, 0, 96)
meterHeader.BackgroundTransparency = 1
meterHeader.ZIndex = 7
meterHeader.Parent = battle

local function meterRow(name: string, y: number): (TextLabel, Frame)
	local rowLabel = Instance.new("TextLabel")
	rowLabel.Name = name .. "Label"
	rowLabel.BackgroundTransparency = 1
	rowLabel.Position = UDim2.fromOffset(0, y)
	rowLabel.Size = UDim2.new(1, -104, 0, 22)
	rowLabel.Font = Enum.Font.GothamMedium
	rowLabel.TextSize = 18
	rowLabel.TextColor3 = Color3.fromRGB(236, 232, 220)
	rowLabel.TextXAlignment = Enum.TextXAlignment.Left
	rowLabel.TextTruncate = Enum.TextTruncate.AtEnd
	rowLabel.Text = name
	rowLabel.ZIndex = 7
	rowLabel.Parent = meterHeader
	local track = Instance.new("Frame")
	track.Name = name .. "Track"
	track.Position = UDim2.fromOffset(0, y + 22)
	track.Size = UDim2.new(1, -104, 0, 16)
	track.BackgroundColor3 = Color3.fromRGB(32, 38, 52)
	track.BorderSizePixel = 0
	track.ZIndex = 7
	track.Parent = meterHeader
	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(0, 6)
	trackCorner.Parent = track
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = if name == "Tower" then Color3.fromRGB(126, 176, 214) else Color3.fromRGB(214, 176, 92)
	fill.BorderSizePixel = 0
	fill.ZIndex = 8
	fill.Parent = track
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 6)
	fillCorner.Parent = fill
	return rowLabel, fill
end

local towerLabel, towerFill = meterRow("Tower", 0)
local waveLabel, waveFill = meterRow("Wave", 46)

local impactView = Instance.new("ViewportFrame")
impactView.Name = "ImpactView"
impactView.BackgroundTransparency = 1
impactView.Position = UDim2.new(1, -96, 0, 8)
impactView.Size = UDim2.fromOffset(88, 80)
impactView.ZIndex = 8
impactView.Ambient = Color3.fromRGB(150, 150, 150)
impactView.LightColor = Color3.fromRGB(255, 236, 210)
impactView.Parent = meterHeader
local impactCamera = Instance.new("Camera")
impactCamera.CFrame = CFrame.new(0, 0, 8)
impactCamera.Parent = impactView
impactView.CurrentCamera = impactCamera
local impactWorld = Instance.new("WorldModel")
impactWorld.Parent = impactView
local impactHost = Instance.new("Part")
impactHost.Name = "ImpactHost"
impactHost.Anchored = true
impactHost.CanCollide = false
impactHost.CanQuery = false
impactHost.Transparency = 1
impactHost.Size = Vector3.new(0.4, 0.4, 0.4)
impactHost.Parent = impactWorld

local function impactEmitter(name: string, texture: string, color: Color3): ParticleEmitter
	local item = Instance.new("ParticleEmitter")
	item.Name = name
	item.Texture = texture
	item.Color = ColorSequence.new(color)
	item.Rate = 0
	item.Lifetime = NumberRange.new(0.18, 0.35)
	item.Speed = NumberRange.new(1, 4)
	item.SpreadAngle = Vector2.new(180, 180)
	item.LightInfluence = 1
	item.LightEmission = 0.15
	item.Rotation = NumberRange.new(0, 360)
	item.RotSpeed = NumberRange.new(-40, 40)
	item.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(1, 0.05),
	})
	item.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(1, 1),
	})
	item.Parent = impactHost
	return item
end

local sparkEmit = impactEmitter("Spark", "rbxasset://textures/particles/sparkles_main.dds", Color3.fromRGB(255, 214, 140))
local shadeEmit = impactEmitter("Shade", "rbxasset://textures/particles/smoke_main.dds", Color3.fromRGB(28, 24, 20))
shadeEmit.LightEmission = 0

local battleScroll = Instance.new("ScrollingFrame")
battleScroll.Name = "BattleScroll"
battleScroll.Position = UDim2.fromOffset(12, 116)
battleScroll.Size = UDim2.new(1, -24, 1, -196)
battleScroll.BackgroundTransparency = 1
battleScroll.BorderSizePixel = 0
battleScroll.ScrollBarThickness = 8
battleScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
battleScroll.CanvasSize = UDim2.new()
battleScroll.ZIndex = 7
battleScroll.Parent = battle

local battleText = Instance.new("TextLabel")
battleText.Name = "BattleText"
battleText.Size = UDim2.new(1, -8, 0, 0)
battleText.AutomaticSize = Enum.AutomaticSize.Y
battleText.BackgroundTransparency = 1
battleText.Font = Enum.Font.Gotham
battleText.TextSize = 18
battleText.TextColor3 = Color3.fromRGB(236, 232, 220)
battleText.TextWrapped = true
battleText.TextXAlignment = Enum.TextXAlignment.Left
battleText.TextYAlignment = Enum.TextYAlignment.Top
battleText.Text = "Battle loads with the profile."
battleText.ZIndex = 7
battleText.Parent = battleScroll

local battleActions = Instance.new("ScrollingFrame")
battleActions.Name = "BattleActions"
battleActions.AnchorPoint = Vector2.new(0, 1)
battleActions.Position = UDim2.new(0, 12, 1, -12)
battleActions.Size = UDim2.new(1, -24, 0, 64)
battleActions.BackgroundTransparency = 1
battleActions.BorderSizePixel = 0
battleActions.ScrollBarThickness = 6
battleActions.AutomaticCanvasSize = Enum.AutomaticSize.X
battleActions.CanvasSize = UDim2.new()
battleActions.ScrollingDirection = Enum.ScrollingDirection.X
battleActions.ZIndex = 7
battleActions.Parent = battle
local actionLayout = Instance.new("UIListLayout")
actionLayout.FillDirection = Enum.FillDirection.Horizontal
actionLayout.Padding = UDim.new(0, 8)
actionLayout.SortOrder = Enum.SortOrder.LayoutOrder
actionLayout.Parent = battleActions

local function battleButtonAt(name: string, text: string, order: number): TextButton
	local item = Instance.new("TextButton")
	item.Name = name
	item.LayoutOrder = order
	item.Size = UDim2.fromOffset(168, 48)
	item.BackgroundColor3 = Color3.fromRGB(48, 78, 120)
	item.Font = Enum.Font.GothamBold
	item.TextSize = 18
	item.TextColor3 = Color3.fromRGB(255, 255, 255)
	item.TextWrapped = true
	item.Text = text
	item.AutoButtonColor = true
	item.Selectable = true
	item.ZIndex = 7
	item.Parent = battleActions
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = item
	return item
end

local placeHero = battleButtonAt("PlaceHero", "Place Frontline", 1)
local fightWave = battleButtonAt("FightWave", "Fight wave", 2)
local upgradeHero = battleButtonAt("UpgradeHero", "Upgrade Frontline", 3)
local upgradeSpell = battleButtonAt("UpgradeBolt", "Upgrade Bolt", 4)
local buyGate = battleButtonAt("BuyGate", "Gate pack locked", 5)
local closeBattle = battleButtonAt("CloseBattle", "Close", 6)

local function paintMeter(meter: CombatUI.Meter?, rowLabel: TextLabel, fill: Frame)
	if meter == nil then
		return
	end
	rowLabel.Text = meter.label
	fill.Size = UDim2.fromScale(math.clamp(meter.fill, 0, 1), 1)
end

local function applyMeters(meters: { CombatUI.Meter })
	paintMeter(meters[1], towerLabel, towerFill)
	paintMeter(meters[2], waveLabel, waveFill)
end

applyMeters(CombatUI.meters(nil))

local reveal = Instance.new("Frame")
reveal.Name = "Reveal"
reveal.Visible = false
reveal.Size = UDim2.fromScale(1, 1)
reveal.BackgroundColor3 = Color3.fromRGB(6, 8, 14)
reveal.BackgroundTransparency = 0.15
reveal.BorderSizePixel = 0
reveal.ZIndex = 8
reveal.SelectionGroup = true
reveal.Parent = screen

local card = Instance.new("Frame")
card.Name = "Card"
card.AnchorPoint = Vector2.new(0.5, 0.5)
card.Position = UDim2.fromScale(0.5, 0.42)
card.Size = UDim2.fromScale(0.72, 0.42)
card.BackgroundColor3 = Color3.fromRGB(36, 44, 64)
card.BorderSizePixel = 0
card.ZIndex = 9
card.Parent = reveal
local cardCorner = Instance.new("UICorner")
cardCorner.CornerRadius = UDim.new(0, 12)
cardCorner.Parent = card
local stroke = Instance.new("UIStroke")
stroke.Name = "FoilStroke"
stroke.Thickness = 3
stroke.Color = Color3.fromRGB(214, 176, 92)
stroke.Enabled = false
stroke.Parent = card
local foilSheen = Instance.new("UIGradient")
foilSheen.Name = "FoilSheen"
foilSheen.Enabled = false
foilSheen.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 236, 186)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(126, 176, 214)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 236, 186)),
})
foilSheen.Parent = card

local packSeal = Instance.new("Frame")
packSeal.Name = "PackSeal"
packSeal.AnchorPoint = Vector2.new(0.5, 0.5)
packSeal.Position = UDim2.fromScale(0.5, 0.4)
packSeal.Size = UDim2.fromOffset(180, 230)
packSeal.BackgroundColor3 = Color3.fromRGB(164, 122, 74)
packSeal.BorderSizePixel = 0
packSeal.Visible = false
packSeal.ZIndex = 9
packSeal.Parent = reveal
local sealCorner = Instance.new("UICorner")
sealCorner.CornerRadius = UDim.new(0, 12)
sealCorner.Parent = packSeal
local seam = Instance.new("Frame")
seam.Name = "Seam"
seam.AnchorPoint = Vector2.new(0.5, 0)
seam.Position = UDim2.new(0.5, 0, 0, 28)
seam.Size = UDim2.new(0.72, 0, 0, 8)
seam.BackgroundColor3 = Color3.fromRGB(92, 64, 36)
seam.BorderSizePixel = 0
seam.ZIndex = 10
seam.Parent = packSeal
local sealLabel = Instance.new("TextLabel")
sealLabel.Name = "SealLabel"
sealLabel.BackgroundTransparency = 1
sealLabel.Size = UDim2.new(1, 0, 0, 40)
sealLabel.Position = UDim2.new(0, 0, 0.45, 0)
sealLabel.Font = Enum.Font.GothamBold
sealLabel.TextSize = 22
sealLabel.TextColor3 = Color3.fromRGB(255, 244, 220)
sealLabel.Text = "PACK"
sealLabel.ZIndex = 10
sealLabel.Parent = packSeal

local revealTitle = Instance.new("TextLabel")
revealTitle.Name = "RevealTitle"
revealTitle.BackgroundTransparency = 1
revealTitle.Size = UDim2.new(1, -24, 0, 80)
revealTitle.Position = UDim2.fromOffset(12, 24)
revealTitle.Font = Enum.Font.GothamBold
revealTitle.TextSize = 28
revealTitle.TextColor3 = Color3.fromRGB(255, 248, 230)
revealTitle.TextWrapped = true
revealTitle.Text = ""
revealTitle.ZIndex = 10
revealTitle.Parent = card

local revealKind = Instance.new("TextLabel")
revealKind.Name = "RevealKind"
revealKind.BackgroundTransparency = 1
revealKind.Size = UDim2.new(1, -24, 0, 32)
revealKind.Position = UDim2.fromOffset(12, 110)
revealKind.Font = Enum.Font.Gotham
revealKind.TextSize = 18
revealKind.TextColor3 = Color3.fromRGB(196, 206, 220)
revealKind.TextXAlignment = Enum.TextXAlignment.Left
revealKind.Text = ""
revealKind.ZIndex = 10
revealKind.Parent = card

local skip = button("SkipReveal", "Skip", 1)
skip.Parent = reveal
skip.AnchorPoint = Vector2.new(0.5, 1)
skip.Position = UDim2.new(0.5, 0, 1, -16)
skip.Size = UDim2.new(0.9, 0, 0, 48)
skip.ZIndex = 10

local activeTween: Tween? = nil
local revealToken = 0
local shakeToken = 0

local function playCue(id: string)
	local cue = Presentation.cue(id, motion)
	if cue.haptic <= 0 then
		return
	end
	pcall(function()
		if HapticService:IsVibrationSupported(Enum.UserInputType.Gamepad1) then
			HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small, cue.haptic)
			task.delay(cue.ms / 1000, function()
				HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small, 0)
			end)
		end
	end)
end

local function mountFace(parent: GuiObject, kind: string)
	local motif = Presentation.face(kind)
	local plate = Instance.new("Frame")
	plate.Name = "Face"
	plate.AnchorPoint = Vector2.new(0.5, 0)
	plate.Position = UDim2.new(0.5, 0, 0, 8)
	plate.Size = UDim2.fromOffset(48, 48)
	plate.BackgroundColor3 = if motif == "chevron" then Color3.fromRGB(92, 64, 28) else Color3.fromRGB(28, 52, 78)
	plate.BorderSizePixel = 0
	plate.ZIndex = parent.ZIndex + 1
	plate.Parent = parent
	local plateCorner = Instance.new("UICorner")
	plateCorner.CornerRadius = UDim.new(0, 8)
	plateCorner.Parent = plate
	if motif == "shield" then
		local gem = Instance.new("Frame")
		gem.Name = "Shield"
		gem.AnchorPoint = Vector2.new(0.5, 0.5)
		gem.Position = UDim2.fromScale(0.5, 0.5)
		gem.Size = UDim2.fromOffset(18, 18)
		gem.Rotation = 45
		gem.BackgroundColor3 = Color3.fromRGB(126, 176, 214)
		gem.BorderSizePixel = 0
		gem.ZIndex = plate.ZIndex + 1
		gem.Parent = plate
	else
		local function slash(name: string, rotation: number, x: number)
			local bar = Instance.new("Frame")
			bar.Name = name
			bar.AnchorPoint = Vector2.new(0.5, 0.5)
			bar.Position = UDim2.new(0.5, x, 0.5, 0)
			bar.Size = UDim2.fromOffset(22, 6)
			bar.Rotation = rotation
			bar.BackgroundColor3 = Color3.fromRGB(232, 186, 96)
			bar.BorderSizePixel = 0
			bar.ZIndex = plate.ZIndex + 1
			bar.Parent = plate
		end
		slash("ChevronLeft", 38, -6)
		slash("ChevronRight", -38, 6)
	end
end

local function cancelRevealTween()
	if activeTween ~= nil then
		activeTween:Cancel()
		activeTween = nil
	end
end

local function hideReveal()
	revealToken += 1
	cancelRevealTween()
	reveal.Visible = false
	packSeal.Visible = false
end

local function playImpact(survived: boolean)
	local spec = Presentation.impact(motion, survived)
	playCue(spec.cue)
	shakeToken += 1
	local token = shakeToken
	task.spawn(function()
		if spec.hold > 0 then
			task.wait(spec.hold)
		end
		if token ~= shakeToken then
			return
		end
		if spec.flash then
			impactView.BackgroundColor3 = Color3.fromRGB(255, 244, 230)
			impactView.BackgroundTransparency = 0.4
			task.delay(0.08, function()
				if token == shakeToken then
					impactView.BackgroundTransparency = 1
				end
			end)
		end
		if spec.particles > 0 then
			sparkEmit:Emit(spec.particles)
			shadeEmit:Emit(math.max(1, math.floor(spec.particles / 2)))
		end
		local trauma = spec.trauma
		local last = os.clock()
		while trauma > 0.02 and token == shakeToken do
			local now = os.clock()
			trauma = Presentation.decayTrauma(trauma, now - last, 1.2)
			last = now
			local offset = Presentation.shakeOffset(trauma, now, 1)
			impactView.Position = UDim2.new(1, -96 + offset.x, 0, 8 + offset.y)
			task.wait()
		end
		if token == shakeToken then
			impactView.Position = UDim2.new(1, -96, 0, 8)
		end
	end)
end

local function playReveal(displayName: string, kind: string, foil: boolean, preview: boolean)
	local described = Reveal.describe(displayName, kind, foil, preview)
	revealToken += 1
	local token = revealToken
	cancelRevealTween()
	local oldFace = card:FindFirstChild("Face")
	if oldFace ~= nil then
		oldFace:Destroy()
	end
	mountFace(card, described.kind)
	local face = card:FindFirstChild("Face")
	if face ~= nil and face:IsA("GuiObject") then
		face.AnchorPoint = Vector2.new(1, 1)
		face.Position = UDim2.new(1, -12, 1, -12)
	end
	reveal.Visible = true
	stroke.Enabled = described.foil
	foilSheen.Enabled = described.foil and motion ~= "reduced"
	card.BackgroundColor3 = if described.foil then Color3.fromRGB(72, 58, 24) else Color3.fromRGB(36, 44, 64)
	revealTitle.Text = described.displayName
	revealKind.Text = Reveal.banner(described) .. " · " .. described.kind .. " · provisional"
	local steps = Presentation.revealSteps(motion, described.foil)
	playCue(if described.foil then "foil" else "rip")
	if foilSheen.Enabled and motion == "full" then
		foilSheen.Offset = Vector2.new(-1, 0)
		local sheen = TweenService:Create(foilSheen, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Offset = Vector2.new(1, 0),
		})
		sheen:Play()
	end
	task.spawn(function()
		for _, step in steps do
			if token ~= revealToken then
				return
			end
			local showingCard = step.id ~= "rip"
			packSeal.Visible = not showingCard
			card.Visible = showingCard
			local goal = if step.scale >= 1 then UDim2.fromScale(0.72, 0.42) else UDim2.fromScale(0.62, 0.34)
			if step.seconds <= 0 then
				card.Size = UDim2.fromScale(0.72, 0.42)
			else
				if step.id == "open" then
					card.Size = UDim2.fromScale(0.4, 0.22)
				end
				local tween = TweenService:Create(card, TweenInfo.new(step.seconds, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
					Size = goal,
				})
				activeTween = tween
				tween:Play()
				tween.Completed:Wait()
			end
		end
		if token == revealToken then
			card.Size = UDim2.fromScale(0.72, 0.42)
			packSeal.Visible = false
			card.Visible = true
			playCue("reveal")
		end
	end)
	GuiService.SelectedObject = skip
end

local function rebuildCards(cards: any)
	for _, child in cardRow:GetChildren() do
		if child:IsA("GuiButton") then
			child:Destroy()
		end
	end
	if type(cards) ~= "table" then
		return
	end
	for index, entry in cards do
		if type(entry) == "table" then
			local displayName = tostring(entry.displayName)
			local kind = tostring(entry.kind)
			local count = if type(entry.count) == "number" then entry.count else 0
			local rank = if type(entry.rank) == "number" then entry.rank else 0
			local item = Instance.new("TextButton")
			item.Name = "OwnedCard"
			item.LayoutOrder = index
			item.Size = UDim2.fromOffset(128, 132)
			item.BackgroundColor3 = Color3.fromRGB(28, 36, 52)
			item.BorderSizePixel = 0
			item.Text = ""
			item.AutoButtonColor = true
			item.Selectable = true
			item.Parent = cardRow
			local itemCorner = Instance.new("UICorner")
			itemCorner.CornerRadius = UDim.new(0, 8)
			itemCorner.Parent = item
			mountFace(item, kind)
			local caption = Instance.new("TextLabel")
			caption.Name = "Caption"
			caption.BackgroundTransparency = 1
			caption.AnchorPoint = Vector2.new(0, 1)
			caption.Position = UDim2.new(0, 6, 1, -6)
			caption.Size = UDim2.new(1, -12, 0, 40)
			caption.Font = Enum.Font.GothamMedium
			caption.TextSize = 18
			caption.TextColor3 = Color3.fromRGB(236, 232, 220)
			caption.TextWrapped = true
			caption.Text = displayName
			caption.ZIndex = item.ZIndex + 1
			caption.Parent = item
			local function showDetail()
				detailText.Text = Presentation.cardDetail(displayName, kind, count, rank)
				detail.Visible = true
				playCue("hover")
			end
			item.MouseEnter:Connect(showDetail)
			item.SelectionGained:Connect(showDetail)
			item.Activated:Connect(showDetail)
		end
	end
end

local function showSnapshot(body: { [string]: any })
	local snap = body.snapshot
	if type(snap) ~= "table" then
		return
	end
	coins.Text = "Coins: " .. tostring(snap.coins) .. " (starter grant provisional)"
	local lines = {}
	local cards = snap.cards
	if type(cards) == "table" and #cards > 0 then
		for _, entry in cards do
			table.insert(lines, tostring(entry.count) .. "x " .. tostring(entry.displayName) .. " (" .. tostring(entry.kind) .. ")")
		end
	else
		table.insert(lines, "empty")
	end
	inventory.Text = "Inventory: " .. table.concat(lines, ", ")
	rebuildCards(cards)
	if type(snap.oddsLines) == "table" then
		freeOddsText = table.concat(snap.oddsLines, "\n")
		if not odds.Visible then
			oddsText.Text = freeOddsText
		end
	end
	if type(snap.paidOddsLines) == "table" then
		paidOddsText = table.concat(snap.paidOddsLines, "\n")
	end
	if type(snap.shopText) == "string" then
		shopText.Text = snap.shopText
	end
	if type(snap.paidPackId) == "string" then
		paidPackId = snap.paidPackId
	end
	if type(snap.developerProductId) == "number" and snap.developerProductId >= 1 and snap.developerProductId ~= listedProductId then
		listedProductId = snap.developerProductId
		priceRequest += 1
		local requestId = priceRequest
		local productId = listedProductId
		task.spawn(function()
			local ok, info = pcall(function()
				return MarketplaceService:GetProductInfoAsync(productId, Enum.InfoType.Product)
			end)
			if requestId ~= priceRequest then
				return
			end
			local quote = ProductPrice.fromInfo(if ok then info else nil)
			shopPrice.Text = ProductPrice.line(quote)
		end)
	end
	entitledId = nil
	entitledButton.Visible = false
	local unopened = snap.unopened
	if type(unopened) == "table" and unopened[1] ~= nil and type(unopened[1].id) == "string" then
		entitledId = unopened[1].id
		entitledButton.Visible = true
		entitledButton.Text = "Open entitled pack"
	end
	if type(snap.combatText) == "string" then
		battleText.Text = snap.combatText
	end
	if type(snap.nextWaveId) == "string" then
		nextWaveId = snap.nextWaveId
	end
	if type(snap.gatePackId) == "string" then
		gatePackId = snap.gatePackId
	end
	gateUnlocked = snap.gateUnlocked == true
	buyGate.Text = if gateUnlocked then "Buy gate pack" else "Gate pack locked"
end

openButton.Activated:Connect(function()
	status.Text = "Opening on the server…"
	openRemote:FireServer({ packId = "placeholder.starter" })
end)

oddsButton.Activated:Connect(function()
	oddsText.Text = freeOddsText
	odds.ZIndex = 5
	odds.Visible = true
	GuiService.SelectedObject = closeOdds
end)
closeOdds.Activated:Connect(function()
	odds.Visible = false
end)
foilButton.Activated:Connect(function()
	playReveal("Placeholder Frontline", "Hero", true, true)
end)
shopButton.Activated:Connect(function()
	shop.Visible = true
	GuiService.SelectedObject = paidOddsButton
end)
battleButton.Activated:Connect(function()
	battle.Visible = true
	GuiService.SelectedObject = placeHero
end)
closeBattle.Activated:Connect(function()
	battle.Visible = false
end)
placeHero.Activated:Connect(function()
	status.Text = "Placing on the server..."
	placeRemote:FireServer({ cardId = "placeholder.frontline", anchorId = "lane.mid" })
end)
fightWave.Activated:Connect(function()
	status.Text = "Fighting on the server..."
	waveRemote:FireServer({ waveId = nextWaveId })
end)
upgradeHero.Activated:Connect(function()
	status.Text = "Upgrading on the server..."
	upgradeRemote:FireServer({ cardId = "placeholder.frontline" })
end)
upgradeSpell.Activated:Connect(function()
	status.Text = "Upgrading on the server..."
	upgradeRemote:FireServer({ cardId = "placeholder.bolt" })
end)
buyGate.Activated:Connect(function()
	if not gateUnlocked then
		status.Text = "Gate pack locked"
		return
	end
	status.Text = "Buying the gate pack on the server..."
	openRemote:FireServer({ packId = gatePackId })
end)
closeShop.Activated:Connect(function()
	shop.Visible = false
end)
paidOddsButton.Activated:Connect(function()
	oddsText.Text = paidOddsText
	odds.ZIndex = 7
	odds.Visible = true
	GuiService.SelectedObject = closeOdds
end)
buyRobux.Activated:Connect(function()
	if paidPackId == nil then
		status.Text = "Paid purchase blocked: ShopNotReady"
		return
	end
	status.Text = "Asking the server about Robux..."
	paidRemote:FireServer({ packId = paidPackId })
end)
entitledButton.Activated:Connect(function()
	if entitledId == nil then
		return
	end
	status.Text = "Opening entitled pack on the server..."
	entitlementRemote:FireServer({ entitlementId = entitledId })
end)
task.spawn(function()
	local ok, info = pcall(function()
		return PolicyService:GetPolicyInfoForPlayerAsync(player)
	end)
	if not ok or type(info) ~= "table" or type(info.ArePaidRandomItemsRestricted) ~= "boolean" then
		policyLabel.Text = "Client policy unknown. Paid purchase stays off."
		return
	end
	if info.ArePaidRandomItemsRestricted then
		policyLabel.Text = "Paid random items are restricted. Earned packs stay available."
	else
		policyLabel.Text = "Client policy loaded. Live Robux purchase stays off."
	end
end)
skip.Activated:Connect(hideReveal)

resultRemote.OnClientEvent:Connect(function(body: any)
	if type(body) ~= "table" then
		return
	end
	showSnapshot(body)
	if body.kind == "combat" then
		if type(body.summary) == "string" then
			battleText.Text = body.summary
		end
		if body.code == "TowerSurvived" then
			status.Text = "Tower survived."
		elseif body.code == "TowerFell" then
			status.Text = "Tower fell."
		elseif body.code == "Placed" then
			status.Text = "Hero placed."
		elseif body.code == "Upgraded" then
			status.Text = "Upgrade applied."
		else
			status.Text = "Combat: " .. tostring(body.code)
		end
		if type(body.combat) == "table" then
			applyMeters(CombatUI.meters({
				seed = if type(body.combat.seed) == "number" then body.combat.seed else 0,
				ticks = if type(body.combat.ticks) == "number" then body.combat.ticks else 0,
				damageDealt = if type(body.combat.damageDealt) == "number" then body.combat.damageDealt else 0,
				survived = body.combat.survived == true,
				towerHp = if type(body.combat.towerHp) == "number" then body.combat.towerHp else nil,
			}))
			if body.code == "TowerSurvived" or body.code == "TowerFell" then
				playImpact(body.combat.survived == true)
			end
		end
		return
	end
	if body.allowPrompt == true and type(body.productId) == "number" and body.productId >= 1 then
		MarketplaceService:PromptProductPurchase(player, body.productId)
	end
	if body.kind == "paid" then
		status.Text = "Paid purchase blocked: " .. tostring(body.code)
		return
	end
	if body.ok == true and type(body.reveal) == "table" then
		status.Text = "Added " .. tostring(body.reveal.displayName)
		playReveal(body.reveal.displayName, body.reveal.kind, body.reveal.foil == true, false)
	elseif body.ok == false then
		status.Text = "Could not open: " .. tostring(body.code)
	else
		status.Text = "Profile ready. Paid rolls are off."
	end
end)

motionButton.Activated:Connect(function()
	motion = Presentation.cycle(motion)
	motionButton.Text = Presentation.motionLabel(motion)
	player:SetAttribute("BPHMotion", motion)
	playCue("press")
end)
detailClose.Activated:Connect(function()
	detail.Visible = false
end)

local function fitViewport()
	local camera = workspace.CurrentCamera
	if camera == nil then
		return
	end
	local textSize = Presentation.bodyText(camera.ViewportSize.Y)
	local height = Presentation.buttonHeight(camera.ViewportSize.Y)
	for _, inst in screen:GetDescendants() do
		if inst:IsA("TextLabel") or inst:IsA("TextButton") then
			if inst.Name == "RevealTitle" or inst.Name == "SealLabel" then
				inst.TextSize = textSize + 8
			else
				inst.TextSize = textSize
			end
		end
		if inst:IsA("TextButton") and inst.Parent == root then
			inst.Size = UDim2.new(1, 0, 0, height)
		end
		if inst:IsA("TextButton") and inst.Parent == battleActions then
			inst.Size = UDim2.fromOffset(168, height)
		end
	end
end

local function bindViewport(camera: Camera)
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(fitViewport)
	fitViewport()
end

if workspace.CurrentCamera ~= nil then
	bindViewport(workspace.CurrentCamera)
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	local camera = workspace.CurrentCamera
	if camera ~= nil then
		bindViewport(camera)
	end
end)

UserInputService.InputBegan:Connect(function(input: InputObject)
	if input.KeyCode ~= Enum.KeyCode.Escape and input.KeyCode ~= Enum.KeyCode.ButtonB then
		return
	end
	if reveal.Visible then
		hideReveal()
	elseif odds.Visible then
		odds.Visible = false
	elseif shop.Visible then
		shop.Visible = false
	elseif battle.Visible then
		battle.Visible = false
	elseif detail.Visible then
		detail.Visible = false
	end
end)
