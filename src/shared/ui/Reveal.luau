--!strict
-- Presentation only. foil=true is a visual. It is not a drop rate.

export type RevealCard = {
	displayName: string,
	kind: string,
	foil: boolean,
	provisional: boolean,
	preview: boolean,
}

local Reveal = {}

function Reveal.describe(displayName: string, kind: string, foil: boolean, preview: boolean): RevealCard
	return {
		displayName = displayName,
		kind = kind,
		foil = foil,
		provisional = true,
		preview = preview,
	}
end

function Reveal.banner(card: RevealCard): string
	if card.preview then
		return "Foil preview — not a reward"
	end
	if card.foil then
		return "Foil"
	end
	return "Standard"
end

return Reveal
