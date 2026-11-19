-- HubPropCandidates: pure-data hero-prop detail recipes for the round-2 "hubprops" LookDev
-- candidate (WORK_QUEUE item 8). Dresses the four shop/counter hubs named in the queue — warung
-- counter, pasar stall, pos polisi desk, Pak RT table — plus a lantern and a sign per hub, with
-- small Roblox primitive parts. NO asset IDs and no Roblox APIs at load time: pure data + pure
-- functions so Lune specs can validate every recipe without a DataModel.
--
-- Each recipe targets a hub model (matched by model name, found recursively in the world) and
-- attaches its parts to that hub's anchor BasePart. Offsets are in anchor-LOCAL space (the adapter
-- multiplies by the anchor CFrame), so details follow the hub's yaw for free. Colors are ART.md §3
-- palette tokens; materials are Enum.Material names resolved best-effort by the adapter.
-- Everything exists only while "hubprops" is enabled; the shipping greybox props are untouched.

local HubPropCandidates = {}

HubPropCandidates.palette = {
	tinta = "2b2118", tinta_lembut = "5b4a38", kertas = "f3e9d2", senja = "f6c97a",
	bambu = "b98a5a", kunyit = "c99a2e", padi = "9bb25a", daun = "6f8a3f",
	genteng = "a8452f", merah = "a83226", malam = "1f4e6b", indigo = "3b4f6b",
}

-- Keys follow MapSpec.HUBS keys. `model` matches the built hub Model's name (nested under
-- workspace.World), `anchor` matches the anchor BasePart child name.
HubPropCandidates.hubOrder = { "pasar", "warung", "polisi", "pakrt" }

HubPropCandidates.hubs = {
	pasar = {
		model = "Pasar", anchor = "Counter",
		parts = {
			{ name = "AwningStrip", shape = "Block", size = { 48, 0.3, 3 }, offset = { 0, 4.6, -2 }, color = "merah", material = "Fabric" },
			{ name = "ProduceCrateA", shape = "Block", size = { 3, 2, 3 }, offset = { -16, 5.6, 0 }, color = "bambu", material = "WoodPlanks" },
			{ name = "ProduceCrateB", shape = "Block", size = { 3, 2, 3 }, offset = { -12, 5.6, 0 }, color = "bambu", material = "WoodPlanks" },
			{ name = "ProducePileA", shape = "Sphere", size = { 2.4, 1.2, 2.4 }, offset = { -16, 7, 0 }, color = "padi", material = "SmoothPlastic" },
			{ name = "ProducePileB", shape = "Sphere", size = { 2.4, 1.2, 2.4 }, offset = { -12, 7, 0 }, color = "genteng", material = "SmoothPlastic" },
			{ name = "Timbangan", shape = "Cylinder", size = { 1.4, 0.4, 1.4 }, offset = { 8, 4.6, 0 }, color = "malam", material = "Metal" },
			{ name = "PriceTag", shape = "Block", size = { 2, 1.4, 0.2 }, offset = { 16, 5.8, 3 }, color = "kertas", material = "SmoothPlastic" },
			{ name = "HangingLantern", shape = "Sphere", size = { 1.6, 1.6, 1.6 }, offset = { 0, 8, 2 }, color = "senja", material = "SmoothPlastic" },
		},
	},
	warung = {
		model = "Warung", anchor = "Table",
		parts = {
			{ name = "CoffeeTray", shape = "Block", size = { 5, 0.3, 3 }, offset = { 0, 3.7, 0 }, color = "bambu", material = "WoodPlanks" },
			{ name = "CupA", shape = "Cylinder", size = { 0.8, 1, 0.8 }, offset = { -1.5, 4.4, 0 }, color = "kertas", material = "SmoothPlastic" },
			{ name = "CupB", shape = "Cylinder", size = { 0.8, 1, 0.8 }, offset = { 0, 4.4, 0 }, color = "kertas", material = "SmoothPlastic" },
			{ name = "CupC", shape = "Cylinder", size = { 0.8, 1, 0.8 }, offset = { 1.5, 4.4, 0 }, color = "kertas", material = "SmoothPlastic" },
			{ name = "Teapot", shape = "Sphere", size = { 1.6, 1.4, 1.6 }, offset = { 4, 4.4, 0 }, color = "genteng", material = "SmoothPlastic" },
			{ name = "StoolA", shape = "Cylinder", size = { 1.8, 2, 1.8 }, offset = { -5, -1, 4 }, color = "bambu", material = "WoodPlanks" },
			{ name = "StoolB", shape = "Cylinder", size = { 1.8, 2, 1.8 }, offset = { 5, -1, 4 }, color = "bambu", material = "WoodPlanks" },
			{ name = "HangingLantern", shape = "Sphere", size = { 1.6, 1.6, 1.6 }, offset = { 0, 7, 1 }, color = "senja", material = "SmoothPlastic" },
		},
	},
	polisi = {
		model = "PosPolisi", anchor = "Desk",
		parts = {
			{ name = "DeskLamp", shape = "Cylinder", size = { 0.5, 2.4, 0.5 }, offset = { 4, 5.6, 0 }, color = "tinta", material = "Metal" },
			{ name = "DeskLampShade", shape = "Sphere", size = { 1.4, 0.9, 1.4 }, offset = { 4, 6.8, 0 }, color = "senja", material = "SmoothPlastic" },
			{ name = "PaperStack", shape = "Block", size = { 3, 0.3, 2 }, offset = { -3, 3.7, 0 }, color = "kertas", material = "SmoothPlastic" },
			{ name = "InboxTray", shape = "Block", size = { 2.4, 0.4, 1.8 }, offset = { 0, 3.8, 0 }, color = "tinta_lembut", material = "SmoothPlastic" },
			{ name = "NamePlate", shape = "Block", size = { 3, 0.9, 0.2 }, offset = { 0, 4.6, 3 }, color = "malam", material = "SmoothPlastic" },
			{ name = "Pen", shape = "Cylinder", size = { 0.2, 1.4, 0.2 }, offset = { -3.4, 4.2, 0 }, color = "tinta", material = "SmoothPlastic" },
			{ name = "BadgeDisc", shape = "Cylinder", size = { 1.2, 0.2, 1.2 }, offset = { 3, 4, 0 }, color = "kunyit", material = "Metal" },
			{ name = "HangingLantern", shape = "Sphere", size = { 1.4, 1.4, 1.4 }, offset = { 0, 7, 1 }, color = "senja", material = "SmoothPlastic" },
		},
	},
	pakrt = {
		model = "RumahPakRT", anchor = "Table",
		parts = {
			{ name = "Ledger", shape = "Block", size = { 2, 0.3, 1.4 }, offset = { 0, 2.7, 0 }, color = "kertas", material = "SmoothPlastic" },
			{ name = "Envelope", shape = "Block", size = { 1.4, 0.1, 0.9 }, offset = { 1, 2.9, 0.3 }, color = "kertas", material = "SmoothPlastic" },
			{ name = "TeaCup", shape = "Cylinder", size = { 0.7, 0.8, 0.7 }, offset = { -1.4, 3, 0 }, color = "genteng", material = "SmoothPlastic" },
			{ name = "Teapot", shape = "Sphere", size = { 1.1, 0.9, 1.1 }, offset = { -1.4, 3.6, -1 }, color = "kunyit", material = "SmoothPlastic" },
			{ name = "ChairA", shape = "Block", size = { 1.6, 3, 1.6 }, offset = { -3.5, -1.5, 0 }, color = "bambu", material = "WoodPlanks" },
			{ name = "ChairB", shape = "Block", size = { 1.6, 3, 1.6 }, offset = { 3.5, -1.5, 0 }, color = "bambu", material = "WoodPlanks" },
			{ name = "HangingLantern", shape = "Sphere", size = { 1.3, 1.3, 1.3 }, offset = { 0, 6, 1 }, color = "senja", material = "SmoothPlastic" },
		},
	},
}

