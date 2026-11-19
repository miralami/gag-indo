-- LookDevTexturesR3: client applier for the OFF-BY-DEFAULT "textures_r3" candidate
-- (WORK_QUEUE round 3 items 20/21). Nine MaterialVariants are built from the real
-- CC0 Poly Haven PBR IDs in Shared.TextureMapR3 and attached to matching MeshParts.
-- No asset ID literals live here. On disable every part's MaterialVariant and
-- Material are restored and the temporary folder is destroyed. No visual verdict.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local LookDev = require(Shared.LookDev)
local TextureMapR3 = require(Shared.TextureMapR3)

local LookDevTexturesR3 = {}

local FOLDER = "JD_R3_MaterialVariants"
local originals: { { part: any, material: any, variant: string } } = {}
local folder: Folder? = nil
local applied = false

local function categoryFor(name: string): string?
	local n = string.lower(name)
	local function has(word: string)
		return string.find(n, word, 1, true) ~= nil
	end
	if has("river") or has("bank") or has("batu") then
		return "river"
	elseif has("pematang") or has("bund") or has("embankment") then
		return "pematang"
	elseif has("field") or has("sawah") or has("paddy") then
		return "field"
	elseif has("road") or has("jalan") or has("path") or has("cross") or has("cobble") then
		return "road"
	elseif has("bamboo") or has("bambu") then
		return "bamboo"
	elseif has("roof") or has("genteng") or has("tiles") or has("eave") then
		return "roof"
	elseif has("seng") or has("metal") or has("zinc") or has("corrugated") then
		return "metal"
	elseif has("floor") or has("ground") or has("plaza") or has("yard") or has("plinth") or has("tanah") then
		return "ground"
	elseif
		has("counter")
		or has("table")
		or has("shelf")
		or has("bench")
		or has("stall")
		or has("deck")
		or has("wall")
		or has("crate")
		or has("gerobak")
		or has("fence")
		or has("post")
		or has("leg")
		or has("divider")
		or has("loft")
		or has("wood")
		or has("kayu")
		or has("papan")
	then
		return "wood"
	end
	return nil
end

-- MaterialVariant only applies to MeshParts. Temporary Parts in the 60x60 corner
-- are left alone unless the corner adapter is also enabled (they remain Parts).
local function targetModels(): { any }
	local list = {}
	local pasar = Workspace:FindFirstChild("Pasar", true)
	if pasar then
		table.insert(list, pasar)
	end
	local corner = Workspace:FindFirstChild("LookDevCorner", true)
	if corner then
		table.insert(list, corner)
	end
	for _, child in Workspace:GetChildren() do
		local prefix = string.sub(child.Name, 1, 5)
		if prefix == "prop_" or string.sub(child.Name, 1, 4) == "kit_" then
			table.insert(list, child)
		end
	end
	return list
end

local function buildVariants(): Folder?
	local existing = ReplicatedStorage:FindFirstChild(FOLDER)
	if existing then
		existing:Destroy()
	end
	local container = Instance.new("Folder")
	container.Name = FOLDER
	container.Parent = ReplicatedStorage
	for _, variant in TextureMapR3.variants do
		if not LookDev.isBuiltinMaterial(variant.baseMaterial) then
			continue
		end
		local okEnum, base = pcall(function()
			return Enum.Material[variant.baseMaterial]
		end)
		if not okEnum or not base then
			continue
		end
		local ok, materialVariant = pcall(function()
			local mv = Instance.new("MaterialVariant")
			mv.Name = variant.name
			mv.BaseMaterial = base
			mv.ColorMap = TextureMapR3.assetUrl(variant.diff)
			mv.NormalMap = TextureMapR3.assetUrl(variant.nor)
			mv.RoughnessMap = TextureMapR3.assetUrl(variant.rough)
			mv.Parent = container
			return mv
		end)
		if not ok then
			warn("textures_r3: could not build MaterialVariant " .. variant.name .. ": " .. tostring(materialVariant))
		end
	end
	return container
end

local function apply(_plan: any)
	if applied then
		return
	end
	originals = {}
	folder = buildVariants()

	for _, model in targetModels() do
		for _, part in model:GetDescendants() do
			if part:IsA("MeshPart") then
				local category = categoryFor(part.Name)
				local slot = category and TextureMapR3.categorySlots[category]
				local variant = slot and TextureMapR3.variants[slot]
				if variant then
					local okRead, oldMaterial = pcall(function()
						return part.Material
					end)
					local okVariant, oldVariant = pcall(function()
						return part.MaterialVariant
					end)
					if okRead and okVariant then
						table.insert(originals, {
							part = part,
							material = oldMaterial,
							variant = oldVariant,
						})
						pcall(function()
							part.MaterialVariant = variant.name
						end)
					end
				end
			end
		end
	end
	applied = true
end

local function restore()
	if not applied then
		return
	end
	for _, entry in originals do
		pcall(function()
			entry.part.Material = entry.material
			entry.part.MaterialVariant = entry.variant
		end)
	end
	originals = {}
	if folder then
		pcall(function()
			folder:Destroy()
		end)
		folder = nil
	end
	applied = false
end

LookDev.register("textures_r3", { apply = apply, restore = restore })

LookDevTexturesR3.apply = apply
LookDevTexturesR3.restore = restore

return LookDevTexturesR3
