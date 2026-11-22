--!nocheck
-- check_q191: WORK_QUEUE section Q item 191, self-contained SERVER-VM Studio check. Paste this whole
-- file into execute_luau in a fresh Play session. It stages sawah_r8 with enableAdditive in this
-- SAME call, measures the live baked padi and prints verbatim CHECK lines, then restores with
-- disableAll(). No harness require, no place save, no visual verdict.
--
-- PADI_IS_MODEL: >= 1 staged PadiPart BasePart is a MeshPart carrying PadiAssetId == the baked padi
--   id, with a baked copy under ServerStorage.LookDevAssets.<id>. Procedural blades cannot pass.
-- PADI_STAGES: >= 2 distinct numeric GrowthStage values across the staged padi parts (yellower
--   terraces use a different stage). PADI_ROWS / SAWAH_GREEN / BUND_SHAPE reuse the item-140/178
--   contracts. SAWAH_TOPS and PERF_BUDGET are regression checks (terrain-only / near-origin census).

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

local PADI_ROWS_MIN = 10
local GREEN_MIN = 40
local STAGES_MIN = 2
local SAWAH_TOP_TOL = 0.5
local PERF_TARGET = 500
local GREEN_COLUMNS_PER_PANE, GREEN_ROWS = 10, 8
local PADI_MAX_PART = 2.5
local FLAT_TOP_MAX = 1.5
local BAKED_PADI_ID = 13286158859

local function attr(instance, key)
	local ok, value = pcall(function()
		return instance:GetAttribute(key)
	end)
	return ok and value or nil
end

local function isRounded(part)
	local okWedge, wedge = pcall(function()
		return part:IsA("WedgePart")
	end)
	if okWedge and wedge then
		return true
	end
	local okPart, isPart = pcall(function()
		return part:IsA("Part")
	end)
	if not okPart or not isPart then
		return false
	end
	local okShape, shape = pcall(function()
		return part.Shape
	end)
	return okShape and shape == Enum.PartType.Cylinder
end

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
		p.IgnoreWater = false
		return p
	end)
	if not okParams then
		return nil
	end
	local okRay, hit = pcall(function()
		return workspace:Raycast(Vector3.new(x, 256, z), Vector3.new(0, -512, 0), params)
	end)
	if okRay and hit and hit.Instance == terrain then
		return hit.Position.Y
	end
	return nil
end

local function asVector3(value)
	if
		type(value) == "table"
		and type(value[1]) == "number"
		and type(value[2]) == "number"
		and type(value[3]) == "number"
	then
		return Vector3.new(value[1], value[2], value[3])
	end
	if typeof(value) == "Vector3" then
		return value
	end
	return nil
end

local function centreOf(inst)
	local ok, cf = pcall(function()
		return inst.CFrame
	end)
	return ok and cf and cf.Position or nil
end

