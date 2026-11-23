--!strict
-- Pure data for WORK_QUEUE item 215: DEFAULT-look sawah dressing. One gubuk per terrace group,
-- two scarecrows in the fields and bird-scare ribbons on poles. Geometry comes from the existing
-- Canonical/Plots/Sawah descriptors; only placement, palette keys and the tag contract are new.
-- No engine calls, no instances, no Ball. The default recipe has no asset IDs; item 271 publishes
-- baked provenance in Data.BAKED_IDS. Greybox stages every descriptor anchored,
-- non-collidable and non-interactive, with SawahDressing=true, SawahDressingKind and
-- SawahDressingGroup set from the fields below.

local Canonical = require(script.Parent.ModelMapCanonicalR10)
local Plots = require(script.Parent.ModelMapPlotsR8)
local Sawah = require(script.Parent.ModelMapSawahR8)

local Data = {}

Data.id = "sawah_dressing_215"
Data.folderName = "LookDevSawahDressingQ215_sawah_dressing_215"

Data.TAG = "SawahDressing"
Data.KIND_ATTR = "SawahDressingKind"
Data.GROUP_ATTR = "SawahDressingGroup"
Data.KINDS = { "gubuk", "scarecrow", "ribbon" }
Data.MIN_GUBUK = 1
Data.MIN_SCARECROWS = 2
Data.MAX_FLOATER_GAP = 0.3

-- Existing Props.palette keys only; Greybox resolves these, this module stays pure RGB-free.
Data.PALETTE_NAMES = { "bambu", "kertas", "genteng", "merah", "kunyit", "daun", "tintaLembut" }

local GUBUK_COLOURS = {
	gubuk_post = "bambu",
	gubuk_floor = "bambu",
	gubuk_wall = "kertas",
	gubuk_roof = "genteng",
	gubuk_bench = "tintaLembut",
	gubuk = "bambu",
}
local SCARECROW_COLOURS = { "bambu", "merah", "bambu", "kunyit" }
local RIBBON_COLOURS = { "merah", "kertas", "kunyit", "daun" }

local function descriptor(
	group: string,
	index: number,
	kind: string,
	name: string,
	shape: string,
	x: number,
	y: number,
	z: number,
	sx: number,
	sy: number,
	sz: number,
	colour: string,
	grounded: boolean,
	rz: number?
): any
	return {
		name = group .. "_" .. string.format("%02d", index) .. "_" .. name,
		group = group,
		kind = kind,
		shape = shape,
		x = x,
		y = y,
		z = z,
		sx = sx,
		sy = sy,
		sz = sz,
		colour = colour,
		rz = rz or 0,
		grounded = grounded,
		anchored = true,
		canCollide = false,
		interactive = false,
	}
end

-- Mirror of MapSpec.paddyWater() for the pure load-time self-check. Production callers pass the
-- real panes. ponytail: if MapSpec ever changes its terrace bands, derive this from a shared table.
function Data.samplePanes(): { any }
	local out = {}
	for terrace, top in ipairs(Sawah.TERRACE_TOPS) do
		local band = Sawah.TERRACE_BANDS[terrace]
		local z = (band.z0 + band.z1) / 2
		for _, side in ipairs({ -1, 1 }) do
			out[#out + 1] = {
				centre = { side * 191, top + 0.2, z },
				size = { 296, 0.2, band.z1 - band.z0 - 4 },
				top = top,
			}
		end
	end
	return out
end

local function paneAt(panes: any, index: number): any
	return type(panes) == "table" and panes[index] or nil
end

local function addGubuk(out: { any }, panes: any, terrace: number)
	local base = Sawah.gubukPosition(panes, terrace)
	-- gubukPosition lands on the terrace boundary; pull it inside so a terrain raycast at the hut
	-- centre hits this terrace's own top instead of the next one up.
	local z = base.z + 3.5
	local group = "GubukT" .. tostring(terrace)
	local useCanonical = terrace % 2 == 0
	local source = if useCanonical then Canonical.gubukParts() else Sawah.gubukParts()
	for index, def in ipairs(source) do
		local dx = if useCanonical then def.dx else def.lx
		local dy = if useCanonical then def.dy else def.ly
		local dz = if useCanonical then def.dz else def.lz
		local shape = if useCanonical
			then def.shape
			else if string.find(def.kind, "post", 1, true) then "Cylinder" else "Block"
		-- Canonical floor bottoms at 0 and posts at 0.4; sink that variant so its posts touch.
		local sink = if useCanonical then 0.4 else 0
		local colour = GUBUK_COLOURS[def.kind] or "bambu"
		out[#out + 1] = descriptor(
			group,
			index,
			"gubuk",
			def.kind,
			shape,
			base.x + dx,
			base.y + dy - sink,
			z + dz,
			def.size[1],
			def.size[2],
			def.size[3],
			colour,
			def.kind == "gubuk_post" or def.kind == "gubuk_floor",
			if useCanonical then def.rz else 0
		)
	end
