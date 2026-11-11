-- Tools (v2 PLAN §3.4). Permanent, bought with cash, one tier per line at a time.
--
--   cangkul  planting quality bonus (better rarity rolls)
--   gembor   growth speed multiplier
--   karung   +sack capacity
--   traktor  reserved for row planting (the 1-click flow already covers most of it)
--
-- `data.tools[lineId] = tierId`. The next tier is the one after the owned one; unknown/missing
-- tiers fall back to no bonus, so a save from a future config never crashes a player.

local Tools = {}

Tools.order = { "cangkul", "gembor", "karung", "traktor" }

Tools.list = {
	cangkul = {
		label = "tool_cangkul",
		rank = "gurem",
		tiers = {
			{ id = "bambu", cost = 60, plantBonus = 0.05 },
			{ id = "baja", cost = 350, plantBonus = 0.12 },
		},
	},
	gembor = {
		label = "tool_gembor",
		rank = "petani",
		tiers = {
			{ id = "gembor", cost = 150, grow = 1.10 },
			{ id = "sprinkler", cost = 600, grow = 1.25 },
		},
	},
	karung = {
		label = "tool_karung",
		rank = "petani",
		tiers = {
			{ id = "besar", cost = 200, sack = 20 },
			{ id = "gerobak", cost = 800, sack = 60 },
		},
	},
	traktor = {
		label = "tool_traktor",
		rank = "juragan",
		tiers = {
			{ id = "traktor", cost = 1500, row = true },
		},
	},
}

function Tools.exists(lineId: any): boolean
	return type(lineId) == "string" and Tools.list[lineId] ~= nil
end

-- Tier table by id, scanning the line. nil when the id is unknown.
function Tools.tier(lineId: string, tierId: any): any?
	local line = Tools.list[lineId]
	if not line then
		return nil
	end
	for _, tier in line.tiers do
		if tier.id == tierId then
			return tier
		end
	end
	return nil
end

-- The tier a player would buy next, or nil when the line is maxed.
function Tools.next(lineId: string, ownedTierId: any): any?
	local line = Tools.list[lineId]
	if not line then
		return nil
	end
	if ownedTierId == nil then
		return line.tiers[1]
	end
	for index, tier in line.tiers do
		if tier.id == ownedTierId then
			return line.tiers[index + 1]
		end
	end
	-- An id this config no longer knows about: treat it as nothing owned.
	return line.tiers[1]end

return Tools
