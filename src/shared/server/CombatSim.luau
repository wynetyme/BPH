--!strict
-- Server combat. The seed is recorded and does not change the wave.

local Types = require("../contracts/Types")
local Result = require("../contracts/Result")
local CombatTables = require("../data/CombatTables")

export type Report = {
	waveId: string,
	ticks: number,
	damageDealt: number,
	survived: boolean,
	towerHp: number,
	killed: number,
	leaked: number,
	mastery: number,
	coins: number,
	seed: number,
}

local CombatSim = {}

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
	local bonus = CombatTables.relicBonus(profile.equippedRelics)
	local schedule = {}
	local at = 1
	for _, group in wave.groups do
		local stats = CombatTables.enemy(group.enemyId)
		if stats == nil or group.count < 1 then
			return Result.err("InvalidWave")
		end
		for _ = 1, group.count do
			table.insert(schedule, { at = at, enemyId = group.enemyId, hp = stats.hp, speed = stats.speed, leak = stats.leak })
			at += group.spacing
		end
	end
	type Enemy = { progress: number, hp: number, speed: number, leak: number, alive: boolean }
	type Defender = { origin: number, damage: number, range: number, cooldown: number, wait: number }
	local enemies: { Enemy } = {}
	local defenders: { Defender } = {}
	for _, slot in profile.placement do
		local origin = CombatTables.anchor(slot.anchorId)
		local stats = CombatTables.card(slot.cardId)
		if origin == nil or stats == nil then
			return Result.err("InvalidPlacement")
		end
		local rank = profile.ranks[slot.cardId] or 0
		table.insert(defenders, {
			origin = origin,
			damage = stats.damage + rank * stats.rankDamage + bonus.damage,
			range = stats.range + bonus.range,
			cooldown = stats.cooldown,
			wait = 0,
		})
	end
	local tower = CombatTables.towerMaxHp() + bonus.tower
	local spawned = 1
	local killed = 0
	local leaked = 0
	local damageDealt = 0
	local ticks = 0
	while ticks < CombatTables.maxTicks() do
		ticks += 1
		while spawned <= #schedule and schedule[spawned].at <= ticks do
			local row = schedule[spawned]
			table.insert(enemies, { progress = 0, hp = row.hp, speed = row.speed, leak = row.leak, alive = true })
			spawned += 1
		end
		for _, enemy in enemies do
			if enemy.alive then
				enemy.progress += enemy.speed
			end
		end
		for _, defender in defenders do
			if defender.wait > 0 then
				defender.wait -= 1
			else
				local target = nil
				for _, enemy in enemies do
					if enemy.alive and math.abs(enemy.progress - defender.origin) <= defender.range then
						if target == nil or enemy.progress > target.progress then
							target = enemy
						end
					end
				end
				if target ~= nil then
					target.hp -= defender.damage
					damageDealt += defender.damage
					defender.wait = defender.cooldown
					if target.hp <= 0 then
						target.alive = false
						killed += 1
					end
				end
			end
		end
		for _, enemy in enemies do
			if enemy.alive and enemy.progress >= CombatTables.pathLength() then
				enemy.alive = false
				leaked += 1
				tower -= enemy.leak
			end
		end
		local pending = spawned <= #schedule
		local alive = false
		for _, enemy in enemies do
			if enemy.alive then
				alive = true
				break
			end
		end
		if tower <= 0 or (not pending and not alive) then
			break
		end
	end
	local aliveLeft = false
	for _, enemy in enemies do
		if enemy.alive then
			aliveLeft = true
			break
		end
	end
	local survived = tower > 0 and not aliveLeft and spawned > #schedule
	if tower < 0 then
		tower = 0
	end
	return Result.ok({
		waveId = waveId,
		ticks = ticks,
		damageDealt = damageDealt,
		survived = survived,
		towerHp = tower,
		killed = killed,
		leaked = leaked,
		mastery = if survived then wave.mastery else 0,
		coins = if survived then wave.coins else 0,
		seed = seed,
	})
end

return CombatSim
