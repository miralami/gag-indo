-- NpcFactory: blocky, big-headed caricature NPCs (GDD §8) built from anchored parts.
-- No Humanoid and no animations: NPCs are moved with Model:PivotTo in a short walk loop,
-- which is deterministic, cheap and works with StreamingEnabled.
--
--   local pakrt = NpcFactory.build({ name = "Pak RT", position = Vector3.new(...) })
--   pakrt:say("Kok cepet banget panennya ya…", 5)
--   pakrt:walkTo(somewhere, 16) -- yields until it arrives
--
-- Designer maps: model a character, tag it NpcSpawn with attribute Npc = "pakrt", and
-- Village.bind() wraps it with NpcFactory.wrap(model) so services get the same API.

local Map = require(script.Parent.Map)
local Props = require(script.Parent.Props)

local NpcFactory = {}
local Npc = {}
Npc.__index = Npc

local STEP_SECONDS = 0.05

local function addPart(model: Model, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): Part
	local p = Props.part({
		Name = name,
		Size = size,
		CFrame = cf,
		Color = color,
		Material = material or Enum.Material.SmoothPlastic,
		CanCollide = false,
		CanQuery = false,
	})
	p.Parent = model
	return p
end

-- Attach the Npc API (name tag, speech, walk) to an existing model and tag it for the map.
function NpcFactory.wrap(model: Model, info: { name: string?, subtitle: string?, npc: string? }?): any
	local opts = info or {}
	if not model.PrimaryPart then
		local primary = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart")
		model.PrimaryPart = primary :: BasePart?
	end
	local anchor = model.PrimaryPart

	Map.add(model, Map.TAGS.Npc)
	if opts.npc then
		model:SetAttribute("Npc", opts.npc)
	end

	local displayName = opts.name or model.Name
	local nameLabel: TextLabel? = nil
	local speechLabel: TextLabel? = nil
	if anchor then
		local nameTag = Props.billboard(anchor, 4.4, Vector2.new(260, 60), { name = "NameTag", maxDistance = 95 })
		nameTag.Text = displayName .. (if opts.subtitle then " · " .. opts.subtitle else "")
		nameTag.TextColor3 = Color3.fromRGB(255, 236, 180)
		nameLabel = nameTag

		local speech = Props.billboard(anchor, 6.4, Vector2.new(320, 90), { name = "Speech" })
		speech.TextColor3 = Color3.new(1, 1, 1)
		speech.TextWrapped = true
		speechLabel = speech
	end

	return setmetatable({
		model = model,
		head = model:FindFirstChild("Head") :: BasePart?,
		torso = anchor,
		nameLabel = nameLabel,
		speechLabel = speechLabel,
		walkToken = 0,
		speechToken = 0,
		homeCFrame = model:GetPivot(),
	}, Npc)
end

