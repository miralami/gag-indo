--!strict
-- Bake every model ID referenced by ReplicatedStorage.Shared.ModelMap* into
-- ServerStorage.LookDevAssets.<id>. Run in the EDIT datamodel via Studio MCP execute_luau.
-- Never run in Play, never save the place (saving is the owner's call).
--
-- Why (2026-11-23): the open place had only 6 of 123 referenced IDs baked, so the background
-- forest was 531 bare trunks and most props/buildings fell back to primitives.
--
-- Safety: IDs in Shared.AssetBlocklist are skipped. Before stripping, every object is scanned
-- and anything suspicious (ScreenGui/BillboardGui-free LayerCollectors, scripts that call
-- require(<number>), GetObjects, loadstring, getfenv, HttpService) is reported by path.
-- All Script/LocalScript/ModuleScript and every ScreenGui are destroyed before parenting.
-- Clothing, sound and animation IDs are not models: they are skipped by key name.

local ServerStorage = game:GetService("ServerStorage")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local AssetBlocklist = require(Shared:WaitForChild("AssetBlocklist")) :: any

local SKIP_KEYS = {
	shirt = true,
	pants = true,
	shirtId = true,
	pantsId = true,
	layeredShirt = true,
	animationId = true,
	replacedR6Id = true,
	assetId = true, -- costume uploads (images)
}

local seen: { [number]: string } = {}
local function walk(t: any, path: string, key: string, depth: number)
	if depth > 7 then
		return
	end
	for k, v in pairs(t) do
		local ks = tostring(k)
		if type(v) == "number" and v > 1000000 and v % 1 == 0 then
			if not SKIP_KEYS[ks] and not string.find(path, "Sounds", 1, true) and not string.find(path, "catalog", 1, true) then
				if not seen[v] then
					seen[v] = path .. "." .. ks
				end
			end
		elseif type(v) == "table" then
			walk(v, path .. "." .. ks, ks, depth + 1)
		end
	end
end

for _, m in ipairs(Shared:GetChildren()) do
	if m:IsA("ModuleScript") and string.sub(m.Name, 1, 8) == "ModelMap" then
		local ok, mod = pcall(require, m)
		if ok and type(mod) == "table" then
			walk(mod, m.Name, "", 0)
		end
	end
end

local SUSPECT = { "require%s*%(%s*%d", "GetObjects", "loadstring", "getfenv", "HttpService", "PlayerGui" }

local rootFolder = ServerStorage:FindFirstChild("LookDevAssets")
if not rootFolder then
	rootFolder = Instance.new("Folder")
	rootFolder.Name = "LookDevAssets"
	rootFolder.Parent = ServerStorage
end

local baked, skipped, failed, stripped = 0, 0, 0, 0
local report: { string } = {}
local n = 0
for id, path in pairs(seen) do
	n += 1
	local key = tostring(id)
	local existing = rootFolder:FindFirstChild(key)
	if AssetBlocklist.isBlocked(id) then
		if existing then
			existing:Destroy()
		end
		table.insert(report, "BLOCKED " .. key .. " " .. path)
	elseif existing and #existing:GetChildren() > 0 then
		skipped += 1
	else
		local ok, objects = pcall(function()
			return game:GetObjects("rbxassetid://" .. key)
		end)
		local source = if ok and type(objects) == "table" then objects[1] else nil
		if not source then
			failed += 1
			table.insert(report, "FAIL " .. key .. " " .. path .. " " .. (if ok then "no objects" else tostring(objects)))
		elseif source:IsA("LuaSourceContainer") or source:IsA("Sound") or source:IsA("Animation") then
			failed += 1
			table.insert(report, "NOTMODEL " .. key .. " " .. path .. " " .. source.ClassName)
			source:Destroy()
		else
			local doomed = {}
			for _, d in ipairs(source:GetDescendants()) do
				if d:IsA("LuaSourceContainer") then
					local src = ""
					pcall(function()
						src = (d :: any).Source
					end)
					for _, p in ipairs(SUSPECT) do
						if string.find(src, p) then
							table.insert(report, "SUSPECT " .. key .. " " .. d:GetFullName() .. " :: " .. p)
							break
						end
					end
					table.insert(doomed, d)
				elseif d:IsA("ScreenGui") then
					table.insert(report, "SUSPECT-GUI " .. key .. " " .. d:GetFullName())
					table.insert(doomed, d)
				end
			end
			for _, d in ipairs(doomed) do
				pcall(function()
					d:Destroy()
				end)
			end
			stripped += #doomed
			if not existing then
				existing = Instance.new("Folder")
				existing.Name = key
				existing.Parent = rootFolder
			end
			source.Parent = existing
			baked += 1
		end
	end
	if n % 6 == 0 then
		task.wait()
	end
end

return {
	referenced = n,
	baked = baked,
	skipped = skipped,
	failed = failed,
	stripped = stripped,
	report = table.concat(report, "\n"),
}
