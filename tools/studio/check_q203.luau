--!nocheck
-- check_q203: WORK_QUEUE item 203, self-contained SERVER-VM Studio check. Paste this whole file
-- into execute_luau in a fresh Play session. It measures the live DataModel BEFORE and AFTER
-- staging signposts_r10 with enableAdditive, prints verbatim CHECK lines, then restores with
-- disableAll() in the same call. No harness require, no place save, no visual verdict.
--
--   SIGNPOSTS             exactly 4 distinct "sign" groups tagged Signpost==true
--   SIGN_TEXT_IN_STRINGS  4/4 staged text keys have non-empty id and en in Shared.Strings
--   SIGN_READABLE         4/4 staged TextLabels have TextSize >= READ_MIN_PX (14)
--
-- CALIBRATION ANCHORS: `local before = measure()` and `local after = measure()` are separate single
-- lines so a mismatch can be injected between them. Destroy a sign board => SIGNPOSTS drops.
-- Remove an `en` variant from the live Strings table in-session (restore it after) =>
-- SIGN_TEXT_IN_STRINGS FAIL. Set a staged label's TextSize below 14 => SIGN_READABLE FAIL.

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

local CHECK_NAMES = { "SIGNPOSTS", "SIGN_TEXT_IN_STRINGS", "SIGN_READABLE" }
local CANDIDATE_ID = "signposts_r10"
local SIGN_TARGET = 4
local READ_MIN_PX = 14

local review, Data, Strings, StringsRaw = nil, nil, nil, nil

-- Every reading comes from the live DataModel, never from the pure data alone.
local function measure()
	local groups, textValid = {}, {}
	local readableLabels, readErrors = 0, 0

	local okDescendants, descendants = pcall(function()
		return workspace:GetDescendants()
	end)
	if not okDescendants or type(descendants) ~= "table" then
		readErrors += 1
	else
		for _, instance in ipairs(descendants) do
			local okTag, tagged = pcall(function()
				return instance:GetAttribute("Signpost") == true
			end)
			if okTag and tagged then
				local okSign, signIndex = pcall(function()
					return instance:GetAttribute("sign")
				end)
				if okSign and signIndex ~= nil then
					groups[signIndex] = true
					local okKey, key = pcall(function()
						return instance:GetAttribute("textKey")
					end)
					local entry = nil
					if okKey and type(key) == "string" and type(StringsRaw) == "table" then
						entry = StringsRaw[key]
					end
					textValid[signIndex] = type(entry) == "table"
						and type(entry.id) == "string"
						and #entry.id > 0
						and type(entry.en) == "string"
						and #entry.en > 0
				end

				local okChildren, children = pcall(function()
					return instance:GetDescendants()
				end)
				if not okChildren or type(children) ~= "table" then
					readErrors += 1
				else
					for _, child in ipairs(children) do
						local okLabel, isLabel = pcall(function()
							return child:IsA("TextLabel")
						end)
						if okLabel and isLabel then
							local okSize, size = pcall(function()
								return child.TextSize
							end)
							if okSize and type(size) == "number" and size >= READ_MIN_PX then
								readableLabels += 1
							end
						end
					end
				end
			end
		end
	end

	local signs, textInStrings = 0, 0
	for index in pairs(groups) do
		signs += 1
		if textValid[index] then
			textInStrings += 1
		end
	end

	return {
		signs = signs,
		textInStrings = textInStrings,
		readable = readableLabels,
		readErrors = readErrors,
	}
end

local ok, err = pcall(function()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	review = require(shared:WaitForChild("LookDevReview"))
	Data = require(shared:WaitForChild("ModelMapSignpostsR10"))
	Strings = require(shared:WaitForChild("Strings"))
	StringsRaw = Strings.raw

	if type(Data) ~= "table" or type(Data.SIGNS) ~= "table" or #Data.SIGNS ~= SIGN_TARGET then
		error("ModelMapSignpostsR10 API missing")
	end
	if type(StringsRaw) ~= "table" then
		error("Shared.Strings.raw missing")
	end
	if type(Data.READ_MIN_PX) == "number" then
		READ_MIN_PX = Data.READ_MIN_PX
	end

	-- CALIBRATION ANCHOR (BEFORE). A mismatch can be injected between the two measure calls.
	local before = measure()

	local enableOk, enabled, why = pcall(review.enableAdditive, CANDIDATE_ID, game)
	local enableReason = nil
	if not enableOk or not enabled then
		enableReason = "enableAdditive failed: " .. tostring(why)
	end

	local after = measure()

	local signDetail = {
		["before.signs"] = before.signs,
		afterSigns = after.signs,
		readErrors = after.readErrors,
		loadFailures = nil,
		reason = enableReason,
	}
	emit("SIGNPOSTS", after.signs == SIGN_TARGET, after.signs, SIGN_TARGET, signDetail)

	local textDetail = {
		["before.textInStrings"] = before.textInStrings,
		afterTextInStrings = after.textInStrings,
		readErrors = after.readErrors,
		reason = enableReason,
	}
	emit("SIGN_TEXT_IN_STRINGS", after.textInStrings == SIGN_TARGET, after.textInStrings, SIGN_TARGET, textDetail)

	local readableDetail = {
		["before.readable"] = before.readable,
		afterReadable = after.readable,
		readMinPx = READ_MIN_PX,
		readErrors = after.readErrors,
		reason = enableReason,
	}
	emit("SIGN_READABLE", after.readable == SIGN_TARGET, after.readable, SIGN_TARGET, readableDetail)
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
		emitOnce(name, false, 0, SIGN_TARGET, reason)
	end
end

return results
