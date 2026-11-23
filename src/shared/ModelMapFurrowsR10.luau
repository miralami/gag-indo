--!strict
-- ModelMapFurrowsR10: pure data for "furrows_r10" (WORK_QUEUE items 205 / 263). Raised soil rows
-- (>=0.3 studs above the soil line, CastShadow in the server applier) inside every plot footprint,
-- alternating dark/light soil. Item 263 also repaints the single showcase plot's grass voxels to
-- Ground; the bounds are pure numbers from Config.Game.plotCenter and grid-aligned by the applier.
-- Geometry comes from Config.Game.plotCenter and ModelMapPlotsR8's plot footprint; no engine calls,
-- no asset IDs, no crop changes. The server applier consumes these descriptors; the Studio check
-- measures the staged Parts in the live DataModel.

local Game = require(script.Parent.Config.Game)

local Data = {}

type Vec3 = { number }
type Bounds = { [number]: Vec3 }
type RGB = { r: number, g: number, b: number }
type StripDescriptor = {
	name: string,
	plot: number,
	position: Vec3,
	size: Vec3,
	color: RGB,
	kind: string,
}

Data.id = "furrows_r10"
Data.folderName = "LookDevFurrowsR10_furrows_r10"

Data.PLOT_COUNT = 10
Data.STRIPS_PER_PLOT = 5 -- >= 4; five parallel rows read as tilled soil from above
Data.PLOT_WIDTH = 34 -- ModelMapPlotsR8.PLOT_WIDTH
Data.PLOT_DEPTH = 34 -- ModelMapPlotsR8.PLOT_DEPTH
Data.DITCH_WIDTH = 2 -- ModelMapPlotsR8.DITCH_WIDTH (outside the soil footprint)
Data.STRIP_WIDTH = 1.2
Data.GROUND_Y = 0.5 -- World.Ground.Y: the real plot soil top surface
Data.MIN_RELIEF = 0.3 -- item 263: rows must stand >= 0.3 studs above the soil
Data.STRIP_HEIGHT = 0.4
Data.STRIP_LENGTH = Data.PLOT_DEPTH - 2 -- ends stop 1 stud inside each plot edge, clear of the ditch
Data.STRIP_SPACING = 6
Data.FURROW_Y = Data.GROUND_Y + Data.STRIP_HEIGHT / 2 -- bottom rests on the soil, top casts a shadow

Data.DARK_SOIL = { r = 72, g = 58, b = 40 }
Data.LIGHT_SOIL = { r = 96, g = 78, b = 52 }

-- Item 263: ONE showcase plot gets its grass repainted (Grass -> Ground, occupancy untouched).
Data.DEMO_PLOT = 3
Data.REPAINT_VOXEL = 4 -- Terrain's authoring grid, as in ShippingLookR7
Data.REPAINT_Y0 = -4
Data.REPAINT_Y1 = 8
Data.REPAINT_PAD = 1

-- Exact plot_aerial_NN names registered in Shared.ReviewCameras (one per configured plot).
Data.CAMERA_NAMES = {
	"plot_aerial_01",
	"plot_aerial_02",
	"plot_aerial_03",
	"plot_aerial_04",
	"plot_aerial_05",
	"plot_aerial_06",
	"plot_aerial_07",
	"plot_aerial_08",
	"plot_aerial_09",
	"plot_aerial_10",
}

function Data.parts(): { StripDescriptor }
	local strips: { StripDescriptor } = {}
	for plot = 1, Data.PLOT_COUNT do
		local cx, cz = Game.plotCenter(plot)
		for index = 1, Data.STRIPS_PER_PLOT do
			local offset = (index - (Data.STRIPS_PER_PLOT + 1) / 2) * Data.STRIP_SPACING
			local color = if index % 2 == 1 then Data.DARK_SOIL else Data.LIGHT_SOIL
			strips[#strips + 1] = {
				name = string.format("Furrow_P%02d_%02d", plot, index),
				plot = plot,
				position = { cx + offset, Data.FURROW_Y, cz },
				size = { Data.STRIP_WIDTH, Data.STRIP_HEIGHT, Data.STRIP_LENGTH },
				color = { r = color.r, g = color.g, b = color.b },
				kind = "furrow",
			}
		end
	end
	return strips
