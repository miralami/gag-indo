--!nocheck
-- Local runner for the single new spec; main session adds it to tests/run.luau.
local Test = require("../../../../../../../tests/lib/Test")
local Env = require("../../../../../../../tests/lib/Env")
local Fakes = require("../../../../../../../tests/lib/Fakes")
local register = require("../../../../../../../tests/specs/model_map_vegetation_r4_spec")

local t = Test.new()
register(t, Env, Fakes)
local passed, failed, failures = t:run(nil, print)
if failed > 0 then
	for _, failure in failures do
		print("  - " .. failure)
	end
	error("vegetation_r4 spec failed")
end
print(`vegetation_r4 spec: {passed} passed, {failed} failed`)
