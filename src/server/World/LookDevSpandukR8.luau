--!strict
-- LookDevSpandukR8: SERVER-ONLY applier for the OFF-BY-DEFAULT "spanduk_r8" candidate
-- (WORK_QUEUE section M item 81). Stages a Warung sign, a Pasar sign, one spanduk across the main
-- south road and two bunting strings (one text panel each) from original Parts under
-- `LookDevSpandukR8_spanduk_r8`. No asset IDs, no brand logos.
--
-- All anchors come from MapSpec geometry through Shared.ModelMapSpandukR8; no world-coordinate
-- literals. Each facing board carries a `SignKey` (a Strings key) and an `ApproachCamera` (a
-- Shared.ReviewCameras name); its CFrame.LookVector is aimed at that camera's eye, so the harness
-- SIGN_FACING check can measure the angle with CFrame/dot math. All text comes from Strings.get with
-- the fixed server locale ("id") and the UI font set from Shared.Config.Visuals, so no player-facing
-- text or font name literal is written to a Text/Font property in src/.
--
-- Every part is anchored and non-collidable; apply is idempotent and restore returns any prior
-- folder exactly. Engine calls are pcall-guarded; failures are published through LookDevFailures.
--   require(game.ReplicatedStorage.Shared.LookDevReview).enable("spanduk_r8", game)

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevSpandukR8] missing service " .. name)
		return nil
	end
	return value
end

local ReplicatedStorage = service("ReplicatedStorage")
local Workspace = service("Workspace")

local Shared: any? = nil
if ReplicatedStorage then
	local ok, folder = pcall(function()
		return (ReplicatedStorage :: any):WaitForChild("Shared")
	end)
	if ok and folder then
		Shared = folder
	else
		warn("[LookDevSpandukR8] missing Shared folder")
	end
end
if not Shared then
	return {}
end

local okModules, LookDev, Data, Strings, LookDevFailures, Visuals = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapSpandukR8),
		require((Shared :: any).Strings),
		require((Shared :: any).LookDevFailures),
		require((Shared :: any).Config.Visuals)
end)
if not okModules or not LookDev or not Data or not Strings or not LookDevFailures or not Visuals then
	warn("[LookDevSpandukR8] could not require LookDev / ModelMapSpandukR8 / Strings / LookDevFailures / Visuals")
	return {}
end

local okSpec, loadedSpec = pcall(function()
	return require(script.Parent.MapSpec)
end)
if not okSpec or not loadedSpec then
	warn("[LookDevSpandukR8] could not require MapSpec")
end
local MapSpec: any? = if okSpec then loadedSpec else nil

-- ReviewCameras lives in Shared but requires MapSpec from the Server datamodel, so it is readable
-- here. Guard the require; if it is absent the boards still stage but facing is unpublished.
local okCameras, loadedCameras = pcall(function()
	return require((Shared :: any).ReviewCameras)
end)
local ReviewCameras: any? = if okCameras then loadedCameras else nil

local LookDevSpandukR8 = {}

local SIGN_LANG = "id" -- server has no client locale; Indonesian is the canonical sign text

local failures = 0
local activeFolder: any? = nil
local savedFolder: any? = nil
local staged: { any } = {}

local function fail(message: string)
	failures += 1
	warn("[LookDevSpandukR8] " .. message)
end

local function publishFailures()
	pcall(function()
		LookDevFailures.set(Data.familyId, failures)
	end)
end

