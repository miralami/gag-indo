--!nocheck
-- Standalone runner for tests/specs/texture_map_r4_spec.luau until the main session
-- adds that spec to tests/run.luau. Run from the repository root:
--   lune run docs/v2/visual/art/textures_r4/src/run_spec.luau

local Test = require("../../../../../../tests/lib/Test")
local Env = require("../../../../../../tests/lib/Env")
local Fakes = require("../../../../../../tests/lib/Fakes")
local spec = require("../../../../../../tests/specs/texture_map_r4_spec")

local t = Test.new()
spec(t, Env, Fakes)
local passed, failed, failures = t:run(nil, print)
if failed > 0 then
	error(table.concat(failures, "\n"))
end
print(`texture_map_r4: {passed} passed, {failed} failed`)
