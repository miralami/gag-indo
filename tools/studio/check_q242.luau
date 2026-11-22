--!nocheck
-- check_q242.luau: self-contained SERVER-VM Studio check for WORK_QUEUE item 242 (horizon void).
-- Paste this whole file into execute_luau in a FRESH Play session on the SHIPPING default look: no
-- LookDev staging, no place save, no visual verdict. The main session saves the printed CHECK lines
-- under docs/v2/evidence/h/<date>-sprint2/CHECK_242.txt.
--
-- CHECKS (targets are NOT weakened):
--   HORIZON_FILL <hitCount> 173   90% of 3 cameras x 64 horizon-band rays = 172.8 -> ceil 173.
--                                 Per camera that is 58/64; PASS uses the 173/192 aggregate.
--   PERF_BUDGET  <count>     500   BasePart centres within XZ radius 100 (check_q186 method).
--   CAL_HORIZON_FILL_FAIL 1 1     The same 192-ray sweep with only the default far-fill Parts added
--                                 to the RaycastParams exclude filter must fall below 90%.
--
-- METHOD. Each fresh Camera uses CFrame.lookAt(eye, lookAt) from ReviewCameras.get, FOV 70 and a
-- 16:9 aspect. 8x8 normalised viewport samples span x 0.02..0.98 and y 0.40..0.60 (the frame's
-- horizon band, y measured from the top). Ray length 5000. Characters start in the RaycastParams
-- exclude filter; buildings, roads and other non-ground/non-hill hits are then skipped by re-casting
-- with that instance added, so a roof does not hide the Terrain or far fill behind it. A hit counts
-- only for Terrain, or a BasePart named Ground/Hill/Mountain/Skirt/Horizon/FarFill or tagged
-- HorizonFill/HorizonSkirt/FarHill/Mountain. This measures geometric fill, not a visual yes/no:
-- the designer grades the shots at S2-STOP.
--
-- CALIBRATION ANCHOR: measure(false) then measure(true) are separate single calls. Nothing in the
-- world is destroyed or mutated; only the local RaycastParams exclude filter changes.

local CHECK_NAMES = { "HORIZON_FILL", "PERF_BUDGET", "CAL_HORIZON_FILL_FAIL" }
local CAMERA_NAMES = {
	"canonical_overview",
	"canonical_overview_left",
	"canonical_overview_right",
}
local SAMPLES = 8
local RAYS_PER_CAMERA = SAMPLES * SAMPLES -- 64
local TOTAL_RAYS = #CAMERA_NAMES * RAYS_PER_CAMERA -- 192
local HORIZON_TARGET = math.ceil(TOTAL_RAYS * 0.90) -- 173
local HORIZON_FRACTION = 0.90
local RAY_LENGTH = 5000
local ASPECT = 16 / 9
local MAX_SKIPS = 24

