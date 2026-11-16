-- SusService: the ONLY owner of the Sus meter (GDD §5.1, TECH.md §6).
-- 0-29 nothing · 30-59 Pak RT gossips · 60-79 Surat Panggilan · 80+ raid rolls · 100 raid now.

local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Law = require(Shared.Config.Law)

local PlayerData = require(script.Parent.Parent.Data.PlayerData)
local Notify = require(script.Parent.Parent.Net.Notify)
local RaidService = require(script.Parent.RaidService)
local FirstSession = require(script.Parent.Parent.Progression.FirstSession)

local SusService = {}

-- The saved Sus as a clamped whole number; a damaged (non-number or NaN) value reads as 0.
local function current(data): number
	local sus = data.sus
	if type(sus) ~= "number" or sus ~= sus then
		return 0
	end
	return math.clamp(math.floor(sus), 0, Law.susMax)
end

local function sync(player: Player, data)
	player:SetAttribute("Sus", current(data))
end

function SusService.get(player: Player): number
	local data = PlayerData.get(player)
	return if data then current(data) else 0
end

-- Set the exact value (raid reset). Clamped and mirrored to the attribute.
function SusService.setSus(player: Player, value: number)
	local data = PlayerData.get(player)
	if not data or type(value) ~= "number" or value ~= value then
		return
	end
	local previous = current(data)
	local updated = math.clamp(math.floor(value), 0, Law.susMax)
	data.sus = updated
	sync(player, data)
	FirstSession.onSusChanged(player, updated, previous)
end

-- Positive raises Sus, negative decays it. Returns the new value.
function SusService.add(player: Player, amount: number, _reason: string?): number
	local data = PlayerData.get(player)
	if not data or type(amount) ~= "number" or amount ~= amount then
		return 0
	end
	local previous = current(data)
	local updated = math.clamp(previous + math.floor(amount), 0, Law.susMax)
	data.sus = updated
	sync(player, data)
	FirstSession.onSusChanged(player, updated, previous)

	if previous < Law.letterSus and updated >= Law.letterSus then
		Notify.send(player, "n_letter", updated)
	end

	if updated >= Law.susMax then
		-- 100 means a raid right now. The raid finder ignores the post-raid cooldown.
		task.defer(RaidService.start, player, false)
	end

	return updated
end

function SusService.reduce(player: Player, amount: number, reason: string?): number
	if type(amount) ~= "number" or amount ~= amount or amount <= 0 then
		return SusService.get(player)
	end
	return SusService.add(player, -math.floor(amount), reason)
end

function SusService.start()
	PlayerData.onLoaded(function(player, data)
		sync(player, data)
	end)

	-- One loop for every player: decay, gossip and the 80+ raid roll.
	task.spawn(function()
		while true do
			task.wait(Law.susDecaySeconds)
			for _, player in Players:GetPlayers() do
				local data = PlayerData.get(player)
				if not data then
					continue
				end

				if (data.sus or 0) > 0 then
					SusService.add(player, -Law.susDecayAmount, "decay")
				end

				local sus = data.sus or 0
				if sus >= Law.gossipSus and sus < Law.letterSus and math.random() < 0.35 then
					Notify.send(player, "n_gossip")
				end

				if sus >= Law.raidChanceSus and math.random() < Law.raidChance then
					RaidService.start(player, false)
				end
			end
		end
	end)
end

return SusService
