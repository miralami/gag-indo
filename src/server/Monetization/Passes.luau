-- Passes: game-pass benefits become server-owned attributes (TECH.md §7).
-- Other services read only the attributes, never MarketplaceService.

local MarketplaceService = game:GetService("MarketplaceService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Products = require(Shared.Config.Products)

local PlayerData = require(script.Parent.Parent.Data.PlayerData)
local Notify = require(script.Parent.Parent.Net.Notify)
local FarmService = require(script.Parent.Parent.Farm.FarmService)

local Passes = {}

local function grant(player: Player, passKey: string)
	local pass = Products.passes[passKey]
	if not pass then
		return
	end
	player:SetAttribute(pass.attribute, true)
	if passKey == "extraPlot" then
		FarmService.refresh(player)
	end
	Notify.send(player, "n_purchase", "@pass_" .. passKey)
end

function Passes.has(player: Player, passKey: string): boolean
	local pass = Products.passes[passKey]
	return pass ~= nil and player:GetAttribute(pass.attribute) == true
end

local function checkPasses(player: Player)
	for passKey, pass in Products.passes do
		if pass.id > 0 then
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.id)
			end)
			if ok and owns then
				player:SetAttribute(pass.attribute, true)
			end
		end
	end
	if player:GetAttribute("Pass_ExtraPlot") then
		FarmService.refresh(player)
	end
end

function Passes.start()
	PlayerData.onLoaded(function(player)
		checkPasses(player)
	end)

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, wasPurchased)
		if not wasPurchased then
			return
		end
		for passKey, pass in Products.passes do
			if pass.id > 0 and pass.id == passId then
				grant(player, passKey)
				return
			end
		end
	end)
end

return Passes
