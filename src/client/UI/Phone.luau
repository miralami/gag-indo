-- Phone: bukti tokens + Lapor, inventory (amplop/bail), the cheat menu and decor shop.
-- All actions are requests; the server re-checks distance, ownership and money.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Cheats = require(Shared.Config.Cheats)
local CosmeticsConfig = require(Shared.Config.Cosmetics)
local GameConfig = require(Shared.Config.Game)
local Strings = require(Shared.Strings)
local Remotes = require(Shared.Remotes)

local Theme = require(script.Parent.Theme)
local Evidence = require(script.Parent.Evidence)

local player = Players.LocalPlayer

local Phone = {}

local function clearChildren(frame: Instance)
	for _, child in frame:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function sectionLabel(parent: Instance, text: string, order: number): TextLabel
	local label = Theme.label({
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 24),
		Text = text,
		TextColor3 = Theme.accent,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = parent,
	})
	label.TextSize = 18
	return label
end

local function scrollPage(parent: Instance, name: string): ScrollingFrame
	local page = Theme.new("ScrollingFrame", {
		Name = name,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = parent,
	}, {
		Theme.new("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
		}),
		Theme.new("UIPadding", {
			PaddingRight = UDim.new(0, 6),
			PaddingBottom = UDim.new(0, 8),
		}),
	})
	return page
end

