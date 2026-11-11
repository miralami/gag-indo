-- RaidService: per-player raid state machine (GDD §5.3, TECH.md §6).
--   idle -> incoming (police walk, overlay) -> choosing (20 s) -> resolving -> cooldown
-- A player who leaves mid-raid is fined in PlayerData's beforeRelease hook.
--
-- Sus is owned by SusService, so this module receives a tiny API via bindSus() in Main
-- (that keeps SusService -> RaidService a one-way dependency).

local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Law = require(Shared.Config.Law)
local Remotes = require(Shared.Remotes)

local PlayerData = require(script.Parent.Parent.Data.PlayerData)
local Notify = require(script.Parent.Parent.Net.Notify)
local RateLimit = require(script.Parent.Parent.Net.RateLimit)
local EconomyService = require(script.Parent.Parent.Economy.EconomyService)
local RankService = require(script.Parent.Parent.Progression.RankService)
local FarmService = require(script.Parent.Parent.Farm.FarmService)
local PlotService = require(script.Parent.Parent.Farm.PlotService)
local Village = require(script.Parent.Parent.World.Village)
local Analytics = require(script.Parent.Parent.Analytics.Analytics)
local BadgeService = require(script.Parent.Parent.Progression.BadgeService)

local RaidService = {}

type Raid = {
	state: string, -- incoming | choosing | resolving | jail
	isViral: boolean,
	fine: number,
	amplop: number,
	deadline: number,
	jailUntil: number?,
	returnCFrame: CFrame?,
	token: number,
}

local raids: { [Player]: Raid } = {}
local nextToken = 0

local susApi: { set: (Player, number) -> (), add: (Player, number, string?) -> () }? = nil

function RaidService.bindSus(api)
	susApi = api
end

local function isActive(raid: Raid?): boolean
	return raid ~= nil and (raid.state == "incoming" or raid.state == "choosing" or raid.state == "resolving")
end

-- Assigning a literal directly to the field would narrow its type to that one value for the
-- rest of the function; going through a `string` parameter keeps it a plain string.
local function setState(raid: Raid, state: string)
	raid.state = state
end

-- `raid.state == "incoming"` narrows the field for the rest of the scope, which then breaks
-- later comparisons; asking through a function keeps each check independent.
local function isState(raid: Raid, state: string): boolean
	return raid.state == state
end

function RaidService.isBusy(player: Player): boolean
	local raid = raids[player]
	return isActive(raid) or (raid ~= nil and raid.state == "jail")
end

function RaidService.getState(player: Player): string
	local raid = raids[player]
	return if raid then raid.state else "idle"
end

function RaidService.isViral(player: Player): boolean
	local raid = raids[player]
	return raid ~= nil and raid.isViral
end

local function computeAmounts(data): (number, number)
	local cash = data.cash or 0
	local fine = math.clamp(math.floor(cash * Law.finePercent), Law.fineMin, Law.fineMax)
	local amplop = math.max(1, math.floor(cash * Law.amplopPercent))
	return fine, amplop
end

local function policeGoTo(position: Vector3, line: string?)
	local police = Village.police
	for i, npc in police do
		task.spawn(function()
			if line and i == 1 then
				npc:say(line, 4)
			end
			npc:walkTo(position + Vector3.new((i - 1) * 4 - 2, 0, 3), 22)
		end)
	end
end

local function policeReturn()
	task.wait(1.5)
	for _, npc in Village.police do
		task.spawn(function()
			npc:walkTo(npc.homeCFrame.Position, 16)
		end)
	end
end

local function applyOutcomeMessages(player: Player, outcome: string, amount: number)
	if outcome == "denda" then
		Notify.send(player, "n_raid_fine", amount)
	elseif outcome == "amplop" then
		Notify.send(player, "n_raid_amplop_ok")
	elseif outcome == "amplop_fail" then
		Notify.send(player, "n_raid_amplop_fail", amount)
	elseif outcome == "jail" then
		Notify.send(player, "n_raid_jail", Law.jailSeconds)
	end
