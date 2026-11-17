--!strict

export type PriceQuote = {
	status: "Ready",
	priceInRobux: number,
} | {
	status: "Unavailable",
	reason: "PriceUnavailable",
}

local ProductPrice = {}

function ProductPrice.fromInfo(info: unknown): PriceQuote
	if type(info) ~= "table" then
		return { status = "Unavailable", reason = "PriceUnavailable" }
	end
	local price = (info :: { [unknown]: unknown }).PriceInRobux
	if type(price) ~= "number" or price ~= price or math.abs(price) == math.huge or price < 1 or price % 1 ~= 0 then
		return { status = "Unavailable", reason = "PriceUnavailable" }
	end
	return { status = "Ready", priceInRobux = price }
end

function ProductPrice.line(quote: PriceQuote): string
	if quote.status == "Ready" then
		return "Robux price: " .. tostring(quote.priceInRobux) .. " from MarketplaceService"
	end
	return "Robux price: unavailable from MarketplaceService"
end

return ProductPrice
