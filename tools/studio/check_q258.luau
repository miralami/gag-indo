--!nocheck
-- check_q258: WORK_QUEUE item 258, self-contained SERVER-VM Studio check. Paste this whole file
-- into execute_luau in a FRESH Play session. It stages ONLY bamboo_bridge_r10 via
-- LookDevReview.enableAdditive, measures the live DataModel, prints verbatim CHECK lines, then
-- restores with disableAll() on every path. No harness require, no client calls, no place save,
-- no visual verdict. The hero shot from the bank belongs to the main session.
--
--   BRIDGE_WALKABLE  same-lane downward raycasts before/after staging (delta 0); hidden default
--                    bridge parts stay in the Include filter because they are the walk lane
--   BRIDGE_RAILS     exactly one rail_left and one rail_right Cylinder among staged parts
--   BRIDGE_SWAP      default Greybox BridgeDeck/Post/Rail/Ramp parts hidden while staged
--   LOOKDEV_LEAK     0 LookDevStage-tagged leftovers after restore, defaults back at exact values
--   BRIDGE_COLORS    yellow posts (R>G>B), black pipes (all channels <60), white pillars (all >200)
--
-- CALIBRATION ANCHORS (each must FAIL its condition, then restore):
--   CAL_BRIDGE_COLORS_FAIL  inject a blue "post" into the staged set -> colour groups fail
--   CAL_LOOKDEV_LEAK_FAIL   leave a LookDevStage-tagged Part behind across disableAll()
--
-- Both measure() moments stay on separate lines so a before/after mismatch can be injected.

local CANDIDATE_ID = "bamboo_bridge_r10"
local LANE_OFFSETS = { -2.5, -1.25, 0, 1.25, 2.5 }
local COLOR_TOLERANCE = 12
local DEFAULT_BRIDGE_NAMES = {
	BridgeDeck = true,
	BridgePost = true,
	BridgeRail = true,
	BridgeRamp = true,
}

local CHECK_NAMES = {
	"BRIDGE_WALKABLE",
	"BRIDGE_RAILS",
	"BRIDGE_SWAP",
	"LOOKDEV_LEAK",
	"BRIDGE_COLORS",
	"CAL_BRIDGE_COLORS_FAIL",
	"CAL_LOOKDEV_LEAK_FAIL",
}
local CHECK_TARGETS = {
	BRIDGE_WALKABLE = 0,
	BRIDGE_RAILS = 2,
	BRIDGE_SWAP = "total",
	LOOKDEV_LEAK = 0,
	BRIDGE_COLORS = "3/3",
	CAL_BRIDGE_COLORS_FAIL = 1,
	CAL_LOOKDEV_LEAK_FAIL = 1,
}

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

local review, Data = nil, nil
local injected = {}

local function descendants()
	local ok, list = pcall(function()
		return workspace:GetDescendants()
	end)
	if ok and type(list) == "table" then
		return list, 0
	end
	return {}, 1
end

