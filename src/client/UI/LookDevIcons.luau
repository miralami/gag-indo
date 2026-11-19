-- LookDevIcons: client applier for the OFF-BY-DEFAULT "icons" look-dev candidate.
--
-- WORK_QUEUE round 2 item 4. Agent-made painted icons are CANDIDATES awaiting a designer yes/no.
-- On enable, this swaps Visuals.icons[*].id to the uploaded candidate values held in
-- Shared.IconMap.candidateIds; on disable it restores every touched slot to id 0 so the letter /
-- palette fallbacks return. The LookDev gate makes this Studio-only and never persisted.
-- This adapter holds no numeric IDs (they live in IconMap) so the LookDev ID guard still passes.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local LookDev = require(Shared.LookDev)
local IconMap = require(Shared.IconMap)
local Visuals = require(Shared.Config.Visuals)

local LookDevIcons = {}

local applied = false

local function apply(_plan)
	if applied then
		return
	end
	IconMap.applyCandidates(Visuals, true)
	applied = true
end

local function restore()
	if not applied then
		return
	end
	IconMap.applyCandidates(Visuals, false)
	applied = false
end

LookDev.register("icons", { apply = apply, restore = restore })

LookDevIcons.apply = apply
LookDevIcons.restore = restore

return LookDevIcons