local results = { checks = {}, byName = {} }
local function emit(name, passed, measured, target, detail)
	local line = "CHECK "
		.. name
		.. " "
		.. (passed and "PASS" or "FAIL")
		.. " "
		.. tostring(measured)
		.. " "
		.. tostring(target)
	results.checks[#results.checks + 1] = line
	results.byName[name] = { line = line, passed = passed, measured = measured, target = target, detail = detail }
	print(line)
end

local function emitOnce(name, passed, measured, target, detail)
	if not results.byName[name] then
		emit(name, passed, measured, target, detail)
	end
end

local QUALIFY_NAMES = { "ground", "hill", "mountain", "skirt", "horizon", "farfill" }
local QUALIFY_TAGS = { "HorizonFill", "HorizonSkirt", "FarHill", "Mountain" }

local function qualifies(instance)
	if not instance then
		return false
	end
	local okTerrain, isTerrain = pcall(function()
		return instance:IsA("Terrain")
	end)
	if okTerrain and isTerrain then
		return true
	end
	local okBase, isBase = pcall(function()
		return instance:IsA("BasePart")
	end)
	if not okBase or not isBase then
		return false
	end
	local okName, name = pcall(function()
		return instance.Name
	end)
	if okName and type(name) == "string" then
		local lower = string.lower(name)
		for _, word in ipairs(QUALIFY_NAMES) do
			if string.find(lower, word, 1, true) then
				return true
			end
		end
	end
	for _, key in ipairs(QUALIFY_TAGS) do
		local okTag, value = pcall(function()
			return instance:GetAttribute(key)
		end)
		if okTag and value == true then
			return true
		end
	end
	return false
end

local function descendants()
	local ok, list = pcall(function()
		return workspace:GetDescendants()
	end)
	return ok and type(list) == "table" and list or {}
end

local function characterParts()
	local out = {}
	local okPlayers, players = pcall(function()
		return game:GetService("Players"):GetPlayers()
	end)
	if not okPlayers or type(players) ~= "table" then
		return out
	end
	for _, player in ipairs(players) do
		local okChar, character = pcall(function()
			return player.Character
		end)
		if okChar and character then
			local okParts, parts = pcall(function()
				return character:GetDescendants()
			end)
			if okParts and type(parts) == "table" then
				for _, part in ipairs(parts) do
					local okBase, isBase = pcall(function()
						return part:IsA("BasePart")
					end)
					if okBase and isBase then
						out[#out + 1] = part
					end
				end
			end
		end
	end
	return out
end

-- Only instances carrying the item-242 tag are added to the calibration filter. The check never
-- destroys the fill; the exclude filter is local to this invocation.
local function fillParts()
	local out = {}
	for _, instance in ipairs(descendants()) do
		local okBase, isBase = pcall(function()
			return instance:IsA("BasePart")
		end)
		if okBase and isBase then
			local okTag, value = pcall(function()
				return instance:GetAttribute("HorizonFill")
			end)
			if okTag and value == true then
				out[#out + 1] = instance
			end
		end
	end
	return out
end

-- Returns true on the first Terrain / ground / hill / fill hit. Non-qualifying hits (roofs, roads,
-- foliage) are appended to this ray's private exclude list and the ray continues.
local function cast(origin, direction, baseBlocked)
	local skipped = table.clone(baseBlocked)
	local position, remaining = origin, RAY_LENGTH
	for _ = 1, MAX_SKIPS do
		local params = RaycastParams.new()
		params.IgnoreWater = false
		params.FilterType = Enum.RaycastFilterType.Exclude
		if #skipped > 0 then
			params:AddToFilter(skipped)
		end
		local okRay, result = pcall(function()
			return workspace:Raycast(position, direction * remaining, params)
		end)
		if not okRay or not result then
			return false
		end
		if qualifies(result.Instance) then
			return true
		end
		if result.Instance then
			skipped[#skipped + 1] = result.Instance
		end
		local distance = (result.Position - position).Magnitude
		if distance < 0.01 then
			distance = 0.01
		end
		remaining -= distance + 0.1
		if remaining <= 0 then
			return false
		end
		position = result.Position + direction * 0.1
	end
	return false
end

local function measure(excludeFill)
	local baseBlocked = characterParts()
	local excluded = {}
	if excludeFill then
		excluded = fillParts()
		for _, part in ipairs(excluded) do
			baseBlocked[#baseBlocked + 1] = part
		end
	end

	local hits, perCamera = 0, {}
	local Cameras = require(game:GetService("ReplicatedStorage").Shared.ReviewCameras)
	for _, name in ipairs(CAMERA_NAMES) do
		perCamera[name] = 0
		local definition = Cameras.get(name)
		if definition then
			local okCamera, camera = pcall(function()
				local made = Instance.new("Camera")
				made.CFrame = CFrame.lookAt(
					Vector3.new(definition.position[1], definition.position[2], definition.position[3]),
					Vector3.new(definition.lookAt[1], definition.lookAt[2], definition.lookAt[3])
				)
				-- A fresh Server-VM Camera exposes no FOV property; the ray fan below derives its
				-- tan half-angles from the fixed 70-degree / 16:9 values above instead.
				return made
			end)
			if okCamera and camera then
				local frame = camera.CFrame
				local forward, right, up = frame.LookVector, frame.RightVector, frame.UpVector
				local tanV = math.tan(math.rad(camera.FOV) / 2)
				local tanH = tanV * ASPECT
				for iy = 0, SAMPLES - 1 do
					local ny = 0.40 + 0.20 * iy / (SAMPLES - 1)
					for ix = 0, SAMPLES - 1 do
						local nx = 0.02 + 0.96 * ix / (SAMPLES - 1)
						local direction = (forward + right * ((2 * nx - 1) * tanH) + up * ((1 - 2 * ny) * tanV)).Unit
						if cast(frame.Position, direction, baseBlocked) then
							hits += 1
							perCamera[name] += 1
						end
					end
				end
				pcall(function()
					camera:Destroy()
				end)
			end
		end
	end
	return { hits = hits, perCamera = perCamera, excludedParts = #excluded }
end

local ok, err = pcall(function()
	local after = measure(false)
	emit("HORIZON_FILL", after.hits >= HORIZON_TARGET, after.hits, HORIZON_TARGET, {
		rays = TOTAL_RAYS,
		fraction = after.hits / TOTAL_RAYS,
		requiredFraction = HORIZON_FRACTION,
		perCamera = after.perCamera,
	})

	local perf = 0
	for _, instance in ipairs(descendants()) do
		local okBase, isBase = pcall(function()
			return instance:IsA("BasePart")
		end)
		if okBase and isBase then
			local okPosition, position = pcall(function()
				return instance.CFrame.Position
			end)
			if okPosition and position and position.X * position.X + position.Z * position.Z <= 10000 then
				perf += 1
			end
		end
	end
	emit("PERF_BUDGET", perf <= 500, perf, 500, { proxy = "BasePart centre within XZ radius 100" })

	local withoutFill = measure(true)
	local fraction = withoutFill.hits / TOTAL_RAYS
	local calPass = fraction < HORIZON_FRACTION
	emit("CAL_HORIZON_FILL_FAIL", calPass, calPass and 1 or 0, 1, {
		hits = withoutFill.hits,
		fraction = fraction,
		requiredFraction = HORIZON_FRACTION,
		excludedParts = withoutFill.excludedParts,
		perCamera = withoutFill.perCamera,
	})
end)

if not ok then
	local reason = { reason = "audit error: " .. tostring(err) }
	local targets = { [CHECK_NAMES[1]] = HORIZON_TARGET, [CHECK_NAMES[2]] = 500, [CHECK_NAMES[3]] = 1 }
	for _, name in ipairs(CHECK_NAMES) do
		emitOnce(name, false, 0, targets[name], reason)
	end
end

return results
