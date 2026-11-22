--!nocheck
-- Local-only runner for the buildings_r4 spec (the central tests/run.luau registry is owned by
-- the main session). Run: lune run docs/v2/visual/art/models_r4/buildings/scripts/run_spec.luau
local Test = require("../../../../../../../tests/lib/Test")
local Env = require("../../../../../../../tests/lib/Env")
local Fakes = require("../../../../../../../tests/lib/Fakes")
local register = require("../../../../../../../tests/specs/model_map_buildings_r4_spec")

local process = require("@lune/process")
local t = Test.new()
register(t, Env, Fakes)
local passed, failed, failures = t:run(nil, print)
if failed > 0 then
	for _, failure in failures do
		print("  - " .. failure)
	end
	print(`{failed} FAILED, {passed} passed`)
	process.exit(1)
end
print(`All {passed} tests passed`)