end

local function resetRaid(player: Player, raid: Raid, outcome: string)
	local data = PlayerData.get(player)
	setState(raid, if outcome == "jail" then "jail" else "cooldown")
	player:SetAttribute("InRaid", false)
	if data then
		data.cooldowns.raidSafeUntil = os.time() + Law.raidCooldown
		data.stats.raids = (data.stats.raids or 0) + 1
		local penalty = if raid.isViral then Law.namaBaikViral else Law.namaBaikCaught
		RankService.addNamaBaik(player, penalty)
	end
	if susApi then
		susApi.set(player, Law.raidResetSus)
	end
	Remotes.Raid_End:FireClient(player, outcome)
	Notify.send(player, "n_raid_over", Law.raidResetSus)
	if outcome ~= "jail" then
		raids[player] = nil
		task.spawn(policeReturn)
	end
end

function RaidService.releaseFromJail(player: Player): boolean
	local raid = raids[player]
	if not raid or not isState(raid, "jail") or not raid.jailUntil then
		return false
	end
	raid.jailUntil = nil
	raids[player] = nil
	player:SetAttribute("InJail", false)
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = 16
		end
		local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root and raid.returnCFrame then
			root.CFrame = raid.returnCFrame + Vector3.new(0, 3, 0)
		end
	end
	Remotes.Jail_State:FireClient(player, 0)
	Notify.send(player, "jail_out")
	task.spawn(policeReturn)
	return true
end

local function sendToJail(player: Player, raid: Raid)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	-- Always start the timer, even if the character is mid-respawn: otherwise the raid
	-- would stay in "jail" forever and block every later raid for this player.
	raid.jailUntil = os.time() + Law.jailSeconds
	setState(raid, "jail")
	player:SetAttribute("InJail", true)
	if character and root then
		raid.returnCFrame = root.CFrame
		root.CFrame = CFrame.new(Village.getPosition("ronda") + Vector3.new(0, 2, 0))
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = 0
		end
	end
	Remotes.Jail_State:FireClient(player, Law.jailSeconds)

	task.spawn(function()
		while raid.jailUntil ~= nil and player.Parent == Players do
			local remaining = raid.jailUntil - os.time()
			Remotes.Jail_State:FireClient(player, math.max(0, remaining))
			if remaining <= 0 then
				RaidService.releaseFromJail(player)
				return
			end
			task.wait(1)
		end
	end)
end

local function resolveChoice(player: Player, choice: string, timedOut: boolean?)
	local raid = raids[player]
	local data = PlayerData.get(player)
	if not raid or not data or raid.state ~= "choosing" then
		return
	end
	if choice == "amplop" and raid.isViral then
		Notify.send(player, "n_viral_case")
		return
	end
	setState(raid, "resolving")
	raid.jailUntil = nil

	if timedOut then
		Notify.send(player, "raid_timeout")
	end

	if choice == "amplop" then
		local cost = raid.amplop
		if data.cash < cost then
			if data.cash > 0 then
				EconomyService.trySpend(player, data.cash)
			end
			applyOutcomeMessages(player, "jail", 0)
			sendToJail(player, raid)
			resetRaid(player, raid, "jail")
			return
		end
		EconomyService.trySpend(player, cost)
		if math.random() < Law.amplopSuccess then
			applyOutcomeMessages(player, "amplop", cost)
			resetRaid(player, raid, "amplop")
		else
			local penalty = math.floor(raid.fine * Law.amplopFailMultiplier)
			if data.cash >= penalty then
				EconomyService.trySpend(player, penalty)
				applyOutcomeMessages(player, "amplop_fail", penalty)
				resetRaid(player, raid, "amplop_fail")
			else
				if data.cash > 0 then
					EconomyService.trySpend(player, data.cash)
				end
				applyOutcomeMessages(player, "jail", 0)
				sendToJail(player, raid)
				resetRaid(player, raid, "jail")
			end
		end
		return
	end

	-- Pay the fine, or go to the guard post when there isn't enough cash.
	if data.cash >= raid.fine then
		EconomyService.trySpend(player, raid.fine)
		applyOutcomeMessages(player, "denda", raid.fine)
		resetRaid(player, raid, "denda")
	else
		if data.cash > 0 then
			EconomyService.trySpend(player, data.cash)
		end
		applyOutcomeMessages(player, "jail", 0)
		sendToJail(player, raid)
		resetRaid(player, raid, "jail")
	end
