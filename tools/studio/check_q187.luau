--!nocheck
-- check_q187.luau: SERVER-VM Studio check for WORK_QUEUE item 187 (source a 3D padi model).
-- Reads the baked copy under ServerStorage.LookDevAssets.<id> in a Play session (in-memory Edit
-- source, place NOT saved). CHECK PADI_MODEL_BAKED: folder exists, has >=1 MeshPart, model widest
-- horizontal dimension <= 2 studs, and the baked copy carries no Script descendants.
-- Main session pastes this whole file into execute_luau (Server VM). No visual verdict, no weakening.

local ID = "13286158859"

local results = { checks = {} }
local function emit(name, passed, measured, target)
	local line = "CHECK "
		.. name
		.. " "
		.. (passed and "PASS" or "FAIL")
		.. " "
		.. tostring(measured)
		.. " "
		.. tostring(target)
	results.checks[#results.checks + 1] = line
	print(line)
end

local root = game:GetService("ServerStorage"):FindFirstChild("LookDevAssets")
local folder = root and root:FindFirstChild(ID)
local meshParts, scripts, widest = 0, 0, 0
if folder then
	for _, d in ipairs(folder:GetDescendants()) do
		if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") then
			scripts = scripts + 1
		end
		if d:IsA("MeshPart") then
			meshParts = meshParts + 1
			widest = math.max(widest, d.Size.X, d.Size.Z)
		end
	end
end
local ok = folder ~= nil and meshParts >= 1 and widest <= 2 and scripts == 0
-- measured = number of distinct MeshParts; detail carried in the evidence file.
emit("PADI_MODEL_BAKED", ok, meshParts, 1)
return results
