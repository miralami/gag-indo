--!nocheck
-- check_r10_template: SERVER-VM Studio check for WORK_QUEUE P-refill items 228-237.
-- The main session substitutes __ID__ with one candidate id, pastes the whole file into
-- execute_luau in a fresh Play session, and saves the printed CHECK lines as CHECK_<item>.txt.
-- It stages ONLY the one candidate via enableAdditive, reads live staged Parts, and calls
-- disableAll() in cleanup even on error. No place save, no visual verdict, no weakened checks.

local ID = "__ID__"

local NAMES = {
	balai_r10 = { "BALAI_PARTS", "BALAI_FIT", "BALAI_SIGN", "NO_GAMEPLAY", "PATH_REACH", "PERF_BUDGET" },
	hub_canopy_r10 = { "HUB_CANOPY", "CANOPY_SIZE", "GATE_CLEAR", "NO_PINES", "PERF_BUDGET" },
	blocks_shrubs_r10 = { "SHRUB_COUNT", "SHRUB_VARIETY", "NO_CUBE_SHRUBS", "WALKABLE", "PERF_BUDGET" },
	pasar_roof_r10 = { "RED_ROOF", "HUB_FIT", "ROOF_SLOPE", "FACADE_STRAY" },
	warung_cluster_r10 = { "WARUNG_STALLS", "WARUNG_TABLES", "LANE_CLEAR", "NO_FLOATERS", "NOT_INTERACTIVE" },
	polisi_roof_r10 = { "BLUE_ROOF", "HUB_FIT", "CAMERA_CLEAR", "FACADE_STRAY" },
	pakrt_roof_r10 = { "PAKRT_ROOF_COLOR", "CAP_ON_RIDGE", "FACADE_STRAY" },
	sawah_gubuk_r10 = { "GUBUK_TERRACE2", "GUBUK_ON_GROUND", "SAWAH_TOPS", "PERF_BUDGET" },
	plots_mailbox_r10 = { "MAILBOX", "MAILBOX_SIGN", "GATE_CLEAR", "NO_FLOATERS" },
	river_palms_r10 = { "RIVER_PALMS", "PALM_TALL", "WATER_CLEAR", "NO_PINES", "PERF_BUDGET" },
}

local results = { id = ID, checks = {}, byName = {} }
local function emit(name, passed, measured, target, detail)
	local line = "CHECK " .. name .. " " .. (passed and "PASS" or "FAIL") .. " " .. tostring(measured) .. " " .. tostring(target)
	results.checks[#results.checks + 1] = line
	results.byName[name] = { line = line, passed = passed, measured = measured, target = target, detail = detail }
	print(line)
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
		return { minX = minX, maxX = maxX, minY = minY, maxY = maxY, minZ = minZ, maxZ = maxZ,
			centreX = (minX + maxX) / 2, centreZ = (minZ + maxZ) / 2 }
	end)
	return ok and box or nil
end

local function rectHit(box, rect)
	return math.min(box.maxX, rect.maxX) - math.max(box.minX, rect.minX) > 0.05
		and math.min(box.maxZ, rect.maxZ) - math.max(box.minZ, rect.minZ) > 0.05
end

