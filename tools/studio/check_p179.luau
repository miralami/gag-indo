--!nocheck
-- check_p179: WORK_QUEUE section P item 179, ad-hoc SERVER-VM Studio check. Paste this whole file
-- into execute_luau in a fresh Play session. It stages pasar_awnings_r8 and pasar_ground_r8 with
-- enableAdditive in this SAME call, measures the LIVE staged Parts and restores with disableAll().
--
-- PAD_MATERIAL: every stall base and every tagged Pasar ground pad must have material Ground,
-- Cobblestone or Pavement (Slate/SmoothPlastic-black pads are failures).
-- STRIPE_VALUE: HSV V = max(R,G,B) of the live Color3 of every AwningStripe Part must be >= 0.6,
-- with red/white/blue all present and >= MIN_STRIPES stripes.
-- STALLS: >= 10 tagged PasarStall Models. LANE_CLEAR: no visible stall Part CFrame+Size AABB
-- overlaps the 6-stud lane rectangle, built from MapSpec.hubPoint corners as in item 148.
-- Non-vacuous: missing folders, empty staging, no pads/stripes or an unreadable lane all FAIL;
-- this file FAILs on the pre-fix repo (54 Slate ground pads) and PASSes after the pad-map fix.
-- No harness require, no place save, no visual verdict.

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

local ALLOWED_PAD_MATERIALS = { Ground = true, Cobblestone = true, Pavement = true }
local MIN_STALLS = 10
local MIN_STRIPE_VALUE = 0.6
local OVERLAP_TOL = 0.05

