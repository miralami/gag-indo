--!strict
-- Roblox monetization IDs (GDD §9). Replace the 0s with real IDs before publishing.
-- Anything still at 0 is treated as "not configured": the UI hides the button and
-- Receipts/Passes never ask Roblox about it. That keeps the game playable in Studio
-- without a published experience.

local Products = {}

-- One dev-product row. Only id/grant are universal; the rest depends on the grant kind, so every
-- optional field is marked to let strict mode accept the heterogeneous rows as one map type.
type Product = {
	id: number,
	grant: string,
	item: string?,
	amount: number?,
	seeds: { [string]: number }?,
	cash: number?,
}

-- Game passes: id + the attribute the rest of the server reads.
-- gudangBesar raises the gudang capacity (StorageService reads the attribute);
-- autoPanen makes the buruh free and permanent (WorkerService reads the attribute).
Products.passes = {
	ordal = { id = 0, attribute = "Pass_Ordal" },
	extraPlot = { id = 0, attribute = "Pass_ExtraPlot", extraTiles = 4 },
	vipWarung = { id = 0, attribute = "Pass_VIPWarung" },
	gudangBesar = { id = 0, attribute = "Pass_GudangBesar" },
	autoPanen = { id = 0, attribute = "Pass_AutoPanen" },
}

-- Developer products: id + what Receipts adds to the profile when bought.
-- `grant` is a key handled by Receipts.luau, never a function (config stays data).
--
-- Rupiah packs carry `cash` instead of `amount`: how much cash one pack is worth is a
-- balance/price decision, so it ships unset. A pack with id 0 or cash <= 0 grants nothing.
Products.products = {
	amplopPremium = { id = 0, grant = "inventory", item = "amplopPremium", amount = 1 },
	jaminanKilat = { id = 0, grant = "inventory", item = "jaminanKilat", amount = 1 },
	karungBibit = {
		id = 0,
		grant = "seeds",
		seeds = { padi = 10, jagung = 5, cabai = 3 },
	},
	-- Restocks the Toko Bibit shelves immediately (a fresh roll, not a free cycle).
	restockToko = { id = 0, grant = "restock" },
	-- Rupiah packs. Purchased cash is not "earned": it must not raise rank or leaderboard.
	rupiahKecil = { id = 0, grant = "cash", cash = 0 },
	rupiahSedang = { id = 0, grant = "cash", cash = 0 },
	rupiahBesar = { id = 0, grant = "cash", cash = 0 },
} :: { [string]: Product }

-- Filled at require time so Receipts can do a single table lookup.
Products.byProductId = {} :: { [number]: { key: string, product: Product } }
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
