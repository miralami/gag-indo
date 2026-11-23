--!nocheck
-- check_q219: WORK_QUEUE item 219, CHUNKED resumable SERVER-VM Studio harness module. require this
-- module in a Play session via execute_luau, call M.init(), call M.chunk(from, to) repeatedly
-- (1-based inclusive; module-level state persists via the require cache across execute_luau calls),
-- then M.finish(). The main session owns evidence, the place and the commit.
-- For every Shared.LookDev.IDS entry it stages with
-- LookDevReview.enableAdditive(id, game) (enable() fallback), snapshots Workspace + Lighting
-- descendant signatures, unstages with disableAll(), snapshots again, and prints verbatim CHECK
-- lines. Client-only ids whose SERVER VM staging fails are reported by LOOKDEV_CLIENT_SKIP and get
-- no per-id PASS line: no sweep, no claim. Any prior active candidate is restored by M.finish().
-- No harness require, no place save, no visual verdict. No task.wait: chunking is across calls.
--
--   LOOKDEV_LEAK                   0 signature deltas over all swept ids (aggregate)
--   LOOKDEV_LEAK_<UPPER_ID>        0 signature deltas for one swept id
--   LOOKDEV_IDS_SWEPT              #LookDev.IDS - #client skips, actually staged and unstaged
--   LOOKDEV_CLIENT_SKIP            client ids the SERVER VM could not stage (declared separately)
--   CAL_LOOKDEV_LEAK_FAIL          inject one tagged leftover part before unstage -> delta > 0 -> 1 1
--
-- Signature = ClassName + GetFullName() of every Workspace/Lighting descendant, with duplicate
-- counts. A candidate that stages then restores correctly leaves the exact same multiset. The
-- calibration anchor proves the delta detector is not vacuous. All injections are destroyed and
-- the prior active candidate is re-enabled on every path, including an exception.

local CHECK_NAMES = {
	"LOOKDEV_LEAK",
	"LOOKDEV_IDS_SWEPT",
	"LOOKDEV_CLIENT_SKIP",
	"CAL_LOOKDEV_LEAK_FAIL",
}

local M = {}

local results = { checks = {}, byName = {}, checkNames = {} }
local review, LookDev = nil, nil
local ids = {}
local priorId = nil
local expectedSwept, clientExpected, clientTarget = 0, 0, 0
local restoreAttempted = false
local swept, skipped, clientStaged, leakTotal = 0, 0, 0, 0
local skipDetails, leaks, sweptIds = {}, {}, {}
local errors, restoreErrors, injected = {}, {}, {}
local auditOk, auditError = false, nil

