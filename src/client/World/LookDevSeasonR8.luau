--!strict
-- LookDevSeasonR8: CLIENT-ONLY appliers for the OFF-BY-DEFAULT "season_r8_hujan/kemarau/panen"
-- looks (WORK_QUEUE section N item 119). Pure values come from Shared.ModelMapSeasonR8.
--
-- Scope: Lighting's own scalar/byte-RGB props, the EXISTING Atmosphere effect, Clouds.Cover under
-- Workspace.Terrain, a bounded snapshot/restored set of existing decor Part colours, and (hujan
-- only) six own anchored puddle-sheet Parts. No ColorCorrection, Bloom, SunRays, ClockTime,
-- Terrain voxel write, DataStore/player/crop state. CLIENT VM REQUIRED: src/client/World/Sky.luau
-- creates Clouds under Terrain and Atmosphere under Lighting on the client only, and tweens Cover
-- for 4 s on mount. A server applier finds no Clouds at all; the harness waits once before its
-- baseline so this applier writes after Sky's tween has settled.
--
-- Every overwritten property is saved on apply and restored byte-for-byte LIFO on restore. Only
-- instances created here are destroyed; a prior same-named puddle folder is detached and
-- re-parented exactly. apply/restore are idempotent, every engine call is pcall-guarded, and
-- failures are published through Shared.LookDevFailures. No asset IDs.
--
--   require(game.ReplicatedStorage.Shared.LookDevReview).enable("season_r8_hujan", game)

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if ok then
		return value
	end
	warn("[LookDevSeasonR8] missing service " .. name)
	return nil
end

local ReplicatedStorage = service("ReplicatedStorage")
local Lighting = service("Lighting")
local Workspace = service("Workspace")
if not ReplicatedStorage or not Lighting or not Workspace then
	return {}
end

local okShared, Shared = pcall(function()
	return (ReplicatedStorage :: any):WaitForChild("Shared")
end)
if not okShared or not Shared then
	warn("[LookDevSeasonR8] missing Shared folder")
	return {}
end

local okModules, LookDev, Data, Failures = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapSeasonR8),
		require((Shared :: any).LookDevFailures)
end)
if not okModules or not LookDev or not Data or not Failures then
	warn("[LookDevSeasonR8] could not require LookDev / ModelMapSeasonR8 / LookDevFailures")
	return {}
end

-- Client convention (LookDevAnimalsR8/LookDevFlyersR8/etc.): never resolve MapSpec relative to
-- this client folder. Prefer the Shared replica when present, then the established server path;
-- a missing spec uses the documented Data.PUDDLE_Y_FALLBACK instead of disabling puddle staging.
local function loadMapSpec(): any?
	local okSharedSpec, spec = pcall(function()
		local world = (Shared :: any).World
		local module = if world then (world :: any):FindFirstChild("MapSpec") else nil
		return if module then require(module) else nil
	end)
	if okSharedSpec and type(spec) == "table" then
		return spec
	end
	local okServer, serverSpec = pcall(function()
		local server = game:GetService("ServerScriptService"):FindFirstChild("Server")
		local world = if server then (server :: any):FindFirstChild("World") else nil
		local module = if world then (world :: any):FindFirstChild("MapSpec") else nil
		return if module then require(module) else nil
	end)
	if okServer and type(serverSpec) == "table" then
		return serverSpec
	end
	return nil
end

local MapSpec = loadMapSpec()

local LookDevSeasonR8 = {}
LookDevSeasonR8.appliers = {} :: { [string]: any }

type SavedProp = { effect: any, prop: string, key: string, value: any }

