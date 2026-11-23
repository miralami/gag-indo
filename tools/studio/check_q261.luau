--!nocheck
-- check_q261: WORK_QUEUE item 261, self-contained SERVER-VM Studio check. Paste this whole file
-- into execute_luau in a FRESH Play session. It measures the live DataModel before and after
-- staging ONLY kampung_r10 via LookDevReview.enableAdditive, prints verbatim CHECK lines plus
-- SUMMARY_Q261, then restores with disableAll() on every path. No harness require, no place save,
-- no visual verdict.
--
--   MODEL_USED     12 staged houses own a baked model descendant (KampungModelAsset attribute)
--   NO_SCRIPTS     0 BaseScript instances under the staged folder
--   HOUSE_SCALE    all 12 staged house bounds within 20% of ModelMapKampungR10.BODY_SIZE
--   NO_MELONS      0 staged KampungHouse Ball parts with max(Size) >= 1.5
--   PATH_REACH     blocked hub-door rays after staging == the count measured before staging
--   PERF_BUDGET    <=500 BasePart centres inside the 100-stud proxy radius
--
-- CALIBRATION ANCHORS (each forces a FAIL the same measure must catch, then restores LIFO):
--   CAL_MODEL_USED_FAIL   clear the baked-model marker on every staged house -> house count drops
--   CAL_HOUSE_SCALE_FAIL  multiply every staged house part's Size -> all bounds leave 20% tolerance

local CANDIDATE_ID = "kampung_r10"
local HOUSE_ASSET_ID = 18239791051
local RAY_LENGTH, RAY_Y = 8, 6
local PERF_RADIUS, PERF_TARGET = 100, 500
local HUB_DOORS = {
	{ x = -64, z = -64, yaw = 0, depth = 52 },
	{ x = -80, z = -120, yaw = 0, depth = 28 },
	{ x = 68, z = -68, yaw = 0, depth = 44 },
	{ x = -108, z = 0, yaw = 90, depth = 40 },
	{ x = -68, z = 68, yaw = 180, depth = 44 },
	{ x = 68, z = 68, yaw = 180, depth = 34 },
}

local CHECK_NAMES = {
	"MODEL_USED",
	"NO_SCRIPTS",
	"HOUSE_SCALE",
	"NO_MELONS",
	"PATH_REACH",
	"PERF_BUDGET",
	"CAL_MODEL_USED_FAIL",
	"CAL_HOUSE_SCALE_FAIL",
}
local CHECK_TARGETS = {
	MODEL_USED = 12,
	NO_SCRIPTS = 0,
	HOUSE_SCALE = 12,
	NO_MELONS = 0,
	PATH_REACH = 0,
	PERF_BUDGET = PERF_TARGET,
	CAL_MODEL_USED_FAIL = 1,
	CAL_HOUSE_SCALE_FAIL = 1,
}

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

local review, Data = nil, nil
local injected = {}

local function attr(instance, key)
	local ok, value = pcall(function()
		return instance:GetAttribute(key)
	end)
	return ok and value or nil
end

local function stageKey()
	return if Data and Data.stageAttribute then Data.stageAttribute else "LookDevStage"
end

local function tagKey()
	return if Data and Data.tagAttribute then Data.tagAttribute else "KampungHouse"
end

local function modelKey()
	return if Data and Data.modelAttribute then Data.modelAttribute else "KampungModelAsset"
end

local function folderName()
	return if Data and Data.folderName then Data.folderName else "LookDevKampungR10_kampung_r10"
end

