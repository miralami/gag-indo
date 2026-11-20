-- LookDevSkyR3: client applier for the OFF-BY-DEFAULT "sky_r3" candidate (WORK_QUEUE
-- round 3 item 24, bug fix item 28). Builds the six-face CC0_hdr sky, the proposed Atmosphere
-- haze and a low ridge-silhouette ring from the pure recipe in Shared.SkyMapR3. The generic loop
-- below writes the REAL Sky properties SkyboxBk/Dn/Ft/Lf/Rt/Up from SkyMapR3.ids, and resolve()
-- turns the plain {r,g,b} arrays (including Atmosphere.Decay) into Color3 at apply time.
-- No asset ID lives here: ids and recipe data come from Shared.SkyMapR3, colours from Visuals.palette.
-- The previous Sky child, every touched Atmosphere value and all created Instances are
-- restored/destroyed on disable. Every Roblox call is pcall'd; failures warn, never throw.
-- No visual verdict is claimed here.

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local LookDev = require(Shared.LookDev)
local SkyMapR3 = require(Shared.SkyMapR3)
local Visuals = require(Shared.Config.Visuals)

local LookDevSkyR3 = {}

local FOLDER = "SkyR3Ridge"
local created: { Instance } = {}
local originals: { { target: any, prop: string, value: any } } = {}
local savedKeys: { [string]: boolean } = {}
local originalSky: Instance? = nil
local originalSkyParent: Instance? = nil
local applied = false

local function attempt(label: string, fn: () -> ()): boolean
	local ok, err = pcall(fn)
	if not ok then
		warn("sky_r3: " .. label .. " failed: " .. tostring(err))
	end
	return ok
end

local function read(label: string, fn: () -> any): any
	local ok, value = pcall(fn)
	if not ok then
		warn("sky_r3: " .. label .. " failed: " .. tostring(value))
		return nil
	end
	return value
end

local function saveProp(target: any, prop: string)
	local key = tostring(target) .. ":" .. prop
	if savedKeys[key] then
		return
	end
	local ok, value = pcall(function()
		return target[prop]
	end)
	if ok then
		savedKeys[key] = true
		table.insert(originals, { target = target, prop = prop, value = value })
	end
end

-- Plain {r,g,b} recipe arrays become Color3 at apply time, never at module load.
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
		folder.Name = FOLDER
	end)
	attempt("parent ridge folder", function()
		folder.Parent = Workspace
	end)

	for _, wedge in ipairs(SkyMapR3.ridge) do
		local part = read("create ridge part", function()
			return Instance.new("Part")
		end)
		if not part then
			continue
		end
		table.insert(created, part)
		attempt("name ridge part", function()
			part.Name = "SkyR3_" .. wedge.name
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

	local sky = read("create Sky", function()
		return Instance.new("Sky")
	end)
	if sky then
		table.insert(created, sky)
		attempt("name Sky", function()
			sky.Name = "SkyR3"
		end)
		for prop, id in SkyMapR3.ids do
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
				atmosphere.Name = "SkyR3Atmosphere"
			end)
			attempt("parent Atmosphere", function()
				atmosphere.Parent = Lighting
			end)
		end
	end
	if atmosphere then
		for prop, value in SkyMapR3.atmosphere do
			saveProp(atmosphere, prop)
			attempt("set Atmosphere." .. prop, function()
				atmosphere[prop] = resolve(value)
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

LookDev.register("sky_r3", { apply = apply, restore = restore })

LookDevSkyR3.apply = apply
LookDevSkyR3.restore = restore

return LookDevSkyR3
