--!strict
-- Camera trauma only. Shake does not move defenders, enemies, or the combat clock.

local CameraFeel = {}

local DECAY = 1.2
local trauma = 0
local clock = 0

function CameraFeel.reset()
	trauma = 0
	clock = 0
end

function CameraFeel.trauma(): number
	return trauma
end

function CameraFeel.add(amount: number, motion: string)
	if motion == "reduced" then
		return
	end
	local scale = if motion == "fast" then 0.45 else 1
	local nextTrauma = trauma + amount * scale
	if nextTrauma < 0 then
		nextTrauma = 0
	elseif nextTrauma > 1 then
		nextTrauma = 1
	end
	trauma = nextTrauma
end

function CameraFeel.step(realDt: number, strength: number): (number, number, number)
	if trauma <= 0 then
		return 0, 0, 0
	end
	local dt = realDt
	if dt ~= dt or dt < 0 or dt == math.huge then
		dt = 0
	end
	trauma = math.max(trauma - DECAY * dt, 0)
	local shake = trauma * trauma * strength
	clock += dt * 30
	if trauma == 0 then
		return 0, 0, 0
	end
	return 1.4 * shake * math.sin(clock * 1.7), 0.8 * shake * math.sin(clock * 2.3), 0.03 * shake * math.sin(clock * 1.1)
end

return CameraFeel
