--!strict

local Types = require("../contracts/Types")
local Result = require("../contracts/Result")
local CombatSim = require("./CombatSim")
local Economy = require("./Economy")
local Progression = require("./Progression")

local RunCombat = {}

local function alreadyCleared(profile: Types.PlayerProfile, waveId: string): boolean
	for _, cleared in profile.clearedWaves do
		if cleared == waveId then
			return true
		end
	end
	return false
end

function RunCombat.fight(profile: Types.PlayerProfile, waveId: string, seed: number): Result.Result<CombatSim.Report>
	local simulated = CombatSim.simulate(profile, waveId, seed)
	if not simulated.ok then
		return simulated
	end
	local report = simulated.value
	Progression.noteBestiary(profile, waveId)
	profile.damageDealt += report.damageDealt
	local cleared = alreadyCleared(profile, report.waveId)
	if report.survived and cleared then
		report.mastery = 0
		report.coins = 0
	elseif report.survived then
		if report.mastery > 0 then
			profile.currencies.mastery += report.mastery
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
