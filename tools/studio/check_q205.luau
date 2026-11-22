--!nocheck
-- check_q205: WORK_QUEUE item 205, self-contained SERVER-VM Studio check. Paste this whole file
-- into execute_luau in a fresh Play session. It measures the live DataModel BEFORE and AFTER
-- staging furrows_r10 with enableAdditive, prints verbatim CHECK lines, then restores with
-- disableAll() in the same call. No harness require, no place save, no visual verdict.
--
--   FURROWS                   minimum live Furrow-tagged strip count across the 10 plots (>=4)
--   FURROW_VISIBLE            number of plot_aerial_NN eyes with >=1 Furrow part within 60 studs
--   CROP_PLACEMENT_UNCHANGED  >0 live Furrow parts staged AND crop-stage Part/Model delta inside the plot area (0)
--
-- CALIBRATION ANCHORS: `local before = measure()` and `local after = measure()` are separate single
-- lines so a mismatch can be injected between them. Destroy one strip before AFTER => FURROWS min
-- drops; move every strip >60 studs from one plot_aerial eye => FURROW_VISIBLE drops; spawn a
-- CropId-tagged Model inside a plot before AFTER => CROP_PLACEMENT_UNCHANGED FAIL; staging failure with
-- zero Furrow parts also FAILS (no vacuous pass).

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

local CHECK_NAMES = { "FURROWS", "FURROW_VISIBLE", "CROP_PLACEMENT_UNCHANGED" }
local CANDIDATE_ID = "furrows_r10"
local MIN_STRIPS = 4
local VISIBLE_RADIUS = 60
local PLOT_AREA_RADIUS = 34

local review, Data, Cameras, Failures = nil, nil, nil, nil

local function plotCentres()
	local sums, counts = {}, {}
	for _, descriptor in ipairs(Data.parts()) do
		local plot = descriptor.plot
		sums[plot] = sums[plot] or { x = 0, z = 0 }
		counts[plot] = (counts[plot] or 0) + 1
		sums[plot].x += descriptor.position[1]
		sums[plot].z += descriptor.position[3]
	end
	local centres = {}
	for plot, sum in pairs(sums) do
		centres[plot] = { x = sum.x / counts[plot], z = sum.z / counts[plot] }
	end
	return centres
end

