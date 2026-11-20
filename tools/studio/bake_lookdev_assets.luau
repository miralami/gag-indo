--!strict
-- WORK_QUEUE item 54, Route B. Run in the EDIT datamodel via Studio MCP execute_luau.
-- Never run in Play, never save the place, never read an API key.
--
-- Every model/hat ID used by the ModelMap*R4/R5/R6 appliers is fetched with GetObjects,
-- stripped of Script/LocalScript/ModuleScript descendants, and stored as one object under
-- ServerStorage.LookDevAssets.<id>. Reruns skip an id only when its folder already has a child.
-- Failures are warned loudly and returned; the appliers' LookDevAssetLoader falls back to the
-- runtime path only when no baked copy exists.

local ServerStorage = game:GetService("ServerStorage")

-- Exact IDs from ModelMapBuildingsR4, ModelMapNpcsR4, ModelMapPropsR4,
-- ModelMapVegetationR4, ModelMapNpcsR5.accessories and ModelMapVegetationR6
-- (ids + the two shortlist alternates). Image costume IDs are not models and are excluded.
local IDS: { number } = {
	-- buildings_r4
	134692206104779,
	102638587410748,
	108444766706310,
	123167704485524,
	-- npcs_r4
	119484467697394,
	77509780044045,
	123174857731098,
	115389644627447,
	105455683512183,
	-- props_r4 (reused unchanged by props_r5 and props_r6)
	119426685469058,
	95025959179405,
	115924626989907,
	103341007913673,
	109848917287023,
	87487192428396,
	138444489439223,
	-- vegetation_r4 (reused by vegetation_r5 and vegetation_r6)
	95769944522207,
	119293239911242,
	130965811347980,
	103132734600778,
	116666781655827,
	-- npcs_r5 / npcs_r6 hats (caping backup included)
	71002247087415,
	14769019514,
	126970096704856,
	-- vegetation_r6 Creator Store shortlist and alternates
	15344074131,
	184362803,
	8864962424,
	361802126,
	9639782964,
	115462020907259,
	5445549227,
	-- props_r8 (WORK_QUEUE item 64): R7-only replacements, loaded in Edit mode on 2026-11-21
	4951145641, -- Cangkul (was alat_tani 109848917287023)
	10506531785, -- Gerobak (was 119426685469058)
	85094565897097, -- bamboo fence, reused for pagar_bambu (was 103341007913673)
}

local function stripScripts(root: Instance)
	local stack: { Instance } = { root }
	while #stack > 0 do
		local current = table.remove(stack)
		if
			current.ClassName == "Script"
			or current.ClassName == "LocalScript"
			or current.ClassName == "ModuleScript"
		then
			pcall(function()
				current:Destroy()
			end)
			continue
		end
		for _, child in ipairs(current:GetChildren()) do
			stack[#stack + 1] = child
		end
	end
end

local rootFolder = ServerStorage:FindFirstChild("LookDevAssets")
if not rootFolder then
	rootFolder = Instance.new("Folder")
	rootFolder.Name = "LookDevAssets"
	rootFolder.Parent = ServerStorage
end

local baked = 0
local failures = 0
local missing: { [number]: string } = {}

for index, id in ipairs(IDS) do
	local key = tostring(id)
	local folder = rootFolder:FindFirstChild(key)
	if folder and #folder:GetChildren() > 0 then
		continue
	end
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = key
		folder.Parent = rootFolder
	end

	local ok, objects = pcall(function()
		return game:GetObjects("rbxassetid://" .. key)
	end)
	local source = if ok and type(objects) == "table" then objects[1] else nil
	if not source then
		local reason = if ok then "GetObjects returned no objects" else tostring(objects)
		failures += 1
		missing[id] = reason
		warn("[bake_lookdev_assets] FAILED " .. key .. ": " .. reason)
		continue
	end

	stripScripts(source)
	local parented = pcall(function()
		source.Parent = folder
	end)
	if not parented then
		failures += 1
		missing[id] = "could not parent baked object"
		warn("[bake_lookdev_assets] FAILED " .. key .. ": could not parent baked object")
		continue
	end
	baked += 1

	if index % 8 == 0 then
		task.wait()
	end
end

return { baked = baked, failures = failures, missing = missing }
