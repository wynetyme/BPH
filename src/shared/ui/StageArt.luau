--!strict
-- Original placeholder presentation. Source-game illustrations, poses, and colors are UNKNOWN.
-- Piece positions do not change combat progress, damage, odds, or receipts.

local CardDefinitions = require("../data/CardDefinitions")
local CombatTables = require("../data/CombatTables")
local Presentation = require("./Presentation")

export type Light = {
	brightness: number,
	range: number,
	r: number,
	g: number,
	b: number,
}

export type Piece = {
	name: string,
	sx: number,
	sy: number,
	sz: number,
	x: number,
	y: number,
	z: number,
	r: number,
	g: number,
	b: number,
	shape: string,
	material: string,
	transparency: number,
	ry: number,
	light: Light?,
}

export type CardFace = {
	displayName: string,
	kind: string,
	motif: string,
	badge: string,
	note: string,
	r: number,
	g: number,
	b: number,
	ar: number,
	ag: number,
	ab: number,
}

export type Feedback = {
	trauma: number,
	pause: number,
	flash: boolean,
	sparks: number,
}

export type PreviewEnemy = {
	enemyId: string,
	progress: number,
	hp: number,
	alive: boolean,
}

export type PreviewShot = {
	cardId: string,
	origin: number,
	progress: number,
}

export type PreviewFrame = {
	tick: number,
	towerHp: number,
	killed: number,
	leaked: number,
	enemies: { PreviewEnemy },
	shots: { PreviewShot },
}

local SPAWN_X = 40
local TOWER_X = -28

local StageArt = {}

local function piece(
	name: string,
	sx: number,
	sy: number,
	sz: number,
	x: number,
	y: number,
	z: number,
	r: number,
	g: number,
	b: number,
	shape: string?,
	material: string?,
	transparency: number?,
	ry: number?,
	light: Light?
): Piece
	return {
		name = name,
		sx = sx,
		sy = sy,
		sz = sz,
		x = x,
		y = y,
		z = z,
		r = r,
		g = g,
		b = b,
		shape = if shape == nil then "Block" else shape,
		material = if material == nil then "SmoothPlastic" else material,
		transparency = if transparency == nil then 0 else transparency,
		ry = if ry == nil then 0 else ry,
		light = light,
	}
end

function StageArt.status(): string
	return "PLACEHOLDER"
end

function StageArt.caption(): string
	return "Placeholder art. Source-game look is UNKNOWN."
end

function StageArt.pathLength(): number
	return CombatTables.pathLength()
end

function StageArt.laneX(progress: number): number
	local path = StageArt.pathLength()
	return SPAWN_X + (progress / path) * (TOWER_X - SPAWN_X)
end

function StageArt.anchorX(anchorId: string): number?
	local progress = CombatTables.anchor(anchorId)
	if progress == nil then
		return nil
	end
	return StageArt.laneX(progress)
end

function StageArt.feetY(): number
	return 9
end

function StageArt.view(): { centerX: number, centerY: number, width: number, height: number }
	return { centerX = 0, centerY = 22, width = 100, height = 54 }
end

function StageArt.lighting()
	return {
		globalShadows = false,
		brightness = 1.1,
		clockTime = 18.4,
		fogStart = 90,
		fogEnd = 260,
		ambient = { 118, 112, 150 },
		outdoor = { 92, 88, 128 },
		fog = { 18, 16, 36 },
	}
end

local FACES: { [string]: { panel: { number }, accent: { number } } } = {
	["packvania.warden"] = { panel = { 48, 36, 28 }, accent = { 214, 176, 92 } },
	["packvania.bolt"] = { panel = { 24, 32, 58 }, accent = { 186, 214, 255 } },
	["packvania.keeper"] = { panel = { 36, 26, 48 }, accent = { 176, 140, 214 } },
	["packvania.gargoyle"] = { panel = { 42, 42, 48 }, accent = { 186, 186, 196 } },
}

