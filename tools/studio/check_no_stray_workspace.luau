--!nocheck
-- WORK_QUEUE section P item 183: list every top-level Workspace child that is not part of the
-- project. Runs unchanged in the Edit datamodel and in a clean Play (Server VM). No place save.
local KNOWN = {
	Terrain = true,
	Camera = true,
	World = true,
	Decor = true,
	BackgroundForest = true, -- saved-place backdrop
}
local KNOWN_PREFIX = { "LookDev", "prop_", "kit_" } -- candidates + saved-place asset models

local function known(child)
	if KNOWN[child.Name] then
		return true
	end
	if child:IsA("Folder") then
		return true -- Rojo-synced / runtime folders
	end
	for _, prefix in ipairs(KNOWN_PREFIX) do
		if string.sub(child.Name, 1, #prefix) == prefix then
			return true
		end
	end
	return false
end

local lines, stray = {}, {}
for _, child in ipairs(workspace:GetChildren()) do
	local position = ""
	if child:IsA("BasePart") then
		position = string.format(" @%.2f,%.2f,%.2f", child.Position.X, child.Position.Y, child.Position.Z)
	elseif child:IsA("Model") then
		local p = child:GetPivot().Position
		position = string.format(" @%.2f,%.2f,%.2f", p.X, p.Y, p.Z)
	end
	local detail = string.format("%s | %s | %d desc%s", child.Name, child.ClassName, #child:GetDescendants(), position)
	if known(child) then
		lines[#lines + 1] = "KNOWN " .. detail
	else
		lines[#lines + 1] = "STRAY " .. detail
		stray[#stray + 1] = detail
	end
end

local passed = #stray == 0
print("CHECK NO_STRAY_WORKSPACE " .. (passed and "PASS" or "FAIL") .. " " .. #stray .. " 0")
return { passed = passed, stray = stray, lines = lines }