function Phone.mount(lang: string)
	local t = function(key: string, ...: any): string
		return Strings.get(lang, key, ...)
	end

	local gui = Theme.screenGui("Phone", 30)

	-- Toggle button lives in the HUD's top-right column so both buttons line up.
	local hud = player:WaitForChild("PlayerGui"):WaitForChild("Hud", 20)
	local column = hud and hud:FindFirstChild("Buttons") :: Frame?
	local toggle = Theme.button({
		Name = "PhoneButton",
		LayoutOrder = 2,
		Size = UDim2.fromScale(1, 0.5),
		BackgroundColor3 = Theme.blue,
		Text = t("hud_phone"),
		Parent = column or gui,
	})
	if not column then
		toggle.AnchorPoint = Vector2.new(1, 0)
		toggle.Position = UDim2.new(1, -10, 0, 72)
		toggle.Size = UDim2.new(0.18, 0, 0.075, 0)
	end

	-- Full-screen scrim + card
	local root = Theme.new("Frame", {
		Name = "Root",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.45,
		Visible = false,
		Parent = gui,
	})

	local card = Theme.card({
		Name = "Card",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.9, 0.84),
		Parent = root,
	}, {
		Theme.new("UISizeConstraint", { MinSize = Vector2.new(290, 320), MaxSize = Vector2.new(520, 680) }),
		Theme.new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) }),
	})
	local cardPadding = Instance.new("UIPadding")
	cardPadding.PaddingLeft = UDim.new(0, 12)
	cardPadding.PaddingRight = UDim.new(0, 12)
	cardPadding.PaddingTop = UDim.new(0, 10)
	cardPadding.PaddingBottom = UDim.new(0, 10)
	cardPadding.Parent = card

	local header = Theme.new("Frame", {
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1,
		Parent = card,
	})
	Theme.label({
		Size = UDim2.new(0.75, 0, 1, 0),
		Text = t("phone_title"),
		TextColor3 = Theme.accent,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = header,
	})
	local close = Theme.button({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.new(0.22, 0, 1, 0),
		Text = "✕",
		BackgroundColor3 = Theme.red,
		Parent = header,
	})

	local tabsRow = Theme.new("Frame", {
		LayoutOrder = 2,
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		Parent = card,
	}, {
		Theme.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0.02, 0),
		}),
	})

	-- Card inner height minus header (34), tab row (40) and the two 6 px list gaps.
	local content = Theme.new("Frame", {
		LayoutOrder = 3,
		Size = UDim2.new(1, 0, 1, -106),
		BackgroundTransparency = 1,
		Parent = card,
	})

	local pages: { [string]: ScrollingFrame } = {
		phone = scrollPage(content, "PagePhone"),
		cheat = scrollPage(content, "PageCheat"),
		dekor = scrollPage(content, "PageDekor"),
	}
	for _, page in pages do
		page.Size = UDim2.fromScale(1, 1)
	end

	local tabButtons: { [string]: TextButton } = {}
	local tabOrder = { "phone", "cheat", "dekor" }
	local activeTab = "phone"
	local refreshCurrent: () -> () = function() end

	local function showTab(tab: string)
		activeTab = tab
		for name, page in pages do
			page.Visible = name == tab
		end
		for name, button in tabButtons do
			button.BackgroundColor3 = if name == tab then Theme.accent else Theme.panelLight
			button.TextColor3 = if name == tab then Color3.fromRGB(30, 30, 30) else Theme.text
		end
		refreshCurrent()
	end

	for order, tab in tabOrder do
		local button = Theme.button({
			LayoutOrder = order,
			Size = UDim2.fromScale(0.32, 1),
			Text = t("phone_tab_" .. tab),
			Parent = tabsRow,
		})
		button.Activated:Connect(function()
			showTab(tab)
		end)
		tabButtons[tab] = button
	end

	---------------------------------------------------------------- phone tab
	local itemRows = {
		{ item = "amplopPremium", key = "item_amplopPremium" },
		{ item = "jaminanKilat", key = "item_jaminanKilat" },
	}

	local function refreshPhoneTab()
		local page = pages.phone
		clearChildren(page)
		local order = 1

		sectionLabel(page, t("phone_inventory"), order)
		order += 1
		for _, entry in itemRows do
			local count = player:GetAttribute("Item_" .. entry.item) or 0
			local row = Theme.new("Frame", {
				LayoutOrder = order,
				Size = UDim2.new(1, 0, 0, 44),
				BackgroundTransparency = 1,
				Parent = page,
			})
			order += 1
			Theme.label({
				Size = UDim2.new(0.62, 0, 1, 0),
				Text = t(entry.key) .. " x" .. count,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = row,
			})
			local use = Theme.button({
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.fromScale(1, 0.5),
				Size = UDim2.new(0.34, 0, 0.86, 0),
				Text = t("phone_use"),
				BackgroundColor3 = if count > 0 then Theme.green else Theme.panelLight,
				Parent = row,
			})
			use.Active = count > 0
			use.Activated:Connect(function()
				Remotes.Item_Use:FireServer(entry.item)
			end)
		end

		sectionLabel(page, "📱 " .. t("phone_bukti"), order)
		order += 1
		local tokens = Evidence.getTokens()
		if #tokens == 0 then
			local empty = Theme.label({
				LayoutOrder = order,
				Size = UDim2.new(1, 0, 0, 30),
				Text = t("phone_empty"),
				TextColor3 = Theme.muted,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = page,
			})
			empty.TextSize = 14
			order += 1
		else
			for _, token in tokens do
				local row = Theme.new("Frame", {
					LayoutOrder = order,
					Size = UDim2.new(1, 0, 0, 46),
					BackgroundColor3 = Theme.panelLight,
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
					Parent = row,
				})
				label.TextSize = 15
				local report = Theme.button({
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.fromScale(1, 0.5),
					Size = UDim2.new(0.32, 0, 0.8, 0),
					Text = t("phone_lapor"),
					BackgroundColor3 = Theme.blue,
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
			TextColor3 = Theme.muted,
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

		local page = pages.cheat
		clearChildren(page)
		local order = 1

		sectionLabel(page, "😈 " .. t("phone_cheat_title"), order)
		order += 1

		sectionLabel(page, t("cheat_oplosan") .. " · Rp " .. Cheats.list.oplosan.cost, order)
		order += 1
		if #tiles == 0 then
			local empty = Theme.label({
				LayoutOrder = order,
				Size = UDim2.new(1, 0, 0, 28),
				Text = t("phone_no_growing"),
				TextColor3 = Theme.muted,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = page,
			})
			empty.TextSize = 14
			order += 1
		else
			for _, tile in tiles do
				local button = Theme.button({
					LayoutOrder = order,
					Size = UDim2.new(1, 0, 0, 42),
					Text = t("phone_oplosan", "@crop_" .. tile.crop, Cheats.list.oplosan.cost),
					BackgroundColor3 = Color3.fromRGB(80, 110, 60),
					Parent = page,
				})
				order += 1
				button.Activated:Connect(function()
					Remotes.Cheat_Apply:FireServer("oplosan", tile.tile)
				end)
			end
		end

		sectionLabel(page, t("cheat_curi_air"), order)
		order += 1
		if #neighbors == 0 then
			local empty = Theme.label({
				LayoutOrder = order,
				Size = UDim2.new(1, 0, 0, 28),
				Text = t("phone_no_neighbors"),
				TextColor3 = Theme.muted,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = page,
			})
			empty.TextSize = 14
			order += 1
		else
			for _, neighbor in neighbors do
				local row = Theme.new("Frame", {
					LayoutOrder = order,
					Size = UDim2.new(1, 0, 0, 44),
					BackgroundTransparency = 1,
					Parent = page,
				})
				order += 1
				local label = Theme.label({
					Size = UDim2.new(0.34, 0, 1, 0),
					Text = neighbor.player.DisplayName,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = row,
				})
				label.TextSize = 15
				local steal = Theme.button({
					Position = UDim2.fromScale(0.35, 0),
					Size = UDim2.fromScale(0.32, 1),
					Text = t("phone_steal_short"),
					BackgroundColor3 = Color3.fromRGB(110, 60, 50),
					Parent = row,
				})
				steal.Activated:Connect(function()
					Remotes.Cheat_Apply:FireServer("curi_air", nil, neighbor.player.UserId)
				end)
				local water = Theme.button({
					Position = UDim2.fromScale(0.68, 0),
					Size = UDim2.fromScale(0.32, 1),
					Text = t("phone_water_short"),
					BackgroundColor3 = Color3.fromRGB(50, 100, 70),
					Parent = row,
				})
				water.Activated:Connect(function()
					Remotes.Water_Neighbor:FireServer(neighbor.player.UserId)
				end)
			end
		end

		local bribeRow = Theme.new("Frame", {
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, 44),
			BackgroundTransparency = 1,
			Parent = page,
		})
		order += 1
		local price = player:GetAttribute("BribePrice") or 100
		local bribe = Theme.button({
			Size = UDim2.fromScale(1, 1),
			Text = t("prompt_bribe", price),
			BackgroundColor3 = Color3.fromRGB(120, 100, 50),
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

		local page = pages.dekor
		clearChildren(page)
		local order = 1
		sectionLabel(page, "🎩 " .. t("phone_tab_dekor"), order)
		order += 1
		local equipped = player:GetAttribute("EquippedCosmetic")

		for _, itemId in CosmeticsConfig.order do
			local item = CosmeticsConfig.list[itemId]
			local owned = player:GetAttribute("Cosmetic_" .. itemId) == true
			local row = Theme.new("Frame", {
				LayoutOrder = order,
				Size = UDim2.new(1, 0, 0, 48),
				BackgroundColor3 = Theme.panelLight,
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
				Parent = row,
			})
			local action
			if not owned then
				action = Theme.button({
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.fromScale(1, 0.5),
					Size = UDim2.new(0.44, 0, 0.8, 0),
					Text = t("phone_cosmetic_buy", item.price),
					BackgroundColor3 = Theme.green,
					Parent = row,
				})
				action.Activated:Connect(function()
					Remotes.Cosmetic_Buy:FireServer(itemId)
				end)
			elseif equipped == itemId then
				action = Theme.button({
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.fromScale(1, 0.5),
					Size = UDim2.new(0.44, 0, 0.8, 0),
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
					Size = UDim2.new(0.44, 0, 0.8, 0),
					Text = t("phone_cosmetic_equip"),
					BackgroundColor3 = Theme.blue,
					Parent = row,
				})
				action.Activated:Connect(function()
					Remotes.Cosmetic_Equip:FireServer(itemId)
				end)
			end
		end
	end

	---------------------------------------------------------------- wiring
	local lastPhoneSignature = ""
	refreshCurrent = function()
		if activeTab == "phone" then
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
		elseif activeTab == "cheat" then
			refreshCheatTab()
		else
			refreshDecorTab()
		end
	end

	local function open()
		root.Visible = true
		lastPhoneSignature = ""
		cheatSignature = ""
		decorSignature = ""
		refreshCurrent()
	end

	local function closePhone()
		root.Visible = false
	end

	toggle.Activated:Connect(function()
		if root.Visible then
			closePhone()
		else
			open()
		end
	end)
	close.Activated:Connect(closePhone)
	root.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch and input.Position then
			-- scrim tap closes only when the card was not hit; card buttons swallow input
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
		if root.Visible and activeTab == "phone" then
			lastPhoneSignature = ""
			refreshCurrent()
		end
	end)
	player.AttributeChanged:Connect(function()
		if root.Visible then
			refreshCurrent()
		end
	end)

	-- Refresh the open tab once a second (tiles change state, neighbors join/leave).
	task.spawn(function()
		while true do
			task.wait(1)
			if root.Visible then
				refreshCurrent()
			end
		end
	end)

	showTab("phone")
end

return Phone
