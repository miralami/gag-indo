--!nocheck
-- check_q208: WORK_QUEUE item 208, self-contained SERVER-VM Studio check on the DEFAULT look.
-- Paste this whole file into execute_luau in a FRESH Play session. It stages nothing, calls no
-- LookDev API, reads only the live DataModel, prints the CHECK lines verbatim and restores every
-- temporary mutation before it returns. No harness require, no place save, no visual verdict.
--
--   PASAR_PAD    <count> 1   >=1 workspace Part with attribute PasarPad==true AND its world AABB
--                             covers every StallCounter AABB (XZ footprint) in the Pasar hub model.
--   PASAR_PROPS  <count> 30  >=30 workspace Parts with attribute PasarProp==true.
--   LANE_CLEAR   <hits>   0   visible (Transparency<1) tagged pads/props overlapping any of the six
--                             hub door lanes (check_r10_template hubLanes rule, tolerance 0.05).
--
-- STALL SELECTION RULE: only Parts named "StallCounter" that are descendants of the Model named
-- MapSpec.hub("pasar").model ("Pasar") under workspace.World. buildPasar creates exactly five, at
-- local x -22/-11/0/11/22, z -6; no other hub builds that name. Coverage is XZ only: the pad is a
-- ground slab, so it cannot enclose a counter in Y.
--
-- CALIBRATION ANCHORS: hide all pads (Transparency=1), re-measure coverage -> CAL_PASAR_PAD_FAIL;
-- count props with an all-excluding filter -> CAL_PASAR_PROPS_FAIL; inject a visible 2x2x2 Part in
-- the Pasar door lane -> CAL_LANE_CLEAR_FAIL. Pads are restored and the injection destroyed.

local CHECK_NAMES = {
	"PASAR_PAD",
	"PASAR_PROPS",
	"LANE_CLEAR",
	"CAL_PASAR_PAD_FAIL",
	"CAL_PASAR_PROPS_FAIL",
	"CAL_LANE_CLEAR_FAIL",
}
local CHECK_TARGETS = {
	PASAR_PAD = 1,
	PASAR_PROPS = 30,
	LANE_CLEAR = 0,
	CAL_PASAR_PAD_FAIL = 1,
	CAL_PASAR_PROPS_FAIL = 1,
	CAL_LANE_CLEAR_FAIL = 1,
}
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

local function visibleCount(parts)
	local count = 0
	for _, part in ipairs(parts) do
		if visible(part) then
			count += 1
		end
	end
	return count
end