-- Record exact prior property/attribute values so every forced FAIL is undone LIFO.
local function recordSet(target, prop, value, isAttribute)
	local okRead, old = pcall(function()
		if isAttribute then
			return target:GetAttribute(prop)
		end
		return target[prop]
	end)
	if not okRead then
		return false
	end
	injected[#injected + 1] = { target = target, prop = prop, value = old, isAttribute = isAttribute }
	local okWrite, why = pcall(function()
		if isAttribute then
			target:SetAttribute(prop, value)
		else
			target[prop] = value
		end
	end)
	if not okWrite then
		warn("[check_q261] could not inject " .. prop .. ": " .. tostring(why))
	end
	return okWrite
end

local function restoreInjected()
	for index = #injected, 1, -1 do
		local entry = injected[index]
		if entry.restore then
			pcall(entry.restore)
		else
			pcall(function()
				if entry.isAttribute then
					entry.target:SetAttribute(entry.prop, entry.value)
				else
					entry.target[entry.prop] = entry.value
				end
			end)
		end
		injected[index] = nil
	end
end

local function descendants()
	local ok, list = pcall(function()
		return workspace:GetDescendants()
	end)
	if ok and type(list) == "table" then
		return list
	end
	return {}
end

-- One entry per staged baked house model. The attribute is set on the model root by the applier so
-- the check can identify a real baked model without relying on MeshId (pick 2 has zero meshes).
local function houseModels()
	local found, byHouse = {}, {}
	for _, instance in ipairs(descendants()) do
		local okModel, isModel = pcall(function()
			return instance:IsA("Model")
		end)
		if okModel and isModel and attr(instance, modelKey()) == HOUSE_ASSET_ID then
			local index = attr(instance, "house")
			if type(index) == "number" and attr(instance, "role") == "house" then
				local key = math.floor(index)
				if not found[key] then
					found[key] = instance
					byHouse[#byHouse + 1] = { index = key, model = instance }
				end
			end
		end
	end
	table.sort(byHouse, function(a, b)
		return a.index < b.index
	end)
	return byHouse
end

local function measureHouses()
	local models = houseModels()
	local tolerance = (Data and Data.scaleTolerance) or 0.2
	local target = (Data and Data.BODY_SIZE) or { 16, 9, 12 }
	local good, bad, samples = 0, {}, {}
	for _, entry in ipairs(models) do
		local okBounds, _, size = pcall(function()
			return entry.model:GetBoundingBox()
		end)
		local axis = if okBounds and size then { size.X, size.Y, size.Z } else nil
		local within = axis ~= nil
			and math.abs(axis[1] - target[1]) <= target[1] * tolerance
			and math.abs(axis[2] - target[2]) <= target[2] * tolerance
			and math.abs(axis[3] - target[3]) <= target[3] * tolerance
		if within then
			good += 1
		else
			bad[#bad + 1] = "house " .. entry.index
		end
		if axis then
			samples[#samples + 1] = string.format("h%d %.2fx%.2fx%.2f", entry.index, axis[1], axis[2], axis[3])
		end
	end
	return #models, good, samples, bad
end

local function measureScripts()
	local folder = nil
	pcall(function()
		folder = workspace:FindFirstChild(folderName())
	end)
	local offenders = {}
	for _, instance in ipairs(descendants()) do
		local okScript, isScript = pcall(function()
			return instance:IsA("BaseScript")
		end)
		if okScript and isScript then
			local underFolder = false
			pcall(function()
				underFolder = folder ~= nil and instance:FindFirstAncestor(folder.Name) ~= nil
			end)
			if underFolder or attr(instance, stageKey()) == CANDIDATE_ID then
				local okName, name = pcall(function()
					return instance:GetFullName()
				end)
				offenders[#offenders + 1] = okName and name or "unreadable script"
			end
		end
	end
	return offenders
end

local function measureMelons()
	local offenders = {}
	for _, instance in ipairs(descendants()) do
		if attr(instance, tagKey()) == true then
			local okBase, isBase = pcall(function()
				return instance:IsA("BasePart")
			end)
			if okBase and isBase then
				local okShape, shape = pcall(function()
					return instance.Shape
				end)
				if okShape and shape == Enum.PartType.Ball then
					local okSize, size = pcall(function()
						return instance.Size
					end)
					if okSize and math.max(size.X, size.Y, size.Z) >= 1.5 then
						offenders[#offenders + 1] = instance:GetFullName()
					end
				end
			end
		end
	end
	return offenders
end

local function hubDoors()
	local doors = {}
	local okMap, MapSpec = pcall(function()
		return require(game:GetService("ServerScriptService"):WaitForChild("Server").World.MapSpec)
	end)
	if okMap and type(MapSpec) == "table" and type(MapSpec.hub) == "function" then
		for _, key in ipairs(MapSpec.HUB_ORDER) do
			local okHub, hub = pcall(MapSpec.hub, key)
			if okHub and hub then
				doors[#doors + 1] = hub
			end
		end
	end
	return #doors > 0 and doors or HUB_DOORS
end

local function blockedDoorRays()
	local blocked, rayErrors = 0, 0
	local okParams, params = pcall(function()
		local q = RaycastParams.new()
		q.IgnoreWater = false
		return q
	end)
	if not okParams then
		return blocked, 1
	end
	for _, hub in ipairs(hubDoors()) do
		local a = math.rad(hub.yaw or 0)
		local depth = hub.depth or 40
		local ox = hub.x + math.sin(a) * (depth / 2 + 1)
		local oz = hub.z + math.cos(a) * (depth / 2 + 1)
		local okRay, hit = pcall(function()
			return workspace:Raycast(
				Vector3.new(ox, RAY_Y, oz),
				Vector3.new(math.sin(a), 0, math.cos(a)) * RAY_LENGTH,
				params
			)
		end)
		if not okRay then
			rayErrors += 1
		elseif hit and hit.Instance then
			local okTerrain, isTerrain = pcall(function()
				return hit.Instance:IsA("Terrain")
			end)
			if attr(hit.Instance, tagKey()) == true or not (okTerrain and isTerrain) then
				blocked += 1
			end
		end
	end
	return blocked, rayErrors
end

local function measurePerf()
	local parts, errors = 0, 0
	for _, instance in ipairs(descendants()) do
		local okBase, isBase = pcall(function()
			return instance:IsA("BasePart")
		end)
		if okBase and isBase then
			local okPosition, position = pcall(function()
				return instance.CFrame.Position
			end)
			if not okPosition then
				okPosition, position = pcall(function()
					return instance.Position
				end)
			end
			if not okPosition or not position then
				errors += 1
			else
				local x, y, z = position.X, position.Y, position.Z
				if type(x) == "number" and type(y) == "number" and type(z) == "number" then
					if x * x + y * y + z * z <= PERF_RADIUS * PERF_RADIUS then
						parts += 1
					end
				else
					errors += 1
				end
			end
		end
	end
	return parts, errors
end

local function measure()
	local houses, scaled, samples, badScale = measureHouses()
	local scripts = measureScripts()
	local melons = measureMelons()
	local blocked, rayErrors = blockedDoorRays()
	local perfParts, perfErrors = measurePerf()
	return {
		houses = houses,
		scaled = scaled,
		samples = samples,
		badScale = badScale,
		scripts = scripts,
		melons = melons,
		blocked = blocked,
		rayErrors = rayErrors,
		perfParts = perfParts,
		perfErrors = perfErrors,
	}
end

local function emptyMeasure()
	return {
		houses = 0,
		scaled = 0,
		samples = {},
		badScale = {},
		scripts = {},
		melons = {},
		blocked = 0,
		rayErrors = 1,
		perfParts = 0,
		perfErrors = 1,
	}
end

local ok, err = pcall(function()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	review = require(shared:WaitForChild("LookDevReview"))
	Data = require(shared:WaitForChild("ModelMapKampungR10"))
	local LookDev = require(shared:WaitForChild("LookDev"))
	if
		type(Data) ~= "table"
		or type(Data.houses) ~= "function"
		or type(Data.BODY_SIZE) ~= "table"
		or type(review.enableAdditive) ~= "function"
		or type(review.disableAll) ~= "function"
	then
		error("ModelMapKampungR10 / LookDevReview API missing")
	end

	-- Runtime wiring only; owner registry files are untouched.
	if type(LookDev.candidates) == "table" and not LookDev.candidates[CANDIDATE_ID] then
		LookDev.candidates[CANDIDATE_ID] = { id = CANDIDATE_ID }
	end
	if type(LookDev.IDS) == "table" and not table.find(LookDev.IDS, CANDIDATE_ID) then
		LookDev.IDS[#LookDev.IDS + 1] = CANDIDATE_ID
	end
	if type(review.paths) == "table" and not review.paths[CANDIDATE_ID] then
		review.paths[CANDIDATE_ID] = { datamodel = "server", path = { "World", "LookDevKampungR10" } }
	end
	local okApplier, applier = pcall(function()
		local server = game:GetService("ServerScriptService"):WaitForChild("Server")
		return require(server:WaitForChild("World"):WaitForChild("LookDevKampungR10"))
	end)
	if okApplier and type(applier) == "table" and type(applier.apply) == "function" then
		pcall(LookDev.register, CANDIDATE_ID, applier)
	end

	local before = measure()
	local enableOk, enabled, why = pcall(review.enableAdditive, CANDIDATE_ID, game)
	local reason = nil
	if not enableOk or not enabled then
		reason = "enableAdditive failed: " .. tostring(why)
	end
	local after = measure()
	local expected = Data.HOUSE_COUNT or 12

	emit("MODEL_USED", reason == nil and after.houses == expected, after.houses, expected, {
		before = before.houses,
		assetId = HOUSE_ASSET_ID,
		reason = reason,
	})
	emit("NO_SCRIPTS", #after.scripts == 0, #after.scripts, 0, {
		before = #before.scripts,
		names = after.scripts,
		reason = reason,
	})
	emit("HOUSE_SCALE", reason == nil and after.scaled == expected, after.scaled, expected, {
		samples = after.samples,
		bad = after.badScale,
		target = Data.BODY_SIZE,
		tolerance = Data.scaleTolerance,
		reason = reason,
	})
	emit("NO_MELONS", #after.melons == 0, #after.melons, 0, {
		before = #before.melons,
		names = after.melons,
		reason = reason,
	})
	emit(
		"PATH_REACH",
		reason == nil and after.rayErrors == 0 and after.blocked == before.blocked,
		after.blocked,
		before.blocked,
		{
			before = before.blocked,
			rays = 6,
			length = RAY_LENGTH,
			rayErrors = after.rayErrors,
			reason = reason,
		}
	)
	emit(
		"PERF_BUDGET",
		reason == nil and after.perfErrors == 0 and after.perfParts <= PERF_TARGET,
		after.perfParts,
		PERF_TARGET,
		{
			before = before.perfParts,
			readErrors = after.perfErrors,
			radius = PERF_RADIUS,
			reason = reason,
		}
	)

	-- CALIBRATION ANCHOR (MODEL_USED FAIL): clear the baked-model marker on every staged house Model
	-- so the measured house count necessarily falls below the target. houseModels() reads that
	-- marker on every IsA("Model") descendant, and the applier tags nested models too: clearing only
	-- the 12 roots lets a nested model take each cleared root's slot and the count stays 12.
	local usedInjected = 0
	for _, instance in ipairs(descendants()) do
		local okModel, isModel = pcall(function()
			return instance:IsA("Model")
		end)
		if okModel and isModel and attr(instance, modelKey()) == HOUSE_ASSET_ID then
			if recordSet(instance, modelKey(), 0, true) then
				usedInjected += 1
			end
		end
	end
	local calUsed = measure()
	local usedFailed = usedInjected > 0 and calUsed.houses < expected
	emit("CAL_MODEL_USED_FAIL", usedFailed, usedFailed and 1 or 0, 1, {
		injected = usedInjected,
		before = after.houses,
		houses = calUsed.houses,
	})
	restoreInjected()

	-- CALIBRATION ANCHOR (HOUSE_SCALE FAIL): multiply every staged house part's Size so every
	-- bounding box leaves the 20% tolerance. recordSet restores each Vector3 byte-exactly.
	local scaleInjected = 0
	for _, entry in ipairs(houseModels()) do
		pcall(function()
			for _, instance in ipairs(entry.model:GetDescendants()) do
				local okBase, isBase = pcall(function()
					return instance:IsA("BasePart")
				end)
				if okBase and isBase then
					local oldSize = instance.Size
					if recordSet(instance, "Size", oldSize * 3, false) then
						scaleInjected += 1
					end
				end
			end
		end)
	end
	local calScale = measure()
	local scaleFailed = scaleInjected > 0 and calScale.scaled < expected
	emit("CAL_HOUSE_SCALE_FAIL", scaleFailed, scaleFailed and 1 or 0, 1, {
		injected = scaleInjected,
		before = after.scaled,
		scaled = calScale.scaled,
	})
	restoreInjected()
end)

-- Restore every mutation on every path: injections first, then all additive candidates.
restoreInjected()
pcall(function()
	if review then
		review.disableAll()
	else
		require(game:GetService("ReplicatedStorage").Shared.LookDevReview).disableAll()
	end
end)

if not ok then
	local reason = { reason = "item 261 audit error: " .. tostring(err) }
	for _, name in ipairs(CHECK_NAMES) do
		emitOnce(name, false, 0, CHECK_TARGETS[name], reason)
	end
end

local function measured(name)
	local entry = results.byName[name]
	return type(entry and entry.measured) == "number" and entry.measured or 0
end

local final = ok and measure() or emptyMeasure()
local calPass = 0
for _, name in ipairs({ "CAL_MODEL_USED_FAIL", "CAL_HOUSE_SCALE_FAIL" }) do
	local entry = results.byName[name]
	if entry and entry.passed then
		calPass += 1
	end
end
print(
	string.format(
		"SUMMARY_Q261 MODEL_USED %d/%d NO_SCRIPTS %d/0 HOUSE_SCALE %d/%d NO_MELONS %d/0 PATH_REACH %d/%d PERF_BUDGET %d/%d CAL %d/2",
		measured("MODEL_USED"),
		CHECK_TARGETS.MODEL_USED,
		measured("NO_SCRIPTS"),
		measured("HOUSE_SCALE"),
		CHECK_TARGETS.HOUSE_SCALE,
		measured("NO_MELONS"),
		measured("PATH_REACH"),
		final.blocked,
		measured("PERF_BUDGET"),
		PERF_TARGET,
		calPass
	)
)

return results
