--!strict
-- LookDevSignpostsR10: SERVER-ONLY applier for the OFF-BY-DEFAULT "signposts_r10" candidate
-- (WORK_QUEUE item 257). Stages four restyled baked blank signposts at the ring-road junctions,
-- each with six green arrow plates, white id text from Shared.Strings and a small lamp on top.
-- Geometry, palette and text keys come from Shared.ModelMapSignpostsR10; the baked asset ID lives
-- here (pure-data specs forbid 8-digit literals). Only instances created here are destroyed, in
-- LIFO order; apply/restore are idempotent and pcall-guarded throughout.
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

local okModules, LookDev, Data, LookDevFailures, Strings, LookDevAssetLoader = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapSignpostsR10),
		require((Shared :: any).LookDevFailures),
		require((Shared :: any).Strings),
		require(script.Parent.LookDevAssetLoader)
end)
if not okModules or not LookDev or not Data or not LookDevFailures or not Strings or not LookDevAssetLoader then
	warn(
		"[LookDevSignpostsR10] could not require LookDev / ModelMapSignpostsR10 / LookDevFailures / Strings / LookDevAssetLoader"
	)
	return {}
end

local LookDevSignpostsR10 = {}

local FAMILY_ID = Data.id
local STAGE_ATTR = "LookDevStage"

-- Baked pick 2 from WORK_QUEUE item 257. Baked-only: LoadAsset is unauthorised in this place.
local ASSET_IDS: { [string]: number } = {
	signpost = 71310674426033,
}

local failures = 0
local active = false
local created: { any } = {}

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

-- Every staged descendant carries the family tag and sign metadata; only the first plate of each
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

local function bounds(instance: any)
	local ok, cframe, size = pcall(function()
		if instance:IsA("Model") then
			return instance:GetBoundingBox()
		end
		if instance:IsA("BasePart") then
			return instance.CFrame, instance.Size
		end
		return nil, nil
	end)
	if ok then
		return cframe, size
	end
	return nil, nil
end

local function loadPost()
	local key = (Data :: any).ASSET_KEY
	local assetId = ASSET_IDS[key]
	if type(assetId) ~= "number" then
		fail("missing baked signpost asset id for " .. tostring(key))
		return nil
	end
	local ok, model = pcall(function()
		return (LookDevAssetLoader :: any).baked(assetId)
	end)
	if not ok or not model then
		fail("baked signpost asset unavailable: " .. tostring(assetId) .. " " .. tostring(model))
		return nil
	end
	return model
end

local function placePost(model: any, descriptor: any)
	local okDescendants, descendants = pcall(function()
		return model:GetDescendants()
	end)
	if okDescendants and type(descendants) == "table" then
		for _, child in ipairs(descendants) do
			pcall(function()
				if child:IsA("LuaSourceContainer") then
					child:Destroy()
				end
			end)
			tag(child, descriptor.index)
			pcall(function()
				if child:IsA("BasePart") then
					child.Anchored = true
					child.CanCollide = false
					child.CastShadow = false
					-- Restyle the baked pole green. The four blank vanes stay in the hierarchy
					-- as green restyled parts but hide behind the six readable arrow plates.
					child.Color = colour((Data :: any).POST_COLOR)
					if child:IsA("MeshPart") then
						child.TextureID = ""
					end
					if string.find(child.Name, "Sign_", 1, true) == 1 then
						child.Transparency = 1
					end
				end
			end)
		end
	end
	tag(model, descriptor.index)

	local bboxCFrame, bboxSize = bounds(model)
	if not bboxCFrame or not bboxSize or bboxSize.Y <= 0 then
		return false
	end
	pcall(function()
		if model:IsA("Model") then
			model:ScaleTo((Data :: any).POST_SIZE[2] / bboxSize.Y)
		end
	end)
	bboxCFrame, bboxSize = bounds(model)
	if not bboxCFrame or not bboxSize then
		return false
	end
	local pivot: any = if model:IsA("Model") then model:GetPivot() else model.CFrame
	if not pivot then
		return false
	end
	local offset = bboxCFrame.Position - pivot.Position
	local target = CFrame.new(
		Vector3.new(descriptor.position.x, descriptor.position.y + bboxSize.Y / 2, descriptor.position.z)
	) * CFrame.Angles(0, math.rad(descriptor.yaw), 0) * CFrame.new(-offset)
	local okPlace = pcall(function()
		if model:IsA("Model") then
			model:PivotTo(target)
		else
			model.CFrame = target
		end
	end)
	return okPlace
end

local function stageFallbackPost(descriptor: any, parent: any)
	local post = (Instance :: any).new("Part")
	post.Name = descriptor.name .. "_SteelPost"
	post.Size = Vector3.new((Data :: any).POST_SIZE[1], (Data :: any).POST_SIZE[2], (Data :: any).POST_SIZE[3])
	post.CFrame =
		CFrame.new(descriptor.position.x, descriptor.position.y + (Data :: any).POST_SIZE[2] / 2, descriptor.position.z)
	post.Color = colour((Data :: any).POST_COLOR)
	post.Material = Enum.Material.Metal
	post.Anchored = true
	post.CanCollide = false
	post.CastShadow = false
	tag(post, descriptor.index)
	track(post)
	post.Parent = parent
end