-- Every reading comes from the live DataModel, never from the pure data alone.
local function measure()
	local perPlot, furrowParts = {}, {}
	local centres = plotCentres()
	local crops = 0

	local okDescendants, descendants = pcall(function()
		return workspace:GetDescendants()
	end)
	if okDescendants and type(descendants) == "table" then
		for _, instance in ipairs(descendants) do
			-- One GUI object with a UDim2 Position must never throw out of measure(): every read,
			-- including .X/.Y/.Z, stays inside this per-instance pcall and is skipped on error.
			pcall(function()
				local okPosition, position = pcall(function()
					return instance.CFrame.Position
				end)
				if not okPosition or not position then
					okPosition, position = pcall(function()
						return instance.Position
					end)
				end
				if not okPosition or not position then
					return
				end
				local okComponents, x, y, z = pcall(function()
					return position.X, position.Y, position.Z
				end)
				if not okComponents then
					return
				end
				if type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number" then
					return
				end

				local okTag, tagged = pcall(function()
					return instance:GetAttribute("Furrow") == true
				end)
				if okTag and tagged then
					local okPlot, plot = pcall(function()
						return instance:GetAttribute("plot")
					end)
					if okPlot and type(plot) == "number" then
						perPlot[plot] = (perPlot[plot] or 0) + 1
					end
					furrowParts[#furrowParts + 1] = { x = x, y = y, z = z, plot = plot }
				end

				local okClass, isCrop = pcall(function()
					local isPartOrModel = instance:IsA("BasePart") or instance:IsA("Model")
					if not isPartOrModel then
						return false
					end
					if
						instance:GetAttribute("CropId") ~= nil
						or instance:GetAttribute("Crop") ~= nil
						or instance:GetAttribute("Stage") ~= nil
						or string.find(string.lower(instance.Name), "crop", 1, true)
					then
						return true
					end
					return false
				end)
				if okClass and isCrop then
					for _, centre in pairs(centres) do
						local dx, dz = x - centre.x, z - centre.z
						if dx * dx + dz * dz <= PLOT_AREA_RADIUS * PLOT_AREA_RADIUS then
							crops += 1
							break
						end
					end
				end
			end)
		end
	end

	local minStrips = math.huge
	for plot = 1, Data.PLOT_COUNT do
		minStrips = math.min(minStrips, perPlot[plot] or 0)
	end
	if minStrips == math.huge then
		minStrips = 0
	end

	local visible, perCamera = 0, {}
	local radiusSq = VISIBLE_RADIUS * VISIBLE_RADIUS
	for _, name in ipairs(Data.CAMERA_NAMES) do
		perCamera[name] = 0
		local okCamera, camera = pcall(Cameras.get, name)
		if okCamera and camera and type(camera.position) == "table" then
			local eye = camera.position
			local ex, ey, ez = tonumber(eye[1]), tonumber(eye[2]), tonumber(eye[3])
			if ex and ey and ez then
				for _, strip in ipairs(furrowParts) do
					local dx, dy, dz = strip.x - ex, strip.y - ey, strip.z - ez
					if dx * dx + dy * dy + dz * dz <= radiusSq then
						perCamera[name] += 1
					end
				end
				if perCamera[name] >= 1 then
					visible += 1
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
		furrows = minStrips,
		perPlot = perPlot,
		visible = visible,
		perCamera = perCamera,
		strips = #furrowParts,
		crops = crops,
		loadFailures = loadFailures,
	}
end

local ok, err = pcall(function()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	review = require(shared:WaitForChild("LookDevReview"))
	Cameras = require(shared:WaitForChild("ReviewCameras"))
	Data = require(shared:WaitForChild("ModelMapFurrowsR10"))
	Failures = require(shared:WaitForChild("LookDevFailures"))

	if type(Data) ~= "table" or type(Data.parts) ~= "function" then
		error("ModelMapFurrowsR10 API missing")
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

	local furrowDetail = {
		["before.furrows"] = before.furrows,
		afterFurrows = after.furrows,
		perPlot = after.perPlot,
		stagedStrips = after.strips,
		loadFailures = after.loadFailures,
		reason = enableReason,
	}
	emit("FURROWS", after.furrows >= MIN_STRIPS, after.furrows, MIN_STRIPS, furrowDetail)

	local visibleDetail = {
		["before.visible"] = before.visible,
		afterVisible = after.visible,
		perCamera = after.perCamera,
		radius = VISIBLE_RADIUS,
		cameras = Data.CAMERA_NAMES,
		loadFailures = after.loadFailures,
		reason = enableReason,
	}
	emit("FURROW_VISIBLE", after.visible == #Data.CAMERA_NAMES, after.visible, #Data.CAMERA_NAMES, visibleDetail)

	local cropDelta = after.crops - before.crops
	local cropDetail = {
		beforeCrops = before.crops,
		afterCrops = after.crops,
		stagedFurrowParts = after.strips,
		plotAreaRadius = PLOT_AREA_RADIUS,
		loadFailures = after.loadFailures,
		reason = enableReason,
	}
	emit("CROP_PLACEMENT_UNCHANGED", after.strips > 0 and cropDelta == 0, cropDelta, 0, cropDetail)
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
	local cameraTarget = Data and type(Data.CAMERA_NAMES) == "table" and #Data.CAMERA_NAMES or 10
	for _, name in ipairs(CHECK_NAMES) do
		local target = if name == "FURROWS" then MIN_STRIPS elseif name == "FURROW_VISIBLE" then cameraTarget else 0
		emitOnce(name, false, 0, target, reason)
	end
end

return results
