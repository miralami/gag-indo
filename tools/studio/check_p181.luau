--!nocheck
-- check_p181: WORK_QUEUE section P item 181, ad-hoc SERVER-VM Studio check. Paste this whole file
-- into execute_luau in a fresh Play session. It stages plots_r8 with enableAdditive in this SAME
-- call, measures GATE_MATERIAL / GATE_SIGN / GATE_CLEAR on the live parts, prints verbatim CHECK
-- lines and restores with disableAll(). No harness require, no place save, no visual verdict.
--
-- GATE_MATERIAL: per plot exactly one gate_lintel and two gate_post parts, each Wood/WoodPlanks and
-- each matching the declared wood RGB. Colour matters: pre-fix the lintel/posts already defaulted
-- to Wood material, so material alone would be a vacuous pass on the cream-gate screenshot.
-- GATE_SIGN: counts REAL visible signs under each plot's gate_sign part (a SurfaceGui TextLabel with
-- text, or a visible Decal with a texture), not a name tag or a bare Kind attribute.
-- GATE_CLEAR: one 6x8x1 overlap box per gate_marker in the marker's own frame, zero CanCollide hits.
-- A missing folder, plot, marker or API is a FAIL, never a skip.

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

local PLOT_COUNT = 10
local GATE_WIDTH, GATE_HEIGHT, GATE_DEPTH = 6, 8, 1
local GROUND_CONTACT_EPS = 0.05
local COLOUR_TOLERANCE = 12

local function attr(instance, key)
	local ok, value = pcall(function()
		return instance:GetAttribute(key)
	end)
	return ok and value or nil
end

-- World direction of a Part's longest local side (check_p173 convention).
local function longAxis(part)
	local size = part.Size
	local localAxis = Vector3.new(1, 0, 0)
	if size.Y > size.X and size.Y > size.Z then
		localAxis = Vector3.new(0, 1, 0)
	elseif size.Z > size.X and size.Z > size.Y then
		localAxis = Vector3.new(0, 0, 1)
	end
	return part.CFrame:VectorToWorldSpace(localAxis).Unit
end

local function isWood(part)
	local ok, material = pcall(function()
		return part.Material
	end)
	return ok and (material == Enum.Material.Wood or material == Enum.Material.WoodPlanks)
end

local function isWoodColour(part, rgb)
	if type(rgb) ~= "table" or #rgb < 3 then
		return false
	end
	local ok, color = pcall(function()
		return part.Color
	end)
	if not ok then
		return false
	end
	local channels = { color.R, color.G, color.B }
	for i = 1, 3 do
		local got = math.floor(channels[i] * 255 + 0.5)
		if math.abs(got - rgb[i]) > COLOUR_TOLERANCE then
			return false
		end
	end
	return true
end

-- A sign counts only when it is rendered by a SurfaceGui label or a Decal, not merely tagged.
local function realSignCount(part)
	local count = 0
	local okDescendants, descendants = pcall(function()
		return part:GetDescendants()
	end)
	if not okDescendants or type(descendants) ~= "table" then
		return 0
	end
	for _, descendant in ipairs(descendants) do
		if descendant:IsA("Decal") then
			local ok, visible, texture = pcall(function()
				return descendant.Visible, descendant.Texture
			end)
			if ok and visible == true and type(texture) == "string" and texture ~= "" then
				count += 1
			end
		elseif descendant:IsA("TextLabel") then
			local parent = descendant.Parent
			local onSurface = parent ~= nil and parent:IsA("SurfaceGui")
			local ok, visible, text = pcall(function()
				return descendant.Visible, descendant.Text
			end)
			if ok and onSurface and visible == true and type(text) == "string" and text ~= "" then
				count += 1
			end
		end
	end
	return count
end

