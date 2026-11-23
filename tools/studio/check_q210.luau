--!nocheck
-- check_q210: WORK_QUEUE item 210, self-contained SERVER-VM Studio check on the DEFAULT look.
-- Paste this whole file into execute_luau in a FRESH Play session. It stages nothing, calls no
-- LookDev API, reads only the live DataModel, prints the CHECK lines verbatim and restores every
-- temporary mutation before it returns. No harness require, no place save, no visual verdict.
--
--   WARUNG_SEATS   <count> 4  >=4 visible BaseParts tagged WarungDress==true carrying
--                              WarungDressKind=="seat". buildWarung tags the two existing benches
--                              plus two new low stools; the serving table is kind=="table".
--   LANE_CLEAR     <hits>  0  item-208/209 rule: visible tagged WarungDress parts must not overlap
--                              any of the six 6-stud hub door lanes (tol 0.05).
--   NOT_INTERACTIVE <count> 0 tagged WarungDress parts (self or descendants) carrying a
--                              ProximityPrompt or ClickDetector. SCOPE: only NEW dressing parts;
--                              the pre-existing WarungPrompt on the untagged Warung table is
--                              item-shipped behaviour that predates this item and is excluded.
--
-- CALIBRATION ANCHORS: hide every tagged seat (Transparency=1, exact save/restore) ->
-- CAL_WARUNG_SEATS_FAIL; inject a visible 2x2x2 tagged Part in the Warung door lane ->
-- CAL_LANE_CLEAR_FAIL; inject a ProximityPrompt into one tagged part -> CAL_NOT_INTERACTIVE_FAIL.
-- Every probe is destroyed and every saved value restored before return.

local CHECK_NAMES = {
	"WARUNG_SEATS",
	"LANE_CLEAR",
	"NOT_INTERACTIVE",
	"CAL_WARUNG_SEATS_FAIL",
	"CAL_LANE_CLEAR_FAIL",
	"CAL_NOT_INTERACTIVE_FAIL",
}
local CHECK_TARGETS = {
	WARUNG_SEATS = 4,
	LANE_CLEAR = 0,
	NOT_INTERACTIVE = 0,
	CAL_WARUNG_SEATS_FAIL = 1,
	CAL_LANE_CLEAR_FAIL = 1,
	CAL_NOT_INTERACTIVE_FAIL = 1,
}
local MIN_SEATS = 4
local OVERLAP_TOL = 0.05

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

local function emitOnce(name, passed, measured, target, detail)
	if not results.byName[name] then
		emit(name, passed, measured, target, detail)
	end
end

local function attr(instance, key)
	local ok, value = pcall(function()
		return instance:GetAttribute(key)
	end)
	return ok and value or nil
end

local function aabb(part)
	local ok, box = pcall(function()
		local cf, size = part.CFrame, part.Size
		local ex = cf:VectorToWorldSpace(Vector3.new(size.X / 2, 0, 0))
		local ey = cf:VectorToWorldSpace(Vector3.new(0, size.Y / 2, 0))
		local ez = cf:VectorToWorldSpace(Vector3.new(0, 0, size.Z / 2))
		local function axis(a, b, c)
			return {
				x = cf.Position.X + a.X + b.X + c.X,
				y = cf.Position.Y + a.Y + b.Y + c.Y,
				z = cf.Position.Z + a.Z + b.Z + c.Z,
			}
		end
		local minX, minY, minZ = math.huge, math.huge, math.huge
		local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
		for _, sx in ipairs({ -1, 1 }) do
			for _, sy in ipairs({ -1, 1 }) do
				for _, sz in ipairs({ -1, 1 }) do
					local p = axis(
						Vector3.new(ex.X * sx, ex.Y * sx, ex.Z * sx),
						Vector3.new(ey.X * sy, ey.Y * sy, ey.Z * sy),
						Vector3.new(ez.X * sz, ez.Y * sz, ez.Z * sz)
					)
					minX, maxX = math.min(minX, p.x), math.max(maxX, p.x)
					minY, maxY = math.min(minY, p.y), math.max(maxY, p.y)
					minZ, maxZ = math.min(minZ, p.z), math.max(maxZ, p.z)
				end
			end
		end
		return {
			minX = minX,
			maxX = maxX,
			minY = minY,
			maxY = maxY,
			minZ = minZ,
			maxZ = maxZ,
			centreX = (minX + maxX) / 2,
			centreZ = (minZ + maxZ) / 2,
		}
	end)
	return ok and box or nil
