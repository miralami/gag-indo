-- Phone: bukti tokens + Lapor, inventory (amplop/bail), the cheat menu and decor shop.
-- All actions are requests; the server re-checks distance, ownership and money.
-- Redesigned for W2 with App Grid Home + Back button, palette tokens, and Icons.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Cheats = require(Shared.Config.Cheats)
local CosmeticsConfig = require(Shared.Config.Cosmetics)
local Crops = require(Shared.Config.Crops)
local GameConfig = require(Shared.Config.Game)
local ToolsConfig = require(Shared.Config.Tools)
local WorkerConfig = require(Shared.Config.Worker)
local PinjolConfig = require(Shared.Config.Pinjol)
local QuestsConfig = require(Shared.Config.Quests)
local Strings = require(Shared.Strings)
local Remotes = require(Shared.Remotes)
local Audio = require(script.Parent.Parent.Audio)
local ClientState = require(script.Parent.Parent.State)
local NavBridge = require(script.Parent.NavBridge)

local Theme = require(script.Parent.Theme)
local Icons = require(script.Parent.Icons)
local Widgets = require(script.Parent.PhoneWidgets)
local Evidence = require(script.Parent.Evidence)
local PhoneLayout = require(Shared.PhoneLayout)
local LazyPages = require(script.Parent.LazyPages)

local player = Players.LocalPlayer

local Phone = {}
local setPhoneLanguageFn: ((string) -> ())? = nil

function Phone.setLanguage(lang: string)
	if setPhoneLanguageFn then
		setPhoneLanguageFn(lang)
	end
end

-- Generic view helpers live in PhoneWidgets (code-health split); keep the local names so every
-- page below calls exactly the same function it did before the move.
local clearChildren = Widgets.clearChildren
local sectionLabel = Widgets.sectionLabel
local scrollPage = Widgets.scrollPage

