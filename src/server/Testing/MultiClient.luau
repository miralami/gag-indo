-- MultiClient: Studio-only server driver for the Q5 ten-player check (WORK_QUEUE item 22).
--
-- Run it from the SERVER command bar after the designer has opened a Local Server with N test
-- clients and enabled the harness (HARNESS.md section 3):
--
--   local MC = require(game.ServerScriptService.Server.Testing.MultiClient)
--   MC.run()
--   -- then, in the same command bar: return MC.lastResults
--
-- It drives the HARNESS.md section 2-4 loop through Harness.dispatch for every player, so every
-- action still goes through the real services behind the gate; it mints nothing. It collects one
-- results table (stuck + desync) and prints both a readable summary and a JSON line to copy into
-- evidence. The pure comparator lives in MultiClientCheck and is fully Lune-tested; the live
-- ten-player run itself is BLOCKED here because this MCP bridge cannot open a Local Server.
--
-- Not observable from a server script: client UI and whether a client's network connection stalls.
-- A "stuck step" here means the real service threw or a save never loaded; a human still watches
-- the clients for the "stopped replying" half (see the evidence REPORT).

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Gate = require(script.Parent.Gate)
local Harness = require(script.Parent.Harness)
local MultiClientCheck = require(script.Parent.MultiClientCheck)

local MultiClient = {}

-- Last completed run, so the designer can read it back with `return MC.lastResults`.
MultiClient.lastResults = nil

-- The section 2-4 loop as data. The trailing `status` is the authoritative end snapshot. `save`
-- is non-critical for Q5 (persistence is Q6) and needs API services, so a refusal is recorded
-- but never marks a player stuck.
local LOOP: { { action: string, value: any?, critical: boolean? } } = {
	{ action = "status" },
	{ action = "plant", value = { tile = 1, cropId = "padi" } },
	{ action = "ready" },
	{ action = "harvest", value = { tile = 1 } },
	{ action = "sell", value = { channel = "pasar" } },
	{ action = "buy", value = { cropId = "padi", amount = 2 } },
	{ action = "quest" },
	{ action = "save", critical = false },
	{ action = "status" },
}

local function runPlayer(player: Player): any
	local steps = {}
	local final = nil
	for _, item in ipairs(LOOP) do
		local called, data, err = pcall(Harness.dispatch, player, item.action, item.value)
		local stepOk = false
		local message = nil
		if called then
			-- dispatch returns (data?, error?): a nil error means the real handler succeeded.
			stepOk = err == nil
			message = err
			if stepOk and item.action == "status" then
				final = data
			end
		else
			-- pcall's second value is the thrown error.
			message = data
		end
		steps[#steps + 1] = {
			action = item.action,
			ok = stepOk,
			critical = item.critical,
			error = message and tostring(message) or nil,
		}
	end
	return {
		name = player.Name,
		userId = player.UserId,
		steps = steps,
		final = final,
	}
end

function MultiClient.run(): any?
	-- Gate: Studio only, and the harness must already be open from a Studio admin. Same two
	-- conditions Harness.dispatch re-checks for every action (defence in depth).
	if not RunService:IsStudio() or not Gate.isOpen() then
		warn("Q5 multi-client refused: enable the harness in Studio first (HARNESS.md section 3).")
		return nil
	end
	local players = Players:GetPlayers()
	if #players < 2 then
		warn("Q5 multi-client needs at least 2 players: open a Local Server and add test clients.")
	end

	local records = {}
	for _, player in players do
		records[#records + 1] = runPlayer(player)
	end

	local results = MultiClientCheck.check(records)
	MultiClient.lastResults = results
	for _, line in MultiClientCheck.lines(results) do
		print(line)
	end
	-- One machine-readable table, copyable from Output into docs/v2/evidence/h/<date>-q5-.../ .
	print("Q5_MULTICLIENT_JSON=" .. HttpService:JSONEncode(results))
	return results
end

return MultiClient