function StageArt.cardFace(cardId: string): CardFace
	local card = CardDefinitions.get(cardId)
	local known = FACES[cardId]
	local panel = if known ~= nil then known.panel else { 40, 28, 48 }
	local accent = if known ~= nil then known.accent else { 200, 80, 160 }
	return {
		displayName = if card ~= nil then card.displayName else cardId,
		kind = if card ~= nil then card.kind else "Hero",
		motif = if card ~= nil then card.motif else "placeholder",
		badge = "PLACEHOLDER",
		note = "Source-game card art is UNKNOWN.",
		r = panel[1],
		g = panel[2],
		b = panel[3],
		ar = accent[1],
		ag = accent[2],
		ab = accent[3],
	}
end

function StageArt.feedback(kind: string, motion: string): Feedback
	if motion == "reduced" then
		return { trauma = 0, pause = 0, flash = false, sparks = 0 }
	end
	if kind == "leak" or kind == "clear" then
		return { trauma = 0.8, pause = 0.1, flash = true, sparks = 16 }
	end
	if kind == "kill" then
		return { trauma = 0.7, pause = 0.08, flash = true, sparks = 14 }
	end
	if kind == "hit" then
		return { trauma = 0.35, pause = 0.04, flash = true, sparks = 8 }
	end
	return { trauma = 0, pause = 0, flash = false, sparks = 0 }
end

function StageArt.frameKind(previous: PreviewFrame?, frame: PreviewFrame): string
	local prevKilled = if previous == nil then 0 else previous.killed
	local prevLeaked = if previous == nil then 0 else previous.leaked
	if frame.leaked > prevLeaked then
		return "leak"
	end
	if frame.killed > prevKilled then
		return "kill"
	end
	if #frame.shots > 0 then
		return "hit"
	end
	return "tick"
end

function StageArt.frameDelay(kind: string, motion: string): number
	return Presentation.combatTickSeconds(motion) + StageArt.feedback(kind, motion).pause
end

function StageArt.playbackSeconds(frames: { PreviewFrame }, motion: string): number
	local total = 0
	local previous: PreviewFrame? = nil
	for _, frame in frames do
		total += StageArt.frameDelay(StageArt.frameKind(previous, frame), motion)
		previous = frame
	end
	return total
end

local function add(list: { Piece }, item: Piece)
	table.insert(list, item)
end

