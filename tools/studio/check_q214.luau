--!nocheck
-- check_q214: WORK_QUEUE item 214, self-contained SERVER-VM Studio check on the DEFAULT look.
-- Paste this whole file into execute_luau in a FRESH Play session. It stages nothing, calls no
-- LookDev API, reads only the live DataModel, prints the CHECK lines verbatim and restores every
-- temporary mutation before it returns. No harness require, no place save, no visual verdict.
--
-- IMPORTANT: main session must wire ModelMapTerraceWallsQ214 into Greybox before this check PASSes.
-- Until Greybox stages the tagged parts, TERRACE_WALLS reads 0 and the check FAILs honestly.
--
--   TERRACE_WALLS     <count>     4    >=4 visible BaseParts with attribute TerraceWall==true.
--   WALL_ON_TERRAIN   <worst gap> 0.3  max(0, wallBottomY - terrainY) over every visible wall:
--                                      the FLOAT gap, measured with a downward Terrain-only ray
--                                      at each wall's XZ centre. Touching or embedded reads 0;
--                                      only a bottom above the surface counts as floating.
--
-- CALIBRATION ANCHORS: hide three walls (Transparency=1, exact restore) -> CAL_TERRACE_WALLS_FAIL;
-- lift ALL walls 2 studs (exact CFrame restore) -> CAL_WALL_ON_TERRAIN_FAIL, so the max float gap
-- cannot hide behind a non-max wall. Both re-measure the same live DataModel, emit PASS 1 1 only
-- when the baseline passed and the mutation broke it, and restore every saved value before return.
-- No instances are injected.

local CHECK_NAMES = {
	"TERRACE_WALLS",
	"WALL_ON_TERRAIN",
	"CAL_TERRACE_WALLS_FAIL",
	"CAL_WALL_ON_TERRAIN_FAIL",
}
local CHECK_TARGETS = {
	TERRACE_WALLS = 4,
	WALL_ON_TERRAIN = "0.3",
	CAL_TERRACE_WALLS_FAIL = 1,
	CAL_WALL_ON_TERRAIN_FAIL = 1,
}
local MIN_WALLS = 4
local WALL_GAP_TOL = 0.3
local CAL_HIDE = 3
local CAL_LIFT = 2
local RAY_ORIGIN_Y, RAY_LENGTH = 256, 512
local NO_TERRAIN_GAP = 1000000

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

local function shown(value)
	return string.format("%.4f", tonumber(value) or 0)
end

local function attr(instance, key)
	local ok, value = pcall(function()
		return instance:GetAttribute(key)
	end)
	return ok and value or nil
end

local function visible(part)
	local ok, value = pcall(function()
		return part.Transparency < 1
	end)
	return ok and value
end

local function visibleCount(parts)
	local count = 0
	for _, part in ipairs(parts) do
		if visible(part) then
			count += 1
		end
	end
	return count
end

