--!strict
-- Fixed-step lane combat. The server owns damage, movement, and targeting.
-- Progress is distance along the path, so leftover movement carries through corners.

local Types = require("../contracts/Types")
local Result = require("../contracts/Result")
local CardDefinitions = require("../data/CardDefinitions")
local HeroCollection = require("./HeroCollection")
local CombatTables = require("../data/CombatTables")

export type EnemyState = {
	progress: number,
	hp: number,
	speed: number,
	leakDamage: number,
	alive: boolean,
	leaked: boolean,
}

export type Report = {
	seed: number,
	waveId: string,
	survived: boolean,
	ticks: number,
	killed: number,
	leaked: number,
	towerHp: number,
	damageDealt: number,
	mastery: number,
	coins: number,
	status: string,
}

local CombatSim = {}

local function distance(a: CombatTables.Vec, b: CombatTables.Vec): number
	local dx = a.x - b.x
	local dy = a.y - b.y
	return math.sqrt(dx * dx + dy * dy)
end

function CombatSim.pickFirst(enemies: { EnemyState }, origin: CombatTables.Vec, range: number): EnemyState?
	local best: EnemyState? = nil
	local bestProgress = -1
	for _, enemy in enemies do
		if enemy.alive and enemy.progress > bestProgress then
			local point = CombatTables.pointAt(enemy.progress)
			if distance(point, origin) <= range then
				best = enemy
				bestProgress = enemy.progress
			end
		end
	end
	return best
end

function CombatSim.travelTicks(speed: number): number
	local length = CombatTables.pathLength()
	local progress = 0
	local ticks = 0
	while progress < length and ticks < CombatTables.maxTicks do
		progress += speed * CombatTables.tick
		ticks += 1
	end
	return ticks
end

local function hasCleared(profile: Types.PlayerProfile, waveId: string): boolean
	for _, cleared in profile.clearedWaves do
		if cleared == waveId then
			return true
		end
	end
	return false
end

function CombatSim.simulate(profile: Types.PlayerProfile, waveId: string, seed: number): Result.Result<Report>
	if seed ~= seed or math.abs(seed) == math.huge or seed % 1 ~= 0 then
		return Result.err("InvalidSeed")
	end
	local wave = CombatTables.wave(waveId)
	if wave == nil then
		return Result.err("UnknownWave")
	end
	if wave.requires ~= nil and not hasCleared(profile, wave.requires) then
		return Result.err("WaveLocked")
	end
	local enemies: { EnemyState } = {}
	local pending: { { stats: CombatTables.EnemyStats, left: number, spacing: number, nextAt: number } } = {}
	local spawned = 0
	for _, group in wave.groups do
		local stats = CombatTables.enemy(group.enemyId)
		if stats == nil or group.count < 1 then
			return Result.err("InvalidWave")
		end
		table.insert(pending, { stats = stats, left = group.count, spacing = group.spacing, nextAt = 0 })
		spawned += group.count
	end
	type Defender = {
		origin: CombatTables.Vec,
		range: number,
		damage: number,
		cooldown: number,
		remaining: number,
	}
	local defenders: { Defender } = {}
	for _, slot in profile.placement do
		local card = CardDefinitions.get(slot.cardId)
		local anchor = CombatTables.anchor(slot.anchorId)
		local stats = CombatTables.unit(slot.cardId)
		if card == nil or card.kind ~= "Hero" or anchor == nil or stats == nil or HeroCollection.count(profile, slot.cardId) < 1 then
			return Result.err("InvalidPlacement")
		end
		table.insert(defenders, {
			origin = { x = anchor.x, y = anchor.y },
			range = stats.range,
			damage = CombatTables.damage(slot.cardId, profile.ranks[slot.cardId] or 0),
			cooldown = stats.cooldown,
			remaining = 0,
		})
	end
	local bolt = CombatTables.unit("placeholder.bolt")
	local boltAnchor = CombatTables.anchor("lane.mid")
	if bolt ~= nil and boltAnchor ~= nil and HeroCollection.count(profile, "placeholder.bolt") >= 1 then
		table.insert(defenders, {
			origin = { x = boltAnchor.x, y = boltAnchor.y },
			range = bolt.range,
			damage = CombatTables.damage("placeholder.bolt", profile.ranks["placeholder.bolt"] or 0),
			cooldown = bolt.cooldown,
			remaining = 0,
		})
	end
	local clock = 0
	local ticks = 0
	local killed = 0
	local leaked = 0
	local towerHp = CombatTables.towerMaxHp
	local damageDealt = 0
	local spawnIndex = 1
	while ticks < CombatTables.maxTicks and towerHp > 0 and killed + leaked < spawned do
		ticks += 1
		clock += CombatTables.tick
		while spawnIndex <= #pending do
			local group = pending[spawnIndex]
			if group.left <= 0 then
				spawnIndex += 1
			elseif clock + 1e-9 >= group.nextAt then
				table.insert(enemies, {
					progress = 0,
					hp = group.stats.hp,
					speed = group.stats.speed,
					leakDamage = group.stats.leakDamage,
					alive = true,
					leaked = false,
				})
				group.left -= 1
				group.nextAt += group.spacing
			else
				break
			end
		end
		for _, enemy in enemies do
			if enemy.alive then
				enemy.progress += enemy.speed * CombatTables.tick
				if enemy.progress >= CombatTables.pathLength() then
					enemy.progress = CombatTables.pathLength()
					enemy.alive = false
					enemy.leaked = true
					leaked += 1
					towerHp -= enemy.leakDamage
				end
			end
		end
		for _, defender in defenders do
			defender.remaining -= CombatTables.tick
			if defender.remaining <= 0 then
				local target = CombatSim.pickFirst(enemies, defender.origin, defender.range)
				if target ~= nil then
					target.hp -= defender.damage
					damageDealt += defender.damage
					defender.remaining = defender.cooldown
					if target.hp <= 0 then
						target.alive = false
						killed += 1
					end
				end
			end
		end
	end
	local survived = towerHp > 0 and leaked == 0 and killed == spawned
	return Result.ok({
		seed = seed,
		waveId = wave.id,
		survived = survived,
		ticks = ticks,
		killed = killed,
		leaked = leaked,
		towerHp = math.max(towerHp, 0),
		damageDealt = damageDealt,
		mastery = if survived then wave.mastery else 0,
		coins = if survived then wave.coins else 0,
		status = CombatTables.status,
	})
end

return CombatSim
