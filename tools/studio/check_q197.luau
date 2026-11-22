--!nocheck
-- check_q197: WORK_QUEUE section Q item 197 lane 1, self-contained SERVER-VM Studio check. Paste
-- this whole file into execute_luau in a fresh Play session. It measures the live place BEFORE and
-- AFTER staging horizon_fill_r10 with enableAdditive, prints verbatim CHECK lines, then restores
-- with disableAll() in the same call. No harness require, no place save, no visual verdict.
--
--   HORIZON_FILL  15/15 downward rays from the five horizon samples of each of the three review
--                 cameras first-hit Terrain or a part tagged HorizonSkirt
--   PERF_BUDGET   0 read errors and <=500 BasePart centres inside the 100-stud proxy radius
--   HAZE_MATCH    Atmosphere.Haze within 0.001 and each Color channel within 0.5/255 of the data
--
-- CALIBRATION ANCHORS: `local before = measure()` and `local after = measure()` are separate single
-- lines so a before/after mismatch can be injected between them.

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

local CHECK_NAMES = { "HORIZON_FILL", "PERF_BUDGET", "HAZE_MATCH" }
local CANDIDATE_ID = "horizon_fill_r10"
local RAY_ORIGIN_Y, RAY_LENGTH = 256, 512
local TOTAL_RAYS = 15

local review, Data, Cameras, Failures = nil, nil, nil, nil

-- Every reading comes from the live DataModel, never from the pure data alone.
local function measure()
	local perCamera, hits = {}, 0

	local okParams, params = pcall(function()
		local q = RaycastParams.new()
		q.IgnoreWater = false
		return q
	end)

	for _, name in ipairs(Data.CAMERA_NAMES) do
		perCamera[name] = 0
		local okCamera, camera = pcall(Cameras.get, name)
		if okParams and okCamera and camera then
			local position, lookAt = camera.position, camera.lookAt
			if type(position) == "table" and type(lookAt) == "table" then
				local okPoints, points = pcall(Data.horizonPoints, position, lookAt)
				if okPoints and type(points) == "table" then
					for _, point in ipairs(points) do
						local okRay, hit = pcall(function()
							local origin = Vector3.new(point.x, RAY_ORIGIN_Y, point.z)
							return workspace:Raycast(origin, Vector3.new(0, -RAY_LENGTH, 0), params)
						end)
						if okRay and hit then
							local instance = hit.Instance
							if instance then
								local okTerrain, isTerrain = pcall(function()
									return instance:IsA("Terrain")
								end)
								local okTag, tagged = pcall(function()
									return instance:GetAttribute("HorizonSkirt") == true
								end)
								if (okTerrain and isTerrain) or (okTag and tagged) then
									hits += 1
									perCamera[name] += 1
								end
							end
						end
					end
				end
			end
		end
	end

	-- PERF proxy: the 100-stud census from check_p182.luau, applied to BasePart centres.
	local perfParts, perfErrors = 0, 0
	local radiusSq = Data.PERF_RADIUS * Data.PERF_RADIUS
	local okDescendants, descendants = pcall(function()
		return workspace:GetDescendants()
	end)
	if not okDescendants or type(descendants) ~= "table" then
		perfErrors += 1
	else
		for _, instance in ipairs(descendants) do
			local okBase, isBase = pcall(function()
				return instance:IsA("BasePart")
			end)
			if okBase and isBase then
				local okPosition, position = pcall(function()
					return instance.CFrame.Position
				end)
				if not okPosition or not position then
					okPosition, position = pcall(function()
						return instance.Position
					end)
				end
				if not okPosition or not position then
					perfErrors += 1
				else
					local x, y, z = position.X, position.Y, position.Z
					if type(x) == "number" and type(y) == "number" and type(z) == "number" then
						if x * x + y * y + z * z <= radiusSq then
							perfParts += 1
						end
					else
						perfErrors += 1
					end
				end
			end
		end
	end

	-- Atmosphere reading: keep numbers only; Color3 channels are converted to 0..255.
	local haze, color = nil, nil
	local okLighting, lighting = pcall(function()
		return game:GetService("Lighting")
	end)
	if okLighting and lighting then
		local okAtmosphere, atmosphere = pcall(function()
			return lighting:FindFirstChildOfClass("Atmosphere")
		end)
		if okAtmosphere and atmosphere then
			local okHaze, hazeValue = pcall(function()
				return atmosphere.Haze
			end)
			if okHaze and type(hazeValue) == "number" then
				haze = hazeValue
			end
			local okColor, color3 = pcall(function()
				return atmosphere.Color
			end)
			if okColor and color3 then
				local okRgb, r, g, b = pcall(function()
					return color3.R * 255, color3.G * 255, color3.B * 255
				end)
				if okRgb and type(r) == "number" and type(g) == "number" and type(b) == "number" then
					color = { r = r, g = g, b = b }
				end
			end
		end
	end

	local loadFailures = 0
	if Failures and type(Failures.get) == "function" then
		local okFailures, count = pcall(Failures.get, CANDIDATE_ID)
		if okFailures and type(count) == "number" then
			loadFailures = count
		end
	end

	return {
		hits = hits,
		perCamera = perCamera,
		perfParts = perfParts,
		perfErrors = perfErrors,
		haze = haze,
		color = color,
		-- Aliases for the pre-stage reading name used by the calibration anchors.
		beforeHaze = haze,
		beforeColor = color,
		loadFailures = loadFailures,
	}
