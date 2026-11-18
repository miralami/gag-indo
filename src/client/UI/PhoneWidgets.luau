-- PhoneWidgets: the three generic view helpers used by Phone's pages. Extracted from Phone.luau
-- (WORK_QUEUE item 8, code health) with no behaviour change: each helper takes its parent
-- explicitly and returns exactly the same instance it did before the move.
local Icons = require(script.Parent.Icons)
local Theme = require(script.Parent.Theme)

local PhoneWidgets = {}

-- Destroys only GuiObject children; non-GUI children (layouts, constraints) are left alone.
function PhoneWidgets.clearChildren(frame: Instance)
	for _, child in frame:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

-- A labelled section row, optionally prefixed by an icon; `order` drives its LayoutOrder.
function PhoneWidgets.sectionLabel(parent: Instance, text: string, order: number, iconName: string?): Frame
	local row = Theme.new("Frame", {
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
		Parent = parent,
	})
	local offset = 0
	if iconName then
		Icons.make(iconName, {
			Position = UDim2.new(0, 0, 0, 2),
			Size = UDim2.fromOffset(22, 22),
			Parent = row,
		})
		offset = 26
	end
	local label = Theme.label({
		Position = UDim2.new(0, offset, 0, 0),
		Size = UDim2.new(1, -offset, 1, 0),
		Text = text,
		TextColor3 = Theme.merah,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = row,
	})
	label.TextSize = 18
	label.Font = Theme.displayFont
	return row
end

-- A full-size scrolling page with a layout-ordered list and the standard phone padding.
function PhoneWidgets.scrollPage(parent: Instance, name: string): ScrollingFrame
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
			Padding = UDim.new(0, 8),
		}),
		Theme.new("UIPadding", {
			PaddingLeft = UDim.new(0, 4),
			PaddingRight = UDim.new(0, 8),
			PaddingTop = UDim.new(0, 6),
			PaddingBottom = UDim.new(0, 24),
		}),
	})
	return page
end

return PhoneWidgets