local function addPlateText(board: any, descriptor: any, plate: any)
	local ok = pcall(function()
		local gui = (Instance :: any).new("SurfaceGui")
		gui.Name = "SignFace"
		gui.Face = Enum.NormalId.Front
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = (Data :: any).PIXELS_PER_STUD
		gui.LightInfluence = 0
		local label = (Instance :: any).new("TextLabel")
		label.Name = "SignText"
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.TextScaled = true
		label.TextSize = plate.fontSizePx
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.Font = Enum.Font.GothamBold
		label.Text = Strings.get("id", plate.textKey)
		label.Parent = gui
		gui.Parent = board
		track(label)
		track(gui)
		tag(label, descriptor.index, { textKey = plate.textKey, fontSizePx = plate.fontSizePx })
		tag(gui, descriptor.index, { textKey = plate.textKey, fontSizePx = plate.fontSizePx })
	end)
	if not ok then
		fail("could not write sign text for " .. tostring(plate.textKey))
	end
end

local function stagePlate(descriptor: any, plate: any, parent: any)
	local yaw = math.rad(descriptor.yaw)
	local faceYaw = math.rad(descriptor.yaw + plate.yawOffset)
	local forwardX, forwardZ = math.sin(yaw), math.cos(yaw)
	local lateralX, lateralZ = math.cos(yaw), -math.sin(yaw)
	local offset = plate.side * (Data :: any).PLATE_LATERAL
	local origin = CFrame.new(
		Vector3.new(
			descriptor.position.x + forwardX * 0.5 + lateralX * offset,
			descriptor.position.y + plate.height,
			descriptor.position.z + forwardZ * 0.5 + lateralZ * offset
		)
	) * CFrame.Angles(0, faceYaw, 0)

	local board = (Instance :: any).new("Part")
	board.Name = plate.name
	board.Size = Vector3.new((Data :: any).PLATE_SIZE[1], (Data :: any).PLATE_SIZE[2], (Data :: any).PLATE_SIZE[3])
	board.CFrame = origin
	board.Color = colour((Data :: any).PLATE_COLOR)
	board.Material = Enum.Material.Metal
	board.Anchored = true
	board.CanCollide = false
	board.CastShadow = false
	tag(board, descriptor.index, {
		SignpostPlate = true,
		Signpost = plate.order == 1,
		textKey = plate.textKey,
		fontSizePx = plate.fontSizePx,
		plateOrder = plate.order,
	})
	track(board)
	board.Parent = parent

	-- A thin wedge tip makes each flat green board read as a direction arrow.
	local tip = (Instance :: any).new("Part")
	tip.Name = plate.name .. "_Tip"
	tip.Shape = Enum.PartType.Wedge
	tip.Size = Vector3.new(0.9, (Data :: any).PLATE_SIZE[2], (Data :: any).PLATE_SIZE[3])
	tip.CFrame = origin * CFrame.new((Data :: any).PLATE_SIZE[1] / 2 + 0.42, 0, 0)
	tip.Color = colour((Data :: any).PLATE_COLOR)
	tip.Material = Enum.Material.Metal
	tip.Anchored = true
	tip.CanCollide = false
	tip.CastShadow = false
	tag(tip, descriptor.index)
	track(tip)
	tip.Parent = parent

	addPlateText(board, descriptor, plate)
end

local function stageLamp(descriptor: any, parent: any)
	local top = descriptor.position.y + (Data :: any).POST_SIZE[2]
	local socket = (Instance :: any).new("Part")
	socket.Name = descriptor.name .. "_LampSocket"
	socket.Shape = Enum.PartType.Cylinder
	socket.Size = Vector3.new((Data :: any).LAMP_SIZE[1], 0.18, (Data :: any).LAMP_SIZE[1])
	socket.CFrame = CFrame.new(descriptor.position.x, top + 0.09, descriptor.position.z)
	socket.Color = colour((Data :: any).POST_COLOR)
	socket.Anchored = true
	socket.CanCollide = false
	socket.CastShadow = false
	tag(socket, descriptor.index)
	track(socket)
	socket.Parent = parent

	local bulb = (Instance :: any).new("Part")
	bulb.Name = descriptor.name .. "_Lamp"
	bulb.Shape = Enum.PartType.Ball
	bulb.Size = Vector3.new((Data :: any).LAMP_SIZE[1], (Data :: any).LAMP_SIZE[2], (Data :: any).LAMP_SIZE[1])
	bulb.CFrame = CFrame.new(descriptor.position.x, top + 0.18 + (Data :: any).LAMP_SIZE[2] / 2, descriptor.position.z)
	bulb.Color = colour((Data :: any).LAMP_COLOR)
	bulb.Material = Enum.Material.Neon
	bulb.Anchored = true
	bulb.CanCollide = false
	bulb.CastShadow = false
	tag(bulb, descriptor.index, { SignpostLamp = true })
	track(bulb)
	bulb.Parent = parent
end

local function apply(_plan: any)
	if active then
		return
	end
	failures = 0

	local root = stageFolder()
	if root then
		for _, descriptor in ipairs((Data :: any).SIGNS) do
			local model = loadPost()
			if model and placePost(model, descriptor) then
				model.Name = descriptor.name
				model.Parent = root
				track(model)
			else
				if model then
					pcall(function()
						model:Destroy()
					end)
				end
				stageFallbackPost(descriptor, root)
			end
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
	active = false
	publishFailures()
end

LookDevSignpostsR10.apply = apply
LookDevSignpostsR10.restore = restore

LookDev.register(FAMILY_ID, { apply = apply, restore = restore })

return LookDevSignpostsR10
