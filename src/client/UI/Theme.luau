-- Theme: the small shared UI kit every panel uses (mobile-first, GDD §10, ART.md §8).
-- Palette, type, spacing and outline/shadow come from shared/Config/Visuals.luau.
-- Also owns the global toast queue so any module can show `Theme.toast(text)`.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Visuals = require(Shared.Config.Visuals)

local player = Players.LocalPlayer

local Theme = {}

local function hex(name: string): Color3
	return Color3.fromHex(Visuals.palette[name])
end

-- New tokens (ART.md §3). Old fields below are kept for every existing screen.
Theme.paper = hex("kertas")
Theme.ink = hex("tinta")
Theme.inkSoft = hex("tinta_lembut")
Theme.senja = hex("senja")
Theme.padi = hex("padi")
Theme.daun = hex("daun")
Theme.genteng = hex("genteng")
Theme.merah = hex("merah")
Theme.bambu = hex("bambu")
Theme.kunyit = hex("kunyit")
Theme.indigo = hex("indigo")
Theme.malam = hex("malam")

-- Legacy fields, remapped to the new palette so old screens keep working.
Theme.panel = Theme.paper
Theme.panelLight = Theme.bambu
Theme.accent = Theme.kunyit
Theme.text = Theme.ink
Theme.muted = Theme.inkSoft
Theme.green = Theme.padi
Theme.red = Theme.merah
Theme.blue = Theme.malam
Theme.onLight = Theme.ink
Theme.onDark = Theme.paper

Theme.font = Enum.Font[Visuals.fonts.body]
Theme.displayFont = Enum.Font[Visuals.fonts.display]
Theme.textSize = Visuals.type
Theme.space = Visuals.space
Theme.radius = Visuals.radius
Theme.outline = Visuals.outline
Theme.shadow = Visuals.shadow
Theme.touch = Visuals.touch

-- WCAG relative luminance, so text on a coloured surface picks the readable ink/paper.
local function channel(value: number): number
	if value <= 0.03928 then
		return value / 12.92
	end
	return ((value + 0.055) / 1.055) ^ 2.4
end

local function luminance(color: Color3): number
	return 0.2126 * channel(color.R) + 0.7152 * channel(color.G) + 0.0722 * channel(color.B)
end

function Theme.contrastText(background: Color3): Color3
	local backgroundLuminance = luminance(background)
	local inkRatio = (backgroundLuminance + 0.05) / (luminance(Theme.ink) + 0.05)
	local paperRatio = (luminance(Theme.paper) + 0.05) / (backgroundLuminance + 0.05)
	if inkRatio >= paperRatio then
		return Theme.ink
	end
	return Theme.paper
end

function Theme.new(className: string, props: { [string]: any }, children: { Instance }?): any
	local inst = Instance.new(className)
	for key, value in props do
		if key ~= "Parent" then
			(inst :: any)[key] = value
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

function Theme.corner(parent: Instance?, radius: number): UICorner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	if parent then
		corner.Parent = parent
	end
	return corner
end

function Theme.padding(parent: Instance, all: number): UIPadding
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, all)
	padding.PaddingRight = UDim.new(0, all)
	padding.PaddingTop = UDim.new(0, all)
	padding.PaddingBottom = UDim.new(0, all)
	padding.Parent = parent
	return padding
end

