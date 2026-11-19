--!nocheck
-- Dump the shipped CropModelCandidates partsFor() output as JSON so the gallery preview generator
-- renders EXACTLY the same data the Studio adapter uses. Run via:
--   lune run docs/v2/visual/art/crops/src/dump_crops.luau > crops.json
local Recipes = require("../../../../../../src/shared/CropModelCandidates")

local function json(value, indent): string
	indent = indent or ""
	local t = type(value)
	if t == "number" then
		return string.format("%.6g", value)
	elseif t == "boolean" then
		return tostring(value)
	elseif t == "string" then
		return '"' .. value:gsub('[%c"\\]', function(c)
			return ({ ["\n"] = "\\n", ["\r"] = "\\r", ["\t"] = "\\t", ['"'] = '\\"', ["\\"] = "\\\\" })[c] or ("\\u%04x"):format(c:byte())
		end) .. '"'
	elseif t == "table" then
		local isArray = #value > 0
		local parts = {}
		if isArray then
			for _, v in value do
				parts[#parts + 1] = json(v, indent)
			end
			return "[" .. table.concat(parts, ",") .. "]"
		end
		local keys = {}
		for k in value do
			keys[#keys + 1] = k
		end
		table.sort(keys)
		for _, k in keys do
			parts[#parts + 1] = json(k) .. ":" .. json(value[k], indent)
		end
		return "{" .. table.concat(parts, ",") .. "}"
	end
	return "null"
end

local out = {
	stages = Recipes.stages,
	cropIds = Recipes.cropIds,
	models = {},
}
for _, cropId in Recipes.cropIds do
	out.models[cropId] = {}
	for _, stage in Recipes.stages do
		out.models[cropId][stage] = Recipes.partsFor(cropId, stage)
	end
end
print(json(out))
