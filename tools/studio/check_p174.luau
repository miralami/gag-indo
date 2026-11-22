--!nocheck
-- check_p174: WORK_QUEUE section P item 174, self-contained SERVER-VM Studio check. Paste the whole
-- file into execute_luau in a fresh Play session. It stages river_r8 with enableAdditive in this
-- SAME call, measures the live tagged plant parts, prints exactly three verbatim CHECK lines and
-- restores every additive candidate with disableAll(). No harness require, no place save, no visual
-- verdict. Missing folder / tags / reads FAIL; there is no vacuous pass.
--
--   NO_CUBE_SHRUBS  no procedural bank part is a Block with all 3 sizes within 20% at >=1.5 studs
--   BANK_PLANTS     >=40 distinct planted centres (bank_veg / BankPlant tags)
--   WATER_CLEAR     every plant part's oriented Z extent clears the 28-wide channel (half 14)

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
	return results
end

local function emitOnce(name, passed, measured, target, detail)
	if not results.byName[name] then
		emit(name, passed, measured, target, detail)
	end
end

local CUBE_RATIO = 1.2
local CUBE_MIN_SIZE = 1.5
local PLANT_MIN = 40
local WATER_HALF = 14 -- mirrored from MapSpec.RIVER_HALF by Shared.ModelMapRiverR8.WATER_HALF

local function isCubeShrub(shape, size)
	if shape ~= "Block" then
		return false
	end
	if type(size) ~= "table" or #size < 3 then
		return true -- unreadable geometry is an offender, never a skip
	end
	local smallest = math.min(size[1], size[2], size[3])
	local largest = math.max(size[1], size[2], size[3])
	if smallest < CUBE_MIN_SIZE then
		return false
	end
	return largest <= smallest * CUBE_RATIO
end

-- Cheap self-probe: the same predicate must reject BOTH old hedge bases (1.6^3 and 2.6/2.4/2.6)
-- and accept the new Ball/Wedge forms. If it does not, NO_CUBE_SHRUBS is forced FAIL.
local probeOk = isCubeShrub("Block", { 1.6, 1.6, 1.6 })
	and isCubeShrub("Block", { 2.6, 2.4, 2.6 })
	and not isCubeShrub("Ball", { 1.7, 1.9, 1.5 })
	and not isCubeShrub("Wedge", { 1.1, 2.4, 0.9 })

