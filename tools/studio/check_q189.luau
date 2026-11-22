--!nocheck
-- check_q189: WORK_QUEUE section Q item 189, self-contained SERVER-VM Studio check. Paste this whole
-- file into execute_luau in a fresh Play session. It stages rocks_r9 with enableAdditive in this SAME
-- call, measures ROCK_COUNT / ROCK_MODELS / ROCK_SIZE / ROCK_VISIBLE on the live staged Models, prints
-- verbatim CHECK lines and restores with disableAll(). No harness require, no place save, no visual
-- verdict.
--
-- ROCK_COUNT: >= 40 tagged rock Models staged under the rocks_r9 folder.
-- ROCK_MODELS: >= 3 DISTINCT real baked asset ids, each present as a RockAssetId attribute on a
--   staged rock Model AND with a baked copy under ServerStorage.LookDevAssets.<id>. Stripping the
--   attribute or removing a baked folder FAILs it; a Part-built rock cannot supply an id.
-- ROCK_SIZE: longest side of each staged rock from its live Model bounding box, 0.8..2.5 studs,
--   median >= 1.2 (item-176 envelope retained; item 189 asks for 1-3 stud rocks).
-- ROCK_VISIBLE: >= 8 rocks visible from the named `river_rocks` ReviewCameras entry. Five camera-plane
--   probes per rock are raycast from the camera eye to the rock bounding box; a rock counts only when
--   >=60% of probes hit its own Model. Missing folder, camera, baked asset or rocks are FAILs.

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

local ROCK_MIN = 40
local MODEL_MIN = 3
local SIZE_MIN = 0.8
local SIZE_MAX = 2.5
local MEDIAN_MIN = 1.2
local VISIBLE_MIN = 8
local HIT_FRACTION = 0.6

local function vec(values)
	return Vector3.new(values[1], values[2], values[3])
end

local function bboxOf(model)
	local ok, cf, size = pcall(function()
		return model:GetBoundingBox()
	end)
	if not ok or not cf or not size then
		return nil, nil
	end
	return cf.Position, size
end

