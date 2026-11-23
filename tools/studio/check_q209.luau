--!nocheck
-- check_q209: WORK_QUEUE item 209, self-contained SERVER-VM Studio check on the DEFAULT look.
-- Paste this whole file into execute_luau in a FRESH Play session. It stages nothing, calls no
-- LookDev API, reads only the live DataModel, prints the CHECK lines verbatim and restores every
-- temporary mutation before it returns. No harness require, no place save, no visual verdict.
--
--   STRIPE_VALUE  <value> 0.6  >=30 Parts tagged PasarStripe==true; HSV V = max(R,G,B) of the LIVE
--                              Color3 of every stripe (the minimum across stripes is reported),
--                              red/white/blue all seen by nearest item-179 palette colour within
--                              12 per channel, and V >= 0.6. Same definition as check_p179.
--   PASAR_SIGN    <count> 1    exactly one Part tagged PasarSign==true, carrying a Strings key
--                              attribute whose id and en variants are both non-empty strings.
--   LANE_CLEAR    <hits>  0    item-208 rule: visible tagged PasarPad/Prop/Stripe/Sign parts must
--                              not overlap any of the six 6-stud hub door lanes (tol 0.05).
--
-- CALIBRATION ANCHORS: grey out every stripe Color -> CAL_STRIPE_VALUE_FAIL; point the board at a
-- nonexistent Strings key -> CAL_PASAR_SIGN_FAIL; inject a visible 2x2x2 Part in the Pasar lane ->
-- CAL_LANE_CLEAR_FAIL. Every mutation is saved and restored exactly; the probe is destroyed.

local CHECK_NAMES = {
	"STRIPE_VALUE",
	"PASAR_SIGN",
	"LANE_CLEAR",
	"CAL_STRIPE_VALUE_FAIL",
	"CAL_PASAR_SIGN_FAIL",
	"CAL_LANE_CLEAR_FAIL",
}
local CHECK_TARGETS = {
	STRIPE_VALUE = 0.6,
	PASAR_SIGN = 1,
	LANE_CLEAR = 0,
	CAL_STRIPE_VALUE_FAIL = 1,
	CAL_PASAR_SIGN_FAIL = 1,
	CAL_LANE_CLEAR_FAIL = 1,
}
local PALETTE = {
	red = { 248, 76, 64 },
	white = { 255, 252, 244 },
	blue = { 72, 148, 236 },
}
local MIN_STRIPE_VALUE = 0.6
local MIN_STRIPES = 30
local COLOUR_TOL = 12
local OVERLAP_TOL = 0.05
local VALUE_FORMAT = "%.4f"
local STRINGS_KEY_ATTR = "StringsKey"
local MISSING_KEY = "q209_missing_strings_key"

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
		local minX, minY, minZ = math.huge, math.huge, math.huge
		local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
		for _, sx in ipairs({ -1, 1 }) do
			for _, sy in ipairs({ -1, 1 }) do
				for _, sz in ipairs({ -1, 1 }) do
					local x = cf.Position.X + ex.X * sx + ey.X * sy + ez.X * sz
					local y = cf.Position.Y + ex.Y * sx + ey.Y * sy + ez.Y * sz
					local z = cf.Position.Z + ex.Z * sx + ey.Z * sy + ez.Z * sz
					minX, maxX = math.min(minX, x), math.max(maxX, x)
					minY, maxY = math.min(minY, y), math.max(maxY, y)
					minZ, maxZ = math.min(minZ, z), math.max(maxZ, z)
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

-- HSV V of the LIVE colour, byte-for-byte check_p179's stripeValue.
local function stripeValue(part)
	local ok, colour = pcall(function()
		return part.Color
	end)
	if not ok or not colour then
		return 0
	end
	return math.max(colour.R, colour.G, colour.B)
end

