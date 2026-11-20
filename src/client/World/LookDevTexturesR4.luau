-- LookDevTexturesR4: client applier for the OFF-BY-DEFAULT "textures_r4" candidate
-- (WORK_QUEUE item 29). Real CC0 PBR IDs live only in Shared.TextureMapR4. This module
-- builds MaterialVariants with BaseMaterial set and installs them as global base-material
-- overrides, so every matching Part AND Terrain changes without any name matching.
-- No asset ID literal appears here. On disable every previous override string is
-- restored exactly and the temporary variants are destroyed. No visual verdict.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local LookDev = require(Shared.LookDev)
local TextureMapR4 = require(Shared.TextureMapR4)

local LookDevTexturesR4 = {}

local okService, MaterialService = pcall(function()
	return game:GetService("MaterialService")
end)
if not okService then
	MaterialService = nil
	warn("textures_r4: MaterialService unavailable; candidate will not apply")
end

type Built = { name: string, baseName: string, base: any }

local previousOverrides: { [string]: string } = {}
local createdVariants: { any } = {}
local applied = false

local function resolveBase(name: string): any?
	if not LookDev.isBuiltinMaterial(name) then
		warn("textures_r4: base material not in the built-in allowlist: " .. tostring(name))
		return nil
	end
	local ok, base = pcall(function()
		return Enum.Material[name]
	end)
	if not ok or base == nil then
		warn("textures_r4: Enum.Material has no " .. tostring(name))
		return nil
	end
	return base
end

local function buildVariants(): { Built }
	local built: { Built } = {}
	for _, variant in TextureMapR4.variants do
		local base = resolveBase(variant.baseMaterial)
		if base then
			local color = TextureMapR4.assetUrl(variant.diff)
			local normal = TextureMapR4.assetUrl(variant.nor)
			local rough = TextureMapR4.assetUrl(variant.rough)
			if color and normal and rough then
				local ok, materialVariant = pcall(function()
					local mv = Instance.new("MaterialVariant")
					mv.Name = variant.name
					mv.BaseMaterial = base
					mv.ColorMap = color
					mv.NormalMap = normal
					mv.RoughnessMap = rough
					mv.StudsPerTile = variant.studsPerTile
					mv.Parent = MaterialService
					return mv
				end)
				if ok and materialVariant then
					table.insert(createdVariants, materialVariant)
					table.insert(built, {
						name = variant.name,
						baseName = variant.baseMaterial,
						base = base,
					})
				else
					warn("textures_r4: could not build " .. variant.name .. ": " .. tostring(materialVariant))
				end
			else
				warn("textures_r4: missing map ID for " .. variant.name)
			end
		end
	end
	return built
end

local function apply(_plan: any)
	if applied then
		return
	end
	if not MaterialService then
		return
	end
	previousOverrides = {}
	createdVariants = {}
	for _, entry in buildVariants() do
		local okRead, previous = pcall(function()
			return MaterialService:GetBaseMaterialOverride(entry.base)
		end)
		if okRead then
			previousOverrides[entry.baseName] = previous or ""
			local okSet, err = pcall(function()
				MaterialService:SetBaseMaterialOverride(entry.base, entry.name)
			end)
			if not okSet then
				warn("textures_r4: override failed for " .. entry.baseName .. ": " .. tostring(err))
			end
		else
			warn("textures_r4: could not read override for " .. entry.baseName .. ": " .. tostring(previous))
		end
	end
	applied = true
end

local function restore()
	if not applied then
		return
	end
	if MaterialService then
		for baseName, previous in previousOverrides do
			local base = resolveBase(baseName)
			if base then
				local ok, err = pcall(function()
					MaterialService:SetBaseMaterialOverride(base, previous)
				end)
				if not ok then
					warn("textures_r4: could not restore override for " .. baseName .. ": " .. tostring(err))
				end
			end
		end
	end
	previousOverrides = {}
	for _, variant in createdVariants do
		pcall(function()
			variant:Destroy()
		end)
	end
	createdVariants = {}
	applied = false
end

LookDev.register("textures_r4", { apply = apply, restore = restore })

LookDevTexturesR4.apply = apply
LookDevTexturesR4.restore = restore

return LookDevTexturesR4
