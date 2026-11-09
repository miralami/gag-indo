-- EvidenceService: server-decided proof tokens, Lapor and VIRAL (GDD §6, TECH.md §6).
-- Only server-logged cheat events can be recorded, so a report can never be faked.
-- Tokens live in memory (not saved) and expire after 180 s.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.Config.Game)
local Law = require(Shared.Config.Law)
local Remotes = require(Shared.Remotes)

local PlayerData = require(script.Parent.Parent.Data.PlayerData)
local RateLimit = require(script.Parent.Parent.Net.RateLimit)
local Notify = require(script.Parent.Parent.Net.Notify)
local EconomyService = require(script.Parent.Parent.Economy.EconomyService)
local RankService = require(script.Parent.Parent.Progression.RankService)
local SusService = require(script.Parent.SusService)
local RaidService = require(script.Parent.RaidService)
local Village = require(script.Parent.Parent.World.Village)
local Analytics = require(script.Parent.Parent.Analytics.Analytics)

local EvidenceService = {}

type CheatEvent = {
	id: string,
	cheaterUserId: number,
	cheaterName: string,
	cheatId: string,
	value: number,
	position: Vector3,
	createdAt: number,
	expiresAt: number,
	reporters: { [number]: number },
	firstReporter: number?,
}

type Token = {
	id: string,
	ownerUserId: number,
	eventId: string,
	expiresAt: number,
}

local events: { [string]: CheatEvent } = {}
local offers: { [number]: { [string]: number } } = {} -- [userId][eventId] = expiresAt
local tokens: { [string]: Token } = {}
-- Distinct reporters per cheater (for VIRAL across several cheat events).
local reportersByCheater: { [number]: { [number]: number } } = {}

local function rootPosition(player: Player): Vector3?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return if root then root.Position else nil
end

local function near(player: Player, position: Vector3, maxDistance: number): boolean
	local at = rootPosition(player)
	return at ~= nil and (at - position).Magnitude <= maxDistance
end

local function offerTo(player: Player, event: CheatEvent)
	if player.UserId == event.cheaterUserId then
		return
	end
	local bucket = offers[player.UserId]
	if not bucket then
		bucket = {}
		offers[player.UserId] = bucket
	end
	bucket[event.id] = event.expiresAt
	Remotes.Evidence_Offer:FireClient(player, event.id, event.cheaterName, event.cheatId, event.expiresAt)
end

-- Create a reportable event and offer it to witnesses (and always to the victim).
function EvidenceService.logCheat(
	cheater: Player,
	cheatId: string,
	value: number,
	position: Vector3?,
	victim: Player?
)
	local data = PlayerData.get(cheater)
	if not data then
		return
	end
	local at = position or rootPosition(cheater) or Vector3.new(0, 0, 0)
	local now = os.time()
	local event: CheatEvent = {
		id = HttpService:GenerateGUID(false),
		cheaterUserId = cheater.UserId,
		cheaterName = cheater.DisplayName,
		cheatId = cheatId,
		value = math.max(0, math.floor(value)),
		position = at,
		createdAt = now,
		expiresAt = now + Law.evidenceTokenSeconds,
		reporters = {},
		firstReporter = nil,
	}
	events[event.id] = event
	data.stats.cheats = (data.stats.cheats or 0) + 1

	for _, player in Players:GetPlayers() do
		if player ~= cheater and near(player, at, Law.evidenceRadius) then
			offerTo(player, event)
		end
	end
	if victim and victim.Parent == Players and victim ~= cheater then
		offerTo(victim, event) -- the water-theft victim always gets a token
	end
end

local function tokenFor(player: Player, event: CheatEvent): string
	local tokenId = HttpService:GenerateGUID(false)
	tokens[tokenId] = {
		id = tokenId,
		ownerUserId = player.UserId,
		eventId = event.id,
		expiresAt = event.expiresAt,
	}
	Remotes.Evidence_Token:FireClient(player, tokenId, event.cheatId, event.expiresAt)
	return tokenId
end

local function onRecord(player: Player, eventId: any)
	if not RateLimit.allow(player, "Evidence_Record", 2) then
		return
	end
	if type(eventId) ~= "string" then
		return
	end
	local bucket = offers[player.UserId]
	if not bucket then
		return
	end
	local expiresAt = bucket[eventId]
	if not expiresAt or os.time() > expiresAt then
		bucket[eventId] = nil
		return
	end
	local event = events[eventId]
	if not event then
		bucket[eventId] = nil
		return
	end
	bucket[eventId] = nil
	tokenFor(player, event)
	Notify.send(player, "n_recorded")
end

local function countRecentReporters(cheaterUserId: number, now: number): number
	local reporters = reportersByCheater[cheaterUserId]
	if not reporters then
		return 0
	end
	local count = 0
	for reporterUserId, at in reporters do
		if now - at > Law.viralWindow then
			reporters[reporterUserId] = nil
		else
			count += 1
		end
	end
	return count
end

