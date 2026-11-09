-- Theme: the small shared UI kit every panel uses (mobile-first, GDD §10).
-- Also owns the global toast queue so any module can show `Theme.toast(text)`.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

local Theme = {}

Theme.font = Enum.Font.FredokaOne
Theme.panel = Color3.fromRGB(35, 30, 25)
Theme.panelLight = Color3.fromRGB(58, 50, 42)
Theme.accent = Color3.fromRGB(240, 180, 40)
Theme.text = Color3.fromRGB(255, 248, 230)
Theme.muted = Color3.fromRGB(150, 140, 130)
Theme.green = Color3.fromRGB(70, 170, 90)
Theme.red = Color3.fromRGB(190, 60, 50)
Theme.blue = Color3.fromRGB(50, 100, 170)

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

function Theme.label(props: { [string]: any }): TextLabel
	props.BackgroundTransparency = if props.BackgroundTransparency ~= nil then props.BackgroundTransparency else 1
	props.Font = Theme.font
	props.TextColor3 = props.TextColor3 or Theme.text
	props.TextScaled = if props.TextScaled ~= nil then props.TextScaled else true
	return Theme.new("TextLabel", props)
end

function Theme.button(props: { [string]: any }): TextButton
	props.Font = Theme.font
	props.TextColor3 = props.TextColor3 or Theme.text
	props.TextScaled = if props.TextScaled ~= nil then props.TextScaled else true
	props.AutoButtonColor = true
	props.BackgroundColor3 = props.BackgroundColor3 or Theme.panelLight
	props.BorderSizePixel = 0
	local button = Theme.new("TextButton", props, {
		Theme.corner(nil, 10),
		(function()
			local padding = Instance.new("UIPadding")
			padding.PaddingLeft = UDim.new(0, 6)
			padding.PaddingRight = UDim.new(0, 6)
			padding.PaddingTop = UDim.new(0, 4)
			padding.PaddingBottom = UDim.new(0, 4)
			return padding
		end)(),
	})
	return button
end

function Theme.card(props: { [string]: any }, children: { Instance }?): Frame
	props.BackgroundColor3 = props.BackgroundColor3 or Theme.panel
	props.BorderSizePixel = 0
	local kids = children or {}
	table.insert(kids, Theme.corner(nil, 14))
	return Theme.new("Frame", props, kids)
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
	local item = Theme.label({
		LayoutOrder = toastOrder,
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundTransparency = 0.1,
		BackgroundColor3 = color or Theme.panel,
		Text = text,
		TextWrapped = true,
		Parent = toastList,
	})
	Theme.corner(item, 8)
	Theme.padding(item, 6)
	item.TextSize = 16

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
