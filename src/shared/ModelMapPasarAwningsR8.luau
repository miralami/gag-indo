--!strict
-- ModelMapPasarAwningsR8: pure data for the OFF-BY-DEFAULT "pasar_awnings_r8" LookDev candidate
-- (WORK_QUEUE section O item 148). Twelve lapak stalls around the Pasar frontage: counters with
-- crates/baskets/hanging cloth, striped red/white/blue awnings and lamps. All geometry is original
-- procedural Parts built by src/server/World/LookDevPasarAwningsR8.luau: no asset IDs, no brand.
--
-- Pure data/functions only: no game APIs, no Instances, no Enums. Every anchor is in Pasar LOCAL
-- coordinates (lx, lz) and is placed by MapSpec.hub("pasar") / MapSpec.hubPoint at apply time.

local Data = {}

Data.id = "pasar_awnings_r8"
Data.familyId = "pasar_awnings_r8"
Data.folderName = "LookDevPasarAwningsR8_pasar_awnings_r8"
Data.stallAttribute = "PasarStall"
Data.stripeAttribute = "AwningStripe"
Data.stripeColourAttribute = "StripeColour"
Data.partAttribute = "StallPart"
Data.collideAttribute = "StallCollide"
Data.idAttribute = "StallId"

-- Plain {r,g,b} arrays; the applier calls Color3.fromRGB. No asset-backed material.
Data.COLOURS = {
	red = { 196, 58, 48 },
	white = { 246, 242, 230 },
	blue = { 54, 104, 178 },
}
Data.STRIPE_ORDER = { "red", "white", "blue" }

Data.STALL_SIZE = { width = 10, depth = 8 }
Data.padMargin = 2
Data.MIN_STALLS = 10
Data.MIN_STRIPES = 30

-- Local +Z is the Pasar door side (toward the plaza). The lane is a 6-stud-wide rectangle that runs
-- along that frontage; every stall sits outside it. Local x -38..38, local z 30..36.
Data.LANE = { lx = 0, lz = 33, width = 76, depth = 6 }

-- Awning stripes: six alternating strips across the stall width, flat at the top of the posts.
local AWNING = { count = 6, height = 9.2, depth = 6.4, zOffset = 1, thickness = 0.35 }
Data.AWNING = AWNING

-- Counter, goods and lamp geometry, all measured up from MapSpec.GROUND_Y in stall-local space.
Data.COUNTER = { width = 8.4, depth = 2.4, y = 3.6, zOffset = 0.4 }
Data.POSTS = {
	{ -4.4, 4.5, -3.4 },
	{ 4.4, 4.5, -3.4 },
	{ -4.4, 4.5, 3.4 },
	{ 4.4, 4.5, 3.4 },
}
Data.CRATE = { size = { 2.4, 1.6, 2 }, offsets = { { -2.8, 4.5, 0.4 }, { 2.8, 4.5, 0.4 } }, vegCount = 3 }
Data.BASKET = { offset = { 0, 4.7, 0.4 }, size = { 1.8, 1.2, 1.8 } }
Data.CLOTH = { offset = { 0, 7.2, -2.6 }, size = { 3, 2.4, 0.15 } }
Data.LAMP = {
	postOffset = { 4.2, 4.5, 3.2 },
	postSize = { 0.4, 9, 0.4 },
	lampOffset = { 4.2, 9.3, 3.2 },
	lampSize = { 1.4, 1, 1.4 },
}
Data.VEGETABLE_COLOURS = { { 92, 142, 58 }, { 196, 148, 42 }, { 178, 62, 52 } }
Data.MATERIALS = {
	base = "Ground",
	wood = "WoodPlanks",
	cloth = "Fabric",
	crate = "Cardboard",
	vegetable = "SmoothPlastic",
	basket = "Wood",
	lamp = "SmoothPlastic",
}

type Stripe = {
	name: string,
	size: { number },
	offset: { number },
	colour: string,
}

-- Alternating red/white/blue, always in that order. Deterministic for any stripe count.
function Data.stripeParts(count: number?): { Stripe }
	local n = count or AWNING.count
	if n < 1 then
		return {}
	end
	local width = Data.STALL_SIZE.width / n
	local out: { Stripe } = {}
	for index = 1, n do
		out[#out + 1] = {
			name = string.format("AwningStripe_%02d", index),
			size = { width - 0.06, AWNING.thickness, AWNING.depth },
			offset = {
				-Data.STALL_SIZE.width / 2 + width * (index - 0.5),
				AWNING.height,
				AWNING.zOffset,
			},
			colour = Data.STRIPE_ORDER[((index - 1) % #Data.STRIPE_ORDER) + 1],
		}
	end
	return out
end

-- Eight stalls on the frontage (facing the lane at yaw 180), two on each return side. All positions
-- are local to the Pasar hub; the applier adds hub.x/hub.z through MapSpec.hubPoint.
local anchors: { { name: string, lx: number, lz: number, yaw: number } } = {}
for index, lx in ipairs({ -35, -25, -15, -5, 5, 15, 25, 35 }) do
	anchors[#anchors + 1] = { name = string.format("front_%02d", index), lx = lx, lz = 42, yaw = 180 }
end
anchors[#anchors + 1] = { name = "west_01", lx = -44, lz = 12, yaw = 90 }
anchors[#anchors + 1] = { name = "west_02", lx = -44, lz = 24, yaw = 90 }
anchors[#anchors + 1] = { name = "east_01", lx = 44, lz = 12, yaw = -90 }
anchors[#anchors + 1] = { name = "east_02", lx = 44, lz = 24, yaw = -90 }

function Data.stalls(): { { name: string, lx: number, lz: number, yaw: number, size: { number } } }
	local out = {} :: { { name: string, lx: number, lz: number, yaw: number, size: { number } } }
	for _, entry in ipairs(anchors) do
		out[#out + 1] = {
			name = entry.name,
			lx = entry.lx,
			lz = entry.lz,
			yaw = entry.yaw,
			size = { Data.STALL_SIZE.width, Data.STALL_SIZE.depth },
		}
	end
	return out
end

function Data.lane(): { lx: number, lz: number, width: number, depth: number }
	return {
		lx = Data.LANE.lx,
		lz = Data.LANE.lz,
		width = Data.LANE.width,
		depth = Data.LANE.depth,
	}
end

function Data.count(): number
	return #anchors
end

return Data
