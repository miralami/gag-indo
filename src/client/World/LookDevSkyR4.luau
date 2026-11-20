-- LookDevSkyR4: three client appliers for the OFF-BY-DEFAULT round-4 sky options
-- sky_r4_a / sky_r4_b / sky_r4_c (WORK_QUEUE item 30). Each reads its six real
-- Roblox Sky face properties, the shared Atmosphere grade and the ridge recipe
-- from Shared.SkyMapR4. No asset ID literal lives here. The previous Sky child,
-- every touched Atmosphere value and all created Instances are restored/destroyed
-- on disable. Every engine call is pcall'd; failures warn, never throw.
-- No visual verdict is claimed here. The central LookDev registry gains the three
-- ids in the integrator pass; registration here is inert until then.

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local LookDev = require(Shared.LookDev)
local SkyMapR4 = require(Shared.SkyMapR4)
local Visuals = require(Shared.Config.Visuals)

local LookDevSkyR4 = {}

type Applier = { apply: (any) -> (), restore: () -> () }

local function make(label: string, key: string): Applier
	local created: { Instance } = {}
	local originals: { { target: any, prop: string, value: any } } = {}
	local savedKeys: { [string]: boolean } = {}
	local originalSky: Instance? = nil
	local originalSkyParent: Instance? = nil
	local applied = false

	local function attempt(action: string, fn: () -> ()): boolean
		local ok, err = pcall(fn)
		if not ok then
			warn(label .. ": " .. action .. " failed: " .. tostring(err))
		end
		return ok
	end

	local function read(action: string, fn: () -> any): any
		local ok, value = pcall(fn)
		if not ok then
			warn(label .. ": " .. action .. " failed: " .. tostring(value))
			return nil
		end
		return value
	end

	local function saveProp(target: any, prop: string)
		local saveKey = tostring(target) .. ":" .. prop
		if savedKeys[saveKey] then
			return
		end
		local ok, value = pcall(function()
			return target[prop]
		end)
		if ok then
			savedKeys[saveKey] = true
			table.insert(originals, { target = target, prop = prop, value = value })
		end
	end

	-- Plain {r,g,b} recipe arrays become engine colours at apply time, never at load.
	local function resolve(value: any): any
		if type(value) == "table" and #value == 3 then
			local ok, color = pcall(function()
				return Color3.fromRGB(value[1], value[2], value[3])
			end)
			if ok and color then
				return color
			end
		end
		return value
	end

	local function colorFor(token: string): any
		local hex = Visuals.palette[token] or Visuals.palette.tinta
		local ok, color = pcall(function()
			return Color3.fromHex(hex)
		end)
		return if ok then color else nil
	end

	local function shapedValue(className: string, name: string): any
		return read("resolve " .. name, function()
			return ((Enum :: any)[className])[name]
		end)
	end

	local function buildRidge()
		local folder = read("create ridge folder", function()
			return Instance.new("Folder")
		end)
		if not folder then
			return
		end
		table.insert(created, folder)
		attempt("name ridge folder", function()
			folder.Name = "SkyR4Ridge_" .. key
		end)
		attempt("parent ridge folder", function()
			folder.Parent = Workspace
		end)

		for _, wedge in ipairs(SkyMapR4.ridgeAt()) do
			local part = read("create ridge part", function()
				return Instance.new("Part")
			end)
			if not part then
				continue
			end
			table.insert(created, part)
			attempt("name ridge part", function()
				part.Name = "SkyR4_" .. key .. "_" .. wedge.name
			end)
			local shape = shapedValue("PartType", wedge.shape)
			if shape then
				attempt("set ridge Shape", function()
					part.Shape = shape
				end)
			end
			local material = shapedValue("Material", "Plastic")
			if material then
				attempt("set ridge Material", function()
					part.Material = material
				end)
			end
			attempt("set ridge Position", function()
				part.Position = Vector3.new(wedge.position[1], wedge.position[2], wedge.position[3])
			end)
			attempt("set ridge Size", function()
				part.Size = Vector3.new(wedge.size[1], wedge.size[2], wedge.size[3])
			end)
			attempt("set ridge Orientation", function()
				part.Orientation = Vector3.new(0, wedge.yaw, 0)
			end)
			local color = colorFor(wedge.color)
			if color then
				attempt("set ridge Color", function()
					part.Color = color
				end)
			end
			attempt("set ridge CastShadow", function()
				part.CastShadow = false
			end)
			attempt("set ridge Anchored", function()
				part.Anchored = true
			end)
			attempt("set ridge CanCollide", function()
				part.CanCollide = false
			end)
			attempt("parent ridge part", function()
				part.Parent = folder
			end)
		end
	end

	local function apply(_plan: any)
		if applied then
			return
		end
		created = {}
		originals = {}
		savedKeys = {}
		originalSky = nil
		originalSkyParent = nil

		-- Hide (do not destroy) the shipping Sky for the duration of the candidate.
		local previousSky = read("find Sky", function()
			return Lighting:FindFirstChildOfClass("Sky")
		end)
		if previousSky then
			originalSky = previousSky
			originalSkyParent = read("read Sky parent", function()
				return previousSky.Parent
			end) or Lighting
			attempt("hide original Sky", function()
				previousSky.Parent = nil
			end)
		end

		local set = SkyMapR4.sets[key]
		local sky = read("create Sky", function()
			return Instance.new("Sky")
		end)
		if sky then
			table.insert(created, sky)
			attempt("name Sky", function()
				sky.Name = "SkyR4_" .. key
			end)
			for _, prop in ipairs(SkyMapR4.faceKeys) do
				local id = set.ids[prop]
				attempt("set Sky." .. prop, function()
					sky[prop] = "rbxassetid://" .. tostring(id)
				end)
			end
			attempt("parent Sky", function()
				sky.Parent = Lighting
			end)
		end

		local atmosphere = read("find Atmosphere", function()
			return Lighting:FindFirstChildOfClass("Atmosphere")
		end)
		if not atmosphere then
			atmosphere = read("create Atmosphere", function()
				return Instance.new("Atmosphere")
			end)
			if atmosphere then
				table.insert(created, atmosphere)
				attempt("name Atmosphere", function()
					atmosphere.Name = "SkyR4Atmosphere_" .. key
				end)
				attempt("parent Atmosphere", function()
					atmosphere.Parent = Lighting
				end)
			end
		end
		if atmosphere then
			local values = SkyMapR4.atmosphere
			for _, prop in ipairs({ "Density", "Color", "Decay", "Offset", "Glare", "Haze" }) do
				saveProp(atmosphere, prop)
				attempt("set Atmosphere." .. prop, function()
					atmosphere[prop] = resolve(values[prop])
				end)
			end
		end

		buildRidge()
		applied = true
	end

	local function restore()
		if not applied then
			return
		end
		applied = false

		for _, entry in ipairs(originals) do
			attempt("restore " .. entry.prop, function()
				entry.target[entry.prop] = entry.value
			end)
		end
		table.clear(originals)
		table.clear(savedKeys)

		if originalSky then
			attempt("restore original Sky", function()
				originalSky.Parent = originalSkyParent or Lighting
			end)
		end
		for _, instance in ipairs(created) do
			attempt("destroy created instance", function()
				if instance.Parent then
					instance:Destroy()
				end
			end)
		end
		table.clear(created)
		originalSky = nil
		originalSkyParent = nil
	end

	return { apply = apply, restore = restore }
end

LookDevSkyR4.appliers = {
	a = make("sky_r4_a", "a"),
	b = make("sky_r4_b", "b"),
	c = make("sky_r4_c", "c"),
}

LookDev.register("sky_r4_a", LookDevSkyR4.appliers.a)
LookDev.register("sky_r4_b", LookDevSkyR4.appliers.b)
LookDev.register("sky_r4_c", LookDevSkyR4.appliers.c)

return LookDevSkyR4
