--!strict
-- Survival grants Mastery only. Wave tables are not invented here.

local Types = require("../contracts/Types")
local Result = require("../contracts/Result")
local Economy = require("./Economy")
local CombatSim = require("./CombatSim")
local Progression = require("./Progression")

export type RunState = {
	active: boolean,
	masteryEarned: number,
}

local RunCombat = {}

function RunCombat.begin(): RunState
	return { active = true, masteryEarned = 0 }
end

function RunCombat.grantSurvivalMastery(profile: Types.PlayerProfile, run: RunState, amount: number): Result.Result<number>
	if not run.active then
		return Result.err("RunInactive")
	end
	if amount ~= amount or math.abs(amount) == math.huge or amount < 0 or amount % 1 ~= 0 then
		return Result.err("InvalidAmount")
	end
	run.masteryEarned += amount
	profile.currencies.mastery += amount
	return Result.ok(profile.currencies.mastery)
end

function RunCombat.finish(run: RunState)
	run.active = false
end

function RunCombat.fight(profile: Types.PlayerProfile, waveId: string, seed: number): Result.Result<CombatSim.Report>
	local simulated = CombatSim.simulate(profile, waveId, seed)
	if not simulated.ok then
		return simulated
	end
	local report = simulated.value
	local cleared = false
	for _, wave in profile.clearedWaves do
		if wave == report.waveId then
			cleared = true
			break
		end
	end
	if report.survived and cleared then
		report.mastery = 0
		report.coins = 0
	elseif report.survived then
		local run = RunCombat.begin()
		local granted = RunCombat.grantSurvivalMastery(profile, run, report.mastery)
		RunCombat.finish(run)
		if not granted.ok then
			return granted
		end
		if report.coins > 0 then
			local paid = Economy.grantCoins(profile, report.coins)
			if not paid.ok then
				return paid
			end
		end
		Progression.recordClear(profile, report.waveId)
	end
	return Result.ok(report)
end

return RunCombat
