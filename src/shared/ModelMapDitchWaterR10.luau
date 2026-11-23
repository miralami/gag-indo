--!strict
-- ModelMapDitchWaterR10: pure data for the OFF-BY-DEFAULT "ditch_water_r10" candidate
-- (WORK_QUEUE items 207 / 263, rebuilt after the sprint-5 hero shots showed no water). Each plot
-- gets a visible irrigation channel along its outer (+Z) long side: a dark Mud bed, two raised Mud
-- banks and a teal Glass water sheet between them. The ground under the plots is solid, so the
-- "trench" is built UP: the banks stand 0.5 above the soil line and the water surface sits 0.2 to
-- 0.4 below the bank tops, which reads as a sunken channel from a 30 degree eye. No engine calls,
-- no asset IDs: a server applier consumes these descriptors. Materials are names, mapped to the
-- engine enum by the applier.

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
	material: string,
}

local Data = {}

Data.id = "ditch_water_r10"
Data.folderName = "LookDevDitchWaterR10_ditch_water_r10"

Data.PLOT_COUNT = 10
Data.DITCH_WIDTH = 2 -- plots_r8 ditch cross-section the channel is laid over
Data.WATER_WIDTH = 2.4 -- item 263 rework: water sheet across, >= MIN_WATER_WIDTH
Data.MIN_WATER_WIDTH = 2 -- water sheet >= 2 studs across
Data.SOIL_Y = 0.5 -- World.Ground.Y: the plot soil line
Data.STRIPS_PER_PLOT = 2
Data.PLOT_WIDTH = 34
Data.PLOT_DEPTH = 34
Data.STRIP_THICKNESS = 0.14
Data.TRANSPARENCY = 0.25
Data.BED_THICKNESS = 0.1
Data.BANK_HEIGHT = 0.5
Data.BANK_WIDTH = 1.2
Data.BANK_TOP = Data.SOIL_Y + Data.BANK_HEIGHT -- 1.0
Data.WATER_Y = Data.SOIL_Y + Data.BED_THICKNESS + Data.STRIP_THICKNESS / 2 -- centre of the water sheet
Data.WATER_TOP = Data.WATER_Y + Data.STRIP_THICKNESS / 2 -- 0.74
Data.BAND_MIN = 0.2 -- bank top minus water top must sit in [0.2, 0.4]
Data.BAND_MAX = 0.4
Data.COLOR_TOLERANCE = 12

Data.WATER_COLOR = { r = 60, g = 130, b = 140 }
Data.BED_COLOR = { r = 58, g = 42, b = 30 }
Data.BANK_COLOR = { r = 88, g = 64, b = 44 }
Data.MATERIALS = { ditch_water = "Glass", ditch_bed = "Mud", ditch_bank = "Mud" }

-- Positions are world-space from Config.Game.plotCenter with the same yaw frame plots_r8 uses
-- (local +Z faces away from the village centre), so no engine APIs are needed here: its +Z axis is
-- (x, z)/r, and CFrame.Angles(0, yaw, 0) has +Z = (sin(yaw), cos(yaw)), hence yaw = atan2(x, z).
local function worldPosition(index: number, lx: number, ly: number, lz: number): { number }
	local px, pz = Game.plotCenter(index)
	local radius = math.sqrt(px * px + pz * pz)
	if radius <= 0 then
		return { px + lx, ly, pz + lz }
	end
	local backX, backZ = px / radius, pz / radius
	local rightX, rightZ = backZ, -backX
	return { px + lx * rightX + lz * backX, ly, pz + lx * rightZ + lz * backZ }
end

local function sheetZ(): number
	return Data.PLOT_DEPTH / 2 + 1 + Data.DITCH_WIDTH / 2
end

local function copyColor(color: RGB): RGB
	return { r = color.r, g = color.g, b = color.b }
end

-- The water sheet: two strips per plot that together span the plot width less the corner posts.
function Data.parts(): { PartDescriptor }
	local out: { PartDescriptor } = {}
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
				position = worldPosition(index, lx, Data.WATER_Y, sheetZ()),
				yaw = yaw,
				size = { stripLength, Data.STRIP_THICKNESS, Data.WATER_WIDTH },
				color = copyColor(Data.WATER_COLOR),
				transparency = Data.TRANSPARENCY,
				kind = "ditch_water",
				material = Data.MATERIALS.ditch_water,
			}
		end
	end
	return out
