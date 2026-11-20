--!strict
-- LookDevAssetLoader: clone-first retrieval of baked Creator Store models (WORK_QUEUE item 54).
-- An Edit-time bake parents each stripped object under ServerStorage.LookDevAssets.<assetId>.
-- Runtime LoadAsset is used ONLY when no baked copy exists; any load failure increments the
-- family's shared failure counter and warns loudly — no silent pcall-and-continue.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local InsertService = game:GetService("InsertService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local LookDevFailures = require(Shared.LookDevFailures)

local LookDevAssetLoader = {}

-- Return a detached clone of the baked object for assetId, or nil when nothing was baked.
function LookDevAssetLoader.baked(assetId: number): any?
	if type(assetId) ~= "number" or assetId <= 0 or assetId % 1 ~= 0 then
		return nil
	end
	local okRoot, root = pcall(function()
		return ServerStorage:FindFirstChild("LookDevAssets")
	end)
	if not okRoot or not root then
		return nil
	end
	local okFolder, folder = pcall(function()
		return root:FindFirstChild(tostring(assetId))
	end)
	if not okFolder or not folder then
		return nil
	end
	-- The bake stores one object per asset id. Prefer the container itself when it is a real
	-- object; otherwise take its first child (the bake's standard layout).
	local okSource, source = pcall(function()
		if folder:IsA("Model") or folder:IsA("Accessory") or folder:IsA("BasePart") then
			return folder
		end
		return folder:GetChildren()[1]
	end)
	if not okSource or not source then
		return nil
	end
	local okClone, clone = pcall(function()
		return source:Clone()
	end)
	if not okClone or not clone then
		return nil
	end
	return clone
end

-- Clone first, then runtime LoadAsset only as a fallback. familyId is the counter key.
function LookDevAssetLoader.get(assetId: number, familyId: string): any?
	local baked = LookDevAssetLoader.baked(assetId)
	if baked then
		return baked
	end
	local ok, loaded = pcall(function()
		return InsertService:LoadAsset(assetId)
	end)
	if not ok or not loaded then
		LookDevFailures.add(familyId, 1)
		warn("[LookDevAssetLoader] " .. familyId .. " load failed for asset " .. tostring(assetId) .. ": " .. tostring(loaded))
		return nil
	end
	return loaded
end

return LookDevAssetLoader
