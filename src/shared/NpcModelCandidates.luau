-- NpcModelCandidates: pure-data caricature detail recipes for the round-2 "npcs" LookDev
-- candidate (WORK_QUEUE item 6). All geometry is procedural (Roblox primitive parts), so there
-- are NO asset IDs here and the LookDev no-ID guard still holds. See docs/v2/visual/art/npcs.md
-- and Config/NpcArchetypes.luau for the design cards this follows.
--
-- Each detail is parented to an existing named part of the live box NPC, with a CFrame offset in
-- that part's local space. Because NpcFactory moves NPCs with Model:PivotTo, children follow the
-- NPC automatically. The client adapter only adds these while "npcs" is enabled and removes them
-- on disable; the shipping box NPCs are untouched.

local NpcModelCandidates = {}

-- Palette tokens from Config/Visuals.luau (ART.md §3). No real badge, uniform, logo or slogan.
NpcModelCandidates.palette = {
	tinta = "2b2118",
	bambu = "b98a5a",
	kunyit = "c99a2e",
	malam = "1f4e6b",
	genteng = "a8452f",
	padi = "9bb25a",
	kertas = "f3e9d2",
	indigo = "3b4f6b",
}

-- shape: Block | Cylinder | Sphere | Wedge. size/offset are {x,y,z} in studs.
-- attachTo: the NPC part this detail is parented to; offset is relative to that part's CFrame.
NpcModelCandidates.recipes = {
	pakrt = {
		-- Broad, avuncular: taller peci, big two-part moustache, clipboard at the hip.
		{ name = "PeciTall", attachTo = "Head", shape = "Cylinder", size = { 2.2, 1.0, 2.2 }, offset = { 0, 1.55, 0 }, color = "tinta" },
		{ name = "PeciBrim", attachTo = "Head", shape = "Cylinder", size = { 2.6, 0.14, 2.6 }, offset = { 0, 1.06, 0 }, color = "tinta" },
		{ name = "MustacheL", attachTo = "Head", shape = "Wedge", size = { 0.62, 0.24, 0.18 }, offset = { -0.27, -0.34, -1.44 }, color = "tinta" },
		{ name = "MustacheR", attachTo = "Head", shape = "Wedge", size = { 0.62, 0.24, 0.18 }, offset = { 0.27, -0.34, -1.44 }, color = "tinta" },
		{ name = "Clipboard", attachTo = "Torso", shape = "Block", size = { 0.95, 1.25, 0.12 }, offset = { 1.35, -0.15, -0.72 }, color = "kertas" },
		{ name = "ClipboardClip", attachTo = "Torso", shape = "Block", size = { 0.4, 0.16, 0.18 }, offset = { 1.35, 0.42, -0.82 }, color = "kunyit" },
	},
	tengkulak = {
		-- Forward-leaning schemer: heavy brow, sling pouch, hunched shoulder pad.
		{ name = "BrowL", attachTo = "Head", shape = "Block", size = { 0.62, 0.2, 0.18 }, offset = { -0.5, 0.52, -1.44 }, color = "tinta" },
		{ name = "BrowR", attachTo = "Head", shape = "Block", size = { 0.62, 0.2, 0.18 }, offset = { 0.5, 0.52, -1.44 }, color = "tinta" },
		{ name = "SlingStrap", attachTo = "Torso", shape = "Block", size = { 0.16, 2.5, 0.14 }, offset = { 0.1, 0.1, -0.68 }, color = "kertas" },
		{ name = "SlingPouch", attachTo = "Torso", shape = "Block", size = { 0.95, 0.8, 0.5 }, offset = { -0.85, -0.75, -0.5 }, color = "genteng" },
		{ name = "Hunch", attachTo = "Torso", shape = "Sphere", size = { 1.4, 0.7, 0.9 }, offset = { 0, 1.15, 0.45 }, color = "tinta" },
	},
	polisi = {
		-- Upright, squared authority — oversized cap and a FICTIONAL plain badge (no insignia).
		{ name = "CapTall", attachTo = "Head", shape = "Cylinder", size = { 2.8, 1.2, 2.8 }, offset = { 0, 1.65, 0 }, color = "malam" },
		{ name = "CapBrimDetail", attachTo = "Head", shape = "Block", size = { 2.9, 0.18, 1.1 }, offset = { 0, 1.12, -1.65 }, color = "malam" },
		{ name = "Badge", attachTo = "Torso", shape = "Cylinder", size = { 0.42, 0.08, 0.42 }, offset = { -0.75, 0.55, -0.68 }, color = "kunyit" },
		{ name = "Belt", attachTo = "Torso", shape = "Block", size = { 2.5, 0.22, 1.3 }, offset = { 0, -1.15, 0 }, color = "tinta" },
	},
	debt_collector = {
		-- The overdue-loan collector: gaunt top hat, satchel, cold sash. Still a caricature.
		{ name = "TopHat", attachTo = "Head", shape = "Cylinder", size = { 1.9, 1.6, 1.9 }, offset = { 0, 1.9, 0 }, color = "tinta" },
		{ name = "TopHatBrim", attachTo = "Head", shape = "Cylinder", size = { 2.7, 0.12, 2.7 }, offset = { 0, 1.12, 0 }, color = "tinta" },
		{ name = "Satchel", attachTo = "Torso", shape = "Block", size = { 1.0, 0.85, 0.55 }, offset = { 1.0, -0.55, -0.5 }, color = "genteng" },
		{ name = "ColdSash", attachTo = "Torso", shape = "Block", size = { 0.18, 2.4, 0.14 }, offset = { -0.15, 0.05, -0.68 }, color = "malam" },
	},
}

-- Which Npc attribute value maps to which recipe. The debt collector has no Npc attribute;
-- it is detected by the "DebtCollector" name in the adapter and mapped here too.
NpcModelCandidates.alias = {
	pakrt = "pakrt",
	tengkulak = "tengkulak",
	polisi = "polisi",
	debt_collector = "debt_collector",
}

function NpcModelCandidates.recipeFor(npcId: string?): any?
	if type(npcId) ~= "string" then
		return nil
	end
	local key = NpcModelCandidates.alias[npcId]
	return if key then NpcModelCandidates.recipes[key] else nil
end

return NpcModelCandidates
