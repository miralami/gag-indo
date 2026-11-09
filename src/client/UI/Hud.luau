-- HUD: cash / rank / sack, seed bar, seed shop and toast notifications.
-- Reads player attributes set by the server; sends only requests (select seed, buy seeds).

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Crops = require(Shared.Config.Crops)
local GameConfig = require(Shared.Config.Game)
local Strings = require(Shared.Strings)
local Remotes = require(Shared.Remotes)

local player = Players.LocalPlayer

local FONT = Enum.Font.FredokaOne
local PANEL = Color3.fromRGB(35, 30, 25)
local ACCENT = Color3.fromRGB(240, 180, 40)
local TEXT = Color3.fromRGB(255, 248, 230)
local MUTED = Color3.fromRGB(150, 140, 130)

local Hud = {}

local function new(className: string, props: { [string]: any }, children: { Instance }?): any
	local inst = Instance.new(className)
	for k, v in props do
		if k ~= "Parent" then
			(inst :: any)[k] = v
		end
	end
	if children then
		for _, child in children do
			child.Parent = inst
		end
	end
	if props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

local function corner(radius: number): UICorner
	return new("UICorner", { CornerRadius = UDim.new(0, radius) })
end

local function label(props: { [string]: any }): TextLabel
	props.BackgroundTransparency = props.BackgroundTransparency or 1
	props.Font = FONT
	props.TextColor3 = props.TextColor3 or TEXT
	props.TextScaled = true
	return new("TextLabel", props)
end

local function button(props: { [string]: any }): TextButton
	props.Font = FONT
	props.TextColor3 = props.TextColor3 or TEXT
	props.TextScaled = true
	props.AutoButtonColor = true
	props.BackgroundColor3 = props.BackgroundColor3 or Color3.fromRGB(70, 60, 50)
	local b = new("TextButton", props, { corner(10), new("UIPadding", {
		PaddingLeft = UDim.new(0, 6),
		PaddingRight = UDim.new(0, 6),
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 4),
	}) })
	return b
end