end

local function addScarecrow(out: { any }, pane: any, groupBase: string, index: number, side: number)
	if type(pane) ~= "table" or type(pane.centre) ~= "table" or type(pane.size) ~= "table" then
		return
	end
	local group = groupBase .. "_" .. string.format("%02d", index)
	local ox = pane.centre[1] + side * pane.size[1] / 6
	local oz = pane.centre[3] + (if side > 0 then 4 else -4)
	local source = Plots.scarecrowParts()
	for partIndex, def in ipairs(source) do
		local sx, sy, sz = def.thickness, def.length, def.thickness
		if def.axis == "x" then
			sx, sy, sz = def.length, def.thickness, def.thickness
		end
		out[#out + 1] = descriptor(
			group,
			partIndex,
			"scarecrow",
			if partIndex == 1 then "pole" else "body" .. tostring(partIndex),
			if partIndex == 1 then "Cylinder" else "Block",
			ox + def.lx,
			pane.top + def.ly,
			oz + def.lz,
			sx,
			sy,
			sz,
			SCARECROW_COLOURS[partIndex] or "bambu",
			partIndex == 1
		)
	end
end

local function addRibbon(out: { any }, pane: any, terrace: number)
	if type(pane) ~= "table" or type(pane.centre) ~= "table" or type(pane.size) ~= "table" then
		return
	end
	local group = "RibbonT" .. tostring(terrace)
	local x = pane.centre[1] - pane.size[1] / 4
	local z = pane.centre[3] + 3
	out[#out + 1] = descriptor(group, 1, "ribbon", "pole", "Cylinder", x, pane.top + 3, z, 0.3, 6, 0.3, "bambu", true)
	for strip, colour in ipairs(RIBBON_COLOURS) do
		out[#out + 1] = descriptor(
			group,
			strip + 1,
			"ribbon",
			"strip" .. tostring(strip),
			"Block",
			x + (if strip % 2 == 0 then 0.9 else -0.9),
			pane.top + 2.8 + strip * 0.7,
			z,
			2.4,
			0.45,
			0.06,
			colour,
			false
		)
	end
end

-- Pure: panes are MapSpec.paddyWater() (west then east, four terraces in order). Real callers pass
-- those; the self-check below uses Data.samplePanes().
function Data.parts(panes: any?): { any }
	local water = panes or Data.samplePanes()
	local out = {}
	for _, terrace in ipairs(Sawah.terraceIndices()) do
		addGubuk(out, water, terrace)
	end
	addScarecrow(out, paneAt(water, 1), "ScarecrowA", 1, 1)
	addScarecrow(out, paneAt(water, 6), "ScarecrowB", 2, -1)
	for _, terrace in ipairs(Sawah.terraceIndices()) do
		addRibbon(out, paneAt(water, (terrace - 1) * 2 + 1), terrace)
	end
	return out
end

-- Item 271 additive baked overlay. The primitive gubuk/scarecrow/ribbon recipe above is the DEFAULT
-- look and stays untouched. This companion recipe names which already-baked Creator Store models
-- (resolved to IDs by the applier from ModelMapBuildingsR8 / ModelMapSawahR8) make the field read as
-- a sawah: a nipa hut per terrace plus padi clumps around the scarecrow and ribbon poles.
Data.MODEL_KINDS = { "gubuk_model", "padi_accent" }
Data.PADI_PER_TERRACE = 4
Data.GUBUK_WIDTH = 8
Data.GUBUK_HEIGHT = 5
Data.PADI_WIDTH = 1.6
Data.PADI_HEIGHT = 2.1

-- Baked provenance for the overlay, all already in ServerStorage.LookDevAssets.
-- ponytail: the real nipa hut is not baked; the baked house stands in at small scale
-- until the designer bakes the hut, then this ID can be swapped without touching the applier.
Data.BAKED_IDS = {
	gubuk_model = 18239791051,
	padi_accent = 13286158859,
}

function Data.modelParts(panes: any?): { any }
	local water = panes or Data.samplePanes()
	local out = {}
	for _, terrace in ipairs(Sawah.terraceIndices()) do
		local pane = paneAt(water, (terrace - 1) * 2 + 1)
		if type(pane) == "table" and type(pane.centre) == "table" and type(pane.size) == "table" then
			local base = Sawah.gubukPosition(water, terrace)
			out[#out + 1] = {
				name = "GubukModel_T" .. tostring(terrace),
				group = "GubukT" .. tostring(terrace),
				kind = "gubuk_model",
				modelSource = "nipa_hut",
				x = base.x,
				y = pane.top,
				z = base.z + 3.5,
				targetWidth = Data.GUBUK_WIDTH,
				targetHeight = Data.GUBUK_HEIGHT,
			}
			local offsets = { -0.3, -0.1, 0.1, 0.3 }
			for index, fraction in ipairs(offsets) do
				out[#out + 1] = {
					name = string.format("PadiAccent_T%d_%02d", terrace, index),
					group = "RibbonT" .. tostring(terrace),
					kind = "padi_accent",
					modelSource = "padi_model",
					x = pane.centre[1] + pane.size[1] * fraction,
					y = pane.top,
					z = pane.centre[3] + (if index % 2 == 0 then 2 else -2),
					targetWidth = Data.PADI_WIDTH,
					targetHeight = Data.PADI_HEIGHT,
				}
			end
		end
	end
	return out
end

-- Load-time self-check: keeps the tag contract, the one-gubuk-per-terrace rule, the two scarecrows,
-- the no-Ball/no-ID staging contract and descriptor validity honest without any engine dependency.
local sample = Data.parts(Data.samplePanes())
assert(Data.TAG == "SawahDressing", "sawah_dressing_q215: tag changed")
assert(
	type(Data.BAKED_IDS.gubuk_model) == "number" and Data.BAKED_IDS.gubuk_model > 0,
	"sawah_dressing_q215: baked hut ID missing"
)
assert(
	type(Data.BAKED_IDS.padi_accent) == "number" and Data.BAKED_IDS.padi_accent > 0,
	"sawah_dressing_q215: baked padi ID missing"
)
assert(Data.KIND_ATTR == "SawahDressingKind", "sawah_dressing_q215: kind attribute changed")
assert(#Data.KINDS == 3, "sawah_dressing_q215: kind count changed")
assert(#Sawah.gubukParts() >= 4, "sawah_dressing_q215: sawah gubuk recipe changed")
assert(#Canonical.gubukParts() >= 6, "sawah_dressing_q215: canonical gubuk recipe changed")
assert(#Plots.scarecrowParts() >= 4, "sawah_dressing_q215: scarecrow recipe changed")
assert(#sample > 0, "sawah_dressing_q215: empty recipe")
local gubukGroups, scarecrowGroups, ribbonGroups = {}, {}, {}
local palette = {}
for _, name in ipairs(Data.PALETTE_NAMES) do
	palette[name] = true
end
for _, def in ipairs(sample) do
	assert(def.shape ~= "Ball", "sawah_dressing_q215: Ball shape is not allowed")
	assert(def.sx > 0 and def.sy > 0 and def.sz > 0, "sawah_dressing_q215: non-positive part size")
	assert(palette[def.colour] == true, "sawah_dressing_q215: unknown palette key " .. tostring(def.colour))
	assert(
		def.anchored == true and def.canCollide == false and def.interactive == false,
		"sawah_dressing_q215: unsafe staging flags"
	)
	assert(def.group ~= nil and def.kind ~= nil and def.name ~= nil, "sawah_dressing_q215: missing descriptor identity")
	if def.kind == "gubuk" then
		gubukGroups[def.group] = true
	elseif def.kind == "scarecrow" then
		scarecrowGroups[def.group] = true
	elseif def.kind == "ribbon" then
		ribbonGroups[def.group] = true
	else
		error("sawah_dressing_q215: unexpected kind " .. tostring(def.kind))
	end
end
local function count(set: { [string]: boolean }): number
	local n = 0
	for _ in pairs(set) do
		n += 1
	end
	return n
end
assert(count(gubukGroups) == #Sawah.TERRACE_TOPS, "sawah_dressing_q215: not one gubuk per terrace")
assert(count(scarecrowGroups) >= Data.MIN_SCARECROWS, "sawah_dressing_q215: fewer than two scarecrows")
assert(count(ribbonGroups) >= #Sawah.TERRACE_TOPS, "sawah_dressing_q215: ribbons missing from a terrace")
local models = Data.modelParts()
assert(#models == #Sawah.TERRACE_TOPS * (1 + Data.PADI_PER_TERRACE), "sawah_dressing_q215: baked overlay incomplete")
for _, def in ipairs(models) do
	assert(
		def.modelSource == "nipa_hut" or def.modelSource == "padi_model",
		"sawah_dressing_q215: unknown baked model source"
	)
	assert(def.targetWidth > 0 and def.targetHeight > 0, "sawah_dressing_q215: non-positive baked model target")
end

return Data
