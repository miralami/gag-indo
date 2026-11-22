--!nocheck
-- check_p178: WORK_QUEUE section P item 178, ad-hoc SERVER-VM Studio check. Paste this whole file
-- into execute_luau in a fresh Play session. It stages sawah_r8 with enableAdditive in this SAME
-- call, measures the live parts and prints verbatim CHECK lines. No harness require, no place save,
-- no visual verdict. disableAll() runs on every exit path, including a thrown measurement error.
--
-- BUND_COLOR: largest RGB-channel delta (0..255) between a staged bund and Terrain's Grass material
-- colour. BUND_SHAPE: every Bund part is a WedgePart or a Cylinder; a flat Block top >1.5 studs is
-- bad, and zero staged bunds is a FAIL. PADI_ROWS / TUFT_SHAPE reuse the item-140 contracts.

local results = { checks = {}, byName = {} }

local function emit(name, passed, measured, target, detail)
	local line = "CHECK "
		.. name
		.. " "
		.. (passed and "PASS" or "FAIL")
		.. " "
		.. tostring(measured)
		.. " "
		.. tostring(target)
	results.checks[#results.checks + 1] = line
	results.byName[name] = { line = line, passed = passed, measured = measured, target = target, detail = detail }
	print(line)
end

local BUND_TOLERANCE = 12
local FLAT_TOP_MAX = 1.5
local PADI_ROWS_MIN = 10
local PART_MAX = 2.5

local function attr(instance, key)
	local ok, value = pcall(function()
		return instance:GetAttribute(key)
	end)
	return ok and value or nil
end

local function isOwnBund(part)
	return attr(part, "Bund") == true
end

local function isRounded(part)
	local okWedge, wedge = pcall(function()
		return part:IsA("WedgePart")
	end)
	if okWedge and wedge then
		return true
	end
	local okPart, isPart = pcall(function()
		return part:IsA("Part")
	end)
	if not okPart or not isPart then
		return false
	end
	local okShape, shape = pcall(function()
		return part.Shape
	end)
	return okShape and shape == Enum.PartType.Cylinder
end

local function flatTopWidth(part)
	local okSize, size = pcall(function()
		return part.Size
	end)
	if not okSize or not size then
		return math.huge
	end
	return math.max(size.X, size.Z)
end

local function channelDelta(a, b)
	return math.max(math.abs(a.R - b.R), math.abs(a.G - b.G), math.abs(a.B - b.B)) * 255
end

local review = nil
local ok, err = pcall(function()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	review = require(shared:WaitForChild("LookDevReview"))
	local sawahData = require(shared:WaitForChild("ModelMapSawahR8"))
	if type(sawahData.BUND_COLOR_TOL) == "number" then
		BUND_TOLERANCE = sawahData.BUND_COLOR_TOL
	end

	local enabled, why = review.enableAdditive("sawah_r8", game)
	if not enabled then
		error("enableAdditive(sawah_r8) failed: " .. tostring(why))
	end
	local folder = workspace:FindFirstChild(sawahData.folderName)
	if not folder then
		error("staging folder missing: " .. tostring(sawahData.folderName))
	end

	local bunds, padiParts = {}, {}
	for _, instance in ipairs(folder:GetDescendants()) do
		local okPart, isPart = pcall(function()
			return instance:IsA("BasePart")
		end)
		if okPart and isPart then
			if isOwnBund(instance) then
				bunds[#bunds + 1] = instance
			end
			if attr(instance, "PadiPart") == true then
				padiParts[#padiParts + 1] = instance
			end
		end
	end

	-- BUND_COLOR --------------------------------------------------------------
	local terrainGrass = nil
	local okTerrain, colour = pcall(function()
		return workspace.Terrain:GetMaterialColor(Enum.Material.Grass)
	end)
	if okTerrain and colour then
		terrainGrass = colour
	else
		terrainGrass = Color3.fromRGB(111, 138, 63) -- Landscape.COLOURS Grass (#6f8a3f)
	end
	local worstDelta, colourReadErrors = 0, 0
	for _, bund in ipairs(bunds) do
		local okColour, partColour = pcall(function()
			return bund.Color
		end)
		if okColour and partColour then
			worstDelta = math.max(worstDelta, channelDelta(partColour, terrainGrass))
		else
			colourReadErrors += 1
			worstDelta = 999
		end
	end
	worstDelta = math.floor(worstDelta * 100) / 100
	if #bunds == 0 then
		worstDelta = 999 -- no bunds is not a vacuous pass
	end
	emit("BUND_COLOR", #bunds > 0 and worstDelta <= BUND_TOLERANCE, worstDelta, BUND_TOLERANCE, {
		bundsChecked = #bunds,
		colourReadErrors = colourReadErrors,
		method = "max |RGB bund - Terrain:GetMaterialColor(Grass)| in 0..255 units",
	})

	-- BUND_SHAPE --------------------------------------------------------------
	local badShape, flatTops = {}, {}
	for _, bund in ipairs(bunds) do
		local width = flatTopWidth(bund)
		if not isRounded(bund) then
			badShape[#badShape + 1] = tostring(bund.Name) .. ":flat-top=" .. tostring(width)
		end
		if width > FLAT_TOP_MAX then
			flatTops[#flatTops + 1] = tostring(bund.Name)
		end
	end
	local shapeBad = #badShape
	if #bunds == 0 then
		shapeBad = 1
	end
	emit("BUND_SHAPE", #bunds > 0 and shapeBad == 0, shapeBad, 0, {
		bundsChecked = #bunds,
		flatTops = flatTops,
		failures = badShape,
		method = "Bund parts must be WedgePart or Shape=Cylinder; plain Blocks with >1.5-stud tops fail",
	})

	-- PADI_ROWS ---------------------------------------------------------------
	local rowsByTerrace = {}
	for _, part in ipairs(padiParts) do
		local terrace, row = attr(part, "TerraceIndex"), attr(part, "PadiRow")
		if type(terrace) == "number" and type(row) == "number" then
			rowsByTerrace[terrace] = rowsByTerrace[terrace] or {}
			rowsByTerrace[terrace][row] = true
		end
	end
	local counts, minRows = {}, math.huge
	for terrace = 1, #sawahData.TERRACE_TOPS do
		local count = 0
		for _ in pairs(rowsByTerrace[terrace] or {}) do
			count += 1
		end
		counts[terrace] = count
		minRows = math.min(minRows, count)
	end
	if minRows == math.huge then
		minRows = 0
	end
	emit("PADI_ROWS", minRows >= PADI_ROWS_MIN, minRows, PADI_ROWS_MIN, {
		perTerrace = counts,
		padiParts = #padiParts,
		method = "MINIMUM distinct numeric PadiRow ids per terrace on PadiPart parts",
	})

	-- TUFT_SHAPE --------------------------------------------------------------
	local oversized = {}
	for _, part in ipairs(padiParts) do
		local okSize, size = pcall(function()
			return part.Size
		end)
		if not okSize or not size or size.X > PART_MAX or size.Y > PART_MAX or size.Z > PART_MAX then
			oversized[#oversized + 1] = tostring(part.Name)
		end
	end
	emit("TUFT_SHAPE", #padiParts > 0 and #oversized == 0, #oversized, 0, {
		padiParts = #padiParts,
		failures = oversized,
		method = "every PadiPart BasePart stays within 2.5 studs on all axes",
	})
end)

-- Restore every additively staged candidate, even when a check threw.
pcall(function()
	if review then
		review.disableAll()
	else
		require(game:GetService("ReplicatedStorage"):WaitForChild("Shared").LookDevReview).disableAll()
	end
end)

if not ok then
	local reason = { reason = "audit error: " .. tostring(err) }
	emit("BUND_COLOR", false, 999, BUND_TOLERANCE, reason)
	emit("BUND_SHAPE", false, 1, 0, reason)
	emit("PADI_ROWS", false, 0, PADI_ROWS_MIN, reason)
	emit("TUFT_SHAPE", false, 1, 0, reason)
end

return results
