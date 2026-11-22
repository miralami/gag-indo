--!nocheck
-- check_p175: WORK_QUEUE section P item 175, ad-hoc SERVER-VM Studio check. Paste this whole file
-- into execute_luau in a fresh Play session. It stages plaza_r9 with enableAdditive in this SAME
-- call, measures the four live geometry checks below, prints verbatim CHECK lines and restores
-- with disableAll(). No harness require, no place save, no visual verdict.
--
-- FOUNTAIN_SIZE: the live FountainBasin part is >= 14 studs across (max Size.X/Size.Z).
-- FOUNTAIN_TIERS: exactly two FountainTier parts, one tagged 1 and one tagged 2.
-- FLAG_CLEAN: every flagged part belongs to exactly one pair id, and each pair is two parallel
--   flat panels (one red above one white); single panels and crossing pairs count as bad.
-- PLAZA_WALKABLE: each of the four lanes reaches the paved ring and its corridor out to the plaza
--   edge has no staged part overlapping it (per-part CFrame:VectorToWorldSpace AABB).
-- A missing folder, data, ring radius or empty part set FAILs; no vacuous pass.

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
	return results
end

local MIN_BASIN = 14
local FLAT_MAX = 0.25 -- panel thickness ceiling; real panels are 0.12 studs thin
local AXIS_DOT = 0.99
local CENTRE_TOL = 0.05
local OVERLAP_TOL = 0.05

local function attr(instance, name)
	local ok, value = pcall(function()
		return instance:GetAttribute(name)
	end)
	if ok then
		return value
	end
	return nil
end