end

-- Grid-aligned bounds for the single grass-cleared plot. The applier reads/writes these exact
-- bounds so the original materials and occupancies can be restored byte-for-byte.
function Data.repaintBounds(): Bounds
	local cx, cz = Game.plotCenter(Data.DEMO_PLOT)
	local halfX = Data.PLOT_WIDTH / 2 + Data.REPAINT_PAD
	local halfZ = Data.PLOT_DEPTH / 2 + Data.REPAINT_PAD
	local voxel = Data.REPAINT_VOXEL
	return {
		{ math.floor((cx - halfX) / voxel) * voxel, Data.REPAINT_Y0, math.floor((cz - halfZ) / voxel) * voxel },
		{ math.ceil((cx + halfX) / voxel) * voxel, Data.REPAINT_Y1, math.ceil((cz + halfZ) / voxel) * voxel },
	}
end

-- Load-time contract check: keeps descriptors honest before the applier or the check reads them.
do
	assert(Data.PLOT_COUNT == 10, "furrows_r10: plot count is not 10")
	assert(Data.STRIPS_PER_PLOT >= 4, "furrows_r10: fewer than 4 strips per plot")
	assert(Data.STRIP_HEIGHT >= Data.MIN_RELIEF, "furrows_r10: rows are not raised >= 0.3 studs")
	assert(#Data.CAMERA_NAMES == Data.PLOT_COUNT, "furrows_r10: camera name count is not the plot count")
	local parts = Data.parts()
	assert(#parts == Data.PLOT_COUNT * Data.STRIPS_PER_PLOT, "furrows_r10: strip descriptor count is wrong")
	local perPlot: { [number]: number } = {}
	for _, part in ipairs(parts) do
		perPlot[part.plot] = (perPlot[part.plot] or 0) + 1
		local cx, cz = Game.plotCenter(part.plot)
		local x, y, z = part.position[1], part.position[2], part.position[3]
		assert(
			math.abs(x - cx) + part.size[1] / 2 <= Data.PLOT_WIDTH / 2
				and math.abs(z - cz) + part.size[3] / 2 <= Data.PLOT_DEPTH / 2,
			"furrows_r10: strip outside plot footprint"
		)
		assert(part.size[2] == Data.STRIP_HEIGHT, "furrows_r10: strip is not a raised row")
		assert(
			math.abs((y + part.size[2] / 2) - Data.GROUND_Y - Data.STRIP_HEIGHT) < 1e-6,
			"furrows_r10: strip relief above the soil is wrong"
		)
		assert(math.abs((y - part.size[2] / 2) - Data.GROUND_Y) < 1e-6, "furrows_r10: row is not on the soil")
		assert(part.kind == "furrow", "furrows_r10: strip kind is not furrow")
		for _, channel in ipairs({ part.color.r, part.color.g, part.color.b }) do
			assert(channel >= 0 and channel <= 255, "furrows_r10: colour channel outside 0..255")
		end
	end
	for plot = 1, Data.PLOT_COUNT do
		assert((perPlot[plot] or 0) >= 4, "furrows_r10: fewer than 4 strips in plot " .. tostring(plot))
	end
	local bounds = Data.repaintBounds()
	for axis = 1, 3 do
		assert(bounds[1][axis] % Data.REPAINT_VOXEL == 0, "furrows_r10: repaint min corner off-grid")
		assert(bounds[2][axis] % Data.REPAINT_VOXEL == 0, "furrows_r10: repaint max corner off-grid")
	end
	assert(bounds[1][1] < bounds[2][1] and bounds[1][3] < bounds[2][3], "furrows_r10: empty repaint region")
end

return Data
