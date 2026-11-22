--!strict
-- LookDevCanonicalR10: SERVER-ONLY appliers for the ten OFF-BY-DEFAULT canonical-gap candidates
-- (WORK_QUEUE section P items 228-237). Each id gets its own Workspace Folder named
-- `LookDev_<id>`; only instances created here are destroyed on restore. Every engine call is
-- pcall guarded, overwritten properties (Pak RT roof colours and a displaced folder's Parent) are
-- saved and restored, and per-id failures are published through Shared.LookDevFailures.
--
--   require(game.ReplicatedStorage.Shared.LookDev).enable("balai_r10") -- etc.

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevCanonicalR10] missing service " .. name)
		return nil
	end
	return value
end

local ReplicatedStorage = service("ReplicatedStorage")
local Workspace = service("Workspace")
if not ReplicatedStorage or not Workspace then
	return {}
end

local okShared, Shared = pcall(function()
	return (ReplicatedStorage :: any):WaitForChild("Shared")
end)
if not okShared or not Shared then
	warn("[LookDevCanonicalR10] missing Shared folder")
	return {}
end

local okModules, LookDev, Data, Failures, Strings, PlotsData = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapCanonicalR10),
		require((Shared :: any).LookDevFailures),
		require((Shared :: any).Strings),
		require((Shared :: any).ModelMapPlotsR8)
end)
if not okModules or not LookDev or not Data or not Failures or not Strings or not PlotsData then
	warn(
		"[LookDevCanonicalR10] could not require LookDev / ModelMapCanonicalR10 / LookDevFailures / Strings / ModelMapPlotsR8"
	)
	return {}
end

local okSpec, loadedSpec = pcall(function()
	return require(script.Parent.MapSpec)
end)
if not okSpec or not loadedSpec then
	warn("[LookDevCanonicalR10] could not require MapSpec")
end
local MapSpec: any? = if okSpec then loadedSpec else nil

local okGame, Game = pcall(function()
	return require((Shared :: any).Config.Game)
end)
if not okGame or not Game then
	warn("[LookDevCanonicalR10] could not require Config.Game")
end

local LookDevCanonicalR10 = {}
LookDevCanonicalR10.appliers = {} :: { [string]: { apply: (any) -> (), restore: () -> () } }

local states: { [string]: any } = {}

local function stateFor(id: string): any
	if not states[id] then
		states[id] = {
			applied = false,
			folder = nil,
			previous = nil,
			created = {},
			saved = {},
			failures = 0,
		}
	end
	return states[id]
end

local function fail(id: string, message: string)
	local state = stateFor(id)
	state.failures += 1
	warn("[LookDevCanonicalR10] " .. id .. ": " .. message)
end

local function publish(id: string)
	pcall(function()
		Failures.set(id, stateFor(id).failures)
	end)
end

