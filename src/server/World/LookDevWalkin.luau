-- LookDevWalkin: server applier for the OFF-BY-DEFAULT "police_walkin" look-dev candidate
-- (WORK_QUEUE item 9, candidate awaiting designer yes).
--
-- It reuses the EXISTING police model and pathing: Village.police[1] is the wrapped Npc built by
-- NpcFactory, with teleport()/walkTo()/stop(). The model is teleported off-frame, walks to the raid
-- cutscene's road anchor over the "walkin" shot duration, and is teleported home on disable().
-- Nothing happens until the designer opts in from the Studio command bar. No new models, no asset
-- IDs, and the NpcFactory walk loop (PivotTo, cancellation token) is used unchanged.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local LookDev = require(Shared.LookDev)
local Village = require(script.Parent.Village)

local LookDevWalkin = {}

local activeNpc: any = nil
local homeCFrame: CFrame? = nil
local walkToken = 0

local function policeNpc(): any
	return Village.police and Village.police[1] or nil
end

local function apply(plan: any)
	local npc = policeNpc()
	if not npc or not npc.model or not npc.model.Parent then
		return
	end
	activeNpc = npc
	homeCFrame = npc.model:GetPivot()
	local baseY = homeCFrame.Position.Y
	local spawn = plan.spawn
	local anchor = plan.anchor

	npc:teleport(Vector3.new(spawn.x, baseY, spawn.z))
	-- walkTo yields, so run it on its own thread; the token lets disable() cancel it cleanly.
	walkToken += 1
	local token = walkToken
	task.spawn(function()
		if token ~= walkToken then
			return
		end
		npc:walkTo(Vector3.new(anchor.x, baseY, anchor.z), plan.speed)
	end)
end

local function restore()
	walkToken += 1 -- cancel any in-flight walk
	if activeNpc then
		pcall(function()
			activeNpc:stop()
		end)
		if homeCFrame then
			pcall(function()
				activeNpc:teleport(homeCFrame.Position)
			end)
		end
	end
	activeNpc = nil
	homeCFrame = nil
end

LookDev.register("police_walkin", { apply = apply, restore = restore })

return LookDevWalkin