-- config: name, subtitle?, npc?, position (feet), shirt, skin, cap?, peci?, parent?
function NpcFactory.build(config)
	local model = Instance.new("Model")
	model.Name = config.name

	local shirt = config.shirt or Color3.fromRGB(90, 120, 160)
	local skin = config.skin or Color3.fromRGB(196, 150, 105)
	local feet = CFrame.new(config.position)

	local torsoCF = feet * CFrame.new(0, 3.0, 0)
	local torso = addPart(model, "Torso", Vector3.new(2.4, 2.6, 1.2), torsoCF, shirt, Enum.Material.Fabric)
	local headCF = feet * CFrame.new(0, 5.5, 0)
	local head = addPart(model, "Head", Vector3.new(2.2, 2.2, 2.2), headCF, skin)
	local leftArm = addPart(model, "LeftArm", Vector3.new(0.8, 2.4, 0.9), torsoCF * CFrame.new(-1.6, 0, 0), shirt)
	local rightArm = addPart(model, "RightArm", Vector3.new(0.8, 2.4, 0.9), torsoCF * CFrame.new(1.6, 0, 0), shirt)
	addPart(model, "LeftLeg", Vector3.new(0.95, 1.8, 0.95), feet * CFrame.new(-0.6, 0.9, 0), Color3.fromRGB(60, 60, 75))
	addPart(model, "RightLeg", Vector3.new(0.95, 1.8, 0.95), feet * CFrame.new(0.6, 0.9, 0), Color3.fromRGB(60, 60, 75))

	-- Face (front is -Z)
	addPart(model, "EyeL", Vector3.new(0.28, 0.4, 0.1), headCF * CFrame.new(-0.5, 0.2, -1.08), Color3.fromRGB(20, 20, 20))
	addPart(model, "EyeR", Vector3.new(0.28, 0.4, 0.1), headCF * CFrame.new(0.5, 0.2, -1.08), Color3.fromRGB(20, 20, 20))
	addPart(model, "Mouth", Vector3.new(0.8, 0.14, 0.1), headCF * CFrame.new(0, -0.55, -1.08), Color3.fromRGB(120, 60, 60))
	if config.mustache then
		addPart(model, "Mustache", Vector3.new(1.1, 0.22, 0.16), headCF * CFrame.new(0, -0.3, -1.1), Color3.fromRGB(30, 25, 20))
	end
	if config.cap then
		local cap = addPart(model, "Cap", Vector3.new(2.5, 0.5, 2.5), headCF * CFrame.new(0, 1.15, 0), config.cap)
		local brim = addPart(model, "CapBrim", Vector3.new(2.5, 0.14, 0.9), headCF * CFrame.new(0, 1.15, -1.5), config.cap)
		cap.CanQuery = false
		brim.CanQuery = false
	elseif config.peci then
		addPart(model, "Peci", Vector3.new(2.1, 0.75, 2.1), headCF * CFrame.new(0, 1.3, 0), Color3.fromRGB(25, 25, 30))
	end

	model.PrimaryPart = torso
	model.Parent = config.parent or workspace

	local npc = NpcFactory.wrap(model, {
		name = config.name,
		subtitle = config.subtitle,
		npc = config.npc,
	})
	npc.head = head
	npc.arms = { leftArm, rightArm }
	return npc
end

function Npc:getPosition(): Vector3
	local pivot = self.model.PrimaryPart
	return if pivot then pivot.Position else self.homeCFrame.Position
end

function Npc:say(text: string, seconds: number?)
	if not self.speechLabel then
		return
	end
	self.speechToken += 1
	local token = self.speechToken
	self.speechLabel.Text = text
	task.delay(seconds or 4, function()
		if self.speechToken == token and self.speechLabel.Parent then
			self.speechLabel.Text = ""
		end
	end)
end

function Npc:lookAt(point: Vector3)
	local pivot = self.model:GetPivot()
	local flat = Vector3.new(point.X, pivot.Position.Y, point.Z)
	if (flat - pivot.Position).Magnitude > 0.1 then
		self.model:PivotTo(CFrame.lookAt(pivot.Position, flat))
	end
end

function Npc:stop()
	self.walkToken += 1
end

-- Yields. `speed` is studs/second (default 14).
function Npc:walkTo(target: Vector3, speed: number?)
	self.walkToken += 1
	local token = self.walkToken
	local pivot = self.model:GetPivot()
	local start = pivot.Position
	local goal = Vector3.new(target.X, start.Y, target.Z)
	local delta = goal - start
	local distance = delta.Magnitude
	if distance < 0.5 then
		return
	end

	local direction = CFrame.lookAt(Vector3.zero, Vector3.new(delta.X, 0, delta.Z))
	local duration = distance / (speed or 14)
	local steps = math.max(1, math.ceil(duration / STEP_SECONDS))

	for i = 1, steps do
		if self.walkToken ~= token or not self.model.Parent then
			return
		end
		local alpha = i / steps
		local position = start:Lerp(goal, alpha) + Vector3.new(0, math.abs(math.sin(i * 0.9)) * 0.18, 0)
		self.model:PivotTo(CFrame.new(position) * direction * CFrame.Angles(0, 0, math.sin(i * 0.9) * 0.05))
		task.wait(STEP_SECONDS)
	end

	self.model:PivotTo(CFrame.new(goal) * direction)
end

-- Teleport instantly (used to reset police after a raid).
function Npc:teleport(position: Vector3)
	self.walkToken += 1
	local pivot = self.model:GetPivot()
	self.model:PivotTo(CFrame.new(position) * (pivot - pivot.Position))
end

return NpcFactory
