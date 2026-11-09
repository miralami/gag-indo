-- Cosmetics: a small cash shop (GDD §9.3). Buying/equipping is server-owned and the
-- cosmetic part is built on the server so every player sees it.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local CosmeticsConfig = require(Shared.Config.Cosmetics)
local Remotes = require(Shared.Remotes)

local PlayerData = require(script.Parent.Parent.Data.PlayerData)
local RateLimit = require(script.Parent.Parent.Net.RateLimit)
local Notify = require(script.Parent.Parent.Net.Notify)
local EconomyService = require(script.Parent.Parent.Economy.EconomyService)

local Cosmetics = {}

local HAT_NAME = "CosmeticHat"
local VEST_NAME = "CosmeticVest"

local function removeVisuals(character: Model)
	for _, name in { HAT_NAME, VEST_NAME } do
		local existing = character:FindFirstChild(name)
		if existing then
			existing:Destroy()
		end
	end
end

local function weld(part: BasePart, parentPart: BasePart)
	part.Anchored = false
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.Parent = parentPart.Parent
	local constraint = Instance.new("WeldConstraint")
	constraint.Part0 = parentPart
	constraint.Part1 = part
	constraint.Parent = part
end

local function applyVisual(player: Player)
	local data = PlayerData.get(player)
	local character = player.Character
	if not data or not character then
		return
	end
	removeVisuals(character)

	local itemId = data.equipped.cosmetic
	local item = if itemId then CosmeticsConfig.list[itemId] else nil
	if not item then
		return
	end

	if item.kind == "hat" then
		local head = character:FindFirstChild("Head") :: BasePart?
		if not head then
			return
		end
		local hat = Instance.new("Part")
		hat.Name = HAT_NAME
		hat.Color = item.color
		hat.Material = Enum.Material.Fabric
		hat.TopSurface = Enum.SurfaceType.Smooth
		hat.BottomSurface = Enum.SurfaceType.Smooth
		if itemId == "caping" then
			hat.Shape = Enum.PartType.Cylinder
			hat.Size = Vector3.new(0.22, 3.6, 3.6)
			hat.CFrame = head.CFrame * CFrame.new(0, head.Size.Y / 2 + 0.12, 0) * CFrame.Angles(0, 0, math.rad(90))
			hat.Material = Enum.Material.Wood
		else
			hat.Size = Vector3.new(1.7, 0.7, 1.7)
			hat.CFrame = head.CFrame * CFrame.new(0, head.Size.Y / 2 + 0.3, 0)
		end
		weld(hat, head)
	elseif item.kind == "shirt" then
		local torso = (character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")) :: BasePart?
		if not torso then
			return
		end
		local vest = Instance.new("Part")
		vest.Name = VEST_NAME
		vest.Color = item.color
		vest.Material = Enum.Material.Fabric
		vest.Transparency = 0.1
		vest.Size = torso.Size + Vector3.new(0.16, 0.12, 0.16)
		vest.CFrame = torso.CFrame
		weld(vest, torso)
	end
end

function Cosmetics.sync(player: Player)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	for itemId in CosmeticsConfig.list do
		player:SetAttribute("Cosmetic_" .. itemId, data.cosmetics[itemId] == true)
	end
	player:SetAttribute("EquippedCosmetic", data.equipped.cosmetic or "")
	applyVisual(player)
end

local function onBuy(player: Player, itemId: any)
	if not RateLimit.allow(player, "Cosmetic_Buy", 2) then
		return
	end
	if type(itemId) ~= "string" then
		return
	end
	local item = CosmeticsConfig.list[itemId]
	local data = PlayerData.get(player)
	if not item or not data then
		return
	end
	if data.cosmetics[itemId] then
		Notify.send(player, "phone_owned")
		return
	end
	if not EconomyService.trySpend(player, item.price) then
		return
	end
	data.cosmetics[itemId] = true
	Cosmetics.sync(player)
	Notify.send(player, "n_cosmetic_bought", "@cosmetic_" .. itemId)
end

local function onEquip(player: Player, itemId: any)
	if not RateLimit.allow(player, "Cosmetic_Equip", 4) then
		return
	end
	local data = PlayerData.get(player)
	if not data then
		return
	end
	if itemId == nil or itemId == "" then
		data.equipped.cosmetic = nil
		Cosmetics.sync(player)
		return
	end
	if type(itemId) ~= "string" or not CosmeticsConfig.list[itemId] then
		return
	end
	if not data.cosmetics[itemId] then
		return
	end
	data.equipped.cosmetic = itemId
	Cosmetics.sync(player)
	Notify.send(player, "n_cosmetic_equipped", "@cosmetic_" .. itemId)
end

function Cosmetics.start()
	Remotes.Cosmetic_Buy.OnServerEvent:Connect(onBuy)
	Remotes.Cosmetic_Equip.OnServerEvent:Connect(onEquip)
	PlayerData.onLoaded(function(player)
		Cosmetics.sync(player)
		player.CharacterAdded:Connect(function(character)
			task.wait(0.3) -- let the character finish assembling
			if character.Parent then
				applyVisual(player)
			end
		end)
	end)
end

return Cosmetics