local function report(player: Player, tokenId: string): boolean
	local data = PlayerData.get(player)
	if not data then
		return false
	end
	local token = tokens[tokenId]
	if not token or token.ownerUserId ~= player.UserId then
		Notify.send(player, "n_token_gone")
		return false
	end
	if os.time() > token.expiresAt then
		tokens[tokenId] = nil
		Remotes.Evidence_Remove:FireClient(player, tokenId)
		Notify.send(player, "n_token_expired")
		return false
	end
	if os.time() < (data.cooldowns.reportReadyAt or 0) then
		Notify.send(player, "n_report_cooldown")
		return false
	end
	if not near(player, Village.getPosition("polisi"), GameConfig.npcDistance) then
		Notify.send(player, "n_report_near")
		return false
	end

	local event = events[token.eventId]
	if not event then
		tokens[tokenId] = nil
		Remotes.Evidence_Remove:FireClient(player, tokenId)
		Notify.send(player, "n_token_expired")
		return false
	end

	local cheater = Players:GetPlayerByUserId(event.cheaterUserId)
	local cheaterData = if cheater then PlayerData.get(cheater) else nil
	if not cheater or not cheaterData then
		-- GDD: if the cheater already left, the report counts for nothing in v1.
		tokens[tokenId] = nil
		Remotes.Evidence_Remove:FireClient(player, tokenId)
		Notify.send(player, "n_token_expired")
		return false
	end

	tokens[tokenId] = nil
	Remotes.Evidence_Remove:FireClient(player, tokenId)
	data.cooldowns.reportReadyAt = os.time() + Law.reportCooldown

	local now = os.time()
	event.reporters[player.UserId] = now
	local reporterMap = reportersByCheater[cheater.UserId]
	if not reporterMap then
		reporterMap = {}
		reportersByCheater[cheater.UserId] = reporterMap
	end
	reporterMap[player.UserId] = now

	local reward = 0
	if event.firstReporter == nil then
		event.firstReporter = player.UserId
		local share = math.floor(event.value * Law.reporterRewardShare)
		reward = EconomyService.transfer(cheater, player, share)
		RankService.addNamaBaik(player, Law.namaBaikPerReport, "report")
		SusService.add(cheater, Law.cheaterSusPerReport, "report")
		data.stats.reportsMade = (data.stats.reportsMade or 0) + 1
		if reward > 0 then
			Notify.send(player, "n_report_ok", reward, Law.namaBaikPerReport)
		else
			Notify.send(player, "n_report_no_cash")
		end
		Analytics.log(player, "report_made", 1)
	else
		data.stats.reportsMade = (data.stats.reportsMade or 0) + 1
		Notify.send(player, "n_report_no_cash")
	end

	cheaterData.stats.timesReported = (cheaterData.stats.timesReported or 0) + 1

	if countRecentReporters(cheater.UserId, now) >= Law.viralReporters then
		RaidService.start(cheater, true)
	end

	return true
end

local function onReport(player: Player, tokenId: any)
	if not RateLimit.allow(player, "Evidence_Report", 1) then
		return
	end
	if type(tokenId) ~= "string" then
		return
	end
	report(player, tokenId)
end

-- Pos Polisi prompt: turn in the oldest valid token, no phone needed.
local function reportOldest(player: Player)
	local now = os.time()
	local bestId: string? = nil
	local bestExpiry = math.huge
	for tokenId, token in tokens do
		if token.ownerUserId == player.UserId and token.expiresAt >= now and token.expiresAt < bestExpiry then
			bestId = tokenId
			bestExpiry = token.expiresAt
		end
	end
	if not bestId then
		Notify.send(player, "n_token_gone")
		return
	end
	onReport(player, bestId)
end

function EvidenceService.tokenCount(player: Player): number
	local count = 0
	for _, token in tokens do
		if token.ownerUserId == player.UserId and token.expiresAt >= os.time() then
			count += 1
		end
	end
	return count
end

function EvidenceService.start()
	Remotes.Evidence_Record.OnServerEvent:Connect(onRecord)
	Remotes.Evidence_Report.OnServerEvent:Connect(onReport)
	Village.onReport(reportOldest)

	-- Expire tokens/offers. Cheap: there are at most a handful alive at once.
	task.spawn(function()
		while true do
			task.wait(5)
			local now = os.time()
			for tokenId, token in tokens do
				if now > token.expiresAt then
					tokens[tokenId] = nil
					local owner = Players:GetPlayerByUserId(token.ownerUserId)
					if owner then
						Remotes.Evidence_Remove:FireClient(owner, tokenId)
						Notify.send(owner, "n_token_expired")
					end
				end
			end
			for userId, bucket in offers do
				for eventId, expiresAt in bucket do
					if now > expiresAt then
						bucket[eventId] = nil
					end
				end
				if next(bucket) == nil then
					offers[userId] = nil
				end
			end
			for _, event in events do
				if now > event.expiresAt + 60 then
					events[event.id] = nil
				end
			end
			for cheaterUserId in reportersByCheater do
				countRecentReporters(cheaterUserId, now)
			end
		end
	end)
end

Players.PlayerRemoving:Connect(function(player)
	offers[player.UserId] = nil
	local pending = {}
	for tokenId, token in tokens do
		if token.ownerUserId == player.UserId then
			table.insert(pending, tokenId)
		end
	end
	for _, tokenId in pending do
		tokens[tokenId] = nil
	end
end)

return EvidenceService
