-- HUD: cash / rank / sack / Sus / Nama Baik, the seed bar and the seed shop.
-- Reads player attributes set by the server; sends only requests (select seed, buy seeds).

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Crops = require(Shared.Config.Crops)
local GameConfig = require(Shared.Config.Game)
local Tiers = require(Shared.Config.Tiers)
local Strings = require(Shared.Strings)
local NextGoal = require(Shared.NextGoal)
local Remotes = require(Shared.Remotes)
local Visuals = require(Shared.Config.Visuals)

local Audio = require(script.Parent.Parent.Audio)
local Icons = require(script.Parent.Icons)
local Theme = require(script.Parent.Theme)
local NavBridge = require(script.Parent.NavBridge)
local ActionFeel = require(script.Parent.Parent.Feel.ActionFeel)
local MomentGuard = require(script.Parent.Parent.Feel.MomentGuard)

-- A rarity reveal holds the fidelity tier steady for about as long as its toast is on screen.
local REVEAL_MOMENT_SECONDS = 3.6

-- Register "sack" fallback in Visuals.icons if missing.
if not Visuals.icons["sack"] then
	Visuals.icons["sack"] = { id = 0, text = "K", token = "bambu" }
end

local player = Players.LocalPlayer

local Hud = {}

-- Global / exported language change listener for UI coordination.
Hud.onLanguageChanged = nil :: ((string) -> ())?
Hud.currentLang = "id"

-- Set by Hud.mount; the phone opens the seed shop through Hud.openShop().
local openShopFn: (() -> ())? = nil
local setLanguageFn: ((string) -> ())? = nil

function Hud.openShop()
	if openShopFn then
		openShopFn()
	end
end

function Hud.setLanguage(lang: string)
	if setLanguageFn then
		setLanguageFn(lang)
	end
end

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