-- Sticker treatment: 2 px ink outline + 4 px hard offset shadow (ART.md §4).
-- The shadow is a sibling because a child can never render behind its parent.
-- Lists and grids skip it: a sibling there would become a layout item.
local function addSticker(inst: GuiObject, radius: number)
	if not inst.Parent then
		return
	end
	if inst:FindFirstChildOfClass("UIStroke") == nil then
		Theme.new("UIStroke", {
			Name = "InkOutline",
			Color = Theme.ink,
			Thickness = Visuals.outline,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			LineJoinMode = Enum.LineJoinMode.Round,
			Parent = inst,
		})
	end

	local parent = inst.Parent
	if parent:FindFirstChildOfClass("UIListLayout") or parent:FindFirstChildOfClass("UIGridLayout") then
		return
	end

	local shadow = Theme.new("Frame", {
		Name = inst.Name .. "Shadow",
		AnchorPoint = inst.AnchorPoint,
		Position = inst.Position + UDim2.fromOffset(Visuals.shadow, Visuals.shadow),
		Size = inst.Size,
		BackgroundColor3 = Theme.ink,
		BackgroundTransparency = 0.12,
		BorderSizePixel = 0,
		ZIndex = inst.ZIndex - 1,
		Visible = inst.Visible,
		Parent = parent,
	})
	Theme.corner(shadow, radius)

	local function syncPosition()
		shadow.Position = inst.Position + UDim2.fromOffset(Visuals.shadow, Visuals.shadow)
	end
	local function syncSize()
		shadow.Size = inst.Size
	end
	local function syncAnchor()
		shadow.AnchorPoint = inst.AnchorPoint
	end
	local function syncVisible()
		shadow.Visible = inst.Visible
	end
	local function syncZIndex()
		shadow.ZIndex = inst.ZIndex - 1
	end
	local function drop()
		if shadow.Parent then
			shadow:Destroy()
		end
	end

	inst:GetPropertyChangedSignal("Position"):Connect(syncPosition)
	inst:GetPropertyChangedSignal("Size"):Connect(syncSize)
	inst:GetPropertyChangedSignal("AnchorPoint"):Connect(syncAnchor)
	inst:GetPropertyChangedSignal("Visible"):Connect(syncVisible)
	inst:GetPropertyChangedSignal("ZIndex"):Connect(syncZIndex)
	inst.Destroying:Connect(drop)
	inst.AncestryChanged:Connect(function()
		if inst.Parent ~= parent then
			drop()
		end
	end)
end

function Theme.sticker(inst: GuiObject, radius: number?)
	addSticker(inst, radius or Visuals.radius.card)
end

function Theme.label(props: { [string]: any }): TextLabel
	props.BackgroundTransparency = if props.BackgroundTransparency ~= nil then props.BackgroundTransparency else 1
	props.Font = props.Font or Theme.font
	props.TextColor3 = props.TextColor3 or Theme.text
	props.TextScaled = if props.TextScaled ~= nil then props.TextScaled else true
	return Theme.new("TextLabel", props)
end

function Theme.button(props: { [string]: any }): TextButton
	local background = props.BackgroundColor3 or Theme.panelLight
	props.Font = props.Font or Theme.font
	props.TextColor3 = props.TextColor3 or Theme.contrastText(background)
	props.TextScaled = if props.TextScaled ~= nil then props.TextScaled else true
	props.AutoButtonColor = true
	props.BackgroundColor3 = background
	props.BorderSizePixel = 0
	local button = Theme.new("TextButton", props, {
		Theme.corner(nil, Visuals.radius.button),
		(function()
			local padding = Instance.new("UIPadding")
			padding.PaddingLeft = UDim.new(0, Visuals.space.sm)
			padding.PaddingRight = UDim.new(0, Visuals.space.sm)
			padding.PaddingTop = UDim.new(0, Visuals.space.xs)
			padding.PaddingBottom = UDim.new(0, Visuals.space.xs)
			return padding
		end)(),
	})
	addSticker(button, Visuals.radius.button)
	return button
end

function Theme.card(props: { [string]: any }, children: { Instance }?): Frame
	props.BackgroundColor3 = props.BackgroundColor3 or Theme.panel
	props.BorderSizePixel = 0
	local kids = children or {}
	table.insert(kids, Theme.corner(nil, Visuals.radius.card))
	local frame = Theme.new("Frame", props, kids)
	addSticker(frame, Visuals.radius.card)
	return frame
end