local function bridgePartsFrom(list)
	local out = {}
	for _, instance in ipairs(list) do
		local okName, name = pcall(function()
			return instance.Name
		end)
		if okName and type(name) == "string" and DEFAULT_BRIDGE_NAMES[name] then
			local okPart, isPart = pcall(function()
				return instance:IsA("BasePart")
			end)
			if okPart and isPart then
				out[#out + 1] = instance
			end
		end
	end
	return out
end

local function countTaggedLeftovers()
	local list, errors = descendants()
	local leftovers = 0
	for _, instance in ipairs(list) do
		pcall(function()
			if instance:GetAttribute("LookDevStage") == CANDIDATE_ID then
				leftovers += 1
			end
		end)
	end
	return leftovers, errors
end

local function snapshotDefaults()
	local snapshot, total, errors = {}, 0, 0
	for _, part in ipairs(bridgePartsFrom(descendants())) do
		total += 1
		local ok, transparency, canCollide = pcall(function()
			return part.Transparency, part.CanCollide
		end)
		if ok then
			snapshot[part] = { transparency = transparency, canCollide = canCollide }
		else
			errors += 1
		end
	end
	return snapshot, total, errors
end

local function measureSwap()
	local hidden, total, errors = 0, 0, 0
	for _, part in ipairs(bridgePartsFrom(descendants())) do
		total += 1
		local ok, transparency, canCollide = pcall(function()
			return part.Transparency, part.CanCollide
		end)
		if ok and transparency == 1 and canCollide == false then
			hidden += 1
		elseif not ok then
			errors += 1
		end
	end
	return hidden, total, errors
end

local function measureRestore(snapshot)
	local restored, total, errors = 0, 0, 0
	for part, original in pairs(snapshot) do
		total += 1
		local ok, transparency, canCollide = pcall(function()
			return part.Transparency, part.CanCollide
		end)
		if ok and transparency == original.transparency and canCollide == original.canCollide then
			restored += 1
		elseif not ok then
			errors += 1
		end
	end
	for _, part in ipairs(bridgePartsFrom(descendants())) do
		if snapshot[part] == nil then
			total += 1
		end
	end
	return restored, total, errors
end

-- One live read supplies walkability, rails and colours. Hidden default parts are explicitly kept
-- in the Include filter; the staged overlay is non-collidable and carries BambooBridge=true.
local function measure(ignoreWalkables)
	local all, readErrors = descendants()
	local staged, walkables = {}, {}
	for _, instance in ipairs(all) do
		pcall(function()
			if instance:GetAttribute("BambooBridge") == true then
				staged[#staged + 1] = instance
			elseif instance:IsA("BasePart") and instance.CanCollide == true then
				walkables[#walkables + 1] = instance
			end
		end)
	end
	local known = {}
	for _, instance in ipairs(walkables) do
		known[instance] = true
	end
	for _, instance in ipairs(bridgePartsFrom(all)) do
		if not known[instance] then
			walkables[#walkables + 1] = instance
		end
	end

	local params = nil
	local filter = if ignoreWalkables then {} else walkables
	local okParams, made = pcall(function()
		local p = RaycastParams.new()
		p.FilterType = Enum.RaycastFilterType.Include
		p.FilterDescendantsInstances = filter
		p.IgnoreWater = true
		return p
	end)
	if okParams and made then
		params = made
	else
		readErrors += 1
	end

	local blocked, samples = 0, 0
	if Data and params then
		local start, finish = Data.BRIDGE_START, Data.BRIDGE_END
		local zSamples = { start.z + 8, (start.z + finish.z) / 2, finish.z - 8 }
		for _, z in ipairs(zSamples) do
			for _, x in ipairs(LANE_OFFSETS) do
				local okRay, hit = pcall(function()
					return workspace:Raycast(Vector3.new(x, start.y + 16, z), Vector3.new(0, -64, 0), params)
				end)
				samples += 1
				if not okRay then
					readErrors += 1
				end
				if not okRay or not hit then
					blocked += 1
				end
			end
		end
	else
		readErrors += 1
		blocked = #LANE_OFFSETS * 3
	end

	local roles = { post = {}, pillar = {}, rail_left = {}, rail_right = {} }
	local railShapes = { rail_left = true, rail_right = true }
	local railHeights = { rail_left = {}, rail_right = {} }
	local intrusions = 0
	local laneHalf = if Data and type(Data.LANE_HALF) == "number" then Data.LANE_HALF else 2
	for _, instance in ipairs(staged) do
		local okRole, role = pcall(function()
			return instance:GetAttribute("role")
		end)
		if okRole and roles[role] then
			local okColor, color = pcall(function()
				return instance.Color
			end)
			if okColor and color then
				roles[role][#roles[role] + 1] = {
					r = color.R * 255,
					g = color.G * 255,
					b = color.B * 255,
				}
			else
				readErrors += 1
			end
			if role == "rail_left" or role == "rail_right" then
				local okShape, shape = pcall(function()
					return instance.Shape
				end)
				if okShape then
					if shape ~= Enum.PartType.Cylinder then
						railShapes[role] = false
					end
				else
					readErrors += 1
				end
				local okY, y = pcall(function()
					return instance.Position.Y
				end)
				if okY then
					railHeights[role][#railHeights[role] + 1] = y
				else
					readErrors += 1
				end
			end
			-- Posts, rails and pillars must stay outside the walking lane (|x| < laneHalf).
			local okLane, innerX = pcall(function()
				return math.abs(instance.Position.X) - instance.Size.X / 2
			end)
			if okLane then
				if innerX < laneHalf then
					intrusions += 1
				end
			else
				readErrors += 1
			end
		end
	end

	return {
		blocked = blocked,
		samples = samples,
		staged = #staged,
		roles = roles,
		railShapes = railShapes,
		railHeights = railHeights,
		intrusions = intrusions,
		readErrors = readErrors,
	}
end

local function nearChannel(value, expected)
	return type(value) == "number" and math.abs(value - expected) <= COLOR_TOLERANCE
end

local function nearColor(color, palette)
	return palette ~= nil
		and nearChannel(color.r, palette.r)
		and nearChannel(color.g, palette.g)
		and nearChannel(color.b, palette.b)
end

-- Returns the measured "n/3" plus one boolean per colour group, all read from live parts.
local function measureColors(measurement)
	local posts = measurement.roles.post
	local rails = {}
	for _, role in ipairs({ "rail_left", "rail_right" }) do
		for _, color in ipairs(measurement.roles[role]) do
			rails[#rails + 1] = color
		end
	end
	local pillars = measurement.roles.pillar

	local postsOk = #posts >= 4
	for _, color in ipairs(posts) do
		if not (color.r > color.g and color.g > color.b) or not nearColor(color, Data and Data.POST_COLOR) then
			postsOk = false
		end
	end
	local railsOk = #measurement.roles.rail_left == 2 and #measurement.roles.rail_right == 2
	for _, color in ipairs(rails) do
		if not (color.r < 60 and color.g < 60 and color.b < 60) or not nearColor(color, Data and Data.RAIL_COLOR) then
			railsOk = false
		end
	end
	local pillarsOk = #pillars >= 4
	for _, color in ipairs(pillars) do
		if
			not (color.r > 200 and color.g > 200 and color.b > 200) or not nearColor(color, Data and Data.PILLAR_COLOR)
		then
			pillarsOk = false
		end
	end

	local good = (postsOk and 1 or 0) + (railsOk and 1 or 0) + (pillarsOk and 1 or 0)
	return {
		good = good,
		postsOk = postsOk,
		railsOk = railsOk,
		pillarsOk = pillarsOk,
		posts = #posts,
		rails = #rails,
		pillars = #pillars,
		tolerance = COLOR_TOLERANCE,
		readErrors = measurement.readErrors,
	}
end

local function inject(part)
	part.Anchored = true
	part.CanCollide = false
	part.CastShadow = false
	part.Parent = workspace
	injected[#injected + 1] = part
	return part
end

local function destroyInjected()
	for index = #injected, 1, -1 do
		pcall(function()
			injected[index]:Destroy()
		end)
		injected[index] = nil
	end
end

local function injectBluePost()
	local part = Instance.new("Part")
	part.Name = "Q258_COLOR_CALIBRATION"
	part.Size = Vector3.new(1, 1, 1)
	part.CFrame = CFrame.new(0, 12, 304)
	part.Color = Color3.fromRGB(40, 80, 200)
	part:SetAttribute("BambooBridge", true)
	part:SetAttribute("role", "post")
	part:SetAttribute("LookDevStage", CANDIDATE_ID)
	return inject(part)
end

local function injectTaggedLeak()
	local part = Instance.new("Part")
	part.Name = "Q258_LEAK_CALIBRATION"
	part.Size = Vector3.new(1, 1, 1)
	part.CFrame = CFrame.new(0, 14, 304)
	part:SetAttribute("LookDevStage", CANDIDATE_ID)
	return inject(part)
end

local ok, err = pcall(function()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	review = require(shared:WaitForChild("LookDevReview"))
	Data = require(shared:WaitForChild("ModelMapBambooBridgeR10"))
	if
		type(review) ~= "table"
		or type(review.enableAdditive) ~= "function"
		or type(review.disableAll) ~= "function"
		or type(Data) ~= "table"
		or type(Data.BRIDGE_START) ~= "table"
		or type(Data.BRIDGE_END) ~= "table"
		or type(Data.POST_COLOR) ~= "table"
		or type(Data.RAIL_COLOR) ~= "table"
		or type(Data.PILLAR_COLOR) ~= "table"
	then
		error("LookDevReview / ModelMapBambooBridgeR10 API missing")
	end

	local snapshot, originalTotal, snapshotErrors = snapshotDefaults()
	local walkBefore = measure(false)
	local staged, stageWhy = review.enableAdditive(CANDIDATE_ID, game)
	local reason = if staged == true then nil else "enableAdditive failed: " .. tostring(stageWhy)

	local hidden, swapTotal, swapErrors = measureSwap()
	emit(
		"BRIDGE_SWAP",
		staged == true
			and originalTotal > 0
			and hidden == originalTotal
			and swapTotal == originalTotal
			and swapErrors == 0
			and snapshotErrors == 0,
		hidden .. "/" .. swapTotal,
		originalTotal,
		{
			originalParts = originalTotal,
			hidden = hidden,
			readErrors = swapErrors + snapshotErrors,
			reason = reason,
		}
	)

	local walkAfter = measure(false)
	local walkDelta = math.max(0, walkAfter.blocked - walkBefore.blocked)
	emit(
		"BRIDGE_WALKABLE",
		staged == true
			and walkAfter.staged > 0
			and walkDelta == 0
			and walkAfter.intrusions == 0
			and walkAfter.samples > 0
			and walkAfter.readErrors == 0
			and walkBefore.readErrors == 0,
		walkDelta,
		0,
		{
			beforeBlocked = walkBefore.blocked,
			afterBlocked = walkAfter.blocked,
			samples = walkAfter.samples,
			staged = walkAfter.staged,
			laneIntrusions = walkAfter.intrusions,
			reason = reason,
		}
	)

	local railCount = 0
	local deckTop = Data.BRIDGE_START.y
	local heightsOk = true
	for _, role in ipairs({ "rail_left", "rail_right" }) do
		-- Two pipes per side, both Cylinders, at 0.85 and 1.7 studs above the deck.
		local ys = walkAfter.railHeights[role]
		table.sort(ys)
		local sideHeights = #ys == 2
			and math.abs(ys[1] - (deckTop + 0.85)) < 0.3
			and math.abs(ys[2] - (deckTop + 1.7)) < 0.3
		if not sideHeights then
			heightsOk = false
		end
		if #walkAfter.roles[role] == 2 and walkAfter.railShapes[role] == true and sideHeights then
			railCount += 1
		end
	end
	emit("BRIDGE_RAILS", railCount == 2 and walkAfter.readErrors == 0, railCount, 2, {
		left = #walkAfter.roles.rail_left,
		right = #walkAfter.roles.rail_right,
		leftCylinder = walkAfter.railShapes.rail_left == true,
		rightCylinder = walkAfter.railShapes.rail_right == true,
		heightsOk = heightsOk,
		reason = reason,
	})

	local colors = measureColors(walkAfter)
	emit("BRIDGE_COLORS", colors.good == 3 and colors.readErrors == 0, colors.good .. "/3", "3/3", {
		postsOk = colors.postsOk,
		railsOk = colors.railsOk,
		pillarsOk = colors.pillarsOk,
		posts = colors.posts,
		rails = colors.rails,
		pillars = colors.pillars,
		tolerance = colors.tolerance,
		reason = reason,
	})

	-- CALIBRATION ANCHOR (COLOURS FAIL): a blue post in the staged set breaks the yellow group.
	local bluePost = injectBluePost()
	local calMeasurement = measure(false)
	local calColors = measureColors(calMeasurement)
	local colorsFailed = not calColors.postsOk and calColors.good < 3
	emit("CAL_BRIDGE_COLORS_FAIL", colorsFailed, colorsFailed and 1 or 0, 1, {
		injectedName = bluePost.Name,
		injectedColor = "40,80,200",
		postsOk = calColors.postsOk,
		good = calColors.good,
	})
	destroyInjected()

	pcall(review.disableAll)
	local leaked, leakedErrors = countTaggedLeftovers()
	local bridgeRestored, bridgeTotal, bridgeErrors = measureRestore(snapshot)
	local bridgeClean = bridgeRestored == originalTotal and bridgeTotal == originalTotal and bridgeErrors == 0
	emit("LOOKDEV_LEAK", bridgeClean and leaked == 0 and leakedErrors == 0, leaked, 0, {
		taggedLeftovers = leaked,
		defaultBridgeRestored = bridgeRestored,
		defaultBridgeTotal = originalTotal,
		readErrors = leakedErrors + bridgeErrors,
	})

	-- CALIBRATION ANCHOR (LEAK FAIL): one tagged Part survives disableAll().
	pcall(review.enableAdditive, CANDIDATE_ID, game)
	injectTaggedLeak()
	pcall(review.disableAll)
	local calLeftovers, calErrors = countTaggedLeftovers()
	local leakFailed = calLeftovers >= 1 and calErrors == 0
	emit("CAL_LOOKDEV_LEAK_FAIL", leakFailed, leakFailed and 1 or 0, 1, {
		injectedName = "Q258_LEAK_CALIBRATION",
		taggedLeftovers = calLeftovers,
		readErrors = calErrors,
	})
	destroyInjected()
end)

-- Restore every staged candidate and every injection, on every path.
pcall(function()
	if review then
		review.disableAll()
	else
		require(game:GetService("ReplicatedStorage").Shared.LookDevReview).disableAll()
	end
end)
destroyInjected()

if not ok then
	local reason = { reason = "item 258 audit error: " .. tostring(err) }
	for _, name in ipairs(CHECK_NAMES) do
		local target = CHECK_TARGETS[name]
		local wrong = if target == "total" then "0/0" elseif target == "3/3" then "0/3" else 0
		emitOnce(name, false, wrong, target, reason)
	end
end

local checkPass, checkTotal, calPass, calTotal = 0, 0, 0, 0
for _, name in ipairs(CHECK_NAMES) do
	local entry = results.byName[name]
	if string.sub(name, 1, 4) == "CAL_" then
		calTotal += 1
		if entry and entry.passed then
			calPass += 1
		end
	else
		checkTotal += 1
		if entry and entry.passed then
			checkPass += 1
		end
	end
end
print(string.format("SUMMARY_Q258 CHECKS %d/%d CAL %d/%d", checkPass, checkTotal, calPass, calTotal))

return results
