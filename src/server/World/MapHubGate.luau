-- MapHubGate: hide the Roblox-built Greybox hubs once the place carries their 3D models.
--
-- Map layout v1 (docs/v2/visual/art/MAP_LAYOUT_V1.md) places the hub 3D models in
-- Workspace.JuraganMap.Hubs, each with the attribute MapHub = "<key>". Greybox still builds its
-- own Pasar, Pak RT, Gelap, Polisi, Ronda and Warung in Play, because the prompts and NPC spots
-- live on those buildings until the logic transfer moves them. Until then this gate makes the old
-- buildings invisible and non-colliding so only the 3D model shows. Nothing is destroyed, the
-- ProximityPrompt parts keep working, and NpcSpawn models are left alone.
--
-- Without a JuraganMap folder (fresh place, Lune, review place) the gate does nothing.

local MapHubGate = {}

-- Hub key (the MapHub attribute) -> the Greybox model name in workspace.World.
MapHubGate.GREYBOX_HUBS = {
	pasar = "Pasar",
	gelap = "TengkulakGelap",
	warung = "Warung",
	polisi = "PosPolisi",
	pakrt = "RumahPakRT",
	ronda = "PosRonda",
}

-- Greybox children that duplicate what JuraganMap now authors: the old road strips and the
-- dressing Decor/Details hung on the old hub walls (lanterns, spilled goods, signs).
MapHubGate.SHARED_PREFIXES = {
	"RingRoad",
	"RoadEast",
	"RoadWest",
	"RoadNorth",
	"RoadSouth",
	"RoadToBalai",
	"RoadToBridge",
	"RoadEdge",
	"Decor",
	"Details",
}

-- Pure: which workspace.World child names to hide, given the hub keys that have a 3D model.
function MapHubGate.plan(hubKeys: { [string]: boolean }, childNames: { string }): { string }
	local hide = {}
	local any = false
	for key, present in hubKeys do
		if present and MapHubGate.GREYBOX_HUBS[key] then
			any = true
		end
	end
	if not any then
		return hide
	end
	local wanted = {}
	for key, name in MapHubGate.GREYBOX_HUBS do
		if hubKeys[key] then
			wanted[name] = true
		end
	end
	for _, name in childNames do
		if wanted[name] then
			table.insert(hide, name)
		else
			for _, prefix in MapHubGate.SHARED_PREFIXES do
				if string.sub(name, 1, #prefix) == prefix then
					table.insert(hide, name)
					break
				end
			end
		end
	end
	return hide
end

local function hideTree(root: Instance, CollectionService)
	local function isNpc(inst: Instance): boolean
		local model = inst:FindFirstAncestorWhichIsA("Model")
		while model do
			if CollectionService:HasTag(model, "NpcSpawn") then
				return true
			end
			model = model.Parent and model.Parent:FindFirstAncestorWhichIsA("Model")
		end
		return false
	end
	local list = root:GetDescendants()
	table.insert(list, root)
	for _, d in list do
		if isNpc(d) then
			continue
		end
		if d:IsA("BasePart") then
			d:SetAttribute("MapHubGateHidden", true)
			d.Transparency = 1
			d.CanCollide = false
			d.CastShadow = false
		elseif d:IsA("Decal") or d:IsA("Texture") then
			d.Transparency = 1
		elseif
			d:IsA("SurfaceGui")
			or d:IsA("BillboardGui")
			or d:IsA("Light")
			or d:IsA("ParticleEmitter")
			or d:IsA("Highlight")
			or d:IsA("Beam")
		then
			(d :: any).Enabled = false
		end
	end
end

-- Roblox side: read the hub keys from JuraganMap.Hubs and hide the matching Greybox content.
function MapHubGate.apply(world: Instance?): { string }
	if not world or typeof(workspace) ~= "Instance" then
		return {}
	end
	local root = workspace:FindFirstChild("JuraganMap")
	local hubs = root and root:FindFirstChild("Hubs")
	if not hubs or not world then
		return {}
	end
	local keys = {}
	for _, model in hubs:GetChildren() do
		local key = model:GetAttribute("MapHub")
		if type(key) == "string" then
			keys[key] = true
		end
	end
	local names = {}
	for _, child in world:GetChildren() do
		table.insert(names, child.Name)
	end
	local hidden = MapHubGate.plan(keys, names)
	if #hidden == 0 then
		return hidden
	end
	local CollectionService = game:GetService("CollectionService")
	local set = {}
	for _, name in hidden do
		set[name] = true
	end
	for _, child in world:GetChildren() do
		if set[child.Name] then
			hideTree(child, CollectionService)
		end
	end
	return hidden
end

return MapHubGate