local function descendantsOf(folder)
	local out = {}
	if not folder then
		return out
	end
	for _, descendant in ipairs(folder:GetDescendants()) do
		out[#out + 1] = descendant
	end
	return out
end

local function basePartsUnder(folder)
	local out = {}
	for _, descendant in ipairs(descendantsOf(folder)) do
		if descendant:IsA("BasePart") then
			out[#out + 1] = descendant
		end
	end
	return out
end

local function materialName(part)
	local ok, name = pcall(function()
		return part.Material.Name
	end)
	return ok and type(name) == "string" and name or "<unknown>"
end

-- HSV V of the LIVE staged colour; Color3 channels are already 0..1.
local function stripeValue(part)
	local ok, colour = pcall(function()
		return part.Color
	end)
	if not ok or not colour then
		return 0
	end
	return math.max(colour.R, colour.G, colour.B)
end

-- World-space XZ AABB from CFrame+Size using VectorToWorldSpace half-extents (matches the harness).
local function worldAABB(part)
	local ok, cf, size = pcall(function()
		return part.CFrame, part.Size
	end)
	if not ok or not cf or not size then
		return nil
	end
	local centre = cf.Position
	local ex = cf:VectorToWorldSpace(Vector3.new(size.X / 2, 0, 0))
	local ey = cf:VectorToWorldSpace(Vector3.new(0, size.Y / 2, 0))
	local ez = cf:VectorToWorldSpace(Vector3.new(0, 0, size.Z / 2))
	local hx = math.abs(ex.X) + math.abs(ey.X) + math.abs(ez.X)
	local hz = math.abs(ex.Z) + math.abs(ey.Z) + math.abs(ez.Z)
	return {
		minX = centre.X - hx,
		maxX = centre.X + hx,
		minZ = centre.Z - hz,
		maxZ = centre.Z + hz,
	}
end

local review = nil
local ok, err = pcall(function()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	review = require(shared:WaitForChild("LookDevReview"))
	local AwningData = require(shared:WaitForChild("ModelMapPasarAwningsR8"))
	local GroundData = require(shared:WaitForChild("ModelMapPasarGroundR8"))

	local MapSpec = nil
	pcall(function()
		local server = game:GetService("ServerScriptService"):FindFirstChild("Server")
		local world = server and server:FindFirstChild("World")
		local module = world and world:FindFirstChild("MapSpec")
		if module then
			MapSpec = require(module)
		end
	end)

	local okAwnings, whyAwnings = review.enableAdditive("pasar_awnings_r8", game, { studio = true })
	if not okAwnings then
		error("enableAdditive(pasar_awnings_r8) failed: " .. tostring(whyAwnings))
	end
	local okGround, whyGround = review.enableAdditive("pasar_ground_r8", game, { studio = true })
	if not okGround then
		error("enableAdditive(pasar_ground_r8) failed: " .. tostring(whyGround))
	end
	local awningFolder = workspace:FindFirstChild(AwningData.folderName)
	local groundFolder = workspace:FindFirstChild(GroundData.folderName)
	if not awningFolder or not groundFolder then
		error("missing staging folder: " .. tostring(AwningData.folderName) .. " / " .. tostring(GroundData.folderName))
	end
	local awningParts = basePartsUnder(awningFolder)
	local groundParts = basePartsUnder(groundFolder)
	if #awningParts == 0 or #groundParts == 0 then
		error("staging folders have no BaseParts")
	end

	-- PAD_MATERIAL ------------------------------------------------------------
	local pads = {}
	for _, part in ipairs(awningParts) do
		if part.Name == "StallBase" then
			pads[#pads + 1] = part
		end
	end
	for _, part in ipairs(groundParts) do
		if part:GetAttribute(GroundData.kindAttribute) ~= nil then
			pads[#pads + 1] = part
		end
	end
	local badPads = {}
	for _, part in ipairs(pads) do
		local name = materialName(part)
		if not ALLOWED_PAD_MATERIALS[name] then
			badPads[#badPads + 1] = part:GetFullName() .. "=" .. name
		end
	end
	emit("PAD_MATERIAL", #pads > 0 and #badPads == 0, #badPads, 0, {
		padsChecked = #pads,
		failures = badPads,
	})

	-- STRIPE_VALUE ------------------------------------------------------------
	local minValue = math.huge
	local stripes, dimStripes = 0, {}
	local seen = { red = false, white = false, blue = false }
	for _, part in ipairs(awningParts) do
		if part:GetAttribute(AwningData.stripeAttribute) == true then
			stripes += 1
			local value = stripeValue(part)
			minValue = math.min(minValue, value)
			if value < MIN_STRIPE_VALUE then
				dimStripes[#dimStripes + 1] = part:GetFullName() .. string.format(" V=%.3f", value)
			end
			local colour = part:GetAttribute(AwningData.stripeColourAttribute)
			if colour == "red" or colour == "white" or colour == "blue" then
				seen[colour] = true
			end
		end
	end
	local measuredValue = if minValue == math.huge then 0 else math.floor(minValue * 1000 + 0.5) / 1000
	local stripePass = stripes >= (AwningData.MIN_STRIPES or 30)
		and minValue >= MIN_STRIPE_VALUE
		and seen.red
		and seen.white
		and seen.blue
	emit("STRIPE_VALUE", stripePass, measuredValue, MIN_STRIPE_VALUE, {
		stripes = stripes,
		seen = seen,
		failures = dimStripes,
	})

	-- STALLS ------------------------------------------------------------------
	local stalls = {}
	for _, descendant in ipairs(descendantsOf(awningFolder)) do
		if descendant:IsA("Model") and descendant:GetAttribute(AwningData.stallAttribute) == true then
			stalls[#stalls + 1] = descendant
		end
	end
	emit("STALLS", #stalls >= MIN_STALLS, #stalls, MIN_STALLS, { stalls = #stalls })

	-- LANE_CLEAR --------------------------------------------------------------
	local laneBox = nil
	if
		MapSpec
		and type(MapSpec.hub) == "function"
		and type(MapSpec.hubPoint) == "function"
		and type(AwningData.lane) == "function"
	then
		local okLane, lane = pcall(AwningData.lane)
		local okHub, hub = pcall(function()
			return MapSpec.hub("pasar")
		end)
		if okLane and okHub and hub ~= nil and type(lane) == "table" then
			local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
			local ready = true
			for _, corner in ipairs({
				{ lane.lx - lane.width / 2, lane.lz - lane.depth / 2 },
				{ lane.lx + lane.width / 2, lane.lz - lane.depth / 2 },
				{ lane.lx - lane.width / 2, lane.lz + lane.depth / 2 },
				{ lane.lx + lane.width / 2, lane.lz + lane.depth / 2 },
			}) do
				local okPoint, x, z = pcall(function()
					return MapSpec.hubPoint(hub, corner[1], corner[2])
				end)
				if not okPoint or type(x) ~= "number" or type(z) ~= "number" then
					ready = false
					break
				end
				minX, maxX = math.min(minX, x), math.max(maxX, x)
				minZ, maxZ = math.min(minZ, z), math.max(maxZ, z)
			end
			if ready and minX < maxX and minZ < maxZ then
				laneBox = { minX = minX, maxX = maxX, minZ = minZ, maxZ = maxZ }
			end
		end
	end
	local overlaps = 0
	if not laneBox then
		overlaps = 1 -- an unreadable lane cannot pass a 0-target
	else
		for _, stall in ipairs(stalls) do
			for _, descendant in ipairs(descendantsOf(stall)) do
				if descendant:IsA("BasePart") and descendant.Transparency < 1 then
					local box = worldAABB(descendant)
					if box then
						local ox = math.min(box.maxX, laneBox.maxX) - math.max(box.minX, laneBox.minX)
						local oz = math.min(box.maxZ, laneBox.maxZ) - math.max(box.minZ, laneBox.minZ)
						if ox > OVERLAP_TOL and oz > OVERLAP_TOL then
							overlaps += 1
						end
					end
				end
			end
		end
	end
	emit("LANE_CLEAR", laneBox ~= nil and overlaps == 0, overlaps, 0, {
		lane = laneBox,
		blockingParts = overlaps,
		stalls = #stalls,
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
	emit("PAD_MATERIAL", false, 0, 0, reason)
	emit("STRIPE_VALUE", false, 0, MIN_STRIPE_VALUE, reason)
	emit("STALLS", false, 0, MIN_STALLS, reason)
	emit("LANE_CLEAR", false, 1, 0, reason)
end

return results
