--!nocheck
-- check_q211: WORK_QUEUE item 211, self-contained SERVER-VM Studio check. Paste the whole file into
-- execute_luau in a FRESH Play session. It prints four CHECK lines verbatim, stages only the
-- OFF-BY-DEFAULT ronda_tower_r9 candidate for the height reading, and restores everything in this
-- SAME call on every path. No harness require, no place save, no visual verdict.
--
--   RONDA_PROPS  <count> 4  >=4 visible BaseParts tagged RondaDress==true whose RondaDressKind is
--                              one of {kentongan, bench, lamp, rack}. Selection: only tagged Parts
--                              with Transparency < 1; the four distinct kinds are recorded in the
--                              result detail. Default-look buildPosRonda() stages them; NOTHING is
--                              staged for this line.
--   TOWER_HEIGHT <height> 28..32  GetBoundingBox().Y of the staged Model carrying
--                              RondaTower=="ronda_tower_r9" (from LookDevReview.enableAdditive).
--                              The default greybox tower's nominal 36 is explicitly NOT the target.
--
-- CALIBRATION ANCHORS: hide every RondaDress prop (Transparency=1, exact save/restore) -> count 0
-- -> CAL_RONDA_PROPS_FAIL; with the candidate staged, evaluate the SAME pass predicate against a
-- synthetic height of 36 -> the guard must reject it -> CAL_TOWER_HEIGHT_FAIL. No model mutation.
-- review.disableAll() and the exact Transparency restore run before return, including on error.

local CHECK_NAMES = {
	"RONDA_PROPS",
	"TOWER_HEIGHT",
	"CAL_RONDA_PROPS_FAIL",
	"CAL_TOWER_HEIGHT_FAIL",
}
local CHECK_TARGETS = {
	RONDA_PROPS = 4,
	TOWER_HEIGHT = "28..32",
	CAL_RONDA_PROPS_FAIL = 1,
	CAL_TOWER_HEIGHT_FAIL = 1,
}
local TAG = "RondaDress"
local KIND_ATTR = "RondaDressKind"
local KINDS = { kentongan = true, bench = true, lamp = true, rack = true }
local MIN_PROPS = 4
local TOWER_ID = "ronda_tower_r9"
local TOWER_FOLDER = "LookDevRondaTowerR9_ronda_tower_r9"
local TOWER_MIN, TOWER_MAX = 28, 32

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

local function allowedKind(part)
	return KINDS[attr(part, KIND_ATTR)] == true
end

local function countedProps(parts)
	local count = 0
	local kinds, distinct = {}, 0
	for _, part in ipairs(parts) do
		if visible(part) and allowedKind(part) then
			count += 1
			local kind = attr(part, KIND_ATTR)
			if not kinds[kind] then
				kinds[kind] = true
				distinct += 1
			end
		end
	end
	return count, distinct, kinds
end

local function towerPass(height: number?): boolean
	return type(height) == "number" and height >= TOWER_MIN and height <= TOWER_MAX
end

local savedTransparency = {}

local function restoreTransparency()
	for part, value in pairs(savedTransparency) do
		pcall(function()
			part.Transparency = value
		end)
	end
	table.clear(savedTransparency)
end

local function restoreAll()
	restoreTransparency()
	pcall(function()
		require(game:GetService("ReplicatedStorage"):WaitForChild("Shared").LookDevReview).disableAll()
	end)
end

local ok, err = pcall(function()
	local props = {}
	for _, inst in ipairs(workspace:GetDescendants()) do
		pcall(function()
			if inst:IsA("BasePart") and attr(inst, TAG) == true then
				props[#props + 1] = inst
			end
		end)
	end

	local count, distinct, kinds = countedProps(props)
	local kindList = {}
	for _, kind in ipairs({ "kentongan", "bench", "lamp", "rack" }) do
		if kinds[kind] then
			kindList[#kindList + 1] = kind
		end
	end
	emit("RONDA_PROPS", count >= MIN_PROPS, count, MIN_PROPS, {
		tagged = #props,
		distinctKinds = distinct,
		kinds = kindList,
		allKindsPresent = distinct == #kindList and distinct == 4,
		selection = "BasePart, RondaDress==true, RondaDressKind in {kentongan,bench,lamp,rack}, Transparency<1",
	})
	print("DETAIL RONDA_PROPS kinds=" .. distinct .. " [" .. table.concat(kindList, ",") .. "]")

	-- CAL_RONDA_PROPS_FAIL: hide every tagged prop, re-count, restore the exact Transparency values.
	for _, part in ipairs(props) do
		pcall(function()
			savedTransparency[part] = part.Transparency
			part.Transparency = 1
		end)
	end
	local hiddenOk, hiddenCount = pcall(countedProps, props)
	local hiddenMeasured = hiddenOk and hiddenCount or -1
	restoreTransparency()
	local calPropsPassed = hiddenOk and hiddenCount == 0 and count >= MIN_PROPS
	emit("CAL_RONDA_PROPS_FAIL", calPropsPassed, calPropsPassed and 1 or 0, 1, {
		propsBefore = count,
		propsWhileHidden = hiddenMeasured,
	})

	-- TOWER_HEIGHT: stage only the OFF-BY-DEFAULT candidate, read the staged Model's world bbox.
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	local review = require(shared:WaitForChild("LookDevReview"))
	local enabled, why = review.enableAdditive(TOWER_ID, game)

	local height, heightReadOk = 0, false
	if enabled then
		for _, inst in ipairs(workspace:GetDescendants()) do
			local isModel = false
			pcall(function()
				isModel = inst:IsA("Model")
			end)
			if isModel and attr(inst, "RondaTower") == TOWER_ID then
				local readOk, cf, size = pcall(function()
					return inst:GetBoundingBox()
				end)
				if readOk and cf and size and type(size.Y) == "number" then
					height = size.Y
					heightReadOk = true
					break
				end
			end
		end
	end
	local shownHeight = math.floor(height * 100 + 0.5) / 100
	emit("TOWER_HEIGHT", heightReadOk and towerPass(height), shownHeight, "28..32", {
		staged = enabled == true,
		stageReason = if enabled then nil else tostring(why),
		folderPresent = workspace:FindFirstChild(TOWER_FOLDER) ~= nil,
		modelFound = heightReadOk,
		note = "staged ronda_tower_r9 bbox, not the default greybox nominal 36",
	})

	-- CAL_TOWER_HEIGHT_FAIL: the guard must reject 36 on the SAME predicate; the model is untouched.
	local synthetic = 36
	local syntheticRejected = not towerPass(synthetic)
	local calTowerPassed = heightReadOk and syntheticRejected and towerPass(height)
	emit("CAL_TOWER_HEIGHT_FAIL", calTowerPassed, calTowerPassed and 1 or 0, 1, {
		syntheticHeight = synthetic,
		syntheticRejected = syntheticRejected,
		realHeight = shownHeight,
	})

	-- One-call cleanup: remove the staged candidate and any leftover hidden props before returning.
	restoreAll()
end)

restoreAll()

if not ok then
	local reason = { reason = "item 211 audit error: " .. tostring(err) }
	for _, name in ipairs(CHECK_NAMES) do
		emitOnce(name, false, 0, CHECK_TARGETS[name], reason)
	end
end

return results
