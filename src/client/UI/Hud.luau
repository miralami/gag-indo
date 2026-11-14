-- HUD: cash / rank / sack / Sus / Nama Baik, the seed bar and the seed shop.
-- Reads player attributes set by the server; sends only requests (select seed, buy seeds).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Crops = require(Shared.Config.Crops)
local GameConfig = require(Shared.Config.Game)
local Tiers = require(Shared.Config.Tiers)
local Strings = require(Shared.Strings)
local Remotes = require(Shared.Remotes)

local Audio = require(script.Parent.Parent.Audio)
local Icons = require(script.Parent.Icons)
local Theme = require(script.Parent.Theme)

local player = Players.LocalPlayer

local Hud = {}

local function susColor(sus: number): Color3
	if sus >= 80 then
		return Theme.merah
	elseif sus >= 60 then
		return Theme.genteng
	elseif sus >= 30 then
		return Theme.inkSoft
	end
	return Theme.ink
end

function Hud.mount(lang: string)
	local t = function(key: string, ...: any): string
		return Strings.get(lang, key, ...)
	end

	local gui = Theme.screenGui("Hud", 10)
	-- Keep the HUD clear of the phone notch / rounded corners in landscape.
	pcall(function()
		(gui :: any).ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
	end)
	local revealToken = 0

	-- The ScreenGui starts below Roblox's top bar (IgnoreGuiInset is false), but the
	-- menu and chat icons still reach about 58 px down the left edge. Start the stats
	-- panel at about 60 px absolute: subtract the top-bar inset from that offset.
	local topInset = 0
	pcall(function()
		topInset = game:GetService("GuiService"):GetGuiInset().Y
	end)
	local statsTop = math.max(0, 60 - topInset)

	---------------------------------------------------------------- stats (top-left)
	local stats = Theme.card({
		Name = "Stats",
		Position = UDim2.new(0, 10, 0, statsTop),
		Size = UDim2.new(0.24, 0, 0, 96),
		BackgroundTransparency = 0.12,
		Parent = gui,
	}, {
		Theme.new("UISizeConstraint", { MinSize = Vector2.new(168, 90), MaxSize = Vector2.new(236, 104) }),
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

	-- Fixed pixel sizes (not TextScaled) so no secondary line drops below 14 px on a phone.
	local cashLabel = Theme.label({
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, 26),
		TextScaled = false,
		TextSize = 22,
		Font = Theme.displayFont,
		TextColor3 = Theme.ink,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = stats,
	})
	local rankLabel = Theme.label({
		LayoutOrder = 2,
		Size = UDim2.new(1, 0, 0, 16),
		TextScaled = false,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = stats,
	})
	local sackLabel = Theme.label({
		LayoutOrder = 3,
		Size = UDim2.new(1, 0, 0, 16),
		TextScaled = false,
		TextSize = 14,
		TextColor3 = Theme.muted,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = stats,
	})

	local chips = Theme.new("Frame", {
		LayoutOrder = 4,
		Size = UDim2.new(1, 0, 0, 18),
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
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		TextScaled = false,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = chips,
	})
	local namaBaikLabel = Theme.label({
		LayoutOrder = 2,
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		TextScaled = false,
		TextSize = 14,
		TextColor3 = Theme.malam,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = chips,
	})

	---------------------------------------------------------------- Harga Cabai Meroket banner
	local eventChip = Theme.card({
		Name = "CabaiEvent",
		Position = UDim2.new(0, 10, 0, statsTop + 102),
		Size = UDim2.new(0.24, 0, 0, 32),
		BackgroundColor3 = Theme.merah,
		Visible = false,
		Parent = gui,
	}, {
		Theme.new("UISizeConstraint", { MinSize = Vector2.new(168, 30), MaxSize = Vector2.new(236, 34) }),
	})
	local eventLabel = Theme.label({
		Size = UDim2.fromScale(1, 1),
		Text = t("hud_event_cabai", GameConfig.cabaiEventMultiplier),
		TextColor3 = Theme.paper,
		TextScaled = false,
		TextSize = 14,
		Parent = eventChip,
	})

	local function refreshEvent()
		eventChip.Visible = ReplicatedStorage:GetAttribute("CabaiEvent") == true
		if eventChip.Visible then
			eventChip.Position = UDim2.new(0, 10, 0, statsTop + stats.AbsoluteSize.Y + 6)
		end
	end
	ReplicatedStorage:GetAttributeChangedSignal("CabaiEvent"):Connect(refreshEvent)
	stats:GetPropertyChangedSignal("AbsoluteSize"):Connect(refreshEvent)
	refreshEvent()

	local function refreshStats()
		cashLabel.Text = "Rp " .. Strings.formatNumber(player:GetAttribute("Cash") or 0, lang)
		rankLabel.Text = t("hud_rank", "@rank_" .. (player:GetAttribute("Rank") or "gurem"))
		sackLabel.Text = t(
			"hud_harvest_bag",
			player:GetAttribute("HarvestCount") or 0,
			player:GetAttribute("SackCapacity") or GameConfig.sackBaseCapacity
		)
		local sus = player:GetAttribute("Sus") or 0
		susLabel.Text = t("hud_sus", sus)
		susLabel.TextColor3 = susColor(sus)
		namaBaikLabel.Text = t("hud_namabaik", player:GetAttribute("NamaBaik") or 50)
	end

	---------------------------------------------------------------- tutorial guide card
	local tutorialCard = Theme.card({
		Name = "TutorialGuide",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 10),
		Size = UDim2.new(0.42, 0, 0, 56),
		BackgroundColor3 = Theme.padi,
		Visible = false,
		Parent = gui,
	}, {
		Theme.new("UISizeConstraint", { MinSize = Vector2.new(240, 50), MaxSize = Vector2.new(460, 64) }),
	})
	local tutorialPadding = Instance.new("UIPadding")
	tutorialPadding.PaddingLeft = UDim.new(0, 10)
	tutorialPadding.PaddingRight = UDim.new(0, 10)
	tutorialPadding.PaddingTop = UDim.new(0, 4)
	tutorialPadding.PaddingBottom = UDim.new(0, 4)
	tutorialPadding.Parent = tutorialCard

	Icons.make("seed", {
		Position = UDim2.new(0, 0, 0, 1),
		Size = UDim2.fromOffset(16, 16),
		Parent = tutorialCard,
	})

	local tutorialTitle = Theme.label({
		Position = UDim2.new(0, 20, 0, 0),
		Size = UDim2.new(1, -20, 0, 18),
		Text = t("tutorial_card_title"),
		Font = Theme.displayFont,
		TextColor3 = Theme.merah,
		TextScaled = false,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = tutorialCard,
	})

	local tutorialText = Theme.label({
		Position = UDim2.new(0, 0, 0, 20),
		Size = UDim2.new(1, 0, 1, -20),
		Text = "",
		TextColor3 = Theme.text,
		TextScaled = false,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Parent = tutorialCard,
	})

	local function refreshTutorial()
		local stepId = player:GetAttribute("TutorialStep")
		if type(stepId) == "string" and stepId ~= "" then
			tutorialText.Text = t("tutorial_" .. stepId)
			tutorialCard.Visible = true
		else
			tutorialCard.Visible = false
		end
	end
	player:GetAttributeChangedSignal("TutorialStep"):Connect(refreshTutorial)
	refreshTutorial()

	---------------------------------------------------------------- seed bar (bottom)
	local seedBar = Theme.new("ScrollingFrame", {
		Name = "SeedBar",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -12),
		Size = UDim2.new(0.82, 0, 0, 54),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollingDirection = Enum.ScrollingDirection.X,
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		CanvasSize = UDim2.new(),
		Parent = gui,
	}, {
		Theme.new("UISizeConstraint", { MinSize = Vector2.new(320, 52), MaxSize = Vector2.new(760, 76) }),
		Theme.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	local seedButtons: { [string]: TextButton } = {}
	for i, cropId in Crops.order do
		local button = Theme.button({
			Name = cropId,
			LayoutOrder = i,
			Size = UDim2.fromOffset(104, 44),
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

	-- Today's shelf count for one crop. nil = not sold this restock cycle.
	local function stockOf(cropId: string): number?
		local value = player:GetAttribute("ShopStock_" .. cropId)
		return if type(value) == "number" then value else nil
	end

	local function refreshSeeds()
		local selected = player:GetAttribute("SelectedSeed")
		for cropId, button in seedButtons do
			local crop = Crops.list[cropId]
			local unlocked = hasRank(crop.rank)
			local owned = player:GetAttribute("Seed_" .. cropId) or 0
			button.Text = if unlocked
				then t("hud_seed_count", "@crop_" .. cropId, owned)
				else t("hud_locked", "@crop_" .. cropId)
			-- Text is always cream with a dark outline; only the background carries the dimming.
			button.TextColor3 = Theme.paper
			button.TextStrokeColor3 = Theme.ink
			button.TextStrokeTransparency = 0
			button.BackgroundColor3 = if not unlocked
				then Theme.inkSoft
				elseif owned > 0 then crop.color:Lerp(Color3.new(0, 0, 0), 0.55)
				else crop.color:Lerp(Color3.new(0, 0, 0), 0.8)
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
		Size = UDim2.new(0.2, 0, 0, 44),
		BackgroundTransparency = 1,
		Parent = gui,
	}, {
		Theme.new("UISizeConstraint", { MinSize = Vector2.new(120, 44), MaxSize = Vector2.new(170, 44) }),
		Theme.new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) }),
	})

	local shopButton = Theme.button({
		Name = "ShopButton",
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Theme.green,
		Text = t("hud_shop_button"),
		TextScaled = false,
		TextSize = 16,
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
	})
	local shopPadding = Instance.new("UIPadding")
	shopPadding.PaddingLeft = UDim.new(0, 12)
	shopPadding.PaddingRight = UDim.new(0, 12)
	shopPadding.PaddingTop = UDim.new(0, 10)
	shopPadding.PaddingBottom = UDim.new(0, 10)
	shopPadding.Parent = shop

	Icons.make("seed", {
		Position = UDim2.new(0, 0, 0, 3),
		Size = UDim2.fromOffset(22, 22),
		Parent = shop,
	})
	Theme.label({
		Name = "Title",
		Position = UDim2.new(0, 28, 0, 0),
		Size = UDim2.new(1, -28, 0, 28),
		Text = t("hud_shop"),
		Font = Theme.displayFont,
		TextColor3 = Theme.merah,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = shop,
	})
	-- Restock countdown, top-right of the title row; refreshed by the timer below.
	local restockLabel = Theme.label({
		Name = "Restock",
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, 28),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = Theme.muted,
		Parent = shop,
	})

	-- Twelve crops do not fit on one screen, so the list scrolls between the title and Close.
	local shopScroll = Theme.new("ScrollingFrame", {
		Name = "Scroll",
		Position = UDim2.new(0, 0, 0, 30),
		Size = UDim2.new(1, 0, 1, -80),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = shop,
	}, {
		Theme.new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }),
	})

	local shopRows: { [string]: { name: TextLabel, buy1: TextButton, buyAll: TextButton } } = {}
	for i, cropId in Crops.order do
		local row = Theme.new("Frame", {
			LayoutOrder = i,
			Size = UDim2.new(1, 0, 0, 44),
			BackgroundTransparency = 1,
			Parent = shopScroll,
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
		local buyAll = Theme.button({
			Position = UDim2.fromScale(0.66, 0),
			Size = UDim2.fromScale(0.34, 1),
			Parent = row,
		})
		buy1.Activated:Connect(function()
			Remotes.Shop_BuySeed:FireServer(cropId, 1)
		end)
		buyAll.Activated:Connect(function()
			-- The server clamps against the real shelf; this is just the whole stack.
			local available = stockOf(cropId)
			if available and available > 0 then
				Remotes.Shop_BuySeed:FireServer(cropId, available)
			end
		end)
		shopRows[cropId] = { name = name, buy1 = buy1, buyAll = buyAll }
	end

	local close = Theme.button({
		Name = "Close",
		Position = UDim2.new(0, 0, 1, -44),
		Size = UDim2.new(1, 0, 0, 44),
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

	local function updateRestock()
		local at = player:GetAttribute("ShopRestockAt")
		if type(at) ~= "number" or at <= 0 then
			restockLabel.Text = ""
			return
		end
		local left = math.max(0, math.ceil(at - os.time()))
		restockLabel.Text = t("shop_restock_in", string.format("%d:%02d", math.floor(left / 60), left % 60))
	end

	local function refreshShop()
		for cropId, row in shopRows do
			local crop = Crops.list[cropId]
			local unlocked = hasRank(crop.rank)
			local available = stockOf(cropId)
			local canBuy = unlocked and available ~= nil and available > 0
			row.name.Text = t("crop_" .. cropId)
			if not unlocked then
				row.buy1.Text = t("shop_needs_rank", "@rank_" .. crop.rank)
				row.buyAll.Text = "[L]"
			elseif available == nil then
				row.buy1.Text = t("shop_not_stocked")
				row.buyAll.Text = "-"
			elseif available <= 0 then
				row.buy1.Text = t("shop_sold_out")
				row.buyAll.Text = "-"
			else
				row.buy1.Text = t("shop_buy", 1, crop.seedCost)
				row.buyAll.Text = t("shop_buy_all", crop.seedCost * available)
			end
			row.buy1.Active = canBuy
			row.buyAll.Active = canBuy
			row.buy1.BackgroundTransparency = if canBuy then 0 else 0.5
			row.buyAll.BackgroundTransparency = if canBuy then 0 else 0.5
		end
		updateRestock()
	end

	---------------------------------------------------------------- notifications
	Remotes.Notify.OnClientEvent:Connect(function(key: string, params: { any }?)
		if type(key) ~= "string" then
			return
		end
		local color: Color3? = nil
		-- The rarity reveal carries the tier id as the third param; tint the toast with it.
		if key == "n_rarity_reveal" and params and type(params[3]) == "string" then
			local tier = Tiers.list[params[3]]
			if tier then
				color = tier.color
			end
			Audio.play(if params[3] == "sultan" then "sting_sultan" else "sting_rare")
			if params[3] == "sultan" then
				revealToken += 1
				local token = revealToken
				local camera = workspace.CurrentCamera
				if camera then
					local original = camera.CFrame
					task.spawn(function()
						for _, offset in { 0.18, -0.18, 0.1, -0.1, 0 } do
							if token ~= revealToken or workspace.CurrentCamera ~= camera then return end
							camera.CFrame = original * CFrame.new(offset, 0, 0)
							task.wait(0.025)
						end
					end)
				end
			end
		elseif key == "n_almanak_page" or key == "n_almanak_new" then
			Audio.play("sting_almanak")
		elseif key == "n_rank_up" then
			Audio.play("sting_rankup")
		elseif key == "n_bought_seeds" then
			Audio.play("ui_buy")
		elseif key == "n_sold" or key == "n_sold_gelap" then
			Audio.play("ui_sell")
		end
		Theme.toast(Strings.get(lang, key, table.unpack(params or {})), color)
	end)

	---------------------------------------------------------------- wiring
	local function refreshAll()
		refreshStats()
		refreshSeeds()
		refreshShop()
	end
	player.AttributeChanged:Connect(refreshAll)
	refreshAll()

	-- Only the countdown ticks; the rows refresh when an attribute changes.
	task.spawn(function()
		while true do
			task.wait(1)
			if shop.Visible then
				updateRestock()
			end
		end
	end)

	return gui
end

return Hud
