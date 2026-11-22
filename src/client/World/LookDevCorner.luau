-- LookDevCorner: client applier for the OFF-BY-DEFAULT "corner" look-dev candidate (WORK_QUEUE
-- round 3 item 2). Builds a standalone 60x60-stud corner (warung, curved road bend, sawah edge)
-- from the pure-data recipe in src/shared/LookDevCorner.luau, in a Folder under Workspace, and
-- shows it at golden hour by setting Lighting.ClockTime while enabled. Everything is destroyed
-- and the original ClockTime restored on disable. No asset IDs, no place save, no world outlines.

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local LookDev = require(Shared.LookDev)
local Corner = require(Shared.LookDevCorner)
local Visuals = require(Shared.Config.Visuals)

local LookDevCorner = {}

local CONTAINER = "LookDevCorner"
local created: { Instance } = {}
local applied = false
local savedClock: number? = nil

local SHAPE_NAMES = { Block = "Block", Cylinder = "Cylinder", Sphere = "Ball", Wedge = "Wedge" }

local function shapeOf(name: string): any
	local ok, shape = pcall(function()
		return ((Enum :: any).PartType)[SHAPE_NAMES[name] or "Block"]
	end)
	return if ok then shape else nil
end

-- Built-in Enum.Material names only; pcall because the restricted Studio MCP VM cannot resolve
-- Enums. A failed lookup leaves the Part on its safe default material.
local function materialOf(name: string): any
	local ok, material = pcall(function()
		return ((Enum :: any).Material)[name]
	end)
	return if ok then material else nil
end

local function vec(t: { number }): Vector3
	return Vector3.new(t[1], t[2], t[3])
end

local function colorFor(token: string): Color3
	return Color3.fromHex(Visuals.palette[token] or Visuals.palette.tinta)
end

local function apply(_plan: any)
	if applied then
		return
	end
	created = {}
	local container = Workspace:FindFirstChild(CONTAINER)
	if container then
		container:Destroy()
	end
	container = Instance.new("Folder")
	container.Name = CONTAINER
	container.Parent = Workspace
	table.insert(created, container)

	for _, detail in Corner.parts do
		local part = Instance.new("Part")
		part.Name = "LookDevCorner_" .. detail.group .. "_" .. detail.name
		local shape = shapeOf(detail.shape)
		if shape then
			part.Shape = shape
		end
		local material = materialOf(detail.material)
		if material then
			part.Material = material
		end
		part.Size = vec(detail.size)
		part.CFrame = CFrame.new(vec(detail.position))
		part.Color = colorFor(detail.color)
		part.CanCollide = false
		part.Anchored = true
		part.Parent = container
		table.insert(created, part)
	end

	savedClock = Lighting.ClockTime
	Lighting.ClockTime = Corner.goldenHourClock
	applied = true
end

local function restore()
	if not applied then
		return
	end
	for _, inst in created do
		if inst.Parent then
			pcall(function()
				inst:Destroy()
			end)
		end
	end
	created = {}
	if savedClock ~= nil then
		local previous = savedClock
		pcall(function()
			Lighting.ClockTime = previous
		end)
		savedClock = nil
	end
	applied = false
end

LookDev.register("corner", { apply = apply, restore = restore })

LookDevCorner.apply = apply
LookDevCorner.restore = restore

return LookDevCorner
