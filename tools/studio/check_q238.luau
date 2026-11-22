--!nocheck
-- check_q238: WORK_QUEUE item 238, self-contained SERVER-VM Studio check. Paste this whole file into
-- execute_luau in a fresh Play session. It creates three temporary ScreenGuis with known initial
-- Enabled states under the first player's PlayerGui, calls hideHud(game) / restoreHud() from the
-- shared LookDevReview module, measures the live DataModel, prints verbatim CHECK lines, then
-- restores and destroys the temporary guis. No harness require, no place save, no visual verdict.
--
--   HUD_HIDDEN   0 enabled ScreenGuis under PlayerGui while hidden
--   HUD_RESTORE  0 temporary ScreenGuis whose Enabled differs from its saved value
--
-- execute_luau runs in the SERVER VM, where Players.LocalPlayer is nil. The helper falls back to
-- Players:GetPlayers()[1].PlayerGui; that is also why this check manipulates PlayerGui from here.
-- Client-VM capture usage is documented in docs/v2/visual/REVIEW_CAMERAS.md.
--
-- CALIBRATION ANCHORS (each measurement is a separate single line so bad state can be injected):
--   * HUD_HIDDEN: after hideHud(game), parent one extra enabled ScreenGui into playerGui before the
--     `local enabledWhileHidden = countEnabled(playerGui)` line (e.g. create a ScreenGui with
--     Enabled = true and Parent = playerGui). The measurement then sees 1 and FAILs.
--   * HUD_RESTORE: after restoreHud(), flip one temporary gui directly before the
--     `local restoreMismatches = countMismatches(saved)` line (e.g. `guis[3].Enabled = not saved[3].enabled`).
--     The measurement then sees 1 mismatch and FAILs.
-- The temporary guis are destroyed afterwards, so either injection is safe.

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

local CHECK_NAMES = { "HUD_HIDDEN", "HUD_RESTORE" }
local created, review, saved = {}, nil, nil

local function countEnabled(playerGui)
	local total, errors = 0, 0
	local ok, descendants = pcall(function()
		return playerGui:GetDescendants()
	end)
	if not ok or type(descendants) ~= "table" then
		return -1
	end
	for _, instance in ipairs(descendants) do
		local okClass, className = pcall(function()
			return instance.ClassName
		end)
		if okClass and className == "ScreenGui" then
			local okEnabled, enabled = pcall(function()
				return instance.Enabled
			end)
			if okEnabled and enabled == true then
				total += 1
			elseif not okEnabled then
				errors += 1
			end
		end
	end
	return total, errors
end

local function countMismatches(entries)
	local mismatches, errors = 0, 0
	for _, entry in ipairs(entries) do
		local ok, value = pcall(function()
			return entry.gui.Enabled
		end)
		if not ok then
			errors += 1
		elseif value ~= entry.enabled then
			mismatches += 1
		end
	end
	return mismatches, errors
end

local ok, err = pcall(function()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	review = require(shared:WaitForChild("LookDevReview"))
	if type(review) ~= "table" or type(review.hideHud) ~= "function" or type(review.restoreHud) ~= "function" then
		error("LookDevReview.hideHud/restoreHud API missing")
	end

	local players = game:GetService("Players")
	local connected = players:GetPlayers()
	local player = connected[1]
	if not player then
		error("no player connected in the SERVER VM")
	end
	local okGui, playerGui = pcall(function()
		return player:WaitForChild("PlayerGui", 5)
	end)
	if not okGui or not playerGui then
		error("player PlayerGui unavailable")
	end

	local guis = {}
	local function addTemporary(name, enabled)
		local gui = Instance.new("ScreenGui")
		gui.Name = name
		gui.Enabled = enabled
		gui.Parent = playerGui
		created[#created + 1] = gui
		guis[#guis + 1] = gui
		return gui
	end
	addTemporary("Q238_Hud", true)
	addTemporary("Q238_Phone", false)
	addTemporary("Q238_Board", true)

	saved = {}
	for _, gui in ipairs(guis) do
		saved[#saved + 1] = { gui = gui, enabled = gui.Enabled }
	end
	local beforeEnabled, beforeErrors = countEnabled(playerGui)

	local hiddenCount = review.hideHud(game)

	-- CALIBRATION ANCHOR (HIDDEN): inject an extra enabled ScreenGui here to force a FAIL.
	local enabledWhileHidden, hiddenErrors = countEnabled(playerGui)
	local hiddenDetail = {
		beforeEnabled = beforeEnabled,
		beforeErrors = beforeErrors,
		temporaryCount = #guis,
		hiddenCount = hiddenCount,
		hiddenErrors = hiddenErrors,
		playerGui = playerGui:GetFullName(),
	}
	emit("HUD_HIDDEN", enabledWhileHidden == 0 and hiddenErrors == 0, enabledWhileHidden, 0, hiddenDetail)

	-- CALIBRATION ANCHOR (RESTORE): flip one temporary gui here to force a restore mismatch.
	local restored = review.restoreHud()
	local restoreMismatches, restoreErrors = countMismatches(saved)
	local restoreDetail = {
		saved = saved,
		restored = restored,
		restoreErrors = restoreErrors,
		expected = { true, false, true },
	}
	emit(
		"HUD_RESTORE",
		restored == true and restoreMismatches == 0 and restoreErrors == 0,
		restoreMismatches,
		0,
		restoreDetail
	)
end)

-- Restore real HUD guis first, then remove only the temporary guis this check created.
pcall(function()
	if review then
		review.restoreHud()
	end
end)
pcall(function()
	for _, gui in ipairs(created) do
		gui:Destroy()
	end
end)

if not ok then
	local reason = { reason = "audit error: " .. tostring(err) }
	for _, name in ipairs(CHECK_NAMES) do
		emitOnce(name, false, 0, 0, reason)
	end
end

return results
