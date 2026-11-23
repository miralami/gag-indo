--!strict
-- ModelMapSignpostsR10: pure data for the OFF-BY-DEFAULT "signposts_r10" candidate
-- (WORK_QUEUE item 257). Four green steel signposts at the ring-road junctions (r = 144,
-- angles 0/90/180/270 in the MapSpec ring convention). Each post carries six flat green arrow
-- plates with white text at distinct heights/directions and a small lamp on top. Plate text keys
-- live in Shared.Strings; the baked asset ID lives in the SERVER applier, never here.

local Data = {}

type RGB = { r: number, g: number, b: number }
type PlateDescriptor = {
	name: string,
	order: number,
	textKey: string,
	height: number,
	side: number,
	yawOffset: number,
	fontSizePx: number,
}
type SignDescriptor = {
	name: string,
	index: number,
	position: { x: number, y: number, z: number },
	yaw: number,
	plates: { PlateDescriptor },
}

Data.id = "signposts_r10"
Data.folderName = "LookDevSignpostsR10_signposts_r10"
Data.ASSET_KEY = "signpost"

Data.RING_RADIUS = 144
Data.GROUND_Y = 0.5
Data.READ_MIN_PX = 14
Data.FONT_SIZE_PX = 24
Data.PIXELS_PER_STUD = 24
Data.PLATE_COUNT = 6

-- Green powder-coated steel post (the baked blank signpost is restyled to this palette).
Data.POST_SIZE = { 0.64, 8.57, 0.64 }
Data.POST_COLOR = { r = 30, g = 104, b = 58 }
Data.PLATE_SIZE = { 5.2, 1.5, 0.18 }
Data.PLATE_COLOR = { r = 38, g = 132, b = 72 }
Data.PLATE_LATERAL = 1.6
Data.LAMP_SIZE = { 0.7, 0.45, 0.7 }
Data.LAMP_COLOR = { r = 255, g = 224, b = 138 }
Data.LAMP_DROP = 0.45

Data.STRING_KEYS = {
	"signpost_pasar",
	"signpost_sungai",
	"signpost_plot",
	"signpost_sawah",
	"signpost_balai_desa",
	"signpost_kampung",
}

local function rotatedKeys(offset: number): { string }
	local keys = {}
	for index = 1, #Data.STRING_KEYS do
		keys[index] = Data.STRING_KEYS[((index + offset - 2) % #Data.STRING_KEYS) + 1]
	end
	return keys
end

local function plates(keys: { string }): { PlateDescriptor }
	local list: { PlateDescriptor } = {}
	for order, key in ipairs(keys) do
		list[order] = {
			name = "SignPlate_" .. tostring(order),
			order = order,
			textKey = key,
			-- Top plate sits just under the lamp; the rest step down the pole.
			height = Data.POST_SIZE[2] - Data.LAMP_DROP - 0.8 - (order - 1) * 0.86,
			side = if order % 2 == 0 then 1 else -1,
			yawOffset = (order - (Data.PLATE_COUNT + 1) / 2) * 14,
			fontSizePx = Data.FONT_SIZE_PX,
		}
	end
	return list
end

local function sign(name: string, index: number, x: number, z: number, yaw: number, keyOffset: number): SignDescriptor
	return {
		name = name,
		index = index,
		position = { x = x, y = Data.GROUND_Y, z = z },
		yaw = yaw,
		plates = plates(rotatedKeys(keyOffset)),
	}
end

-- Yaw turns local +Z outward; the plates' SurfaceGui Front face (local -Z) looks inward at the
-- plaza, matching the item-240 signpost_pasar hero camera.
Data.SIGNS = {
	sign("SignpostPasar", 1, Data.RING_RADIUS, 0, 90, 0),
	sign("SignpostSungai", 2, 0, Data.RING_RADIUS, 0, 1),
	sign("SignpostPlot", 3, -Data.RING_RADIUS, 0, 270, 2),
	sign("SignpostSawah", 4, 0, -Data.RING_RADIUS, 180, 3),
}

-- Load-time contract check. Keeps the data honest before any applier or harness reads it.
do
	assert(#Data.SIGNS == 4, "signposts_r10: sign count is not 4")
	assert(#Data.STRING_KEYS == 6, "signposts_r10: text key count is not 6")
	local declared, unique = {}, 0
	for _, key in ipairs(Data.STRING_KEYS) do
		if not declared[key] then
			declared[key] = true
			unique += 1
		end
	end
	assert(unique == 6, "signposts_r10: text keys are not unique")
	local seen = {}
	for _, descriptor in ipairs(Data.SIGNS) do
		assert(not seen[descriptor.index], "signposts_r10: duplicate sign index")
		seen[descriptor.index] = true
		assert(#descriptor.plates == Data.PLATE_COUNT, "signposts_r10: plate count is not 6")
		local heights, keys = {}, {}
		for _, plate in ipairs(descriptor.plates) do
			assert(not heights[plate.height], "signposts_r10: duplicate plate height")
			assert(not keys[plate.textKey], "signposts_r10: duplicate plate text key")
			assert(declared[plate.textKey] == true, "signposts_r10: plate key not declared in STRING_KEYS")
			assert(plate.fontSizePx >= Data.READ_MIN_PX, "signposts_r10: fontSizePx below READ_MIN_PX")
			assert(plate.height > 0 and plate.height < Data.POST_SIZE[2], "signposts_r10: plate off the post")
			heights[plate.height], keys[plate.textKey] = true, true
		end
	end
	assert(seen[1] and seen[2] and seen[3] and seen[4], "signposts_r10: missing junction sign")
	for _, colour in ipairs({ Data.POST_COLOR, Data.PLATE_COLOR, Data.LAMP_COLOR }) do
		for _, channel in ipairs({ colour.r, colour.g, colour.b }) do
			assert(channel >= 0 and channel <= 255, "signposts_r10: colour channel outside 0..255")
		end
	end
end

return Data
