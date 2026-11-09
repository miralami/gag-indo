-- Notify: the one helper every service uses to send a localized string key to a client.
-- Kept separate from EconomyService so services never need each other just for a toast.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage:WaitForChild("Shared").Remotes)

local Notify = {}

function Notify.send(player: Player, key: string, ...: any)
	Remotes.Notify:FireClient(player, key, { ... })
end

function Notify.broadcast(key: string, ...: any)
	Remotes.Notify:FireAllClients(key, { ... })
end

return Notify