end

-- The earthworks: one dark bed under the water and an inner and an outer bank per plot.
function Data.banks(): { PartDescriptor }
	local out: { PartDescriptor } = {}
	local span = Data.PLOT_WIDTH - 2
	local bankOffset = Data.WATER_WIDTH / 2 + Data.BANK_WIDTH / 2
	for index = 1, Data.PLOT_COUNT do
		local px, pz = Game.plotCenter(index)
		local yaw = math.atan2(px, pz)
		out[#out + 1] = {
			name = `DitchBed_{index}`,
			plot = index,
			position = worldPosition(index, 0, Data.SOIL_Y + Data.BED_THICKNESS / 2, sheetZ()),
			yaw = yaw,
			size = { span, Data.BED_THICKNESS, Data.WATER_WIDTH },
			color = copyColor(Data.BED_COLOR),
			transparency = 0,
			kind = "ditch_bed",
			material = Data.MATERIALS.ditch_bed,
		}
		for side = 1, 2 do
			local sign = if side == 1 then -1 else 1
			out[#out + 1] = {
				name = `DitchBank_{index}_{side}`,
				plot = index,
				position = worldPosition(index, 0, Data.SOIL_Y + Data.BANK_HEIGHT / 2, sheetZ() + sign * bankOffset),
				yaw = yaw,
				size = { span, Data.BANK_HEIGHT, Data.BANK_WIDTH },
				color = copyColor(Data.BANK_COLOR),
				transparency = 0,
				kind = "ditch_bank",
				material = Data.MATERIALS.ditch_bank,
			}
		end
	end
	return out
end

-- Load-time contract check: keeps the pure data honest before any applier or harness reads it.
do
	local parts = Data.parts()
	local banks = Data.banks()
	assert(Data.PLOT_COUNT == 10, "ditch_water_r10: plot count is not 10")
	assert(Data.STRIPS_PER_PLOT >= 1, "ditch_water_r10: fewer than one strip per plot")
	assert(Data.WATER_WIDTH >= Data.MIN_WATER_WIDTH, "ditch_water_r10: water narrower than 2 studs")
	assert(Data.WATER_Y > Data.SOIL_Y, "ditch_water_r10: water is not above the soil line")
	local gap = Data.BANK_TOP - Data.WATER_TOP
	assert(gap >= Data.BAND_MIN and gap <= Data.BAND_MAX, "ditch_water_r10: water not 0.2-0.4 below the bank top")
	assert(#parts == Data.PLOT_COUNT * Data.STRIPS_PER_PLOT, "ditch_water_r10: part count does not match plot count")
	assert(#banks == Data.PLOT_COUNT * 3, "ditch_water_r10: bank count is not 3 per plot")
	local perPlot = {}
	for _, part in ipairs(parts) do
		perPlot[part.plot] = (perPlot[part.plot] or 0) + 1
		assert(part.size[3] >= Data.MIN_WATER_WIDTH, "ditch_water_r10: strip narrower than 2 studs")
		assert(part.position[2] > Data.SOIL_Y, "ditch_water_r10: strip is not above the soil line")
		assert(part.size[2] == Data.STRIP_THICKNESS, "ditch_water_r10: strip is not thin glass")
		assert(part.transparency >= 0.2 and part.transparency <= 0.3, "ditch_water_r10: transparency outside 0.2-0.3")
		assert(part.kind == "ditch_water", "ditch_water_r10: unexpected part kind")
	end
	for index = 1, Data.PLOT_COUNT do
		assert(perPlot[index] == Data.STRIPS_PER_PLOT, "ditch_water_r10: strip count per plot is not constant")
	end
	for _, bank in ipairs(banks) do
		assert(bank.kind == "ditch_bed" or bank.kind == "ditch_bank", "ditch_water_r10: unexpected earthwork kind")
		assert(bank.material == "Mud", "ditch_water_r10: earthwork is not Mud")
	end
	for _, colour in ipairs({ Data.WATER_COLOR, Data.BED_COLOR, Data.BANK_COLOR }) do
		for _, channel in ipairs({ colour.r, colour.g, colour.b }) do
			assert(channel >= 0 and channel <= 255, "ditch_water_r10: colour channel outside 0..255")
		end
	end
end

return Data
