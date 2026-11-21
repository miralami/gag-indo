--!nocheck
-- crop_growth_check: WORK_QUEUE section M6 item 93 (crop stage audit). CLIENT-VM ONLY — the
-- `crops` LookDev applier (src/client/World/LookDevCrops.luau) stages 36 showcase Models in the
-- CLIENT workspace (folder `LookDevCropShowcase`), one per crop x stage. Paste this whole file into
-- Studio MCP execute_luau with datamodel_type="Client" in a fresh Play session, after injecting
-- the client applier into ReplicatedStorage.Shared.LookDevCropsInjected (saved-place boots predate
-- the module, so `hasApplier("crops")` is false until it is required). The check returns a results
-- table with `byName.CROP_GROWTH`, the verbatim `CHECK ...` lines, and the 36-row bbox table.
--
-- WHY ENGINE BBOX: the pure descriptor calc in CropModelCandidates diverges from the real
-- Model:GetBoundingBox() because rotated Wedge/Ball/Cylinder geometry has different extents than
-- offset +/- size/2. Item 93 measures GetBoundingBox, so this check reads it live and never
-- substitutes the pure approximation.
--
-- WHY ANCHOR: the applier stages UNANCHORED parts near the player; they fall under physics and the
-- bbox drifts every frame (padi bibit 1.357 -> 1.551 in 0.3 s). This check anchors every BasePart
-- in the SAME call as enable(), before any task.wait(), so the measured bbox is the reproducible
-- as-built geometry. No place is saved; the prior candidate is restored at the end.
--
-- Thresholds are the item's verbatim bounds (MIN_H 0.5, MAX_H 6.0 studs, MIN_GROWTH 15% per gap)
-- and are never weakened. A missing folder/model or a failed read FAILs loudly; no silent skip.

local MIN_H = 0.5
local MAX_H = 6.0
local MIN_GROWTH = 15.0
local STAGES = { "bibit", "tumbuh", "siap" }
local CONTAINER = "LookDevCropShowcase"

local results = {}
results.byName = {}
local function emit(name, passed, measured, target, detail)
	local line = "CHECK "
		.. name
		.. " "
		.. (passed and "PASS" or "FAIL")
		.. " "
		.. tostring(measured)
		.. " "
		.. tostring(target)
	results[#results + 1] = line
	results.byName[name] = { line = line, passed = passed, measured = measured, target = target, detail = detail }
end

local ok, err = pcall(function()
	local S = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	local LD = require(S:WaitForChild("LookDev"))
	local Model = require(S:WaitForChild("CropModelCandidates"))

	-- Saved-place boots predate the client applier: require the injected copy so it registers.
	if not LD.hasApplier("crops") then
		local inj = S:FindFirstChild("LookDevCropsInjected")
		if inj then
			pcall(require, inj)
		end
	end

	local prior = LD.current and LD.current() or nil
	LD.disable()
	local enabled, enErr = LD.enable("crops", { studio = true })
	if not enabled then
		error("enable(crops) failed: " .. tostring(enErr))
	end

	local folder = workspace:FindFirstChild(CONTAINER)
	if not folder then
		error("showcase folder missing after enable(crops)")
	end

	-- Freeze physics drift: anchor every staged part in this same call, before any task.wait().
	for _, o in ipairs(folder:GetDescendants()) do
		if o:IsA("BasePart") then
			o.Anchored = true
		end
	end

	local rows = {}
	local failures = {}
	local measuredCount = 0
	for _, crop in ipairs(Model.cropIds) do
		local h = {}
		local complete = true
		for _, stage in ipairs(STAGES) do
			local m = folder:FindFirstChild("LookDevCrop_" .. crop .. "_" .. stage)
			if not m then
				complete = false
				break
			end
			local _, size = m:GetBoundingBox()
			h[stage] = size.Y
		end
		if not complete then
			failures[#failures + 1] = crop .. ": missing stage model"
		else
			measuredCount += 1
			local g1 = (h.tumbuh / h.bibit - 1) * 100
			local g2 = (h.siap / h.tumbuh - 1) * 100
			local inBounds = h.bibit >= MIN_H
				and h.tumbuh >= MIN_H
				and h.siap >= MIN_H
				and h.bibit <= MAX_H
				and h.tumbuh <= MAX_H
				and h.siap <= MAX_H
			local grows = g1 >= MIN_GROWTH and g2 >= MIN_GROWTH
			if not (inBounds and grows) then
				failures[#failures + 1] = string.format(
					"%s %.3f/%.3f/%.3f g1=%.1f%% g2=%.1f%% bounds=%s grows=%s",
					crop,
					h.bibit,
					h.tumbuh,
					h.siap,
					g1,
					g2,
					tostring(inBounds),
					tostring(grows)
				)
			end
			rows[#rows + 1] = {
				crop = crop,
				bibit = math.floor(h.bibit * 1000) / 1000,
				tumbuh = math.floor(h.tumbuh * 1000) / 1000,
				siap = math.floor(h.siap * 1000) / 1000,
				g1 = math.floor(g1 * 10) / 10,
				g2 = math.floor(g2 * 10) / 10,
				ok = inBounds and grows,
			}
		end
	end

	table.sort(rows, function(a, b)
		return a.crop < b.crop
	end)

	local pass = (#failures == 0) and measuredCount == #Model.cropIds
	emit("CROP_GROWTH", pass, measuredCount, #Model.cropIds, {
		measured = measuredCount,
		expected = #Model.cropIds,
		failures = failures,
		minHeight = MIN_H,
		maxHeight = MAX_H,
		minGrowthPct = MIN_GROWTH,
		anchored = true,
		enabled = enabled,
		prior = prior,
	})
	results.table = rows

	-- Exact restore: disable the showcase, then re-enable whatever candidate was active before.
	LD.disable()
	if prior and prior ~= "none" then
		pcall(function()
			return LD.enable(prior, { studio = true })
		end)
	end
end)

if not ok then
	emit("CROP_GROWTH", false, 0, 12, { reason = "audit error: " .. tostring(err) })
end

return results