local review = nil
local ok, err = pcall(function()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	review = require(shared:WaitForChild("LookDevReview"))
	local data = require(shared:WaitForChild("ModelMapRiverR8"))

	local enabled, why = review.enableAdditive("river_r8", game)
	if not enabled then
		error("enableAdditive(river_r8) failed: " .. tostring(why))
	end
	local folder = workspace:FindFirstChild(data.folderName)
	if not folder then
		error("staging folder missing: " .. tostring(data.folderName))
	end
	local descendants = folder:GetDescendants()
	if type(descendants) ~= "table" or #descendants == 0 then
		error("staging folder has no descendants")
	end

	-- Use the live MapSpec centreline when readable; the pure shared mirror is the fallback.
	local centreFn = data.RIVER_CENTRE
	local okSpec, mapSpec = pcall(function()
		return require(game:GetService("ServerScriptService").Server.World.MapSpec)
	end)
	if okSpec and type(mapSpec) == "table" and type(mapSpec.riverCentreZ) == "function" then
		centreFn = mapSpec.riverCentreZ
	end
	local waterHalf = type(data.WATER_HALF) == "number" and data.WATER_HALF or WATER_HALF
	if waterHalf ~= WATER_HALF then
		error("channel half-width mismatch: " .. tostring(waterHalf))
	end

	local plantParts = {}
	for _, instance in ipairs(descendants) do
		if instance:IsA("BasePart") then
			local bankPlant = instance:GetAttribute("BankPlant")
			local kind = instance:GetAttribute("Kind")
			if bankPlant == true or kind == "bank_veg" then
				plantParts[#plantParts + 1] = instance
			end
		end
	end
	if #plantParts == 0 then
		error("no BankPlant / bank_veg tagged parts under " .. tostring(data.folderName))
	end

	-- NO_CUBE_SHRUBS: every procedural plant part, plus any stray non-model part in the bank-veg
	-- folder. Baked model descendants are excluded (their meshes are not the old base hedge).
	local function underBakedModel(part)
		local node = part.Parent
		while node and node ~= folder do
			local okKind, kind = pcall(function()
				return node:GetAttribute("Kind")
			end)
			if okKind and kind == "bank_veg_model" then
				return true
			end
			node = node.Parent
		end
		return false
	end

	local seen, candidates = {}, {}
	local function addCandidate(part)
		if not seen[part] then
			seen[part] = true
			candidates[#candidates + 1] = part
		end
	end
	for _, part in ipairs(plantParts) do
		addCandidate(part)
	end
	local vegFolder = folder:FindFirstChild("BankVeg_river_r8")
	if vegFolder then
		for _, part in ipairs(vegFolder:GetDescendants()) do
			if part:IsA("BasePart") and not underBakedModel(part) then
				addCandidate(part)
			end
		end
	end

	local cubeFailures, cubeList = 0, {}
	for _, part in ipairs(candidates) do
		local okRead, shapeName, size = pcall(function()
			local shape = part.Shape
			local raw = part.Size
			return shape and shape.Name or "?", { raw.X, raw.Y, raw.Z }
		end)
		local bad = not okRead
		if not bad then
			bad = isCubeShrub(shapeName, size)
		end
		if bad then
			cubeFailures += 1
			if #cubeList < 10 then
				cubeList[#cubeList + 1] = part:GetFullName()
			end
		end
	end
	emit("NO_CUBE_SHRUBS", probeOk and cubeFailures == 0, cubeFailures, 0, {
		checked = #candidates,
		taggedParts = #plantParts,
		offenders = cubeList,
		probeOk = probeOk,
		folderPresent = true,
	})

	-- BANK_PLANTS: count distinct planted centres via VegX/VegZ (fallback: part position) so a
	-- 3-blade cluster is one plant, not three.
	local centres = {}
	for _, part in ipairs(plantParts) do
		local okRead, x, z = pcall(function()
			local vx, vz = part:GetAttribute("VegX"), part:GetAttribute("VegZ")
			if type(vx) == "number" and type(vz) == "number" then
				return vx, vz
			end
			local pos = part.Position
			return pos.X, pos.Z
		end)
		if okRead and type(x) == "number" and type(z) == "number" then
			centres[string.format("%.3f:%.3f", x, z)] = true
		end
	end
	local plantCount = 0
	for _ in pairs(centres) do
		plantCount += 1
	end
	emit("BANK_PLANTS", plantCount >= PLANT_MIN, plantCount, ">=" .. PLANT_MIN, {
		taggedParts = #plantParts,
		distinctCentres = plantCount,
		folderPresent = true,
	})

	-- WATER_CLEAR: use the part's real orientation. CFrame:VectorToWorldSpace maps the local X/Z
	-- axes into world space so a rotated blade's inward edge is measured, not just its centre.
	-- VectorToWorldVector is not available in this Studio build and must not be used here.
	local waterFailures, waterList = 0, {}
	for _, part in ipairs(plantParts) do
		local okRead, px, pz, halfZ = pcall(function()
			local cf = part.CFrame
			local size = part.Size
			local axisX = cf:VectorToWorldSpace(Vector3.new(1, 0, 0))
			local axisZ = cf:VectorToWorldSpace(Vector3.new(0, 0, 1))
			return cf.Position.X, cf.Position.Z, math.abs(axisX.Z) * size.X * 0.5 + math.abs(axisZ.Z) * size.Z * 0.5
		end)
		if not okRead then
			waterFailures += 1
			if #waterList < 10 then
				waterList[#waterList + 1] = "unreadable part"
			end
		else
			local centreZ = centreFn(px)
			local clearance = math.min(math.abs(pz - halfZ - centreZ), math.abs(pz + halfZ - centreZ))
			if clearance <= waterHalf then
				waterFailures += 1
				if #waterList < 10 then
					waterList[#waterList + 1] = string.format(
						"%s x=%.2f z=%.2f halfZ=%.2f clear=%.2f",
						part:GetFullName(),
						px,
						pz,
						halfZ,
						clearance
					)
				end
			end
		end
	end
	emit("WATER_CLEAR", waterFailures == 0, waterFailures, 0, {
		checked = #plantParts,
		waterHalf = waterHalf,
		offenders = waterList,
		folderPresent = true,
	})
end)

-- Restore every additively staged candidate, even when a check threw.
pcall(function()
	if review then
		review.disableAll()
	else
		require(game:GetService("ReplicatedStorage"):WaitForChild("Shared").LookDevReview).disableAll()
	end
end)

if not ok then
	local reason = { reason = "audit error: " .. tostring(err) }
	emitOnce("NO_CUBE_SHRUBS", false, 0, 0, reason)
	emitOnce("BANK_PLANTS", false, 0, ">=" .. PLANT_MIN, reason)
	emitOnce("WATER_CLEAR", false, 0, 0, reason)
end

return results
