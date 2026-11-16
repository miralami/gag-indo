-- Inventory: the v3 generic item bag (v2 PLAN §7.1). `items[itemId] = count` holds
-- consumables (amplopPremium, jaminanKilat, ...) and seeds (`seed_<crop>`), so adding an
-- item never needs a new save field.
--
-- Pure module: no Roblox APIs.

local Inventory = {}

local SEED_PREFIX = "seed_"

local function bag(data): { [string]: number }
	if type(data.items) ~= "table" then
		data.items = {}
	end
	return data.items
end

-- A damaged count (non-number, NaN, infinite, negative) reads as 0, so it can never be spent.
function Inventory.get(data, itemId: string): number
	local count = bag(data)[itemId]
	if type(count) ~= "number" or count ~= count or count == math.huge or count < 0 then
		return 0
	end
	return count
end

-- Returns how many were actually added.
function Inventory.add(data, itemId: string, amount: number): number
	if type(amount) ~= "number" or amount ~= amount or amount <= 0 then
		return 0
	end
	local whole = math.floor(amount)
	if whole < 1 then
		return 0
	end
	bag(data)[itemId] = Inventory.get(data, itemId) + whole
	return whole
end

-- All-or-nothing: returns false and changes nothing when the player has too few.
function Inventory.take(data, itemId: string, amount: number): boolean
	if type(amount) ~= "number" or amount ~= amount or amount <= 0 then
		return false
	end
	local whole = math.floor(amount)
	local have = Inventory.get(data, itemId)
	if have < whole then
		return false
	end
	bag(data)[itemId] = have - whole
	return true
end

function Inventory.seedId(cropId: string): string
	return SEED_PREFIX .. cropId
end

function Inventory.getSeed(data, cropId: string): number
	return Inventory.get(data, Inventory.seedId(cropId))
end

function Inventory.addSeed(data, cropId: string, amount: number): number
	return Inventory.add(data, Inventory.seedId(cropId), amount)
end

function Inventory.takeSeed(data, cropId: string, amount: number): boolean
	return Inventory.take(data, Inventory.seedId(cropId), amount)
end

-- Snapshot for the replicated state module (copy, never the live table).
function Inventory.snapshot(data): { [string]: number }
	return table.clone(bag(data))
end

return Inventory
