-- Single list of every RemoteEvent (TECH.md §5).
-- The server creates them; clients wait for them (bounded).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local NAMES = {
	-- client -> server (requests only; the server decides)
	"Farm_SelectSeed", -- (cropId: string)
	"Farm_Complete", -- (score: number) -- minigame result 0..1
	"Farm_Auto", -- (tile: number, action: "plant"|"harvest", cropId: string?)
	"Shop_BuySeed", -- (cropId: string, amount: number)
	"Market_Sell", -- (cropId: "all", channel: "pasar"|"gelap")
	"Cheat_Apply", -- (cheatId: string, tile: number?, targetUserId: number?)
	"Bribe_RT", -- ()
	"Raid_Choose", -- ("denda"|"amplop")
	"Evidence_Record", -- (eventId: string)
	"Evidence_Report", -- (tokenId: string)
	"Item_Use", -- ("amplopPremium"|"jaminanKilat")
	"Cosmetic_Buy", -- (itemId: string)
	"Cosmetic_Equip", -- (itemId: string?)
	"Water_Neighbor", -- (targetUserId: number) -- gotong royong, +Nama Baik
	"State_Request", -- () -- ask for a fresh snapshot (join, respawn, hot reload)
	"Admin_Command", -- ({ action: string, value: any }) -- allowlisted users only

	-- server -> client
	"Notify", -- (key: string, params: {any}?)
	"Minigame_Start", -- (action, tile, cropId)
	"Minigame_Cancel", -- (tile: number)
	"Evidence_Offer", -- (eventId, cheaterName, cheatId, expiresAt)
	"Evidence_Token", -- (tokenId, cheatId, expiresAt)
	"Evidence_Remove", -- (tokenId)
	"Raid_Start", -- (payload: table)
	"Raid_End", -- (outcome: string)
	"Jail_State", -- (secondsLeft: number)
	"State_Snapshot", -- ({ version, sections }) -- full structured state on join
	"State_Patch", -- ({ [section]: value }) -- changed sections only
	"Admin_Result", -- ({ ok, message?, data? })
}

local Remotes: { [string]: RemoteEvent } = {}

if RunService:IsServer() then
	if ReplicatedStorage:FindFirstChild("Remotes") then
		-- Studio hot-reload: reuse the folder so re-running the bootstrap never leaves
		-- duplicate remotes behind (clients would bind to the wrong instance).
		ReplicatedStorage.Remotes:Destroy()
	end
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
