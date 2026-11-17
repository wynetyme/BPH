--!strict
-- Deterministic integer generator. The server picks the seed. Clients never send one.

local SeededRoll = {}

function SeededRoll.integer(seed: number): (number) -> number
	local state = seed % 2147483647
	if state <= 0 then
		state = 1
	end
	return function(total: number): number
		state = (state * 48271) % 2147483647
		if total < 1 then
			return 1
		end
		return (state % total) + 1
	end
end

return SeededRoll
