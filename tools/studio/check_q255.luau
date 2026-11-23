--!nocheck
-- check_q255: WORK_QUEUE item 255, self-contained SERVER-VM Studio check. Paste the whole file into
-- execute_luau in a fresh Play session. Stages one candidate at a time, measures SUBJECT_COVERAGE
-- (>= 0.30), CAMERA_GRASS (4 / 3 / 12) and HERO_CLEAR (0 non-subject opaque hits over 25 sampled
-- subject points) from its hero_* camera, prints verbatim CHECK lines and restores on every path.
--
--   SC255_<ID>   staged candidate visible fraction >= 0.30 from hero_<id>
--   CG255_<ID>   0 CAMERA_GRASS failures from hero_<id>
--   HC255_<ID>   0 non-subject opaque ray hits from the eye to 25 subject points
--
-- CALIBRATION ANCHORS (single lines; change injected state, never the targets):
--   * CAL_HERO_CLEAR_BLOCK_255: one opaque Part 2 studs along the first pair's eye->subject ray.
--   * CAL_CAMERA_GRASS_OLD_255: the old low eye (grade + 1 stud) must fail CAMERA_GRASS.
-- No screen_capture, no place save. return results.

local results = { checks = {}, byName = {} }

local PAIRS = {
	{ id = "balai_r10", camera = "hero_balai_r10" },
	{ id = "hub_canopy_r10", camera = "hero_hub_canopy_r10" },
	{ id = "blocks_shrubs_r10", camera = "hero_blocks_shrubs_r10" },
	{ id = "pasar_roof_r10", camera = "hero_pasar_roof_r10" },
	{ id = "warung_cluster_r10", camera = "hero_warung_cluster_r10" },
	{ id = "polisi_roof_r10", camera = "hero_polisi_roof_r10" },
	{ id = "pakrt_roof_r10", camera = "hero_pakrt_roof_r10" },
	{ id = "sawah_gubuk_r10", camera = "hero_sawah_gubuk_r10" },
	{ id = "plots_mailbox_r10", camera = "hero_plots_mailbox_r10" },
	{ id = "river_palms_r10", camera = "hero_river_palms_r10" },
	{ id = "meadow_r10", camera = "hero_meadow_r10" },
	{ id = "ground_variation_r10", camera = "hero_ground_variation_r10" },
	{ id = "paths_curved_r10", camera = "hero_paths_curved_r10" },
	{ id = "horizon_fill_r10", camera = "hero_horizon_fill_r10" },
	{ id = "mountains_r10", camera = "hero_mountains_r10" },
	{ id = "hill_dressing_r10", camera = "hero_hill_dressing_r10" },
	{ id = "kampung_r10", camera = "hero_kampung_r10" },
	{ id = "road_fence_r10", camera = "hero_road_fence_r10" },
	{ id = "lamps_r10", camera = "hero_lamps_r10" },
	{ id = "signposts_r10", camera = "hero_signposts_r10" },
	{ id = "bamboo_bridge_r10", camera = "hero_bamboo_bridge_r10" },
	{ id = "furrows_r10", camera = "hero_furrows_r10" },
	{ id = "crop_stages_r10", camera = "hero_crop_stages_r10" },
	{ id = "ditch_water_r10", camera = "hero_ditch_water_r10" },
	{ id = "default_warung", camera = "hero_default_warung" },
	{ id = "river_foam_212", camera = "hero_river_foam_212" },
	{ id = "terrace_walls_214", camera = "hero_terrace_walls_214" },
	{ id = "lamps_r10_night", camera = "hero_lamps_r10_night" },
}

-- These subjects are default-look parts (or LookDevCanonicalR10 staging), not LookDevReview ids.
-- Mirror LookDevStage onto the live parts for coverage.measure, then restore the exact prior value.
local SPECIALS = {
	river_foam_212 = { tag = "RiverFoam", kindAttr = "RiverFoamKind", kindValue = "foam" },
	terrace_walls_214 = { tag = "TerraceWall", kindAttr = "TerraceWall", kindValue = true },
	default_warung = { stage = "warung_cluster_r10" },
	-- The night variant is a camera clock preset, not a review candidate: stage the day lamps parts.
	lamps_r10_night = { stage = "lamps_r10" },
	-- Canonical R10 roof tint: no LookDevStage parts, mirror Pak RT hub roof panels honestly.
	pakrt_roof_r10 = { pakrtRoof = true },
}

