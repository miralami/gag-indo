--!strict
-- ModelMapSignpostsR10: pure data for the OFF-BY-DEFAULT "signposts_r10" candidate
-- (WORK_QUEUE item 203). Four wooden papan petunjuk at the ring-road junctions (r = 144,
-- angles 0/90/180/270 in the MapSpec ring convention). All text lives in Shared.Strings;
-- no engine calls and no asset IDs here: a server applier consumes these descriptors.

local Data = {}

type RGB = { r: number, g: number, b: number }
type PartDescriptor = {
	name: string,
	kind: string,
	signIndex: number,
	size: { number },
	position: { number },
	color: RGB,
	yaw: number,
}
type SignDescriptor = {
	name: string,
	index: number,
	position: { x: number, y: number, z: number },
	yaw: number,
	board: { size: { number }, color: RGB },
	post: { size: { number }, color: RGB },
	textKey: string,
	fontSizePx: number,
}

Data.id = "signposts_r10"
Data.folderName = "LookDevSignpostsR10_signposts_r10"

Data.RING_RADIUS = 144
Data.GROUND_Y = 0.5
Data.READ_MIN_PX = 14
Data.FONT_SIZE_PX = 18

-- Wooden palette: warm board front, darker post.
Data.BOARD_SIZE = { 6, 3, 0.4 }
Data.BOARD_COLOR = { r = 139, g = 94, b = 54 }
Data.POST_SIZE = { 0.8, 7, 0.8 }
Data.POST_COLOR = { r = 92, g = 60, b = 32 }

Data.STRING_KEYS = { "signpost_pasar", "signpost_sungai", "signpost_plot", "signpost_sawah" }

local function sign(name: string, index: number, x: number, z: number, yaw: number, textKey: string): SignDescriptor
	return {
		name = name,
		index = index,
		position = { x = x, y = Data.GROUND_Y, z = z },
		yaw = yaw,
		board = { size = Data.BOARD_SIZE, color = Data.BOARD_COLOR },
		post = { size = Data.POST_SIZE, color = Data.POST_COLOR },
		textKey = textKey,
		fontSizePx = Data.FONT_SIZE_PX,
	}
end

-- Junction positions follow MapSpec.ROAD.ringCentre. Yaw turns local +Z to (sin, cos), so the
-- board's SurfaceGui Front face (local -Z) looks inward at the plaza from every junction.
Data.SIGNS = {
	sign("SignpostPasar", 1, Data.RING_RADIUS, 0, 90, "signpost_pasar"),
	sign("SignpostSungai", 2, 0, Data.RING_RADIUS, 0, "signpost_sungai"),
	sign("SignpostPlot", 3, -Data.RING_RADIUS, 0, 270, "signpost_plot"),
	sign("SignpostSawah", 4, 0, -Data.RING_RADIUS, 180, "signpost_sawah"),
}

function Data.parts(): { PartDescriptor }
	local parts: { PartDescriptor } = {}
	for _, descriptor in ipairs(Data.SIGNS) do
		local x, y, z = descriptor.position.x, descriptor.position.y, descriptor.position.z
		local rad = math.rad(descriptor.yaw)
		local outwardX, outwardZ = math.sin(rad), math.cos(rad)
		-- ponytail: board sits against the post's outward face; keep the offset while the post is square.
		local offset = descriptor.post.size[1] / 2 + descriptor.board.size[3] / 2
		parts[#parts + 1] = {
			name = descriptor.name .. "_Post",
			kind = "post",
			signIndex = descriptor.index,
			size = descriptor.post.size,
			position = { x, y + descriptor.post.size[2] / 2, z },
			color = descriptor.post.color,
			yaw = descriptor.yaw,
		}
		parts[#parts + 1] = {
			name = descriptor.name .. "_Board",
			kind = "board",
			signIndex = descriptor.index,
			size = descriptor.board.size,
			position = {
				x + outwardX * offset,
				y + descriptor.post.size[2] + descriptor.board.size[2] / 2 - 1,
				z + outwardZ * offset,
			},
			color = descriptor.board.color,
			yaw = descriptor.yaw,
		}
	end
	return parts
end

-- Load-time contract check. Keeps the data honest before any applier or harness reads it.
do
	assert(#Data.SIGNS == 4, "signposts_r10: sign count is not 4")
	assert(#Data.STRING_KEYS == 4, "signposts_r10: text key count is not 4")
	local declared, unique = {}, 0
	for _, key in ipairs(Data.STRING_KEYS) do
		if not declared[key] then
			declared[key] = true
			unique += 1
		end
	end
	assert(unique == 4, "signposts_r10: text keys are not unique")
	local seen = {}
	for _, descriptor in ipairs(Data.SIGNS) do
		assert(not seen[descriptor.textKey], "signposts_r10: duplicate sign text key")
		seen[descriptor.textKey] = true
		assert(declared[descriptor.textKey] == true, "signposts_r10: text key not declared in STRING_KEYS")
		assert(descriptor.fontSizePx >= Data.READ_MIN_PX, "signposts_r10: fontSizePx below READ_MIN_PX")
		for _, colour in ipairs({ descriptor.board.color, descriptor.post.color }) do
			for _, channel in ipairs({ colour.r, colour.g, colour.b }) do
				assert(channel >= 0 and channel <= 255, "signposts_r10: colour channel outside 0..255")
			end
		end
	end
	assert(#Data.parts() == 8, "signposts_r10: expected 8 board/post descriptors")
end

return Data
