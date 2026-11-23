--!nocheck
-- check_q212: WORK_QUEUE item 212, self-contained SERVER-VM Studio check on the DEFAULT look.
-- IMPORTANT FOR THE MAIN SESSION: wire src/shared/ModelMapRiverFoamQ212.luau into
-- src/server/World/Greybox.luau (staged as anchored, non-collidable, non-interactive Block Parts
-- tagged RiverFoam=true) BEFORE running this check; with no live tagged parts FOAM_LINE FAILs.
-- Paste this whole file into execute_luau in a FRESH Play session. It stages nothing, calls no
-- LookDev API, reads only the live DataModel, prints the CHECK lines verbatim and restores every
-- temporary mutation before it returns. No harness require, no place save, no visual verdict.
--
--   FOAM_LINE  <fraction> 0.60  live visible RiverFoam parts cover >=60% of both bank edges by
--                                Sampling every 4 studs along x -400..400 (ModelMapRiverFoamQ212
--                                coverage()). Dividing the 800-stud bank by 16-stud segments gives
--                                100 descriptors (50 per bank); expected fraction 1.0000.
--   PERF_BUDGET <count>  120   live tagged RiverFoam BaseParts, expected 100 for the default line.
--
-- CALIBRATION ANCHORS: hide every other visible foam Part (exact Transparency save/restore) ->
-- CAL_FOAM_LINE_FAIL; inject enough tagged Parts to exceed PERF_BUDGET -> CAL_PERF_BUDGET_FAIL.
-- Every probe is destroyed and every saved property restored before return.

local CHECK_NAMES = {
	"FOAM_LINE",
	"PERF_BUDGET",
	"CAL_FOAM_LINE_FAIL",
	"CAL_PERF_BUDGET_FAIL",
}
local CHECK_TARGETS = {
	FOAM_LINE = "0.60",
	PERF_BUDGET = 120,
	CAL_FOAM_LINE_FAIL = 1,
	CAL_PERF_BUDGET_FAIL = 1,
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

local function positionOf(part)
	local ok, x, z = pcall(function()
		return part.Position.X, part.Position.Z
	end)
	if not ok then
		return nil, nil
	end
	return x, z
end

local function taggedFoam(tag)
	local out = {}
	for _, inst in ipairs(workspace:GetDescendants()) do
		pcall(function()
			if inst:IsA("BasePart") and attr(inst, tag) == true then
				out[#out + 1] = inst
			end
		end)
	end
	table.sort(out, function(a, b)
		return a.Name < b.Name
	end)
	return out
end

local function descriptors(parts, Foam)
	local out = {}
	for _, part in ipairs(parts) do
		if attr(part, Foam.TAG) == true and visible(part) then
			local x, z = positionOf(part)
			if x and z then
				out[#out + 1] = { x = x, z = z }
			end
		end
	end
	return out
end

local injected = {}
local function destroyInjected()
	for index = #injected, 1, -1 do
		pcall(function()
			injected[index]:Destroy()
		end)
		injected[index] = nil
	end
end

local ok, err = pcall(function()
	local Foam = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("ModelMapRiverFoamQ212"))
	if Foam.TAG ~= "RiverFoam" or type(Foam.coverage) ~= "function" then
		error("ModelMapRiverFoamQ212 contract missing")
	end

	local foam = taggedFoam(Foam.TAG)
	local live = descriptors(foam, Foam)
	local fraction, covered, total = Foam.coverage(live)
	print("FOAM_SAMPLES " .. covered .. "/" .. total .. " parts=" .. #foam .. " visible=" .. #live)
	emit(
		"FOAM_LINE",
		fraction >= Foam.MIN_COVERAGE and total > 0,
		string.format("%.4f", fraction),
		string.format("%.2f", Foam.MIN_COVERAGE),
		{ covered = covered, total = total, parts = #foam, visible = #live }
	)

	emit("PERF_BUDGET", #foam <= Foam.PERF_BUDGET, #foam, Foam.PERF_BUDGET, {
		tagged = #foam,
		proxy = "live workspace BaseParts tagged RiverFoam=true",
	})

	-- CAL_FOAM_LINE_FAIL: hide every other visible foam part, re-measure, restore exact Transparency.
	local saved = {}
	local hidden = 0
	local hideOk = pcall(function()
		for index, part in ipairs(foam) do
			if index % 2 == 0 and visible(part) then
				saved[part] = part.Transparency
				part.Transparency = 1
				hidden += 1
			end
		end
	end)
	local measuredOk, calFraction, calCovered = pcall(function()
		return Foam.coverage(descriptors(foam, Foam))
	end)
	for part, value in pairs(saved) do
		pcall(function()
			part.Transparency = value
		end)
	end
	local foamFailed = hideOk
		and measuredOk
		and hidden > 0
		and fraction >= Foam.MIN_COVERAGE
		and calFraction < Foam.MIN_COVERAGE
	emit("CAL_FOAM_LINE_FAIL", foamFailed, foamFailed and 1 or 0, 1, {
		hidden = hidden,
		fractionBefore = fraction,
		fractionHidden = if measuredOk then calFraction else -1,
		coveredHidden = if measuredOk then calCovered else -1,
	})

	-- CAL_PERF_BUDGET_FAIL: inject just enough tagged Parts to cross the budget, re-count, destroy.
	local needed = math.max(1, Foam.PERF_BUDGET - #foam + 1)
	local injectOk = pcall(function()
		for index = 1, needed do
			local probe = Instance.new("Part")
			probe.Name = "Q212_PERF_CALIBRATION_" .. index
			probe.Size = Vector3.new(1, 1, 1)
			probe.Position = Vector3.new(0, -100, 0)
			probe.Anchored = true
			probe.CanCollide = false
			probe.CastShadow = false
			probe:SetAttribute(Foam.TAG, true)
			probe:SetAttribute(Foam.KIND_ATTR, Foam.KIND)
			probe.Parent = workspace
			injected[#injected + 1] = probe
		end
	end)
	local calCount = injectOk and #taggedFoam(Foam.TAG) or -1
	local perfFailed = injectOk and #foam <= Foam.PERF_BUDGET and calCount > Foam.PERF_BUDGET
	emit("CAL_PERF_BUDGET_FAIL", perfFailed, perfFailed and 1 or 0, 1, {
		before = #foam,
		injected = needed,
		after = calCount,
		budget = Foam.PERF_BUDGET,
	})
	destroyInjected()
end)

-- Only the hidden Transparency and the injected probes are temporary; both are restored inside the
-- pcall above. destroyInjected() is the belt-and-braces path on error.
destroyInjected()

if not ok then
	local reason = { reason = "item 212 audit error: " .. tostring(err) }
	for _, name in ipairs(CHECK_NAMES) do
		emitOnce(name, false, 0, CHECK_TARGETS[name], reason)
	end
end

return results