end

function RaidService.start(player: Player, isViral: boolean)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	local existing = raids[player]
	if isActive(existing) or (existing and existing.state == "jail") then
		return
	end
	local skipCooldown = isViral or (data.sus or 0) >= Law.susMax
	if not skipCooldown and os.time() < (data.cooldowns.raidSafeUntil or 0) then
		return
	end

	local fine, amplop = computeAmounts(data)
	nextToken += 1
	local raid: Raid = {
		state = "incoming",
		isViral = isViral,
		fine = fine,
		amplop = amplop,
		deadline = 0,
		jailUntil = nil,
		returnCFrame = nil,
		token = nextToken,
	}
	raids[player] = raid
	player:SetAttribute("InRaid", true)
	Analytics.log(player, "raid_started", if isViral then 2 else 1)

	-- Confiscate hot produce before the player can sell it.
	local hot = FarmService.confiscateHotTiles(player) + EconomyService.removeHotHarvest(player)
	if hot > 0 then
		Notify.send(player, "n_confiscated", hot)
	end

	Remotes.Raid_Start:FireClient(player, {
		phase = "incoming",
		isViral = isViral,
		fine = fine,
		amplop = amplop,
	})
	Notify.send(player, if isViral then "n_viral" else "n_raid_came")
	BadgeService.award(player, "first_raid")

	local plot = PlotService.getPlotOf(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local target = if plot then plot.spawnCFrame.Position elseif root then root.Position else Vector3.new(0, 0, 0)
	task.spawn(policeGoTo, target, if isViral then "VIRAL! Buka, Pak!" else "Operasi! Buka ladangnya!")

	task.delay(3, function()
		local current = raids[player]
		if current ~= raid or not isState(raid, "incoming") then
			return
		end
		setState(raid, "choosing")
		raid.deadline = os.time() + Law.raidChoiceTimeout
		Remotes.Raid_Start:FireClient(player, {
			phase = "choosing",
			isViral = isViral,
			fine = fine,
			amplop = amplop,
			timeout = Law.raidChoiceTimeout,
		})

		task.delay(Law.raidChoiceTimeout, function()
			local still = raids[player]
			if still == raid and isState(raid, "choosing") then
				resolveChoice(player, "denda", true)
			end
		end)
	end)
end

local function onChoose(player: Player, choice: any)
	if not RateLimit.allow(player, "Raid_Choose", 2) then
		return
	end
	if not PlayerData.get(player) then
		return
	end
	if choice ~= "denda" and choice ~= "amplop" then
		return
	end
	local raid = raids[player]
	if not raid or not isState(raid, "choosing") then
		return
	end
	resolveChoice(player, choice)
end

-- Runs inside PlayerData.beforeRelease: MUST NOT yield.
function RaidService.resolveOnLeave(player: Player, data)
	local raid = raids[player]
	if not raid then
		return
	end
	if isActive(raid) then
		local fine = raid.fine
		data.cash = math.max(0, (data.cash or 0) - fine)
		data.cooldowns.raidSafeUntil = os.time() + Law.raidCooldown
		data.stats.raids = (data.stats.raids or 0) + 1
		local penalty = if raid.isViral then Law.namaBaikViral else Law.namaBaikCaught
		data.namaBaik = math.clamp((data.namaBaik or Law.namaBaikStart) + penalty, 0, Law.namaBaikMax)
	end
	raids[player] = nil
end

function RaidService.init()
	Remotes.Raid_Choose.OnServerEvent:Connect(onChoose)
	PlayerData.onBeforeRelease(RaidService.resolveOnLeave)
end

return RaidService
