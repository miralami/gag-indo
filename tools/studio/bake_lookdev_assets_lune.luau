--!strict
-- WORK_QUEUE item 54, Route A (preferred): Open Cloud asset-delivery -> assets/lookdev/<id>.rbxm.
-- Run with `lune run tools/studio/bake_lookdev_assets_lune.luau`. The key is read from the
-- ROBLOX_API_KEY env var and is NEVER printed, logged or written to a file.
-- On a 401/403/404 the exact status and response body are printed ONCE and the script stops;
-- the item records that response and Route B (Edit-mode bake) is used instead.

local fs = require("@lune/fs")
local net = require("@lune/net")
local serde = require("@lune/serde")
local roblox = require("@lune/roblox")
local process = require("@lune/process")

local KEY = process.env.ROBLOX_API_KEY
if not KEY or KEY == "" then
	print("ROUTE_A RESULT: key-missing")
	return
end

local IDS: { number } = {
	134692206104779, 102638587410748, 108444766706310, 123167704485524,
	119484467697394, 77509780044045, 123174857731098, 115389644627447, 105455683512183,
	119426685469058, 95025959179405, 115924626989907, 103341007913673, 109848917287023,
	87487192428396, 138444489439223,
	95769944522207, 119293239911242, 130965811347980, 103132734600778, 116666781655827,
	71002247087415, 14769019514, 126970096704856,
	15344074131, 184362803, 8864962424, 361802126, 9639782964, 115462020907259, 5445549227,
}

local OUT_DIR = "assets/lookdev"
local SCRIPT_CLASSES = { Script = true, LocalScript = true, ModuleScript = true }

local function clean(roots: { any }): { any }
	local kept = {}
	for _, root in roots do
		local stack = { root }
		while #stack > 0 do
			local current = table.remove(stack)
			if SCRIPT_CLASSES[current.ClassName] then
				current:Destroy()
			else
				for _, child in ipairs(current:GetChildren()) do
					stack[#stack + 1] = child
				end
			end
		end
		if not SCRIPT_CLASSES[root.ClassName] then
			kept[#kept + 1] = root
		end
	end
	return kept
end

local function fetch(id: number): (boolean, string?)
	local url = "https://apis.roblox.com/asset-delivery-api/v1/assetId/" .. tostring(id)
	local ok, result = pcall(function()
		return net.request({
			url = url,
			method = "GET",
			headers = { ["x-api-key"] = KEY, ["Accept-Encoding"] = "gzip" },
			query = { skipSigningScripts = "true" },
		})
	end)
	if not ok then
		return false, "REQUEST ERROR: " .. tostring(result)
	end
	if result.statusCode ~= 200 then
		return false, "HTTP " .. tostring(result.statusCode) .. " " .. tostring(result.body)
	end
	local decodedOk, meta = pcall(function()
		return serde.decode("json", result.body)
	end)
	if not decodedOk or type(meta) ~= "table" or type(meta.location) ~= "string" then
		return false, "NO LOCATION: " .. tostring(result.body)
	end
	local binOk, bin = pcall(function()
		return net.request({
			url = meta.location,
			method = "GET",
			headers = { ["Accept-Encoding"] = "gzip" },
			options = { decompress = true },
		})
	end)
	if not binOk or bin.statusCode ~= 200 then
		return false, "CDN HTTP " .. tostring(bin and bin.statusCode) .. " " .. tostring(bin and bin.body)
	end
	local roots = roblox.deserializeModel(bin.body)
	local kept = clean(roots)
	if #kept == 0 then
		return false, "NO ROOTS after script strip"
	end
	fs.writeFile(OUT_DIR .. "/" .. tostring(id) .. ".rbxm", roblox.serializeModel(kept))
	return true, nil
end

local baked, failures = 0, 0
for _, id in ipairs(IDS) do
	if fs.isFile(OUT_DIR .. "/" .. tostring(id) .. ".rbxm") then
		baked += 1
		continue
	end
	local ok, why = fetch(id)
	if ok then
		baked += 1
	else
		failures += 1
		print("ROUTE_A FAIL id=" .. tostring(id) .. " " .. tostring(why))
		-- A denied scope/asset is decisive: record one exact response and stop.
		if string.find(tostring(why), "HTTP 401", 1, true)
			or string.find(tostring(why), "HTTP 403", 1, true)
			or string.find(tostring(why), "HTTP 404", 1, true)
		then
			break
		end
	end
end

print("ROUTE_A RESULT baked=" .. baked .. " failures=" .. failures)
