--!strict
-- CONFIGURABLE_PLACEHOLDER combat numbers. Source-game stats, path, and timing are UNKNOWN.
-- Observed rules kept: waves threaten a tower, survival pays Mastery, Mastery upgrades a hero or spell,
-- and a clear unlocks another pack and a realm. Targeting "first" is the tower-defense default, not a measured BPH rule.

local CombatTables = {}

export type Vec = { x: number, y: number }
export type Segment = { from: Vec, to: Vec, length: number, start: number }

CombatTables.status = "UNVERIFIED_PLACEHOLDER"
CombatTables.tick = 0.05
CombatTables.maxTicks = 2000
CombatTables.towerMaxHp = 15
CombatTables.upgradeCost = 5
CombatTables.maxRank = 3

local PATH: { Vec } = {
	{ x = 0, y = 0 },
	{ x = 60, y = 0 },
	{ x = 60, y = 20 },
}

local function buildSegments(points: { Vec }): ({ Segment }, number)
	local segments: { Segment } = {}
	local total = 0
	for index = 1, #points - 1 do
		local from = points[index]
		local to = points[index + 1]
		local dx = to.x - from.x
		local dy = to.y - from.y
		local length = math.sqrt(dx * dx + dy * dy)
		table.insert(segments, { from = from, to = to, length = length, start = total })
		total += length
	end
	return segments, total
end

local SEGMENTS, PATH_LENGTH = buildSegments(PATH)

function CombatTables.pathLength(): number
	return PATH_LENGTH
end

function CombatTables.pointAt(progress: number): Vec
	local clamped = math.clamp(progress, 0, PATH_LENGTH)
	for _, segment in SEGMENTS do
		if clamped <= segment.start + segment.length then
			local along = if segment.length == 0 then 0 else (clamped - segment.start) / segment.length
			return {
				x = segment.from.x + (segment.to.x - segment.from.x) * along,
				y = segment.from.y + (segment.to.y - segment.from.y) * along,
			}
		end
	end
	local last = PATH[#PATH]
	return { x = last.x, y = last.y }
end

export type Anchor = { id: string, x: number, y: number }
export type UnitStats = {
	cardId: string,
	damage: number,
	cooldown: number,
	range: number,
	damagePerRank: number,
}
export type EnemyStats = { id: string, hp: number, speed: number, leakDamage: number }
export type WaveGroup = { enemyId: string, count: number, spacing: number }
export type WaveDef = {
	id: string,
	displayName: string,
	groups: { WaveGroup },
	mastery: number,
	coins: number,
	requires: string?,
}

local ANCHORS: { Anchor } = {
	{ id = "lane.mid", x = 30, y = 10 },
}

local UNITS: { [string]: UnitStats } = {
	["placeholder.frontline"] = {
		cardId = "placeholder.frontline",
		damage = 6,
		cooldown = 0.4,
		range = 16,
		damagePerRank = 8,
	},
	["placeholder.bolt"] = {
		cardId = "placeholder.bolt",
		damage = 3,
		cooldown = 1.2,
		range = 16,
		damagePerRank = 8,
	},
}

local ENEMIES: { [string]: EnemyStats } = {
	["placeholder.grunt"] = { id = "placeholder.grunt", hp = 18, speed = 10, leakDamage = 15 },
	["placeholder.brute"] = { id = "placeholder.brute", hp = 70, speed = 10, leakDamage = 15 },
}

local WAVES: { WaveDef } = {
	{
		id = "placeholder.wave.1",
		displayName = "Placeholder wave 1",
		groups = { { enemyId = "placeholder.grunt", count = 3, spacing = 1.2 } },
		mastery = 5,
		coins = 10,
		requires = nil,
	},
	{
		id = "placeholder.wave.2",
		displayName = "Placeholder wave 2",
		groups = { { enemyId = "placeholder.brute", count = 1, spacing = 1 } },
		mastery = 5,
		coins = 10,
		requires = "placeholder.wave.1",
	},
}

function CombatTables.anchors(): { Anchor }
	return ANCHORS
end

function CombatTables.anchor(anchorId: string): Anchor?
	for _, anchor in ANCHORS do
		if anchor.id == anchorId then
			return anchor
		end
	end
	return nil
end

function CombatTables.unit(cardId: string): UnitStats?
	return UNITS[cardId]
end

function CombatTables.enemy(enemyId: string): EnemyStats?
	return ENEMIES[enemyId]
end

function CombatTables.waves(): { WaveDef }
	return WAVES
end

function CombatTables.wave(waveId: string): WaveDef?
	for _, wave in WAVES do
		if wave.id == waveId then
			return wave
		end
	end
	return nil
end

function CombatTables.damage(cardId: string, rank: number): number
	local unit = UNITS[cardId]
	if unit == nil then
		return 0
	end
	return unit.damage + rank * unit.damagePerRank
end

function CombatTables.startingRealm(): string
	return "placeholder.tower"
end

function CombatTables.clearedRealm(): string
	return "placeholder.gate"
end

function CombatTables.realmName(realmId: string): string
	if realmId == "placeholder.gate" then
		return "Placeholder Gate"
	end
	return "Placeholder Tower"
end

return CombatTables