local function track(instance: any?)
	if instance then
		staged[#staged + 1] = instance
	end
end

local function clearActive()
	for index = #staged, 1, -1 do
		pcall(function()
			staged[index]:Destroy()
		end)
	end
	table.clear(staged)
	local folder = activeFolder
	if folder then
		pcall(function()
			folder:Destroy()
		end)
	end
	activeFolder = nil
end

local function newFolder(name: string, parent: any): any?
	local okNew, folder = pcall(function()
		return Instance.new("Folder")
	end)
	if not okNew or not folder then
		return nil
	end
	pcall(function()
		folder.Name = name
		folder.Parent = parent
	end)
	return folder
end

-- Approach-camera eye as an array {x, y, z}, or nil when the registry/name is unavailable.
local function cameraEye(name: string): { number }?
	if not ReviewCameras then
		return nil
	end
	local ok, camera = pcall(function()
		return (ReviewCameras :: any).get(name)
	end)
	if not ok or not camera or type(camera.position) ~= "table" then
		return nil
	end
	return camera.position
end

-- Base frame whose LookVector points horizontally at the approach camera. Local X is the board's
-- width direction; local Y stays world-up, so every child offset keeps its intended meaning.
local function facingBase(x: number, z: number, groundY: number, eye: { number }?): any?
	local ok, base = pcall(function()
		if eye then
			return CFrame.lookAt(Vector3.new(x, groundY, z), Vector3.new(eye[1], groundY, eye[3]))
		end
		return CFrame.new(x, groundY, z)
	end)
	if not ok or not base then
		fail("could not build facing base CFrame")
		return nil
	end
	return base
end

local function newModel(name: string, kind: string, key: string, camera: string, folder: any): any?
	local ok, model = pcall(function()
		return Instance.new("Model")
	end)
	if not ok or not model then
		fail("could not create model for " .. name)
		return nil
	end
	track(model)
	local okSet = pcall(function()
		model.Name = name
		model:SetAttribute(Data.stageAttribute, Data.familyId)
		model:SetAttribute(Data.kindAttribute, kind)
		model:SetAttribute(Data.keyAttribute, key)
		model:SetAttribute(Data.cameraAttribute, camera)
		model.Parent = folder
	end)
	if not okSet then
		fail("could not configure model for " .. name)
	end
	return model
end

local function placePart(
	model: any,
	descriptor: any,
	base: any,
	kind: string,
	colour: { number }?,
	size: { number }?,
	offset: { number }?,
	worldCF: any?
): any?
	local ok, part = pcall(function()
		return Instance.new("Part")
	end)
	if not ok or not part then
		fail("could not create part " .. descriptor.name .. " for " .. kind)
		return nil
	end
	track(part)
	local shapeName = descriptor.shape == "Cylinder" and "Cylinder" or "Block"
	local finalSize = size or descriptor.size
	local finalOffset = offset or descriptor.offset
	local finalColour = colour or descriptor.colour
	local okSet = pcall(function()
		local okShape, shape = pcall(function()
			return (Enum :: any).PartType[shapeName]
		end)
		part.Name = descriptor.name
		part.Shape = if okShape and shape then shape else Enum.PartType.Block
		part.Size = Vector3.new(finalSize[1], finalSize[2], finalSize[3])
		part.CFrame = if worldCF then worldCF else base * CFrame.new(finalOffset[1], finalOffset[2], finalOffset[3])
		part.Color = Color3.fromRGB(finalColour[1], finalColour[2], finalColour[3])
		part.Material = (Enum :: any).Material[descriptor.material] or Enum.Material.SmoothPlastic
		part.Anchored = true
		part.CanCollide = false
		part:SetAttribute(Data.stageAttribute, Data.familyId)
		part:SetAttribute(Data.kindAttribute, kind)
		part.Parent = model
	end)
	if not okSet then
		fail("could not configure part " .. descriptor.name .. " for " .. kind)
	end
	return part
end

-- A facing board carries its Strings KEY and renders Strings.get(lang, key) on both faces, using
-- the UI display font from Shared.Config.Visuals. Both faces are written so the text reads from
-- either side regardless of the Front/Back face convention; the facing normal is CFrame.LookVector.
local FONT = (Enum :: any).Font

local function addSignText(board: any, key: string)
	local ok = pcall(function()
		board:SetAttribute(Data.keyAttribute, key)
		local font = FONT[Visuals.fonts.display] or FONT[Visuals.fonts.body]
		for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
			local gui = Instance.new("SurfaceGui")
			gui.Name = "SignFace"
			gui.Face = face
			gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			gui.PixelsPerStud = 40
			gui.LightInfluence = 0
			local label = Instance.new("TextLabel")
			label.Size = UDim2.fromScale(1, 1)
			label.BackgroundTransparency = 1
			label.TextScaled = true
			label.TextWrapped = true
			label.Font = font
			label.TextColor3 = Color3.fromRGB(48, 34, 24)
			label.Text = Strings.get(SIGN_LANG, key)
			label.Parent = gui
			gui.Parent = board
			track(label)
			track(gui)
		end
	end)
	if not ok then
		fail("could not write sign text for " .. key)
	end
end

local function stageHubSign(recipe: any, index: number, groundY: number, folder: any)
	local model = newModel(string.format("Spanduk_sign_%02d", index), "sign", recipe.key, recipe.camera, folder)
	if not model then
		return
	end
	local base = facingBase(recipe.x, recipe.z, groundY, cameraEye(recipe.camera))
	if not base then
		return
	end
	for _, descriptor in ipairs(Data.RECIPES.sign) do
		local board = placePart(model, descriptor, base, "sign")
		if board and descriptor.name == "Board" then
			addSignText(board, recipe.key)
		end
	end
end

local function stageRoadSpanduk(recipe: any, groundY: number, folder: any)
	local model = newModel("Spanduk_road_01", "spanduk", recipe.key, recipe.camera, folder)
	if not model then
		return
	end
	local base = facingBase(recipe.x, recipe.z, groundY, cameraEye(recipe.camera))
	if not base then
		return
	end
	for _, descriptor in ipairs(Data.RECIPES.spanduk) do
		local size, offset = descriptor.size, descriptor.offset
		if descriptor.name == "PoleL" then
			offset = { -recipe.halfSpan, offset[2], 0 }
		elseif descriptor.name == "PoleR" then
			offset = { recipe.halfSpan, offset[2], 0 }
		elseif descriptor.name == "Board" then
			size = { recipe.halfSpan * 2, size[2], size[3] }
		end
		local board = placePart(model, descriptor, base, "spanduk", nil, size, offset)
		if board and descriptor.name == "Board" then
			addSignText(board, recipe.key)
		end
	end
end

local function stageBunting(recipe: any, index: number, groundY: number, folder: any)
	local model = newModel(string.format("Spanduk_bunting_%02d", index), "bunting", recipe.key, recipe.camera, folder)
	if not model then
		return
	end
	-- Poles and cord stand in world space; only the text panel faces the approach camera.
	local topY = groundY + recipe.poleHeight
	local okPoles = pcall(function()
		for _, descriptor in ipairs(Data.RECIPES.bunting) do
			if descriptor.name == "PoleL" or descriptor.name == "PoleR" then
				local pole = recipe.left
				if descriptor.name == "PoleR" then
					pole = recipe.right
				end
				placePart(
					model,
					descriptor,
					CFrame.new(pole.x, groundY, pole.z),
					"bunting",
					nil,
					nil,
					nil,
					CFrame.new(pole.x, groundY + descriptor.size[2] / 2, pole.z)
				)
			elseif descriptor.name == "Cord" then
				local from = Vector3.new(recipe.left.x, topY, recipe.left.z)
				local to = Vector3.new(recipe.right.x, topY, recipe.right.z)
				local middle = (from + to) / 2
				local cord = placePart(
					model,
					descriptor,
					CFrame.new(middle),
					"bunting",
					nil,
					{ (to - from).Magnitude, 0.1, 0.1 },
					nil,
					CFrame.lookAt(middle, to)
				)
				if cord and cord.Name ~= "Cord" then
					cord.Name = "Cord"
				end
			end
		end
	end)
	if not okPoles then
		fail("could not stage bunting poles/cord " .. tostring(index))
	end

	for flag = 1, recipe.count do
		local point = Data.buntingPoint(recipe, (flag - 1) / math.max(recipe.count - 1, 1))
		if point then
			if flag == recipe.textIndex then
				local panelY = topY - point.drop - Data.RECIPES.bunting[4].size[2] / 2
				local panelBase = facingBase(point.x, point.z, panelY, cameraEye(recipe.camera))
				if panelBase then
					for _, descriptor in ipairs(Data.RECIPES.bunting) do
						if descriptor.name == "Board" then
							local board = placePart(model, descriptor, panelBase, "bunting")
							if board then
								board.Name = "Board"
								addSignText(board, recipe.key)
							end
						end
					end
				end
			else
				local flagY = topY - point.drop - Data.RECIPES.flag[1].size[2] / 2
				placePart(model, Data.RECIPES.flag[1], CFrame.new(point.x, flagY, point.z), "bunting")
			end
		end
	end
end

local applier = {
	apply = function()
		failures = 0
		pcall(function()
			LookDevFailures.reset(Data.familyId)
		end)
		clearActive()
		if not Workspace or not MapSpec then
			fail("missing Workspace/MapSpec")
			publishFailures()
			return
		end
		local previous = nil
		pcall(function()
			previous = (Workspace :: any):FindFirstChild(Data.folderName)
		end)
		if previous then
			pcall(function()
				previous.Parent = nil
			end)
			savedFolder = previous
		end
		local folder = newFolder(Data.folderName, Workspace)
		if not folder then
			fail("could not create staging folder")
			publishFailures()
			return
		end
		activeFolder = folder
		track(folder)

		local warung = MapSpec.hub("warung")
		local pasar = MapSpec.hub("pasar")
		if warung then
			local recipe = Data.hubSign(warung, "sign_warung", "hub_warung")
			if recipe then
				stageHubSign(recipe, 1, MapSpec.GROUND_Y, folder)
			end
		else
			fail("no MapSpec warung hub")
		end
		if pasar then
			local recipe = Data.hubSign(pasar, "spanduk_pasar", "hub_pasar")
			if recipe then
				stageHubSign(recipe, 2, MapSpec.GROUND_Y, folder)
			end
		else
			fail("no MapSpec pasar hub")
		end

		local southArm = nil
		for _, arm in ipairs(MapSpec.roadArms()) do
			if arm.name == "RoadSouth" then
				southArm = arm
				break
			end
		end
		if southArm then
			local recipe = Data.roadSpanduk(southArm, "spanduk_selamat_datang", "canonical_overview")
			if recipe then
				stageRoadSpanduk(recipe, MapSpec.GROUND_Y, folder)
			end
		else
			fail("no MapSpec south road arm")
		end

		local buntingWarung = if warung then Data.bunting(warung, "bunting_mampir", "hub_warung", 1) else nil
		local buntingPasar = if pasar then Data.bunting(pasar, "bunting_belanja", "hub_pasar", -1) else nil
		if buntingWarung then
			stageBunting(buntingWarung, 1, MapSpec.GROUND_Y, folder)
		end
		if buntingPasar then
			stageBunting(buntingPasar, 2, MapSpec.GROUND_Y, folder)
		end

		publishFailures()
	end,

	restore = function()
		clearActive()
		local previous = savedFolder
		if previous then
			pcall(function()
				previous.Parent = Workspace
			end)
			savedFolder = nil
		end
		publishFailures()
	end,
}

LookDevSpandukR8.apply = applier.apply
LookDevSpandukR8.restore = applier.restore

LookDev.register(Data.familyId, applier)

return LookDevSpandukR8
