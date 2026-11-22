--!nocheck
-- WORK_QUEUE item 36: coverage-first r5 spawn-ground candidate. Source/data assertions only;
-- the applier needs Roblox APIs. No visual verdict, no Studio claim, no asset IDs.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect
	local env = Env.new()
	local Data = env:require("shared/SpawnGroundMapR5")
	local MapSpec = env:require("server/World/MapSpec")
	local LookDev = env:require("shared/LookDev")

	local applier = fs.readFile("src/server/World/LookDevSpawnGroundR5.luau")
	local data = fs.readFile("src/shared/SpawnGroundMapR5.luau")

	t:describe("SpawnGroundMapR5 data", function()
		t:it("is pure data derived from MapSpec, with no Roblox APIs or asset IDs", function()
			expect(Data.id):toBe("spawn_ground_r5")
			expect(Data.folderName):toBe("LookDevSpawnGroundR5")
			expect(data:find("GetService", 1, true)):toBe(nil)
			expect(data:find("Instance.new", 1, true)):toBe(nil)
			expect(data:find("rbxassetid", 1, true)):toBe(nil)
			expect(data:find("%d%d%d%d%d%d%d")):toBe(nil)
			expect(applier:find("rbxassetid", 1, true)):toBe(nil)
			expect(applier:find("%d%d%d%d%d%d%d")):toBe(nil)
			expect(#Data.pathRects(MapSpec)):toBe(
				#MapSpec.roadArms() + #MapSpec.ringSegments() + #MapSpec.roadContinuations()
			)
		end)

		t:it("keeps the default road and stores the alternative behind the flag", function()
			expect(data:find("REMAIN THE DEFAULT", 1, true) ~= nil):toBe(true)
			expect(data:find("stored alternative behind the LookDev flag", 1, true) ~= nil):toBe(true)
			expect(applier:find('LookDev.enable("spawn_ground_r5")', 1, true) ~= nil):toBe(true)
		end)

		t:it("uses earth/dirt materials and no Slate kerb", function()
			expect(LookDev.isBuiltinMaterial(Data.materials.path)):toBe(true)
			expect(LookDev.isBuiltinMaterial(Data.materials.feather)):toBe(true)
			expect(Data.materials.path):toBe("Ground")
			expect(Data.materials.feather):toBe("Mud")
			expect(Data.materials.path == "Slate" or Data.materials.feather == "Slate"):toBe(false)
			expect(applier:find("Enum.Material.Slate", 1, true)):toBe(nil)
			expect(applier:find("RoadEdge = true", 1, true) ~= nil):toBe(true) -- hide only, never create
		end)

		t:it("layers paths above terrain and old mud without coplanar faces", function()
			local h = Data.heights
			expect(h.pathThickness > 0 and h.featherThickness > 0):toBe(true)
			expect(h.featherLift - h.featherThickness / 2 > 0.17):toBe(true) -- old MudPatch top
			expect(h.pathLift - h.pathThickness / 2 > h.featherLift + h.featherThickness / 2):toBe(true)
			expect(applier:find("MapSpec.GROUND_Y + height", 1, true) ~= nil):toBe(true)
			expect(applier:find("part.CanCollide = false", 1, true) ~= nil):toBe(true)
		end)
	end)

	t:describe("SpawnGroundMapR5 footprints", function()
		t:it("builds conservative rectangles from every MapSpec road family", function()
			local names = {}
			for _, path in ipairs(Data.pathRects(MapSpec)) do
				expect(path.halfX >= 0 and path.halfZ >= 0):toBe(true)
				expect(path.sx > 0 and path.sz > 0):toBe(true)
				names[path.name] = true
			end
			for _, name in ipairs({ "RoadEast", "RoadNorth", "RingRoad", "RoadToBridge" }) do
				expect(names[name]):toBe(true)
			end
			expect(Data.intersects({ x = 0, z = 0, halfX = 1, halfZ = 1 }, { x = 3, z = 0, halfX = 1, halfZ = 1 })):toBe(
				false
			)
			expect(Data.intersects({ x = 0, z = 0, halfX = 2, halfZ = 1 }, { x = 3, z = 0, halfX = 1, halfZ = 1 })):toBe(
				true
			)
		end)

		t:it("excludes hub footprints and tagged PlotAnchor zones from every placed path", function()
			local anchor = { x = 0, z = 100, halfX = 6, halfZ = 6 }
			local zones = Data.exclusionRects(MapSpec, { anchor })
			expect(#zones):toBe(#MapSpec.HUBS + 1)
			local allowed = Data.allowedRects(MapSpec, { anchor })
			expect(#allowed < #Data.pathRects(MapSpec)):toBe(true)
			local kept = {}
			for _, path in ipairs(allowed) do
				kept[path.name] = true
				for _, zone in ipairs(zones) do
					expect(Data.intersects(Data.featherRect(path), zone)):toBe(false)
				end
			end
			-- Pos Ronda's rotated hub AABB reaches the west arm end; its margin must trim it.
			expect(kept.RoadWest):toBe(nil)
			expect(kept.RoadSouth):toBe(nil) -- the fake PlotAnchor at (0, 100)
			expect(kept.RoadNorth):toBe(true)
			expect(applier:find("Map.TAGS.PlotAnchor", 1, true) ~= nil):toBe(true)
			expect(applier:find("SpawnGroundMapR5.allowedRects(MapSpec, anchorRects())", 1, true) ~= nil):toBe(true)
		end)

		t:it("carries soft-edge width and low opacity data", function()
			expect(Data.feather.overhang > 0):toBe(true)
			expect(Data.feather.transparency > 0 and Data.feather.transparency < 1):toBe(true)
			local path = Data.pathRects(MapSpec)[1]
			local feather = Data.featherRect(path)
			expect(feather.sx > path.sx and feather.sz > path.sz):toBe(true)
			expect(feather.halfX > path.halfX and feather.halfZ > path.halfZ):toBe(true)
			expect(applier:find('"Feather"', 1, true) ~= nil):toBe(true)
			expect(applier:find("part.Transparency = transparency", 1, true) ~= nil):toBe(true)
			expect(applier:find("SpawnGroundMapR5.featherRect(path)", 1, true) ~= nil):toBe(true)
		end)
	end)

	t:describe("LookDevSpawnGroundR5 applier source", function()
		t:it("registers the off-by-default candidate and exposes apply/restore", function()
			expect(
				applier:find('LookDev.register("spawn_ground_r5", { apply = apply, restore = restore })', 1, true)
					~= nil
			):toBe(true)
			expect(applier:find("LookDevSpawnGroundR5.apply = apply", 1, true) ~= nil):toBe(true)
			expect(applier:find("LookDevSpawnGroundR5.restore = restore", 1, true) ~= nil):toBe(true)
			expect(applier:find("local function apply()", 1, true) ~= nil):toBe(true)
			expect(applier:find("local function restore()", 1, true) ~= nil):toBe(true)
		end)

		t:it("hides roads and overlapping MudPatch while recording exact prior state", function()
			expect(applier:find("saved[part] = { visible = visible, canCollide = canCollide }", 1, true) ~= nil):toBe(
				true
			)
			expect(applier:find("part.Visible = false", 1, true) ~= nil):toBe(true)
			expect(applier:find("part.CanCollide = false", 1, true) ~= nil):toBe(true)
			expect(applier:find('instance.Name == "MudPatch"', 1, true) ~= nil):toBe(true)
			expect(
				applier:find("SpawnGroundMapR5.intersects(disc, SpawnGroundMapR5.featherRect(path))", 1, true) ~= nil
			):toBe(true)
			expect(applier:find("hide(instance)", 1, true) ~= nil):toBe(true)
		end)

		t:it("restores every saved state exactly and destroys everything created", function()
			expect(applier:find("for part, state in pairs(saved) do", 1, true) ~= nil):toBe(true)
			expect(applier:find("part.Visible = state.visible", 1, true) ~= nil):toBe(true)
			expect(applier:find("part.CanCollide = state.canCollide", 1, true) ~= nil):toBe(true)
			expect(applier:find("saved = {}", 1, true) ~= nil):toBe(true)
			expect(applier:find("createdFolder:Destroy()", 1, true) ~= nil):toBe(true)
			expect(applier:find("createdFolder = nil", 1, true) ~= nil):toBe(true)
			expect(applier:find('Instance.new("Folder")', 1, true) ~= nil):toBe(true)
		end)

		t:it("guards Roblox calls with pcall so a bad toggle cannot break the server", function()
			local _, guards = string.gsub(applier, "pcall%(", "")
			expect(guards >= 8):toBe(true)
		end)
	end)
end
