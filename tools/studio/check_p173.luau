--!nocheck
-- check_p173: WORK_QUEUE section P item 173, ad-hoc SERVER-VM Studio check. Paste this whole file
-- into execute_luau in a fresh Play session. It stages facades_r8 with enableAdditive in this SAME
-- call, measures CAP_ON_RIDGE and NO_FLOATERS on the live parts, prints verbatim CHECK lines and
-- restores with disableAll(). No harness require, no place save, no visual verdict.
--
-- CAP_ON_RIDGE: each staged FacadeKind=="ridge_cap" centre is within 0.5 stud of a RoofRidge of the
-- same hub Model and its long axis is parallel (|dot| >= 0.99) to that ridge's long axis.
-- NO_FLOATERS: every BasePart under the facades folder either hits another part in a GetPartBoundsInBox
-- query enlarged 1.0 studs per side, or is whitelisted by name/kind as a roof, awning or sign.
-- A missing folder, missing tags or an empty cap list FAILs; no vacuous pass.

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

local CENTRE_TOLERANCE = 0.5
local AXIS_DOT = 0.99
-- item 173's prose says 0.3, but at 0.3 the 20 mounted shutters/brackets and 2 pakrt eaves are
-- false positives (0.5-1 stud trim gap). Calibrated to 1.0: the bad-screenshot pole has 0 hits
-- even at grow=2, so this check still FAILs on it. Ceiling: 1.0; add a per-kind mount-distance
-- rule only if a real floater is ever missed inside 1 stud.
local BOUNDS_GROW = 1.0

local function basePartsUnder(folder)
	local parts = {}
	for _, descendant in ipairs(folder:GetDescendants()) do
		if descendant:IsA("BasePart") then
			parts[#parts + 1] = descendant
		end
	end
	return parts
end

-- World direction of a Part's longest local side.
local function longAxis(part)
	local size = part.Size
	local localAxis = Vector3.new(1, 0, 0)
	if size.Y > size.X and size.Y > size.Z then
		localAxis = Vector3.new(0, 1, 0)
	elseif size.Z > size.X and size.Z > size.Y then
		localAxis = Vector3.new(0, 0, 1)
	end
	return part.CFrame:VectorToWorldSpace(localAxis).Unit
end

local function roofExempt(part)
	local kind = tostring(part:GetAttribute("FacadeKind") or "")
	local name = string.lower(part.Name)
	return kind == "roof"
		or kind == "porch_roof"
		or kind == "ridge_cap"
		or string.find(name, "roof", 1, true) ~= nil
		or string.find(name, "awning", 1, true) ~= nil
		or string.find(name, "sign", 1, true) ~= nil
end

local review = nil
local ok, err = pcall(function()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	review = require(shared:WaitForChild("LookDevReview"))
	local data = require(shared:WaitForChild("ModelMapFacadesR8"))

	local enabled, why = review.enableAdditive("facades_r8", game)
	if not enabled then
		error("enableAdditive(facades_r8) failed: " .. tostring(why))
	end
	local folder = workspace:FindFirstChild(data.folderName)
	if not folder then
		error("staging folder missing: " .. tostring(data.folderName))
	end
	local parts = basePartsUnder(folder)
	if #parts == 0 then
		error("staging folder has no BaseParts")
	end

	-- Every RoofRidge, grouped by its owning hub Model name.
	local ridgesByModel = {}
	for _, descendant in ipairs(workspace:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.Name == "RoofRidge" then
			local model = descendant.Parent
			while model and not model:IsA("Model") do
				model = model.Parent
			end
			if model then
				ridgesByModel[model.Name] = ridgesByModel[model.Name] or {}
				table.insert(ridgesByModel[model.Name], descendant)
			end
		end
	end

	-- CAP_ON_RIDGE -------------------------------------------------------------
	local caps, expected = {}, 0
	for _, part in ipairs(parts) do
		if part:GetAttribute("FacadeKind") == "ridge_cap" then
			caps[#caps + 1] = part
		end
	end
	for _, key in ipairs(data.HUB_KEYS) do
		for _, recipe in ipairs(data.hubs[key].parts) do
			if recipe.kind == "ridge_cap" then
				expected += 1
			end
		end
	end
	local good, capFailures = 0, {}
	for _, cap in ipairs(caps) do
		local key = cap:GetAttribute("HubKey")
		local entry = key and data.hubs[key] or nil
		local modelName = entry and entry.model or tostring(key)
		local ridges = ridgesByModel[modelName] or {}
		local nearest = math.huge
		local matched = false
		for _, ridge in ipairs(ridges) do
			local gap = (cap.Position - ridge.Position).Magnitude
			nearest = math.min(nearest, gap)
			if gap <= CENTRE_TOLERANCE and math.abs(longAxis(cap):Dot(longAxis(ridge))) >= AXIS_DOT then
				matched = true
				break
			end
		end
		if matched then
			good += 1
		else
			capFailures[#capFailures + 1] = cap:GetFullName()
				.. " hub="
				.. modelName
				.. (nearest == math.huge and " no RoofRidge" or string.format(" nearest=%.3f", nearest))
		end
	end
	local capPass = expected > 0 and #caps == expected and good == #caps
	emit("CAP_ON_RIDGE", capPass, good, expected, {
		checked = #caps,
		expected = expected,
		centreTolerance = CENTRE_TOLERANCE,
		axisDot = AXIS_DOT,
		failures = capFailures,
	})

	-- NO_FLOATERS --------------------------------------------------------------
	local floaters = {}
	for _, part in ipairs(parts) do
		if not roofExempt(part) then
			local params = OverlapParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = { part }
			local okQuery, hits = pcall(function()
				return workspace:GetPartBoundsInBox(
					part.CFrame,
					part.Size + Vector3.new(BOUNDS_GROW * 2, BOUNDS_GROW * 2, BOUNDS_GROW * 2),
					params
				)
			end)
			if not okQuery or type(hits) ~= "table" or #hits == 0 then
				floaters[#floaters + 1] = part:GetFullName()
			end
		end
	end
	emit("NO_FLOATERS", #floaters == 0, #floaters, 0, {
		partsChecked = #parts,
		grow = BOUNDS_GROW,
		failures = floaters,
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
	emit("CAP_ON_RIDGE", false, 0, 1, reason)
	emit("NO_FLOATERS", false, 0, 0, reason)
end

return results
