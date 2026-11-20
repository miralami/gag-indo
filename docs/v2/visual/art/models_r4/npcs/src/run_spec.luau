--!nocheck
-- Local lane runner: validates the npcs_r4 spec without editing the shared tests/run.luau.
local Test = require("../../../../../../../tests/lib/Test")
local Env = require("../../../../../../../tests/lib/Env")
local Fakes = require("../../../../../../../tests/lib/Fakes")
local register = require("../../../../../../../tests/specs/model_map_npcs_r4_spec")

local t = Test.new()
register(t, Env, Fakes)
local passed, failed, failures = t:run(nil, print)
for _, failure in ipairs(failures) do
	print("FAILURE", failure)
end
print("RESULT passed=" .. tostring(passed) .. " failed=" .. tostring(failed))
if failed > 0 then
	error("npcs_r4 spec failed")
end
