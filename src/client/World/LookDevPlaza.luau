-- LookDevPlaza: client applier for the OFF-BY-DEFAULT "plaza_lighting" look-dev candidate
-- (WORK_QUEUE item 9, candidate awaiting designer yes).
--
-- It swaps a few plaza part materials for built-in Roblox materials and applies an alternative
-- Lighting grade, remembering every original value so disable() restores the live look exactly.
-- It registers itself with the shared LookDev toggle at boot but does NOTHING until the designer
-- opts in from the Studio command bar. No asset IDs: Enum.Material[name] only.

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local LookDev = require(Shared.LookDev)

local LookDevPlaza = {}

local originalMaterials: { { part: Instance, material: any } } = {}
local originalLighting: { { target: any, prop: string, value: any } } = {}

local function rgb(value): Color3
	return Color3.fromRGB(value[1], value[2], value[3])
end

-- Which candidate material category a part name maps to. Ordered most-specific first so a
-- "RoadFloor" reads as road, not ground. Unknown parts are left untouched.
local function categoryFor(name: string): string?
	local n = string.lower(name)
	local function has(word: string)
		return string.find(n, word, 1, true) ~= nil
	end
	if has("road") or has("jalan") or has("path") or has("cross") then
		return "road"
	elseif has("floor") or has("ground") or has("plaza") or has("yard") then
		return "ground"
	elseif has("counter") or has("table") or has("shelf") or has("bench") or has("stall") or has("deck") then
		return "wood"
	elseif has("roof") or has("trim") or has("eave") or has("awning") then
		return "roof"
	end
	return nil
end

local function plazaModel()
	-- MapSpec.HUBS pasar.model == "Pasar". Search recursively so the fallback and designer worlds
	-- both work without either module having to agree on a tag.
	return Workspace:FindFirstChild("Pasar", true)
end

local function apply(plan: any)
	originalMaterials = {}
	originalLighting = {}

	local model = plazaModel()
	if model then
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				local category = categoryFor(part.Name)
				local materialName = category and plan.materials[category]
				if materialName and LookDev.isBuiltinMaterial(materialName) then
					local material = Enum.Material[materialName]
					if material then
						local ok, old = pcall(function()
							return part.Material
						end)
						if ok then
							table.insert(originalMaterials, { part = part, material = old })
							pcall(function()
								part.Material = material
							end)
						end
					end
				end
			end
		end
	end

	local L = plan.lighting
	local fields = {
		ClockTime = L.clockTime,
		Brightness = L.brightness,
		FogEnd = L.fogEnd,
		FogColor = rgb(L.fogColor),
		Ambient = rgb(L.ambient),
		OutdoorAmbient = rgb(L.outdoorAmbient),
		ColorShift_Top = rgb(L.colorShiftTop),
		ColorShift_Bottom = rgb(L.colorShiftBottom),
	}
	for prop, value in fields do
		local ok, old = pcall(function()
			return Lighting[prop]
		end)
		if ok then
			table.insert(originalLighting, { target = Lighting, prop = prop, value = old })
			pcall(function()
				Lighting[prop] = value
			end)
		end
	end

	-- Post-processing effects are optional in a place; only touch ones that already exist so the
	-- candidate never adds instances to the live DataModel.
	for _, effect in Lighting:GetChildren() do
		if effect:IsA("Atmosphere") then
			local changes = {
				Density = L.atmosphereDensity,
				Haze = L.atmosphereHaze,
				Color = rgb(L.atmosphereColor),
				Decay = rgb(L.atmosphereDecay),
			}
			for prop, value in changes do
				local ok, old = pcall(function()
					return effect[prop]
				end)
				if ok then
					table.insert(originalLighting, { target = effect, prop = prop, value = old })
					pcall(function()
						effect[prop] = value
					end)
				end
			end
		elseif effect:IsA("ColorCorrectionEffect") then
			local ok, old = pcall(function()
				return effect.TintColor
			end)
			if ok then
				table.insert(originalLighting, { target = effect, prop = "TintColor", value = old })
				pcall(function()
					effect.TintColor = rgb(L.tint)
				end)
			end
		end
	end
end

local function restore()
	for _, entry in originalMaterials do
		pcall(function()
			entry.part.Material = entry.material
		end)
	end
	for _, entry in originalLighting do
		pcall(function()
			entry.target[entry.prop] = entry.value
		end)
	end
	originalMaterials = {}
	originalLighting = {}
end

LookDev.register("plaza_lighting", { apply = apply, restore = restore })

return LookDevPlaza