local function median(values)
	if #values == 0 then
		return 0
	end
	table.sort(values)
	return values[math.ceil(#values / 2)]
end

local values = nil
local review = nil
local ok, err = pcall(function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	review = require(ReplicatedStorage.Shared.LookDevReview)
	local data = require(ReplicatedStorage.Shared.ModelMapRocksR9)
	local cameras = require(ReplicatedStorage.Shared.ReviewCameras)

	local enabled, why = review.enableAdditive("rocks_r9", game)
	if not enabled then
		error("enableAdditive(rocks_r9) failed: " .. tostring(why))
	end
	local workspace = game:GetService("Workspace")
	local folder = workspace:FindFirstChild(data.folderName)
	if not folder then
		error("staging folder missing: " .. tostring(data.folderName))
	end
	local models = {}
	for _, inst in ipairs(folder:GetDescendants()) do
		local tagged, isModel = pcall(function()
			return inst:IsA("Model") and inst:GetAttribute(data.rockAttribute) == data.familyId
		end)
		if tagged and isModel then
			models[#models + 1] = inst
		end
	end
	if #models == 0 then
		error("staging folder has no tagged rock Models")
	end

	-- ROCK_MODELS: distinct real baked asset ids on staged rocks with a baked folder present.
	local idAttr = type(data.ROCK_ASSET_ID_ATTRIBUTE) == "string" and data.ROCK_ASSET_ID_ATTRIBUTE or "RockAssetId"
	local bakedRoot = game:GetService("ServerStorage"):FindFirstChild("LookDevAssets")
	local seen, distinct = {}, {}
	for _, model in ipairs(models) do
		local okId, assetId = pcall(function()
			return model:GetAttribute(idAttr)
		end)
		if okId and type(assetId) == "number" and assetId > 0 and assetId % 1 == 0 and not seen[assetId] then
			seen[assetId] = true
			local baked = bakedRoot and bakedRoot:FindFirstChild(tostring(assetId))
			if baked then
				distinct[#distinct + 1] = assetId
			end
		end
	end
	table.sort(distinct)

	-- ROCK_SIZE: longest side of each staged rock, from its live Model bounding box.
	local sizes, outOfRange = {}, {}
	for _, model in ipairs(models) do
		local _, size = bboxOf(model)
		if not size then
			outOfRange[#outOfRange + 1] = model:GetFullName() .. ":unreadable-box"
		else
			local longest = math.max(size.X, size.Y, size.Z)
			sizes[#sizes + 1] = longest
			if longest < SIZE_MIN or longest > SIZE_MAX then
				outOfRange[#outOfRange + 1] = string.format("%s:%.2f", model:GetFullName(), longest)
			end
		end
	end
	local measuredMedian = median(sizes)

	-- ROCK_VISIBLE: the named server camera, five camera-plane probes per rock.
	local camera = cameras.get("river_rocks")
	if not camera then
		error("ReviewCameras has no river_rocks camera")
	end
	local eye, lookAt = vec(camera.position), vec(camera.lookAt)
	if (eye - lookAt).Magnitude < 0.01 then
		error("river_rocks camera has no view direction")
	end
	local view = CFrame.lookAt(eye, lookAt)
	local ignore = {}
	local okPlayers, players = pcall(function()
		return game:GetService("Players"):GetPlayers()
	end)
	if okPlayers and type(players) == "table" then
		for _, player in ipairs(players) do
			local okChar, character = pcall(function()
				return player.Character
			end)
			if okChar and character then
				ignore[#ignore + 1] = character
			end
		end
	end

	local probes = {
		{ 0, 0 },
		{ 0, 0.3 },
		{ -0.25, 0.15 },
		{ 0.25, 0.15 },
		{ 0, -0.15 },
	}
	local visible, rayErrors = 0, 0
	local blocked = {}
	for _, model in ipairs(models) do
		local centre, size = bboxOf(model)
		if not centre or not size then
			rayErrors += 1
		else
			local hits = 0
			for _, probe in ipairs(probes) do
				local offset = view:VectorToWorldSpace(Vector3.new(probe[1] * size.X, probe[2] * size.Y, 0))
				local target = centre + offset
				local delta = target - eye
				if delta.Magnitude < 0.01 then
					rayErrors += 1
				else
					local okParams, params = pcall(function()
						local p = RaycastParams.new()
						p.FilterType = Enum.RaycastFilterType.Exclude
						p.FilterDescendantsInstances = ignore
						p.IgnoreWater = true
						return p
					end)
					local okRay, hit = false, nil
					if okParams and params then
						okRay, hit = pcall(function()
							return workspace:Raycast(eye, delta, params)
						end)
					end
					if not okParams or not okRay then
						rayErrors += 1
					elseif hit and hit.Instance then
						local own = false
						pcall(function()
							own = hit.Instance == model or hit.Instance:IsDescendantOf(model)
						end)
						if own then
							hits += 1
						end
					end
				end
			end
			if hits >= math.ceil(#probes * HIT_FRACTION) then
				visible += 1
			elseif #blocked < 8 then
				blocked[#blocked + 1] = model:GetFullName() .. ":" .. hits .. "/" .. #probes
			end
		end
	end

	values = {
		count = #models,
		models = distinct,
		median = measuredMedian,
		sizeBad = #outOfRange,
		sizeBadDetail = outOfRange,
		visible = visible,
		rayErrors = rayErrors,
		blocked = blocked,
		probes = #probes,
		camera = camera.name,
	}
end)

-- Restore every additively staged candidate even when a measurement threw.
pcall(function()
	if review then
		review.disableAll()
	else
		require(game:GetService("ReplicatedStorage").Shared.LookDevReview).disableAll()
	end
end)

if not ok or not values then
	local reason = { reason = "audit error: " .. tostring(err) }
	emit("ROCK_COUNT", false, 0, ROCK_MIN, reason)
	emit("ROCK_MODELS", false, 0, MODEL_MIN, reason)
	emit("ROCK_SIZE", false, 0, MEDIAN_MIN, reason)
	emit("ROCK_VISIBLE", false, 0, VISIBLE_MIN, reason)
else
	emit("ROCK_COUNT", values.count >= ROCK_MIN, values.count, ROCK_MIN, { models = values.count, folder = true })
	emit(
		"ROCK_MODELS",
		#values.models >= MODEL_MIN,
		#values.models,
		MODEL_MIN,
		{ ids = values.models, idAttr = "RockAssetId" }
	)
	emit(
		"ROCK_SIZE",
		values.sizeBad == 0 and values.median >= MEDIAN_MIN,
		string.format("%.2f", values.median),
		MEDIAN_MIN,
		{ envelope = SIZE_MIN .. ".." .. SIZE_MAX, outOfRange = values.sizeBad, examples = values.sizeBadDetail }
	)
	emit("ROCK_VISIBLE", values.visible >= VISIBLE_MIN and values.rayErrors == 0, values.visible, VISIBLE_MIN, {
		camera = values.camera,
		probes = values.probes,
		hitFraction = HIT_FRACTION,
		rayErrors = values.rayErrors,
		blocked = values.blocked,
	})
end

return results