local function classify(colour)
	local bestName, bestDiff = nil, math.huge
	local r, g, b = colour.R * 255, colour.G * 255, colour.B * 255
	for name, rgb in pairs(PALETTE) do
		local diff = math.max(math.abs(r - rgb[1]), math.abs(g - rgb[2]), math.abs(b - rgb[3]))
		if diff < bestDiff then
			bestName, bestDiff = name, diff
		end
	end
	return bestName, bestDiff
end

local function measureStripes(stripes)
	local count, minValue = 0, math.huge
	local seen = { red = false, white = false, blue = false }
	local dim, wrong = {}, {}
	for _, part in ipairs(stripes) do
		count += 1
		local value = stripeValue(part)
		minValue = math.min(minValue, value)
		if value < MIN_STRIPE_VALUE then
			dim[#dim + 1] = part.Name .. string.format(" V=" .. VALUE_FORMAT, value)
		end
		local okColour, colour = pcall(function()
			return part.Color
		end)
		if okColour and colour then
			local name, diff = classify(colour)
			if name and diff <= COLOUR_TOL then
				seen[name] = true
			else
				wrong[#wrong + 1] = part.Name .. "=" .. tostring(name) .. " d=" .. string.format("%.1f", diff)
			end
		end
	end
	local value = if minValue == math.huge then 0 else minValue
	local passed = count >= MIN_STRIPES and value >= MIN_STRIPE_VALUE and seen.red and seen.white and seen.blue
	return value, passed, count, seen, dim, wrong
end

local function signState(signs, Strings)
	local board = signs[1]
	local key = board and attr(board, STRINGS_KEY_ATTR) or nil
	local entry = nil
	if Strings and type(key) == "string" then
		local ok, raw = pcall(function()
			return Strings.raw[key]
		end)
		if ok then
			entry = raw
		end
	end
	local id = entry and entry.id or nil
	local en = entry and entry.en or nil
	local passed = #signs == 1 and type(id) == "string" and #id > 0 and type(en) == "string" and #en > 0
	return passed, key, id, en
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
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	local Strings = require(shared:WaitForChild("Strings"))
	local lanes, laneErrors = hubLanes(MapSpec)

	local pads, props, stripes, signs = {}, {}, {}, {}
	for _, inst in ipairs(workspace:GetDescendants()) do
		pcall(function()
			if inst:IsA("BasePart") then
				if attr(inst, "PasarPad") == true then
					pads[#pads + 1] = inst
				end
				if attr(inst, "PasarProp") == true then
					props[#props + 1] = inst
				end
				if attr(inst, "PasarStripe") == true then
					stripes[#stripes + 1] = inst
				end
				if attr(inst, "PasarSign") == true then
					signs[#signs + 1] = inst
				end
			end
		end)
	end

	-- STRIPE_VALUE ------------------------------------------------------------
	local value, stripePass, stripeCount, seen, dim, wrong = measureStripes(stripes)
	emit("STRIPE_VALUE", stripePass, string.format(VALUE_FORMAT, value), MIN_STRIPE_VALUE, {
		stripes = stripeCount,
		minStripes = MIN_STRIPES,
		value = value,
		seen = seen,
		dim = dim,
		wrong = wrong,
	})

	-- PASAR_SIGN --------------------------------------------------------------
	local signPass, signKey, signId, signEn = signState(signs, Strings)
	print("PASAR_SIGN_STRINGS key=" .. tostring(signKey) .. " id=" .. tostring(signId) .. " en=" .. tostring(signEn))
	emit("PASAR_SIGN", signPass, #signs, 1, {
		key = signKey,
		id = signId,
		en = signEn,
	})

	-- LANE_CLEAR (item 208 rule, now including stripes and the sign) -----------
	local marked = {}
	for _, list in ipairs({ pads, props, stripes, signs }) do
		for _, part in ipairs(list) do
			marked[#marked + 1] = part
		end
	end
	local violations, blockers = laneViolations(marked, lanes)
	emit("LANE_CLEAR", #lanes == 6 and laneErrors == 0 and violations == 0, violations, 0, {
		lanes = #lanes,
		laneErrors = laneErrors,
		blockers = blockers,
		marked = #marked,
	})

	-- CAL_STRIPE_VALUE_FAIL: grey out every stripe, re-measure, restore exact Color3.
	do
		local saved = {}
		for _, part in ipairs(stripes) do
			pcall(function()
				saved[part] = part.Color
				part.Color = Color3.new(0.25, 0.25, 0.25)
			end)
		end
		local calValue, calPass = measureStripes(stripes)
		for part, colour in pairs(saved) do
			pcall(function()
				part.Color = colour
			end)
		end
		local afterValue = measureStripes(stripes)
		local failed = stripePass and not calPass and calValue < MIN_STRIPE_VALUE and afterValue >= MIN_STRIPE_VALUE
		emit("CAL_STRIPE_VALUE_FAIL", failed, failed and 1 or 0, 1, {
			before = value,
			during = calValue,
			after = afterValue,
			stripes = #stripes,
		})
	end

	-- CAL_PASAR_SIGN_FAIL: point the board at a missing key, re-measure, restore the exact key.
	do
		local board = signs[1]
		local savedKey = board and attr(board, STRINGS_KEY_ATTR) or nil
		local setOk = false
		if board then
			setOk = pcall(function()
				board:SetAttribute(STRINGS_KEY_ATTR, MISSING_KEY)
			end)
		end
		local calOk, calKey, calId, calEn = false, nil, nil, nil
		if setOk then
			calOk, calKey, calId, calEn = signState(signs, Strings)
			calOk = not calOk
		end
		if board then
			pcall(function()
				board:SetAttribute(STRINGS_KEY_ATTR, savedKey)
			end)
		end
		local restoredKey = board and attr(board, STRINGS_KEY_ATTR) or nil
		local afterOk = signState(signs, Strings)
		local failed = signPass and setOk and calOk and afterOk and restoredKey == savedKey
		emit("CAL_PASAR_SIGN_FAIL", failed, failed and 1 or 0, 1, {
			keyBefore = savedKey,
			keyDuring = calKey,
			idDuring = calId,
			enDuring = calEn,
			keyAfter = restoredKey,
		})
	end

	-- CAL_LANE_CLEAR_FAIL: inject a visible 2x2x2 Part in the Pasar door lane, re-measure, destroy.
	do
		local hub = MapSpec.hub("pasar")
		local groundY = type(MapSpec.GROUND_Y) == "number" and MapSpec.GROUND_Y or 0.5
		local ix, iz = MapSpec.hubPoint(hub, 0, hub.depth / 2 + 12)
		local probe = Instance.new("Part")
		probe.Name = "Q209_LANE_CALIBRATION"
		probe.Size = Vector3.new(2, 2, 2)
		probe.Position = Vector3.new(ix, groundY + 1, iz)
		probe.Anchored = true
		probe.CanCollide = false
		probe.CastShadow = false
		probe:SetAttribute("PasarProp", true)
		probe.Parent = workspace
		injected[#injected + 1] = probe
		local calHits = laneViolations({ probe }, lanes)
		local failed = calHits >= 1 and violations == 0
		emit("CAL_LANE_CLEAR_FAIL", failed, failed and 1 or 0, 1, {
			hitsBefore = violations,
			hitsWithProbe = calHits,
		})
	end
	destroyInjected()
end)

-- No staging to restore; only stripe Color, the board's Strings key and the injected probe were
-- temporary, and all three are restored inside the pcall above. destroyInjected() is the backup.
destroyInjected()

if not ok then
	local reason = { reason = "item 209 audit error: " .. tostring(err) }
	for _, name in ipairs(CHECK_NAMES) do
		local measured = if name == "STRIPE_VALUE" then string.format(VALUE_FORMAT, 0) else 0
		emitOnce(name, false, measured, CHECK_TARGETS[name], reason)
	end
end

return results
