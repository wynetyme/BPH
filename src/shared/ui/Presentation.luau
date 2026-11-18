--!strict
-- Presentation only. No rolls, grants, or audio asset ids.

export type Motion = "full" | "fast" | "reduced"

local Presentation = {}

function Presentation.parse(value: unknown): Motion
	if value == "fast" or value == "reduced" then
		return value
	end
	return "full"
end

function Presentation.cycle(motion: Motion): Motion
	if motion == "full" then
		return "fast"
	end
	if motion == "fast" then
		return "reduced"
	end
	return "full"
end

function Presentation.motionLabel(motion: Motion): string
	if motion == "fast" then
		return "Motion: Fast"
	end
	if motion == "reduced" then
		return "Motion: Reduced"
	end
	return "Motion: Full"
end

function Presentation.revealSeconds(motion: Motion): number
	if motion == "reduced" then
		return 0
	end
	if motion == "fast" then
		return 0.2
	end
	return 0.45
end

function Presentation.combatTickSeconds(motion: Motion): number
	if motion == "reduced" then
		return 0
	end
	if motion == "fast" then
		return 0.05
	end
	return 0.12
end

function Presentation.buttonHeight(viewportY: number): number
	return math.clamp(math.floor(viewportY / 16), 44, 56)
end

function Presentation.bodyText(viewportY: number): number
	return math.clamp(math.floor(viewportY / 28), 18, 28)
end

return Presentation