local FIGURES: { [string]: { Piece } } = {
	["card:packvania.warden"] = {
		piece("WardenCloak", 3.2, 7.2, 1.2, 0, 4.2, 0, 72, 62, 108, "Block", "SmoothPlastic", 0, 0, nil),
		piece("WardenHead", 1.8, 1.8, 1.2, 0, 8.6, 0.1, 228, 214, 190, "Block", "SmoothPlastic", 0, 0, nil),
		piece("WardenShield", 0.5, 3.4, 2.2, -1.8, 4.4, 0.2, 214, 176, 92, "Block", "Neon", 0, 0, nil),
		piece("WardenSpear", 0.35, 8.4, 0.35, 1.5, 5.2, 0, 196, 186, 160, "Block", "Slate", 0, 0, nil),
	},
	["card:packvania.bolt"] = {
		piece("BoltStaff", 0.35, 7.5, 0.35, 0, 4.2, 0, 186, 170, 130, "Block", "Slate", 0, 0, nil),
		piece("BoltOrb", 1.8, 1.8, 1.8, 0, 8.4, 0, 186, 214, 255, "Ball", "Neon", 0, 0, nil),
		piece("BoltChevron", 2.4, 0.45, 0.4, 0.2, 6.2, 0.2, 236, 226, 196, "Block", "Neon", 0, 0, nil),
		piece("BoltChevronLow", 1.6, 0.35, 0.35, 0.6, 5.4, 0.2, 236, 226, 196, "Block", "Neon", 0, 0, nil),
	},
	["card:packvania.keeper"] = {
		piece("KeeperBody", 2.2, 6.4, 1.1, 0, 4, 0, 58, 42, 84, "Block", "SmoothPlastic", 0, 0, nil),
		piece("KeeperHead", 1.5, 1.5, 1.1, 0, 7.8, 0.1, 210, 196, 176, "Block", "SmoothPlastic", 0, 0, nil),
		piece("KeeperWingL", 3.6, 1.6, 0.35, -2.2, 5.6, 0, 36, 28, 58, "Block", "SmoothPlastic", 0, 0, nil),
		piece("KeeperWingR", 3.6, 1.6, 0.35, 2.2, 5.2, 0, 36, 28, 58, "Block", "SmoothPlastic", 0, 0, nil),
	},
	["card:packvania.gargoyle"] = {
		piece("GargoyleBody", 3.6, 4.2, 1.6, 0, 2.8, 0, 128, 128, 138, "Block", "Slate", 0, 0, nil),
		piece("GargoyleHead", 2.2, 1.8, 1.4, 0.4, 5.4, 0.1, 146, 146, 156, "Block", "Slate", 0, 0, nil),
		piece("GargoyleHornL", 0.4, 1.4, 0.4, -0.4, 6.6, 0, 96, 96, 108, "Block", "Slate", 0, 0, nil),
		piece("GargoyleHornR", 0.4, 1.4, 0.4, 1.1, 6.6, 0, 96, 96, 108, "Block", "Slate", 0, 0, nil),
		piece("GargoyleWing", 4.2, 1.2, 0.4, 0, 4.2, -0.2, 108, 108, 120, "Block", "Slate", 0, 0, nil),
	},
	["enemy:shade"] = {
		piece("ShadeBody", 2.2, 7.4, 1, 0, 4.2, 0, 16, 12, 28, "Block", "SmoothPlastic", 0.12, 0, nil),
		piece("ShadeHood", 2.6, 1.4, 1.1, 0, 7.6, 0, 10, 8, 20, "Block", "SmoothPlastic", 0, 0, nil),
		piece("ShadeEyeL", 0.28, 0.28, 0.3, -0.4, 6.6, 0.4, 186, 220, 255, "Ball", "Neon", 0, 0, nil),
		piece("ShadeEyeR", 0.28, 0.28, 0.3, 0.4, 6.6, 0.4, 186, 220, 255, "Ball", "Neon", 0, 0, nil),
	},
	["enemy:bat"] = {
		piece("BatBody", 1.4, 1.1, 1.2, 0, 7.2, 0, 48, 36, 64, "Ball", "SmoothPlastic", 0, 0, nil),
		piece("BatWingL", 3.4, 0.45, 0.3, -2, 7.3, 0, 86, 64, 120, "Block", "SmoothPlastic", 0, 0, nil),
		piece("BatWingR", 3.4, 0.45, 0.3, 2, 7.1, 0, 86, 64, 120, "Block", "SmoothPlastic", 0, 0, nil),
		piece("BatEar", 0.3, 0.7, 0.3, 0.3, 8, 0, 36, 28, 52, "Block", "SmoothPlastic", 0, 0, nil),
	},
	["enemy:hound"] = {
		piece("HoundBody", 4.6, 1.8, 1.3, 0, 1.6, 0, 112, 52, 52, "Block", "SmoothPlastic", 0, 0, nil),
		piece("HoundHead", 1.6, 1.5, 1.2, -2.2, 2.4, 0.1, 92, 40, 42, "Block", "SmoothPlastic", 0, 0, nil),
		piece("HoundTail", 1.4, 0.35, 0.35, 2.6, 2.2, 0, 84, 36, 40, "Block", "SmoothPlastic", 0, 0, nil),
		piece("HoundPaw", 0.5, 0.6, 0.5, -1.2, 0.5, 0.2, 72, 32, 34, "Block", "Slate", 0, 0, nil),
	},
}

function StageArt.figure(kind: string, id: string): { Piece }
	local found = FIGURES[kind .. ":" .. id]
	if found == nil then
		return { piece("Placeholder", 2, 2, 2, 0, 3, 0, 200, 80, 160, "Ball", "Neon", 0, 0, nil) }
	end
	local copy = {}
	for _, item in found do
		table.insert(copy, item)
	end
	return copy
end

function StageArt.rankPips(rank: number): { Piece }
	local list = {}
	local shown = math.min(math.max(rank, 0), 5)
	for index = 1, shown do
		table.insert(list, piece("Pip" .. tostring(index), 0.45, 0.45, 0.3, -1.2 + index * 0.6, 10.4, 0.3, 214, 176, 92, "Block", "Neon", 0, 0, nil))
	end
	return list