end

local function rectHit(box, rect)
	return math.min(box.maxX, rect.maxX) - math.max(box.minX, rect.minX) > OVERLAP_TOL
		and math.min(box.maxZ, rect.maxZ) - math.max(box.minZ, rect.minZ) > OVERLAP_TOL
end

-- Verbatim check_r10_template hubLanes(): six 6-stud lanes, local x +/-3, z depth/2..depth/2+24.
local function hubLanes(MapSpec)
	local lanes, errors = {}, 0
	if type(MapSpec.HUB_ORDER) ~= "table" or type(MapSpec.hubPoint) ~= "function" then
		errors = 1
		return lanes, errors
	end
	for _, key in ipairs(MapSpec.HUB_ORDER) do
		local hub = MapSpec.hub(key)
		if not hub then
			errors = errors + 1
		else
			local minX, minZ, maxX, maxZ = math.huge, math.huge, -math.huge, -math.huge
			for _, corner in ipairs({
				{ -3, hub.depth / 2 },
				{ 3, hub.depth / 2 },
				{ -3, hub.depth / 2 + 24 },
				{ 3, hub.depth / 2 + 24 },
			}) do
				local okPoint, x, z = pcall(function()
					return MapSpec.hubPoint(hub, corner[1], corner[2])
				end)
				if not okPoint or type(x) ~= "number" or type(z) ~= "number" then
					errors = errors + 1
					break
				end
				minX, maxX = math.min(minX, x), math.max(maxX, x)
				minZ, maxZ = math.min(minZ, z), math.max(maxZ, z)
			end
			lanes[#lanes + 1] = { minX = minX, maxX = maxX, minZ = minZ, maxZ = maxZ }
		end
	end
	return lanes, errors
end

local function visible(part)
	local ok, value = pcall(function()
		return part.Transparency < 1
	end)
	return ok and value
end

local function visibleSeats(parts)
	local count = 0
	for _, part in ipairs(parts) do
		if attr(part, "WarungDressKind") == "seat" and visible(part) then
			count += 1
		end
	end
	return count
end

local function laneViolations(parts, lanes)
	local hits, blockers = 0, {}
	for _, part in ipairs(parts) do
		if visible(part) then
			local box = aabb(part)
			if box then
				for _, lane in ipairs(lanes) do
					if rectHit(box, lane) then
						hits += 1
						blockers[#blockers + 1] = part.Name
						break
					end
				end
			end
		end
	end
	return hits, blockers
end

local function hasInteraction(part)
	local ok, found = pcall(function()
		if part:IsA("ProximityPrompt") or part:IsA("ClickDetector") then
			return true
		end
		for _, child in ipairs(part:GetDescendants()) do
			if child:IsA("ProximityPrompt") or child:IsA("ClickDetector") then
				return true
			end
		end
		return false
	end)
	return ok and found == true
end

local function interactiveCount(parts)
	local count = 0
	for _, part in ipairs(parts) do
		if hasInteraction(part) then
			count += 1
		end
	end
	return count
end

local injected = {}
local function destroyInjected()
	for index = #injected, 1, -1 do
		pcall(function()
			injected[index]:Destroy()
		end)
		injected[index] = nil
	end
end

local ok, err = pcall(function()
	local MapSpec = require(game:GetService("ServerScriptService"):WaitForChild("Server").World.MapSpec)
	if type(MapSpec.hub) ~= "function" or type(MapSpec.hubPoint) ~= "function" then
		error("MapSpec API missing")
	end
	local hub = MapSpec.hub("warung")
	if not hub or type(hub.model) ~= "string" then
		error("MapSpec hub 'warung' missing")
	end
	local lanes, laneErrors = hubLanes(MapSpec)

	local dress = {}
	for _, inst in ipairs(workspace:GetDescendants()) do
		pcall(function()
			if inst:IsA("BasePart") and attr(inst, "WarungDress") == true then
				dress[#dress + 1] = inst
			end
		end)
	end

	local seats = visibleSeats(dress)
	emit("WARUNG_SEATS", seats >= MIN_SEATS, seats, MIN_SEATS, { tagged = #dress })

	local violations, blockers = laneViolations(dress, lanes)
	emit("LANE_CLEAR", #lanes == 6 and laneErrors == 0 and violations == 0, violations, 0, {
		lanes = #lanes,
		blockers = blockers,
	})

	local interactive = interactiveCount(dress)
	emit("NOT_INTERACTIVE", interactive == 0, interactive, 0, {
		tagged = #dress,
		scope = "WarungDress parts only; pre-existing WarungPrompt on the untagged table is excluded",
	})

	-- CAL_WARUNG_SEATS_FAIL: hide every tagged seat, re-count, restore exact Transparency.
	local saved = {}
	for _, part in ipairs(dress) do
		pcall(function()
			if attr(part, "WarungDressKind") == "seat" then
				saved[part] = part.Transparency
				part.Transparency = 1
			end
		end)
	end
	local okCount, calSeats = pcall(visibleSeats, dress)
	for part, value in pairs(saved) do
		pcall(function()
			part.Transparency = value
		end)
	end
	local seatsFailed = okCount and calSeats == 0 and seats >= MIN_SEATS
	emit("CAL_WARUNG_SEATS_FAIL", seatsFailed, seatsFailed and 1 or 0, 1, {
		seatsBefore = seats,
		seatsWhileHidden = if okCount then calSeats else -1,
	})

	-- CAL_LANE_CLEAR_FAIL: inject a visible 2x2x2 tagged Part in the Warung door lane, re-measure,
	-- then destroy it. The warung door lane is local x +/-3, z depth/2..depth/2+24.
	local groundY = type(MapSpec.GROUND_Y) == "number" and MapSpec.GROUND_Y or 0.5
	local ix, iz = MapSpec.hubPoint(hub, 0, hub.depth / 2 + 12)
	local probe = Instance.new("Part")
	probe.Name = "Q210_LANE_CALIBRATION"
	probe.Size = Vector3.new(2, 2, 2)
	probe.Position = Vector3.new(ix, groundY + 1, iz)
	probe.Anchored = true
	probe.CanCollide = false
	probe.CastShadow = false
	probe:SetAttribute("WarungDress", true)
	probe:SetAttribute("WarungDressKind", "seat")
	probe.Parent = workspace
	injected[#injected + 1] = probe
	local calHits, calBlockers = laneViolations(dress, lanes)
	local addedHits = laneViolations({ probe }, lanes)
	calHits += addedHits
	local laneFailed = calHits >= 1 and violations == 0
	emit("CAL_LANE_CLEAR_FAIL", laneFailed, laneFailed and 1 or 0, 1, {
		hitsBefore = violations,
		hitsWithProbe = calHits,
		blockers = calBlockers,
	})
	destroyInjected()

	-- CAL_NOT_INTERACTIVE_FAIL: inject one ProximityPrompt into a tagged part, re-count, destroy.
	local target = dress[1]
	local promptOk, prompt = pcall(function()
		if not target then
			error("no WarungDress part to inject into")
		end
		local p = Instance.new("ProximityPrompt")
		p.Name = "Q210_INTERACTION_CALIBRATION"
		p.Parent = target
		return p
	end)
	if promptOk and prompt then
		injected[#injected + 1] = prompt
	end
	local calInteractive = promptOk and interactiveCount(dress) or -1
	destroyInjected()
	local interactiveFailed = promptOk and calInteractive >= 1 and interactive == 0
	emit("CAL_NOT_INTERACTIVE_FAIL", interactiveFailed, interactiveFailed and 1 or 0, 1, {
		interactiveBefore = interactive,
		interactiveWithPrompt = calInteractive,
	})
end)

-- No staging to restore; only the injected probes and the seat Transparency are temporary, and both
-- are restored inside the pcall above. destroyInjected() is the belt-and-braces path on error.
destroyInjected()

if not ok then
	local reason = { reason = "item 210 audit error: " .. tostring(err) }
	for _, name in ipairs(CHECK_NAMES) do
		emitOnce(name, false, 0, CHECK_TARGETS[name], reason)
	end
end

return results
