-- StorageService: owns `data.gudang` (v2 PLAN §3.4).
--
-- The gudang lets a player park clean produce until the Pasar price recovers, and it frees sack
-- space for the next harvest. Hot (oplosan) produce is refused: a raid must never be dodged by
-- moving the evidence into a shed.
--
-- The capacity is stored in the save so the Gudang Besar pass can raise it later without a
-- migration; it never shrinks below today's base capacity.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.Config.Game)
local Remotes = require(Shared.Remotes)
local Produce = require(Shared.Produce)

local PlayerData = require(script.Parent.Parent.Data.PlayerData)
local RateLimit = require(script.Parent.Parent.Net.RateLimit)
local Notify = require(script.Parent.Parent.Net.Notify)
local State = require(script.Parent.Parent.Net.State)
local EconomyService = require(script.Parent.Parent.Economy.EconomyService)

local StorageService = {}

local MOVE_RATE = 3
local depositHook: ((Player, number) -> ())? = nil

function StorageService.onDeposit(hook: (Player, number) -> ())
	depositHook = hook
end

local function baseCapacity(player: Player?): number
	return if player and player:GetAttribute("Pass_GudangBesar")
		then GameConfig.gudangPassCapacity
		else GameConfig.gudangBaseCapacity
end

-- Make sure the gudang table exists without changing stored capacity semantics.
local function ensureGudang(data)
	data.gudang = data.gudang or { stacks = {} }
	data.gudang.stacks = data.gudang.stacks or {}
	if data.gudang.capacity == nil then
		data.gudang.capacity = GameConfig.gudangBaseCapacity
	end
	return data.gudang
end

local function stacks(data): { [string]: any }
	return ensureGudang(data).stacks
end

function StorageService.capacity(player: Player, data): number
	local base = baseCapacity(player)
	if not data then
		return base
	end
	local gudang = data.gudang
	local stored = if gudang and gudang.capacity ~= nil then tonumber(gudang.capacity) else base
	if not stored or stored ~= stored or stored == math.huge or stored == -math.huge then
		stored = base
	end
	stored = math.floor(stored)
	-- Read-only: never mutates save. Removing a pass must not destroy stored items.
	return math.max(base, stored)
end

function StorageService.used(data): number
	local gudang = data and data.gudang
	if not gudang or not gudang.stacks then
		return 0
	end
	return Produce.count(gudang.stacks)
end

-- Move one stack amount into another sack, keeping the average quality.
local function moveStack(fromSack, toSack, key: string, stack, amount: number)
	local average = if stack.count > 0 then stack.qualitySum / stack.count else 0
	local target = toSack[key]
	if not target then
		target = {
			crop = stack.crop,
			tier = stack.tier,
			traits = table.clone(stack.traits or {}),
			count = 0,
			qualitySum = 0,
		}
		toSack[key] = target
	end
	target.count += amount
	target.qualitySum += average * amount

	stack.count -= amount
	stack.qualitySum -= average * amount
	if stack.count <= 0 then
		fromSack[key] = nil
	end
end

local function sortedKeys(sack): { string }
	local keys = {}
	for key in sack do
		table.insert(keys, key)
	end
	table.sort(keys)
	return keys
end

function StorageService.publish(player: Player, data)
	if data then
		ensureGudang(data)
	end
	player:SetAttribute("GudangUsed", StorageService.used(data))
	player:SetAttribute("GudangCapacity", StorageService.capacity(player, data))
end

local function afterMove(player: Player, data)
	StorageService.publish(player, data)
	EconomyService.sync(player)
	State.touch(player, "produce")
	State.touch(player, "gudang")
end

-- Moves as much clean produce as fits. Returns how many items moved.
function StorageService.depositAll(player: Player): number
	local data = PlayerData.get(player)
	if not data then
		return 0
	end
	local free = StorageService.capacity(player, data) - StorageService.used(data)
	if free <= 0 then
		Notify.send(player, "n_gudang_full")
		return 0
	end

	local sack = data.produce or {}
	local shed = stacks(data)
	local moved = 0
	for _, key in sortedKeys(sack) do
		if free <= 0 then
			break
		end
		local stack = sack[key]
		if stack and stack.count > 0 and not Produce.isHot(stack) then
			local amount = math.min(stack.count, free)
			moveStack(sack, shed, key, stack, amount)
			free -= amount
			moved += amount
		end
	end

	if moved <= 0 then
		Notify.send(player, "n_gudang_nothing")
		return 0
	end
	afterMove(player, data)
	Notify.send(player, "n_gudang_deposit", moved)
	if depositHook then
		depositHook(player, moved)
	end
	return moved
end

-- Moves everything back into the sack. Returns how many items moved.
function StorageService.withdrawAll(player: Player): number
	local data = PlayerData.get(player)
	if not data then
		return 0
	end
	local shed = stacks(data)
	if type(data.produce) ~= "table" then
		data.produce = {}
	end
	local sack = data.produce
	local moved = 0
	for _, key in sortedKeys(shed) do
		local stack = shed[key]
		if stack and stack.count > 0 then
			local amount = stack.count
			moveStack(shed, sack, key, stack, amount)
			moved += amount
		end
	end
	if moved <= 0 then
		Notify.send(player, "n_gudang_empty")
		return 0
	end
	afterMove(player, data)
	Notify.send(player, "n_gudang_withdraw", moved)
	return moved
end

function StorageService.start()
	Remotes.Storage_Deposit.OnServerEvent:Connect(function(player)
		if RateLimit.allow(player, "Storage_Deposit", MOVE_RATE) then
			StorageService.depositAll(player)
		end
	end)
	Remotes.Storage_Withdraw.OnServerEvent:Connect(function(player)
		if RateLimit.allow(player, "Storage_Withdraw", MOVE_RATE) then
			StorageService.withdrawAll(player)
		end
	end)

	PlayerData.onLoaded(function(player, data)
		StorageService.publish(player, data)
		State.touch(player, "gudang")
	end)
end

return StorageService
