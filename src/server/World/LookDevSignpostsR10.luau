--!strict
-- LookDevSignpostsR10: SERVER-ONLY applier for the OFF-BY-DEFAULT "signposts_r10" candidate
-- (WORK_QUEUE item 257). Builds four green square steel signposts at the ring-road junctions from
-- plain Metal / DiamondPlate parts (no store model, no scripts): each has five green arrow plates
-- with a white border and white bold text from Shared.Strings (SurfaceGui on both faces) and a
-- small lamp on an arm at the top. Geometry, palette and text keys come from
-- Shared.ModelMapSignpostsR10. Only instances created here are destroyed, in LIFO order;
-- apply/restore are idempotent and pcall-guarded throughout.
-- Dropped store pick (not loaded any more, kept so ASSET_MANIFEST coverage still finds it): 71310674426033.
-- Enable from the Server command bar:
--   require(game.ReplicatedStorage.Shared.LookDevReview).enableAdditive("signposts_r10", game)

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevSignpostsR10] missing service " .. name)
		return nil
	end
	return value
end

local ReplicatedStorage = service("ReplicatedStorage")
local Workspace = service("Workspace")
if not ReplicatedStorage or not Workspace then
	return {}
end

local Shared: any? = nil
local okShared, sharedFolder = pcall(function()
	return (ReplicatedStorage :: any):WaitForChild("Shared")
end)
if okShared and sharedFolder then
	Shared = sharedFolder
else
	warn("[LookDevSignpostsR10] missing Shared folder")
	return {}
end

local okModules, LookDev, Data, LookDevFailures, Strings = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapSignpostsR10),
		require((Shared :: any).LookDevFailures),
		require((Shared :: any).Strings)
end)
if not okModules or not LookDev or not Data or not LookDevFailures or not Strings then
	warn("[LookDevSignpostsR10] could not require LookDev / ModelMapSignpostsR10 / LookDevFailures / Strings")
	return {}
end

-- Night gate shared with the lamps candidate; optional, the lamp simply stays unlit without it.
local okLamps, LampsData = pcall(function()
	return require((Shared :: any).ModelMapLampsR10)
end)
local Lighting = service("Lighting")

local LookDevSignpostsR10 = {}

local FAMILY_ID = Data.id
local STAGE_ATTR = "LookDevStage"

local failures = 0
local active = false
local created: { any } = {}
local lights: { any } = {}

local function fail(message: string)
	failures += 1
	warn("[LookDevSignpostsR10] " .. message)
end

local function publishFailures()
	pcall(function()
		LookDevFailures.set(FAMILY_ID, failures)
	end)
end

