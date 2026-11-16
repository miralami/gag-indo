-- RemoteGuards: defensive handlers for client->server remotes that have no gameplay
-- owner yet. They must never mutate state or trust payloads. Rate-limit and ignore
-- so future wiring cannot accidentally inherit an unsafe open listener.
--
-- T2 remote audit: every RemoteEvent/RemoteFunction name is accounted for here or
-- in a dedicated service handler (see docs/testing/CODE_AUDIT.md).

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")

local RemoteGuards = {}

local GUARDED_IGNORED = {
	"Trade_Request",
	"Trade_Respond",
	"Event_Claim",
}

function RemoteGuards.start(remotes: any?, rateLimit: any?)
	local remotesTable = remotes or require(Shared.Remotes)
	local limiter = rateLimit or require(script.Parent.RateLimit)
	for _, name in GUARDED_IGNORED do
		local remote = remotesTable[name]
		if remote and remote.OnServerEvent then
			remote.OnServerEvent:Connect(function(player, ...)
				if not limiter.allow(player, name, 2) then
					return
				end
				-- Intentionally ignored: no server feature owns this remote yet.
				-- Payload is never read into state.
			end)
		end
	end
end

function RemoteGuards.guarded()
	return table.clone(GUARDED_IGNORED)
end

return RemoteGuards