-- Builds the device (frame, home grid, app tiles, wiring) on the first open, not at mount.
-- `ctx` carries the always-present pieces made by Phone.mount: gui, toggle and the shared
-- language state. Returns the open function and the language setter for the built device.
local function buildDevice(ctx: any)
	local activeLang: string = ctx.state.lang
	local Hud = require(script.Parent.Hud)
	local gui: ScreenGui = ctx.gui
	local toggle: TextButton = ctx.toggle

	local t = function(key: string, ...: any): string
		return Strings.get(activeLang, key, ...)
	end

	-- Full-screen scrim. Tapping outside the device closes the phone.
	local root = Theme.new("Frame", {
		Name = "Root",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.ink,
		BackgroundTransparency = 0.5,
		Visible = false,
		Parent = gui,
	})

	-- The device follows the screen orientation (applyLayout, below): a portrait phone
	-- (aspect 0.5, 88% of the height) normally, or a landscape phone (aspect 2, 90% of the
	-- height) on short screens. The aspect constraint keeps the shape; MaxSize only caps it.
	-- No MinSize: a minimum would break the aspect ratio on small screens.
	local aspect = Theme.new("UIAspectRatioConstraint", {
		AspectRatio = 0.5,
		AspectType = Enum.AspectType.FitWithinMaxSize,
		DominantAxis = Enum.DominantAxis.Height,
	})
	local sizeLimit = Theme.new("UISizeConstraint", { MaxSize = Vector2.new(340, 680) })
	local card = Theme.new("Frame", {
		Name = "Card",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.9, 0.88),
		BackgroundColor3 = Theme.ink,
		BorderSizePixel = 0,
		Parent = root,
	}, {
		Theme.corner(nil, 26),
		Theme.new("UIStroke", { Color = Theme.inkSoft, Thickness = 2 }),
		aspect,
		sizeLimit,
	})

	-- Speaker slit in the top bezel.
	Theme.new("Frame", {
		Name = "Speaker",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 6),
		Size = UDim2.fromOffset(40, 4),
		BackgroundColor3 = Theme.inkSoft,
		BorderSizePixel = 0,
		Parent = card,
	}, { Theme.corner(nil, 2) })

	-- The lit screen, inset by the bezel (10 px sides and bottom, 16 px top for the speaker).
	local deviceScreen = Theme.new("Frame", {
		Name = "Screen",
		Position = UDim2.fromOffset(10, 16),
		Size = UDim2.new(1, -20, 1, -26),
		BackgroundColor3 = Theme.paper,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = card,
	}, { Theme.corner(nil, 18) })

	-- Wallpaper: only visible on the home grid.
	local wallpaper = Theme.new("Frame", {
		Name = "Wallpaper",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.malam,
		BorderSizePixel = 0,
		Parent = deviceScreen,
	}, {
		Theme.new("UIGradient", { Color = ColorSequence.new(Theme.malam, Theme.indigo), Rotation = 90 }),
	})

	-- Top bar: status line (clock, glyphs) over the navigation row (back, title, close).
	-- 22 px status row + 44 px navigation row (44 px touch targets for Back and Close).
	local topBar = Theme.new("Frame", {
		Name = "TopBar",
		Size = UDim2.new(1, 0, 0, 66),
		BackgroundColor3 = Theme.malam,
		BorderSizePixel = 0,
		Parent = deviceScreen,
	})
	local clock = Theme.label({
		Name = "Clock",
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(0.5, 0, 0, 22),
		Text = "",
		TextScaled = false,
		TextSize = 12,
		Font = Theme.displayFont,
		TextColor3 = Theme.paper,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = topBar,
	})
	Theme.label({
		Name = "Glyphs",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 0),
		Size = UDim2.new(0.5, 0, 0, 22),
		Text = "|||| 4G [===]",
		TextScaled = false,
		TextSize = 11,
		TextColor3 = Theme.paper,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = topBar,
	})

	local function updateClock()
		clock.Text = os.date("%H:%M")
	end

	local header = Theme.new("Frame", {
		Name = "Header",
		Position = UDim2.fromOffset(0, 22),
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		Parent = topBar,
	})

	local backButton = Theme.button({
		Name = "Back",
		Position = UDim2.fromOffset(6, 0),
		Size = UDim2.fromOffset(44, 44),
		Text = "<",
		BackgroundColor3 = Theme.bambu,
		Visible = false,
		Parent = header,
	})

	local titleLabel = Theme.label({
		Name = "Title",
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -110, 1, 0),
		Text = t("phone_title"),
		Font = Theme.displayFont,
		TextColor3 = Theme.paper,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = false,
		Parent = header,
	})
	-- One line: the title scales down to fit its row and never wraps.
	Theme.new("UITextSizeConstraint", { MaxTextSize = 22, MinTextSize = 12, Parent = titleLabel })

	local langToggle = Theme.button({
		Name = "LangToggle",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -54, 0, 0),
		Size = UDim2.fromOffset(44, 44),
		Text = activeLang:upper(),
		Font = Theme.displayFont,
		TextSize = 14,
		BackgroundColor3 = Theme.padi,
		TextColor3 = Theme.ink,
		Parent = header,
	})

	local close = Theme.button({
		Name = "Close",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -6, 0, 0),
		Size = UDim2.fromOffset(44, 44),
		Text = "X",
		BackgroundColor3 = Theme.red,
		Parent = header,
	})

	local homeBarHeight = PhoneLayout.homeBarHeight

	-- Content: fills the screen between the top bar and the home bar.
	local content = Theme.new("Frame", {
		Name = "Content",
		-- Top: 66 px TopBar + 4 px gap. Bottom: home bar + 8 px safety margin.
		Position = UDim2.new(0, 8, 0, 70),
		Size = UDim2.new(1, -16, 1, -(70 + homeBarHeight + 8)),
		BackgroundTransparency = 1,
		Parent = deviceScreen,
	})

	-- Home bar: a touch-friendly bar at the bottom. Inside an app it goes home; on home it closes the phone.
	local homeBar = Theme.new("TextButton", {
		Name = "HomeBar",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, homeBarHeight),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		Parent = deviceScreen,
	})
	local homePill = Theme.new("Frame", {
		Name = "Pill",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(84, 5),
		BackgroundColor3 = Theme.paper,
		BorderSizePixel = 0,
		Parent = homeBar,
	}, { Theme.corner(nil, 3) })

	-- Closing is always possible: the X, the home bar on home, and a tap outside the device.
	-- App pages are built on open (LazyPages); closing the phone tears them down again.
	local registry: any
	local function closePhone()
		Audio.play("ui_close")
		root.Visible = false
		registry:closeAll()
		toggle.Visible = true
	end

	-- Home grid: column count and cell size are set by applyLayout (3 portrait, 4 landscape).
	local homeGrid = Theme.new("UIGridLayout", {
		CellSize = UDim2.new(1 / 3, -4, 0, 88),
		CellPadding = UDim2.fromOffset(4, 6),
		FillDirectionMaxCells = 3,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	local homePage = Theme.new("ScrollingFrame", {
		Name = "PageHome",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = true,
		Parent = content,
	}, {
		homeGrid,
		Theme.new("UIPadding", {
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 24),
			PaddingLeft = UDim.new(0, 4),
			PaddingRight = UDim.new(0, 4),
		}),
	})

	-- Orientation by screen: landscape when the screen is short (height < 500, or wide and
	-- under 600 high), portrait otherwise. Only the card aspect, its size cap and the grid
	-- columns change; pages are not rebuilt.
	local function isLandscape(viewport: Vector2): boolean
		return viewport.Y < 500 or (viewport.X > 1.6 * viewport.Y and viewport.Y < 600)
	end

	local function applyLayout()
		local camera = workspace.CurrentCamera
		if not camera then
			return
		end
		local landscape = isLandscape(camera.ViewportSize)
		aspect.AspectRatio = if landscape then 2 else 0.5
		card.Size = if landscape then UDim2.fromScale(0.95, 0.9) else UDim2.fromScale(0.9, 0.88)
		sizeLimit.MaxSize = if landscape then Vector2.new(1200, 600) else Vector2.new(340, 680)
		homeGrid.FillDirectionMaxCells = if landscape then 4 else 3
		homeGrid.CellSize = if landscape then UDim2.new(1 / 4, -4, 0, 88) else UDim2.new(1 / 3, -4, 0, 88)
	end

	local viewportConnection: RBXScriptConnection? = nil
	local function watchCamera()
		if viewportConnection then
			viewportConnection:Disconnect()
			viewportConnection = nil
		end
		local camera = workspace.CurrentCamera
		if camera then
			viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(applyLayout)
		end
		applyLayout()
	end
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
	watchCamera()

	-- Apps with `page` open a screen inside the phone; apps with `action` open a panel elsewhere.
	local appDefs = {
		{ id = "phone", icon = "phone", label = "phone_tab_phone", color = Theme.malam },
		{ id = "kebun", icon = "garden", label = "phone_tab_kebun", color = Theme.daun },
		{ id = "pinjol", icon = "debt", label = "phone_tab_pinjol", color = Theme.genteng },
		{ id = "tugas", icon = "quest", label = "phone_tab_tugas", color = Theme.kunyit },
		{ id = "cheat", icon = "cheat", label = "phone_tab_cheat", color = Theme.merah },
		{ id = "dekor", icon = "hat", label = "phone_tab_dekor", color = Theme.indigo },
		{ id = "shop", icon = "shop", label = "hud_shop", color = Theme.padi, action = "shop" },
		{ id = "board", icon = "trophy", label = "phone_app_board", color = Theme.kunyit, action = "board" },
	}

	local currentScreen = "home"
	local appLabels: { [string]: TextLabel } = {}

	local function showScreen(screen: string)
		currentScreen = screen
		homePage.Visible = screen == "home"
		wallpaper.Visible = screen == "home"
		homePill.BackgroundColor3 = if screen == "home" then Theme.paper else Theme.ink
		backButton.Visible = screen ~= "home"
		if screen == "home" then
			titleLabel.Position = UDim2.fromOffset(12, 0)
			titleLabel.Size = UDim2.new(1, -110, 1, 0)
			titleLabel.Text = t("phone_title")
		else
			titleLabel.Position = UDim2.fromOffset(50, 0)
			titleLabel.Size = UDim2.new(1, -154, 1, 0)
			titleLabel.Text = t("phone_tab_" .. screen)
		end
		-- Only the current app page exists: the others are destroyed, this one is built and filled.
		registry:show(if screen == "home" then nil else screen)
	end

	backButton.Activated:Connect(function()
		Audio.play("ui_click")
		showScreen("home")
	end)

	for order, app in appDefs do
		local tile = Theme.new("TextButton", {
			Name = "App_" .. app.id,
			LayoutOrder = order,
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Text = "",
			Parent = homePage,
		})
		-- Rounded app icon (a sticker: paper square with an ink outline).
		local square = Theme.new("Frame", {
			Name = "Icon",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 4),
			-- Height follows width (RelativeXX): a 0 Y-scale with only an aspect constraint collapses to 0x0.
			Size = UDim2.fromScale(0.6, 0.6),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
			BackgroundColor3 = Theme.paper,
			BorderSizePixel = 0,
			Parent = tile,
		}, {
			Theme.corner(nil, 14),
			Theme.new("UIStroke", { Color = Theme.ink, Thickness = 2 }),
			Theme.new("UIAspectRatioConstraint", { AspectRatio = 1 }),
			Theme.new("UISizeConstraint", { MaxSize = Vector2.new(60, 60) }),
		})
		Icons.make(app.icon, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.62, 0.62),
			Color = app.color,
			Parent = square,
		})
		local label = Theme.label({
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, 0),
			Size = UDim2.new(1, 0, 0, 26),
			Text = t(app.label),
			TextColor3 = Theme.paper,
			TextStrokeColor3 = Theme.ink,
			TextStrokeTransparency = 0.3,
			TextWrapped = true,
			Parent = tile,
		})
		Theme.new("UITextSizeConstraint", { MaxTextSize = 14, MinTextSize = 11, Parent = label })
		appLabels[app.id] = label
		tile.Activated:Connect(function()
			Audio.play("ui_click")
			if app.action == "shop" then
				closePhone()
				require(script.Parent.Hud).openShop()
			elseif app.action == "board" then
				closePhone()
				require(script.Parent.Leaderboard).open()
			else
				showScreen(app.id)
			end
		end)
	end

	---------------------------------------------------------------- phone tab
	local itemRows = {
		{ item = "amplopPremium", key = "item_amplopPremium" },
		{ item = "jaminanKilat", key = "item_jaminanKilat" },
	}

	local function refreshPhoneTab()
		local page = registry:get("phone")
		clearChildren(page)
		local order = 1

		sectionLabel(page, t("phone_inventory"), order, "warehouse")
		order += 1
		for _, entry in itemRows do
			local count = player:GetAttribute("Item_" .. entry.item) or 0
			local row = Theme.new("Frame", {
				LayoutOrder = order,
				Size = UDim2.new(1, 0, 0, 48),
				BackgroundTransparency = 1,
				Parent = page,
			})
			order += 1
			Theme.label({
				Size = UDim2.new(0.62, 0, 1, 0),
				Text = t(entry.key) .. " x" .. count,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = Theme.ink,
				Parent = row,
			})
			local use = Theme.button({
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.fromScale(1, 0.5),
				Size = UDim2.new(0.34, 0, 0, 44),
				Text = t("phone_use"),
				BackgroundColor3 = if count > 0 then Theme.padi else Theme.bambu,
				Parent = row,
			})
			use.Active = count > 0
			use.Activated:Connect(function()
				Remotes.Item_Use:FireServer(entry.item)
			end)
		end

		sectionLabel(page, t("phone_bukti"), order, "evidence")
		order += 1
		local tokens = Evidence.getTokens()
		if #tokens == 0 then
			local empty = Theme.label({
				LayoutOrder = order,
				Size = UDim2.new(1, 0, 0, 30),
				Text = t("phone_empty"),
				TextColor3 = Theme.inkSoft,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = page,
			})
			empty.TextSize = 14
			order += 1
		else
			for _, token in tokens do
				local row = Theme.new("Frame", {
					LayoutOrder = order,
					Size = UDim2.new(1, 0, 0, 48),
					BackgroundColor3 = Theme.paper,
					Parent = page,
				}, {
					Theme.corner(nil, 8),
					Theme.new("UIPadding", {
						PaddingLeft = UDim.new(0, 8),
						PaddingRight = UDim.new(0, 8),
					}),
				})
				order += 1
				local minutes = math.max(0, math.ceil((token.expiresAt - os.time()) / 60))
				local label = Theme.label({
					Size = UDim2.new(0.64, 0, 1, 0),
					Text = t("cheat_" .. token.cheatId) .. " (" .. minutes .. "m)",
					TextXAlignment = Enum.TextXAlignment.Left,
					TextColor3 = Theme.ink,
					Parent = row,
				})
				label.TextSize = 14
				local report = Theme.button({
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.fromScale(1, 0.5),
					Size = UDim2.new(0.32, 0, 0, 44),
					Text = t("phone_lapor"),
					BackgroundColor3 = Theme.malam,
					Parent = row,
				})
				report.Activated:Connect(function()
					Remotes.Evidence_Report:FireServer(token.tokenId)
				end)
			end
		end

		local help = Theme.label({
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, 44),
			Text = t("phone_help"),
			TextColor3 = Theme.inkSoft,
			TextWrapped = true,
			Parent = page,
		})
		help.TextSize = 13
	end

	---------------------------------------------------------------- cheat tab
	local cheatSignature = ""

	local function ownPlot(): number
		return player:GetAttribute("PlotIndex") or 0
	end

	local function growingTiles(): { { tile: number, crop: string } }
		local result = {}
		local mine = ownPlot()
		for _, instance in CollectionService:GetTagged("Tile") do
			local tile = instance :: BasePart
			if tile:GetAttribute("PlotIndex") == mine and tile:GetAttribute("State") == "growing" then
				local crop = tile:GetAttribute("Crop")
				if type(crop) == "string" then
					table.insert(result, { tile = tile:GetAttribute("TileIndex"), crop = crop })
				end
			end
		end
		table.sort(result, function(a, b)
			return a.tile < b.tile
		end)
		return result
	end

	local function neighborPlayers(): { { player: Player, plot: number } }
		local result = {}
		local mine = ownPlot()
		if mine == 0 then
			return result
		end
		local world = workspace:FindFirstChild("World")
		if not world then
			return result
		end
		local wanted = {}
		for _, index in { ((mine - 2) % GameConfig.plotCount) + 1, (mine % GameConfig.plotCount) + 1 } do
			wanted[index] = true
		end
		for _, model in world:GetChildren() do
			local plotIndex = model:GetAttribute("PlotIndex")
			local ownerUserId = model:GetAttribute("OwnerUserId")
			if wanted[plotIndex] and type(ownerUserId) == "number" and ownerUserId > 0 then
				local other = Players:GetPlayerByUserId(ownerUserId)
				if other and other ~= player then
					table.insert(result, { player = other, plot = plotIndex })
				end
			end
		end
		table.sort(result, function(a, b)
			return a.plot < b.plot
		end)
		return result
	end

	local function refreshCheatTab(force: boolean?)
		local tiles = growingTiles()
		local neighbors = neighborPlayers()
		local signature = ""
		for _, tile in tiles do
			signature ..= tile.tile .. ":" .. tile.crop .. ";"
		end
		for _, neighbor in neighbors do
			signature ..= "n" .. neighbor.player.UserId .. ";"
		end
		signature ..= "b" .. tostring(player:GetAttribute("BribePrice"))
		if not force and signature == cheatSignature then
			return
		end
		cheatSignature = signature

		local page = registry:get("cheat")
		clearChildren(page)
		local order = 1

		sectionLabel(page, t("phone_cheat_title"), order, "cheat")
		order += 1

		sectionLabel(page, t("cheat_oplosan") .. " - Rp " .. Cheats.list.oplosan.cost, order, "warning")
		order += 1
		if #tiles == 0 then
			local empty = Theme.label({
				LayoutOrder = order,
				Size = UDim2.new(1, 0, 0, 28),
				Text = t("phone_no_growing"),
				TextColor3 = Theme.inkSoft,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = page,
			})
			empty.TextSize = 14
			order += 1
		else
			for _, tile in tiles do
				local button = Theme.button({
					LayoutOrder = order,
					Size = UDim2.new(1, 0, 0, 46),
					Text = t("phone_oplosan", "@crop_" .. tile.crop, Cheats.list.oplosan.cost),
					BackgroundColor3 = Theme.daun,
					Parent = page,
				})
				order += 1
				button.Activated:Connect(function()
					Remotes.Cheat_Apply:FireServer("oplosan", tile.tile)
				end)
			end
		end

		sectionLabel(page, t("cheat_curi_air"), order, "steal")
		order += 1
		if #neighbors == 0 then
			local empty = Theme.label({
				LayoutOrder = order,
				Size = UDim2.new(1, 0, 0, 28),
				Text = t("phone_no_neighbors"),
				TextColor3 = Theme.inkSoft,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = page,
			})
			empty.TextSize = 14
			order += 1
		else
			for _, neighbor in neighbors do
				local row = Theme.new("Frame", {
					LayoutOrder = order,
					Size = UDim2.new(1, 0, 0, 48),
					BackgroundTransparency = 1,
					Parent = page,
				})
				order += 1
				local label = Theme.label({
					Size = UDim2.new(0.32, 0, 1, 0),
					Text = neighbor.player.DisplayName,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextColor3 = Theme.ink,
					Parent = row,
				})
				label.TextSize = 14
				local steal = Theme.button({
					Position = UDim2.new(0.34, 0, 0, 2),
					Size = UDim2.new(0.32, -4, 0, 44),
					Text = t("phone_steal_short"),
					BackgroundColor3 = Theme.genteng,
					Parent = row,
				})
				steal.Activated:Connect(function()
					Remotes.Cheat_Apply:FireServer("curi_air", nil, neighbor.player.UserId)
				end)
				local water = Theme.button({
					Position = UDim2.new(0.68, 0, 0, 2),
					Size = UDim2.new(0.32, 0, 0, 44),
					Text = t("phone_water_short"),
					BackgroundColor3 = Theme.malam,
					Parent = row,
				})
				water.Activated:Connect(function()
					Remotes.Water_Neighbor:FireServer(neighbor.player.UserId)
				end)
			end
		end

		local bribeRow = Theme.new("Frame", {
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, 46),
			BackgroundTransparency = 1,
			Parent = page,
		})
		order += 1
		local price = player:GetAttribute("BribePrice") or 100
		local bribe = Theme.button({
			Size = UDim2.fromScale(1, 1),
			Text = t("prompt_bribe", price),
			BackgroundColor3 = Theme.kunyit,
			Parent = bribeRow,
		})
		bribe.Activated:Connect(function()
			Remotes.Bribe_RT:FireServer()
		end)
	end

	---------------------------------------------------------------- decor tab
	local decorSignature = ""

	local function refreshDecorTab(force: boolean?)
		local signature = tostring(player:GetAttribute("EquippedCosmetic")) .. "|" .. tostring(player:GetAttribute("Cash"))
		for itemId in CosmeticsConfig.list do
			signature ..= "|" .. itemId .. tostring(player:GetAttribute("Cosmetic_" .. itemId))
		end
		if not force and signature == decorSignature then
			return
		end
		decorSignature = signature

		local page = registry:get("dekor")
		clearChildren(page)
		local order = 1
		sectionLabel(page, t("phone_tab_dekor"), order, "hat")
		order += 1
		local equipped = player:GetAttribute("EquippedCosmetic")

		for _, itemId in CosmeticsConfig.order do
			local item = CosmeticsConfig.list[itemId]
			local owned = player:GetAttribute("Cosmetic_" .. itemId) == true
			local row = Theme.new("Frame", {
				LayoutOrder = order,
				Size = UDim2.new(1, 0, 0, 52),
				BackgroundColor3 = Theme.paper,
				Parent = page,
			}, {
				Theme.corner(nil, 8),
				Theme.new("UIPadding", {
					PaddingLeft = UDim.new(0, 8),
					PaddingRight = UDim.new(0, 8),
				}),
			})
			order += 1
			Theme.label({
				Size = UDim2.new(0.5, 0, 1, 0),
				Text = t("cosmetic_" .. itemId),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = Theme.ink,
				Parent = row,
			})
			local action
			if not owned then
				action = Theme.button({
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.fromScale(1, 0.5),
					Size = UDim2.new(0.46, 0, 0, 44),
					Text = t("phone_cosmetic_buy", item.price),
					BackgroundColor3 = Theme.padi,
					Parent = row,
				})
				action.Activated:Connect(function()
					Remotes.Cosmetic_Buy:FireServer(itemId)
				end)
			elseif equipped == itemId then
				action = Theme.button({
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.fromScale(1, 0.5),
					Size = UDim2.new(0.46, 0, 0, 44),
					Text = t("phone_cosmetic_unequip"),
					BackgroundColor3 = Theme.red,
					Parent = row,
				})
				action.Activated:Connect(function()
					Remotes.Cosmetic_Equip:FireServer(nil)
				end)
			else
				action = Theme.button({
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.fromScale(1, 0.5),
					Size = UDim2.new(0.46, 0, 0, 44),
					Text = t("phone_cosmetic_equip"),
					BackgroundColor3 = Theme.malam,
					Parent = row,
				})
				action.Activated:Connect(function()
					Remotes.Cosmetic_Equip:FireServer(itemId)
				end)
			end
		end
	end

	---------------------------------------------------------------- kebun tab (gudang, tools, prices)
	local kebunSignature = ""

	local function refreshKebunTab(force: boolean?)
		local signature = tostring(player:GetAttribute("GudangUsed"))
			.. "|" .. tostring(player:GetAttribute("GudangCapacity"))
			.. "|" .. tostring(player:GetAttribute("Cash"))
			.. "|w" .. tostring(player:GetAttribute("WorkerUntil"))
		for _, lineId in ToolsConfig.order do
			signature ..= "|" .. lineId .. tostring(player:GetAttribute("Tool_" .. lineId))
		end
		for _, cropId in Crops.order do
			signature ..= "|" .. tostring(ReplicatedStorage:GetAttribute("Market_" .. cropId))
		end
		if not force and signature == kebunSignature then
			return
		end
		kebunSignature = signature

		local page = registry:get("kebun")
		clearChildren(page)
		local order = 1
		local used = player:GetAttribute("GudangUsed") or 0
		local capacity = player:GetAttribute("GudangCapacity") or GameConfig.gudangBaseCapacity

		sectionLabel(page, t("phone_gudang", used, capacity), order, "warehouse")
		order += 1
		local store = Theme.button({
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, 46),
			Text = t("phone_gudang_deposit"),
			BackgroundColor3 = Theme.padi,
			Parent = page,
		})
		order += 1
		store.Activated:Connect(function()
			Remotes.Storage_Deposit:FireServer()
		end)
		local take = Theme.button({
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, 46),
			Text = t("phone_gudang_withdraw"),
			BackgroundColor3 = Theme.malam,
			Parent = page,
		})
		order += 1
		take.Activated:Connect(function()
			Remotes.Storage_Withdraw:FireServer()
		end)

		sectionLabel(page, t("phone_buruh"), order, "worker")
		order += 1
		local workerUntil = player:GetAttribute("WorkerUntil") or 0
		local workerActive = player:GetAttribute("WorkerActive") == true
		local workerRow = Theme.new("Frame", {
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, 48),
			BackgroundTransparency = 1,
			Parent = page,
		})
		order += 1
		if workerActive then
			local label = Theme.label({
				Size = UDim2.fromScale(1, 1),
				Text = t("phone_buruh_active", os.date("%H:%M", workerUntil)),
				TextColor3 = Theme.inkSoft,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = workerRow,
			})
			label.TextSize = 14
		else
			local hire = Theme.button({
				Size = UDim2.fromScale(1, 1),
				Text = t("phone_buruh_hire", math.floor(WorkerConfig.hireSeconds / 60), WorkerConfig.hireCost),
				BackgroundColor3 = Theme.kunyit,
				Parent = workerRow,
			})
			hire.Activated:Connect(function()
				Remotes.Worker_Hire:FireServer()
			end)
		end

		sectionLabel(page, t("phone_alat"), order, "tools")
		order += 1
		for _, lineId in ToolsConfig.order do
			local line = ToolsConfig.list[lineId]
			local owned = player:GetAttribute("Tool_" .. lineId)
			local nextTier = ToolsConfig.next(lineId, owned)
			local row = Theme.new("Frame", {
				LayoutOrder = order,
				Size = UDim2.new(1, 0, 0, 52),
				BackgroundColor3 = Theme.paper,
				Parent = page,
			}, {
				Theme.corner(nil, 8),
				Theme.new("UIPadding", {
					PaddingLeft = UDim.new(0, 8),
					PaddingRight = UDim.new(0, 8),
				}),
			})
			order += 1

			local label = Theme.label({
				Size = UDim2.new(0.48, 0, 1, 0),
				Text = t(line.label) .. (if owned then " - " .. t("tool_tier_" .. owned) else ""),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = Theme.ink,
				Parent = row,
			})
			label.TextSize = 14

			if nextTier then
				local buy = Theme.button({
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.fromScale(1, 0.5),
					Size = UDim2.new(0.48, 0, 0, 44),
					Text = t("phone_tool_next", t("tool_tier_" .. nextTier.id), nextTier.cost),
					BackgroundColor3 = Theme.padi,
					Parent = row,
				})
				buy.Activated:Connect(function()
					Remotes.Tool_Buy:FireServer(lineId)
				end)
			else
				local maxed = Theme.label({
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.fromScale(1, 0.5),
					Size = UDim2.new(0.48, 0, 0, 44),
					Text = t("phone_tool_max"),
					TextColor3 = Theme.inkSoft,
					TextXAlignment = Enum.TextXAlignment.Right,
					Parent = row,
				})
				maxed.TextSize = 13
			end
		end

		sectionLabel(page, t("phone_harga"), order, "price")
		order += 1
		for _, cropId in Crops.order do
			local multiplier = ReplicatedStorage:GetAttribute("Market_" .. cropId) or 1
			local arrow = if multiplier > 1.02 then "^" elseif multiplier < 0.98 then "v" else "-"
			local arrowColor = if multiplier > 1.02 then Theme.daun elseif multiplier < 0.98 then Theme.merah else Theme.inkSoft
			local row = Theme.new("Frame", {
				LayoutOrder = order,
				Size = UDim2.new(1, 0, 0, 28),
				BackgroundTransparency = 1,
				Parent = page,
			})
			order += 1
			local arrowLabel = Theme.label({
				Size = UDim2.new(0, 20, 1, 0),
				Text = arrow,
				TextColor3 = arrowColor,
				Font = Theme.displayFont,
				Parent = row,
			})
			arrowLabel.TextSize = 14
			local label = Theme.label({
				Position = UDim2.new(0, 24, 0, 0),
				Size = UDim2.new(1, -24, 1, 0),
				Text = t("phone_price_line", "", t("crop_" .. cropId), string.format("%.2f", multiplier)),
				TextColor3 = Theme.ink,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = row,
			})
			label.TextSize = 14
		end
	end

	---------------------------------------------------------------- pinjol tab
	local function refreshPinjolTab()
		local page = registry:get("pinjol")
		clearChildren(page)
		local order = 1

		sectionLabel(page, t("phone_pinjol_title"), order, "debt")
		order += 1

		local rank = player:GetAttribute("Rank") or "gurem"
		local namaBaik = player:GetAttribute("NamaBaik") or 50
		local maxLimit = PinjolConfig.calcLimit(rank, namaBaik)
		local isOwed = player:GetAttribute("DebtActive") == true
		local owed = player:GetAttribute("DebtOwed") or 0
		local dueAt = player:GetAttribute("DebtDueAt") or 0

		local _limitLabel = Theme.label({
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, 26),
			Text = t("phone_pinjol_limit", Strings.formatNumber(maxLimit, activeLang)),
			TextColor3 = Theme.merah,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = page,
		})
		order += 1

		if isOwed and owed > 0 then
			local _owedLabel = Theme.label({
				LayoutOrder = order,
				Size = UDim2.new(1, 0, 0, 26),
				Text = t("phone_pinjol_owed", Strings.formatNumber(owed, activeLang)),
				TextColor3 = Theme.red,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = page,
			})
			order += 1

			local remaining = math.max(0, math.ceil(dueAt - os.time()))
			local dueText = string.format("%d:%02d", math.floor(remaining / 60), remaining % 60)
			local _dueLabel = Theme.label({
				LayoutOrder = order,
				Size = UDim2.new(1, 0, 0, 26),
				Text = t("phone_pinjol_due", dueText),
				TextColor3 = if remaining <= 0 then Theme.red else Theme.inkSoft,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = page,
			})
			order += 1

			local repayBtn = Theme.button({
				LayoutOrder = order,
				Size = UDim2.new(1, 0, 0, 46),
				Text = t("phone_pinjol_repay", Strings.formatNumber(owed, activeLang)),
				BackgroundColor3 = Theme.padi,
				Parent = page,
			})
			order += 1
			repayBtn.Activated:Connect(function()
				Remotes.Debt_Repay:FireServer()
			end)
		else
			local _clearLabel = Theme.label({
				LayoutOrder = order,
				Size = UDim2.new(1, 0, 0, 26),
				Text = t("phone_pinjol_clear"),
				TextColor3 = Theme.text,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = page,
			})
			order += 1

			local borrowAmounts = { math.floor(maxLimit * 0.5), maxLimit }
			for _, amt in borrowAmounts do
				if amt > 0 then
					local bBtn = Theme.button({
						LayoutOrder = order,
						Size = UDim2.new(1, 0, 0, 46),
						Text = t("phone_pinjol_borrow", Strings.formatNumber(amt, activeLang)),
						BackgroundColor3 = Theme.malam,
						Parent = page,
					})
					order += 1
					bBtn.Activated:Connect(function()
						Remotes.Debt_Borrow:FireServer(amt)
					end)
				end
			end
		end
	end

	---------------------------------------------------------------- tugas tab
	local function refreshTugasTab()
		local page = registry:get("tugas")
		clearChildren(page)
		local order = 1

		local streak = player:GetAttribute("LoginStreak") or 1
		local claimed = player:GetAttribute("LoginClaimed") == true

		sectionLabel(page, t("phone_tugas_login", streak), order, "calendar")
		order += 1

		local loginBtn = Theme.button({
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, 46),
			Text = if claimed then t("phone_tugas_claimed") else t("phone_tugas_claim_login"),
			BackgroundColor3 = if claimed then Theme.bambu else Theme.kunyit,
			Parent = page,
		})
		order += 1
		loginBtn.Active = not claimed
		loginBtn.Activated:Connect(function()
			Remotes.Quest_ClaimDaily:FireServer()
		end)

		sectionLabel(page, t("phone_tugas_daily"), order, "quest")
		order += 1

		local qData = ClientState.get("quests") or {}
		local tasks = qData.tasks or {}
		for taskId, task in tasks do
			local def = nil
			for _, p in QuestsConfig.taskPool do
				if p.id == taskId then
					def = p
					break
				end
			end
			if def then
				local row = Theme.card({
					Name = "Task_" .. taskId,
					LayoutOrder = order,
					Size = UDim2.new(1, 0, 0, 56),
					BackgroundColor3 = Theme.paper,
					Parent = page,
				})
				order += 1

				local pLeft = Instance.new("UIPadding")
				pLeft.PaddingLeft = UDim.new(0, 8)
				pLeft.PaddingRight = UDim.new(0, 8)
				pLeft.Parent = row

				Theme.label({
					Position = UDim2.fromScale(0, 0.08),
					Size = UDim2.new(0.64, 0, 0.44, 0),
					Text = t(def.labelKey),
					TextColor3 = Theme.ink,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = row,
				})

				local prog = task.progress or 0
				local tgt = task.target or 1
				local isReady = prog >= tgt and not task.done

				Theme.label({
					Position = UDim2.fromScale(0, 0.54),
					Size = UDim2.new(0.64, 0, 0.4, 0),
					Text = t("phone_tugas_progress", prog, tgt) .. " (+Rp " .. def.rewardCash .. ")",
					TextColor3 = Theme.inkSoft,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = row,
				})

				local claimBtn = Theme.button({
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.fromScale(1, 0.5),
					Size = UDim2.new(0.32, 0, 0, 44),
					Text = if task.done then t("phone_tugas_claimed") else t("phone_tugas_claim"),
					BackgroundColor3 = if task.done then Theme.bambu elseif isReady then Theme.padi else Theme.paper,
					Parent = row,
				})
				claimBtn.Active = isReady
				claimBtn.Activated:Connect(function()
					Remotes.Quest_ClaimTask:FireServer(taskId)
				end)
			end
		end
	end

	---------------------------------------------------------------- wiring
	local lastPhoneSignature = ""
	local function refreshPhoneIfChanged()
		local signature = ""
		for _, entry in itemRows do
			signature ..= tostring(player:GetAttribute("Item_" .. entry.item)) .. ","
		end
		signature ..= "#" .. #Evidence.getTokens()
		for _, token in Evidence.getTokens() do
			signature ..= token.tokenId
		end
		if signature ~= lastPhoneSignature then
			lastPhoneSignature = signature
			refreshPhoneTab()
		end
	end

	-- A destroyed page must be refilled by the next build, so the change signatures are reset.
	local function resetSignatures()
		lastPhoneSignature = ""
		kebunSignature = ""
		cheatSignature = ""
		decorSignature = ""
	end

	-- Phone app pages are built on first open (not at mount) and destroyed on leaving them.
	-- Every page reads its state from player attributes / ClientState / Evidence when applied,
	-- so nothing is pushed into a page that does not exist; `apply` is the refresh function.
	local function pageDef(name: string, refresh: () -> ())
		return {
			build = function()
				return scrollPage(content, name)
			end,
			apply = function()
				refresh()
			end,
			destroy = function(instance: Instance)
				instance:Destroy()
				resetSignatures()
			end,
		}
	end
	registry = LazyPages.new({
		phone = pageDef("PagePhone", refreshPhoneIfChanged),
		kebun = pageDef("PageKebun", function()
			refreshKebunTab()
		end),
		pinjol = pageDef("PagePinjol", refreshPinjolTab),
		tugas = pageDef("PageTugas", refreshTugasTab),
		cheat = pageDef("PageCheat", function()
			refreshCheatTab()
		end),
		dekor = pageDef("PageDekor", function()
			refreshDecorTab()
		end),
	})

	-- Refreshes the open app page; a no-op on home or when its page is not built.
	local function refreshCurrent()
		registry:refresh(currentScreen)
	end

	local function setPhoneLanguage(newLang: string)
		activeLang = newLang
		ctx.state.lang = newLang
		langToggle.Text = activeLang:upper()
		for _, app in appDefs do
			local lbl = appLabels[app.id]
			if lbl then
				lbl.Text = t(app.label)
			end
		end
		if currentScreen == "home" then
			titleLabel.Text = t("phone_title")
		else
			titleLabel.Text = t("phone_tab_" .. currentScreen)
		end
		resetSignatures()
		if root.Visible and currentScreen ~= "home" then
			refreshCurrent()
		end
	end

	langToggle.Activated:Connect(function()
		local nextLang = if activeLang == "id" then "en" else "id"
		Hud.setLanguage(nextLang)
		setPhoneLanguage(nextLang)
	end)

	local function open()
		Audio.play("ui_open")
		root.Visible = true
		toggle.Visible = false
		updateClock()
		resetSignatures()
		showScreen("home")
	end

	close.Activated:Connect(closePhone)
	-- WORK_QUEUE item 21: B/Escape closes the phone; selecting it focuses the X button.
	NavBridge.register("phone", {
		root = root,
		default = close,
		onClose = closePhone,
	})
	homeBar.Activated:Connect(function()
		if currentScreen == "home" then
			closePhone()
		else
			showScreen("home")
		end
	end)
	root.InputBegan:Connect(function(input)
		local kind = input.UserInputType
		if (kind == Enum.UserInputType.Touch or kind == Enum.UserInputType.MouseButton1) and input.Position then
			-- scrim tap closes only when the device was not hit; device buttons swallow input
			local cardPos = card.AbsolutePosition
			local cardSize = card.AbsoluteSize
			local p = input.Position
			local inside = p.X >= cardPos.X and p.X <= cardPos.X + cardSize.X
				and p.Y >= cardPos.Y and p.Y <= cardPos.Y + cardSize.Y
			if not inside then
				closePhone()
			end
		end
	end)

	Evidence.onChanged(function()
		if root.Visible and currentScreen == "phone" then
			lastPhoneSignature = ""
			refreshCurrent()
		end
	end)
	player.AttributeChanged:Connect(function()
		if root.Visible then
			refreshCurrent()
		end
	end)

	-- Once a second: the status-bar clock, and the open tab (tiles change state, neighbors join/leave).
	task.spawn(function()
		while true do
			task.wait(1)
			if root.Visible then
				updateClock()
				if currentScreen ~= "home" then
					refreshCurrent()
				end
			end
		end
	end)

	showScreen("home")
	return open, setPhoneLanguage