-- Live tagged parts only. Any BasePart carrying TerraceWall==true counts; no name filter, no
-- LookDev folder assumption and no descriptor substitution.
local function wallParts()
	local out = {}
	local ok, descendants = pcall(function()
		return workspace:GetDescendants()
	end)
	if not ok or type(descendants) ~= "table" then
		return out
	end
	for _, instance in ipairs(descendants) do
		pcall(function()
			if instance:IsA("BasePart") and attr(instance, "TerraceWall") == true then
				out[#out + 1] = instance
			end
		end)
	end
	return out
end

local function wallBottom(part)
	local ok, bottom = pcall(function()
		return part.CFrame.Position.Y - part.Size.Y / 2
	end)
	return ok and bottom or nil
end

-- Terrain-only downward ray. Whitelisting Terrain excludes the wall itself, paddy water, ramps
-- and every other Part, so the hit is the real voxel surface under the wall footprint.
local function terrainSurfaceY(x, z)
	local okTerrain, terrain = pcall(function()
		return workspace:FindFirstChildOfClass("Terrain")
	end)
	if not okTerrain or not terrain then
		return nil
	end
	local okParams, params = pcall(function()
		local p = RaycastParams.new()
		p.FilterType = Enum.RaycastFilterType.Include
		p.FilterDescendantsInstances = { terrain }
		p.IgnoreWater = true
		return p
	end)
	if not okParams then
		return nil
	end
	local okRay, hit = pcall(function()
		return workspace:Raycast(Vector3.new(x, RAY_ORIGIN_Y, z), Vector3.new(0, -RAY_LENGTH, 0), params)
	end)
	if okRay and hit and hit.Instance == terrain then
		return hit.Position.Y
	end
	return nil
end

local function worstWallGap(walls)
	local worst = 0
	if #walls == 0 then
		return NO_TERRAIN_GAP
	end
	for _, wall in ipairs(walls) do
		if visible(wall) then
			local okCentre, x, z = pcall(function()
				local centre = wall.CFrame.Position
				return centre.X, centre.Z
			end)
			local bottom = wallBottom(wall)
			local surface = okCentre and terrainSurfaceY(x, z) or nil
			if not okCentre or bottom == nil or surface == nil then
				return NO_TERRAIN_GAP
			end
			-- Bottom above terrain floats; bottom at/below terrain is contact and reads 0.
			worst = math.max(worst, bottom - surface)
		end
	end
	return worst
end

local savedTransparency, savedCFrames = {}, {}

local function restoreCalibrations()
	for part, value in pairs(savedTransparency) do
		pcall(function()
			part.Transparency = value
		end)
	end
	for part, value in pairs(savedCFrames) do
		pcall(function()
			part.CFrame = value
		end)
	end
	table.clear(savedTransparency)
	table.clear(savedCFrames)
end

local ok, err = pcall(function()
	local walls = wallParts()
	local count = visibleCount(walls)
	local worst = worstWallGap(walls)

	emit("TERRACE_WALLS", count >= MIN_WALLS, count, MIN_WALLS, { tagged = #walls, visible = count })
	emit("WALL_ON_TERRAIN", count >= MIN_WALLS and worst <= WALL_GAP_TOL, shown(worst), "0.3", {
		worst = worst,
		walls = count,
	})

	-- CAL_TERRACE_WALLS_FAIL: hide exactly three walls, re-count visible tagged parts, restore.
	for index = 1, math.min(CAL_HIDE, #walls) do
		local wall = walls[index]
		pcall(function()
			savedTransparency[wall] = wall.Transparency
			wall.Transparency = 1
		end)
	end
	local hiddenCount = visibleCount(walls)
	local wallsFailed = count >= MIN_WALLS and hiddenCount < MIN_WALLS
	emit("CAL_TERRACE_WALLS_FAIL", wallsFailed, wallsFailed and 1 or 0, 1, {
		visibleBefore = count,
		visibleWhileHidden = hiddenCount,
		hidden = CAL_HIDE,
	})
	restoreCalibrations()

	-- CAL_WALL_ON_TERRAIN_FAIL: lift ALL walls 2 studs, re-measure the same raycasts, restore.
	-- Lifting every wall keeps the calibration deterministic even when walls[1] is not the max.
	for _, wall in ipairs(walls) do
		pcall(function()
			savedCFrames[wall] = wall.CFrame
			wall.CFrame = wall.CFrame + Vector3.new(0, CAL_LIFT, 0)
		end)
	end
	local liftedWorst = worstWallGap(walls)
	local gapFailed = worst <= WALL_GAP_TOL and liftedWorst > WALL_GAP_TOL
	emit("CAL_WALL_ON_TERRAIN_FAIL", gapFailed, gapFailed and 1 or 0, 1, {
		worstBefore = worst,
		worstWhileLifted = liftedWorst,
		lift = CAL_LIFT,
	})
	restoreCalibrations()
end)

-- Belt-and-braces restore on every path, including a thrown measurement.
restoreCalibrations()

if not ok then
	local reason = { reason = "item 214 audit error: " .. tostring(err) }
	for _, name in ipairs(CHECK_NAMES) do
		emitOnce(name, false, 0, CHECK_TARGETS[name], reason)
	end
end

return results
