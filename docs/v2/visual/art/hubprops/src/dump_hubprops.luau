--!nocheck
-- Dump the shipped HubPropCandidates.partsFor() output as JSON for the gallery preview generator.
-- Run: lune run docs/v2/visual/art/hubprops/src/dump_hubprops.luau > hubprops.json
local Recipes = require("../../../../../../src/shared/HubPropCandidates")

local function json(value): string
	local t = type(value)
	if t == "number" then return string.format("%.6g", value)
	elseif t == "boolean" then return tostring(value)
	elseif t == "string" then return '"' .. value:gsub('[%c"\\]', function(c)
		return ({ ["\n"]="\\n", ["\r"]="\\r", ["\t"]="\\t", ['"']='\\"', ["\\"]="\\\\" })[c] or ("\\u%04x"):format(c:byte())
	end) .. '"'
	elseif t == "table" then
		if #value > 0 then
			local p = {} for _, v in value do p[#p+1] = json(v) end
			return "[" .. table.concat(p, ",") .. "]"
		end
		local keys = {} for k in value do keys[#keys+1] = k end
		table.sort(keys)
		local p = {} for _, k in keys do p[#p+1] = json(k) .. ":" .. json(value[k]) end
		return "{" .. table.concat(p, ",") .. "}"
	end
	return "null"
end

local out = { hubOrder = Recipes.hubOrder, hubs = {}, parts = {}, accent = Recipes.ACCENT }
for _, key in Recipes.hubOrder do
	out.hubs[key] = { model = Recipes.hubs[key].model, anchor = Recipes.hubs[key].anchor }
	out.parts[key] = Recipes.partsFor(key)
end
print(json(out))