function Hud.mount(initialLang: string?)
	-- Default language is Indonesian ("id").
	local activeLang = if initialLang == "en" then "en" else "id"
	Hud.currentLang = activeLang

	local t = function(key: string, ...: any): string
		return Strings.get(activeLang, key, ...)
	end

	local gui = Theme.screenGui("Hud", 10)
	pcall(function()
		(gui :: any).ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
	end)
	local revealToken = 0
	local revealMoment = MomentGuard.new()
	gui.Destroying:Connect(revealMoment.finish)

	local topInset = 0
	pcall(function()
		topInset = GuiService:GetGuiInset().Y
	end)
	local statsTop = math.max(6, 48 - topInset)

	---------------------------------------------------------------- stats panel (compact icon chips)
	local stats = Theme.new("Frame", {
		Name = "Stats",
		Position = UDim2.new(0, 8, 0, statsTop),
		Size = UDim2.new(0, 0, 0, 32),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		Parent = gui,
	}, {
		Theme.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
	})

	local function makeChip(name: string, order: number, iconName: string, iconColor: Color3?)
		local chip = Theme.new("Frame", {
			Name = name,
			LayoutOrder = order,
			Size = UDim2.new(0, 0, 0, 30),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = Theme.paper,
			BackgroundTransparency = 0.05,
			BorderSizePixel = 0,
			Parent = stats,
		}, {
			Theme.corner(nil, Visuals.radius.chip),
			Theme.new("UIStroke", {
				Color = Theme.ink,
				Thickness = 2,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
			Theme.new("UIPadding", {
				PaddingLeft = UDim.new(0, 6),
				PaddingRight = UDim.new(0, 8),
				PaddingTop = UDim.new(0, 4),
				PaddingBottom = UDim.new(0, 4),
			}),
			Theme.new("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 6),
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),
		})

		Icons.make(iconName, {
			LayoutOrder = 1,
			Size = UDim2.fromOffset(20, 20),
			Color = iconColor,
			Parent = chip,
		})

		local lbl = Theme.label({
			LayoutOrder = 2,
			Size = UDim2.new(0, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			TextScaled = false,
			TextSize = 14,
			Font = Theme.displayFont,
			TextColor3 = Theme.ink,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = chip,
		})

		return chip, lbl
	end

	-- 1. Cash chip (gold / money icon + Rp amount)
	local _, cashLabel = makeChip("CashChip", 1, "cash", Theme.kunyit)
	cashLabel.TextSize = 15

	-- 2. Sack chip (harvest bag icon + X/Y count)
	local _, sackLabel = makeChip("SackChip", 2, "sack", Theme.bambu)
	sackLabel.Font = Theme.font

	-- 3. Sus chip (warning/sus icon + value)
	local _, susLabel = makeChip("SusChip", 3, "sus", Theme.merah)
	susLabel.Font = Theme.font

	-- 4. Nama Baik chip (reputation/star icon + value)
	local _, namaBaikLabel = makeChip("NamaBaikChip", 4, "reputation", Theme.malam)
	namaBaikLabel.Font = Theme.font

	-- 5. Language toggle chip ("ID" / "EN")
	local langToggleBtn = Theme.button({
		Name = "LangToggle",
		LayoutOrder = 5,
		Size = UDim2.new(0, 44, 0, 30),
		Text = activeLang:upper(),
		TextSize = 13,
		Font = Theme.displayFont,
		BackgroundColor3 = Theme.padi,
		TextColor3 = Theme.ink,
		Parent = stats,
	})

	---------------------------------------------------------------- Harga Cabai Meroket banner
	local eventChip = Theme.card({
		Name = "CabaiEvent",
		Position = UDim2.new(0, 8, 0, statsTop + 36),
		Size = UDim2.new(0.24, 0, 0, 30),
		BackgroundColor3 = Theme.kunyit,
		Visible = false,
		Parent = gui,
	}, {
		Theme.new("UISizeConstraint", { MinSize = Vector2.new(168, 28), MaxSize = Vector2.new(236, 32) }),
	})
	local eventLabel = Theme.label({
		Size = UDim2.fromScale(1, 1),
		Text = "",
		TextColor3 = Theme.ink,
		TextScaled = false,
		TextSize = 14,
		Parent = eventChip,
	})

	local function updateEventLabel()
		local multiplier = GameConfig.cabaiEventMultiplier
		local endsAt = ReplicatedStorage:GetAttribute("CabaiEventEndsAt")
		if type(endsAt) ~= "number" or endsAt <= 0 then
			eventLabel.Text = t("hud_event_cabai_on", multiplier)
			return
		end
		local left = math.max(0, math.ceil(endsAt - os.time()))
		eventLabel.Text = t("hud_event_cabai_left", multiplier, string.format("%d:%02d", math.floor(left / 60), left % 60))
	end

	local function refreshEvent()
		eventChip.Visible = ReplicatedStorage:GetAttribute("CabaiEvent") == true
		if eventChip.Visible then
			eventChip.Position = UDim2.new(0, 8, 0, statsTop + stats.AbsoluteSize.Y + 4)
			updateEventLabel()
		end
	end
	ReplicatedStorage:GetAttributeChangedSignal("CabaiEvent"):Connect(refreshEvent)
	ReplicatedStorage:GetAttributeChangedSignal("CabaiEventEndsAt"):Connect(refreshEvent)
	stats:GetPropertyChangedSignal("AbsoluteSize"):Connect(refreshEvent)
	refreshEvent()

	local function refreshStats()
		cashLabel.Text = t("cash_label", player:GetAttribute("Cash") or 0)
		sackLabel.Text = string.format("%d/%d",
			player:GetAttribute("HarvestCount") or 0,
			player:GetAttribute("SackCapacity") or GameConfig.sackBaseCapacity
		)
		local sus = player:GetAttribute("Sus") or 0
		susLabel.Text = tostring(sus)
		susLabel.TextColor3 = susColor(sus)
		namaBaikLabel.Text = tostring(player:GetAttribute("NamaBaik") or 50)
	end

	---------------------------------------------------------------- tutorial guide card
	local tutorialCard = Theme.card({
		Name = "TutorialGuide",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 8),
		Size = UDim2.new(0.42, 0, 0, 54),
		BackgroundColor3 = Theme.padi,
		Visible = false,
		Parent = gui,
	}, {
		Theme.new("UISizeConstraint", { MinSize = Vector2.new(240, 48), MaxSize = Vector2.new(460, 60) }),
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

	local function refreshGoal()
		local stepId = player:GetAttribute("TutorialStep")
		local goal = NextGoal.pick({
			tutorialStep = if type(stepId) == "string" then stepId else nil,
			rank = player:GetAttribute("Rank"),
			lifetimeEarned = player:GetAttribute("LifetimeEarned"),
			tilesOwned = player:GetAttribute("TilesOwned"),
		})
		tutorialTitle.Text = if goal.kind == "tutorial" then t("tutorial_card_title") else t("goal_card_title")
		tutorialText.Text = t(goal.key, table.unpack(goal.params))
		tutorialCard.Visible = true
	end
	refreshGoal()

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
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	local seedButtons: { [string]: TextButton } = {}
	local seedIcons: { [string]: GuiObject } = {}
	local seedLabels: { [string]: TextLabel } = {}
	for i, cropId in Crops.order do
		local button = Theme.button({
			Name = cropId,
			LayoutOrder = i,
			Size = UDim2.fromOffset(116, 44),
			Text = "",
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
		local icon = Icons.make(Icons.slot("crop", cropId), {
			Name = "Icon",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 6, 0.5, 0),
			Size = UDim2.fromOffset(28, 28),
			Parent = button,
		})
		local label = Theme.label({
			Name = "Label",
			Position = UDim2.new(0, 38, 0, 0),
			Size = UDim2.new(1, -42, 1, 0),
			Text = "",
			TextXAlignment = Enum.TextXAlignment.Left,
			TextScaled = false,
			TextSize = 13,
			Font = Theme.font,
			TextColor3 = Theme.paper,
			TextStrokeColor3 = Theme.ink,
			TextStrokeTransparency = 0,
			TextWrapped = true,
			Parent = button,
		})
		button.Activated:Connect(function()
			Remotes.Farm_SelectSeed:FireServer(cropId)
		end)
		seedButtons[cropId] = button
		seedIcons[cropId] = icon
		seedLabels[cropId] = label
	end

	local buySeedsButton = Theme.button({
		Name = "BuySeedsButton",
		LayoutOrder = 0,
		Size = UDim2.fromOffset(160, 44),
		BackgroundColor3 = Theme.green,
		Text = t("hud_buy_seeds"),
		Visible = false,
		Parent = seedBar,
	})

	local function hasRank(rank: string): boolean
		local mine = GameConfig.rankIndex[player:GetAttribute("Rank") or "gurem"] or 1
		return mine >= (GameConfig.rankIndex[rank] or 1)
	end

	local function stockOf(cropId: string): number?
		local value = player:GetAttribute("ShopStock_" .. cropId)
		return if type(value) == "number" then value else nil
	end

	local function refreshSeeds()
		local selected = player:GetAttribute("SelectedSeed")
		local anyVisible = false
		for cropId, button in seedButtons do
			local crop = Crops.list[cropId]
			local unlocked = hasRank(crop.rank)
			local owned = player:GetAttribute("Seed_" .. cropId) or 0
			button.Visible = owned > 0 or selected == cropId
			if button.Visible then
				anyVisible = true
			end
			local label = seedLabels[cropId]
			if label then
				label.Text = if unlocked
					then t("hud_seed_count", "@crop_" .. cropId, owned)
					else t("hud_locked", "@crop_" .. cropId)
			end
			button.Text = ""
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
		buySeedsButton.Visible = not anyVisible
	end

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
	local shopTitle = Theme.label({
		Name = "Title",
		Position = UDim2.new(0, 28, 0, 0),
		Size = UDim2.new(1, -28, 0, 28),
		Text = t("hud_shop"),
		Font = Theme.displayFont,
		TextColor3 = Theme.merah,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = shop,
	})
	local restockLabel = Theme.label({
		Name = "Restock",
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, 28),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = Theme.muted,
		Parent = shop,
	})

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
	-- WORK_QUEUE item 21: B/Escape closes the seed shop; selecting it focuses the X button.
	NavBridge.register("shop", {
		root = shop,
		default = close,
		onClose = function()
			shop.Visible = false
		end,
	})
	buySeedsButton.Activated:Connect(function()
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

	---------------------------------------------------------------- notifications & feel
	local lastCash = player:GetAttribute("Cash") or 0
	local recentSaleAmount: number? = nil
	local recentSaleTime = 0

	local function triggerSell(amount: number)
		local originPos = nil
		local char = player.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			originPos = char.HumanoidRootPart.Position
		end
		ActionFeel.onSell(amount, originPos)
	end

	Remotes.Notify.OnClientEvent:Connect(function(key: string, params: { any }?)
		if type(key) ~= "string" then
			return
		end
		local color: Color3? = nil
		if key == "n_rarity_reveal" and params and type(params[3]) == "string" then
			local tierName = params[3]
			local tier = Tiers.list[tierName]
			if tier then
				color = tier.color
			end
			ActionFeel.onHarvest(nil, tierName)
			-- begin() replaces any open reveal (one end for it); only the newest token may end it.
			revealToken += 1
			local token = revealToken
			revealMoment.begin()
			task.delay(REVEAL_MOMENT_SECONDS, function()
				if token == revealToken then
					revealMoment.finish()
				end
			end)
		elseif key == "n_almanak_page" or key == "n_almanak_new" then
			Audio.play("sting_almanak")
		elseif key == "n_rank_up" then
			Audio.play("sting_rankup")
		elseif key == "n_bought_seeds" then
			Audio.play("ui_buy")
		elseif key == "n_sold" or key == "n_sold_gelap" then
			local amount = if params and type(params[1]) == "number" then params[1] else 0
			if recentSaleTime > 0 and (os.clock() - recentSaleTime) < 1.5 then
				recentSaleTime = 0
				local sellAmt = if amount > 0 then amount else (recentSaleAmount or 0)
				recentSaleAmount = nil
				triggerSell(sellAmt)
			else
				recentSaleAmount = amount
				recentSaleTime = os.clock()
			end
		end
		Theme.toast(Strings.get(activeLang, key, table.unpack(params or {})), color)
	end)

	player:GetAttributeChangedSignal("Cash"):Connect(function()
		local current = player:GetAttribute("Cash") or 0
		local diff = current - lastCash
		lastCash = current
		if diff > 0 then
			if recentSaleTime > 0 and (os.clock() - recentSaleTime) < 1.5 then
				recentSaleTime = 0
				local amount = if (recentSaleAmount and recentSaleAmount > 0) then recentSaleAmount else diff
				recentSaleAmount = nil
				triggerSell(amount)
			else
				recentSaleAmount = diff
				recentSaleTime = os.clock()
			end
		end
	end)

	---------------------------------------------------------------- wiring
	local function refreshAll()
		refreshStats()
		refreshGoal()
		refreshSeeds()
		refreshShop()
	end

	local function switchLanguage(newLang: string)
		activeLang = newLang
		Hud.currentLang = activeLang
		langToggleBtn.Text = activeLang:upper()
		buySeedsButton.Text = t("hud_buy_seeds")
		shopTitle.Text = t("hud_shop")
		close.Text = t("hud_close")
		refreshAll()
		if eventChip.Visible then
			updateEventLabel()
		end
		if Hud.onLanguageChanged then
			Hud.onLanguageChanged(activeLang)
		end
	end

	setLanguageFn = switchLanguage

	langToggleBtn.Activated:Connect(function()
		local nextLang = if activeLang == "id" then "en" else "id"
		switchLanguage(nextLang)
	end)

	player.AttributeChanged:Connect(refreshAll)
	refreshAll()

	openShopFn = function()
		shop.Visible = true
		refreshShop()
	end

	task.spawn(function()
		while true do
			task.wait(1)
			if shop.Visible then
				updateRestock()
			end
			if eventChip.Visible then
				updateEventLabel()
			end
		end
	end)

	return gui
end

return Hud
