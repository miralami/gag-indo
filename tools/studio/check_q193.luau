--!nocheck
-- check_q193.luau: SERVER-VM Studio check for WORK_QUEUE item 193 (source a flower-meadow and
-- wild-grass set). Reads the baked copies under ServerStorage.LookDevAssets.<id> in a Play session
-- (in-memory Edit source, place NOT saved). CHECK MEADOW_MODELS: at least 3 of the 5 sourced IDs
-- are baked with >=1 BasePart / MeshPart, 0 Script descendants and a non-degenerate footprint.
-- Main session pastes this whole file into execute_luau (Server VM). No visual verdict, no weakening.

local IDS = {
	7974911801, -- Wildflower02 (Oneshot7577), flower
	13032768586, -- WildFlower04 (realOmlet), flower
	70509679878841, -- Daisy Flower ([HL] Creative Team), flower
	128368650541272, -- TallGrass (Reneniza981), wild grass
	8715139325, -- Wild Grass (wooful67), wild grass
}

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
local valid = 0
for _, id in ipairs(IDS) do
	local folder = root and root:FindFirstChild(tostring(id))
	local parts, scripts, widest = 0, 0, 0
	if folder then
		for _, d in ipairs(folder:GetDescendants()) do
			if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") then
				scripts = scripts + 1
			end
			if d:IsA("BasePart") then
				parts = parts + 1
				widest = math.max(widest, d.Size.X, d.Size.Y, d.Size.Z)
			end
		end
	end
	if folder and parts >= 1 and scripts == 0 and widest > 0.01 and widest <= 100 then
		valid += 1
	end
end
emit("MEADOW_MODELS", valid >= 3, valid, 3)
return results
