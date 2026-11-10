-- State (server): replicates structured save data as a snapshot + section patches.
--
-- Scalars stay on player attributes (Cash, Sus, Rank, ...). This module covers the data
-- that does not fit in an attribute: produce stacks, items, tools, gudang, debt, quests,
-- almanak and story (v2 PLAN §7.1).
--
-- Ownership: PlayerData owns the data, shared/State shapes it, this module only sends it.
-- Services call State.touch(player, section) after mutating a section.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.Config.Game)
local Remotes = require(Shared.Remotes)
local StateSchema = require(Shared.State)

local PlayerData = require(script.Parent.Parent.Data.PlayerData)
local RateLimit = require(script.Parent.Parent.Net.RateLimit)

local State = {}

-- [player] = { [section] = true }
local dirty: { [Player]: { [string]: boolean } } = {}

local function sendSnapshot(player: Player)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	dirty[player] = nil
	Remotes.State_Snapshot:FireClient(player, StateSchema.snapshot(data))
end

-- Mark one section as changed; the patch is coalesced and sent on the next tick.
function State.touch(player: Player, section: string)
	if not StateSchema.isSection(section) or not PlayerData.get(player) then
		return
	end
	local sections = dirty[player]
	if not sections then
		sections = {}
		dirty[player] = sections
	end
	sections[section] = true
end

function State.touchAll(player: Player)
	for _, section in StateSchema.SECTIONS do
		State.touch(player, section)
	end
end

function State.start()
	Remotes.State_Request.OnServerEvent:Connect(function(player)
		if RateLimit.allow(player, "State_Request", 1) then
			sendSnapshot(player)
		end
	end)

	PlayerData.onLoaded(function(player)
		sendSnapshot(player)
	end)
	PlayerData.onBeforeRelease(function(player)
		dirty[player] = nil
	end)

	task.spawn(function()
		while true do
			task.wait(GameConfig.statePatchInterval)
			for player, sections in dirty do
				local data = PlayerData.get(player)
				dirty[player] = nil
				if data then
					local patch = StateSchema.patch(data, sections)
					if next(patch) ~= nil then
						Remotes.State_Patch:FireClient(player, patch)
					end
				end
			end
		end
	end)
end

return State