local review = nil
local ok, err = pcall(function()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	review = require(shared:WaitForChild("LookDevReview"))
	local data = require(shared:WaitForChild("ModelMapPlotsR8"))

	local enabled, why = review.enableAdditive("plots_r8", game)
	if not enabled then
		error("enableAdditive(plots_r8) failed: " .. tostring(why))
	end
	local folder = workspace:FindFirstChild(data.folderName)
	if not folder then
		error("staging folder missing: " .. tostring(data.folderName))
	end

	-- Plot folders and their tagged parts, indexed by PlotIndex.
	local plotFolders, partsByPlot = {}, {}
	for i = 1, PLOT_COUNT do
		partsByPlot[i] = {}
	end
	for _, child in ipairs(folder:GetChildren()) do
		local index = tonumber(string.match(tostring(child.Name), "^Plot_(%d+)_plots_r8$"))
		if index and index >= 1 and index <= PLOT_COUNT then
			plotFolders[index] = child
		end
	end
	local plotCount = 0
	for i = 1, PLOT_COUNT do
		if plotFolders[i] then
			plotCount += 1
		end
	end
	if plotCount == 0 then
		error("staging folder has no Plot_<n>_plots_r8 folders")
	end
	for index, plotFolder in pairs(plotFolders) do
		for _, descendant in ipairs(plotFolder:GetDescendants()) do
			if descendant:IsA("BasePart") and attr(descendant, "LookDevPlotsR8") == data.id then
				local partIndex = attr(descendant, "PlotIndex")
				if type(partIndex) == "number" and partsByPlot[partIndex] then
					partsByPlot[partIndex][#partsByPlot[partIndex] + 1] = descendant
				end
			end
		end
	end

	-- GATE_MATERIAL -----------------------------------------------------------
	local bad, gatePartsSeen = 0, 0
	local materialOffenders, colourOffenders, countOffenders, axisOffenders = {}, {}, {}, {}
	for i = 1, PLOT_COUNT do
		local lintels, posts, markers = {}, {}, {}
		for _, part in ipairs(partsByPlot[i]) do
			local kind = attr(part, "Kind")
			if kind == "gate_lintel" then
				lintels[#lintels + 1] = part
			elseif kind == "gate_post" then
				posts[#posts + 1] = part
			elseif kind == "gate_marker" then
				markers[#markers + 1] = part
			end
		end
		gatePartsSeen += #lintels + #posts
		if #lintels ~= 1 or #posts ~= 2 then
			bad += 1
			countOffenders[#countOffenders + 1] = `P{i}:{#lintels} lintels/{#posts} posts`
		end
		for _, part in ipairs(lintels) do
			if not isWood(part) then
				bad += 1
				materialOffenders[#materialOffenders + 1] = part:GetFullName()
			end
			if not isWoodColour(part, data.GATE_WOOD_RGB) then
				bad += 1
				colourOffenders[#colourOffenders + 1] = part:GetFullName()
			end
			local okAxis, spansGate = pcall(function()
				if #markers == 0 then
					return false
				end
				local depthAxis = markers[1].CFrame:VectorToWorldSpace(Vector3.new(0, 0, 1)).Unit
				return math.abs(longAxis(part):Dot(depthAxis)) < 0.1
			end)
			if not okAxis or not spansGate then
				bad += 1
				axisOffenders[#axisOffenders + 1] = part:GetFullName()
			end
		end
		for _, part in ipairs(posts) do
			if not isWood(part) then
				bad += 1
				materialOffenders[#materialOffenders + 1] = part:GetFullName()
			end
			if not isWoodColour(part, data.GATE_WOOD_RGB) then
				bad += 1
				colourOffenders[#colourOffenders + 1] = part:GetFullName()
			end
		end
	end
	emit("GATE_MATERIAL", plotCount == PLOT_COUNT and gatePartsSeen == PLOT_COUNT * 3 and bad == 0, bad, 0, {
		plots = plotCount,
		gatePartsSeen = gatePartsSeen,
		colourTolerance = COLOUR_TOLERANCE,
		materialOffenders = materialOffenders,
		colourOffenders = colourOffenders,
		countOffenders = countOffenders,
		axisOffenders = axisOffenders,
	})

	-- GATE_SIGN ---------------------------------------------------------------
	local signs, signedPlots, signOffenders = 0, 0, {}
	for i = 1, PLOT_COUNT do
		local perPlot = 0
		for _, part in ipairs(partsByPlot[i]) do
			if attr(part, "Kind") == "gate_sign" then
				perPlot += realSignCount(part)
			end
		end
		signs += perPlot
		if perPlot >= 1 then
			signedPlots += 1
		end
		if perPlot ~= 1 then
			signOffenders[#signOffenders + 1] = `P{i}:{perPlot}`
		end
	end
	emit(
		"GATE_SIGN",
		plotCount == PLOT_COUNT and signedPlots == PLOT_COUNT and signs == PLOT_COUNT and #signOffenders == 0,
		signs,
		plotCount,
		{ plots = plotCount, signedPlots = signedPlots, perPlot = signOffenders }
	)

	-- GATE_CLEAR --------------------------------------------------------------
	local gateOffenders, gateErrors, gateHits, markers = {}, {}, 0, {}
	for i = 1, PLOT_COUNT do
		for _, part in ipairs(partsByPlot[i]) do
			if attr(part, "Kind") == "gate_marker" then
				markers[#markers + 1] = { part = part, index = i }
			end
		end
	end
	for _, marker in ipairs(markers) do
		local label = "P" .. marker.index
		-- Measure the opening in the marker's OWN frame, lifted off the ground slab.
		local okCF, cf = pcall(function()
			return marker.part.CFrame * CFrame.new(0, GATE_HEIGHT / 2 + GROUND_CONTACT_EPS, 0)
		end)
		local okParams, params = pcall(function()
			local p = OverlapParams.new()
			p.CollisionGroup = "Default"
			return p
		end)
		local okSize, size = pcall(function()
			return Vector3.new(GATE_WIDTH, GATE_HEIGHT, GATE_DEPTH)
		end)
		local okBox, hits = false, nil
		if okCF and okParams and okSize then
			okBox, hits = pcall(function()
				return workspace:GetPartBoundsInBox(cf, size, params)
			end)
		end
		if not okBox or type(hits) ~= "table" then
			gateErrors[#gateErrors + 1] = label
		else
			for _, hit in ipairs(hits) do
				local okCollide, collide = pcall(function()
					return hit.CanCollide
				end)
				if okCollide and collide == true then
					gateHits += 1
					local okName, hitName = pcall(function()
						return hit.Name
					end)
					gateOffenders[#gateOffenders + 1] = label .. ":" .. (okName and tostring(hitName) or "?")
				end
			end
		end
	end
	local gateIndexCounts = {}
	for i = 1, PLOT_COUNT do
		gateIndexCounts[i] = 0
	end
	for _, marker in ipairs(markers) do
		gateIndexCounts[marker.index] += 1
	end
	for i = 1, PLOT_COUNT do
		if gateIndexCounts[i] ~= 1 then
			gateOffenders[#gateOffenders + 1] = `P{i}:markers={gateIndexCounts[i]}`
		end
	end
	emit(
		"GATE_CLEAR",
		plotCount == PLOT_COUNT
			and #markers == PLOT_COUNT
			and #gateErrors == 0
			and gateHits == 0
			and #gateOffenders == 0,
		gateHits,
		0,
		{
			markers = #markers,
			box = { GATE_WIDTH, GATE_HEIGHT, GATE_DEPTH },
			offenders = gateOffenders,
			errors = gateErrors,
		}
	)
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
	emit("GATE_MATERIAL", false, 0, 0, reason)
	emit("GATE_SIGN", false, 0, PLOT_COUNT, reason)
	emit("GATE_CLEAR", false, 0, 0, reason)
end

return results
