-- Icons: name -> image id, with an on-palette procedural fallback while ids are 0.
-- ART.md §7/§8: painted icon slots, no emoji. Fill `Visuals.icons[name].id` when art lands.
-- Shared.IconMap centralises crop/currency/tier/phone-app slots (TODO: NEEDS-ASSET IDs).

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Visuals = require(Shared.Config.Visuals)
local IconMap = require(Shared.IconMap)
local Theme = require(script.Parent.Theme)

IconMap.apply(Visuals)

local Icons = {}

Icons.entries = Visuals.icons
Icons.map = IconMap

function Icons.id(name: string): number
	local entry = Visuals.icons[name]
	return Visuals.assetId(if entry then entry.id else nil) or 0
end

function Icons.has(name: string): boolean
	return Icons.id(name) > 0
end

function Icons.text(name: string): string
	local entry = Visuals.icons[name]
	return if entry then entry.text else "?"
end

function Icons.slot(kind: string, key: string): string
	if kind == "crop" then
		return IconMap.cropSlot(key)
	elseif kind == "phone" or kind == "app" then
		return IconMap.phoneAppSlot(key)
	elseif kind == "tier" then
		return IconMap.tierSlot(key)
	elseif kind == "currency" then
		return IconMap.currencySlot(key)
	end
	return key
end

-- Renders either the real image or a small palette chip with the ASCII fallback.
-- Props are the usual GuiObject fields; `Color` overrides the palette token.
function Icons.make(name: string, props: { [string]: any }): GuiObject
	local entry = Visuals.icons[name]
	local id = Visuals.assetId(if entry then entry.id else nil)
	local parent = props.Parent
	if name:sub(1, 5) == "tier_" then
		return Theme.rarityChip(name:sub(6), props)
	end

	local common: { [string]: any } = {
		Name = props.Name or ("Icon_" .. name),
		AnchorPoint = props.AnchorPoint,
		Position = props.Position,
		Size = props.Size or UDim2.fromOffset(28, 28),
		LayoutOrder = props.LayoutOrder,
		ZIndex = props.ZIndex,
		Visible = props.Visible,
		Parent = parent,
	}

	if id then
		common.Image = Visuals.assetUrl(id)
		common.BackgroundTransparency = 1
		common.ScaleType = Enum.ScaleType.Fit
		common.ImageTransparency = props.ImageTransparency
		return Theme.new("ImageLabel", common)
	end

	local token = if entry then entry.token else "tinta_lembut"
	local color = props.Color or Color3.fromHex(Visuals.palette[token] or Visuals.palette.tinta_lembut)
	common.BackgroundColor3 = color
	common.BackgroundTransparency = props.BackgroundTransparency or 0
	common.BorderSizePixel = 0
	local chip = Theme.new("Frame", common, { Theme.corner(nil, Visuals.radius.chip) })
	Theme.label({
		Size = UDim2.fromScale(1, 1),
		Text = if entry then entry.text else "?",
		TextColor3 = Theme.contrastText(color),
		TextScaled = true,
		Font = Theme.font,
		Parent = chip,
	})
	return chip
end

return Icons
