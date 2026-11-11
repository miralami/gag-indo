--!nocheck
-- Test runner.   Run from the repository root:
--
--     lune run tests/run                 (all tests)
--     lune run tests/run -- economy      (only tests whose name contains "economy")
--
-- Exit code is 1 when anything fails, so CI can use it directly.

local process = require("@lune/process")

local Test = require("./lib/Test")
local Env = require("./lib/Env")
local Fakes = require("./lib/Fakes")

-- Add new spec files here.
local specs = {
	require("./specs/config_spec"),
	require("./specs/produce_spec"),
	require("./specs/state_spec"),
	require("./specs/seasons_spec"),
	require("./specs/shop_spec"),
	require("./specs/market_spec"),
	require("./specs/tool_spec"),
	require("./specs/storage_spec"),
	require("./specs/worker_spec"),
	require("./specs/onboarding_spec"),
	require("./specs/liveconfig_spec"),
	require("./specs/rarity_spec"),
	require("./specs/traits_spec"),
	require("./specs/almanak_spec"),
	require("./specs/ratelimit_spec"),
	require("./specs/sus_spec"),
	require("./specs/rank_spec"),
	require("./specs/economy_spec"),
	require("./specs/receipts_spec"),
	require("./specs/playerdata_spec"),
}

local t = Test.new()
for _, register in specs do
	register(t, Env, Fakes)
end

local filter = process.args[1]
local passed, failed, failures = t:run(filter, print)

print("")
if failed > 0 then
	print(`{failed} FAILED, {passed} passed`)
	print("")
	for _, failure in failures do
		print("  - " .. failure)
	end
	process.exit(1)
end
print(`All {passed} tests passed`)
