--!nocheck
-- check_q213: WORK_QUEUE item 213, self-contained SERVER-VM Studio check. Paste the whole file into
-- execute_luau in a FRESH Play session. It stages the OFF-BY-DEFAULT client candidate animals_r8
-- with LookDevReview.enableAdditive, reads the live DataModel, prints the CHECK lines verbatim and
-- restores everything in this SAME call. No harness require, no place save, no visual verdict.
--
--   DUCKS          <count> 6       Models named bebek_* with >=1 visible BasePart (Transparency<1).
--   DUCKS_ON_WATER <delta> 0.5     max |Model.PrimaryPart (Anchor) world Y - ModelMapRiverR8
--                                  .WATER_SURFACE_Y| over those ducks. The duck home band is at the
--                                  water surface, so the Anchor is the animal's waterline position.
--   FISH_RIPPLES   <count> 1       BaseParts tagged FishRipple==true (flat Cylinder discs, no Ball,
--                                  CanCollide=false) in the same candidate folder.
--   CLIENT_ONLY_ANIM 0 0           Read-only script-source audit: zero Script/ModuleScript Sources
--                                  under ServerScriptService mention animals_r8 / ModelMapAnimalsR8
--                                  / FishRipple AND Heartbeat; the client applier Source does contain
--                                  both. A synthetic animal+Heartbeat source is proven to trip the
--                                  same predicate (non-vacuous).
--
-- STAGING NOTE: animals_r8 is registered in LookDevReview.paths with datamodel="client". This harness
-- still attempts enableAdditive from the SERVER VM. If that fails, it reads an already client-staged
-- folder if one exists and prints DETAIL STAGING source=client-staged; if neither works the three
-- geometry checks emit real FAIL lines with measured 0. No PASS is fabricated.
--
-- CALIBRATION ANCHORS: hide every duck's visible parts -> DUCKS count 0; lift one duck 2 studs ->
-- max water delta > 0.5; Destroy() every fish ripple -> ripple count 0. Duck Transparency and CFrame
-- are restored exactly; ripples are removed from the candidate folder and disableAll() restores the
-- rest. No injection survives the call.

local CHECK_NAMES = {
	"DUCKS",
	"DUCKS_ON_WATER",
	"FISH_RIPPLES",
	"CLIENT_ONLY_ANIM",
	"CAL_DUCKS_FAIL",
	"CAL_DUCKS_ON_WATER_FAIL",
	"CAL_FISH_RIPPLES_FAIL",
}
local CHECK_TARGETS = {
	DUCKS = 6,
	DUCKS_ON_WATER = 0.5,
	FISH_RIPPLES = 1,
	CLIENT_ONLY_ANIM = 0,
	CAL_DUCKS_FAIL = 1,
	CAL_DUCKS_ON_WATER_FAIL = 1,
	CAL_FISH_RIPPLES_FAIL = 1,
}

local CANDIDATE_ID = "animals_r8"
local MIN_DUCKS = 6
local WATER_TOLERANCE = 0.5
local MIN_RIPPLES = 1
local LIFT = 2

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
	return ok and value == true
end

local function descendants(instance)
	if not instance then
		return {}
	end
	local ok, list = pcall(function()
		return instance:GetDescendants()
	end)
	return ok and type(list) == "table" and list or {}
end