local function track(state: any, instance: any?)
	if instance then
		state.created[#state.created + 1] = instance
	end
	return instance
end

local function newInstance(state: any, className: string, name: string): any?
	local okNew, instance = pcall(function()
		return Instance.new(className)
	end)
	if not okNew or not instance then
		return nil
	end
	pcall(function()
		instance.Name = name
	end)
	return track(state, instance)
end

local function setAttrs(instance: any, values: { [string]: any })
	pcall(function()
		for key, value in pairs(values) do
			instance:SetAttribute(key, value)
		end
	end)
end

local function clearState(id: string)
	local state = stateFor(id)
	for index = #state.saved, 1, -1 do
		local entry = state.saved[index]
		pcall(function()
			entry.instance[entry.prop] = entry.value
		end)
		state.saved[index] = nil
	end
	for index = #state.created, 1, -1 do
		local instance = state.created[index]
		pcall(function()
			instance:Destroy()
		end)
		state.created[index] = nil
	end
	local previous = state.previous
	if previous then
		pcall(function()
			previous.Parent = Workspace
		end)
		state.previous = nil
	end
	state.folder = nil
	state.applied = false
end

local function openFolder(id: string): any?
	local state = stateFor(id)
	local name = Data.folderName(id)
	local previous = nil
	pcall(function()
		previous = (Workspace :: any):FindFirstChild(name)
	end)
	if previous then
		pcall(function()
			previous.Parent = nil
		end)
		state.previous = previous
	end
	local folder = newInstance(state, "Folder", name)
	if not folder then
		fail(id, "could not create " .. name)
		return nil
	end
	state.folder = folder
	setAttrs(folder, {
		[Data.stageAttribute] = id,
		[Data.kindAttribute] = "stage_folder",
	})
	pcall(function()
		folder.Parent = Workspace
	end)
	return folder
end

local function signText(id: string, board: any, key: string)
	local raw = Strings.raw and Strings.raw[key] or nil
	if type(raw) ~= "table" or type(raw.id) ~= "string" or type(raw.en) ~= "string" then
		fail(id, "sign key " .. tostring(key) .. " has no id/en variant")
		return
	end
	setAttrs(board, {
		[Data.stringsKeyAttribute] = key,
		[Data.idTextAttribute] = raw.id,
		[Data.enTextAttribute] = raw.en,
	})
	local gui = newInstance(stateFor(id), "SurfaceGui", "SignText")
	local label = newInstance(stateFor(id), "TextLabel", "SignLabel")
	if not gui or not label then
		fail(id, "could not build sign text")
		return
	end
	setAttrs(gui, { [Data.stageAttribute] = id, [Data.kindAttribute] = "sign_gui" })
	setAttrs(label, { [Data.stageAttribute] = id, [Data.kindAttribute] = "sign_label" })
	pcall(function()
		gui.Adornee = board
		gui.Face = (Enum :: any).NormalId.Front
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.TextScaled = true
		label.TextWrapped = true
		label.Text = Strings.get("id", key)
		label.Parent = gui
		gui.Parent = board
	end)
end

local function groundY(): number
	local y = 0.5
	if MapSpec and type(MapSpec.GROUND_Y) == "number" then
		y = MapSpec.GROUND_Y
	end
	return y
end

local function stageRecipe(id: string, parent: any, anchor: any, recipe: any, index: number)
	local state = stateFor(id)
	local partInst = newInstance(state, "Part", string.format("%s_%02d", recipe.kind, index))
	if not partInst then
		fail(id, "could not create " .. tostring(recipe.kind))
		return
	end
	local okShape, shapeValue = pcall(function()
		return (Enum :: any).PartType[recipe.shape] or (Enum :: any).PartType.Block
	end)
	if not okShape then
		shapeValue = nil
	end
	local okMaterial, materialValue = pcall(function()
		return (Enum :: any).Material[recipe.material] or (Enum :: any).Material.SmoothPlastic
	end)
	if not okMaterial then
		materialValue = nil
	end
	local baseY = type(anchor.y) == "number" and anchor.y or groundY()
	local okPose = pcall(function()
		local base = CFrame.new(anchor.x, baseY, anchor.z) * CFrame.Angles(0, math.rad(anchor.yaw or 0), 0)
		partInst.CFrame = base
			* CFrame.new(recipe.dx, recipe.dy, recipe.dz)
			* CFrame.Angles(math.rad(recipe.rx or 0), math.rad(recipe.ry or 0), math.rad(recipe.rz or 0))
	end)
	if not okPose then
		fail(id, "could not pose " .. tostring(recipe.kind))
		return
	end
	local okProps = pcall(function()
		partInst.Shape = shapeValue
		partInst.Material = materialValue
		partInst.Size = Vector3.new(recipe.size[1], recipe.size[2], recipe.size[3])
		partInst.Color = Color3.fromRGB(recipe.rgb[1], recipe.rgb[2], recipe.rgb[3])
		partInst.Anchored = true
		partInst.CanCollide = false -- visual candidate; never blocks the walking lane
		partInst.Parent = parent
	end)
	if not okProps then
		fail(id, "could not configure " .. tostring(recipe.kind))
		return
	end
	local attrs = {
		[Data.stageAttribute] = id,
		[Data.kindAttribute] = recipe.kind,
	}
	if recipe.species then
		attrs.Species = recipe.species
	end
	setAttrs(partInst, attrs)
	if recipe.signKey then
		signText(id, partInst, recipe.signKey)
	end
end

local function stageParts(id: string, folder: any, anchors: { any })
	local index = 0
	for _, anchor in ipairs(anchors) do
		local parent = folder
		if id == "sawah_gubuk_r10" then
			-- One counted hut Model per terrace anchor; the parts stay tagged as its children.
			local model = newInstance(stateFor(id), "Model", "Gubuk")
			if model then
				setAttrs(model, { [Data.stageAttribute] = id, [Data.kindAttribute] = "gubuk" })
				pcall(function()
					model.Parent = folder
				end)
				parent = model
			end
		end
		for _, recipe in ipairs(Data.partsFor(id, anchor)) do
			index += 1
			stageRecipe(id, parent, anchor, recipe, index)
		end
	end
	return index
end

local function plotGateCentres(): { any }
	local out = {}
	local okPlotGame, plotGame = pcall(function()
		return require((Shared :: any).Config.Game)
	end)
	if not okPlotGame or not plotGame or type(plotGame.plotCenter) ~= "function" then
		return out
	end
	local depth = PlotsData.PLOT_DEPTH or 34
	for index = 1, plotGame.plotCount or 10 do
		local okCentre, x, z = pcall(plotGame.plotCenter, index)
		if okCentre and type(x) == "number" and type(z) == "number" then
			local yaw = math.deg(math.atan2(x, z))
			local gx, gz = Data.rotatePoint(x, z, yaw, 0, -(depth / 2 + 3))
			out[#out + 1] = { x = gx, z = gz }
		end
	end
	return out
end

local function pakrtRoofTargets(hub: any): { any }
	local out = {}
	if not MapSpec or type(MapSpec.hubBounds) ~= "function" then
		return out
	end
	local okBounds, bounds = pcall(MapSpec.hubBounds, hub)
	if not okBounds or type(bounds) ~= "table" then
		return out
	end
	local pad = 4
	local okList, list = pcall(function()
		return (Workspace :: any):GetDescendants()
	end)
	if not okList or type(list) ~= "table" then
		return out
	end
	for _, instance in ipairs(list) do
		local okPart, isPart = pcall(function()
			return instance:IsA("BasePart")
		end)
		local okName, name = pcall(function()
			return instance.Name
		end)
		if
			okPart
			and isPart
			and okName
			and type(name) == "string"
			and string.find(name, "Roof", 1, true) ~= nil
			and string.find(name, "Ridge", 1, true) == nil
			and string.find(name, "Cap", 1, true) == nil
			and string.find(name, "Porch", 1, true) == nil
		then
			local okPos, x, y, z = pcall(function()
				local pos = instance.CFrame.Position
				return pos.X, pos.Y, pos.Z
			end)
			if
				okPos
				and x >= bounds.minX - pad
				and x <= bounds.maxX + pad
				and z >= bounds.minZ - pad
				and z <= bounds.maxZ + pad
				and y > groundY() + 4
			then
				out[#out + 1] = instance
			end
		end
	end
	return out
end

local function tintPakrt(id: string, hub: any)
	local state = stateFor(id)
	local targets = pakrtRoofTargets(hub)
	if #targets == 0 then
		fail(id, "no Pak RT roof panels found")
		return
	end
	local rgb = Data.COLORS.yellow_orange
	for _, instance in ipairs(targets) do
		local okRead, previous = pcall(function()
			return instance.Color
		end)
		if not okRead then
			fail(id, "could not read a roof colour")
			continue
		end
		state.saved[#state.saved + 1] = { instance = instance, prop = "Color", value = previous }
		local okWrite, err = pcall(function()
			instance.Color = Color3.fromRGB(rgb[1], rgb[2], rgb[3])
		end)
		if not okWrite then
			fail(id, "could not retint a roof: " .. tostring(err))
		end
	end
end

local function context(id: string): any
	return {
		MapSpec = MapSpec,
		Game = if okGame then Game else nil,
		groundY = groundY(),
		gateCentres = id == "blocks_shrubs_r10" and plotGateCentres() or nil,
	}
end

local function make(id: string): { apply: (any) -> (), restore: () -> () }
	local function apply(_plan: any)
		local state = stateFor(id)
		if state.applied then
			return
		end
		clearState(id)
		state.failures = 0
		pcall(function()
			Failures.reset(id)
		end)
		if not MapSpec or not Data.known(id) then
			fail(id, "MapSpec / id missing")
			publish(id)
			return
		end
		local folder = openFolder(id)
		if not folder then
			publish(id)
			return
		end
		local anchors = Data.anchorsFor(id, context(id))
		if #anchors == 0 then
			fail(id, "no MapSpec anchors")
			publish(id)
			return
		end
		if id == "pakrt_roof_r10" then
			tintPakrt(id, anchors[1].hub)
		else
			local staged = stageParts(id, folder, anchors)
			local expected = Data.counts(id, { MapSpec = MapSpec }).parts * #anchors
			if staged < expected then
				fail(id, "staged " .. staged .. "/" .. expected .. " parts")
			end
		end
		pcall(function()
			folder:SetAttribute("AnchorCount", #anchors)
		end)
		state.applied = true
		publish(id)
	end

	local function restore()
		local state = stateFor(id)
		if not state.applied and #state.created == 0 and #state.saved == 0 and not state.previous then
			return
		end
		clearState(id)
		publish(id)
	end

	return { apply = apply, restore = restore }
end

for _, id in ipairs(Data.order) do
	local applier = make(id)
	LookDevCanonicalR10.appliers[id] = applier
	LookDev.register(id, { apply = applier.apply, restore = applier.restore })
end

return LookDevCanonicalR10