-- Sign dressing: one plaque + two posts, placed relative to the anchor. Shared by all four hubs,
-- with the hub's own accent colour token filled in by the adapter.
HubPropCandidates.signParts = {
	{ name = "SignPostL", shape = "Cylinder", size = { 0.3, 3, 0.3 }, offset = { -6, 1.5, 3.5 }, color = "tinta", material = "Metal" },
	{ name = "SignPostR", shape = "Cylinder", size = { 0.3, 3, 0.3 }, offset = { 6, 1.5, 3.5 }, color = "tinta", material = "Metal" },
	{ name = "SignBoard", shape = "Block", size = { 12, 2.2, 0.3 }, offset = { 0, 3.4, 3.5 }, color = "accent", material = "WoodPlanks" },
}

HubPropCandidates.ACCENT = {
	pasar = "merah", warung = "genteng", polisi = "malam", pakrt = "kunyit",
}

-- Flat list of every part descriptor for one hub (detail parts + sign dressing). The single source
-- used by the Studio adapter and the gallery preview generator. Returns nil for an unknown hub.
function HubPropCandidates.partsFor(hubKey: string): any?
	local hub = HubPropCandidates.hubs[hubKey]
	if not hub then
		return nil
	end
	local accent = HubPropCandidates.ACCENT[hubKey] or "tinta"
	local out = {}
	for _, p in hub.parts do
		out[#out + 1] = p
	end
	for _, p in HubPropCandidates.signParts do
		local copy = {
			name = p.name, shape = p.shape, size = p.size, offset = p.offset,
			color = if p.color == "accent" then accent else p.color, material = p.material,
		}
		out[#out + 1] = copy
	end
	return out
end

return HubPropCandidates
