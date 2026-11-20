--!nocheck
-- WORK_QUEUE item 45: coverage-first r6 spawn-ground candidate. Source/data assertions only;
-- the applier needs Roblox APIs. No visual verdict, no Studio claim, no asset IDs.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect
	local env = Env.new()
	local Data = env:require("shared/SpawnGroundMapR6")
	local Old = env:require("shared/SpawnGroundMapR5")
	local MapSpec = env:require("server/World/MapSpec")
	local LookDev = env:require("shared/LookDev")
	local Review = env:require("shared/LookDevReview")

	local applier = fs.readFile("src/server/World/LookDevSpawnGroundR6.luau")
	local data = fs.readFile("src/shared/SpawnGroundMapR6.luau")
	local mapSpecSrc = fs.readFile("src/server/World/MapSpec.luau")
	local greyboxSrc = fs.readFile("src/server/World/Greybox.luau")
	local floraSrc = fs.readFile("src/server/World/Flora.luau")
	local decorSrc = fs.readFile("src/server/World/Decor.luau")
	local mainSrc = fs.readFile("src/server/Main.server.luau")

	local function centre(rect)
		return { x = rect.x, z = rect.z, halfX = 0.01, halfZ = 0.01 }
	end

	t:describe("SpawnGroundMapR6 data", function()
		t:it("is pure data with no Roblox APIs or asset IDs and leaves R5 untouched", function()
			expect(Data.id):toBe("spawn_ground_r6")
			expect(Data.folderName):toBe("LookDevSpawnGroundR6")
			expect(data:find("GetService", 1, true)):toBe(nil)
			expect(data:find("Instance.new", 1, true)):toBe(nil)
			expect(data:find("rbxassetid", 1, true)):toBe(nil)
			expect(data:find("%d%d%d%d%d%d%d")):toBe(nil)
			expect(applier:find("rbxassetid", 1, true)):toBe(nil)
			expect(applier:find("%d%d%d%d%d%d%d")):toBe(nil)
			expect(Old.id):toBe("spawn_ground_r5")
			expect(Old.folderName):toBe("LookDevSpawnGroundR5")
			expect(data:find("Nothing here mutates SpawnGroundMapR5", 1, true) ~= nil):toBe(true)
			expect(applier:find("buildRoads / MapSpec / Greybox / Flora / Decor code stays untouched", 1, true) ~= nil):toBe(
				true
			)
			expect(applier:find('LookDev.enable("spawn_ground_r6")', 1, true) ~= nil):toBe(true)
		end)

		t:it("uses earth/dirt materials and no Slate kerb", function()
			expect(LookDev.isBuiltinMaterial(Data.materials.path)):toBe(true)
			expect(LookDev.isBuiltinMaterial(Data.materials.feather)):toBe(true)
			expect(LookDev.isBuiltinMaterial(Data.materials.corridor)):toBe(true)
			expect(Data.materials.path):toBe("Ground")
			expect(Data.materials.feather):toBe("Mud")
			expect(Data.materials.corridor):toBe("Ground")
			expect(
				Data.materials.path == "Slate"
					or Data.materials.feather == "Slate"
					or Data.materials.corridor == "Slate"
			):toBe(false)
			expect(applier:find("Enum.Material.Slate", 1, true)):toBe(nil)
			expect(applier:find("local names = { RoadEdge = true }", 1, true) ~= nil):toBe(true) -- hide only
		end)

		t:it("layers corridor, feather and path without coplanar faces above old mud", function()
			local h = Data.heights
			expect(h.corridorThickness > 0 and h.featherThickness > 0 and h.pathThickness > 0):toBe(true)
			expect(h.corridorLift - h.corridorThickness / 2 > 0.17):toBe(true)
			expect(h.featherLift - h.featherThickness / 2 > h.corridorLift + h.corridorThickness / 2):toBe(true)
			expect(h.pathLift - h.pathThickness / 2 > h.featherLift + h.featherThickness / 2):toBe(true)
			expect(h.corridorStagger > 0):toBe(true)
			expect(applier:find("MapSpec.GROUND_Y + height", 1, true) ~= nil):toBe(true)
			expect(applier:find("part.CanCollide = false", 1, true) ~= nil):toBe(true)
		end)
	end)

	t:describe("SpawnGroundMapR6 full road coverage", function()
		t:it("derives the tanah core from every MapSpec road family", function()
			expect(#Data.pathRects(MapSpec)):toBe(
				#MapSpec.roadArms() + #MapSpec.ringSegments() + #MapSpec.roadContinuations()
			)
			local names = {}
			for _, path in ipairs(Data.pathRects(MapSpec)) do
				expect(path.halfX > 0 and path.halfZ > 0):toBe(true)
				names[path.name] = true
			end
			for _, name in ipairs({ "RoadEast", "RoadNorth", "RoadSouth", "RingRoad", "RoadToBridge" }) do
				expect(names[name]):toBe(true)
			end
		end)

		t:it("covers the full corridor including the 30-wide back ring strip R5 missed", function()
			local corridors = Data.corridorRects(MapSpec)
			expect(#corridors):toBe(2 + #MapSpec.roadContinuations() + Data.corridor.ringBlocks)
			expect(Data.corridor.ringBlock >= MapSpec.ROAD.ringWidth):toBe(true)
			expect(mapSpecSrc:find('30, TERRAIN_VOXEL, 30, "Ground"', 1, true) ~= nil):toBe(true)
			local ring = 0
			for _, rect in ipairs(corridors) do
				if rect.name == "CorridorRing" then
					ring += 1
					expect(rect.sx):toBe(Data.corridor.ringBlock)
					expect(rect.sz):toBe(Data.corridor.ringBlock)
					local radius = math.sqrt(rect.x * rect.x + rect.z * rect.z)
					expect(math.abs(radius - MapSpec.ROAD.ringCentre) < 0.01):toBe(true)
				end
			end
			expect(ring):toBe(Data.corridor.ringBlocks)
			local covers = Data.coverRects(MapSpec, {})
			local coveredRing = 0
			for _, cover in ipairs(covers) do
				if string.find(cover.name, "CorridorRing_", 1, true) then
					coveredRing += 1
				end
			end
			expect(coveredRing >= Data.corridor.ringBlocks):toBe(true)
			-- Every tanah core piece sits on some surviving cover or is itself an allowed path.
			local allowed = Data.allowedRects(MapSpec, {})
			for _, path in ipairs(Data.pathRects(MapSpec)) do
				local found = false
				for _, piece in ipairs(allowed) do
					if Data.intersects(centre(path), centre(piece)) then
						found = true
						break
					end
				end
				if not found then
					for _, cover in ipairs(covers) do
						if Data.intersects(centre(path), cover) then
							found = true
							break
						end
					end
				end
				expect(found):toBe(true)
			end
			expect(applier:find("SpawnGroundMapR6.coverRects(MapSpec, anchors)", 1, true) ~= nil):toBe(true)
			expect(applier:find("buildCovers(covers)", 1, true) ~= nil):toBe(true)
		end)

		t:it("clips every corridor fragment clear of hubs, plaza, plots and future slots", function()
			local anchor = { x = 0, z = 100, halfX = 6, halfZ = 6 }
			local zones = Data.coverExclusionRects(MapSpec, { anchor })
			expect(#zones):toBe(#MapSpec.keepOutRects() + 1)
			expect(#Data.coverRects(MapSpec, { anchor }) > #Data.corridorRects(MapSpec)):toBe(true)
			for _, cover in ipairs(Data.coverRects(MapSpec, { anchor })) do
				for _, zone in ipairs(zones) do
					expect(Data.intersects(cover, zone)):toBe(false)
				end
			end
			expect(
				Data.subtractRect({ x = 0, z = 0, sx = 10, sz = 10 }, { x = 0, z = 0, halfX = 2, halfZ = 2 })[1].sx
					~= nil
			):toBe(true)
			expect(#Data.subtractRect({ x = 0, z = 0, sx = 10, sz = 10 }, { x = 20, z = 0, halfX = 2, halfZ = 2 })):toBe(
				1
			)
		end)
	end)

	t:describe("SpawnGroundMapR6 flower-bed and plot grass mask", function()
		t:it("copies Decor bed centres/radius and masks beds plus tagged plots", function()
			expect(#Data.flowerBeds):toBe(6)
			expect(Data.flowerBedRadius):toBe(5.6)
			expect(decorSrc:find("local BED_RADIUS = 5.6", 1, true) ~= nil):toBe(true)
			expect(decorSrc:find('Name = "BedSoil"', 1, true) ~= nil):toBe(true)
			expect(decorSrc:find('Name = "Flower"', 1, true) ~= nil):toBe(true)
			local zones = Data.grassExclusionRects(MapSpec, {})
			expect(#zones):toBe(#Data.flowerBeds)
			local anchor = { x = 100, z = 100, halfX = 6, halfZ = 6 }
			zones = Data.grassExclusionRects(MapSpec, { anchor })
			expect(#zones):toBe(#Data.flowerBeds + 1)
			for _, bed in ipairs(Data.flowerBeds) do
				expect(Data.grassBlocked(Data.grassRect(bed.x, bed.z, 1, 1), Data.grassExclusionRects(MapSpec, {}))):toBe(
					true
				)
			end
			expect(Data.grassBlocked(Data.grassRect(100, 100, 1, 1), zones)):toBe(true)
			expect(Data.grassBlocked(Data.grassRect(0, 200, 1, 1), zones)):toBe(false)
			expect(Data.grassRect(0, 0, 2, 1).halfX > 1):toBe(true)
		end)

		t:it("masks ONLY grass wedges, saving exact prior state, never editing Flora", function()
			expect(applier:find('instance:IsA("WedgePart") and instance.Name == "FloraGrass"', 1, true) ~= nil):toBe(
				true
			)
			expect(applier:find("SpawnGroundMapR6.grassRect(position.X, position.Z, size.X, size.Z)", 1, true) ~= nil):toBe(
				true
			)
			expect(applier:find("SpawnGroundMapR6.grassBlocked(footprint, zones)", 1, true) ~= nil):toBe(true)
			expect(applier:find("hide(instance)", 1, true) ~= nil):toBe(true)
			expect(floraSrc:find('name = "FloraGrass"', 1, true) ~= nil):toBe(true)
			expect(floraSrc:find('class = "WedgePart"', 1, true) ~= nil):toBe(true)
			expect(floraSrc:find("local function flowerBeds", 1, true)):toBe(nil)
			expect(applier:find("Flora.build", 1, true)):toBe(nil)
		end)
	end)

	t:describe("LookDevSpawnGroundR6 applier source", function()
		t:it("registers the off-by-default candidate and wires registry, review and bootstrap", function()
			expect(
				applier:find('LookDev.register("spawn_ground_r6", { apply = apply, restore = restore })', 1, true)
					~= nil
			):toBe(true)
			expect(applier:find("LookDevSpawnGroundR6.apply = apply", 1, true) ~= nil):toBe(true)
			expect(applier:find("LookDevSpawnGroundR6.restore = restore", 1, true) ~= nil):toBe(true)
			expect(applier:find("local function apply()", 1, true) ~= nil):toBe(true)
			expect(applier:find("local function restore()", 1, true) ~= nil):toBe(true)
			expect(LookDev.IDS[38]):toBe("spawn_ground_r6")
			expect(LookDev.plan("spawn_ground_r6").idsSource):toBe("Shared.SpawnGroundMapR6")
			expect(LookDev.candidates.spawn_ground_r6.status):toBe("candidate, awaiting designer yes")
			expect(Review.pathsFor("spawn_ground_r6").datamodel):toBe("server")
			expect(Review.pathsFor("spawn_ground_r6").path):toEqual({ "World", "LookDevSpawnGroundR6" })
			expect(mainSrc:find("pcall(require, script.Parent.World.LookDevSpawnGroundR6)", 1, true) ~= nil):toBe(true)
		end)

		t:it("hides roads and overlapping mud while recording exact prior state", function()
			expect(applier:find("saved[part] = { visible = visible, canCollide = canCollide }", 1, true) ~= nil):toBe(
				true
			)
			expect(applier:find("part.Visible = false", 1, true) ~= nil):toBe(true)
			expect(applier:find("part.CanCollide = false", 1, true) ~= nil):toBe(true)
			expect(applier:find('instance.Name == "MudPatch"', 1, true) ~= nil):toBe(true)
			expect(
				applier:find("SpawnGroundMapR6.intersects(disc, SpawnGroundMapR6.featherRect(path))", 1, true) ~= nil
			):toBe(true)
			expect(applier:find("SpawnGroundMapR6.intersects(disc, cover)", 1, true) ~= nil):toBe(true)
		end)

		t:it("restores every saved state exactly and destroys everything created", function()
			expect(applier:find("for part, state in pairs(saved) do", 1, true) ~= nil):toBe(true)
			expect(applier:find("part.Visible = state.visible", 1, true) ~= nil):toBe(true)
			expect(applier:find("part.CanCollide = state.canCollide", 1, true) ~= nil):toBe(true)
			expect(applier:find("saved = {}", 1, true) ~= nil):toBe(true)
			expect(applier:find("createdFolder:Destroy()", 1, true) ~= nil):toBe(true)
			expect(applier:find("createdFolder = nil", 1, true) ~= nil):toBe(true)
			expect(applier:find('Instance.new("Folder")', 1, true) ~= nil):toBe(true)
			expect(applier:find("Map.TAGS.PlotAnchor", 1, true) ~= nil):toBe(true)
		end)

		t:it("guards Roblox calls with pcall so a bad toggle cannot break the server", function()
			local _, guards = string.gsub(applier, "pcall%(", "")
			expect(guards >= 10):toBe(true)
		end)
	end)

	t:describe("no default-code edits", function()
		t:it("leaves the shipped road generators and R5 baseline in place", function()
			expect(greyboxSrc:find("local function buildRoads(world: Folder)", 1, true) ~= nil):toBe(true)
			expect(greyboxSrc:find('Name = "RoadEdge"', 1, true) ~= nil):toBe(true)
			expect(mapSpecSrc:find("function MapSpec.roadArms()", 1, true) ~= nil):toBe(true)
			expect(floraSrc:find("function Flora.build(world: Instance)", 1, true) ~= nil):toBe(true)
			expect(decorSrc:find("function Decor.build(world: Instance)", 1, true) ~= nil):toBe(true)
			expect(
				fs.readFile("src/shared/SpawnGroundMapR5.luau"):find('SpawnGroundMapR5.id = "spawn_ground_r5"', 1, true)
					~= nil
			):toBe(true)
		end)
	end)
end
