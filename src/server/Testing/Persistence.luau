-- Persistence: Studio-only server driver for the Q6 save → leave → rejoin rehearsal
-- (WORK_QUEUE item 23). Exact designer steps are in docs/testing/Q6_PUBLISHED_PLACE.md.
--
--   -- SERVER command bar, before leaving (harness enabled, API services on):
--   local P = require(game.ServerScriptService.Server.Testing.Persistence)
--   P.capture()                       -- prints Q6_BEFORE_JSON=... ; copy that line's JSON
--   -- Leave (Shift+F5), Play again, then in the SERVER command bar:
--   P.compare(<paste the JSON string here>)
--
-- The JSON has to be pasted back because a leave/rejoin resets module state; that is deliberate,
-- so the before snapshot cannot be faked by the same process. Both functions are gated exactly
-- like the harness (Studio + admin flag), so neither can be used in a published server — the real
-- published-place half of Q6 is the human step in the plan. The pure comparison is in
-- PersistenceCheck and is fully Lune-tested; this driver only captures, decodes and prints.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Gate = require(script.Parent.Gate)
local Harness = require(script.Parent.Harness)
local PersistenceCheck = require(script.Parent.PersistenceCheck)

local Persistence = {}

-- Keyed by UserId so a designer with more than one player in a Local Server can capture each.
Persistence.before = {}
Persistence.lastResult = nil

local function ready(): boolean
	if not RunService:IsStudio() or not Gate.isOpen() then
		warn("Q6 persistence refused: enable the harness in Studio first (HARNESS.md section 3).")
		return false
	end
	return true
end

local function pick(player)
	if player then
		return player
	end
	local list = Players:GetPlayers()
	return list[1]
end

-- Capture the "before" numbers and save now. `save` is non-critical here only in the sense that a
-- refusal is reported: without API services the later compare will fail, which is the honest result.
function Persistence.capture(player): (any?, boolean?)
	if not ready() then
		return nil, nil
	end
	player = pick(player)
	if not player then
		warn("Q6 capture needs a player in the session.")
		return nil, nil
	end
	local snapshot, err = Harness.dispatch(player, "status")
	if not snapshot then
		warn("Q6 capture could not read status: " .. tostring(err))
		return nil, nil
	end
	local saved, saveErr = Harness.dispatch(player, "save")
	local saveOk = saved ~= nil
	Persistence.before[player.UserId] = snapshot
	print("Q6_BEFORE_JSON=" .. HttpService:JSONEncode(snapshot))
	if not saveOk then
		warn("Q6 save step refused: " .. tostring(saveErr) .. " (Enable Studio Access to API Services?)")
	end
	return snapshot, saveOk
end

-- Compare a pasted before snapshot (table or JSON string) with a fresh status after rejoin.
function Persistence.compare(before: any, player): any?
	if not ready() then
		return nil
	end
	player = pick(player)
	if not player then
		warn("Q6 compare needs a player in the session.")
		return nil
	end
	if type(before) == "string" then
		-- JSONDecode throws on bad input; pcall keeps a paste typo from aborting the command bar.
		local ok, parsed = pcall(function()
			return HttpService:JSONDecode(before)
		end)
		if not ok then
			warn("Q6 compare could not decode the pasted JSON: " .. tostring(parsed))
			return nil
		end
		before = parsed
	end
	if type(before) ~= "table" then
		warn("Q6 compare needs the Q6_BEFORE_JSON table or its JSON string.")
		return nil
	end
	local after, err = Harness.dispatch(player, "status")
	if not after then
		warn("Q6 compare could not read status: " .. tostring(err))
		return nil
	end
	local results = PersistenceCheck.compare(before, after)
	Persistence.lastResult = results
	for _, line in PersistenceCheck.lines(results) do
		print(line)
	end
	print("Q6_RESULT_JSON=" .. HttpService:JSONEncode(results))
	return results
end

return Persistence