local function duckModels(folder)
	local out = {}
	for _, inst in ipairs(descendants(folder)) do
		pcall(function()
			if inst:IsA("Model") and string.sub(inst.Name, 1, 6) == "bebek_" then
				out[#out + 1] = inst
			end
		end)
	end
	return out
end

local function countDucks(models)
	local count = 0
	for _, model in ipairs(models) do
		local hasVisible = false
		for _, part in ipairs(descendants(model)) do
			pcall(function()
				if part:IsA("BasePart") and visible(part) then
					hasVisible = true
				end
			end)
			if hasVisible then
				break
			end
		end
		if hasVisible then
			count += 1
		end
	end
	return count
end

local function duckY(model)
	local primary = model.PrimaryPart
	if not primary then
		return nil
	end
	local ok, y = pcall(function()
		return primary.CFrame.Position.Y
	end)
	return ok and type(y) == "number" and y or nil
end

local function maxDuckDelta(models, waterY)
	local worst, missing = 0, 0
	for _, model in ipairs(models) do
		local y = duckY(model)
		if y == nil then
			missing += 1
		else
			worst = math.max(worst, math.abs(y - waterY))
		end
	end
	return worst, missing
end

local function rounded(value)
	return math.floor(value * 10000 + 0.5) / 10000
end

local function rippleParts(folder)
	local out = {}
	for _, inst in ipairs(descendants(folder)) do
		pcall(function()
			if inst:IsA("BasePart") and attr(inst, "FishRipple") == true then
				out[#out + 1] = inst
			end
		end)
	end
	return out
end

local function mentionsAnimalAnimation(src)
	return type(src) == "string"
		and (src:find("animals_r8", 1, true) or src:find("ModelMapAnimalsR8", 1, true) or src:find(
			"FishRipple",
			1,
			true
		)) ~= nil
		and src:find("Heartbeat", 1, true) ~= nil
end

local review = nil
local savedTransparency, savedCFrame, injected = {}, {}, {}

local function restoreTransparency()
	for part, value in pairs(savedTransparency) do
		pcall(function()
			part.Transparency = value
		end)
	end
	table.clear(savedTransparency)
end

local function restoreCFrames()
	for model, frame in pairs(savedCFrame) do
		pcall(function()
			model:SetPrimaryPartCFrame(frame)
		end)
	end
	table.clear(savedCFrame)
end

local function restoreAll()
	restoreTransparency()
	restoreCFrames()
	for _, part in ipairs(injected) do
		pcall(function()
			part:Destroy()
		end)
	end
	table.clear(injected)
	pcall(function()
		if review then
			review.disableAll()
		else
			require(game:GetService("ReplicatedStorage"):WaitForChild("Shared").LookDevReview).disableAll()
		end
	end)
end

local ok, err = pcall(function()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	review = require(shared:WaitForChild("LookDevReview"))
	local Data = require(shared:WaitForChild("ModelMapAnimalsR8"))
	local River = require(shared:WaitForChild("ModelMapRiverR8"))
	local waterY = River.WATER_SURFACE_Y
	if type(waterY) ~= "number" or type(Data.folder) ~= "string" then
		error("shared animals/river data API missing")
	end

	-- Stage the client candidate from the SERVER VM; fall back to an existing client-staged folder.
	local enableOk, enabled, why = pcall(review.enableAdditive, CANDIDATE_ID, game, { studio = true })
	local staged = enableOk == true and enabled == true
	local folder = workspace:FindFirstChild(Data.folder)
	local source = if folder then (staged and "server-staged" or "client-staged") else "none"
	print(
		"DETAIL STAGING id="
			.. CANDIDATE_ID
			.. " source="
			.. source
			.. " enable="
			.. tostring(staged)
			.. (staged and "" or (" why=" .. tostring(why)))
	)
	if not staged and not folder then
		print(
			"DETAIL STAGING note=SERVER VM could not stage the client datamodel path and no client-staged parts are present"
		)
	end

	local models = duckModels(folder)
	local duckCount = countDucks(models)
	emit("DUCKS", duckCount >= MIN_DUCKS, duckCount, MIN_DUCKS, {
		source = source,
		models = #models,
		expectedDataCount = Data.COUNT.bebek,
		selection = "Model name bebek_* with >=1 visible BasePart inside " .. Data.folder,
	})

	local worst, missing = maxDuckDelta(models, waterY)
	local waterPass = duckCount >= MIN_DUCKS and missing == 0 and worst <= WATER_TOLERANCE
	emit("DUCKS_ON_WATER", waterPass, rounded(worst), WATER_TOLERANCE, {
		waterY = waterY,
		missingPrimaryPart = missing,
		measure = "Model.PrimaryPart (Anchor) world Y",
	})

	local ripples = rippleParts(folder)
	emit("FISH_RIPPLES", #ripples >= MIN_RIPPLES, #ripples, MIN_RIPPLES, {
		source = source,
		selection = "BasePart FishRipple==true, Shape Cylinder (never Ball), CanCollide=false",
	})

	-- Read-only source audit: no server-side Heartbeat for this candidate; client still has one.
	local violations, scanned = 0, 0
	local okDesc, serverSources = pcall(function()
		return game:GetService("ServerScriptService"):GetDescendants()
	end)
	if okDesc and type(serverSources) == "table" then
		for _, inst in ipairs(serverSources) do
			local okSrc, src = pcall(function()
				if inst:IsA("LuaSourceContainer") then
					return inst.Source
				end
				return nil
			end)
			if okSrc and type(src) == "string" then
				scanned += 1
				if mentionsAnimalAnimation(src) then
					violations += 1
				end
			end
		end
	end

	local clientHasLoop, clientWhy = false, nil
	pcall(function()
		local entry = review.paths and review.paths[CANDIDATE_ID]
		local node = entry and review.resolveContainer(entry.datamodel, game)
		if node then
			for _, segment in ipairs(entry.path) do
				local okChild, child = pcall(function()
					return node[segment]
				end)
				node = okChild and child or nil
				if not node then
					break
				end
			end
		end
		if not node then
			clientWhy = "client applier module not found"
			return
		end
		local okSrc, src = pcall(function()
			return node.Source
		end)
		if not okSrc or type(src) ~= "string" then
			clientWhy = "client applier Source unreadable"
			return
		end
		clientHasLoop = src:find("Heartbeat", 1, true) ~= nil and src:find("FishRipple", 1, true) ~= nil
	end)
	local synthetic = "RunService.Heartbeat:Connect(function() -- animals_r8 FishRipple"
	local probeRejects = mentionsAnimalAnimation(synthetic)
	emit("CLIENT_ONLY_ANIM", violations == 0 and clientHasLoop and probeRejects, violations, 0, {
		serverScriptsScanned = scanned,
		clientHeartbeatAndRipples = clientHasLoop,
		clientReason = clientWhy,
		probeRejectsSynthetic = probeRejects,
		note = "read-only source audit; no server script connects a Heartbeat for this candidate",
	})

	-- CAL_DUCKS_FAIL: hide every visible duck part, re-count, restore the exact Transparency values.
	for _, model in ipairs(models) do
		for _, part in ipairs(descendants(model)) do
			pcall(function()
				if part:IsA("BasePart") then
					savedTransparency[part] = part.Transparency
					part.Transparency = 1
				end
			end)
		end
	end
	local hiddenCount = countDucks(models)
	restoreTransparency()
	local calDucks = duckCount >= MIN_DUCKS and hiddenCount == 0
	emit("CAL_DUCKS_FAIL", calDucks, calDucks and 1 or 0, 1, {
		ducksBefore = duckCount,
		ducksWhileHidden = hiddenCount,
	})

	-- CAL_DUCKS_ON_WATER_FAIL: lift one duck 2 studs; the same delta guard must reject it.
	local liftDelta = 0
	if #models > 0 and duckY(models[1]) ~= nil then
		pcall(function()
			local model = models[1]
			local original = model.PrimaryPart.CFrame
			savedCFrame[model] = original
			model:SetPrimaryPartCFrame(original * CFrame.new(0, LIFT, 0))
		end)
		liftDelta = maxDuckDelta(models, waterY)
		restoreCFrames()
	end
	local calWater = waterPass and liftDelta > WATER_TOLERANCE
	emit("CAL_DUCKS_ON_WATER_FAIL", calWater, calWater and 1 or 0, 1, {
		baseDelta = rounded(worst),
		liftedDelta = rounded(liftDelta),
		liftStuds = LIFT,
	})

	-- CAL_FISH_RIPPLES_FAIL: Destroy() the staged ripple discs; the count must fall to zero.
	for _, disc in ipairs(ripples) do
		pcall(function()
			disc:Destroy()
		end)
	end
	local ripplesAfter = #rippleParts(folder)
	local calRipples = #ripples >= MIN_RIPPLES and ripplesAfter == 0
	emit("CAL_FISH_RIPPLES_FAIL", calRipples, calRipples and 1 or 0, 1, {
		ripplesBefore = #ripples,
		ripplesAfterDestroy = ripplesAfter,
	})
end)

restoreAll()

if not ok then
	local reason = { reason = "item 213 audit error: " .. tostring(err) }
	for _, name in ipairs(CHECK_NAMES) do
		emitOnce(name, false, 0, CHECK_TARGETS[name], reason)
	end
end

return results
