-- LookDevSkyR6: six client appliers for the OFF-BY-DEFAULT round-6 Creator Store
-- sky options sky_r6_a..sky_r6_f (WORK_QUEUE section J item 44). Each reads its
-- six real face IDs, the shared Atmosphere grade, the lowered Terrain Clouds.Cover
-- and the shared effect stack from Shared.SkyMapR6. No asset ID literal lives here:
-- the rbxassetid:// scheme is added at apply time. The previous Sky, every touched
-- property and all created instances are restored/destroyed on disable. Every
-- engine call is pcall'd; failures warn, never throw. No Part is created and no
-- visual verdict is claimed. sky_r5 stays the untouched baseline.

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local LookDev = require(Shared.LookDev)
local SkyMapR6 = require(Shared.SkyMapR6)

type Applier = { apply: (any) -> (), restore: () -> () }

local TOP_FACE = "SkyboxUp"
local SUN_RAY_PROPS = { "Intensity", "Spread", "Enabled" }
local BLOOM_PROPS = { "Intensity", "Threshold", "Size", "Enabled" }
local CC_PROPS = { "Saturation", "Contrast", "TintColor", "Brightness", "Enabled" }

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

	-- Plain {r,g,b} recipe arrays become an engine colour at apply time, never at
	-- load. Most colours are 0-255 (fromRGB); TintColor is 0-1 (new).
	local function resolve(value: any, useNew: boolean?): any
		if type(value) == "table" and #value == 3 then
			local ok, color = pcall(if useNew then Color3.new else Color3.fromRGB, value[1], value[2], value[3])
			if ok and color then
				return color
			end
		end
		return value
	end

	-- Cube top-face seam fix carried over from the r4/r5 appliers: SkyboxUp is
	-- assigned as its own step so the apex edge aligns with the four side faces.
	local function applyCubeTopFaceSeamFix(skyInstance: any, set: any)
		local id = set.ids[TOP_FACE]
		attempt("set Sky.SkyboxUp (top-face seam fix)", function()
			skyInstance[TOP_FACE] = "rbxassetid://" .. tostring(id)
		end)
	end

	local function applyCloudCover()
		local terrain = read("find Terrain", function()
			return Workspace:FindFirstChildOfClass("Terrain")
		end)
		if not terrain then
			return
		end
		local clouds = read("find Terrain Clouds", function()
			return terrain:FindFirstChildOfClass("Clouds")
		end)
		if not clouds then
			return
		end
		saveProp(clouds, "Cover")
		attempt("lower Terrain Clouds.Cover", function()
			clouds.Cover = SkyMapR6.cloudCover
		end)
	end

	-- Reuse an existing Lighting effect of the class if present; otherwise create
	-- one. Every touched property is saved first and restored exactly on disable;
	-- only instances this applier created are ever destroyed.
	local function applyEffect(className: string, name: string, values: any, props: { string }, newProp: string?)
		local effectInstance = read("find " .. className, function()
			return Lighting:FindFirstChildOfClass(className)
		end)
		if not effectInstance then
			effectInstance = read("create " .. className, function()
				return Instance.new(className)
			end)
			if effectInstance then
				table.insert(created, effectInstance)
				attempt("name " .. className, function()
					effectInstance.Name = name
				end)
				attempt("parent " .. className, function()
					effectInstance.Parent = Lighting
				end)
			end
		end
		if not effectInstance then
			return
		end
		for _, prop in ipairs(props) do
			local value = values[prop]
			if value ~= nil then
				saveProp(effectInstance, prop)
				attempt("set " .. className .. "." .. prop, function()
					effectInstance[prop] = resolve(value, prop == newProp)
				end)
			end
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

		local set = SkyMapR6.sets[key]
		local sky = read("create Sky", function()
			return Instance.new("Sky")
		end)
		if sky then
			table.insert(created, sky)
			attempt("name Sky", function()
				sky.Name = "SkyR6_" .. key
			end)
			for _, prop in ipairs(SkyMapR6.faceKeys) do
				if prop ~= TOP_FACE then
					local id = set.ids[prop]
					attempt("set Sky." .. prop, function()
						sky[prop] = "rbxassetid://" .. tostring(id)
					end)
				end
			end
			applyCubeTopFaceSeamFix(sky, set)
			-- The sun stays on. This property lives on Sky, not Lighting.
			attempt("set Sky.CelestialBodiesShown", function()
				sky.CelestialBodiesShown = SkyMapR6.effects.celestialBodiesShown
			end)
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
					atmosphere.Name = "SkyR6Atmosphere_" .. key
				end)
				attempt("parent Atmosphere", function()
					atmosphere.Parent = Lighting
				end)
			end
		end
		if atmosphere then
			local values = SkyMapR6.atmosphere
			for _, prop in ipairs({ "Density", "Haze", "Color", "Decay", "Offset", "Glare" }) do
				saveProp(atmosphere, prop)
				attempt("set Atmosphere." .. prop, function()
					atmosphere[prop] = resolve(values[prop])
				end)
			end
		end

		applyCloudCover()

		local effects = SkyMapR6.effects
		applyEffect("SunRaysEffect", "SkyR6SunRays_" .. key, effects.sunRays, SUN_RAY_PROPS)
		applyEffect("BloomEffect", "SkyR6Bloom_" .. key, effects.bloom, BLOOM_PROPS)
		applyEffect(
			"ColorCorrectionEffect",
			"SkyR6ColorCorrection_" .. key,
			effects.colorCorrection,
			CC_PROPS,
			"TintColor"
		)

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

local LookDevSkyR6 = {}

LookDevSkyR6.appliers = {
	a = make("sky_r6_a", "a"),
	b = make("sky_r6_b", "b"),
	c = make("sky_r6_c", "c"),
	d = make("sky_r6_d", "d"),
	e = make("sky_r6_e", "e"),
	f = make("sky_r6_f", "f"),
}

for _, key in ipairs(SkyMapR6.order) do
	LookDev.register("sky_r6_" .. key, LookDevSkyR6.appliers[key])
end

return LookDevSkyR6
