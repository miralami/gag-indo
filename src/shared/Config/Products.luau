-- Roblox monetization IDs (GDD §9). Replace the 0s with real IDs before publishing.
-- Anything still at 0 is treated as "not configured": the UI hides the button and
-- Receipts/Passes never ask Roblox about it. That keeps the game playable in Studio
-- without a published experience.

local Products = {}

-- Game passes: id + the attribute the rest of the server reads.
Products.passes = {
	ordal = { id = 0, attribute = "Pass_Ordal" },
	extraPlot = { id = 0, attribute = "Pass_ExtraPlot", extraTiles = 4 },
	vipWarung = { id = 0, attribute = "Pass_VIPWarung" },
}

-- Developer products: id + what Receipts adds to the profile when bought.
-- `grant` is a key handled by Receipts.luau, never a function (config stays data).
Products.products = {
	amplopPremium = { id = 0, grant = "inventory", item = "amplopPremium", amount = 1 },
	jaminanKilat = { id = 0, grant = "inventory", item = "jaminanKilat", amount = 1 },
	karungBibit = {
		id = 0,
		grant = "seeds",
		seeds = { padi = 10, jagung = 5, cabai = 3 },
	},
}

-- Filled at require time so Receipts can do a single table lookup.
Products.byProductId = {}
for key, product in Products.products do
	if product.id > 0 then
		Products.byProductId[product.id] = { key = key, product = product }
	end
end

function Products.passConfigured(passKey: string): boolean
	local pass = Products.passes[passKey]
	return pass ~= nil and pass.id > 0
end

function Products.productKeyForId(productId: number): string?
	local entry = Products.byProductId[productId]
	return if entry then entry.key else nil
end

return Products
