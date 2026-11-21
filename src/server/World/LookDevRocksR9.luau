--!strict
-- LookDevRocksR9: SERVER-ONLY applier for the OFF-BY-DEFAULT "rocks_r9" candidate
-- (WORK_QUEUE section O item 151). Stages half-buried boulders and stones from original Parts under
-- `LookDevRocksR9_rocks_r9`, placed from MapSpec river banks, hill foot and sawah terraces.
--
-- Three procedural shapes (Ball, squashed Wedge, 3-ball cluster) stand in for rock models: no
-- verified rock MODEL id exists in the shared asset maps, so no asset id is invented. Every rock is
-- excluded from the live MapSpec path rectangles and from every live plot gate (staged gate markers
-- first, tagged PlotAnchor parts next, Config.Game.plotCenter fallback). A gate list that cannot be
-- read is a FAIL, never a vacuous pass. Engine calls are pcall guarded, failures are published.
--   require(game.ReplicatedStorage.Shared.LookDevReview).enable("rocks_r9", game)

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevRocksR9] missing service " .. name)
		return nil
	end
	return value
end

local ReplicatedStorage = service("ReplicatedStorage")
local Workspace = service("Workspace")
local CollectionService = service("CollectionService")

local Shared: any? = nil
if ReplicatedStorage then
	local ok, folder = pcall(function()
		return (ReplicatedStorage :: any):WaitForChild("Shared")
	end)
	if ok and folder then
		Shared = folder
	else
		warn("[LookDevRocksR9] missing Shared folder")
	end
end
if not Shared then
	return {}
end

local okModules, LookDev, Data, PlotsData, LookDevFailures = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapRocksR9),
		require((Shared :: any).ModelMapPlotsR8),
		require((Shared :: any).LookDevFailures)
end)
if not okModules or not LookDev or not Data or not PlotsData or not LookDevFailures then
	warn("[LookDevRocksR9] could not require LookDev / ModelMapRocksR9 / ModelMapPlotsR8 / LookDevFailures")
	return {}
end

local okSpec, loadedSpec = pcall(function()
	return require(script.Parent.MapSpec)
end)
if not okSpec or not loadedSpec then
	warn("[LookDevRocksR9] could not require MapSpec")
end
local MapSpec: any? = if okSpec then loadedSpec else nil

local LookDevRocksR9 = {}

local failures = 0
local activeFolder: any? = nil
local savedFolder: any? = nil
local staged: { any } = {}

local function fail(message: string)
	failures += 1
	warn("[LookDevRocksR9] " .. message)
end

local function publishFailures()
	pcall(function()
		LookDevFailures.set(Data.familyId, failures)
	end)
end