local CAL_CLEAR = "CAL_HERO_CLEAR_BLOCK_255"
local CAL_GRASS = "CAL_CAMERA_GRASS_OLD_255"
local CHECK_NAMES = {}
local function label(id)
	local cleaned = id:gsub("[^%w]", "_")
	return cleaned:upper()
end
for _, pair in ipairs(PAIRS) do
	CHECK_NAMES[#CHECK_NAMES + 1] = "SC255_" .. label(pair.id)
	CHECK_NAMES[#CHECK_NAMES + 1] = "CG255_" .. label(pair.id)
	CHECK_NAMES[#CHECK_NAMES + 1] = "HC255_" .. label(pair.id)
end
CHECK_NAMES[#CHECK_NAMES + 1] = CAL_CLEAR
CHECK_NAMES[#CHECK_NAMES + 1] = CAL_GRASS

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

local function shown(value)
	return string.format("%.4f", tonumber(value) or 0)
end

local tagged = {}
local function tagSpecial(measureId, pairId, shared, review)
	local rule = SPECIALS[pairId]
	if not rule then
		return 0
	end
	local candidates = {}
	if rule.tag then
		local okTagged, service = pcall(function()
			return game:GetService("CollectionService")
		end)
		if okTagged and service then
			local okGet, found = pcall(function()
				return service:GetTagged(rule.tag)
			end)
			if okGet and type(found) == "table" then
				for _, instance in ipairs(found) do
					candidates[#candidates + 1] = instance
				end
			end
		end
		if #candidates == 0 then
			local okDesc, descendants = pcall(function()
				return workspace:GetDescendants()
			end)
			if okDesc and type(descendants) == "table" then
				for _, instance in ipairs(descendants) do
					local okKind, kind = pcall(function()
						return instance:GetAttribute(rule.kindAttr)
					end)
					if okKind and kind == rule.kindValue then
						candidates[#candidates + 1] = instance
					end
				end
			end
		end
	elseif rule.stage then
		local folderName = rule.stage
		local okData, Data = pcall(function()
			return require(shared:WaitForChild("ModelMapCanonicalR10"))
		end)
		if okData and type(Data) == "table" and type(Data.folderName) == "function" then
			local okName, named = pcall(Data.folderName, rule.stage)
			if okName and type(named) == "string" then
				folderName = named
			end
		end
		local okFolder, folder = pcall(function()
			return workspace:FindFirstChild(folderName)
		end)
		if okFolder and folder then
			local okDesc, descendants = pcall(function()
				return folder:GetDescendants()
			end)
			if okDesc and type(descendants) == "table" then
				for _, instance in ipairs(descendants) do
					candidates[#candidates + 1] = instance
				end
			end
		end
	elseif rule.pakrtRoof then
		local okMap, MapSpec = pcall(function()
			return require(game:GetService("ServerScriptService"):WaitForChild("Server").World.MapSpec)
		end)
		if
			okMap
			and type(MapSpec) == "table"
			and type(MapSpec.hubBounds) == "function"
			and type(MapSpec.hub) == "function"
		then
			local hub = MapSpec.hub("pakrt")
			if hub then
				local bounds = MapSpec.hubBounds(hub)
				local groundY = if type(MapSpec.GROUND_Y) == "number" then MapSpec.GROUND_Y else 0.5
				local pad = (MapSpec.S or 2) * 2
				local okDesc, descendants = pcall(function()
					return workspace:GetDescendants()
				end)
				if okDesc and type(descendants) == "table" then
					for _, instance in ipairs(descendants) do
						local okPart, isPart = pcall(function()
							return instance:IsA("BasePart")
						end)
						if okPart and isPart then
							local okPos, pos = pcall(function()
								return instance.Position
							end)
							if
								okPos
								and pos
								and pos.X >= bounds.minX - pad
								and pos.X <= bounds.maxX + pad
								and pos.Z >= bounds.minZ - pad
								and pos.Z <= bounds.maxZ + pad
								and pos.Y > groundY + 4
							then
								candidates[#candidates + 1] = instance
							end
						end
					end
				end
			end
		end
	end
	local count = 0
	for _, instance in ipairs(candidates) do
		local okPart, isPart = pcall(function()
			return instance:IsA("BasePart")
		end)
		if okPart and isPart then
			local okGet, saved = pcall(function()
				return instance:GetAttribute("LookDevStage")
			end)
			local okSet = pcall(function()
				instance:SetAttribute("LookDevStage", measureId)
			end)
			if okGet and okSet then
				tagged[#tagged + 1] = { part = instance, saved = saved }
				count += 1
			end
		end
	end
	return count
end

local function restoreTagged()
	for index = #tagged, 1, -1 do
		local entry = tagged[index]
		pcall(function()
			entry.part:SetAttribute("LookDevStage", entry.saved)
		end)
		tagged[index] = nil
	end
end

local review, blocker = nil, nil
local scPass, cgPass, hcPass, calPass, calChecked = 0, 0, 0, 0, 0

local ok, err = pcall(function()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	local coverage = require(shared:WaitForChild("SubjectCoverage"))
	local Grass = require(shared:WaitForChild("CameraGrass"))
	review = require(shared:WaitForChild("LookDevReview"))
	local Cameras = require(shared:WaitForChild("ReviewCameras"))
	local terrain = workspace:FindFirstChildOfClass("Terrain")
	if
		type(coverage) ~= "table"
		or type(coverage.measure) ~= "function"
		or type(Grass) ~= "table"
		or type(Grass.evaluate) ~= "function"
		or type(Grass.regionFor) ~= "function"
		or type(Grass.column) ~= "function"
		or type(review) ~= "table"
		or type(review.enableAdditive) ~= "function"
		or type(review.disableAll) ~= "function"
		or type(Cameras) ~= "table"
		or type(Cameras.get) ~= "function"
		or not terrain
	then
		error("SubjectCoverage / CameraGrass / LookDevReview / ReviewCameras / Terrain API missing")
	end

	local mapOk, MapSpec = pcall(function()
		return require(game:GetService("ServerScriptService"):WaitForChild("Server").World.MapSpec)
	end)
	if not mapOk or type(MapSpec) ~= "table" or type(MapSpec.GROUND_Y) ~= "number" then
		MapSpec = nil
	end

	-- Any pair id that is not a real LookDevReview candidate must stage a real candidate. SPECIALS
	-- maps the known aliases; a *_night camera preset falls back to its day id.
	local function stageIdFor(id: string): string
		local rule = SPECIALS[id]
		if rule and rule.stage then
			return rule.stage
		end
		if type(review.paths) == "table" and not review.paths[id] then
			local day = id:match("^(.-)_night$")
			if day and review.paths[day] then
				return day
			end
		end
		return id
	end

	local cache = {}
	local function readColumn(x, z)
		local x0, y0, z0, x1, y1, z1 = Grass.regionFor(x, z)
		local key = x0 .. ":" .. z0
		if cache[key] then
			return cache[key]
		end
		local region = Region3.new(Vector3.new(x0, y0, z0), Vector3.new(x1, y1, z1))
		local okRead, materials, occupancies = pcall(function()
			return terrain:ReadVoxels(region, Grass.VOXEL)
		end)
		local column
		if okRead and type(materials) == "table" and type(occupancies) == "table" then
			column = Grass.column(materials, occupancies, x, z)
		else
			column = { ok = false, reason = "ReadVoxels failed: " .. tostring(occupancies) }
		end
		cache[key] = column
		return column
	end

	local players = game:GetService("Players")
	local includeFilter
	local okFilter, filter = pcall(function()
		return Enum.RaycastFilterType.Include or Enum.RaycastFilterType.Whitelist
	end)
	if okFilter and filter then
		includeFilter = filter
	end

	local function collectParts(id)
		local parts = {}
		local okDesc, descendants = pcall(function()
			return workspace:GetDescendants()
		end)
		if not okDesc or type(descendants) ~= "table" then
			return parts
		end
		for _, instance in ipairs(descendants) do
			local okPart, isPart = pcall(function()
				return instance:IsA("BasePart")
			end)
			if okPart and isPart then
				local okTag, tag = pcall(function()
					return instance:GetAttribute("LookDevStage")
				end)
				if okTag and tag == id then
					parts[#parts + 1] = instance
				end
			end
		end
		return parts
	end

	local function aabb(part)
		local okSize, size = pcall(function()
			return part.Size
		end)
		local okFrame, frame = pcall(function()
			return part.CFrame
		end)
		if not okSize or not okFrame or not size or not frame then
			return nil
		end
		local lo = Vector3.new(math.huge, math.huge, math.huge)
		local hi = Vector3.new(-math.huge, -math.huge, -math.huge)
		for sx = -1, 1, 2 do
			for sy = -1, 1, 2 do
				for sz = -1, 1, 2 do
					local corner =
						frame:PointToWorldSpace(Vector3.new(sx * size.X / 2, sy * size.Y / 2, sz * size.Z / 2))
					lo = Vector3.new(math.min(lo.X, corner.X), math.min(lo.Y, corner.Y), math.min(lo.Z, corner.Z))
					hi = Vector3.new(math.max(hi.X, corner.X), math.max(hi.Y, corner.Y), math.max(hi.Z, corner.Z))
				end
			end
		end
		return lo, hi
	end

	local function unionAabb(parts)
		local lo, hi
		for _, part in ipairs(parts) do
			local partLo, partHi = aabb(part)
			if partLo then
				if not lo then
					lo, hi = partLo, partHi
				else
					lo = Vector3.new(math.min(lo.X, partLo.X), math.min(lo.Y, partLo.Y), math.min(lo.Z, partLo.Z))
					hi = Vector3.new(math.max(hi.X, partHi.X), math.max(hi.Y, partHi.Y), math.max(hi.Z, partHi.Z))
				end
			end
		end
		return lo, hi
	end

	local function component(vector, name: string): number
		if name == "X" then
			return vector.X
		end
		if name == "Y" then
			return vector.Y
		end
		return vector.Z
	end

	-- HERO_CLEAR ends its rays on the visible SURFACE of the subject, never on an arbitrary point
	-- inside an AABB: interior points are legitimately crossed by the subject's own far face or by
	-- a sibling part and are not "a prop between the eye and the subject".
	local function surfaceSamples(eye, parts, subjectParams, count: number)
		local surface = {}
		local lo, hi = unionAabb(parts)
		if not lo then
			return surface
		end
		local centre = Vector3.new((lo.X + hi.X) / 2, (lo.Y + hi.Y) / 2, (lo.Z + hi.Z) / 2)
		local toward = centre - eye
		local ax, ay, az = math.abs(toward.X), math.abs(toward.Y), math.abs(toward.Z)
		local axis = "X"
		if ay >= ax and ay >= az then
			axis = "Y"
		elseif az >= ax and az >= ay then
			axis = "Z"
		end
		local uAxis, vAxis = "X", "Y"
		if axis == "X" then
			uAxis, vAxis = "Y", "Z"
		elseif axis == "Y" then
			uAxis, vAxis = "X", "Z"
		end
		local along = component(toward, axis)
		local face = if along > 0 then component(lo, axis) else component(hi, axis)
		for index = 1, count do
			local part = parts[((index - 1) % #parts) + 1]
			local partLo, partHi = aabb(part)
			local centreHit
			if partLo then
				local partCentre =
					Vector3.new((partLo.X + partHi.X) / 2, (partLo.Y + partHi.Y) / 2, (partLo.Z + partHi.Z) / 2)
				local delta = partCentre - eye
				if delta.Magnitude > 0 then
					local okHit, hit = pcall(function()
						return workspace:Raycast(eye, delta.Unit * delta.Magnitude, subjectParams)
					end)
					if okHit and hit and hit.Instance then
						centreHit = hit
					end
				end
			end
			if centreHit then
				local fu = (((index - 1) % 5) + 0.5) / 5
				local fv = ((math.floor((index - 1) / 5) % 5) + 0.5) / 5
				local u = component(lo, uAxis) + (component(hi, uAxis) - component(lo, uAxis)) * fu
				local v = component(lo, vAxis) + (component(hi, vAxis) - component(lo, vAxis)) * fv
				local coords = { X = 0, Y = 0, Z = 0 }
				coords[axis] = face
				coords[uAxis] = u
				coords[vAxis] = v
				local gridPoint = Vector3.new(coords.X, coords.Y, coords.Z)
				local point = centreHit.Position
				local gridDelta = gridPoint - eye
				if gridDelta.Magnitude > 0 then
					local okHit, hit = pcall(function()
						return workspace:Raycast(eye, gridDelta.Unit * gridDelta.Magnitude, subjectParams)
					end)
					if okHit and hit and hit.Instance then
						point = hit.Position
					end
				end
				surface[index] = point
			end
		end
		return surface
	end

	local function firstSurfaceTarget(camera, parts)
		local eye = Vector3.new(camera.position[1], camera.position[2], camera.position[3])
		local subjectParams = RaycastParams.new()
		pcall(function()
			if includeFilter then
				subjectParams.FilterType = includeFilter
				subjectParams.FilterDescendantsInstances = parts
			end
			subjectParams.IgnoreWater = true
		end)
		return surfaceSamples(eye, parts, subjectParams, 1)[1]
	end

	local function heroClear(camera, parts, injected)
		if not camera or #parts == 0 then
			return 1, { reason = "no staged candidate parts" }
		end
		local eye = Vector3.new(camera.position[1], camera.position[2], camera.position[3])
		local subjectSet, characterSet, blockers = {}, {}, {}
		for _, part in ipairs(parts) do
			subjectSet[part] = true
		end
		for _, player in ipairs(players:GetPlayers()) do
			local character = player.Character
			if character then
				characterSet[character] = true
				for _, descendant in ipairs(character:GetDescendants()) do
					characterSet[descendant] = true
				end
			end
		end
		local okDesc, descendants = pcall(function()
			return workspace:GetDescendants()
		end)
		if okDesc and type(descendants) == "table" then
			for _, instance in ipairs(descendants) do
				local okPart, isPart = pcall(function()
					return instance:IsA("BasePart")
				end)
				local okTerrain, isTerrain = pcall(function()
					return instance:IsA("Terrain") or instance.ClassName == "Terrain"
				end)
				if
					okPart
					and isPart
					and not (okTerrain and isTerrain)
					and not subjectSet[instance]
					and not characterSet[instance]
				then
					blockers[#blockers + 1] = instance
				end
			end
		end
		for _, instance in ipairs(injected or {}) do
			blockers[#blockers + 1] = instance
		end
		local params = RaycastParams.new()
		pcall(function()
			if includeFilter then
				params.FilterType = includeFilter
				params.FilterDescendantsInstances = blockers
			else
				params.FilterType = Enum.RaycastFilterType.Exclude
				local excluded = {}
				for instance in pairs(subjectSet) do
					excluded[#excluded + 1] = instance
				end
				for instance in pairs(characterSet) do
					excluded[#excluded + 1] = instance
				end
				params.FilterDescendantsInstances = excluded
			end
			params.IgnoreWater = true
		end)
		local subjectParams = RaycastParams.new()
		pcall(function()
			if includeFilter then
				subjectParams.FilterType = includeFilter
				subjectParams.FilterDescendantsInstances = parts
			else
				subjectParams.FilterType = Enum.RaycastFilterType.Exclude
				subjectParams.FilterDescendantsInstances = blockers
			end
			subjectParams.IgnoreWater = true
		end)
		local points = surfaceSamples(eye, parts, subjectParams, 25)
		local hits, samples = 0, 0
		for index = 1, 25 do
			local point = points[index]
			samples += 1
			if not point then
				hits += 1 -- the subject has no visible surface from this eye
			else
				local delta = point - eye
				local distance = delta.Magnitude
				if distance > 0 then
					local okHit, hit = pcall(function()
						return workspace:Raycast(eye, delta.Unit * distance, params)
					end)
					if okHit and hit and hit.Instance then
						local okTransparency, transparency = pcall(function()
							return hit.Instance.Transparency
						end)
						if okTransparency and type(transparency) == "number" and transparency < 0.5 then
							hits += 1
						end
					end
				end
			end
		end
		return hits, { samples = samples, parts = #parts, blockers = #blockers }
	end

	for _, pair in ipairs(PAIRS) do
		pcall(review.disableAll)
		local special = SPECIALS[pair.id]
		local measureId = (special and special.stage) or pair.id
		local staged, why = true, "default-look tagged subject"
		if special and special.stage then
			staged, why = review.enableAdditive(special.stage, game)
		elseif special and special.tag then
			staged, why = true, "default-look tagged subject"
		else
			staged, why = review.enableAdditive(stageIdFor(pair.id), game)
		end
		local scName = "SC255_" .. label(pair.id)
		local cgName = "CG255_" .. label(pair.id)
		local hcName = "HC255_" .. label(pair.id)
		if not staged then
			emit(scName, false, "0.0000", "0.30", { staged = false, reason = why, camera = pair.camera })
			emit(cgName, false, 1, 0, { staged = false, reason = why, camera = pair.camera })
			emit(hcName, false, 1, 0, { staged = false, reason = why, camera = pair.camera })
		else
			local taggedCount = special and tagSpecial(measureId, pair.id, shared, review) or 0
			local parts = collectParts(measureId)
			local measured = coverage.measure(measureId, pair.camera)
			local scOk = measured.ok == true and measured.fraction >= 0.30
			emit(scName, scOk, shown(measured.fraction), "0.30", {
				reason = #parts == 0 and "no staged candidate parts" or nil,
				fraction = measured.fraction,
				id = pair.id,
				measureId = measureId,
				camera = pair.camera,
				stageReason = why,
				taggedParts = taggedCount,
				detail = measured,
			})
			if scOk then
				scPass += 1
			end

			local camera = Cameras.get(pair.camera)
			local grass = Grass.evaluate(camera.position, camera.lookAt, readColumn)
			local cgOk = grass.ok == true
			emit(cgName, cgOk, cgOk and 0 or 1, 0, {
				camera = pair.camera,
				eyeClearance = grass.eyeClearance,
				lowEye = grass.lowEye,
				lowGrassHits = grass.lowGrassHits,
				samples = grass.samples,
				reason = grass.reason,
			})
			if cgOk then
				cgPass += 1
			end

			local hits, clearDetail = heroClear(camera, parts)
			emit(hcName, hits == 0, hits, 0, {
				camera = pair.camera,
				id = pair.id,
				measureId = measureId,
				detail = clearDetail,
			})
			if hits == 0 then
				hcPass += 1
			end

			if pair == PAIRS[1] and camera and #parts > 0 then
				-- CALIBRATION ANCHOR: inject one opaque blocker 2 studs along the first eye->subject ray.
				local eye = Vector3.new(camera.position[1], camera.position[2], camera.position[3])
				local target = firstSurfaceTarget(camera, parts)
				if target then
					local direction = (target - eye).Unit
					blocker = Instance.new("Part")
					blocker.Name = "Q255_HERO_BLOCKER"
					blocker.Size = Vector3.new(2, 2, 2)
					blocker.CFrame = CFrame.lookAt(eye + direction * 2, eye)
					blocker.Anchored = true
					blocker.CanCollide = false
					blocker.Transparency = 0
					blocker.Parent = workspace
					local blocked = heroClear(camera, parts)
					local calOk = blocked >= 1
					emit(CAL_CLEAR, calOk, blocked, 1, { camera = pair.camera, detail = blocked })
					calChecked += 1
					if calOk then
						calPass += 1
					end
					pcall(function()
						blocker:Destroy()
					end)
					blocker = nil
				else
					emit(CAL_CLEAR, false, 0, 1, { reason = "no calibration sample point" })
					calChecked += 1
				end
			end
		end
		restoreTagged()
		pcall(review.disableAll)
	end

	-- CALIBRATION ANCHOR: the old grade+1 eye must fail the 4-stud eye-clearance floor.
	if MapSpec then
		local first = Cameras.get(PAIRS[1].camera)
		local oldEye = { first.position[1], MapSpec.GROUND_Y + 1, first.position[3] }
		local grass = Grass.evaluate(oldEye, first.lookAt, readColumn)
		local failed = grass.ok ~= true and 1 or 0
		emit(CAL_GRASS, failed >= 1, failed, 1, {
			camera = PAIRS[1].camera,
			eyeClearance = grass.eyeClearance,
			lowEye = grass.lowEye,
			reason = grass.reason,
		})
		calChecked += 1
		if failed >= 1 then
			calPass += 1
		end
	else
		emit(CAL_GRASS, false, 0, 1, { reason = "MapSpec.GROUND_Y unavailable" })
		calChecked += 1
	end

	print(
		string.format(
			"SUMMARY_Q255 SC %d/%d CG %d/%d HERO_CLEAR %d/%d CAL %d/%d",
			scPass,
			#PAIRS,
			cgPass,
			#PAIRS,
			hcPass,
			#PAIRS,
			calPass,
			calChecked
		)
	)
end)

pcall(function()
	if review then
		review.disableAll()
	end
end)
restoreTagged()
pcall(function()
	if blocker then
		blocker:Destroy()
	end
end)

if not ok then
	local reason = { reason = "item 255 audit error: " .. tostring(err) }
	for _, name in ipairs(CHECK_NAMES) do
		local target: any = "0.30"
		if name:find("CG255_", 1, true) or name:find("HC255_", 1, true) then
			target = 0
		elseif name == CAL_CLEAR or name == CAL_GRASS then
			target = 1
		end
		emitOnce(name, false, 0, target, reason)
	end
end

return results