local function make(key: string): any
	local id: string = Data.idPrefix .. key
	local applied = false
	local failures = 0
	local savedOrder: { SavedProp } = {}
	local savedFolder: any = nil
	local activeFolder: any = nil
	local state = { activeKey = nil :: string?, applied = false, tinted = 0, saved = 0 }

	local function fail(message: string)
		failures += 1
		warn("[LookDevSeasonR8] " .. id .. ": " .. message)
	end

	local function publishFailures()
		pcall(function()
			Failures.set(id, failures)
		end)
	end

	-- enable() passes LookDev.plan(id), not a raw id. Honour the explicit key fields and also accept
	-- the id suffix so the applier stays correct if a caller hands it the bare id.
	local function resolveKey(plan: any): string?
		if type(plan) == "table" then
			for _, field in ipairs({ "seasonKey", "key" }) do
				local candidate = plan[field]
				if type(candidate) == "string" and Data.valuesFor(candidate) then
					return candidate
				end
			end
			if type(plan.id) == "string" and #plan.id > #Data.idPrefix then
				local suffix = string.sub(plan.id, #Data.idPrefix + 1)
				if Data.valuesFor(suffix) then
					return suffix
				end
			end
		end
		return key
	end

	local function saveProp(effect: any, prop: string, keyName: string): boolean
		for _, entry in ipairs(savedOrder) do
			if entry.key == keyName then
				return true
			end
		end
		local okRead, value = pcall(function()
			return effect[prop]
		end)
		if not okRead then
			fail("could not read " .. keyName .. ": " .. tostring(value))
			return false
		end
		savedOrder[#savedOrder + 1] = { effect = effect, prop = prop, key = keyName, value = value }
		return true
	end

	local function setProp(effect: any, prop: string, keyName: string, value: any)
		local okSet, err = pcall(function()
			effect[prop] = value
		end)
		if not okSet then
			fail("could not set " .. keyName .. ": " .. tostring(err))
		end
	end

	local function rgb(value: any): (any?, string?)
		if type(value) ~= "table" then
			return nil, "missing RGB triple"
		end
		local ok, color = pcall(function()
			return Color3.fromRGB(value.r, value.g, value.b)
		end)
		if not ok or not color then
			return nil, tostring(color)
		end
		return color, nil
	end

	local function targetValue(className: string, prop: string, value: any): (any?, string?)
		if className == "Lighting" and prop ~= "Brightness" and prop ~= "FogEnd" then
			return rgb(value)
		end
		if className == "Atmosphere" and (prop == "Color" or prop == "Decay") then
			return rgb(value)
		end
		if className == "Decor" and prop == "Color" then
			return rgb(value)
		end
		return value, nil
	end

	local function findAtmosphere(): any?
		local ok, effect = pcall(function()
			return (Lighting :: any):FindFirstChildOfClass("Atmosphere")
		end)
		if not ok then
			fail("Atmosphere lookup: " .. tostring(effect))
			return nil
		end
		if not effect then
			fail("no existing Atmosphere under Lighting")
		end
		return effect
	end

	-- Sky creates this Clouds instance on the client under Workspace.Terrain. Never create one.
	local function findClouds(): any?
		local ok, clouds = pcall(function()
			local terrain = (Workspace :: any):FindFirstChild("Terrain")
			return if terrain then (terrain :: any):FindFirstChildOfClass("Clouds") else nil
		end)
		if not ok then
			fail("Clouds lookup: " .. tostring(clouds))
			return nil
		end
		if not clouds then
			fail("no existing Clouds under Terrain")
		end
		return clouds
	end

	local function matchingParts(selector: any): { any }
		local found = {}
		local okList, list = pcall(function()
			return (Workspace :: any):GetDescendants()
		end)
		if not okList or type(list) ~= "table" then
			fail("decor scan: " .. tostring(list))
			return found
		end
		for _, instance in ipairs(list) do
			if #found >= selector.max then
				break
			end
			local okPart, isPart = pcall(function()
				return (instance :: any):IsA("BasePart")
			end)
			if okPart and isPart then
				local use = true
				if selector.namePrefix then
					local okName, name = pcall(function()
						return (instance :: any).Name
					end)
					use = okName
						and type(name) == "string"
						and string.sub(name, 1, #selector.namePrefix) == selector.namePrefix
				end
				if use then
					local okAttr, value = pcall(function()
						return (instance :: any):GetAttribute(selector.attribute)
					end)
					use = okAttr and value ~= nil
				end
				if use then
					found[#found + 1] = instance
				end
			end
		end
		return found
	end

	local function clearPuddles()
		if activeFolder then
			pcall(function()
				activeFolder:Destroy()
			end)
			activeFolder = nil
		end
	end

	local function stagePuddles(tint: any)
		local roadY: any = nil
		if MapSpec and type((MapSpec :: any).ROAD) == "table" then
			roadY = (MapSpec :: any).ROAD.y
		end
		if type(roadY) ~= "number" then
			roadY = Data.PUDDLE_Y_FALLBACK
		end
		if type(roadY) ~= "number" then
			fail("MapSpec.ROAD.y and PUDDLE_Y_FALLBACK unavailable; puddle sheets not staged")
			return
		end
		clearPuddles()
		local okFind, previous = pcall(function()
			return (Workspace :: any):FindFirstChild(Data.PUDDLE_FOLDER)
		end)
		if okFind and previous then
			pcall(function()
				previous.Parent = nil
			end)
			savedFolder = previous
		end
		local okFolder, folder = pcall(function()
			return (Instance :: any).new("Folder")
		end)
		if not okFolder or not folder then
			fail("could not create puddle folder: " .. tostring(folder))
			return
		end
		pcall(function()
			folder.Name = Data.PUDDLE_FOLDER
			folder:SetAttribute("LookDevSeasonR8", id)
			folder.Parent = Workspace
		end)
		activeFolder = folder
		for index, sheet in ipairs(Data.PUDDLE_SHEETS) do
			local okPart, part = pcall(function()
				return (Instance :: any).new("Part")
			end)
			if not okPart or not part then
				fail("could not create puddle sheet " .. index)
				continue
			end
			pcall(function()
				part.Name = "PuddleSheet_" .. index
				part:SetAttribute("LookDevSeasonR8", id)
				part:SetAttribute("Kind", "puddle_sheet")
				part.Material = (Enum :: any).Material[Data.PUDDLE_MATERIAL]
				part.Color = (Color3 :: any).fromRGB(tint.r, tint.g, tint.b)
				part.Transparency = Data.PUDDLE_TRANSPARENCY
				part.Anchored = true
				part.CanCollide = false
				part.Size = (Vector3 :: any).new(sheet.sx, 0.05, sheet.sz)
				part.CFrame = (CFrame :: any).new(sheet.x, roadY + 0.05, sheet.z)
				part.Parent = folder
			end)
		end
	end

	local function apply(plan: any)
		if applied then
			return
		end
		for index = #savedOrder, 1, -1 do
			savedOrder[index] = nil
		end
		savedFolder = nil
		clearPuddles()
		failures = 0
		state.tinted = 0
		local activeKey = resolveKey(plan)
		local values = activeKey and Data.valuesFor(activeKey)
		if not values then
			fail("unknown season key " .. tostring(plan))
			publishFailures()
			return
		end

		for _, prop in ipairs(Data.properties.Lighting) do
			if saveProp(Lighting, prop, "Lighting." .. prop) then
				local target, why = targetValue("Lighting", prop, values.Lighting[prop])
				if target == nil then
					fail("bad Lighting." .. prop .. ": " .. tostring(why))
				else
					setProp(Lighting, prop, "Lighting." .. prop, target)
				end
			end
		end

		local atmosphere = findAtmosphere()
		if atmosphere then
			for _, prop in ipairs(Data.properties.Atmosphere) do
				if saveProp(atmosphere, prop, "Atmosphere." .. prop) then
					local target, why = targetValue("Atmosphere", prop, values.Atmosphere[prop])
					if target == nil then
						fail("bad Atmosphere." .. prop .. ": " .. tostring(why))
					else
						setProp(atmosphere, prop, "Atmosphere." .. prop, target)
					end
				end
			end
		end

		local clouds = findClouds()
		if clouds then
			local prop = Data.properties.Clouds[1]
			if saveProp(clouds, prop, "Clouds." .. prop) then
				setProp(clouds, prop, "Clouds." .. prop, values.Clouds[prop])
			end
		end

		local tints = Data.tintsFor(activeKey) or {}
		for _, selector in ipairs(Data.TINT_SELECTORS) do
			local tint = tints[selector.key]
			if tint then
				for index, part in ipairs(matchingParts(selector)) do
					local keyName = "Decor." .. selector.key .. "." .. index
					if saveProp(part, "Color", keyName) then
						local target, why = targetValue("Decor", "Color", tint)
						if target == nil then
							fail("bad decor tint " .. keyName .. ": " .. tostring(why))
						else
							setProp(part, "Color", keyName, target)
							state.tinted += 1
						end
					end
				end
			end
		end

		if Data.puddlesFor(activeKey) > 0 then
			stagePuddles(tints.puddle)
		end

		state.activeKey = activeKey
		state.saved = #savedOrder
		state.applied = true
		applied = true
		publishFailures()
	end

	local function restore()
		if not applied and #savedOrder == 0 and not activeFolder and not savedFolder then
			return
		end
		applied = false
		state.applied = false
		for index = #savedOrder, 1, -1 do
			local entry = savedOrder[index]
			local ok, err = pcall(function()
				entry.effect[entry.prop] = entry.value
			end)
			if not ok then
				fail("could not restore " .. entry.key .. ": " .. tostring(err))
			end
			savedOrder[index] = nil
		end
		clearPuddles()
		if savedFolder then
			pcall(function()
				savedFolder.Parent = Workspace
			end)
			savedFolder = nil
		end
		state.activeKey = nil
		state.tinted = 0
		state.saved = 0
		publishFailures()
	end

	return { apply = apply, restore = restore, state = state }
end

for _, key in ipairs(Data.order) do
	local applier = make(key)
	LookDevSeasonR8.appliers[key] = applier
	LookDev.register(Data.idPrefix .. key, applier)
end

-- Diagnostics for the harness and the Studio command bar.
function LookDevSeasonR8.appliedKey(): string?
	for _, key in ipairs(Data.order) do
		local state = LookDevSeasonR8.appliers[key].state
		if state.applied then
			return state.activeKey
		end
	end
	return nil
end

function LookDevSeasonR8.isApplied(): boolean
	return LookDevSeasonR8.appliedKey() ~= nil
end

function LookDevSeasonR8.savedCount(): number
	local total = 0
	for _, key in ipairs(Data.order) do
		total += LookDevSeasonR8.appliers[key].state.saved
	end
	return total
end

function LookDevSeasonR8.tintedParts(): number
	local total = 0
	for _, key in ipairs(Data.order) do
		total += LookDevSeasonR8.appliers[key].state.tinted
	end
	return total
end

return LookDevSeasonR8
