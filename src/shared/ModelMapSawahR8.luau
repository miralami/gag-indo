--!strict
-- ModelMapSawahR8: pure data for the OFF-BY-DEFAULT "sawah_r8" LookDev candidate
-- (WORK_QUEUE section M item 72). Terrace dressing: muddy water sheets, alang-alang verge tufts,
-- one small field hut on terrace 2 and a few stepping stones between terraces.
--
-- Pure data/functions only: no Roblox APIs, no Instances, no Enums, no asset IDs. Procedural Parts
-- are built by src/server/World/LookDevSawahR8.luau, so no uploaded asset ID exists or is needed.
-- Terrace bands and water panes mirror MapSpec; panes are passed in so this module stays pure.

local ModelMapSawahR8 = {}

ModelMapSawahR8.id = "sawah_r8"
ModelMapSawahR8.folderName = "LookDevSawahR8_sawah_r8"
ModelMapSawahR8.WATER_TRANSPARENCY = 0.55
ModelMapSawahR8.WATER_COLOR = { 86, 104, 52 } -- muddy green-brown paddy water
ModelMapSawahR8.MIN_VERGE_TUFTS = 40
ModelMapSawahR8.TERRACE_TOPS = { 4.5, 8.5, 12.5, 16.5 }
ModelMapSawahR8.TERRACE_BANDS = {
	{ z0 = -328, z1 = -312 },
	{ z0 = -344, z1 = -328 },
	{ z0 = -360, z1 = -344 },
	{ z0 = -376, z1 = -360 },
}
ModelMapSawahR8.SIDES = { "west", "east" }
ModelMapSawahR8.TUFTS_PER_EDGE = 5
ModelMapSawahR8.BLADE_OFFSETS = {
	{ -0.35, 0, 0 },
	{ 0, 0.2, 0 },
	{ 0.35, 0, 0 },
}
ModelMapSawahR8.BLADE_HEIGHTS = { 1.6, 2.1, 1.4 }

function ModelMapSawahR8.terraceIndices(): { number }
	local out = {}
	for index = 1, #ModelMapSawahR8.TERRACE_TOPS do
		out[index] = index
	end
	return out
end

-- MapSpec.paddyWater() emits two panes per terrace, west then east, in terrace order.
function ModelMapSawahR8.waterPanes(panes: any, terrace: number): { any }
	if type(panes) ~= "table" or terrace < 1 or terrace > #ModelMapSawahR8.TERRACE_TOPS then
		return {}
	end
	local first = (terrace - 1) * 2 + 1
	return { panes[first], panes[first + 1] }
end

-- Alang-alang tufts sit on the 2-stud bund just outside each pane's north and south edge, never
-- inside the water rectangle. Five tufts per edge, two edges per pane, two panes per terrace:
-- 20 tufts per terrace, 80 total, each drawn as three thin blades by the applier. Deterministic.
function ModelMapSawahR8.vergeTufts(panes: any): { any }
	local tufts = {}
	for _, terrace in ModelMapSawahR8.terraceIndices() do
		local pair = ModelMapSawahR8.waterPanes(panes, terrace)
		for sideIndex, pane in ipairs(pair) do
			if type(pane) == "table" and type(pane.centre) == "table" and type(pane.size) == "table" then
				local zNorth = pane.centre[3] - pane.size[3] / 2 - 1
				local zSouth = pane.centre[3] + pane.size[3] / 2 + 1
				local spread = pane.size[1] / 2 - 4
				for _, z in ipairs({ zNorth, zSouth }) do
					for step = 1, ModelMapSawahR8.TUFTS_PER_EDGE do
						local offset = (step - (ModelMapSawahR8.TUFTS_PER_EDGE + 1) / 2)
							/ ((ModelMapSawahR8.TUFTS_PER_EDGE - 1) / 2)
						tufts[#tufts + 1] = {
							terrace = terrace,
							side = ModelMapSawahR8.SIDES[sideIndex],
							x = pane.centre[1] + offset * spread,
							y = pane.top,
							z = z,
							blades = ModelMapSawahR8.BLADE_OFFSETS,
						}
					end
				end
			end
		end
	end
	return tufts
end

-- Terrace 2, west lane: on the bund at the pane's south edge, far from the central ramp.
function ModelMapSawahR8.gubukPosition(panes: any, terrace: number?): { [string]: number }
	local pair = ModelMapSawahR8.waterPanes(panes, terrace or 2)
	local pane = pair[1]
	if type(pane) ~= "table" or type(pane.centre) ~= "table" or type(pane.size) ~= "table" then
		return { x = 0, y = 0, z = 0 }
	end
	return {
		x = pane.centre[1] + pane.size[1] / 4,
		y = pane.top,
		z = pane.centre[3] - pane.size[3] / 2 - 1,
	}
end

-- 4 corner posts, one thatch roof and one bench: exactly one roof identifies the single hut.
function ModelMapSawahR8.gubukParts(): { any }
	return {
		{ kind = "gubuk_post", lx = -1.8, ly = 1.6, lz = -0.55, size = { 0.35, 3.2, 0.35 } },
		{ kind = "gubuk_post", lx = 1.8, ly = 1.6, lz = -0.55, size = { 0.35, 3.2, 0.35 } },
		{ kind = "gubuk_post", lx = -1.8, ly = 1.6, lz = 0.55, size = { 0.35, 3.2, 0.35 } },
		{ kind = "gubuk_post", lx = 1.8, ly = 1.6, lz = 0.55, size = { 0.35, 3.2, 0.35 } },
		{ kind = "gubuk_roof", lx = 0, ly = 3.5, lz = 0, size = { 5.2, 0.4, 2.4 } },
		{ kind = "gubuk_bench", lx = 0, ly = 0.85, lz = 0, size = { 2.6, 0.25, 0.6 } },
	}
end

-- Three flat stones, one on the bund at each terrace boundary, alternating west/east lanes.
function ModelMapSawahR8.steppingStones(): { any }
	local out = {}
	for index = 1, #ModelMapSawahR8.TERRACE_TOPS - 1 do
		out[index] = {
			terrace = index + 1,
			x = if index % 2 == 1 then -52 else 52,
			y = ModelMapSawahR8.TERRACE_TOPS[index + 1] + 0.15,
			z = ModelMapSawahR8.TERRACE_BANDS[index].z0,
			size = { 4, 0.4, 3 },
		}
	end
	return out
end

return ModelMapSawahR8
