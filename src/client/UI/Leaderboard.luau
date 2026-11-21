-- Leaderboard UI: a compact three-tab panel plus optional boards on parts tagged
-- `LeaderboardBoard` (the Balai Desa board). Reads only Leaderboard_Data; the payload is
-- validated with shared/Leaderboard before anything is rendered.

local CollectionService = game:GetService("CollectionService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Strings = require(Shared.Strings)
local Leaderboard = require(Shared.Leaderboard)

local Theme = require(script.Parent.Theme)
local NavBridge = require(script.Parent.NavBridge)


local LeaderboardUI = {}

local TABS = {
	{ id = "richest", label = "lb_tab_richest", value = "lb_value_richest" },
	{ id = "sultan", label = "lb_tab_sultan", value = "lb_value_sultan" },
	{ id = "raids", label = "lb_tab_raids", value = "lb_value_raids" },
}

local function clear(holder: Instance)
	for _, child in holder:GetChildren() do
		if child:IsA("TextLabel") or child:IsA("Frame") then
			child:Destroy()
		end
	end
end

function LeaderboardUI.mount(lang: string)
	local t = function(key: string, ...: any): string
		return Strings.get(lang, key, ...)
	end

	local gui = Theme.screenGui("Leaderboard", 12)
	local boards = Leaderboard.emptyBoards()
	local current = "richest"

	-- No HUD button: the phone opens the board through LeaderboardUI.open().
	local panel = Theme.card({
		Name = "Panel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.56, 0.62),
		Visible = false,
		Parent = gui,
	}, {
		Theme.new("UISizeConstraint", { MinSize = Vector2.new(280, 300), MaxSize = Vector2.new(520, 460) }),
	})
	Theme.padding(panel, 12)

	Theme.label({
		Name = "Title",
		Size = UDim2.new(1, 0, 0, 28),
		Text = t("lb_title"),
		Font = Theme.displayFont,
		TextColor3 = Theme.merah,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = panel,
	})

	local tabRow = Theme.new("Frame", {
		Name = "Tabs",
		Position = UDim2.new(0, 0, 0, 32),
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		Parent = panel,
	}, {
		Theme.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
		}),
	})

	local list = Theme.new("ScrollingFrame", {
		Name = "Rows",
		Position = UDim2.new(0, 0, 0, 78),
		Size = UDim2.new(1, 0, 1, -118),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = panel,
	}, {
		Theme.new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }),
	})

	local empty = Theme.label({
		Name = "Empty",
		Position = UDim2.new(0, 0, 0, 78),
		Size = UDim2.new(1, 0, 0, 32),
		Text = t("lb_empty"),
		TextColor3 = Theme.muted,
		Parent = panel,
	})

	local close = Theme.button({
		Name = "Close",
		Position = UDim2.new(0, 0, 1, -38),
		Size = UDim2.new(1, 0, 0, 38),
		Text = t("hud_close"),
		BackgroundColor3 = Theme.red,
		Parent = panel,
	})

	local tabButtons: { [string]: TextButton } = {}
	for index, tab in TABS do
		local tabButton = Theme.button({
			Name = tab.id,
			LayoutOrder = index,
			Size = UDim2.fromScale(0.32, 1),
			Text = t(tab.label),
			Parent = tabRow,
		})
		tabButton.Activated:Connect(function()
			current = tab.id
			LeaderboardUI.render()
		end)
		tabButtons[tab.id] = tabButton
	end

	local surfaceBoards: { [Instance]: { gui: SurfaceGui, frame: Frame, rows: Frame } } = {}

	local function renderRows(holder: Frame, entries)
		clear(holder)
		for index, entry in entries do
			local row = Theme.new("Frame", {
				LayoutOrder = index,
				Size = UDim2.new(1, 0, 0, 26),
				BackgroundTransparency = 1,
				Parent = holder,
			})
			local name = Theme.label({
				Size = UDim2.fromScale(0.55, 1),
				Text = string.format("%d. %s", index, entry.name),
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = row,
			})
			name.TextSize = 13
			local value = Theme.label({
				Position = UDim2.fromScale(0.56, 0),
				Size = UDim2.fromScale(0.44, 1),
				Text = t(TABS[1].value),
				TextXAlignment = Enum.TextXAlignment.Right,
				Parent = row,
			})
			value.TextSize = 13
			for _, tab in TABS do
				if tab.id == current then
					value.Text = t(tab.value, entry.value)
					break
				end
			end
		end
	end

	function LeaderboardUI.render()
		for id, tabButton in tabButtons do
			tabButton.BackgroundColor3 = if id == current then Theme.accent else Theme.panelLight
			tabButton.TextColor3 = Theme.text
		end
		local entries = boards[current] or {}
		empty.Visible = #entries == 0
		list.Visible = #entries > 0
		renderRows(list :: any, entries)

		for _, surface in surfaceBoards do
			renderRows(surface.rows, entries)
		end
	end

	local function addSurface(part: Instance)
		if surfaceBoards[part] then
			return
		end
		local ok, surfaceGui = pcall(function()
			local surface = Theme.new("SurfaceGui", {
				Name = "LeaderboardSurface",
				Adornee = part,
				Face = Enum.NormalId.Front,
				SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
				PixelsPerStud = 50,
				Parent = part,
			})
			local frame = Theme.card({
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Theme.panel,
				Parent = surface,
			})
			Theme.padding(frame, 10)
			Theme.label({
				Size = UDim2.new(1, 0, 0, 30),
				Text = t("lb_title"),
				Font = Theme.displayFont,
				TextColor3 = Theme.merah,
				Parent = frame,
			})
			local rows = Theme.new("Frame", {
				Position = UDim2.new(0, 0, 0, 34),
				Size = UDim2.new(1, 0, 1, -34),
				BackgroundTransparency = 1,
				Parent = frame,
			}, {
				Theme.new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 3) }),
			})
			return { gui = surface, frame = frame, rows = rows }
		end)
		if ok and surfaceGui then
			surfaceBoards[part] = surfaceGui
			LeaderboardUI.render()
		end
	end

	local function removeSurface(part: Instance)
		local surface = surfaceBoards[part]
		if surface then
			surfaceBoards[part] = nil
			if surface.frame.Parent then
				surface.frame.Parent:Destroy()
			end
		end
	end

	pcall(function()
		for _, part in CollectionService:GetTagged("LeaderboardBoard") do
			addSurface(part)
		end
		CollectionService:GetInstanceAddedSignal("LeaderboardBoard"):Connect(addSurface)
		CollectionService:GetInstanceRemovedSignal("LeaderboardBoard"):Connect(removeSurface)
	end)

	Remotes.Leaderboard_Data.OnClientEvent:Connect(function(payload)
		local validated = Leaderboard.validatePayload(payload)
		if not validated then
			return
		end
		boards = validated
		LeaderboardUI.render()
	end)

	close.Activated:Connect(function()
		panel.Visible = false
	end)

	-- WORK_QUEUE item 21: B/Escape closes the board; selecting it focuses the X button.
	NavBridge.register("leaderboard", {
		root = panel,
		default = close,
		onClose = function()
			panel.Visible = false
		end,
	})

	function LeaderboardUI.open()
		LeaderboardUI.render()
		panel.Visible = true
	end

	LeaderboardUI.render()
	return gui
end

return LeaderboardUI
