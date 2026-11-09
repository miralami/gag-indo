-- EconomyService: the ONLY code that changes cash, seeds, harvest sacks and rank.
-- Also mirrors those values onto player attributes so the client HUD can read them.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Crops = require(Shared.Config.Crops)
local GameConfig = require(Shared.Config.Game)
local Remotes = require(Shared.Remotes)

local PlayerData = require(script.Parent.Parent.Data.PlayerData)
local RateLimit = require(script.Parent.Parent.Net.RateLimit)
local PlotService = require(script.Parent.Parent.Farm.PlotService)

local EconomyService = {}

local function notify(player: Player, key: string, ...: any)
	Remotes.Notify:FireClient(player, key, { ... })
end
EconomyService.notify = notify

local function isFiniteNumber(n: any): boolean
	return type(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge
end

local function near(player: Player, position: Vector3, maxDistance: number): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return root ~= nil and (root.Position - position).Magnitude <= maxDistance
end
EconomyService.near = near

function EconomyService.hasRank(data, rank: string): boolean
	return (GameConfig.rankIndex[data.rank] or 1) >= (GameConfig.rankIndex[rank] or 1)
end

-- Mirror save data onto attributes (read-only for the client; the server ignores client attributes).
function EconomyService.sync(player: Player)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	player:SetAttribute("Cash", data.cash)
	player:SetAttribute("LifetimeEarned", data.lifetimeEarned)
	player:SetAttribute("Rank", data.rank)
	player:SetAttribute("TilesOwned", data.tilesOwned)
	local bag = 0
	for _, cropId in Crops.order do
		player:SetAttribute("Seed_" .. cropId, data.seeds[cropId] or 0)
		local sack = data.harvest[cropId]
		bag += if sack then sack.count else 0
	end
	player:SetAttribute("HarvestCount", bag)
end

local function updateRank(player: Player, data)
	local current = GameConfig.rankIndex[data.rank] or 1
	for i = current + 1, #GameConfig.rankOrder do
		local rank = GameConfig.rankOrder[i]
		local req = GameConfig.rankRequirements[rank]
		if data.lifetimeEarned >= req.lifetimeEarned and data.tilesOwned >= req.tilesOwned then
			data.rank = rank
			notify(player, "n_rank_up", "@rank_" .. rank)
		else
			break
		end
	end
end

-- earned = true when this is income (counts toward lifetimeEarned / ranks)
function EconomyService.addCash(player: Player, amount: number, earned: boolean)
	local data = PlayerData.get(player)
	if not data or not isFiniteNumber(amount) or amount <= 0 then
		return
	end
	amount = math.floor(amount)
	data.cash += amount
	if earned then
		data.lifetimeEarned += amount
		updateRank(player, data)
	end
	EconomyService.sync(player)
end

-- Returns true and deducts if the player can afford it.
function EconomyService.trySpend(player: Player, amount: number): boolean
	local data = PlayerData.get(player)
	if not data or not isFiniteNumber(amount) or amount < 0 then
		return false
	end
	amount = math.floor(amount)
	if data.cash < amount then
		notify(player, "n_not_enough_cash")
		return false
	end
	data.cash -= amount
	EconomyService.sync(player)
	return true
end

-- Re-check rank requirements that depend on things other than income (e.g. tiles owned).
function EconomyService.refreshRank(player: Player)
	local data = PlayerData.get(player)
	if data then
		updateRank(player, data)
		EconomyService.sync(player)
	end
end

function EconomyService.addHarvest(player: Player, cropId: string, quality: number, hot: boolean)
	local data = PlayerData.get(player)
	if not data or not Crops.list[cropId] then
		return
	end
	local sack = data.harvest[cropId]
	if not sack then
		sack = { count = 0, qualitySum = 0, hotCount = 0 }
		data.harvest[cropId] = sack
	end
	sack.count += 1
	sack.qualitySum += quality
	if hot then
		sack.hotCount += 1
	end
	EconomyService.sync(player)
end

-- Legal sale at the Pasar. (Black-market channel arrives in week 3.)
function EconomyService.sellAll(player: Player)
	if not RateLimit.allow(player, "sell", 2) then
		return
	end
	local data = PlayerData.get(player)
	if not data then
		return
	end
	if not near(player, PlotService.getPasarPosition(), GameConfig.interactDistance) then
		return
	end
	local total = 0
	for cropId, sack in data.harvest do
		local crop = Crops.list[cropId]
		if crop and sack.count > 0 then
			total += crop.sellPrice * sack.qualitySum -- qualitySum = sum of per-item multipliers
		end
	end
	if total <= 0 then
		notify(player, "n_nothing_to_sell")
		return
	end
	data.harvest = {}
	EconomyService.addCash(player, total, true)
	notify(player, "n_sold", math.floor(total))
end

local function onBuySeed(player: Player, cropId: any, amount: any)
	if not RateLimit.allow(player, "Shop_BuySeed", 4) then
		return
	end
	if type(cropId) ~= "string" or type(amount) ~= "number" then
		return
	end
	local crop = Crops.list[cropId]
	if not crop or amount ~= math.floor(amount) or amount < 1 or amount > GameConfig.maxSeedBuy then
		return
	end
	local data = PlayerData.get(player)
	if not data then
		return
	end
	if not EconomyService.hasRank(data, crop.rank) then
		notify(player, "n_rank_locked", "@rank_" .. crop.rank)
		return
	end
	if not EconomyService.trySpend(player, crop.seedCost * amount) then
		return
	end
	data.seeds[cropId] = (data.seeds[cropId] or 0) + amount
	EconomyService.sync(player)
	notify(player, "n_bought_seeds", amount, "@crop_" .. cropId)
end

function EconomyService.start()
	Remotes.Shop_BuySeed.OnServerEvent:Connect(onBuySeed)
	PlotService.onPasarPrompt(EconomyService.sellAll)
	PlayerData.onLoaded(function(player)
		EconomyService.sync(player)
	end)
end

return EconomyService