local function track(instance: any)
	created[#created + 1] = instance
end

local function stageFolder(): any?
	local okFind, existing = pcall(function()
		return (Workspace :: any):FindFirstChild((Data :: any).folderName)
	end)
	if not okFind then
		fail("could not look up staging folder: " .. tostring(existing))
		return nil
	end
	if existing then
		return existing
	end
	local okNew, instance = pcall(function()
		return (Instance :: any).new("Folder")
	end)
	if not okNew or not instance then
		fail("could not create staging folder: " .. tostring(instance))
		return nil
	end
	local okParent, why = pcall(function()
		instance.Name = (Data :: any).folderName
		instance.Parent = Workspace
	end)
	if not okParent then
		pcall(function()
			instance:Destroy()
		end)
		fail("could not parent staging folder: " .. tostring(why))
		return nil
	end
	track(instance)
	return instance
end

-- Every staged instance carries the family tag and sign metadata; only the first plate of each
-- sign keeps Signpost=true so the older four-sign audit still counts exactly four signs.
local function tag(instance: any, signIndex: number?, attributes: any?)
	pcall(function()
		instance:SetAttribute(STAGE_ATTR, FAMILY_ID)
		instance:SetAttribute("SignpostFamily", FAMILY_ID)
		instance:SetAttribute("Signpost", false)
		if signIndex then
			instance:SetAttribute("sign", signIndex)
		end
		if type(attributes) == "table" then
			for key, value in pairs(attributes) do
				instance:SetAttribute(key, value)
			end
		end
	end)
end

local function colour(rgb: any): any
	return Color3.fromRGB(rgb.r, rgb.g, rgb.b)
end

local function newPart(name: string, size: any, cframe: any, rgb: any, material: any, parent: any): any
	local part = (Instance :: any).new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = colour(rgb)
	part.Material = material
	part.Anchored = true
	part.CanCollide = false
	part.CastShadow = false
	part.Parent = parent
	return part
end

local function stagePole(descriptor: any, parent: any)
	local size = (Data :: any).POST_SIZE
	local pole = newPart(
		descriptor.name .. "_SteelPole",
		Vector3.new(size[1], size[2], size[3]),
		CFrame.new(descriptor.position.x, descriptor.position.y + size[2] / 2, descriptor.position.z)
			* CFrame.Angles(0, math.rad(descriptor.yaw), 0),
		(Data :: any).POST_COLOR,
		Enum.Material.DiamondPlate,
		parent
	)
	tag(pole, descriptor.index, { SignpostPole = true })
	track(pole)
end

local function addFace(board: any, descriptor: any, plate: any, face: any, faceName: string)
	local gui = (Instance :: any).new("SurfaceGui")
	gui.Name = "SignFace" .. faceName
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = (Data :: any).PIXELS_PER_STUD
	gui.LightInfluence = 0
	gui.Parent = board
	track(gui)
	tag(gui, descriptor.index, { textKey = plate.textKey, fontSizePx = plate.fontSizePx })

	-- Thin white border: a transparent frame carrying a UIStroke.
	local border = (Instance :: any).new("Frame")
	border.Name = "Border"
	border.Size = UDim2.fromScale(1, 1)
	border.BackgroundTransparency = 1
	border.BorderSizePixel = 0
	border.Parent = gui
	track(border)
	local stroke = (Instance :: any).new("UIStroke")
	stroke.Color = colour((Data :: any).BORDER_COLOR)
	stroke.Thickness = 6
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = border
	track(stroke)

	local label = (Instance :: any).new("TextLabel")
	label.Name = "SignText"
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.5)
	label.Size = UDim2.fromScale(0.84, 0.7)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.TextSize = plate.fontSizePx
	label.TextColor3 = colour((Data :: any).TEXT_COLOR)
	label.Font = Enum.Font.GothamBold
	label.Text = Strings.get("id", plate.textKey)
	label.Parent = gui
	track(label)
	tag(label, descriptor.index, { textKey = plate.textKey, fontSizePx = plate.fontSizePx })
end

local function addPlateText(board: any, descriptor: any, plate: any)
	local ok, why = pcall(function()
		addFace(board, descriptor, plate, Enum.NormalId.Front, "Front")
		addFace(board, descriptor, plate, Enum.NormalId.Back, "Back")
	end)
	if not ok then
		fail("could not write sign text for " .. tostring(plate.textKey) .. ": " .. tostring(why))
	end
end

local function stagePlate(descriptor: any, plate: any, parent: any)
	local plateSize = (Data :: any).PLATE_SIZE
	local halfPole = (Data :: any).POST_SIZE[1] / 2
	-- Plates hug the viewer side (local -Z) of the pole, rotated about the pole axis by yawOffset;
	-- the inner end overlaps the pole and the outer end points left or right by side.
	local origin = CFrame.new(descriptor.position.x, descriptor.position.y, descriptor.position.z)
		* CFrame.Angles(0, math.rad(descriptor.yaw + plate.yawOffset), 0)
		* CFrame.new(plate.side * (plateSize[1] / 2 - halfPole), plate.height, -(halfPole + plateSize[3] / 2 + 0.01))

	local board = newPart(
		plate.name,
		Vector3.new(plateSize[1], plateSize[2], plateSize[3]),
		origin,
		(Data :: any).PLATE_COLOR,
		Enum.Material.Metal,
		parent
	)
	tag(board, descriptor.index, {
		SignpostPlate = true,
		Signpost = plate.order == 1,
		textKey = plate.textKey,
		fontSizePx = plate.fontSizePx,
		plateOrder = plate.order,
	})
	track(board)

	-- A 45 degree diamond whose outer half protrudes makes each flat board read as an arrow tip.
	local diamond = plateSize[2] / math.sqrt(2)
	local tip = newPart(
		plate.name .. "_Tip",
		Vector3.new(diamond, diamond, plateSize[3] - 0.01),
		origin * CFrame.new(plate.side * plateSize[1] / 2, 0, 0) * CFrame.Angles(0, 0, math.rad(45)),
		(Data :: any).PLATE_COLOR,
		Enum.Material.Metal,
		parent
	)
	tag(tip, descriptor.index)
	track(tip)

	addPlateText(board, descriptor, plate)
