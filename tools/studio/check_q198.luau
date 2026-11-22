--!nocheck
-- check_q198: WORK_QUEUE item 198, self-contained SERVER-VM Studio check. Paste this whole file
-- into execute_luau in a fresh Play session. It measures the live DataModel BEFORE and AFTER
-- staging mountains_r10 with enableAdditive, prints verbatim CHECK lines, then restores with
-- disableAll() in the same call. No harness require, no place save, no visual verdict.
--
--   MOUNTAINS     >=3 live Parts tagged Mountain==true
--   MOUNTAIN_FAR  0 tagged Parts within 450 studs of origin (X/Z radius)
--   NO_COLLISION  0 tagged Parts with CanCollide==true
--   PERF_BUDGET   0 read errors and <=500 BasePart centres inside the 100-stud proxy radius
--
-- CALIBRATION ANCHORS: `local before = measure()` and `local after = measure()` are separate single
-- lines so a mismatch can be injected between them. Destroying a mountain before AFTER =>
-- MOUNTAINS drops; moving one to origin => MOUNTAIN_FAR FAIL; setting CanCollide=true =>
-- NO_COLLISION FAIL.

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

local CHECK_NAMES = { "MOUNTAINS", "MOUNTAIN_FAR", "NO_COLLISION", "PERF_BUDGET" }
local CANDIDATE_ID = "mountains_r10"
local FAR_LIMIT = 450

local review, Data, Failures = nil, nil, nil

-- Every reading comes from the live DataModel, never from the pure data alone.
local function measure()
	local mountains, near, colliding = 0, 0, 0
	local perfParts, perfErrors = 0, 0
	local radiusSq = Data.PERF_RADIUS * Data.PERF_RADIUS
	local farSq = FAR_LIMIT * FAR_LIMIT

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
						local okTag, tagged = pcall(function()
							return instance:GetAttribute("Mountain") == true
						end)
						if okTag and tagged then
							mountains += 1
							if x * x + z * z < farSq then
								near += 1
							end
							local okCollision, collision = pcall(function()
								return instance.CanCollide
							end)
							if not okCollision then
								perfErrors += 1
							elseif collision == true then
								colliding += 1
							end
						end
					else
						perfErrors += 1
					end
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
		mountains = mountains,
		near = near,
		colliding = colliding,
		perfParts = perfParts,
		perfErrors = perfErrors,
		loadFailures = loadFailures,
	}
end

local ok, err = pcall(function()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	review = require(shared:WaitForChild("LookDevReview"))
	Data = require(shared:WaitForChild("ModelMapMountainsR10"))
	Failures = require(shared:WaitForChild("LookDevFailures"))

	if type(Data) ~= "table" or type(Data.mountainParts) ~= "function" then
		error("ModelMapMountainsR10 API missing")
	end

	-- CALIBRATION ANCHOR (BEFORE). A mismatch can be injected between the two measure calls.
	local before = measure()

	local enableOk, enabled, why = pcall(review.enableAdditive, CANDIDATE_ID, game)
	local enableReason = nil
	if not enableOk or not enabled then
		enableReason = "enableAdditive failed: " .. tostring(why)
	end

	local after = measure()

	local mountainDetail = {
		["before.mountains"] = before.mountains,
		afterMountains = after.mountains,
		farLimit = FAR_LIMIT,
		loadFailures = after.loadFailures,
		reason = enableReason,
	}
	emit("MOUNTAINS", after.mountains >= 3, after.mountains, 3, mountainDetail)

	local farDetail = {
		["before.near"] = before.near,
		afterNear = after.near,
		farLimit = FAR_LIMIT,
		loadFailures = after.loadFailures,
		reason = enableReason,
	}
	emit("MOUNTAIN_FAR", after.near == 0, after.near, 0, farDetail)

	local collisionDetail = {
		["before.colliding"] = before.colliding,
		afterColliding = after.colliding,
		loadFailures = after.loadFailures,
		reason = enableReason,
	}
	emit("NO_COLLISION", after.colliding == 0, after.colliding, 0, collisionDetail)

	local perfDetail = {
		proxy = "BasePart centre within PERF_RADIUS (100) studs of origin",
		readErrors = after.perfErrors,
		beforeParts = before.perfParts,
		loadFailures = after.loadFailures,
		reason = enableReason,
	}
	local perfPass = after.perfErrors == 0 and after.perfParts <= Data.PERF_TARGET
	emit("PERF_BUDGET", perfPass, after.perfParts, Data.PERF_TARGET, perfDetail)
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
		local target = if name == "MOUNTAINS" then 3 elseif name == "PERF_BUDGET" then 500 else 0
		emitOnce(name, false, 0, target, reason)
	end
end

return results
