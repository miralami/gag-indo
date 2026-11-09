-- Props: tiny builders for greybox parts, prompts and billboards.
-- Shared by Village and PlotService so every prompt behaves the same on mobile.

local Props = {}

function Props.part(properties: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
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
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.TextWrapped = true
	label.Text = ""
	label.Parent = gui
	return label
end

return Props
