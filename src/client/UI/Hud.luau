-- HUD: cash / rank / sack / Sus / Nama Baik, the seed bar and the seed shop.
-- Reads player attributes set by the server; sends only requests (select seed, buy seeds).

local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Crops = require(Shared.Config.Crops)
local GameConfig = require(Shared.Config.Game)
local Strings = require(Shared.Strings)
local Remotes = require(Shared.Remotes)

local Theme = require(script.Parent.Theme)

local player = Players.LocalPlayer

local Hud = {}

local function susColor(sus: number): Color3
	if sus >= 80 then
		return Theme.red
	elseif sus >= 60 then
		return Color3.fromRGB(230, 120, 40)
	elseif sus >= 30 then
		return Theme.accent
	end
	return Theme.green
end

function Hud.mount(lang: string)
	local t = function(key: string, ...: any): string
		return Strings.get(lang, key, ...)
	end

	local gui = Theme.screenGui("Hud", 10)

	---------------------------------------------------------------- stats (top-left)
	local stats = Theme.card({
		Name = "Stats",
		Position = UDim2.new(0, 10, 0, 10),
		Size = UDim2.new(0.34, 0, 0.2, 0),
		BackgroundTransparency = 0.12,
		Parent = gui,
	}, {
		Theme.new("UISizeConstraint", { MinSize = Vector2.new(190, 96), MaxSize = Vector2.new(330, 150) }),
	})

	-- Theme.card already created the frame; add padding to it explicitly.
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.PaddingTop = UDim.new(0, 6)
	padding.PaddingBottom = UDim.new(0, 6)
	padding.Parent = stats
	Theme.new("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 2),
		Parent = stats,
	})

	local cashLabel = Theme.label({
		LayoutOrder = 1,
		Size = UDim2.fromScale(1, 0.36),
		TextColor3 = Theme.accent,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = stats,
	})
	local rankLabel = Theme.label({
		LayoutOrder = 2,
		Size = UDim2.fromScale(1, 0.2),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = stats,
	})
	local sackLabel = Theme.label({
		LayoutOrder = 3,
		Size = UDim2.fromScale(1, 0.18),
		TextColor3 = Theme.muted,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = stats,
	})

	local chips = Theme.new("Frame", {
		LayoutOrder = 4,
		Size = UDim2.fromScale(1, 0.26),
		BackgroundTransparency = 1,
		Parent = stats,
	}, {
		Theme.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
		}),
	})

	local susLabel = Theme.label({
		LayoutOrder = 1,
		Size = UDim2.fromScale(0.45, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = chips,
	})
	local namaBaikLabel = Theme.label({
		LayoutOrder = 2,
		Size = UDim2.fromScale(0.45, 1),
		TextColor3 = Color3.fromRGB(120, 210, 240),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = chips,
	})

	local function refreshStats()
		cashLabel.Text = "Rp " .. Strings.formatNumber(player:GetAttribute("Cash") or 0, lang)
		rankLabel.Text = t("hud_rank", "@rank_" .. (player:GetAttribute("Rank") or "gurem"))
		sackLabel.Text = t("hud_harvest_bag", player:GetAttribute("HarvestCount") or 0)
		local sus = player:GetAttribute("Sus") or 0
		susLabel.Text = t("hud_sus", sus)
		susLabel.TextColor3 = susColor(sus)
		namaBaikLabel.Text = t("hud_namabaik", player:GetAttribute("NamaBaik") or 50)
	end

	---------------------------------------------------------------- seed bar (bottom)
	local seedBar = Theme.new("Frame", {
		Name = "SeedBar",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -12),
		Size = UDim2.new(0.72, 0, 0.1, 0),
		BackgroundTransparency = 1,
		Parent = gui,
	}, {
		Theme.new("UISizeConstraint", { MinSize = Vector2.new(320, 52), MaxSize = Vector2.new(640, 76) }),
		Theme.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0.02, 0),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	local seedButtons: { [string]: TextButton } = {}
	for i, cropId in Crops.order do
		local button = Theme.button({
			Name = cropId,
			LayoutOrder = i,
			Size = UDim2.fromScale(0.23, 1),
			Parent = seedBar,
		})
		Theme.new("UIStroke", {
			Name = "Selected",
			Color = Theme.accent,
			Thickness = 3,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Enabled = false,
			Parent = button,
		})
		button.Activated:Connect(function()
			Remotes.Farm_SelectSeed:FireServer(cropId)
		end)
		seedButtons[cropId] = button
	end

	local function hasRank(rank: string): boolean
		local mine = GameConfig.rankIndex[player:GetAttribute("Rank") or "gurem"] or 1
		return mine >= (GameConfig.rankIndex[rank] or 1)
	end

	local function refreshSeeds()
		local selected = player:GetAttribute("SelectedSeed")
		for cropId, button in seedButtons do
			local crop = Crops.list[cropId]
			local unlocked = hasRank(crop.rank)
			button.Text = if unlocked
				then t("hud_seed_count", "@crop_" .. cropId, player:GetAttribute("Seed_" .. cropId) or 0)
				else t("hud_locked", "@crop_" .. cropId)
			button.TextColor3 = if unlocked then Theme.text else Theme.muted
			button.BackgroundColor3 = if unlocked
				then crop.color:Lerp(Color3.new(0, 0, 0), 0.55)
				else Color3.fromRGB(50, 50, 50)
			local stroke = button:FindFirstChild("Selected") :: UIStroke?
			if stroke then
				stroke.Enabled = selected == cropId
			end
		end
	end

	---------------------------------------------------------------- buttons (top-right)
	local buttonColumn = Theme.new("Frame", {
		Name = "Buttons",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 10),
		Size = UDim2.new(0.2, 0, 0.16, 0),
		BackgroundTransparency = 1,
		Parent = gui,
	}, {
		Theme.new("UISizeConstraint", { MinSize = Vector2.new(120, 96), MaxSize = Vector2.new(190, 150) }),
		Theme.new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) }),
	})

	local shopButton = Theme.button({
		Name = "ShopButton",
		LayoutOrder = 1,
		Size = UDim2.fromScale(1, 0.5),
		BackgroundColor3 = Theme.green,
		Text = t("hud_shop_button"),
		Parent = buttonColumn,
	})

	---------------------------------------------------------------- shop
	local shop = Theme.card({
		Name = "Shop",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.6, 0.62),
		Visible = false,
		Parent = gui,
	}, {
		Theme.new("UISizeConstraint", { MinSize = Vector2.new(300, 300), MaxSize = Vector2.new(560, 460) }),
		Theme.new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0.015, 0) }),
	})
	local shopPadding = Instance.new("UIPadding")
	shopPadding.PaddingLeft = UDim.new(0, 12)
	shopPadding.PaddingRight = UDim.new(0, 12)
	shopPadding.PaddingTop = UDim.new(0, 10)
	shopPadding.PaddingBottom = UDim.new(0, 10)
	shopPadding.Parent = shop

	Theme.label({
		LayoutOrder = 0,
		Size = UDim2.fromScale(1, 0.11),
		Text = "🌱 " .. t("hud_shop"),
		TextColor3 = Theme.accent,
		Parent = shop,
	})

	local shopRows: { [string]: { name: TextLabel, buy1: TextButton, buy10: TextButton } } = {}
	for i, cropId in Crops.order do
		local row = Theme.new("Frame", {
			LayoutOrder = i,
			Size = UDim2.fromScale(1, 0.16),
			BackgroundTransparency = 1,
			Parent = shop,
		})
		local name = Theme.label({
			Size = UDim2.fromScale(0.3, 1),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row,
		})
		local buy1 = Theme.button({
			Position = UDim2.fromScale(0.31, 0),
			Size = UDim2.fromScale(0.33, 1),
			Parent = row,
		})
		local buy10 = Theme.button({
			Position = UDim2.fromScale(0.66, 0),
			Size = UDim2.fromScale(0.34, 1),
			Parent = row,
		})
		buy1.Activated:Connect(function()
			Remotes.Shop_BuySeed:FireServer(cropId, 1)
		end)
		buy10.Activated:Connect(function()
			Remotes.Shop_BuySeed:FireServer(cropId, 10)
		end)
		shopRows[cropId] = { name = name, buy1 = buy1, buy10 = buy10 }
	end

	local close = Theme.button({
		LayoutOrder = 99,
		Size = UDim2.fromScale(1, 0.11),
		Text = t("hud_close"),
		BackgroundColor3 = Theme.red,
		Parent = shop,
	})
	close.Activated:Connect(function()
		shop.Visible = false
	end)
	shopButton.Activated:Connect(function()
		shop.Visible = not shop.Visible
	end)

	local function refreshShop()
		for cropId, row in shopRows do
			local crop = Crops.list[cropId]
			local unlocked = hasRank(crop.rank)
			row.name.Text = t("crop_" .. cropId)
			if unlocked then
				row.buy1.Text = t("shop_buy", 1, crop.seedCost)
				row.buy10.Text = t("shop_buy", 10, crop.seedCost * 10)
			else
				row.buy1.Text = t("shop_needs_rank", "@rank_" .. crop.rank)
				row.buy10.Text = "🔒"
			end
			row.buy1.Active = unlocked
			row.buy10.Active = unlocked
			row.buy1.BackgroundTransparency = if unlocked then 0 else 0.5
			row.buy10.BackgroundTransparency = if unlocked then 0 else 0.5
		end
	end

	---------------------------------------------------------------- notifications
	Remotes.Notify.OnClientEvent:Connect(function(key: string, params: { any }?)
		if type(key) ~= "string" then
			return
		end
		Theme.toast(Strings.get(lang, key, table.unpack(params or {})))
	end)

	---------------------------------------------------------------- wiring
	local function refreshAll()
		refreshStats()
		refreshSeeds()
		refreshShop()
	end
	player.AttributeChanged:Connect(refreshAll)
	refreshAll()

	return gui
end

return Hud