end

-- Only the toggle button exists at mount; the device is built by the first tap on it.
function Phone.mount(initialLang: string?)
	-- Default language is Indonesian ("id").
	local state = { lang = if initialLang == "en" then "en" else "id" }
	local Hud = require(script.Parent.Hud)
	local t = function(key: string, ...: any): string
		return Strings.get(state.lang, key, ...)
	end

	-- Above the HUD (DisplayOrder 10) so the dim backdrop covers the Next Goal card and stats.
	local gui = Theme.screenGui("Phone", 20)
	-- The scrim must cover the whole screen, including the top-bar strip where the HUD goal card sits.
	gui.IgnoreGuiInset = true

	-- The only top-right control: a small phone. Hidden while the phone is open.
	local toggle = Theme.new("TextButton", {
		Name = "PhoneButton",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 10),
		Size = UDim2.fromOffset(44, 64),
		BackgroundColor3 = Theme.ink,
		BorderSizePixel = 0,
		AutoButtonColor = true,
		Text = "",
		Parent = gui,
	}, {
		Theme.corner(nil, 10),
		Theme.new("UIStroke", { Color = Theme.inkSoft, Thickness = 2 }),
		Theme.new("UISizeConstraint", { MinSize = Vector2.new(44, 64), MaxSize = Vector2.new(56, 80) }),
	})
	local lit = Theme.new("Frame", {
		Name = "LitScreen",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -8, 1, -12),
		BackgroundColor3 = Theme.malam,
		BorderSizePixel = 0,
		Parent = toggle,
	}, {
		Theme.corner(nil, 6),
		Theme.new("UIGradient", { Color = ColorSequence.new(Theme.malam, Theme.indigo), Rotation = 90 }),
	})
	local litLabel = Theme.label({
		Name = "Label",
		Size = UDim2.fromScale(1, 1),
		Text = t("hud_phone"),
		Font = Theme.displayFont,
		TextColor3 = Theme.paper,
		Parent = lit,
	})
	Theme.new("UITextSizeConstraint", { MaxTextSize = 14, MinTextSize = 11, Parent = litLabel })

	local ensureBuilt = LazyPages.once(buildDevice)
	local openDevice: (() -> ())? = nil
	local setBuiltLanguage: ((string) -> ())? = nil

	-- Works before and after the first build: before it the language is only remembered
	-- (the build reads it); after it the built device updates its labels too.
	local function setLanguage(newLang: string)
		state.lang = newLang
		litLabel.Text = t("hud_phone")
		if setBuiltLanguage then
			setBuiltLanguage(newLang)
		end
	end
	setPhoneLanguageFn = setLanguage
	Hud.onLanguageChanged = function(newLang: string)
		if state.lang ~= newLang then
			setLanguage(newLang)
		end
	end

	toggle.Activated:Connect(function()
		if not openDevice then
			openDevice, setBuiltLanguage = ensureBuilt({ gui = gui, toggle = toggle, state = state })
		end
		(openDevice :: () -> ())()
	end)
end

return Phone