local function coveredStalls(pads, stalls)
	local covered, names = 0, {}
	for index, stall in ipairs(stalls) do
		local sb = aabb(stall)
		local hit = false
		for _, pad in ipairs(pads) do
			if sb and visible(pad) then
				local pb = aabb(pad)
				if
					pb
					and pb.minX - OVERLAP_TOL <= sb.minX
					and pb.maxX + OVERLAP_TOL >= sb.maxX
					and pb.minZ - OVERLAP_TOL <= sb.minZ
					and pb.maxZ + OVERLAP_TOL >= sb.maxZ
				then
					hit = true
					break
				end
			end
		end
		if hit then
			covered += 1
			names[#names + 1] = "StallCounter[" .. index .. "]"
		end
	end
	return covered, names
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
	local hub = MapSpec.hub("pasar")
	if not hub or type(hub.model) ~= "string" then
		error("MapSpec hub 'pasar' missing")
	end
	local lanes, laneErrors = hubLanes(MapSpec)

	local pads, props = {}, {}
	for _, inst in ipairs(workspace:GetDescendants()) do
		pcall(function()
			if inst:IsA("BasePart") then
				if attr(inst, "PasarPad") == true then
					pads[#pads + 1] = inst
				end
				if attr(inst, "PasarProp") == true then
					props[#props + 1] = inst
				end
			end
		end)
	end

	-- Stall selection rule (see header): StallCounter descendants of workspace.World.<hub.model>.
	local worldFolder = workspace:FindFirstChild("World")
	local pasarModel = worldFolder and worldFolder:FindFirstChild(hub.model)
	if not pasarModel then
		for _, inst in ipairs(workspace:GetDescendants()) do
			if inst:IsA("Model") and inst.Name == hub.model then
				pasarModel = inst
				break
			end
		end
	end
	local stalls = {}
	if pasarModel then
		for _, inst in ipairs(pasarModel:GetDescendants()) do
			pcall(function()
				if inst:IsA("BasePart") and inst.Name == "StallCounter" then
					stalls[#stalls + 1] = inst
				end
			end)
		end
	end
	table.sort(stalls, function(a, b)
		local okA, ax = pcall(function()
			return a.Position.X
		end)
		local okB, bx = pcall(function()
			return b.Position.X
		end)
		return (okA and ax or 0) < (okB and bx or 0)
	end)

	local covered, coveredNames = coveredStalls(pads, stalls)
	print("PASAR_PAD_STALLS " .. covered .. "/" .. #stalls .. " " .. table.concat(coveredNames, ","))
	emit("PASAR_PAD", #pads >= 1 and #stalls > 0 and covered == #stalls and laneErrors == 0, #pads, 1, {
		stalls = #stalls,
		covered = covered,
		coveredNames = coveredNames,
		laneErrors = laneErrors,
	})

	local crateCount, basketCount, sackCount = 0, 0, 0
	for _, prop in ipairs(props) do
		local name = prop.Name
		if string.find(name, "Crate", 1, true) then
			crateCount += 1
		elseif string.find(name, "Basket", 1, true) then
			basketCount += 1
		elseif string.find(name, "Sack", 1, true) then
			sackCount += 1
		end
	end
	emit("PASAR_PROPS", #props >= 30, #props, 30, {
		crates = crateCount,
		baskets = basketCount,
		sacks = sackCount,
	})

	local marked = {}
	for _, pad in ipairs(pads) do
		marked[#marked + 1] = pad
	end
	for _, prop in ipairs(props) do
		marked[#marked + 1] = prop
	end
	local violations, blockers = laneViolations(marked, lanes)
	emit("LANE_CLEAR", #lanes == 6 and laneErrors == 0 and violations == 0, violations, 0, {
		lanes = #lanes,
		blockers = blockers,
	})

	-- CAL_PASAR_PAD_FAIL: hide every pad, re-measure, then restore the exact original Transparency.
	local saved = {}
	for _, pad in ipairs(pads) do
		pcall(function()
			saved[pad] = pad.Transparency
			pad.Transparency = 1
		end)
	end
	local calCovered = coveredStalls(pads, stalls)
	for pad, value in pairs(saved) do
		pcall(function()
			pad.Transparency = value
		end)
	end
	local padFailed = #pads > 0 and #stalls > 0 and calCovered == 0 and covered == #stalls
	emit("CAL_PASAR_PAD_FAIL", padFailed, padFailed and 1 or 0, 1, {
		coveredBefore = covered,
		coveredWhileHidden = calCovered,
		stalls = #stalls,
	})

	-- CAL_PASAR_PROPS_FAIL: hide every tagged prop, re-count visible ones, restore exact Transparency.
	-- Both the hide and the measurement are wrapped, and every saved value is restored under pcall
	-- even when either throws, so no mutation leaks into later checks or into the place.
	local visibleBefore = visibleCount(props)
	local savedPropTransparency = {}
	local hiddenOk = pcall(function()
		for _, prop in ipairs(props) do
			pcall(function()
				savedPropTransparency[prop] = prop.Transparency
				prop.Transparency = 1
			end)
		end
	end)
	local countedOk, visibleWhileHidden = pcall(function()
		return visibleCount(props)
	end)
	for prop, value in pairs(savedPropTransparency) do
		pcall(function()
			prop.Transparency = value
		end)
	end
	local propsFailed = hiddenOk and countedOk and #props >= 30 and visibleBefore >= 30 and visibleWhileHidden == 0
	emit("CAL_PASAR_PROPS_FAIL", propsFailed, propsFailed and 1 or 0, 1, {
		propsBefore = #props,
		visibleBefore = visibleBefore,
		visibleWhileHidden = if countedOk then visibleWhileHidden else -1,
	})

	-- CAL_LANE_CLEAR_FAIL: inject a visible 2x2x2 Part in the Pasar door lane, re-measure, destroy.
	local groundY = type(MapSpec.GROUND_Y) == "number" and MapSpec.GROUND_Y or 0.5
	local ix, iz = MapSpec.hubPoint(hub, 0, hub.depth / 2 + 12)
	local probe = Instance.new("Part")
	probe.Name = "Q208_LANE_CALIBRATION"
	probe.Size = Vector3.new(2, 2, 2)
	probe.Position = Vector3.new(ix, groundY + 1, iz)
	probe.Anchored = true
	probe.CanCollide = false
	probe.CastShadow = false
	probe:SetAttribute("PasarProp", true)
	probe.Parent = workspace
	injected[#injected + 1] = probe
	local calMarked = {}
	for _, part in ipairs(marked) do
		calMarked[#calMarked + 1] = part
	end
	calMarked[#calMarked + 1] = probe
	local calHits, calBlockers = laneViolations(calMarked, lanes)
	local laneFailed = calHits >= 1 and violations == 0
	emit("CAL_LANE_CLEAR_FAIL", laneFailed, laneFailed and 1 or 0, 1, {
		hitsBefore = violations,
		hitsWithProbe = calHits,
		blockers = calBlockers,
	})
	destroyInjected()
end)

-- No staging to restore; only the injected probe and the pad Transparency are temporary, and both
-- are restored inside the pcall above. destroyInjected() is the belt-and-braces path on error.
destroyInjected()

if not ok then
	local reason = { reason = "item 208 audit error: " .. tostring(err) }
	for _, name in ipairs(CHECK_NAMES) do
		emitOnce(name, false, 0, CHECK_TARGETS[name], reason)
	end
end

return results