local function basePartsUnder(folder)
	local parts = {}
	for _, descendant in ipairs(folder:GetDescendants()) do
		if descendant:IsA("BasePart") then
			local okTransparency, transparency = pcall(function()
				return descendant.Transparency
			end)
			if okTransparency and type(transparency) == "number" and transparency < 1 then
				parts[#parts + 1] = descendant
			end
		end
	end
	return parts
end

-- World XZ AABB of a rotated Part; VectorToWorldSpace maps each local half-axis to its world
-- contribution. Local coordinates are relative to MapSpec.PLAZA centre (originX, originZ).
local function partBox(part, originX, originZ)
	local size = part.Size
	local cframe = part.CFrame
	local halfX = cframe:VectorToWorldSpace(Vector3.new(size.X / 2, 0, 0))
	local halfZ = cframe:VectorToWorldSpace(Vector3.new(0, 0, size.Z / 2))
	local centre = cframe.Position
	local localX, localZ = centre.X - originX, centre.Z - originZ
	local dx = math.abs(halfX.X) + math.abs(halfZ.X)
	local dz = math.abs(halfX.Z) + math.abs(halfZ.Z)
	return { minX = localX - dx, maxX = localX + dx, minZ = localZ - dz, maxZ = localZ + dz }
end

local function overlaps(a, b)
	return math.min(a.maxX, b.maxX) - math.max(a.minX, b.minX) > OVERLAP_TOL
		and math.min(a.maxZ, b.maxZ) - math.max(a.minZ, b.minZ) > OVERLAP_TOL
end

local review = nil
local ok, err = pcall(function()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	review = require(shared:WaitForChild("LookDevReview"))
	local data = require(shared:WaitForChild("ModelMapPlazaR9"))

	local enabled, why = review.enableAdditive("plaza_r9", game)
	if not enabled then
		error("enableAdditive(plaza_r9) failed: " .. tostring(why))
	end
	local folder = workspace:FindFirstChild(data.folderName)
	if not folder then
		error("staging folder missing: " .. tostring(data.folderName))
	end
	local parts = basePartsUnder(folder)
	if #parts == 0 then
		error("staging folder has no visible BaseParts")
	end

	-- FOUNTAIN_SIZE -----------------------------------------------------------
	local basin = nil
	for _, part in ipairs(parts) do
		if part.Name == "FountainBasin" then
			basin = part
			break
		end
	end
	local diameter = 0
	if basin then
		diameter = math.max(basin.Size.X, basin.Size.Z)
	end
	emit("FOUNTAIN_SIZE", diameter >= MIN_BASIN, diameter, MIN_BASIN, {
		basinFound = basin ~= nil,
		failures = basin and {} or { "no FountainBasin part" },
	})

	-- FOUNTAIN_TIERS ----------------------------------------------------------
	local tiers = {}
	for _, part in ipairs(parts) do
		local tier = attr(part, data.fountainTierAttribute)
		if type(tier) == "number" then
			tiers[tier] = (tiers[tier] or 0) + 1
		end
	end
	local tierCount = (tiers[1] or 0) + (tiers[2] or 0)
	local tierPass = tiers[1] == 1 and tiers[2] == 1 and tierCount == 2
	emit("FOUNTAIN_TIERS", tierPass, tierCount, 2, { tier1 = tiers[1] or 0, tier2 = tiers[2] or 0 })

	-- FLAG_CLEAN --------------------------------------------------------------
	local flagPairs = {}
	local stray = 0
	for _, part in ipairs(parts) do
		if attr(part, data.buntingFlagAttribute) == true then
			local pairId = attr(part, data.flagPairAttribute)
			if type(pairId) ~= "string" then
				stray += 1
			else
				flagPairs[pairId] = flagPairs[pairId] or {}
				table.insert(flagPairs[pairId], part)
			end
		end
	end
	local pairCount = 0
	for _ in pairs(flagPairs) do
		pairCount += 1
	end
	local expectedFlags = 0
	if type(data.BUNTING) == "table" and type(data.BUNTING.flagCount) == "number" then
		expectedFlags = data.BUNTING.flagCount
	end
	local badFlags, badDetails = stray, {}
	if stray > 0 then
		badDetails[#badDetails + 1] = stray .. " flagged parts without a pair id"
	end
	local function flat(part)
		local size = part.Size
		return math.min(size.X, size.Y, size.Z) <= FLAT_MAX and size.X > FLAT_MAX and size.Y > FLAT_MAX
	end
	for pairId, panels in pairs(flagPairs) do
		local bad = #panels ~= 2
		local red, white = nil, nil
		if not bad then
			for _, panel in ipairs(panels) do
				local colour = attr(panel, data.flagPanelAttribute)
				if colour == "red" then
					red = panel
				elseif colour == "white" then
					white = panel
				end
			end
			bad = red == nil or white == nil
		end
		if not bad then
			bad = not flat(red) or not flat(white)
		end
		if not bad then
			local normalRed = red.CFrame:VectorToWorldSpace(Vector3.new(0, 0, 1)).Unit
			local normalWhite = white.CFrame:VectorToWorldSpace(Vector3.new(0, 0, 1)).Unit
			bad = math.abs(normalRed:Dot(normalWhite)) < AXIS_DOT
		end
		if not bad then
			local dx = red.Position.X - white.Position.X
			local dz = red.Position.Z - white.Position.Z
			bad = red.Position.Y - white.Position.Y <= CENTRE_TOL or math.sqrt(dx * dx + dz * dz) > CENTRE_TOL
		end
		if bad then
			badFlags += 1
			badDetails[#badDetails + 1] = tostring(pairId)
		end
	end
	if expectedFlags <= 0 or pairCount ~= expectedFlags then
		badFlags += math.abs(expectedFlags - pairCount)
		badDetails[#badDetails + 1] = "pairs " .. pairCount .. " expected " .. expectedFlags
	end
	emit("FLAG_CLEAN", expectedFlags > 0 and badFlags == 0, badFlags, 0, {
		pairs = pairCount,
		expected = expectedFlags,
		failures = badDetails,
	})

	-- PLAZA_WALKABLE ----------------------------------------------------------
	local blocked, reasons = 0, {}
	local originX, originZ, halfW, halfD = 0, 0, data.DRESSED.width / 2, data.DRESSED.depth / 2
	local okSpec, mapSpec = pcall(function()
		return require(game:GetService("ServerScriptService").Server.World.MapSpec)
	end)
	if okSpec and type(mapSpec) == "table" and type(mapSpec.PLAZA) == "table" then
		originX, originZ = mapSpec.PLAZA.x, mapSpec.PLAZA.z
		halfW, halfD = mapSpec.PLAZA.width / 2, mapSpec.PLAZA.depth / 2
	end
	local ringRadius = type(data.FOUNTAIN) == "table" and data.FOUNTAIN.ringRadius or nil
	local lanes = type(data.lanes) == "function" and data.lanes() or nil
	local gap = type(data.LANE_GAP) == "number" and data.LANE_GAP or 0
	if type(ringRadius) ~= "number" or type(lanes) ~= "table" or #lanes ~= 4 then
		blocked = 1
		reasons[#reasons + 1] = "ring radius or four lane recipes missing"
	else
		for _, lane in ipairs(lanes) do
			local box = {
				minX = lane.x - lane.width / 2,
				maxX = lane.x + lane.width / 2,
				minZ = lane.z - lane.depth / 2,
				maxZ = lane.z + lane.depth / 2,
			}
			local inner = if lane.name == "east" or lane.name == "west"
				then math.abs(lane.x) - lane.width / 2
				else math.abs(lane.z) - lane.depth / 2
			local corridor = { minX = box.minX, maxX = box.maxX, minZ = box.minZ, maxZ = box.maxZ }
			if lane.name == "north" then
				corridor.minZ = -halfD
			elseif lane.name == "south" then
				corridor.maxZ = halfD
			elseif lane.name == "east" then
				corridor.maxX = halfW
			elseif lane.name == "west" then
				corridor.minX = -halfW
			end
			if inner > ringRadius + gap + OVERLAP_TOL then
				blocked += 1
				reasons[#reasons + 1] = lane.name .. " lane stops short of the ring"
			else
				for _, part in ipairs(parts) do
					if overlaps(partBox(part, originX, originZ), corridor) then
						blocked += 1
						reasons[#reasons + 1] = lane.name .. " blocked by " .. part:GetFullName()
						break
					end
				end
			end
		end
	end
	emit("PLAZA_WALKABLE", blocked == 0, blocked, 0, {
		lanes = type(lanes) == "table" and #lanes or 0,
		partsChecked = #parts,
		failures = reasons,
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
	emit("FOUNTAIN_SIZE", false, 0, MIN_BASIN, reason)
	emit("FOUNTAIN_TIERS", false, 0, 2, reason)
	emit("FLAG_CLEAN", false, 1, 0, reason)
	emit("PLAZA_WALKABLE", false, 1, 0, reason)
end

return results
