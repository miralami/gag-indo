-- LookDevTerrainR6: client appliers for the OFF-BY-DEFAULT "terrain_r6_a/b"
-- candidates (WORK_QUEUE section J item 46). One make() factory, two palettes.
-- Terrain keeps its built-in material and gets only a tuned SetMaterialColor;
-- CC0 maps are installed as base-material overrides for parts/meshes only.
-- Every engine call is pcall-guarded, every prior colour/override string is
-- restored exactly and only created variants are destroyed. No Part is created,
-- no asset ID literal appears here and no visual verdict is claimed.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local LookDev = require(Shared.LookDev)
local TerrainMapR6 = require(Shared.TerrainMapR6)

local okService, MaterialService = pcall(function()
	return game:GetService("MaterialService")
end)
if not okService then
	MaterialService = nil
end

type Applier = { apply: (any) -> (), restore: () -> () }

local function resolveBase(name: string): any?
	if not LookDev.isBuiltinMaterial(name) then
		warn("terrain_r6: base material not in the built-in allowlist: " .. tostring(name))
		return nil
	end
	local ok, base = pcall(function()
		return Enum.Material[name]
	end)
	if not ok or base == nil then
		warn("terrain_r6: Enum.Material has no " .. tostring(name))
		return nil
	end
	return base
end

local function findTerrain(): any?
	local ok, workspace = pcall(function()
		return game:GetService("Workspace")
	end)
	if not ok or not workspace then
		return nil
	end
	local okFind, terrain = pcall(function()
		return workspace:FindFirstChildOfClass("Terrain")
	end)
	return if okFind then terrain else nil
end

local function make(key: string): Applier
	local previousColors: { [string]: any } = {}
	local previousOverrides: { [string]: string } = {}
	local createdVariants: { any } = {}
	local applied = false

	local function applyTerrainColors()
		local palette = TerrainMapR6.paletteFor(key)
		if not palette then
			return
		end
		local terrain = findTerrain()
		if
			not terrain
			or type(terrain.GetMaterialColor) ~= "function"
			or type(terrain.SetMaterialColor) ~= "function"
		then
			return
		end
		for _, baseName in ipairs(TerrainMapR6.terrainMaterials) do
			if baseName == "Water" then
				continue
			end
			local base = resolveBase(baseName)
			local rgb = palette[baseName]
			if not base or type(rgb) ~= "table" or #rgb ~= 3 then
				continue
			end
			local okRead, current = pcall(function()
				return terrain:GetMaterialColor(base)
			end)
			if not okRead then
				warn("terrain_r6: could not read Terrain colour for " .. baseName .. ": " .. tostring(current))
				continue
			end
			local okSet, err = pcall(function()
				terrain:SetMaterialColor(base, Color3.fromRGB(rgb[1], rgb[2], rgb[3]))
			end)
			if okSet then
				previousColors[baseName] = current
			else
				warn("terrain_r6: could not set Terrain colour for " .. baseName .. ": " .. tostring(err))
			end
		end
	end

	local function applyPartOverrides()
		if not MaterialService then
			return
		end
		for _, baseName in ipairs(TerrainMapR6.partOrder) do
			-- Belt and braces: Terrain materials must never get a CC0 override.
			if TerrainMapR6.isTerrainMaterial(baseName) then
				continue
			end
			local base = resolveBase(baseName)
			local variantName = TerrainMapR6.variantNameFor(baseName)
			local studsPerTile = TerrainMapR6.studsFor(baseName)
			local color, normal, rough = TerrainMapR6.mapsFor(baseName)
			if not base or not variantName or not studsPerTile or not color or not normal or not rough then
				warn("terrain_r6: missing map data for " .. baseName)
				continue
			end
			local okBuild, variant = pcall(function()
				local mv = Instance.new("MaterialVariant")
				mv.Name = variantName
				mv.BaseMaterial = base
				mv.ColorMap = color
				mv.NormalMap = normal
				mv.RoughnessMap = rough
				mv.StudsPerTile = studsPerTile
				mv.Parent = MaterialService
				return mv
			end)
			if not okBuild or not variant then
				warn("terrain_r6: could not build " .. variantName .. ": " .. tostring(variant))
				continue
			end
			table.insert(createdVariants, variant)
			local okRead, previous = pcall(function()
				return MaterialService:GetBaseMaterialOverride(base)
			end)
			if not okRead then
				warn("terrain_r6: could not read override for " .. baseName .. ": " .. tostring(previous))
				continue
			end
			previousOverrides[baseName] = previous or ""
			local okSet, err = pcall(function()
				MaterialService:SetBaseMaterialOverride(base, variantName)
			end)
			if not okSet then
				warn("terrain_r6: override failed for " .. baseName .. ": " .. tostring(err))
			end
		end
	end

	local function apply(_plan: any)
		if applied then
			return
		end
		previousColors = {}
		previousOverrides = {}
		createdVariants = {}
		applyTerrainColors()
		applyPartOverrides()
		applied = true
	end

	local function restore()
		if not applied then
			return
		end
		applied = false

		local terrain = findTerrain()
		if terrain and type(terrain.SetMaterialColor) == "function" then
			for baseName, previous in pairs(previousColors) do
				local base = resolveBase(baseName)
				if base then
					local ok, err = pcall(function()
						terrain:SetMaterialColor(base, previous)
					end)
					if not ok then
						warn("terrain_r6: could not restore Terrain colour for " .. baseName .. ": " .. tostring(err))
					end
				end
			end
		end
		previousColors = {}

		if MaterialService then
			for baseName, previous in pairs(previousOverrides) do
				local base = resolveBase(baseName)
				if base then
					local ok, err = pcall(function()
						MaterialService:SetBaseMaterialOverride(base, previous)
					end)
					if not ok then
						warn("terrain_r6: could not restore override for " .. baseName .. ": " .. tostring(err))
					end
				end
			end
		end
		previousOverrides = {}

		for _, variant in ipairs(createdVariants) do
			pcall(function()
				variant:Destroy()
			end)
		end
		createdVariants = {}
	end

	return { apply = apply, restore = restore }
end

local LookDevTerrainR6 = {}

LookDevTerrainR6.appliers = {
	a = make("a"),
	b = make("b"),
}

for _, key in ipairs(TerrainMapR6.order) do
	LookDev.register(TerrainMapR6.idPrefix .. key, LookDevTerrainR6.appliers[key])
end

return LookDevTerrainR6
