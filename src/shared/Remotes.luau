-- Single list of every RemoteEvent (TECH.md §5).
-- The server creates them; clients wait for them (bounded).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local NAMES = {
	-- client -> server
	"Farm_SelectSeed", -- (cropId: string)
	"Shop_BuySeed", -- (cropId: string, amount: number)
	-- server -> client
	"Notify", -- (key: string, params: {any}?)
}

local Remotes: { [string]: RemoteEvent } = {}

if RunService:IsServer() then
	local folder = Instance.new("Folder")
	folder.Name = "Remotes"
	for _, name in NAMES do
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
		Remotes[name] = remote
	end
	folder.Parent = ReplicatedStorage
else
	local folder = ReplicatedStorage:WaitForChild("Remotes", 30)
	assert(folder, "[Remotes] Remotes folder never replicated")
	for _, name in NAMES do
		local remote = folder:WaitForChild(name, 10)
		assert(remote, "[Remotes] missing remote " .. name)
		Remotes[name] = remote :: RemoteEvent
	end
end

return Remotes
