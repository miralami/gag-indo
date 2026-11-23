--!nocheck
-- check_q267: WORK_QUEUE item 267, self-contained CLIENT-VM Studio check. Run in a fresh Play
-- session via execute_luau (Client DataModel). Item 238's helper hid only PlayerGui ScreenGuis,
-- which left the Roblox top bar (CoreGui) visible in sprint-4 captures. This check measures both:
--
--   HUD_HIDDEN   0 enabled ScreenGuis across PlayerGui AND the CoreGui top bar while hidden
--   HUD_RESTORE  0 ScreenGuis whose Enabled differs from the value saved before hideHud
--
-- Only the three named top-bar guis (RobloxGui / TopBarApp / TopBarScrim) are counted in CoreGui;
-- capture internals (CaptureManager / CaptureOverlay / ScreenshotsCarousel) are deliberately excluded
-- so screen_capture keeps working. The check never captures and never saves the place.
--
-- CALIBRATION ANCHORS (each measurement is one line so bad state can be injected):
--   * HUD_HIDDEN: parent one extra enabled ScreenGui into PlayerGui before the `hidden = count()`
--     line; the measurement sees 1 and FAILs.
--   * HUD_RESTORE: flip one saved gui directly before `mismatch = countMismatches(saved)`; sees 1.

local results = { checks = {}, byName = {} }

local function emit(name, passed, measured, target, detail)
	local line = "CHECK " .. name .. " " .. (passed and "PASS" or "FAIL") .. " " .. tostring(measured) .. " " .. tostring(target)
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
local TOP_BAR = { RobloxGui = true, TopBarApp = true, TopBarScrim = true }
local review, saved = nil, nil

local function tracked(playerGui, coreGui)
	local out = {}
	for _, d in ipairs(playerGui:GetDescendants()) do
		if d:IsA("ScreenGui") then
			out[#out + 1] = d
		end
	end
	if coreGui then
		for _, d in ipairs(coreGui:GetDescendants()) do
			if d:IsA("ScreenGui") and TOP_BAR[d.Name] then
				out[#out + 1] = d
			end
		end
	end
	return out
end

local function countEnabled(playerGui, coreGui)
	local n = 0
	for _, gui in ipairs(tracked(playerGui, coreGui)) do
		if gui.Enabled then
			n += 1
		end
	end
	return n
end

local function countMismatches(entries)
	local mismatches = 0
	for _, e in ipairs(entries) do
		if e.gui.Enabled ~= e.enabled then
			mismatches += 1
		end
	end
	return mismatches
end

local ok, err = pcall(function()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	review = require(shared:WaitForChild("LookDevReview"))
	if type(review) ~= "table" or type(review.hideHud) ~= "function" or type(review.restoreHud) ~= "function" then
		error("LookDevReview.hideHud/restoreHud API missing")
	end
	local localPlayer = game:GetService("Players").LocalPlayer
	if not localPlayer then
		error("no LocalPlayer in the CLIENT VM")
	end
	local playerGui = localPlayer:WaitForChild("PlayerGui", 5)
	local coreGui = game:GetService("CoreGui")

	local guis = tracked(playerGui, coreGui)
	saved = {}
	for _, gui in ipairs(guis) do
		saved[#saved + 1] = { gui = gui, enabled = gui.Enabled }
	end
	local before = countEnabled(playerGui, coreGui)

	local hidden = review.hideHud(game)
	-- CALIBRATION ANCHOR (HIDDEN): inject an enabled ScreenGui into playerGui here to force FAIL.
	local during = countEnabled(playerGui, coreGui)
	emit("HUD_HIDDEN", during == 0, during, 0, { before = before, hidden = hidden, tracked = #guis })

	local restored = review.restoreHud()
	-- CALIBRATION ANCHOR (RESTORE): flip one saved gui here to force a restore mismatch.
	local mismatch = countMismatches(saved)
	emit("HUD_RESTORE", restored == true and mismatch == 0, mismatch, 0, { restored = restored, before = before })
end)

pcall(function()
	if review then
		review.restoreHud()
	end
end)

if not ok then
	local reason = { reason = "audit error: " .. tostring(err) }
	for _, name in ipairs(CHECK_NAMES) do
		emitOnce(name, false, 0, 0, reason)
	end
end

print("SUMMARY_Q267 HUD_HIDDEN " .. tostring(results.byName.HUD_HIDDEN and results.byName.HUD_HIDDEN.passed) .. " HUD_RESTORE " .. tostring(results.byName.HUD_RESTORE and results.byName.HUD_RESTORE.passed))
return results