end

function StageArt.scenery(): { Piece }
	local list: { Piece } = {}
	add(list, piece("SkyTop", 240, 70, 2, 0, 58, -12, 8, 10, 26, "Block", "SmoothPlastic", 0, 0, nil))
	add(list, piece("SkyMid", 240, 46, 2, 0, 28, -11, 22, 18, 48, "Block", "SmoothPlastic", 0, 0, nil))
	add(list, piece("SkyGlow", 70, 28, 1.5, 30, 38, -9, 58, 42, 92, "Block", "SmoothPlastic", 0.15, 0, nil))
	for index = 1, 14 do
		local x = -48 + ((index * 19) % 96)
		local y = 30 + ((index * 7) % 16)
		add(list, piece("Star" .. tostring(index), 0.45, 0.45, 0.45, x, y, -8.5, 236, 226, 200, "Ball", "Neon", 0, 0, nil))
	end
	add(list, piece("Moon", 1.3, 11, 11, 30, 40, -7, 236, 226, 196, "Cylinder", "Neon", 0, 90, {
		brightness = 1.35,
		range = 42,
		r = 236,
		g = 220,
		b = 186,
	}))
	add(list, piece("MoonBite", 1.3, 8.2, 8.2, 33.2, 42.2, -6.7, 18, 16, 40, "Cylinder", "SmoothPlastic", 0, 90, nil))
	add(list, piece("HillFar", 220, 12, 2, 0, 8, -7.2, 18, 16, 34, "Block", "Slate", 0, 0, nil))
	add(list, piece("HillLeft", 64, 16, 2,  -46, 12, -5.4, 28, 24, 46, "Block", "Slate", 0, 0, nil))
	add(list, piece("HillRight", 72, 14, 2, 40, 11, -5.4, 24, 22, 42, "Block", "Slate", 0, 0, nil))
	add(list, piece("Chapel", 22, 14, 2, 14, 16, -5, 62, 58, 88, "Block", "Slate", 0, 0, nil))
	add(list, piece("ChapelRoof", 26, 3, 1.6, 14, 24.5, -4.7, 112, 48, 68, "Block", "SmoothPlastic", 0, 0, nil))
	add(list, piece("ChapelSpireL", 2.4, 16, 1.6, 5, 26, -4.8, 70, 66, 98, "Block", "Slate", 0, 0, nil))
	add(list, piece("ChapelSpireR", 2.4, 12, 1.6, 23, 24, -4.8, 70, 66, 98, "Block", "Slate", 0, 0, nil))
	add(list, piece("ChapelWindow", 2.2, 4.2, 0.4, 14, 16, -3.8, 186, 210, 255, "Block", "Neon", 0, 0, nil))
	add(list, piece("ChapelBell", 1.6, 1.6, 1.6, 14, 29, -4.4, 214, 176, 92, "Ball", "Neon", 0, 0, nil))
	local trees = { -20, 6, 34 }
	for index, x in trees do
		local name = "Cypress" .. tostring(index)
		add(list, piece(name .. "Trunk", 1.3, 11, 1.2, x, 14, -3.4, 32, 28, 46, "Block", "Slate", 0, 0, nil))
		add(list, piece(name .. "Crown", 3.4, 5.5, 1.3, x, 20, -3.2, 20, 34, 40, "Block", "SmoothPlastic", 0, 0, nil))
	end
	add(list, piece("Courtyard", 240, 16, 2, 0, 0, -2, 34, 28, 52, "Block", "Slate", 0, 0, nil))
	add(list, piece("Path", 86, 3.2, 1.6, 6, 8.6, 0.15, 78, 70, 112, "Block", "Slate", 0, 0, nil))
	for step = 2, 34, 4 do
		add(list, piece("Slab" .. tostring(step), 3.1, 0.4, 1.35, StageArt.laneX(step), 10.15, 0.7, 108, 98, 146, "Block", "Slate", 0, 0, nil))
	end
	add(list, piece("Mist", 96, 1.1, 1, 4, 8.4, 1.2, 78, 70, 120, "Block", "SmoothPlastic", 0.72, 0, nil))
	add(list, piece("TowerPlinth", 18, 3.5, 2.2, -42, 8.2, 1, 78, 74, 96, "Block", "Slate", 0, 0, nil))
	add(list, piece("Tower", 12, 20, 2, -42, 19, 1.15, 104, 100, 126, "Block", "Slate", 0, 0, nil))
	add(list, piece("TowerMerlonL", 2.6, 3.4, 2, -47, 30.5, 1.25, 120, 116, 142, "Block", "Slate", 0, 0, nil))
	add(list, piece("TowerMerlonR", 2.6, 3.4, 2, -37, 30.5, 1.25, 120, 116, 142, "Block", "Slate", 0, 0, nil))
	add(list, piece("TowerRoof", 16, 2.6, 2.1, -42, 33.2, 1.3, 132, 52, 74, "Block", "SmoothPlastic", 0, 0, nil))
	add(list, piece("TowerDoor", 3.6, 6.4, 0.8, -42, 10.4, 2.15, 214, 176, 92, "Block", "Neon", 0, 0, {
		brightness = 0.7,
		range = 14,
		r = 214,
		g = 170,
		b = 96,
	}))
	add(list, piece("TowerWindow", 2.4, 3.4, 0.35, -42, 22, 2.2, 186, 214, 255, "Block", "Neon", 0, 0, nil))
	add(list, piece("BannerPole", 0.3, 7, 0.3, -34.5, 24, 1.8, 90, 78, 64, "Block", "Slate", 0, 0, nil))
	add(list, piece("Banner", 2.6, 3.4, 0.25, -33, 22.2, 1.8, 132, 48, 72, "Block", "SmoothPlastic", 0, 0, nil))
	add(list, piece("SpawnPillarL", 2.2, 14, 1.6, 40, 15, 1, 64, 52, 92, "Block", "Slate", 0, 0, nil))
	add(list, piece("SpawnPillarR", 2.2, 14, 1.6, 48, 15, 1, 64, 52, 92, "Block", "Slate", 0, 0, nil))
	add(list, piece("SpawnLintel", 12, 2.2, 1.8, 44, 22.4, 1.05, 78, 64, 110, "Block", "Slate", 0, 0, nil))
	add(list, piece("SpawnGate", 6.4, 8, 0.35, 44, 16, 1.7, 48, 36, 72, "Block", "SmoothPlastic", 0.2, 0, nil))
	local pads = {
		{ "lane.back", 86, 98, 140 },
		{ "lane.mid", 108, 86, 150 },
		{ "lane.front", 132, 78, 96 },
	}
	for _, pad in pads do
		local anchorId = pad[1] :: string
		local x = StageArt.anchorX(anchorId)
		if x ~= nil then
			add(list, piece(anchorId, 5.2, 7.6, 1.35, x, 13, 2, pad[2] :: number, pad[3] :: number, pad[4] :: number, "Block", "Slate", 0, 0, nil))
			add(list, piece(anchorId .. "Trim", 5.6, 0.45, 1.45, x, 9.5, 2.15, 214, 176, 92, "Block", "Neon", 0, 0, nil))
		end
	end
	add(list, piece("PackPedestal", 6.2, 3.2, 1.5, -30, 11.2, 2.35, 92, 70, 54, "Block", "Slate", 0, 0, nil))
	add(list, piece("NightPack", 3.8, 5, 0.7, -30, 15.2, 2.7, 92, 48, 78, "Block", "SmoothPlastic", 0, 0, nil))
	add(list, piece("NightPackBand", 4.1, 1.1, 0.8, -30, 15.4, 2.85, 236, 220, 180, "Block", "SmoothPlastic", 0, 0, nil))
	add(list, piece("NightPackSeal", 1.15, 1.15, 1.15, -30, 15.5, 3.15, 214, 176, 92, "Ball", "Neon", 0, 0, {
		brightness = 0.45,
		range = 8,
		r = 214,
		g = 176,
		b = 92,
	}))
	return list
end

return StageArt
