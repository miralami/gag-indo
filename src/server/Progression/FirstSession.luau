-- FirstSession: beat sheet orchestrator and first-session timing/guarantees (v2 PLAN §3.1).

local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local FirstSessionConfig = require(Shared.Config.FirstSession)
local Crops = require(Shared.Config.Crops)
local OnboardingConfig = require(Shared.Config.Onboarding)

local PlayerData = require(script.Parent.Parent.Data.PlayerData)
local Notify = require(script.Parent.Parent.Net.Notify)
local Analytics = require(script.Parent.Parent.Analytics.Analytics)

local FirstSession = {}
local joinTimes: { [Player]: number } = {}

local function getData(player: any, passedData: any?): any?
	if passedData then
		return passedData
	end
	if type(player) == "table" and (player.story or player.stats) then
		return player
	end
	return PlayerData.get(player)
end

local function isFinished(data): boolean
	if not data or type(data.tutorial) ~= "table" then
		return false
	end
	local step = tonumber(data.tutorial.step) or 1
	return step > OnboardingConfig.total
end

function FirstSession.getGrowSeconds(player: Player?, cropId: string, data: any?, toolService: any?): number
	data = getData(player, data)
	local harvests = if data and data.stats and data.stats.harvests then data.stats.harvests else 0
	if not isFinished(data) and cropId == "padi" and harvests == 0 then
		return FirstSessionConfig.tutorialPadiGrowSeconds
	end
	local crop = Crops.list[cropId]
	local ts = toolService
	if not ts then
		local ok, mod = pcall(function()
			return require(script.Parent.Parent.Farm.ToolService)
		end)
		if ok then
			ts = mod
		end
	end
	if ts and type(ts.growSeconds) == "function" and crop then
		return ts.growSeconds(crop.growSeconds, crop.family, data)
	end
	return if crop then crop.growSeconds else 60
end

function FirstSession.getHarvestTier(player: Player?, data: any?, rolledTier: string): string
	data = getData(player, data)
	if not data then
		return rolledTier
	end
	if not data.stats then
		data.stats = {}
	end
	local harvests = (data.stats.harvests or 0) + 1
	data.stats.harvests = harvests
	local guaranteed = FirstSessionConfig.guaranteedTiers[harvests]
	if guaranteed then
		return guaranteed
	end
	return rolledTier
end

function FirstSession.onSusChanged(player: Player, updated: number, previous: number?)
	local data = getData(player)
	if not data then
		return
	end
	if not data.story then
		data.story = { chapter = 0, flags = {} }
	end
	if not data.story.flags then
		data.story.flags = {}
	end
	local prev = previous or 0
	if not data.story.flags["sus_explained"] and updated > 0 and prev == 0 then
		data.story.flags["sus_explained"] = true
		Notify.send(player, "sus_explain")
	end
end

function FirstSession.tick(player: Player, elapsedSessionTime: number?)
	local data = getData(player)
	if not data then
		return
	end
	if not data.story then
		data.story = { chapter = 0, flags = {} }
	end
	if not data.story.flags then
		data.story.flags = {}
	end

	local elapsed = elapsedSessionTime
	if elapsed == nil then
		local joinTime = joinTimes[player] or os.time()
		elapsed = os.time() - joinTime
	end

	local finished = isFinished(data)
	if not data.story.flags["beat_bayarlater"] and (elapsed >= FirstSessionConfig.bayarlaterOfferDelay or finished) then
		data.story.flags["beat_bayarlater"] = true
		Notify.send(player, "bayarlater_offer")
		Analytics.funnel(player, "first_session", 5, "bayarlater_offer")
	end

	if not data.story.flags["beat_scripted_raid"] and elapsed >= FirstSessionConfig.scriptedRaidDelay then
		data.story.flags["beat_scripted_raid"] = true
		Notify.send(player, "scripted_raid_gossip")
		Analytics.funnel(player, "first_session", 7, "scripted_raid")
	end

	if not data.story.flags["beat_warung_rumour"] and elapsed >= FirstSessionConfig.warungRumourDelay then
		data.story.flags["beat_warung_rumour"] = true
		Notify.send(player, "warung_rumour")
		Analytics.funnel(player, "first_session", 8, "warung_rumour")
	end
end

function FirstSession.onRankUp(player: Player, newRank: string)
	local data = getData(player)
	if not data then
		return
	end
	if not data.story then
		data.story = { chapter = 0, flags = {} }
	end
	if not data.story.flags then
		data.story.flags = {}
	end

	if newRank == "petani" and not data.story.flags["beat_ceremony"] then
		data.story.flags["beat_ceremony"] = true
		Notify.send(player, "ceremony_petani")
		Analytics.funnel(player, "first_session", 9, "rankup_petani")
	end
end

function FirstSession.start()
	local function trackPlayer(player: Player)
		joinTimes[player] = os.time()
	end

	for _, player in Players:GetPlayers() do
		trackPlayer(player)
	end
	Players.PlayerAdded:Connect(trackPlayer)
	Players.PlayerRemoving:Connect(function(player)
		joinTimes[player] = nil
	end)

	task.spawn(function()
		while true do
			task.wait(5)
			for _, player in Players:GetPlayers() do
				FirstSession.tick(player)
			end
		end
	end)
end

return FirstSession
