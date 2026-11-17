--!strict
-- UNVERIFIED_DESIGNED Packvania tuning. Not measured Booster Pack Heroes stats.

local CombatTables = {}

CombatTables.status = "UNVERIFIED_DESIGNED"

local PATH = 36
local TICK = 1
local TOWER = 10
local MAX_TICKS = 80
local UPGRADE = 5

local ANCHORS = {
	["lane.back"] = 8,
	["lane.mid"] = 16,
	["lane.front"] = 24,
}

local ENEMIES = {
	shade = { displayName = "Courtyard Shade", hp = 12, speed = 2, leak = 4 },
	bat = { displayName = "Choir Bat", hp = 9, speed = 3, leak = 3 },
	hound = { displayName = "Gate Hound", hp = 28, speed = 2, leak = 6 },
}

local CARDS = {
	["packvania.warden"] = { damage = 4, range = 12, cooldown = 2, rankDamage = 2 },
	["packvania.bolt"] = { damage = 3, range = 16, cooldown = 2, rankDamage = 2 },
	["packvania.keeper"] = { damage = 2, range = 14, cooldown = 1, rankDamage = 1 },
	["packvania.gargoyle"] = { damage = 6, range = 8, cooldown = 3, rankDamage = 2 },
}

local WAVES = {
	["packvania.wave.courtyard"] = {
		displayName = "Moon Courtyard",
		mastery = 5,
		coins = 10,
		requires = nil :: string?,
		groups = { { enemyId = "shade", count = 4, spacing = 5 } },
	},
	["packvania.wave.chapel"] = {
		displayName = "Chapel Gate",
		mastery = 8,
		coins = 12,
		requires = "packvania.wave.courtyard" :: string?,
		groups = {
			{ enemyId = "bat", count = 6, spacing = 3 },
			{ enemyId = "hound", count = 2, spacing = 5 },
		},
	},
}

local RELICS = {
	{ id = "packvania.cloak", displayName = "Night Cloak", damage = 1, range = 0, tower = 0 },
	{ id = "packvania.bell", displayName = "Chapel Bell", damage = 0, range = 0, tower = 4 },
	{ id = "packvania.lantern", displayName = "Pale Lantern", damage = 0, range = 4, tower = 0 },
}

function CombatTables.pathLength(): number
	return PATH
end

function CombatTables.tick(): number
	return TICK
end

function CombatTables.towerMaxHp(): number
	return TOWER
end

function CombatTables.maxTicks(): number
	return MAX_TICKS
end

function CombatTables.upgradeCost(): number
	return UPGRADE
end

function CombatTables.anchor(anchorId: string): number?
	return ANCHORS[anchorId]
end

function CombatTables.anchors(): { string }
	local names = {}
	for name in ANCHORS do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

function CombatTables.enemy(enemyId: string)
	return ENEMIES[enemyId]
end

function CombatTables.enemies()
	local rows = {}
	for id, stats in ENEMIES do
		table.insert(rows, { id = id, displayName = stats.displayName })
	end
	table.sort(rows, function(a, b)
		return a.displayName < b.displayName
	end)
	return rows
end

function CombatTables.card(cardId: string)
	return CARDS[cardId]
end

function CombatTables.wave(waveId: string)
	return WAVES[waveId]
end

function CombatTables.relics()
	return RELICS
end

function CombatTables.relicBonus(equipped: { string }): { damage: number, range: number, tower: number }
	local bonus = { damage = 0, range = 0, tower = 0 }
	for _, relicId in equipped do
		for _, relic in RELICS do
			if relic.id == relicId then
				bonus.damage += relic.damage
				bonus.range += relic.range
				bonus.tower += relic.tower
			end
		end
	end
	return bonus
end

function CombatTables.clearedRealm(): string
	return "packvania.chapel"
end

function CombatTables.startRealm(): string
	return "packvania.courtyard"
end

function CombatTables.realmName(realmId: string): string
	if realmId == "packvania.chapel" then
		return "Chapel Gate"
	end
	return "Moon Courtyard"
end

return CombatTables
