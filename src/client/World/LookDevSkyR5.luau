-- LookDevSkyR5: client applier for the OFF-BY-DEFAULT "sky_r5" candidate
-- (WORK_QUEUE item 38). Adapts the proven r4 applier mechanics: one real-ID CC0
-- sky set from Shared.SkyMapR5, the shared bright/humid Atmosphere grade, a
-- lowered Terrain Clouds.Cover, the cube top-face seam fix, and NO ridge parts.
-- The previous Sky, every touched Atmosphere value and the exact prior Cover
-- are restored on disable. Every engine call is pcall'd; failures warn, never
-- throw, and missing Sky/Terrain/Clouds are a graceful no-op. No visual claim.

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local LookDev = require(Shared.LookDev)
local SkyMapR5 = require(Shared.SkyMapR5)

local LookDevSkyR5 = {}

local TOP_FACE = "SkyboxUp"

local originals: { { target: any, prop: string, value: any } } = {}
local savedKeys: { [string]: boolean } = {}
local created: { Instance } = {}
local originalSky: Instance? = nil
local originalSkyParent: Instance? = nil
local applied = false

local function attempt(action: string, fn: () -> ()): boolean
	local ok, err = pcall(fn)
	if not ok then
		warn("sky_r5: " .. action .. " failed: " .. tostring(err))
	end
	return ok
end

local function read(action: string, fn: () -> any): any
	local ok, value = pcall(fn)
	if not ok then
		warn("sky_r5: " .. action .. " failed: " .. tostring(value))
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

-- Plain {r,g,b} recipe arrays become an engine colour at apply time, never at load.
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

-- Cube top-face seam fix, carried over from the r4 applier: assign the verified
-- top face through the REAL Sky.SkyboxUp property (not the old r3 image-name
-- property). Applying SkyboxUp as its own step keeps the apex edge aligned with
-- the four side faces and avoids the visible top-face seam.
local function applyCubeTopFaceSeamFix(skyInstance: any, set: any)
	local id = set.ids[TOP_FACE]
	attempt("set Sky.SkyboxUp (top-face seam fix)", function()
		skyInstance[TOP_FACE] = "rbxassetid://" .. tostring(id)
	end)
end

-- Bug fix: lower Terrain Clouds.Cover while active; the exact prior value is
-- saved first and restored by restore(). No Terrain/Clouds => graceful no-op.
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
		clouds.Cover = SkyMapR5.cloudCover
	end)
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

	local set = SkyMapR5.sets[SkyMapR5.primaryKey]
	local sky = read("create Sky", function()
		return Instance.new("Sky")
	end)
	if sky then
		table.insert(created, sky)
		attempt("name Sky", function()
			sky.Name = "SkyR5_" .. SkyMapR5.primaryKey
		end)
		for _, prop in ipairs(SkyMapR5.faceKeys) do
			if prop ~= TOP_FACE then
				local id = set.ids[prop]
				attempt("set Sky." .. prop, function()
					sky[prop] = "rbxassetid://" .. tostring(id)
				end)
			end
		end
		applyCubeTopFaceSeamFix(sky, set)
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
				atmosphere.Name = "SkyR5Atmosphere"
			end)
			attempt("parent Atmosphere", function()
				atmosphere.Parent = Lighting
			end)
		end
	end
	if atmosphere then
		local values = SkyMapR5.atmosphere
		for _, prop in ipairs({ "Density", "Color", "Decay", "Offset", "Glare", "Haze" }) do
			saveProp(atmosphere, prop)
			attempt("set Atmosphere." .. prop, function()
				atmosphere[prop] = resolve(values[prop])
			end)
		end
	end

	applyCloudCover()
	-- No ridge parts: r4's plaza slabs are gone; a horizon ridge is a later level.
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

LookDev.register("sky_r5", { apply = apply, restore = restore })

return LookDevSkyR5