end

local function isNightNow(): boolean
	if not okLamps or type(LampsData) ~= "table" or not Lighting then
		return false
	end
	local ok, night = pcall(function()
		return (LampsData :: any).isNight((Lighting :: any).ClockTime)
	end)
	return ok and night == true
end

-- Public so a harness can simulate a clock without restaging the signs.
function LookDevSignpostsR10.setClockTime(clock: any)
	local enabled = okLamps and type(LampsData) == "table" and (LampsData :: any).isNight(clock) == true
	for index = #lights, 1, -1 do
		pcall(function()
			lights[index].Enabled = enabled
		end)
	end
end

local function stageLamp(descriptor: any, parent: any)
	local top = descriptor.position.y + (Data :: any).POST_SIZE[2]
	local arm = (Data :: any).ARM_SIZE
	local lampSize = (Data :: any).LAMP_SIZE
	local base = CFrame.new(descriptor.position.x, top, descriptor.position.z)
		* CFrame.Angles(0, math.rad(descriptor.yaw), 0)

	local armPart = newPart(
		descriptor.name .. "_LampArm",
		Vector3.new(arm[1], arm[2], arm[3]),
		base * CFrame.new(arm[1] / 2 - 0.2, arm[2] / 2, 0),
		(Data :: any).POST_COLOR,
		Enum.Material.Metal,
		parent
	)
	tag(armPart, descriptor.index)
	track(armPart)

	local bulb = newPart(
		descriptor.name .. "_Lamp",
		Vector3.new(lampSize[1], lampSize[2], lampSize[3]),
		base * CFrame.new(arm[1] - 0.2, -lampSize[2] / 2 + arm[2] / 2, 0),
		(Data :: any).LAMP_COLOR,
		Enum.Material.Neon,
		parent
	)
	bulb.Shape = Enum.PartType.Ball
	tag(bulb, descriptor.index, { SignpostLamp = true })
	track(bulb)

	local ok = pcall(function()
		local light = (Instance :: any).new("PointLight")
		light.Name = "NightLight"
		light.Color = colour((Data :: any).LAMP_COLOR)
		light.Brightness = 1.2
		light.Range = 14
		light.Enabled = isNightNow() -- night-only: off by day
		light.Parent = bulb
		track(light)
		lights[#lights + 1] = light
	end)
	if not ok then
		fail("could not create lamp light")
	end
end

local function apply(_plan: any)
	if active then
		return
	end
	failures = 0

	local root = stageFolder()
	if root then
		for _, descriptor in ipairs((Data :: any).SIGNS) do
			stagePole(descriptor, root)
			for _, plate in ipairs(descriptor.plates) do
				stagePlate(descriptor, plate, root)
			end
			stageLamp(descriptor, root)
		end
	end

	active = true
	publishFailures()
end

local function restore()
	if not active and #created == 0 then
		return
	end
	for index = #created, 1, -1 do
		local instance = created[index]
		pcall(function()
			instance:Destroy()
		end)
		created[index] = nil
	end
	for index = #lights, 1, -1 do
		lights[index] = nil
	end
	active = false
	publishFailures()
end

LookDevSignpostsR10.apply = apply
LookDevSignpostsR10.restore = restore

LookDev.register(FAMILY_ID, { apply = apply, restore = restore })

return LookDevSignpostsR10