local function track(instance: any?)
	if instance then
		staged[#staged + 1] = instance
	end
end

local function clearActive()
	for index = #staged, 1, -1 do
		pcall(function()
			staged[index]:Destroy()
		end)
	end
	table.clear(staged)
	local folder = activeFolder
	if folder then
		pcall(function()
			folder:Destroy()
		end)
	end
	activeFolder = nil
end

local function newFolder(name: string, parent: any): any?
	local okNew, folder = pcall(function()
		return Instance.new("Folder")
	end)
	if not okNew or not folder then
		return nil
	end
	pcall(function()
		folder.Name = name
		folder.Parent = parent
	end)
	return folder
end

-- Stage the gate centres from the real plots. Gate markers are written by LookDevPlotsR8 at the
-- same local z used by the harness; tagged PlotAnchors and Config.Game.plotCenter are the fallbacks.
local function gateCentres(): { any }
	local out = {}
	if Workspace then
		local okPlots, plots = pcall(function()
			return (Workspace :: any):FindFirstChild(PlotsData.folderName)
		end)
		if okPlots and plots then
			local okList, list = pcall(function()
				return plots:GetDescendants()
			end)
			if okList and type(list) == "table" then
				for _, part in ipairs(list) do
					local okMarker, isMarker = pcall(function()
						local kind = part:GetAttribute("Kind")
						local key = part:GetAttribute("LookDevPlotsR8")
						return kind == "gate_marker" and key == "plots_r8" and part:IsA("BasePart")
					end)
					if okMarker and isMarker then
						local okPos, pos = pcall(function()
							return part.CFrame.Position
						end)
						if okPos then
							out[#out + 1] = { x = pos.X, z = pos.Z }
						end
					end
				end
			end
		end
	end
	if #out > 0 then
		return out
	end

	if CollectionService then
		local okTagged, tagged = pcall(function()
			return (CollectionService :: any):GetTagged("PlotAnchor")
		end)
		if okTagged and type(tagged) == "table" then
			for _, anchor in ipairs(tagged) do
				local okAnchor, x, z = pcall(function()
					local gate = anchor.CFrame * CFrame.new(0, 0, -(anchor.Size.Z / 2 + 3))
					return gate.Position.X, gate.Position.Z
				end)
				if okAnchor then
					out[#out + 1] = { x = x, z = z }
				end
			end
		end
	end
	if #out > 0 then
		return out
	end

	local okGame, Game = pcall(function()
		return require((Shared :: any).Config.Game)
	end)
	if okGame and Game then
		for index = 1, PlotsData.PLOT_COUNT do
			local okCentre, gx, gz = pcall(function()
				local x, z = Game.plotCenter(index)
				local frame = CFrame.lookAt(Vector3.new(x, 0, z), Vector3.zero)
				local gate = frame * CFrame.new(0, 0, -(PlotsData.PLOT_DEPTH / 2 + 3))
				return gate.Position.X, gate.Position.Z
			end)
			if okCentre and type(gx) == "number" and type(gz) == "number" then
				out[#out + 1] = { x = gx, z = gz }
			end
		end
	end
	return out
end

-- The harness's PATH_CLEAR geometry, rebuilt from live MapSpec: axis-aligned road rectangles plus
-- the 6-degree ring chords' tangent/normal axes and half-length.
local function pathGeometry(): (any, any, boolean)
	local rects, segments = {}, {}
	if
		not MapSpec
		or type(MapSpec.roadArms) ~= "function"
		or type(MapSpec.roadContinuations) ~= "function"
		or type(MapSpec.ringSegments) ~= "function"
	then
		fail("MapSpec path functions missing")
		return rects, segments, false
	end
	local okArms, arms = pcall(MapSpec.roadArms)
	local okConts, conts = pcall(MapSpec.roadContinuations)
	local okRing, ring = pcall(MapSpec.ringSegments)
	if
		not okArms
		or type(arms) ~= "table"
		or not okConts
		or type(conts) ~= "table"
		or not okRing
		or type(ring) ~= "table"
	then
		fail("MapSpec path tables unreadable")
		return rects, segments, false
	end
	for _, list in ipairs({ arms, conts }) do
		for _, item in ipairs(list) do
			if
				type(item.x) ~= "number"
				or type(item.z) ~= "number"
				or type(item.sx) ~= "number"
				or type(item.sz) ~= "number"
			then
				fail("malformed MapSpec road rectangle")
				return rects, segments, false
			end
			rects[#rects + 1] = { x = item.x, z = item.z, halfX = item.sx / 2, halfZ = item.sz / 2 }
		end
	end
	for _, item in ipairs(ring) do
		if
			type(item.x) ~= "number"
			or type(item.z) ~= "number"
			or type(item.yaw) ~= "number"
			or type(item.length) ~= "number"
		then
			fail("malformed MapSpec ring chord")
			return rects, segments, false
		end
		local a = math.rad(item.yaw)
		segments[#segments + 1] = {
			x = item.x,
			z = item.z,
			tx = math.cos(a),
			tz = -math.sin(a),
			nx = math.sin(a),
			nz = math.cos(a),
			halfLen = item.length / 2,
		}
	end
	if #rects == 0 or #segments == 0 then
		fail("MapSpec path tables empty")
		return rects, segments, false
	end
	return rects, segments, true
end

local function addPart(parent: any, rock: any, recipe: any, index: number, groundY: number)
	local ok, part = pcall(function()
		local created = Instance.new("Part")
		created.Name = string.format("Rock_%02d_%s", index, recipe.shape)
		created.Shape = (Enum :: any).PartType[recipe.shape] or (Enum :: any).PartType.Ball
		created.Size = Vector3.new(recipe.size[1], recipe.size[2], recipe.size[3])
		-- Half-buried: the centre sits BURY_FRACTION of the part height below the surface.
		created.CFrame =
			CFrame.new(rock.x + recipe.dx, groundY - recipe.size[2] * Data.BURY_FRACTION, rock.z + recipe.dz)
		created.Material = (Enum :: any).Material.Rock
		created.Color = Color3.fromRGB(126 + index % 12, 122 + index % 9, 112 + index % 8)
		created.Anchored = true
		created.CanCollide = false -- visual overlay; never blocks the walking lane
		created:SetAttribute(Data.stageAttribute, Data.familyId)
		created:SetAttribute(Data.rockAttribute, Data.familyId)
		created:SetAttribute(Data.kindAttribute, rock.kind)
		created.Parent = parent
		return created
	end)
	if not ok or not part then
		fail("could not stage rock " .. index .. ": " .. tostring(part))
		return
	end
	track(part)
end

local applier = {
	apply = function()
		failures = 0
		pcall(function()
			LookDevFailures.reset(Data.familyId)
		end)
		clearActive()
		if not Workspace or not MapSpec then
			fail("missing Workspace / MapSpec")
			publishFailures()
			return
		end
		if type(MapSpec.riverCentreZ) ~= "function" or type(MapSpec.TERRAIN_HALF) ~= "number" then
			fail("MapSpec river / terrain geometry missing")
			publishFailures()
			return
		end

		local gates = gateCentres()
		if #gates < PlotsData.PLOT_COUNT then
			fail("only " .. #gates .. "/" .. PlotsData.PLOT_COUNT .. " plot gates readable")
			publishFailures()
			return
		end

		local rects, segments, pathsOk = pathGeometry()
		if not pathsOk then
			publishFailures()
			return
		end

		local allRocks = Data.rocks({
			centreZ = MapSpec.riverCentreZ,
			terrainHalf = MapSpec.TERRAIN_HALF,
			terraces = MapSpec.TERRACES,
			terraceX = MapSpec.TERRACE_X,
			terraceGap = MapSpec.TERRACE_GAP,
			riverHalf = 14,
			riverBank = 8,
		})
		if Data.count(allRocks) < Data.MIN_ROCKS then
			fail("generated only " .. Data.count(allRocks) .. "/" .. Data.MIN_ROCKS .. " rocks")
			publishFailures()
			return
		end
		local rocks = Data.pathExcluded(Data.gateExcluded(allRocks, gates, Data.GATE_CLEAR), rects, segments)
		if Data.count(rocks) < Data.MIN_ROCKS then
			fail("path/gate exclusion left " .. Data.count(rocks) .. "/" .. Data.MIN_ROCKS .. " rocks")
			publishFailures()
			return
		end
		if #Data.kinds(rocks) < Data.MIN_SPECIES then
			fail("only " .. #Data.kinds(rocks) .. " rock species")
			publishFailures()
			return
		end

		local previous = nil
		pcall(function()
			previous = (Workspace :: any):FindFirstChild(Data.folderName)
		end)
		if previous then
			pcall(function()
				previous.Parent = nil
			end)
			savedFolder = previous
		end
		local folder = newFolder(Data.folderName, Workspace)
		if not folder then
			fail("could not create staging folder")
			publishFailures()
			return
		end
		activeFolder = folder
		track(folder)
		pcall(function()
			folder:SetAttribute(Data.stageAttribute, Data.familyId)
		end)

		local stagedRocks = 0
		for index, rock in ipairs(rocks) do
			local okModel, model = pcall(function()
				return Instance.new("Model")
			end)
			if not okModel or not model then
				fail("could not create model for rock " .. index)
				continue
			end
			track(model)
			local okConfigure = pcall(function()
				model.Name = string.format("Rock_%s_%02d", rock.band, index)
				model:SetAttribute(Data.stageAttribute, Data.familyId)
				model:SetAttribute(Data.rockAttribute, Data.familyId)
				model:SetAttribute(Data.kindAttribute, rock.kind)
				model:SetAttribute("Band", rock.band)
				model.Parent = folder
			end)
			if not okConfigure then
				fail("could not configure rock " .. index)
				continue
			end
			for _, recipe in ipairs(Data.partsFor(rock)) do
				addPart(model, rock, recipe, index, MapSpec.GROUND_Y)
			end
			stagedRocks += 1
		end
		if stagedRocks ~= Data.count(rocks) then
			fail("staged " .. stagedRocks .. "/" .. Data.count(rocks) .. " rocks")
		end
		pcall(function()
			folder:SetAttribute("RockCount", stagedRocks)
		end)
		publishFailures()
	end,

	restore = function()
		clearActive()
		local previous = savedFolder
		if previous then
			pcall(function()
				previous.Parent = Workspace
			end)
			savedFolder = nil
		end
		publishFailures()
	end,
}

LookDevRocksR9.apply = applier.apply
LookDevRocksR9.restore = applier.restore

LookDev.register(Data.familyId, applier)

return LookDevRocksR9
