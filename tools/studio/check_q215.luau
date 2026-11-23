--!nocheck
-- check_q215: WORK_QUEUE item 215, self-contained SERVER-VM Studio check on the DEFAULT look.
-- Paste this whole file into execute_luau in a FRESH Play session. It stages nothing, calls no
-- LookDev API, reads only the live DataModel, prints the CHECK lines verbatim and restores every
-- temporary mutation before it returns. No harness require, no place save, no visual verdict.
-- MAIN SESSION: wire src/shared/ModelMapSawahDressingQ215.luau into Greybox before this check
-- PASSes. Without that wiring every count below stays at zero and the check correctly FAILs.
--
--   GUBUK       <groups> 1  >=1 distinct visible group with SawahDressingKind=="gubuk".
--   SCARECROWS  <groups> 2  >=2 distinct visible groups with SawahDressingKind=="scarecrow".
--   NO_FLOATERS <count>  0  ground-contact tagged parts (name contains post/floor/pole) whose
--                             bottom is >0.3 above the terrain surface at their XZ centre.
--                             Overhead parts (roofs, shirts, arms, heads, ribbon strips) are
--                             supported by those ground parts and are not false positives.
--
-- Group key: SawahDressingGroup attribute when present, else the "<Group>_<NN>_" name prefix.
-- Terrain surface: Terrain raycast down from y=256, excluding tagged parts; MapSpec terrace top
-- by Z band is the fallback. A missing surface counts as a floater (never a vacuous PASS).
--
-- CALIBRATION ANCHORS: hide every gubuk part (exact Transparency save/restore) -> CAL_GUBUK_FAIL;
-- hide every scarecrow part the same way -> CAL_SCARECROWS_FAIL; lift one ground-contact part by
-- 2 studs (exact CFrame save/restore) -> CAL_NO_FLOATERS_FAIL. Every mutation is restored.

local CHECK_NAMES = {
	"GUBUK",
	"SCARECROWS",
	"NO_FLOATERS",
	"CAL_GUBUK_FAIL",
	"CAL_SCARECROWS_FAIL",
	"CAL_NO_FLOATERS_FAIL",
}
local CHECK_TARGETS = {
	GUBUK = 1,
	SCARECROWS = 2,
	NO_FLOATERS = 0,
	CAL_GUBUK_FAIL = 1,
	CAL_SCARECROWS_FAIL = 1,
	CAL_NO_FLOATERS_FAIL = 1,
}
local MIN_GUBUK = 1
local MIN_SCARECROWS = 2
local FLOATER_TOL = 0.3
local GROUND_TOKENS = { "post", "floor", "pole" }

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

local function aabb(part)
	local ok, box = pcall(function()
		local cf, size = part.CFrame, part.Size
		local ex = cf:VectorToWorldSpace(Vector3.new(size.X / 2, 0, 0))
		local ey = cf:VectorToWorldSpace(Vector3.new(0, size.Y / 2, 0))
		local ez = cf:VectorToWorldSpace(Vector3.new(0, 0, size.Z / 2))
		local function axis(a, b, c)
			return {
				x = cf.Position.X + a.X + b.X + c.X,
				y = cf.Position.Y + a.Y + b.Y + c.Y,
				z = cf.Position.Z + a.Z + b.Z + c.Z,
			}
		end
		local minX, minY, minZ = math.huge, math.huge, math.huge
		local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
		for _, sx in ipairs({ -1, 1 }) do
			for _, sy in ipairs({ -1, 1 }) do
				for _, sz in ipairs({ -1, 1 }) do
					local p = axis(
						Vector3.new(ex.X * sx, ex.Y * sx, ex.Z * sx),
						Vector3.new(ey.X * sy, ey.Y * sy, ey.Z * sy),
						Vector3.new(ez.X * sz, ez.Y * sz, ez.Z * sz)
					)
					minX, maxX = math.min(minX, p.x), math.max(maxX, p.x)
					minY, maxY = math.min(minY, p.y), math.max(maxY, p.y)
					minZ, maxZ = math.min(minZ, p.z), math.max(maxZ, p.z)
				end
			end
		end
		return {
			minY = minY,
			centreX = (minX + maxX) / 2,
			centreZ = (minZ + maxZ) / 2,
		}
	end)
	return ok and box or nil
end

local function groupKey(part)
	local value = attr(part, "SawahDressingGroup")
	if type(value) == "string" and value ~= "" then
		return value
	end
	return string.match(part.Name, "^(.-)_%d+_") or part.Name
end

local function groundContact(part)
	local name = string.lower(part.Name)
	for _, token in ipairs(GROUND_TOKENS) do
		if string.find(name, token, 1, true) then
			return true
		end
	end
	return false
end

local function terraceTop(MapSpec, z)
	if type(MapSpec.TERRACES) ~= "table" then
		return nil
	end
	for _, band in ipairs(MapSpec.TERRACES) do
		if z >= band.z0 and z <= band.z1 then
			return band.top
		end
	end
	return nil
end

local function terrainSurfaceY(params, MapSpec, x, z)
	local ok, result = pcall(function()
		return workspace.Terrain:Raycast(Vector3.new(x, 256, z), Vector3.new(0, -1, 0), params)
	end)
	if ok and result then
		local okY, y = pcall(function()
			return result.Position.Y
		end)
		if okY and type(y) == "number" then
			return y
		end
	end
	return terraceTop(MapSpec, z)
end

