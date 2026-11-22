-- LookDevTextures: client applier for the OFF-BY-DEFAULT "textures" look-dev candidate
-- (WORK_QUEUE round 2 item 5). The 7 seamless painted textures are CANDIDATES awaiting a
-- designer yes/no — never shipped on by default.
--
-- On enable this sets Shared.TextureMap.candidateIds into Visuals.textures, then walks the Pasar
-- hub and lets the existing Visuals.applySurface attach a SurfaceAppearance.ColorMap to matching
-- parts. On disable it restores each part's original Colour, Material and SurfaceAppearance and
-- returns every Visuals.textures slot to 0. No asset ID literals live here: they are in TextureMap.
-- The LookDev gate keeps this Studio-only and never persisted.

local Workspace = game:GetService("Workspace")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local LookDev = require(Shared.LookDev)
local TextureMap = require(Shared.TextureMap)
local Visuals = require(Shared.Config.Visuals)

local LookDevTextures = {}

local originals: { { part: any, color: any, material: any, hadSurface: boolean, colorMap: any } } = {}
local applied = false

local function categoryFor(name: string): string?
	local n = string.lower(name)
	local function has(word: string)
		return string.find(n, word, 1, true) ~= nil
	end
	if has("field") or has("sawah") or has("paddy") then
		return "field"
	elseif has("sign") or has("board") or has("paper") or has("karung") then
		return "sign"
	elseif has("seng") or has("metal") or has("zinc") or has("barrel") or has("motor") then
		return "metal"
	elseif has("road") or has("jalan") or has("path") or has("cross") or has("sumur") then
		return "road"
	elseif has("roof") or has("trim") or has("eave") or has("awning") or has("hut") then
		return "roof"
	elseif has("counter") or has("table") or has("shelf") or has("bench") or has("stall")
		or has("deck") or has("wall") or has("crate") or has("gerobak") or has("fence")
		or has("post") or has("leg") or has("divider") or has("loft") then
		return "wood"
	elseif has("floor") or has("ground") or has("plaza") or has("yard") or has("plinth") then
		return "ground"
	end
	return nil
end

-- SurfaceAppearance can ONLY be parented to MeshParts (verified in Studio: parenting to the
-- greybox Pasar Parts throws). The imported v2 prop/kit models are MeshParts, so target those
-- plus any MeshParts under Pasar. The greybox Parts are left untouched — this is a LookDev
-- candidate, not a redesign of the shipping greybox.
local function targetModels(): { any }
	local list = {}
	local pasar = Workspace:FindFirstChild("Pasar", true)
	if pasar then
		table.insert(list, pasar)
	end
	for _, child in Workspace:GetChildren() do
		local prefix = string.sub(child.Name, 1, 5)
		if prefix == "prop_" or string.sub(child.Name, 1, 4) == "kit_" then
			table.insert(list, child)
		end
	end
	return list
end

local function apply(_plan: any)
	if applied then
		return
	end
	originals = {}
	TextureMap.applyCandidates(Visuals, true)

	for _, model in targetModels() do
		for _, part in model:GetDescendants() do
			if part:IsA("MeshPart") then
				local category = categoryFor(part.Name)
				local slot = category and TextureMap.categorySlots[category]
				local fallbackName = slot and TextureMap.fallbackMaterials[slot]
				if slot and fallbackName and LookDev.isBuiltinMaterial(fallbackName) then
					local okColor, color = pcall(function()
						return part.Color
					end)
					local okMaterial, material = pcall(function()
						return part.Material
					end)
					if okColor and okMaterial then
						local existing = part:FindFirstChildOfClass("SurfaceAppearance")
						local hadSurface = existing ~= nil
						local colorMap = nil
						if hadSurface then
							local okMap, map = pcall(function()
								return existing.ColorMap
							end)
							colorMap = if okMap then map else nil
						end
						table.insert(originals, {
							part = part,
							color = color,
							material = material,
							hadSurface = hadSurface,
							colorMap = colorMap,
						})
						pcall(function()
							Visuals.applySurface(part, slot, Enum.Material[fallbackName])
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
			entry.part.Color = entry.color
			entry.part.Material = entry.material
		end)
		local surface = entry.part:FindFirstChildOfClass("SurfaceAppearance")
		if surface then
			if entry.hadSurface then
				if entry.colorMap ~= nil then
					pcall(function()
						surface.ColorMap = entry.colorMap
					end)
				end
			else
				pcall(function()
					surface:Destroy()
				end)
			end
		end
	end
	originals = {}
	TextureMap.applyCandidates(Visuals, false)
	applied = false
end

LookDev.register("textures", { apply = apply, restore = restore })

LookDevTextures.apply = apply
LookDevTextures.restore = restore

return LookDevTextures
