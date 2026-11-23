--!strict
-- ModelMapDitchWaterR10: pure data for the OFF-BY-DEFAULT "ditch_water_r10" candidate
-- (WORK_QUEUE item 207). Thin glassy Parts laid over the 2-stud plots_r8 ditch, tinted with the
-- same teal as shipping water variant A. No engine calls, no asset IDs: a server applier consumes
-- these descriptors. The candidates, review paths and docs are wired by the main session.

local Game = require(script.Parent.Config.Game)

type RGB = { r: number, g: number, b: number }
type PartDescriptor = {
	name: string,
	plot: number,
	position: { number },
	yaw: number,
	size: { number },
	color: RGB,
	transparency: number,
	kind: string,
}

local Data = {}

Data.id = "ditch_water_r10"
Data.folderName = "LookDevDitchWaterR10_ditch_water_r10"

Data.PLOT_COUNT = 10
Data.DITCH_WIDTH = 2
Data.MIN_WATER_WIDTH = 2 -- item 263: water sheet >= 2 studs across
Data.SOIL_Y = 0.5 -- World.Ground.Y: the plot soil line
Data.STRIPS_PER_PLOT = 2
Data.PLOT_WIDTH = 34
Data.PLOT_DEPTH = 34
Data.STRIP_THICKNESS = 0.12
Data.TRANSPARENCY = 0.35
Data.WATER_Y = 0.58 -- item 263: above the soil line
Data.COLOR_TOLERANCE = 12

-- Exact variant-A teal from src/shared/ModelMapWaterR8.luau:
--   variants.a.values.WaterColor = { r = 48, g = 124, b = 104 } -- "clear tropical green"
-- ShippingLookR7 selects that shipping water look; the palette itself lives in ModelMapWaterR8.
Data.WATER_COLOR = { r = 48, g = 124, b = 104 }

-- plots_r8's ditchLayout puts a single 2-stud sheet on the OUTER (+Z) edge, span = width - 2.
-- Two strips split that sheet into equal halves; each keeps the ditch's 2-stud cross-section.
-- Positions are world-space from Config.Game.plotCenter with the same yaw frame plots_r8 uses
-- (local +Z faces away from the village centre), so no engine APIs are needed here. That frame is
-- CFrame.lookAt(Vector3.new(x, 0, z), Vector3.zero) (LookDevPlotsR8.luau plotFrame): its +Z axis is
-- (x, z)/r, and CFrame.Angles(0, yaw, 0) has +Z = (sin(yaw), cos(yaw)), hence yaw = atan2(x, z).
local function worldPosition(index: number, lx: number, lz: number): { number }
	local px, pz = Game.plotCenter(index)
	local radius = math.sqrt(px * px + pz * pz)
	if radius <= 0 then
		return { px + lx, Data.WATER_Y, pz + lz }
	end
	local backX, backZ = px / radius, pz / radius
	local rightX, rightZ = backZ, -backX
	return { px + lx * rightX + lz * backX, Data.WATER_Y, pz + lx * rightZ + lz * backZ }
end

function Data.parts(): { PartDescriptor }
	local out: { PartDescriptor } = {}
	local sheetZ = Data.PLOT_DEPTH / 2 + 1 + Data.DITCH_WIDTH / 2
	local span = Data.PLOT_WIDTH - 2
	local stripLength = span / Data.STRIPS_PER_PLOT
	for index = 1, Data.PLOT_COUNT do
		local px, pz = Game.plotCenter(index)
		local yaw = math.atan2(px, pz)
		for strip = 1, Data.STRIPS_PER_PLOT do
			local lx = -span / 2 + stripLength / 2 + (strip - 1) * stripLength
			out[#out + 1] = {
				name = `DitchWaterGlass_{index}_{strip}`,
				plot = index,
				position = worldPosition(index, lx, sheetZ),
				yaw = yaw,
				size = { stripLength, Data.STRIP_THICKNESS, Data.DITCH_WIDTH },
				color = {
					r = Data.WATER_COLOR.r,
					g = Data.WATER_COLOR.g,
					b = Data.WATER_COLOR.b,
				},
				transparency = Data.TRANSPARENCY,
				kind = "ditch_water",
			}
		end
	end
	return out
end

-- Load-time contract check: keeps the pure data honest before any applier or harness reads it.
do
	local parts = Data.parts()
	assert(Data.PLOT_COUNT == 10, "ditch_water_r10: plot count is not 10")
	assert(Data.STRIPS_PER_PLOT >= 1, "ditch_water_r10: fewer than one strip per plot")
	assert(Data.DITCH_WIDTH >= Data.MIN_WATER_WIDTH, "ditch_water_r10: water narrower than 2 studs")
	assert(Data.WATER_Y > Data.SOIL_Y, "ditch_water_r10: water is not above the soil line")
	assert(#parts == Data.PLOT_COUNT * Data.STRIPS_PER_PLOT, "ditch_water_r10: part count does not match plot count")
	local perPlot = {}
	for _, part in ipairs(parts) do
		perPlot[part.plot] = (perPlot[part.plot] or 0) + 1
		assert(part.size[3] == Data.DITCH_WIDTH, "ditch_water_r10: strip width does not match the 2-stud ditch width")
		assert(part.size[3] >= Data.MIN_WATER_WIDTH, "ditch_water_r10: strip narrower than 2 studs")
		assert(part.position[2] > Data.SOIL_Y, "ditch_water_r10: strip is not above the soil line")
		assert(part.size[2] == 0.12, "ditch_water_r10: strip is not thin glass")
		assert(part.kind == "ditch_water", "ditch_water_r10: unexpected part kind")
	end
	for index = 1, Data.PLOT_COUNT do
		assert(perPlot[index] == Data.STRIPS_PER_PLOT, "ditch_water_r10: strip count per plot is not constant")
	end
	for _, channel in ipairs({ Data.WATER_COLOR.r, Data.WATER_COLOR.g, Data.WATER_COLOR.b }) do
		assert(channel >= 0 and channel <= 255, "ditch_water_r10: colour channel outside 0..255")
	end
end

return Data
