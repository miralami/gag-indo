--!strict
-- Pure data for WORK_QUEUE item 209: DEFAULT-look Pasar awning stripes and hanging board.
-- No engine APIs, no instances. COLOURS is a byte-exact copy of the item-179 palette in
-- Shared.ModelMapPasarAwningsR8.COLOURS; do not invent new colours here.

local Data = {}

Data.stripeAttribute = "PasarStripe"
Data.signAttribute = "PasarSign"
Data.stripeColourAttribute = "StripeColour"
Data.stringsKeyAttribute = "StringsKey"
Data.boardKey = "sign_pasar_board"

Data.COLOURS = {
	red = { 248, 76, 64 },
	white = { 255, 252, 244 },
	blue = { 72, 148, 236 },
}
Data.ORDER = { "red", "white", "blue" }
Data.STRIPES_PER_BOOTH = 6
Data.MIN_STRIPES = 30

-- The five stall counters Greybox already builds at local x -22..22, z -6.
Data.BOOTH_X = { -22, -11, 0, 11, 22 }
Data.BOOTH_Z = -6
Data.COUNTER_WIDTH = 9
Data.COUNTER_DEPTH = 4
Data.AWNING_RISE = 7.2 -- studs above GROUND_Y
Data.STRIPE_THICKNESS = 0.3
Data.STRIPE_GAP = 0.06

-- The board hangs just inside the front eave, clear of all six 6-stud hub door lanes.
Data.BOARD = {
	lx = 0,
	lz = 24,
	width = 10,
	height = 2.4,
	thickness = 0.3,
	drop = 1.6, -- eave underside to board centre
	facePixelsPerStud = 40,
}

Data.STRIPES = {}
for booth, lx in ipairs(Data.BOOTH_X) do
	local width = Data.COUNTER_WIDTH / Data.STRIPES_PER_BOOTH
	for index = 1, Data.STRIPES_PER_BOOTH do
		Data.STRIPES[#Data.STRIPES + 1] = {
			name = string.format("PasarStripe_%02d_%02d", booth, index),
			lx = lx - Data.COUNTER_WIDTH / 2 + width * (index - 0.5),
			lz = Data.BOOTH_Z,
			colour = Data.ORDER[((index - 1) % #Data.ORDER) + 1],
			width = width - Data.STRIPE_GAP,
			depth = Data.COUNTER_DEPTH + 0.4,
		}
	end
end

return Data
