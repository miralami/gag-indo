-- State (client): the small structured-state store (v2 PLAN §7.1).
--
-- The server sends one snapshot on join and section patches after that. UI code reads
-- State.get("produce") and subscribes with State.onChanged. Scalars still come from
-- player attributes, exactly as in v1.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local State = {}

State.data = {} :: { [string]: any }
State.ready = false
State.version = 0

local listeners: { (string) -> () } = {}

local function fire(section: string)
	for _, callback in table.clone(listeners) do
		task.spawn(callback, section)
	end
end

function State.get(section: string): any
	return State.data[section]
end

-- callback(section) runs for every changed section ("all" for a full snapshot).
-- Returns a handle with :Disconnect().
function State.onChanged(callback: (string) -> ()): { Disconnect: () -> () }
	table.insert(listeners, callback)
	return {
		Disconnect = function()
			local index = table.find(listeners, callback)
			if index then
				table.remove(listeners, index)
			end
		end,
	}
end

function State.request()
	Remotes.State_Request:FireServer()
end

function State.mount()
	Remotes.State_Snapshot.OnClientEvent:Connect(function(snapshot)
		if type(snapshot) ~= "table" or type(snapshot.sections) ~= "table" then
			return
		end
		for section, value in snapshot.sections do
			State.data[section] = value
		end
		State.version = tonumber(snapshot.version) or 0
		State.ready = true
		fire("all")
	end)

	Remotes.State_Patch.OnClientEvent:Connect(function(patch)
		if type(patch) ~= "table" then
			return
		end
		for section, value in patch do
			State.data[section] = value
			fire(section)
		end
	end)

	State.request()
end

return State
