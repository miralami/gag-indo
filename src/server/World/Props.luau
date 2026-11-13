-- Props: tiny builders for greybox parts, prompts and billboards.
-- Shared by Village and PlotService so every prompt behaves the same on mobile.

local Props = {}

local PALETTE = {
	kertas = Color3.fromHex("f3e9d2"), tinta = Color3.fromHex("2b2118"),
	tintaLembut = Color3.fromHex("5b4a38"), senja = Color3.fromHex("f6c97a"),
	padi = Color3.fromHex("9bb25a"), daun = Color3.fromHex("6f8a3f"),
	genteng = Color3.fromHex("a8452f"), merah = Color3.fromHex("a83226"),
	bambu = Color3.fromHex("b98a5a"), kunyit = Color3.fromHex("c99a2e"),
	indigo = Color3.fromHex("3b4f6b"), malam = Color3.fromHex("1f4e6b"),
	ungu = Color3.fromHex("7652a8"),
}

function Props.palette(name: string): Color3
	return PALETTE[name] or PALETTE.bambu
end

function Props.part(properties: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.Material = Enum.Material.Wood
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in properties do
		(p :: any)[key] = value
	end
	return p
end

function Props.prompt(parent: Instance, objectText: string, actionText: string): ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = objectText
	prompt.ActionText = actionText
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = parent
	return prompt
end

-- options: { name: string?, alwaysOnTop: boolean?, maxDistance: number? }
function Props.billboard(
	parent: Instance,
	height: number,
	size: Vector2,
	options: { name: string?, alwaysOnTop: boolean?, maxDistance: number? }?
): TextLabel
	local gui = Instance.new("BillboardGui")
	gui.Name = (options and options.name) or "BillboardGui"
	gui.Size = UDim2.fromOffset(size.X, size.Y)
	gui.StudsOffset = Vector3.new(0, height, 0)
	gui.MaxDistance = (options and options.maxDistance) or 90
	gui.AlwaysOnTop = options ~= nil and options.alwaysOnTop == true
	gui.Parent = parent
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.LuckiestGuy
	label.TextColor3 = PALETTE.kertas
	label.TextStrokeColor3 = PALETTE.tinta
	label.TextStrokeTransparency = 0
	label.TextWrapped = true
	label.Text = ""
	label.Parent = gui
	return label
end

return Props
