-- LookDevNpcs: client applier for the OFF-BY-DEFAULT "npcs" look-dev candidate (WORK_QUEUE item 6).
-- It adds procedural caricature detail meshes (peci, moustache, heavy brow, fictional badge,
-- satchel, …) to the live box NPCs from Config/NpcArchetypes and npcs.md. Every detail is a
-- primitive part parented to an existing NPC part, so it follows Model:PivotTo walking for free.
-- No asset IDs live here — geometry is procedural and described in NpcModelCandidates.luau.
-- Everything is removed on disable; the shipping NPCs and their API are untouched.

local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local LookDev = require(Shared.LookDev)
local NpcModelCandidates = require(Shared.NpcModelCandidates)
local Visuals = require(Shared.Config.Visuals)

local LookDevNpcs = {}

local CONTAINER = "LookDevNpcDetails"
local created: { Instance } = {}
local decorated: { Instance } = {}
local addedConn: RBXScriptConnection? = nil
local descendantConn: RBXScriptConnection? = nil
local applied = false

-- Indexed dynamically so selene's roblox std (which omits PartShape fields) stays quiet; the
-- recipe stores shape NAMES, and Roblox resolves Enum.PartShape[name] at runtime. Resolution is
-- best-effort: the restricted Studio MCP execute_luau VM has no Enum.PartShape member (it throws
-- "PartShape is not a valid member of Enum"), so a nil result simply leaves the Part at its
-- default Block shape. The real LocalScript VM resolves the full set of shapes.
local SHAPE_NAMES = {
	Block = "Block",
	Cylinder = "Cylinder",
	Sphere = "Ball",
	Wedge = "Wedge",
}

local function shapeOf(name: string): any
	local ok, shape = pcall(function()
		return ((Enum :: any).PartShape)[SHAPE_NAMES[name] or "Block"]
	end)
	return if ok then shape else nil
end

local function vec(t: { number }): Vector3
	return Vector3.new(t[1], t[2], t[3])
end

local function decorate(model: Instance)
	if table.find(decorated, model) then
		return
	end
	local npcId: string? = nil
	if model:IsA("Model") then
		local attr = model:GetAttribute("Npc")
		if type(attr) == "string" then
			npcId = attr
		end
	end
	if not npcId and model.Name == "DebtCollector" then
		npcId = "debt_collector"
	end
	local recipe = NpcModelCandidates.recipeFor(npcId)
	if not recipe then
		return
	end
	table.insert(decorated, model)

	local container = model:FindFirstChild(CONTAINER)
	if not container then
		container = Instance.new("Folder")
		container.Name = CONTAINER
		container.Parent = model
	end
	table.insert(created, container)

	for _, detail in recipe do
		local anchor = model:FindFirstChild(detail.attachTo)
		if not anchor or not anchor:IsA("BasePart") then
			continue
		end
		local part = Instance.new("Part")
		part.Name = detail.name
		local shape = shapeOf(detail.shape)
		if shape then
			part.Shape = shape
		end
		part.Size = vec(detail.size)
		part.CFrame = anchor.CFrame * CFrame.new(vec(detail.offset))
		local hex = NpcModelCandidates.palette[detail.color] or Visuals.palette.tinta
		part.Color = Color3.fromHex(hex)
		part.Material = Enum.Material.SmoothPlastic
		part.CanCollide = false
		part.CanQuery = false
		part.CastShadow = false
		part.Parent = container
		table.insert(created, part)
	end
end

local function scan()
	for _, model in CollectionService:GetTagged("NpcSpawn") do
		decorate(model)
	end
	for _, obj in Workspace:GetDescendants() do
		if obj.Name == "DebtCollector" then
			decorate(obj)
		end
	end
end

local function apply(_plan: any)
	if applied then
		return
	end
	created = {}
	decorated = {}
	scan()
	addedConn = CollectionService:GetInstanceAddedSignal("NpcSpawn"):Connect(function(model)
		decorate(model)
	end)
	descendantConn = Workspace.DescendantAdded:Connect(function(obj)
		if obj.Name == "DebtCollector" then
			decorate(obj)
		end
	end)
	applied = true
end

local function restore()
	if not applied then
		return
	end
	if addedConn then
		addedConn:Disconnect()
		addedConn = nil
	end
	if descendantConn then
		descendantConn:Disconnect()
		descendantConn = nil
	end
	for _, inst in created do
		if inst.Parent then
			pcall(function()
				inst:Destroy()
			end)
		end
	end
	created = {}
	decorated = {}
	applied = false
end

LookDev.register("npcs", { apply = apply, restore = restore })

LookDevNpcs.apply = apply
LookDevNpcs.restore = restore
LookDevNpcs.decorate = decorate

return LookDevNpcs
