--!strict
-- Presentation timing only. This module does not roll packs, grant cards, or store audio asset ids.
-- Foil and chevron treatments are visual. They are not drop rates.

export type Motion = "full" | "fast" | "reduced"

export type Step = {
	id: string,
	seconds: number,
	scale: number,
}

export type Cue = {
	id: string,
	ms: number,
	haptic: number,
	audible: boolean,
}

export type Impact = {
	cue: string,
	trauma: number,
	particles: number,
	flash: boolean,
	hold: number,
}

export type Offset = { x: number, y: number }

local Presentation = {}

local STANDARD: { Step } = {
	{ id = "rip", seconds = 0.22, scale = 1 },
	{ id = "open", seconds = 0.18, scale = 0.86 },
	{ id = "settle", seconds = 0.16, scale = 1 },
}

local CUES: { [string]: { ms: number, haptic: number } } = {
	rip = { ms = 90, haptic = 0.2 },
	reveal = { ms = 140, haptic = 0.35 },
	foil = { ms = 180, haptic = 0.45 },
	hover = { ms = 40, haptic = 0.08 },
	press = { ms = 50, haptic = 0.15 },
	impact = { ms = 120, haptic = 0.5 },
	defeat = { ms = 160, haptic = 0.4 },
}

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

function Presentation.revealSteps(motion: Motion, foil: boolean): { Step }
	if motion == "reduced" then
		return { { id = "show", seconds = 0, scale = 1 } }
	end
	local steps: { Step } = {}
	for _, step in STANDARD do
		local seconds = step.seconds
		local scale = step.scale
		if motion == "fast" then
			seconds *= 0.45
			if scale < 1 then
				scale = 0.94
			end
		end
		table.insert(steps, { id = step.id, seconds = seconds, scale = scale })
	end
	if foil then
		local shimmer = if motion == "fast" then 0.09 else 0.2
		table.insert(steps, { id = "shimmer", seconds = shimmer, scale = 1 })
	end
	return steps
end

function Presentation.totalSeconds(steps: { Step }): number
	local total = 0
	for _, step in steps do
		total += step.seconds
	end
	return total
end

function Presentation.cue(id: string, motion: Motion): Cue
	local found = CUES[id]
	local ms = if found ~= nil then found.ms else 40
	local haptic = if found ~= nil then found.haptic else 0
	if motion == "reduced" then
		haptic = 0
		ms = math.min(ms, 40)
	elseif motion == "fast" then
		ms = math.floor(ms * 0.7)
	end
	return {
		id = id,
		ms = ms,
		haptic = haptic,
		audible = false,
	}
end

function Presentation.impact(motion: Motion, survived: boolean): Impact
	local cue = if survived then "impact" else "defeat"
	if motion == "reduced" then
		return { cue = cue, trauma = 0, particles = 0, flash = false, hold = 0 }
	end
	if motion == "fast" then
		if survived then
			return { cue = cue, trauma = 0.2, particles = 6, flash = false, hold = 0 }
		end
		return { cue = cue, trauma = 0.35, particles = 8, flash = false, hold = 0 }
	end
	if survived then
		return { cue = cue, trauma = 0.4, particles = 10, flash = false, hold = 0.04 }
	end
	return { cue = cue, trauma = 0.7, particles = 12, flash = true, hold = 0.1 }
end

function Presentation.decayTrauma(trauma: number, realDt: number, decay: number): number
	if trauma ~= trauma or realDt ~= realDt or decay ~= decay then
		return 0
	end
	return math.max(trauma - decay * math.max(realDt, 0), 0)
end

function Presentation.shakeOffset(trauma: number, time: number, strength: number): Offset
	if trauma <= 0 or strength <= 0 or trauma ~= trauma then
		return { x = 0, y = 0 }
	end
	local shake = trauma * trauma * strength
	return {
		x = 12 * shake * math.sin(time * 1.7),
		y = 8 * shake * math.sin(time * 2.3),
	}
end

function Presentation.buttonHeight(viewportY: number): number
	if viewportY ~= viewportY then
		return 48
	end
	return math.clamp(math.floor(viewportY * 0.065 + 0.5), 44, 56)
end

function Presentation.bodyText(viewportY: number): number
	if viewportY ~= viewportY then
		return 18
	end
	return math.clamp(math.floor(viewportY / 40 + 0.5), 18, 28)
end

function Presentation.face(kind: string): string
	if kind == "Spell" then
		return "chevron"
	end
	return "shield"
end

function Presentation.cardDetail(displayName: string, kind: string, count: number, rank: number): string
	return table.concat({
		displayName,
		kind .. " · owned " .. tostring(count) .. " · rank " .. tostring(rank),
		"Foil is a preview. This pack does not roll foil.",
		"Provisional combat numbers are not release balance.",
	}, "\n")
end

return Presentation
