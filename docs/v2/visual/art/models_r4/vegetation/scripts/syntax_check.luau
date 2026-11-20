--!nocheck
local fs = require("@lune/fs")
local luau = require("@lune/luau")
for _, path in {
	"src/shared/ModelMapVegetationR4.luau",
	"src/server/World/LookDevModelsVegetationR4.luau",
	"tests/specs/model_map_vegetation_r4_spec.luau",
} do
	local ok, err = luau.load(fs.readFile(path))
	print(ok and "OK  " or "FAIL", path, ok and "" or tostring(err))
	if not ok then
		error("syntax check failed: " .. path)
	end
end