local review = nil
local ok, err = pcall(function()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	review = require(shared:WaitForChild("LookDevReview"))
	local Data = require(shared:WaitForChild("ModelMapCanonicalR10"))
	local Strings = require(shared:WaitForChild("Strings"))
	local MapSpec = require(game:GetService("ServerScriptService"):WaitForChild("Server").World.MapSpec)
	local Game = require(shared:WaitForChild("Config").Game)
	local PlotsData = require(shared:WaitForChild("ModelMapPlotsR8"))

	local enabled, why = review.enableAdditive(ID, game)
	if not enabled then
		error("enableAdditive(" .. ID .. ") failed: " .. tostring(why))
	end
	local folder = workspace:FindFirstChild(Data.folderName(ID))
	if not folder then
		error("staging folder missing: " .. Data.folderName(ID))
	end

	local all = folder:GetDescendants()
	local parts, kinds = {}, {}
	for _, inst in ipairs(all) do
		if attr(inst, "LookDevStage") == ID and inst:IsA("BasePart") then
			parts[#parts + 1] = inst
			kinds[attr(inst, "Kind") or inst.Name] = (kinds[attr(inst, "Kind") or inst.Name] or 0) + 1
		end
	end
	local groundY = type(MapSpec.GROUND_Y) == "number" and MapSpec.GROUND_Y or 0.5

	local function roadRects()
		local rects = {}
		if type(MapSpec.roadArms) == "function" and type(MapSpec.roadContinuations) == "function" then
			for _, list in ipairs({ MapSpec.roadArms(), MapSpec.roadContinuations() }) do
				for _, r in ipairs(list) do
					rects[#rects + 1] = { minX = r.x - r.sx / 2, maxX = r.x + r.sx / 2,
						minZ = r.z - r.sz / 2, maxZ = r.z + r.sz / 2 }
				end
			end
		end
		return rects
	end

	local function hubLanes()
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
					{ -3, hub.depth / 2 }, { 3, hub.depth / 2 },
					{ -3, hub.depth / 2 + 24 }, { 3, hub.depth / 2 + 24 },
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

	local function gateCentres()
		local out = {}
		if type(Game.plotCenter) ~= "function" then return out end
		for i = 1, (Game.plotCount or 10) do
			local okG, gx, gz = pcall(function()
				local x, z = Game.plotCenter(i)
				local yaw = math.deg(math.atan2(x, z))
				return Data.rotatePoint(x, z, yaw, 0, -((PlotsData.PLOT_DEPTH or 34) / 2 + 3))
			end)
			if okG then out[#out + 1] = { x = gx, z = gz } end
		end
		return out
	end

	local function countNearGates(box, gates, limit)
		local bad = 0
		for _, g in ipairs(gates) do
			local dx, dz = box.centreX - g.x, box.centreZ - g.z
			if dx * dx + dz * dz < limit * limit then bad = bad + 1 end
		end
		return bad
	end

	local perf = 0
	for _, inst in ipairs(workspace:GetDescendants()) do
		local isPart = pcall(function() return inst:IsA("BasePart") end)
		if isPart and inst:IsA("BasePart") then
			local p = inst.CFrame.Position
			if p.X * p.X + p.Z * p.Z <= 10000 then perf = perf + 1 end
		end
	end

	if ID == "balai_r10" then
		emit("BALAI_PARTS", #parts >= 20, #parts, 20)
		local slot = Data.balaiSlot(MapSpec.FUTURE_SLOTS and MapSpec.FUTURE_SLOTS[1] or nil)
		local outside = 0
		for _, part in ipairs(parts) do
			local b = aabb(part)
			if b and (b.minX < slot.x - slot.width / 2 - 0.5 or b.maxX > slot.x + slot.width / 2 + 0.5
				or b.minZ < slot.z - slot.depth / 2 - 0.5 or b.maxZ > slot.z + slot.depth / 2 + 0.5) then
				outside = outside + 1
			end
		end
		emit("BALAI_FIT", outside == 0, outside, 0)
		local signed = 0
		for _, part in ipairs(parts) do
			if attr(part, "Kind") == "balai_sign" then
				local key = attr(part, "StringsKey")
				local idText, enText = attr(part, "IdText"), attr(part, "EnText")
				local raw = type(Strings.raw) == "table" and Strings.raw[key] or nil
				if type(key) == "string" and type(idText) == "string" and type(enText) == "string"
					and type(raw) == "table" and type(raw.id) == "string" and type(raw.en) == "string" then
					signed = signed + 1
				end
			end
		end
		emit("BALAI_SIGN", signed >= 1, signed, 1)
		local interactive = 0
		for _, inst in ipairs(all) do
			local isInteractive = pcall(function()
				return inst:IsA("ProximityPrompt") or inst:IsA("ClickDetector")
			end)
			if isInteractive and (inst:IsA("ProximityPrompt") or inst:IsA("ClickDetector")) then
				interactive = interactive + 1
			end
		end
		emit("NO_GAMEPLAY", interactive == 0, interactive, 0)
		local lanes, laneErrors = hubLanes()
		local blocked = laneErrors
		for _, part in ipairs(parts) do
			local b = aabb(part)
			if b then for _, lane in ipairs(lanes) do if rectHit(b, lane) then blocked = blocked + 1 end end end
		end
		emit("PATH_REACH", blocked == 0, blocked, 0)
		emit("PERF_BUDGET", perf <= 500, perf, 500)

	elseif ID == "hub_canopy_r10" then
		local hubs = {}
		for _, hub in ipairs(MapSpec.HUBS or {}) do hubs[hub.key] = { x = hub.x, z = hub.z, crowns = {}, trunks = 0 } end
		local badSize, pine = 0, 0
		for _, part in ipairs(parts) do
			local kind = attr(part, "Kind")
			local name = part.Name or ""
			if string.find(string.lower(name), "pine", 1, true) then pine = pine + 1 end
			local b = aabb(part)
			if kind == "canopy_crown" then
				local span = b and (b.maxX - b.minX) or 0
				if span < 10 or span > 12 then badSize = badSize + 1 end
			end
			local best, bestD = nil, math.huge
			for key, hub in pairs(hubs) do
				local pos = part.CFrame.Position
				local d = (pos.X - hub.x) ^ 2 + (pos.Z - hub.z) ^ 2
				if d < bestD then best, bestD = key, d end
			end
			if best and bestD < 60 * 60 then
				if kind == "canopy_crown" then hubs[best].crowns[#hubs[best].crowns + 1] = part end
				if kind == "canopy_trunk" then hubs[best].trunks = hubs[best].trunks + 1 end
			end
		end
		local covered, gates = 0, gateCentres()
		local nearGate = 0
		for _, hub in pairs(hubs) do
			if #hub.crowns >= 2 and #hub.crowns <= 3 and hub.trunks >= 2 then covered = covered + 1 end
			for _, crown in ipairs(hub.crowns) do
				nearGate = nearGate + countNearGates(aabb(crown), gates, 6)
			end
		end
		emit("HUB_CANOPY", covered == 6, covered, 6)
		emit("CANOPY_SIZE", badSize == 0, badSize, 0)
		emit("GATE_CLEAR", nearGate == 0, nearGate, 0)
		emit("NO_PINES", pine == 0, pine, 0)
		emit("PERF_BUDGET", perf <= 500, perf, 500)

	elseif ID == "blocks_shrubs_r10" then
		local shrubs, species = 0, {}
		local cube = 0
		for _, part in ipairs(parts) do
			if attr(part, "Kind") == "shrub" then
				shrubs = shrubs + 1
				local sp = attr(part, "Species")
				if type(sp) == "string" then species[sp] = true end
				if part.Shape ~= Enum.PartType.Ball and part.Shape ~= Enum.PartType.Cylinder then cube = cube + 1 end
			end
		end
		local variety = 0 for _ in pairs(species) do variety = variety + 1 end
		emit("SHRUB_COUNT", shrubs >= 60, shrubs, 60)
		emit("SHRUB_VARIETY", variety >= 3, variety, 3)
		emit("NO_CUBE_SHRUBS", cube == 0, cube, 0)
		local rects, onRoad = roadRects(), 0
		for _, part in ipairs(parts) do
			local b = aabb(part)
			if b then for _, r in ipairs(rects) do if rectHit(b, r) then onRoad = onRoad + 1 end end end
		end
		emit("WALKABLE", onRoad == 0, onRoad, 0)
		emit("PERF_BUDGET", perf <= 500, perf, 500)

	elseif ID == "pasar_roof_r10" or ID == "polisi_roof_r10" then
		local key = ID == "pasar_roof_r10" and "pasar" or "polisi"
		local hub = MapSpec.hub(key)
		local bounds = MapSpec.hubBounds(hub)
		local coloured, tilted, stray = 0, 0, 0
		for _, part in ipairs(parts) do
			local c, b = part.Color, aabb(part)
			if ID == "pasar_roof_r10" then
				if c.R > c.G * 2 and c.R > c.B * 2 then coloured = coloured + 1 end
			else
				if c.B > c.R * 1.5 and c.B > c.G * 1.3 then coloured = coloured + 1 end
			end
			if attr(part, "Kind") == "roof_panel" then
				local up = part.CFrame:VectorToWorldSpace(Vector3.new(0, 1, 0))
				if math.abs(up.Y) < 0.999 then tilted = tilted + 1 end
			end
			if b and (b.minX < bounds.minX - 4 or b.maxX > bounds.maxX + 4
				or b.minZ < bounds.minZ - 4 or b.maxZ > bounds.maxZ + 4) then stray = stray + 1 end
		end
		if ID == "pasar_roof_r10" then
			emit("RED_ROOF", coloured >= 2, coloured, 2)
		else
			emit("BLUE_ROOF", coloured >= 2, coloured, 2)
		end
		emit("HUB_FIT", stray == 0, stray, 0)
		if ID == "pasar_roof_r10" then emit("ROOF_SLOPE", tilted >= 2, tilted, 2) end
		emit("FACADE_STRAY", stray == 0, stray, 0)
		if ID == "polisi_roof_r10" then
			local Cameras = require(shared:WaitForChild("ReviewCameras"))
			local cam = Cameras.get("hub_polisi")
			local clear = 1
			if cam and type(cam.position) == "table" and type(cam.lookAt) == "table" then
				local origin = Vector3.new(cam.position[1], cam.position[2], cam.position[3])
				local look = Vector3.new(cam.lookAt[1], cam.lookAt[2], cam.lookAt[3])
				local dir = look - origin
				local params = RaycastParams.new()
				params.FilterType = Enum.RaycastFilterType.Blacklist
				params.FilterDescendantsInstances = {}
				local hit = workspace:Raycast(origin, dir.Unit * 6, params)
				if hit then clear = 0 end
			end
			emit("CAMERA_CLEAR", clear == 1, 1 - clear, 0)
		end

	elseif ID == "warung_cluster_r10" then
		local stalls, tables, floating, interactive = 0, 0, 0, 0
		for _, part in ipairs(parts) do
			local kind = attr(part, "Kind")
			if kind == "stall_tin_roof" then stalls = stalls + 1 end
			if kind == "table_top" then tables = tables + 1 end
			if kind == "stall_post" or kind == "table_leg" then
				local b = aabb(part)
				if b and b.minY > groundY + 0.6 then floating = floating + 1 end
			end
		end
		for _, inst in ipairs(all) do
			local isInteractive = pcall(function()
				return inst:IsA("ProximityPrompt") or inst:IsA("ClickDetector")
			end)
			if isInteractive and (inst:IsA("ProximityPrompt") or inst:IsA("ClickDetector")) then
				interactive = interactive + 1
			end
		end
		local lanes, laneErrors = hubLanes()
		local blocked = laneErrors
		for _, part in ipairs(parts) do
			local b = aabb(part)
			if b then for _, lane in ipairs(lanes) do if rectHit(b, lane) then blocked = blocked + 1 end end end
		end
		emit("WARUNG_STALLS", stalls >= 3, stalls, 3)
		emit("WARUNG_TABLES", tables >= 2, tables, 2)
		emit("LANE_CLEAR", blocked == 0, blocked, 0)
		emit("NO_FLOATERS", floating == 0, floating, 0)
		emit("NOT_INTERACTIVE", interactive == 0, interactive, 0)

	elseif ID == "pakrt_roof_r10" then
		local hub = MapSpec.hub("pakrt")
		local bounds = MapSpec.hubBounds(hub)
		local tinted, capsTinted, stray = 0, 0, 0
		for _, inst in ipairs(workspace:GetDescendants()) do
			local isPart = pcall(function() return inst:IsA("BasePart") end)
			if isPart and inst:IsA("BasePart") then
				local pos = inst.CFrame.Position
				if pos.X >= bounds.minX - 4 and pos.X <= bounds.maxX + 4
					and pos.Z >= bounds.minZ - 4 and pos.Z <= bounds.maxZ + 4
					and pos.Y > groundY + 4 then
					local name = inst.Name or ""
					local isCap = string.find(name, "Cap", 1, true) ~= nil or string.find(name, "Ridge", 1, true) ~= nil
					local isRoof = string.find(name, "Roof", 1, true) ~= nil
					local c = inst.Color
					local r255, g255, b255 = math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5)
					local yellowOrange = r255 > 200 and g255 >= 100 and g255 <= 190 and b255 < 90
					if isRoof and not isCap and yellowOrange then tinted = tinted + 1 end
					if isCap and yellowOrange then capsTinted = capsTinted + 1 end
				end
			end
		end
		for _, part in ipairs(parts) do
			local b = aabb(part)
			if b and (b.minX < bounds.minX - 4 or b.maxX > bounds.maxX + 4
				or b.minZ < bounds.minZ - 4 or b.maxZ > bounds.maxZ + 4) then stray = stray + 1 end
		end
		emit("PAKRT_ROOF_COLOR", tinted >= 1, tinted, 1)
		emit("CAP_ON_RIDGE", capsTinted == 0, capsTinted, 0)
		emit("FACADE_STRAY", stray == 0, stray, 0)

	elseif ID == "sawah_gubuk_r10" then
		local huts, floor = 0, nil
		for _, inst in ipairs(all) do
			if attr(inst, "LookDevStage") == ID and attr(inst, "Kind") == "gubuk" then huts = huts + 1 end
		end
		for _, part in ipairs(parts) do
			if attr(part, "Kind") == "gubuk_floor" then floor = part end
		end
		local deviation = math.huge
		if floor then
			local b = aabb(floor)
			local top = type(MapSpec.TERRACES) == "table" and MapSpec.TERRACES[2] and MapSpec.TERRACES[2].top or nil
			if b and type(top) == "number" then deviation = math.abs(b.minY - top) end
		end
		local outside = 0
		if floor and type(MapSpec.TERRACES) == "table" and MapSpec.TERRACES[2] then
			local t, b = MapSpec.TERRACES[2], aabb(floor)
			if b and (b.centreZ < t.z0 - 2 or b.centreZ > t.z1 + 2) then outside = 1 end
		end
		emit("GUBUK_TERRACE2", huts == 1, huts, 1)
		emit("GUBUK_ON_GROUND", deviation <= 0.3, deviation, 0.3)
		emit("SAWAH_TOPS", outside == 0, outside, 0)
		emit("PERF_BUDGET", perf <= 500, perf, 500)

	elseif ID == "plots_mailbox_r10" then
		local boxes, signs, floating = 0, 0, 0
		for _, part in ipairs(parts) do
			local kind = attr(part, "Kind")
			if kind == "mailbox" then boxes = boxes + 1 end
			if kind == "mailbox_sign" then
				local key = attr(part, "StringsKey")
				local raw = type(Strings.raw) == "table" and Strings.raw[key] or nil
				if type(attr(part, "IdText")) == "string" and type(attr(part, "EnText")) == "string"
					and type(raw) == "table" and type(raw.id) == "string" and type(raw.en) == "string" then
					signs = signs + 1
				end
			end
			if kind == "mailbox_post" then
				local b = aabb(part)
				if b and b.minY > groundY + 0.6 then floating = floating + 1 end
			end
		end
		local gates = gateCentres()
		local nearGate = 0
		for _, part in ipairs(parts) do
			nearGate = nearGate + countNearGates(aabb(part), gates, 6)
		end
		local plotCount = Game.plotCount or 10
		emit("MAILBOX", boxes >= plotCount, boxes, plotCount)
		emit("MAILBOX_SIGN", signs >= plotCount, signs, plotCount)
		emit("GATE_CLEAR", nearGate == 0, nearGate, 0)
		emit("NO_FLOATERS", floating == 0, floating, 0)

	elseif ID == "river_palms_r10" then
		local trunks, inWater, pine = 0, 0, 0
		local treeParts = {}
		for _, part in ipairs(parts) do
			local kind, name = attr(part, "Kind"), part.Name or ""
			if string.find(string.lower(name), "pine", 1, true) then pine = pine + 1 end
			local b = aabb(part)
			if b then
				if kind == "palm_trunk" then trunks = trunks + 1 end
				if kind == "palm_trunk" or kind == "palm_frond" then
					treeParts[#treeParts + 1] = { box = b, kind = kind }
				end
				if MapSpec.riverCentreZ then
					local centre = MapSpec.riverCentreZ(b.centreX)
					if math.abs(b.centreZ - centre) < 14 then inWater = inWater + 1 end
				end
			end
		end
		-- Height is full palm top above ground (trunk 13, canopy ~15.7), not trunk length.
		-- Each tree = one trunk plus fronds within 5 studs XZ; a tree is tall when its top >= 14.
		local tall = 0
		for _, tp in ipairs(treeParts) do
			if tp.kind == "palm_trunk" then
				local top = tp.box.maxY
				for _, other in ipairs(treeParts) do
					local dx, dz = other.box.centreX - tp.box.centreX, other.box.centreZ - tp.box.centreZ
					if dx * dx + dz * dz <= 25 and other.box.maxY > top then top = other.box.maxY end
				end
				if top - groundY >= 14 then tall = tall + 1 end
			end
		end
		emit("RIVER_PALMS", trunks >= 20, trunks, 20)
		emit("PALM_TALL", tall >= 20, tall, 20)
		emit("WATER_CLEAR", inWater == 0, inWater, 0)
		emit("NO_PINES", pine == 0, pine, 0)
		emit("PERF_BUDGET", perf <= 500, perf, 500)
	end
end)

pcall(function()
	if review then review.disableAll() end
end)

if not ok then
	local reason = "audit error: " .. tostring(err)
	for _, name in ipairs(NAMES[ID] or {}) do emit(name, false, 0, 0, reason) end
end

return results
