--!nocheck
-- ShippingLookR7: shipping-default ground look (WORK_QUEUE item 55). At startup it
-- applies the approved spawn_ground_r6 look, then paints only the flower-bed and
-- tagged PlotAnchor centres to Enum.Material.Ground. No whole-map fill, no new
-- generators, no asset IDs, no LookDev enable call. Startup cannot yield, so apply()
-- schedules the work and the Terrain/anchor wait is deferred with a 10 s cap.

local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local SpawnGroundMapR6 = require(Shared.SpawnGroundMapR6)
local SkyMapR6 = require(Shared.SkyMapR6)
local LookDevSpawnGroundR6 = require(script.Parent.LookDevSpawnGroundR6)
local Map = require(script.Parent.Map)

local ShippingLookR7 = {}

local MAX_ATTEMPTS = 40
local RETRY_SECONDS = 0.25 -- 40 * 0.25 = 10 s
-- Bed diameter 11.2 rounded down, plus 1 stud = 12x12 centred on the bed.
local BED_BOX = math.floor(SpawnGroundMapR6.flowerBedRadius * 2) + 1
local PLOT_PAD = 1
local FILL_Y = 2
local FILL_HEIGHT = 4

local state = { groundApplied = false, painted = 0, failures = 0 }
local started = false

local function fail(message: string)
	state.failures += 1
	warn("ShippingLookR7: " .. message)
end

-- The approved sky is a shipping default, applied on the server too so the round-7
-- Server-VM check reads the same SkyboxFt as the client. Client Sky.luau applies the
-- identical faces plus the atmosphere stack. No LookDev enable call is involved.
local function applySky()
	local ok, err = pcall(function()
		local sky = Lighting:FindFirstChildOfClass("Sky")
		if not sky then
			sky = Instance.new("Sky")
			sky.Name = "Sky"
		end
		for _, key in ipairs(SkyMapR6.faceKeys) do
			sky[key] = "rbxassetid://" .. tostring(SkyMapR6.sets.e.ids[key])
		end
		sky.CelestialBodiesShown = true
		sky.Parent = Lighting
	end)
	if not ok then
		fail("shipping sky apply failed: " .. tostring(err))
	end
end

local function applyGround()
	local ok, err = pcall(LookDevSpawnGroundR6.apply)
	if ok then
		state.groundApplied = true
	else
		fail("spawn_ground_r6 apply failed: " .. tostring(err))
	end
end

local function fill(terrain: Terrain, x: number, z: number, sx: number, sz: number, label: string)
	local ok, err = pcall(function()
		terrain:FillBlock(CFrame.new(x, FILL_Y, z), Vector3.new(sx, FILL_HEIGHT, sz), Enum.Material.Ground)
	end)
	if ok then
		state.painted += 1
	else
		fail("FillBlock " .. label .. " failed: " .. tostring(err))
	end
end

local function paintBeds(terrain: Terrain)
	for index, bed in ipairs(SpawnGroundMapR6.flowerBeds) do
		fill(terrain, bed.x, bed.z, BED_BOX, BED_BOX, "flowerbed:" .. index)
	end
end

local function paintPlots(terrain: Terrain, anchors: { any })
	for index, anchor in ipairs(anchors) do
		local ok, x, z, sx, sz = pcall(function()
			if not anchor:IsA("BasePart") then
				return nil
			end
			local position, size = anchor.Position, anchor.Size
			return position.X, position.Z, size.X + PLOT_PAD, size.Z + PLOT_PAD
		end)
		if ok then
			if x ~= nil then
				fill(terrain, x, z, sx, sz, "plot:" .. index)
			end
		else
			fail("reading PlotAnchor " .. index .. " failed: " .. tostring(x))
		end
	end
end

local function run()
	applySky()
	applyGround()

	local terrain, anchors
	for _ = 1, MAX_ATTEMPTS do
		if not terrain then
			local ok, found = pcall(function()
				return Workspace:FindFirstChildOfClass("Terrain")
			end)
			if not ok then
				fail("find Terrain failed: " .. tostring(found))
			elseif found then
				terrain = found
				paintBeds(terrain)
			end
		end
		if not anchors or #anchors == 0 then
			local ok, tagged = pcall(function()
				return CollectionService:GetTagged(Map.TAGS.PlotAnchor)
			end)
			if not ok then
				fail("GetTagged(PlotAnchor) failed: " .. tostring(tagged))
			elseif tagged and #tagged > 0 then
				anchors = tagged
			end
		end
		if terrain and anchors then
			break
		end
		task.wait(RETRY_SECONDS)
	end

	if not terrain then
		fail("Terrain not found within 10 s; no voxels painted")
		return
	end
	if not anchors then
		warn("ShippingLookR7: no PlotAnchor parts within 10 s; only flower beds painted")
		return
	end
	paintPlots(terrain, anchors)
end

function ShippingLookR7.apply()
	if started then
		return
	end
	started = true
	task.defer(run)
end

function ShippingLookR7.status()
	return {
		groundApplied = state.groundApplied,
		painted = state.painted,
		failures = state.failures,
	}
end

-- A bare require() from Main.server starts the shipping look. An explicit apply()
-- call afterwards is idempotent.
ShippingLookR7.apply()

return ShippingLookR7