local function measure(parts, params, MapSpec)
	local groups, grounded = {}, {}
	for _, part in ipairs(parts) do
		if visible(part) then
			local kind = attr(part, "SawahDressingKind")
			if kind == "gubuk" or kind == "scarecrow" then
				local key = groupKey(part)
				if groups[key] == nil then
					groups[key] = { kind = kind, count = 0 }
				end
				groups[key].count += 1
			end
			if groundContact(part) then
				grounded[#grounded + 1] = part
			end
		end
	end
	local gubuk, scarecrows = 0, 0
	for _, info in pairs(groups) do
		if info.kind == "gubuk" then
			gubuk += 1
		elseif info.kind == "scarecrow" then
			scarecrows += 1
		end
	end
	local floaters = {}
	for _, part in ipairs(grounded) do
		local box = aabb(part)
		if not box then
			floaters[#floaters + 1] = part.Name .. ":no-aabb"
		else
			local surface = terrainSurfaceY(params, MapSpec, box.centreX, box.centreZ)
			if surface == nil or box.minY - surface > FLOATER_TOL then
				floaters[#floaters + 1] = part.Name .. ":" .. tostring(box.minY - (surface or -math.huge))
			end
		end
	end
	return gubuk, scarecrows, floaters, grounded
end

local function raycastParams(parts)
	local ok, params = pcall(function()
		local p = RaycastParams.new()
		p.FilterType = Enum.RaycastFilterType.Exclude
		for _, part in ipairs(parts) do
			p:AddToFilter(part)
		end
		return p
	end)
	return ok and params or nil
end

local function hideParts(parts, kind)
	local saved = {}
	for _, part in ipairs(parts) do
		pcall(function()
			if attr(part, "SawahDressingKind") == kind then
				saved[part] = part.Transparency
				part.Transparency = 1
			end
		end)
	end
	return saved
end

local function restoreTransparency(saved)
	for part, value in pairs(saved) do
		pcall(function()
			part.Transparency = value
		end)
	end
end

local ok, err = pcall(function()
	local MapSpec = require(game:GetService("ServerScriptService"):WaitForChild("Server").World.MapSpec)
	if type(MapSpec.TERRACES) ~= "table" then
		error("MapSpec.TERRACES missing")
	end
	local dress = {}
	for _, inst in ipairs(workspace:GetDescendants()) do
		pcall(function()
			if inst:IsA("BasePart") and attr(inst, "SawahDressing") == true then
				dress[#dress + 1] = inst
			end
		end)
	end
	local params = raycastParams(dress)
	local gubuk, scarecrows, floaters, grounded = measure(dress, params, MapSpec)
	print("SAWAH_DRESSING_TAGGED " .. #dress .. " groups:" .. tostring(gubuk) .. "/" .. tostring(scarecrows))
	emit("GUBUK", gubuk >= MIN_GUBUK, gubuk, MIN_GUBUK, { tagged = #dress })
	emit("SCARECROWS", scarecrows >= MIN_SCARECROWS, scarecrows, MIN_SCARECROWS, { tagged = #dress })
	emit("NO_FLOATERS", #floaters == 0, #floaters, 0, {
		grounded = #grounded,
		offenders = floaters,
	})

	-- CAL_GUBUK_FAIL: hide every gubuk part, re-count groups, restore the exact Transparency.
	local savedGubuk = hideParts(dress, "gubuk")
	local okGubuk, calGubuk, calScarecrows = pcall(measure, dress, params, MapSpec)
	restoreTransparency(savedGubuk)
	local gubukFailed = okGubuk and gubuk >= MIN_GUBUK and calGubuk == 0
	emit("CAL_GUBUK_FAIL", gubukFailed, gubukFailed and 1 or 0, 1, {
		gubukBefore = gubuk,
		gubukWhileHidden = if okGubuk then calGubuk else -1,
		scarecrowsWhileHidden = if okGubuk then calScarecrows else -1,
	})

	-- CAL_SCARECROWS_FAIL: hide every scarecrow part, re-count groups, restore exactly.
	local savedScarecrows = hideParts(dress, "scarecrow")
	local okScarecrows, calGubuk2, calScarecrow2 = pcall(measure, dress, params, MapSpec)
	restoreTransparency(savedScarecrows)
	local scarecrowFailed = okScarecrows and scarecrows >= MIN_SCARECROWS and calScarecrow2 == 0
	emit("CAL_SCARECROWS_FAIL", scarecrowFailed, scarecrowFailed and 1 or 0, 1, {
		scarecrowsBefore = scarecrows,
		scarecrowsWhileHidden = if okScarecrows then calScarecrow2 else -1,
		gubukWhileHidden = if okScarecrows then calGubuk2 else -1,
	})

	-- CAL_NO_FLOATERS_FAIL: lift one ground-contact part by 2 studs, re-measure, restore CFrame.
	local probe = grounded[1]
	local savedCFrame = nil
	local liftedOk = pcall(function()
		if not probe then
			error("no ground-contact SawahDressing part to lift")
		end
		savedCFrame = probe.CFrame
		probe.CFrame = savedCFrame * CFrame.new(0, 2, 0)
	end)
	local okFloaters
	local calFloaters = {}
	if liftedOk then
		okFloaters, _, _, calFloaters = pcall(measure, dress, params, MapSpec)
	end
	pcall(function()
		if savedCFrame then
			probe.CFrame = savedCFrame
		end
	end)
	local floaterFailed = liftedOk and okFloaters and #floaters == 0 and #calFloaters >= 1
	emit("CAL_NO_FLOATERS_FAIL", floaterFailed, floaterFailed and 1 or 0, 1, {
		floatersBefore = #floaters,
		floatersWhileLifted = if okFloaters then #calFloaters else -1,
		probe = probe and probe.Name or "none",
	})
	-- No injection is staged; the only mutations were Transparency and CFrame, restored above.
end)

if not ok then
	local reason = { reason = "item 215 audit error: " .. tostring(err) }
	for _, name in ipairs(CHECK_NAMES) do
		emitOnce(name, false, 0, CHECK_TARGETS[name], reason)
	end
end

return results
