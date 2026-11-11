-- MarketService: the per-server Pasar price board (v2 PLAN §3.4).
--
-- Ownership: this module owns the crop pressure table. EconomyService asks for the multiplier
-- when paying a Pasar sale and reports the sale back; the Tengkulak Gelap never calls it.
--
-- Pressure is deliberately in memory: a server restart is a fresh market, which is fine for a
-- ten-minute wave. The client reads the `Market_<crop>` attributes on ReplicatedStorage.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Crops = require(Shared.Config.Crops)
local Market = require(Shared.Config.Market)

local MarketService = {}

-- [cropId] = pressure (0 .. 1 - floor)
local pressure: { [string]: number } = {}
local lastTick = os.clock()

local function clampPressure(value: number): number
	return math.clamp(value, 0, 1 - Market.minMultiplier)
end

-- Price multiplier for one crop, between the floor and the HET ceiling.
function MarketService.multiplier(cropId: string): number
	if not Crops.list[cropId] then
		return 1
	end
	local raw = 1 - clampPressure(pressure[cropId] or 0)
	return math.clamp(raw, Market.minMultiplier, Market.maxMultiplier)
end

-- Selling pushes the price down. `count` is the number of items sold.
function MarketService.recordSale(cropId: string, count: number)
	if not Crops.list[cropId] or type(count) ~= "number" or count <= 0 then
		return
	end
	pressure[cropId] = clampPressure((pressure[cropId] or 0) + math.floor(count) * Market.pressurePerItem)
end

function MarketService.pressure(cropId: string): number
	return clampPressure(pressure[cropId] or 0)
end

-- Price board snapshot: { [cropId] = multiplier }.
function MarketService.snapshot(): { [string]: number }
	local out = {}
	for _, cropId in Crops.order do
		out[cropId] = MarketService.multiplier(cropId)
	end
	return out
end

local function decay(now: number)
	local elapsed = math.max(0, now - lastTick)
	lastTick = now
	if elapsed <= 0 then
		return
	end
	local factor = math.exp(-elapsed / Market.decaySeconds)
	for cropId, value in pressure do
		pressure[cropId] = clampPressure(value * factor)
	end
end

local function publish()
	for _, cropId in Crops.order do
		ReplicatedStorage:SetAttribute("Market_" .. cropId, MarketService.multiplier(cropId))
	end
end

-- Exposed for tests and for the admin panel later.
function MarketService.tick(now: number?)
	decay(now or os.clock())
	publish()
end

function MarketService.start()
	publish()
	task.spawn(function()
		while true do
			task.wait(Market.tickSeconds)
			MarketService.tick()
		end
	end)
end

return MarketService