end

local ok, err = pcall(function()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	review = require(shared:WaitForChild("LookDevReview"))
	Cameras = require(shared:WaitForChild("ReviewCameras"))
	Data = require(shared:WaitForChild("ModelMapHorizonFillR10"))
	Failures = require(shared:WaitForChild("LookDevFailures"))

	if type(Data) ~= "table" or type(Data.horizonPoints) ~= "function" then
		error("ModelMapHorizonFillR10 API missing")
	end
	if type(Cameras) ~= "table" or type(Cameras.get) ~= "function" then
		error("ReviewCameras.get API missing")
	end

	-- CALIBRATION ANCHOR (BEFORE). A mismatch can be injected between the two measure calls.
	local before = measure()

	local enableOk, enabled, why = pcall(review.enableAdditive, CANDIDATE_ID, game)
	local enableReason = nil
	if not enableOk or not enabled then
		enableReason = "enableAdditive failed: " .. tostring(why)
	end

	local after = measure()

	local fillDetail = {
		["before.hits"] = before.hits,
		afterHits = after.hits,
		perCamera = after.perCamera,
		rays = TOTAL_RAYS,
		loadFailures = after.loadFailures,
		reason = enableReason,
	}
	emit("HORIZON_FILL", after.hits == TOTAL_RAYS, after.hits, TOTAL_RAYS, fillDetail)

	local perfDetail = {
		proxy = "BasePart centre within PERF_RADIUS (100) studs of origin",
		readErrors = after.perfErrors,
		beforeParts = before.perfParts,
		loadFailures = after.loadFailures,
		reason = enableReason,
	}
	local perfPass = after.perfErrors == 0 and after.perfParts <= Data.PERF_TARGET
	emit("PERF_BUDGET", perfPass, after.perfParts, Data.PERF_TARGET, perfDetail)

	local hazeMatch = false
	if after.haze and after.color then
		local hazeOk = math.abs(after.haze - Data.HAZE) < 0.001
		local colorOk = true
		for _, channel in ipairs({ "r", "g", "b" }) do
			if math.abs(after.color[channel] - Data.HAZE_COLOR[channel]) > 0.5 then
				colorOk = false
			end
		end
		hazeMatch = hazeOk and colorOk
	end
	local hazeDetail = {
		beforeHaze = before.haze,
		beforeColor = before.color,
		afterHaze = after.haze,
		afterColor = after.color,
		targetHaze = Data.HAZE,
		targetColor = Data.HAZE_COLOR,
	}
	emit("HAZE_MATCH", hazeMatch, hazeMatch and 1 or 0, 1, hazeDetail)
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
	for _, name in ipairs(CHECK_NAMES) do
		local target = if name == "PERF_BUDGET" then 500 elseif name == "HAZE_MATCH" then 1 else TOTAL_RAYS
		emitOnce(name, false, 0, target, reason)
	end
end

return results