function Hud.mount(lang: string)
	local t = function(key: string, ...: any): string
		return Strings.get(lang, key, ...)
	end

	local gui = new("ScreenGui", {
		Name = "Hud",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})

	---------------------------------------------------------------- stats (top-left)
	local stats = new("Frame", {
		Name = "Stats",
		Position = UDim2.new(0, 12, 0, 12),
		Size = UDim2.new(0.28, 0, 0.16, 0),
		BackgroundColor3 = PANEL,
		BackgroundTransparency = 0.15,
		Parent = gui,
	}, {
		corner(12),
		new("UISizeConstraint", { MinSize = Vector2.new(170, 80), MaxSize = Vector2.new(300, 130) }),
		new("UIPadding", {
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
			PaddingTop = UDim.new(0, 6),
			PaddingBottom = UDim.new(0, 6),
		}),
		new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) }),
	})
	local cashLabel = label({ LayoutOrder = 1, Size = UDim2.fromScale(1, 0.42), TextColor3 = ACCENT, TextXAlignment = Enum.TextXAlignment.Left, Parent = stats })
	local rankLabel = label({ LayoutOrder = 2, Size = UDim2.fromScale(1, 0.28), TextXAlignment = Enum.TextXAlignment.Left, Parent = stats })
	local sackLabel = label({ LayoutOrder = 3, Size = UDim2.fromScale(1, 0.24), TextColor3 = MUTED, TextXAlignment = Enum.TextXAlignment.Left, Parent = stats })

	local function refreshStats()
		cashLabel.Text = "Rp " .. Strings.formatNumber(player:GetAttribute("Cash") or 0, lang)
		rankLabel.Text = t("hud_rank", "@rank_" .. (player:GetAttribute("Rank") or "gurem"))
		sackLabel.Text = t("hud_harvest_bag", player:GetAttribute("HarvestCount") or 0)
	end

	---------------------------------------------------------------- seed bar (bottom)
	local seedBar = new("Frame", {
		Name = "SeedBar",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -16),
		Size = UDim2.new(0.7, 0, 0.11, 0),
		BackgroundTransparency = 1,
		Parent = gui,
	}, {
		new("UISizeConstraint", { MinSize = Vector2.new(320, 54), MaxSize = Vector2.new(640, 80) }),
		new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0.02, 0),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	local seedButtons: { [string]: TextButton } = {}
	for i, cropId in Crops.order do
		local b = button({
			Name = cropId,
			LayoutOrder = i,
			Size = UDim2.fromScale(0.23, 1),
			Parent = seedBar,
		})
		new("UIStroke", { Name = "Selected", Color = ACCENT, Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Enabled = false, Parent = b })
		b.Activated:Connect(function()
			Remotes.Farm_SelectSeed:FireServer(cropId)
		end)
		seedButtons[cropId] = b
	end

	local function hasRank(rank: string): boolean
		local mine = GameConfig.rankIndex[player:GetAttribute("Rank") or "gurem"] or 1
		return mine >= (GameConfig.rankIndex[rank] or 1)
	end

	local function refreshSeeds()
		local selected = player:GetAttribute("SelectedSeed")
		for cropId, b in seedButtons do
			local crop = Crops.list[cropId]
			local unlocked = hasRank(crop.rank)
			b.Text = if unlocked
				then t("hud_seed_count", "@crop_" .. cropId, player:GetAttribute("Seed_" .. cropId) or 0)
				else t("hud_locked", "@crop_" .. cropId)
			b.TextColor3 = if unlocked then TEXT else MUTED
			b.BackgroundColor3 = if unlocked then crop.color:Lerp(Color3.new(0, 0, 0), 0.55) else Color3.fromRGB(50, 50, 50);
			(b:FindFirstChild("Selected") :: UIStroke).Enabled = selected == cropId
		end
	end

	---------------------------------------------------------------- shop
	local shopButton = button({
		Name = "ShopButton",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 12),
		Size = UDim2.new(0.16, 0, 0.08, 0),
		BackgroundColor3 = Color3.fromRGB(40, 120, 60),
		Text = "🌱 " .. t("hud_shop"),
		Parent = gui,
	})
	new("UISizeConstraint", { MinSize = Vector2.new(110, 44), MaxSize = Vector2.new(200, 60), Parent = shopButton })

	local shop = new("Frame", {
		Name = "Shop",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.6, 0.65),
		BackgroundColor3 = PANEL,
		Visible = false,
		Parent = gui,
	}, {
		corner(16),
		new("UISizeConstraint", { MinSize = Vector2.new(300, 260), MaxSize = Vector2.new(560, 460) }),
		new("UIPadding", {
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
			PaddingTop = UDim.new(0, 10),
			PaddingBottom = UDim.new(0, 10),
		}),
		new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0.02, 0) }),
	})
	label({ LayoutOrder = 0, Size = UDim2.fromScale(1, 0.12), Text = t("hud_shop"), TextColor3 = ACCENT, Parent = shop })

	local shopRows: { [string]: { name: TextLabel, buy1: TextButton, buy10: TextButton } } = {}
	for i, cropId in Crops.order do
		local row = new("Frame", { LayoutOrder = i, Size = UDim2.fromScale(1, 0.15), BackgroundTransparency = 1, Parent = shop })
		local name = label({ Size = UDim2.fromScale(0.34, 1), TextXAlignment = Enum.TextXAlignment.Left, Parent = row })
		local buy1 = button({ Position = UDim2.fromScale(0.36, 0), Size = UDim2.fromScale(0.3, 1), Parent = row })
		local buy10 = button({ Position = UDim2.fromScale(0.69, 0), Size = UDim2.fromScale(0.31, 1), Parent = row })
		buy1.Activated:Connect(function()
			Remotes.Shop_BuySeed:FireServer(cropId, 1)
		end)
		buy10.Activated:Connect(function()
			Remotes.Shop_BuySeed:FireServer(cropId, 10)
		end)
		shopRows[cropId] = { name = name, buy1 = buy1, buy10 = buy10 }
	end
	local close = button({ LayoutOrder = 99, Size = UDim2.fromScale(1, 0.12), Text = t("hud_close"), BackgroundColor3 = Color3.fromRGB(120, 50, 40), Parent = shop })
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
		end
	end

	---------------------------------------------------------------- toasts
	local toasts = new("Frame", {
		Name = "Toasts",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 12),
		Size = UDim2.fromScale(0.5, 0.3),
		BackgroundTransparency = 1,
		Parent = gui,
	}, {
		new("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, 6),
		}),
	})
	local toastOrder = 0

	local function toast(text: string)
		toastOrder += 1
		local item = label({
			LayoutOrder = toastOrder,
			Size = UDim2.new(1, 0, 0, 34),
			BackgroundTransparency = 0.2,
			BackgroundColor3 = PANEL,
			Text = text,
			Parent = toasts,
		})
		corner(8).Parent = item
		new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), Parent = item })
		task.delay(3, function()
			local tween = TweenService:Create(item, TweenInfo.new(0.4), { TextTransparency = 1, BackgroundTransparency = 1 })
			tween:Play()
			tween.Completed:Wait()
			item:Destroy()
		end)
		local all = toasts:GetChildren()
		local count = 0
		for _, c in all do
			if c:IsA("TextLabel") then
				count += 1
			end
		end
		if count > 4 then
			for _, c in all do
				if c:IsA("TextLabel") and c.LayoutOrder <= toastOrder - 4 then
					c:Destroy()
				end
			end
		end
	end

	Remotes.Notify.OnClientEvent:Connect(function(key: string, params: { any }?)
		if type(key) ~= "string" then
			return
		end
		toast(Strings.get(lang, key, table.unpack(params or {})))
	end)

	---------------------------------------------------------------- wiring
	local function refreshAll()
		refreshStats()
		refreshSeeds()
		refreshShop()
	end
	player.AttributeChanged:Connect(refreshAll)
	refreshAll()
end

return Hud
