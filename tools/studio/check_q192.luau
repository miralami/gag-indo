--!nocheck
-- check_q192: WORK_QUEUE section Q item 192, self-contained SERVER-VM Studio check. Paste this whole
-- file into execute_luau in a fresh Play session. It stages river_r8 with enableAdditive in this
-- SAME call, measures the live tagged geometry, prints verbatim CHECK lines and restores with
-- disableAll(). No harness require, no place save, no visual verdict.
--
--   NO_CUBE_SHRUBS  no procedural bank part is a Block with all 3 sizes within 20% at >=1.5 studs
--   BANK_PLANTS     >=60 distinct planted centres (BankPlant / bank_veg tags), up from item 174's 40
--   BANK_MODELS     >=3 distinct real baked Creator Store model IDs published on bank plant models
--   WATER_CLEAR     every bank plant part's oriented Z extent clears the 28-wide channel (half 14)
--   LILY_PADS       >=6 real baked lily pads inside the channel beside the bridge, on the water

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

local CUBE_RATIO = 1.2
local CUBE_MIN_SIZE = 1.5
local PLANT_MIN = 60
local MODEL_MIN = 3
local LILY_MIN = 6
local WATER_HALF = 14

local function isCubeShrub(shape, size)
	if shape ~= "Block" then
		return false
	end
	if type(size) ~= "table" or #size < 3 then
		return true
	end
	local smallest = math.min(size[1], size[2], size[3])
	local largest = math.max(size[1], size[2], size[3])
	if smallest < CUBE_MIN_SIZE then
		return false
	end
	return largest <= smallest * CUBE_RATIO
end

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

	local modelAttr = data.BANK_MODEL_ID_ATTRIBUTE or "BankModelId"
	local lilyAttr = data.LILY_ASSET_ID_ATTRIBUTE or "LilyAssetId"

	-- Gather tagged bank-plant base parts, baked plant models and lily parts in one pass.
	local plantParts, bakedModels, lilyParts = {}, {}, {}
	for _, instance in ipairs(descendants) do
		if instance:IsA("BasePart") then
			local bankPlant = instance:GetAttribute("BankPlant")
			local kind = instance:GetAttribute("Kind")
			if bankPlant == true or kind == "bank_veg" then
				plantParts[#plantParts + 1] = instance
			end
			if instance:GetAttribute("WaterLily") == true and kind == "water_lily" then
				lilyParts[#lilyParts + 1] = instance
			end
		end
		local mid = instance:GetAttribute(modelAttr)
		if type(mid) == "number" then
			bakedModels[#bakedModels + 1] = instance
		end
	end
	if #plantParts == 0 then
		error("no BankPlant / bank_veg tagged parts under " .. tostring(data.folderName))
	end

	local function underBakedModel(part)
		local node = part.Parent
		while node and node ~= folder do
			local okKind, kind = pcall(function()
				return node:GetAttribute("Kind")
			end)
			if okKind and (kind == "bank_veg_model" or kind == "water_lily") then
				return true
			end
			node = node.Parent
		end
		return false
	end

	-- NO_CUBE_SHRUBS: procedural bank parts only (baked-model meshes excluded).
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
	})

	-- BANK_PLANTS: distinct planted centres via VegX/VegZ so a 3-blade cluster counts once.
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
	emit("BANK_PLANTS", plantCount >= PLANT_MIN, plantCount, PLANT_MIN, {
		taggedParts = #plantParts,
		distinctCentres = plantCount,
	})

	-- BANK_MODELS: distinct real baked model IDs published on staged bank plant models. A clone
	-- without the ID attribute cannot pass; adding the attribute to a plain Part is still backed by
	-- the ServerStorage.LookDevAssets.<id> folder check below.
	local bakedRoot = game:GetService("ServerStorage"):FindFirstChild("LookDevAssets")
	local ids, wrongIds = {}, {}
	for _, model in ipairs(bakedModels) do
		local kind = model:GetAttribute("Kind")
		if kind == "bank_veg_model" then
			local mid = model:GetAttribute(modelAttr)
			if type(mid) == "number" and bakedRoot and bakedRoot:FindFirstChild(tostring(mid)) then
				ids[mid] = true
			else
				wrongIds[#wrongIds + 1] = tostring(mid)
			end
		end
	end
	local modelCount = 0
	for _ in pairs(ids) do
		modelCount += 1
	end
	local idList = {}
	for id in pairs(ids) do
		idList[#idList + 1] = id
	end
	table.sort(idList)
	emit("BANK_MODELS", modelCount >= MODEL_MIN, modelCount, MODEL_MIN, {
		ids = idList,
		noBakedFolder = #wrongIds,
		taggedModels = #bakedModels,
	})

	-- WATER_CLEAR: oriented Z extent of every bank plant base part clears the 28-wide channel.
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
	})

	-- LILY_PADS: real baked lily parts inside the channel beside the bridge, with the baked ID.
	local lilyCentres, lilyBad = {}, {}
	for _, part in ipairs(lilyParts) do
		local okRead, x, z, y, lid = pcall(function()
			return part.Position.X, part.Position.Z, part.Position.Y, part:GetAttribute(lilyAttr)
		end)
		if
			not okRead
			or type(lid) ~= "number"
			or not bakedRoot
			or not bakedRoot:FindFirstChild(tostring(lid))
			or math.abs(z - centreFn(x)) >= waterHalf
			or math.abs(x) <= 6
			or type(y) ~= "number"
			or y > 1
		then
			lilyBad[#lilyBad + 1] = okRead and string.format("x=%.2f z=%.2f y=%.2f id=%s", x, z, y, tostring(lid))
				or "unreadable"
		else
			lilyCentres[string.format("%.3f:%.3f", x, z)] = true
		end
	end
	local lilyCount = 0
	for _ in pairs(lilyCentres) do
		lilyCount += 1
	end
	emit("LILY_PADS", lilyCount >= LILY_MIN, lilyCount, LILY_MIN, {
		distinctPads = lilyCount,
		badParts = lilyBad,
		method = "WaterLily/water_lily parts with real baked LilyAssetId, inside channel beside bridge, y<=1",
	})
end)

-- Restore every additively staged candidate, even when a measurement threw.
pcall(function()
	if review then
		review.disableAll()
	else
		require(game:GetService("ReplicatedStorage").Shared.LookDevReview).disableAll()
	end
end)

if not ok then
	local reason = { reason = "audit error: " .. tostring(err) }
	emitOnce("NO_CUBE_SHRUBS", false, 1, 0, reason)
	emitOnce("BANK_PLANTS", false, 0, PLANT_MIN, reason)
	emitOnce("BANK_MODELS", false, 0, MODEL_MIN, reason)
	emitOnce("WATER_CLEAR", false, 1, 0, reason)
	emitOnce("LILY_PADS", false, 0, LILY_MIN, reason)
end

return results