function Theme.rarityChip(tierId: string, props: { [string]: any }?): Frame
	local tier = Visuals.rarity[tierId] or Visuals.rarity.biasa
	local opts = props or {}
	local color = hex(tier.token)
	local frame = Theme.new("Frame", {
		Name = opts.Name or "Rarity_" .. tierId,
		Size = opts.Size or UDim2.fromOffset(72, 28),
		Position = opts.Position,
		AnchorPoint = opts.AnchorPoint,
		LayoutOrder = opts.LayoutOrder,
		Visible = opts.Visible,
		BackgroundTransparency = opts.BackgroundTransparency or 0,
		BackgroundColor3 = Theme.paper,
		BorderSizePixel = 0,
		Parent = opts.Parent,
	})
	Theme.corner(frame, Visuals.radius.chip)
	local stroke = Instance.new("UIStroke")
	stroke.Name = "TierFrame"
	stroke.Color = color
	stroke.Thickness = if tier.frame == "double" or tier.frame == "gold" then 3 else 2
	stroke.Parent = frame
	if tier.frame == "leaf" or tier.frame == "ornate" then
		local accent = Theme.new("Frame", {
			Name = "TierAccent",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 0),
			Size = UDim2.fromOffset(8, 8),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			Parent = frame,
		})
		Theme.corner(accent, 3)
	end
	local label = Theme.label({
		Name = "Label",
		Size = UDim2.fromScale(1, 1),
		Text = tierId,
		TextColor3 = Theme.ink,
		TextSize = Visuals.type.small,
		Parent = frame,
	})
	label.ZIndex = frame.ZIndex + 1
	for key, value in opts do
		if key ~= "Parent" and key ~= "Name" and key ~= "Size" and key ~= "Position" and key ~= "AnchorPoint" and key ~= "LayoutOrder" and key ~= "Visible" and key ~= "BackgroundTransparency" then
			(frame :: any)[key] = value
		end
	end
	return frame
end

function Theme.screenGui(name: string, displayOrder: number): ScreenGui
	return Theme.new("ScreenGui", {
		Name = name,
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = displayOrder,
		Parent = player:WaitForChild("PlayerGui"),
	})
end

-- Toasts ------------------------------------------------------------------
local toastGui: ScreenGui? = nil
local toastList: Frame? = nil
local toastOrder = 0

local function ensureToasts()
	if toastGui and toastGui.Parent then
		return
	end
	toastGui = Theme.screenGui("Toasts", 90)
	local holder = Theme.new("Frame", {
		Name = "Holder",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 10),
		Size = UDim2.fromScale(0.62, 0.28),
		BackgroundTransparency = 1,
		Parent = toastGui,
	}, {
		Theme.new("UISizeConstraint", { MinSize = Vector2.new(260, 120), MaxSize = Vector2.new(560, 260) }),
		Theme.new("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, 6),
		}),
	})
	toastList = holder
end

function Theme.toast(text: string, color: Color3?)
	ensureToasts()
	if not toastList then
		return
	end
	toastOrder += 1
	local background = color or Theme.panel
	local item = Theme.label({
		LayoutOrder = toastOrder,
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 0,
		BackgroundColor3 = background,
		Text = text,
		TextColor3 = Theme.contrastText(background),
		TextWrapped = true,
		Parent = toastList,
	})
	item.Size = UDim2.new(1, 0, 0, 0)
	TweenService:Create(item, TweenInfo.new(Visuals.motion.duration, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(1, 0, 0, 40),
	}):Play()
	Theme.corner(item, Visuals.radius.button)
	Theme.padding(item, Visuals.space.sm)
	item.TextSize = Visuals.type.body

	task.delay(3.2, function()
		if not item.Parent then
			return
		end
		local tween = TweenService:Create(item, TweenInfo.new(0.35), {
			TextTransparency = 1,
			BackgroundTransparency = 1,
		})
		tween:Play()
		tween.Completed:Wait()
		item:Destroy()
	end)

	-- Keep at most four visible toasts.
	local labels = {}
	for _, child in toastList:GetChildren() do
		if child:IsA("TextLabel") then
			table.insert(labels, child)
		end
	end
	if #labels > 4 then
		table.sort(labels, function(a, b)
			return a.LayoutOrder < b.LayoutOrder
		end)
		for i = 1, #labels - 4 do
			labels[i]:Destroy()
		end
	end
end

return Theme