local review = nil
local ok, err = pcall(function()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	review = require(shared:WaitForChild("LookDevReview"))
	local data = require(shared:WaitForChild("ModelMapSawahR8"))
	local okSpec, MapSpec = pcall(function()
		return require(game:GetService("ServerScriptService").Server.World.MapSpec)
	end)
	if not okSpec or type(MapSpec) ~= "table" then
		error("MapSpec not readable")
	end

	local enabled, why = review.enableAdditive("sawah_r8", game)
	if not enabled then
		error("enableAdditive(sawah_r8) failed: " .. tostring(why))
	end
	local folder = workspace:FindFirstChild(data.folderName)
	if not folder then
		error("staging folder missing: " .. tostring(data.folderName))
	end

	local idAttr = type(data.PADI_ASSET_ID_ATTRIBUTE) == "string" and data.PADI_ASSET_ID_ATTRIBUTE or "PadiAssetId"
	local stageAttr = type(data.PADI_STAGE_ATTRIBUTE) == "string" and data.PADI_STAGE_ATTRIBUTE or "GrowthStage"

	local bunds, padiParts, allParts = {}, {}, {}
	for _, instance in ipairs(folder:GetDescendants()) do
		local okPart, isPart = pcall(function()
			return instance:IsA("BasePart")
		end)
		if okPart and isPart then
			allParts[#allParts + 1] = instance
			if attr(instance, "Bund") == true then
				bunds[#bunds + 1] = instance
			end
			if attr(instance, "PadiPart") == true then
				padiParts[#padiParts + 1] = instance
			end
		end
	end

	-- PADI_IS_MODEL -----------------------------------------------------------
	local bakedRoot = game:GetService("ServerStorage"):FindFirstChild("LookDevAssets")
	local baked = bakedRoot and bakedRoot:FindFirstChild(tostring(BAKED_PADI_ID))
	local modelPadi, wrongId = 0, 0
	for _, part in ipairs(padiParts) do
		local okMesh, isMesh = pcall(function()
			return part:IsA("MeshPart")
		end)
		if okMesh and isMesh then
			if attr(part, idAttr) == BAKED_PADI_ID then
				modelPadi += 1
			else
				wrongId += 1
			end
		end
	end
	emit("PADI_IS_MODEL", baked ~= nil and modelPadi > 0, modelPadi, 1, {
		stagedPadiParts = #padiParts,
		bakedFolderPresent = baked ~= nil,
		wrongIdMeshParts = wrongId,
		method = "MeshPart PadiPart with PadiAssetId == 13286158859 and baked folder present",
	})

	-- PADI_STAGES -------------------------------------------------------------
	local stageSeen, stageCount = {}, 0
	for _, part in ipairs(padiParts) do
		local stage = attr(part, stageAttr)
		if type(stage) == "number" and not stageSeen[stage] then
			stageSeen[stage] = true
			stageCount += 1
		end
	end
	emit("PADI_STAGES", stageCount >= STAGES_MIN, stageCount, STAGES_MIN, {
		padiParts = #padiParts,
		method = "distinct numeric GrowthStage values across staged PadiPart parts",
	})

	-- PADI_ROWS ---------------------------------------------------------------
	local rowsByTerrace = {}
	for _, part in ipairs(padiParts) do
		local terrace, row = attr(part, "TerraceIndex"), attr(part, "PadiRow")
		if type(terrace) == "number" and type(row) == "number" then
			rowsByTerrace[terrace] = rowsByTerrace[terrace] or {}
			rowsByTerrace[terrace][row] = true
		end
	end
	local rowCounts, minRows = {}, math.huge
	for terrace = 1, #data.TERRACE_TOPS do
		local count = 0
		for _ in pairs(rowsByTerrace[terrace] or {}) do
			count += 1
		end
		rowCounts[terrace] = count
		minRows = math.min(minRows, count)
	end
	if minRows == math.huge then
		minRows = 0
	end
	emit("PADI_ROWS", minRows >= PADI_ROWS_MIN, minRows, PADI_ROWS_MIN, {
		perTerrace = rowCounts,
		padiParts = #padiParts,
		method = "MINIMUM distinct numeric PadiRow ids per terrace on PadiPart parts",
	})

	-- BUND_SHAPE --------------------------------------------------------------
	local badShape, flatTops = {}, {}
	for _, bund in ipairs(bunds) do
		local okSize, size = pcall(function()
			return bund.Size
		end)
		local width = (okSize and size) and math.max(size.X, size.Z) or math.huge
		if not isRounded(bund) then
			badShape[#badShape + 1] = tostring(bund.Name) .. ":flat-top=" .. tostring(width)
		end
		if width > FLAT_TOP_MAX then
			flatTops[#flatTops + 1] = tostring(bund.Name)
		end
	end
	local shapeBad = #badShape
	if #bunds == 0 then
		shapeBad = 1
	end
	emit("BUND_SHAPE", #bunds > 0 and shapeBad == 0, shapeBad, 0, {
		bundsChecked = #bunds,
		flatTops = flatTops,
		failures = badShape,
		method = "Bund parts must be WedgePart or Shape=Cylinder; plain Blocks with >1.5-stud tops fail",
	})

	-- SAWAH_GREEN -------------------------------------------------------------
	local greenEye, greenReason = nil, nil
	local okCams, Cameras = pcall(function()
		return require(shared:WaitForChild("ReviewCameras"))
	end)
	if not okCams or type(Cameras) ~= "table" or type(Cameras.all) ~= "function" then
		greenReason = "ReviewCameras not readable"
	else
		for _, camera in ipairs(Cameras.all()) do
			if camera.name == "sawah_above" then
				greenEye = asVector3(camera.position)
				break
			end
		end
		if not greenEye then
			greenReason = "sawah_above camera missing or bad coords"
		end
	end
	local panes = nil
	local okPanes, paneValue = pcall(function()
		return MapSpec.paddyWater()
	end)
	if okPanes and type(paneValue) == "table" and #paneValue >= #data.TERRACE_TOPS * 2 then
		panes = paneValue
	else
		greenReason = greenReason or "paddyWater panes not readable"
	end
	local greenPcts, greenHits, greenSamples, greenErrors = {}, {}, {}, 0
	if greenEye and panes and #padiParts > 0 then
		local okParams, params = pcall(function()
			local p = RaycastParams.new()
			p.FilterType = Enum.RaycastFilterType.Include
			p.FilterDescendantsInstances = { folder }
			p.IgnoreWater = false
			return p
		end)
		if not okParams or not params then
			greenReason = "RaycastParams unavailable"
		else
			for terrace = 1, #data.TERRACE_TOPS do
				local pair = { panes[(terrace - 1) * 2 + 1], panes[terrace * 2] }
				local hits, samples = 0, 0
				for _, pane in ipairs(pair) do
					if
						type(pane) == "table"
						and type(pane.centre) == "table"
						and type(pane.size) == "table"
						and type(pane.top) == "number"
					then
						local x0 = pane.centre[1] - pane.size[1] / 2
						local z0 = pane.centre[3] - pane.size[3] / 2
						for column = 1, GREEN_COLUMNS_PER_PANE do
							local x = x0 + (column - 0.5) * pane.size[1] / GREEN_COLUMNS_PER_PANE
							for row = 1, GREEN_ROWS do
								local z = z0 + (row - 0.5) * pane.size[3] / GREEN_ROWS
								local sample = Vector3.new(x, pane.top + 0.2, z)
								local delta = sample - greenEye
								samples += 1
								local okRay, hit = pcall(function()
									return workspace:Raycast(greenEye, delta.Unit * (delta.Magnitude + 2), params)
								end)
								if not okRay then
									greenErrors += 1
								elseif hit and hit.Instance and attr(hit.Instance, "PadiPart") == true then
									hits += 1
								end
							end
						end
					end
				end
				greenHits[terrace] = hits
				greenSamples[terrace] = samples
				greenPcts[terrace] = samples > 0 and math.floor(hits * 100 / samples) or 0
			end
		end
	end
	local minGreen = math.huge
	for terrace = 1, #data.TERRACE_TOPS do
		minGreen = math.min(minGreen, greenPcts[terrace] or 0)
	end
	if minGreen == math.huge then
		minGreen = 0
	end
	emit("SAWAH_GREEN", greenReason == nil and minGreen >= GREEN_MIN, minGreen, GREEN_MIN, {
		perTerracePct = greenPcts,
		hits = greenHits,
		samples = greenSamples,
		rayErrors = greenErrors,
		reason = greenReason,
		method = "MINIMUM per-terrace pct of 20x8 above-view rays whose first hit is a PadiPart",
	})

	-- SAWAH_TOPS (terrain-only regression) -------------------------------------
	local topWorst, topFailed, topSamples = 0, {}, 0
	local terraces = MapSpec.TERRACES
	for index, pane in ipairs(panes or {}) do
		topSamples += 1
		local terrace = terraces and terraces[math.floor((index - 1) / 2) + 1] or nil
		local x = type(pane) == "table" and type(pane.centre) == "table" and pane.centre[1] or nil
		local z = type(pane) == "table" and type(pane.centre) == "table" and pane.centre[3] or nil
		if type(x) ~= "number" or type(z) ~= "number" or type(terrace) ~= "table" or type(terrace.top) ~= "number" then
			topFailed[#topFailed + 1] = "pane:" .. index .. ":bad-spec"
			topWorst = 999
		else
			local y = terrainSurfaceY(x, z)
			if type(y) ~= "number" then
				topFailed[#topFailed + 1] = "pane:" .. index .. ":no-terrain-read"
				topWorst = 999
			else
				local diff = math.abs(y - terrace.top)
				topWorst = math.max(topWorst, diff)
				if diff > SAWAH_TOP_TOL then
					topFailed[#topFailed + 1] =
						string.format("pane:%d:y=%.2f want=%.2f d=%.2f", index, y, terrace.top, diff)
				end
			end
		end
	end
	emit(
		"SAWAH_TOPS",
		topSamples == #data.TERRACE_TOPS * 2 and #topFailed == 0,
		math.floor(topWorst * 100) / 100,
		SAWAH_TOP_TOL,
		{ samples = topSamples, terrainOnly = true, failed = topFailed }
	)

	-- PERF_BUDGET (near-origin BasePart census regression) ---------------------
	local perfParts, perfReadErrors = 0, 0
	local okScene, scene = pcall(function()
		return workspace:GetDescendants()
	end)
	if not okScene or type(scene) ~= "table" then
		perfReadErrors += 1
		scene = {}
	end
	for _, inst in ipairs(scene) do
		local okPart, isPart = pcall(function()
			return inst:IsA("BasePart")
		end)
		if not okPart then
			perfReadErrors += 1
		elseif isPart then
			local centre = centreOf(inst)
			if centre then
				if centre.X * centre.X + centre.Y * centre.Y + centre.Z * centre.Z <= 100 * 100 then
					perfParts += 1
				end
			else
				perfReadErrors += 1
			end
		end
	end
	emit("PERF_BUDGET", perfReadErrors == 0 and perfParts <= PERF_TARGET, perfParts, PERF_TARGET, {
		proxy = "BaseParts within 100 studs of (0,0,0)",
		readErrors = perfReadErrors,
	})
end)

-- Restore every additively staged candidate even when a measurement threw.
pcall(function()
	if review then
		review.disableAll()
	else
		require(game:GetService("ReplicatedStorage"):WaitForChild("Shared").LookDevReview).disableAll()
	end
end)

if not ok then
	local reason = { reason = "audit error: " .. tostring(err) }
	emit("PADI_IS_MODEL", false, 0, 1, reason)
	emit("PADI_STAGES", false, 0, STAGES_MIN, reason)
	emit("PADI_ROWS", false, 0, PADI_ROWS_MIN, reason)
	emit("BUND_SHAPE", false, 1, 0, reason)
	emit("SAWAH_GREEN", false, 0, GREEN_MIN, reason)
	emit("SAWAH_TOPS", false, 999, SAWAH_TOP_TOL, reason)
	emit("PERF_BUDGET", false, 0, PERF_TARGET, reason)
end

return results
