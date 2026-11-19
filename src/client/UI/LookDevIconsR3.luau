-- LookDevIconsR3: client applier for the OFF-BY-DEFAULT "icons_r3" look-dev candidate.
--
-- WORK_QUEUE round 3 item 22 (icon half). Real r3 icon IDs live in Shared.IconMapR3 only; this
-- adapter swaps Visuals.icons[*].id on enable and restores the captured originals on disable.
-- The LookDev gate makes this Studio-only and never persisted. No numeric IDs in this file so
-- the LookDev ID guard still passes.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local LookDev = require(Shared.LookDev)
local IconMapR3 = require(Shared.IconMapR3)
local Visuals = require(Shared.Config.Visuals)

local LookDevIconsR3 = {}

local applied = false

local function apply(_plan)
	if applied then
		return
	end
	IconMapR3.apply(Visuals, true)
	applied = true
end

local function restore()
	if not applied then
		return
	end
	IconMapR3.apply(Visuals, false)
	applied = false
end

LookDev.register("icons_r3", { apply = apply, restore = restore })

LookDevIconsR3.apply = apply
LookDevIconsR3.restore = restore

return LookDevIconsR3
