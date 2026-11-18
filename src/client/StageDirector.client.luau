--!strict
-- Plays the server combat preview. Damage and rewards already happened.

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local StageArt = require(Shared:WaitForChild("ui"):WaitForChild("StageArt"))
local Presentation = require(Shared:WaitForChild("ui"):WaitForChild("Presentation"))
local CameraFeel = require(Shared:WaitForChild("ui"):WaitForChild("CameraFeel"))

local map = Workspace:WaitForChild("Packvania", 30)
if map == nil then
	return
end

local playback = Instance.new("Folder")
playback.Name = "Playback"
playback.Parent = map
local bursts = Instance.new("Folder")
bursts.Name = "Bursts"
bursts.Parent = map

local playToken = 0

local function colorOf(spec): Color3
	return Color3.fromRGB(spec.r, spec.g, spec.b)
end

local function placePiece(parent: Instance, spec, ox: number, oy: number, oz: number)
	local pos = Vector3.new(spec.x + ox, spec.y + oy, spec.z + oz)
	local block = Instance.new("Part")
	block.Name = spec.name
	block.Anchored = true
	block.CanCollide = false
	block.CanQuery = false
	block.CanTouch = false
	block.CastShadow = false
	block.Size = Vector3.new(spec.sx, spec.sy, spec.sz)
	block.Color = colorOf(spec)
	block.Transparency = spec.transparency
	if spec.material == "Neon" then
		block.Material = Enum.Material.Neon
	elseif spec.material == "Slate" then
		block.Material = Enum.Material.Slate
	else
		block.Material = Enum.Material.SmoothPlastic
	end
	if spec.shape == "Cylinder" then
		block.Shape = Enum.PartType.Cylinder
	elseif spec.shape == "Ball" then
		block.Shape = Enum.PartType.Ball
	end
	block.CFrame = CFrame.new(pos) * CFrame.Angles(0, math.rad(spec.ry), 0)
	block:SetAttribute("ArtStatus", StageArt.status())
	block:SetAttribute("SourceArt", "UNKNOWN")
	block.Parent = parent
	return block
end

local function clearPlayback()
	playback:ClearAllChildren()
end

local function beam(x0: number, x1: number, y: number, color: Color3)
	local from = Instance.new("Part")
	from.Name = "ShotFrom"
	from.Anchored = true
	from.CanCollide = false
	from.CanQuery = false
	from.CanTouch = false
	from.Transparency = 1
	from.Size = Vector3.new(0.2, 0.2, 0.2)
	from.Position = Vector3.new(x0, y, 3.4)
	from.Parent = playback
	local to = from:Clone()
	to.Name = "ShotTo"
	to.Position = Vector3.new(x1, y, 3.4)
	to.Parent = playback
	local att0 = Instance.new("Attachment")
	att0.Parent = from
	local att1 = Instance.new("Attachment")
	att1.Parent = to
	local bolt = Instance.new("Beam")
	bolt.Attachment0 = att0
	bolt.Attachment1 = att1
	bolt.Width0 = 0.38
	bolt.Width1 = 0.1
	bolt.FaceCamera = true
	bolt.LightEmission = 0.85
	bolt.Color = ColorSequence.new(color)
	bolt.Parent = from
end

local function burst(x: number, y: number, color: Color3, count: number)
	if count <= 0 then
		return
	end
	local host = Instance.new("Part")
	host.Name = "Burst"
	host.Anchored = true
	host.CanCollide = false
	host.CanQuery = false
	host.CanTouch = false
	host.Transparency = 1
	host.Size = Vector3.new(0.4, 0.4, 0.4)
	host.Position = Vector3.new(x, y, 3.6)
	host.Parent = bursts
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Rate = 0
	emitter.Lifetime = NumberRange.new(0.16, 0.32)
	emitter.Speed = NumberRange.new(1.5, 4)
	emitter.SpreadAngle = Vector2.new(24, 24)
	emitter.LightEmission = 0.7
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.45),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Color = ColorSequence.new(color)
	emitter.Parent = host
	emitter:Emit(count)
	Debris:AddItem(host, 0.45)
end

local function drawFrame(frame, kind: string)
	clearPlayback()
	local feel = StageArt.feedback(kind, Presentation.parse(player:GetAttribute("PackvaniaMotion")))
	for _, enemy in frame.enemies do
		local x = StageArt.laneX(enemy.progress)
		for _, spec in StageArt.figure("enemy", enemy.enemyId) do
			local block = placePiece(playback, spec, x, StageArt.feetY(), 0)
			if not enemy.alive then
				block.Transparency = math.clamp(block.Transparency + 0.45, 0, 1)
			end
		end
		if not enemy.alive and feel.sparks > 0 then
			burst(x, StageArt.feetY() + 4, Color3.fromRGB(236, 220, 180), feel.sparks)
		end
	end
	for _, shot in frame.shots do
		local face = StageArt.cardFace(shot.cardId)
		local color = Color3.fromRGB(face.ar, face.ag, face.ab)
		beam(StageArt.laneX(shot.origin), StageArt.laneX(shot.progress), 14, color)
		if feel.flash then
			burst(StageArt.laneX(shot.progress), 14, color, feel.sparks)
		end
	end
	if kind == "leak" and feel.flash then
		burst(StageArt.laneX(StageArt.pathLength()), 16, Color3.fromRGB(214, 92, 92), feel.sparks)
	end
end

local function play(frames)
	playToken += 1
	local token = playToken
	clearPlayback()
	local motion = Presentation.parse(player:GetAttribute("PackvaniaMotion"))
	local previous = nil
	for _, frame in frames do
		if token ~= playToken then
			return
		end
		local kind = StageArt.frameKind(previous, frame)
		drawFrame(frame, kind)
		CameraFeel.add(StageArt.feedback(kind, motion).trauma, motion)
		local delay = StageArt.frameDelay(kind, motion)
		previous = frame
		if delay > 0 then
			task.wait(delay)
		end
	end
	if token == playToken then
		task.delay(0.2, function()
			if token == playToken then
				clearPlayback()
			end
		end)
	end
end

local remotes = ReplicatedStorage:WaitForChild("PackvaniaRemotes")
local resultRemote = remotes:WaitForChild("PackOpenResult") :: RemoteEvent
resultRemote.OnClientEvent:Connect(function(body)
	if type(body) ~= "table" or body.kind ~= "combat" or type(body.preview) ~= "table" then
		return
	end
	task.spawn(play, body.preview)
end)