local function emit(name, passed, measured, target, detail)
	if not results.byName[name] then
		results.checkNames[#results.checkNames + 1] = name
	end
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

local function addError(message)
	errors[#errors + 1] = message
end

local function checkNameFor(id)
	local upper = string.upper(id)
	upper = upper:gsub("[^%w_]", "_")
	return "LOOKDEV_LEAK_" .. upper
end

-- One container at a time; a read failure invalidates the snapshot rather than looking like 0.
local function signature(serviceName)
	local ok, list = pcall(function()
		return game:GetService(serviceName):GetDescendants()
	end)
	if not ok or type(list) ~= "table" then
		return nil
	end
	local map = {}
	for _, instance in ipairs(list) do
		local okKey, key = pcall(function()
			return instance.ClassName .. "|" .. instance:GetFullName()
		end)
		if not okKey then
			return nil
		end
		map[key] = (map[key] or 0) + 1
	end
	return map
end

local function snapshot()
	local workspace, lighting = signature("Workspace"), signature("Lighting")
	if not workspace or not lighting then
		return nil
	end
	return { Workspace = workspace, Lighting = lighting }
end

-- Symmetric-difference size; leftovers and missing originals both count as a leak.
local function diffSignatures(before, after)
	if not before or not after then
		return nil, {}
	end
	local total, offenders = 0, {}
	for container, map in pairs(before) do
		for key, count in pairs(map) do
			local afterCount = (after[container] or {})[key] or 0
			if count ~= afterCount then
				total += math.abs(count - afterCount)
				offenders[#offenders + 1] = container .. ":" .. key .. " " .. count .. "->" .. afterCount
			end
		end
	end
	for container, map in pairs(after) do
		for key, count in pairs(map) do
			if not before[container] or not before[container][key] then
				total += count
				offenders[#offenders + 1] = container .. ":" .. key .. " 0->" .. count
			end
		end
	end
	return total, offenders
end

local function stage(id)
	if type(review) ~= "table" then
		return false, "review missing"
	end
	if type(review.enableAdditive) == "function" then
		return pcall(review.enableAdditive, id, game)
	end
	if type(review.enable) == "function" then
		return pcall(review.enable, id, game)
	end
	return false, "no staging API"
end

local function unstage()
	if type(review) ~= "table" or type(review.disableAll) ~= "function" then
		return false
	end
	local ok = pcall(review.disableAll)
	return ok
end

local function destroyInjected()
	for index = #injected, 1, -1 do
		pcall(function()
			injected[index]:Destroy()
		end)
		injected[index] = nil
	end
end

local function injectLeftover()
	local part = Instance.new("Part")
	part.Name = "Q219_LEAK_CALIBRATION"
	part.Size = Vector3.new(0.2, 0.2, 0.2)
	part.CFrame = CFrame.new(0, 0.1, 0)
	part.Anchored = true
	part.CanCollide = false
	part.CastShadow = false
	part:SetAttribute("Q219LeakCalibration", true)
	part.Parent = game:GetService("Workspace")
	injected[#injected + 1] = part
end

local function restorePrior()
	if not priorId or restoreAttempted or type(LookDev) ~= "table" or type(LookDev.enable) ~= "function" then
		return
	end
	restoreAttempted = true
	local ok, result = pcall(function()
		return LookDev.enable(priorId)
	end)
	if not ok or result == false then
		restoreErrors[#restoreErrors + 1] = priorId .. ":" .. tostring(result)
	end
end

function M.init()
	auditOk, auditError = false, nil
	review, LookDev = nil, nil
	ids = {}
	priorId = nil
	expectedSwept, clientExpected, clientTarget = 0, 0, 0
	restoreAttempted = false
	destroyInjected()
	injected = {}
	swept, skipped, clientStaged, leakTotal = 0, 0, 0, 0
	skipDetails, leaks, sweptIds = {}, {}, {}
	errors, restoreErrors = {}, {}
	results.checks, results.byName, results.checkNames = {}, {}, {}

	local ok, err = pcall(function()
		local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
		review = require(shared:WaitForChild("LookDevReview"))
		LookDev = require(shared:WaitForChild("LookDev"))
		if type(LookDev) ~= "table" or type(LookDev.IDS) ~= "table" or #LookDev.IDS == 0 then
			error("LookDev.IDS missing")
		end
		if type(LookDev.current) ~= "function" or type(LookDev.enable) ~= "function" then
			error("LookDev toggle API missing")
		end
		if type(review) ~= "table" or type(review.pathsFor) ~= "function" then
			error("LookDevReview.pathsFor missing")
		end

		local okCurrent, current = pcall(function()
			return LookDev.current()
		end)
		if okCurrent and type(current) == "string" then
			priorId = current
		end
		unstage() -- clear any prior active candidate before the first baseline

		ids = LookDev.IDS
		for _, id in ipairs(ids) do
			local entry = review.pathsFor(id)
			if entry and entry.datamodel == "client" then
				clientExpected += 1
			end
		end
		clientTarget = clientExpected
		expectedSwept = #ids -- refined by finish() using the actual client skips
	end)
	if not ok then
		auditError = tostring(err)
		return { ok = false, reason = auditError }
	end
	auditOk = true
	return { ids = #ids, clientExpected = clientExpected, ok = true }
end

function M.chunk(from, to)
	if type(from) ~= "number" or type(to) ~= "number" then
		return { done = true, from = from, to = to, processed = 0, cumulativeSwept = swept, cumulativeLeaks = leakTotal }
	end
	local first, last = math.max(1, from), math.min(to, #ids)
	local processed = 0
	for index = first, last do
		local id = ids[index]
		local name = checkNameFor(id)
		local okBody, errBody = pcall(function()
			local entry = review.pathsFor(id)
			local before = snapshot() -- baseline must be read before staging
			local stageOk, staged, why = stage(id)
			if not stageOk or staged == false then
				if entry and entry.datamodel == "client" then
					skipped += 1
					skipDetails[#skipDetails + 1] = id .. ":" .. tostring(why or staged)
				else
					addError(id .. ":stage:" .. tostring(why or staged))
					emit(name, false, 1, 0, {
						reason = tostring(why or staged),
						datamodel = entry and entry.datamodel or nil,
					})
				end
				unstage()
			else
				if not before then
					addError(id .. ":snapshot-before")
					emit(name, false, 1, 0, { reason = "snapshot-before" })
				elseif not unstage() then
					addError(id .. ":unstage")
					emit(name, false, 1, 0, { reason = "unstage" })
				else
					local after = snapshot()
					if not after then
						addError(id .. ":snapshot-after")
						emit(name, false, 1, 0, { reason = "snapshot-after" })
					else
						local delta, offenders = diffSignatures(before, after)
						if not delta then
							addError(id .. ":diff")
							emit(name, false, 1, 0, { reason = "diff" })
						else
							leakTotal += delta
							if delta > 0 then
								leaks[#leaks + 1] = id .. "(" .. table.concat(offenders, ",") .. ")"
							end
							emit(name, delta == 0, delta, 0, {
								delta = delta,
								offenders = offenders,
								datamodel = entry and entry.datamodel or nil,
							})
						end
					end
				end
				swept += 1
				sweptIds[#sweptIds + 1] = id
				if entry and entry.datamodel == "client" then
					clientStaged += 1
				end
			end
		end)
		if not okBody then
			unstage() -- no staged candidate may bleed into the next chunk
			addError(id .. ":chunk")
			emit(name, false, 1, 0, { reason = tostring(errBody) })
		end
		processed += 1
	end
	return {
		done = true,
		from = from,
		to = to,
		processed = processed,
		cumulativeSwept = swept,
		cumulativeLeaks = leakTotal,
	}
end

function M.finish()
	local ok, err = pcall(function()
		-- CALIBRATION ANCHOR (FAIL): the injected part survives disableAll, so the delta must be > 0.
		local calDelta, calOffenders, calReason = 0, {}, nil
		if #sweptIds == 0 then
			calReason = "no swept candidate"
		else
			local calId = sweptIds[1]
			local stageOk, staged, why = stage(calId)
			if not stageOk or staged == false then
				calReason = tostring(why or staged)
			else
				local calBefore = snapshot()
				if not calBefore then
					calReason = "snapshot-before"
				else
					injectLeftover()
					if not unstage() then
						calReason = "unstage"
					else
						local calAfter = snapshot()
						if not calAfter then
							calReason = "snapshot-after"
						else
							calDelta, calOffenders = diffSignatures(calBefore, calAfter)
							if not calDelta then
								calDelta, calReason = 0, "diff"
							end
						end
					end
				end
			end
		end
		destroyInjected()

		restorePrior()

		expectedSwept = #ids - skipped
		if expectedSwept <= 0 then
			addError("no swept ids")
		end
		local sweptPass = swept > 0 and swept == expectedSwept and #errors == 0
		emit("LOOKDEV_IDS_SWEPT", sweptPass, swept, expectedSwept, {
			totalIds = #ids,
			clientExpected = clientExpected,
			clientStaged = clientStaged,
			clientSkipped = skipped,
			errors = errors,
		})

		local skipTarget = clientExpected - clientStaged
		local skipPass = skipped == skipTarget and #errors == 0
		emit("LOOKDEV_CLIENT_SKIP", skipPass, skipped, skipTarget, {
			ids = skipDetails,
			clientExpected = clientExpected,
			clientStaged = clientStaged,
			totalIds = #ids,
			swept = swept,
		})

		emit("CAL_LOOKDEV_LEAK_FAIL", calDelta ~= nil and calDelta >= 1, calDelta and calDelta >= 1 and 1 or 0, 1, {
			delta = calDelta,
			offenders = calOffenders,
			reason = calReason,
			candidate = sweptIds[1],
		})

		local leakPass = leakTotal == 0 and sweptPass and skipPass and #errors == 0 and #restoreErrors == 0
		emit("LOOKDEV_LEAK", leakPass, leakTotal + #errors + #restoreErrors, 0, {
			leaks = leaks,
			errors = errors,
			restoreErrors = restoreErrors,
			swept = swept,
			clientSkipped = skipped,
			restored = priorId,
		})
	end)

	-- Restore on every path: injections die first, then the prior active candidate comes back.
	destroyInjected()
	restorePrior()

	if not ok or not auditOk then
		local reason = { reason = "item 219 audit error: " .. tostring(err or auditError) }
		local seen = {}
		for _, name in ipairs(CHECK_NAMES) do
			seen[name] = true
		end
		for _, name in ipairs(results.checkNames) do
			seen[name] = true
		end
		for name in pairs(seen) do
			local target = 0
			if name == "CAL_LOOKDEV_LEAK_FAIL" then
				target = 1
			elseif name == "LOOKDEV_IDS_SWEPT" then
				target = expectedSwept
			elseif name == "LOOKDEV_CLIENT_SKIP" then
				target = clientTarget
			end
			emitOnce(name, false, 1, target, reason)
		end
	end

	return results
end

return M
