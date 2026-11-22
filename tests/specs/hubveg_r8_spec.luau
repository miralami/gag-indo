--!nocheck
-- WORK_QUEUE section M item 70 (densified in section O item 144): hubveg_r8 per-hub vegetation.
-- Pure-data contract plus the server LookDev wiring and the read-only Studio harness targets.
-- No Studio claim: visual verdict and CHECK evidence belong to the main session. Every slot must
-- survive the same R5 exclusion zones + 6-stud door lanes the applier uses at runtime.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect

	local env = Env.new()
	local Data = env:require("shared/ModelMapVegetationHubR8")
	local MapSpec = env:require("server/World/MapSpec")
	local R5 = env:require("shared/ModelMapVegetationR5")
	local LookDev = env:require("shared/LookDev")
	local Review = env:require("shared/LookDevReview")
	local zones = R5.exclusionZones(MapSpec, {})
	local slots = Data.slots()
	local harnessSrc = fs.readFile("tools/studio/review_check_r8.luau")

	-- Measured in a real Studio Play probe (main session, 2026-11-21): max/avg XZ AABB spans of
	-- the scaled r8 instances. A rotated AABB can be up to ~1.41x the unrotated span, and the
	-- harness VEG_OVERLAP check uses a 0.05 stud tolerance, so the conservative half-span floor
	-- below is max/2 * 1.41 + 0.05. The four item-144 entries use the SCALED span (base * target /
	-- native height); their group member offsets are documented in the data module's comments.
	local MEASURED_XZ_SPAN = {
		mangga = { max = 23.94, avg = 21.74 },
		pisang = { max = 17.52, avg = 15.93 },
		puring = { max = 6.94, avg = 6.02 },
		bambu = { max = 6.03, avg = 5.14 },
		["kembang sepatu"] = { max = 4.99, avg = 4.42 },
		bunga = { max = 4.5, avg = 3.89 },
		["teh-tehan"] = { max = 3.61, avg = 3.31 },
		keladi = { max = 3.36, avg = 3.02 },
		talas = { max = 3.33, avg = 2.85 },
		["alang-alang"] = { max = 1.87, avg = 1.63 },
		["lidah mertua"] = { max = 0.61, avg = 0.54 },
		mangga_tree = { max = 8.71, avg = 7.91 }, -- mangga 22 -> 8 studs
		pisang_group = { max = 8.47, avg = 7.70 }, -- pisang 12 -> 5.8 studs
		bambu_clump = { max = 3.45, avg = 2.94 }, -- bambu 21 -> 12 studs
		bunga_bed = { max = 2.14, avg = 1.85 }, -- bunga 2 -> 0.95 studs
		shrub_bed = { max = 1.87, avg = 1.66 }, -- kembang sepatu 4 -> 1.5 studs
	}

	t:describe("hubveg_r8 per-hub vegetation data", function()
		t:it("derives all six hubs from MapSpec and keeps the server staging name", function()
			expect(Data.id):toBe("hubveg_r8")
			expect(Data.folderName):toBe("LookDevModelsVegetationHubR8_hubveg_r8")
			expect(Data.hubKeys):toEqual(MapSpec.HUB_ORDER)
			expect(#Data.hubKeys):toBe(6)
			expect(Data.RADIUS):toBe(40)
			expect(Data.MIN_SPACING):toBe(2)
			expect(Data.MIN_PER_HUB):toBe(30)
			expect(Data.TARGET_PER_HUB >= 30):toBe(true)
			expect(Data.MIN_TREES):toBe(2)
			expect(Data.TREE_HEIGHT_MIN):toBe(8)
			expect(Data.TREE_HEIGHT_MAX):toBe(12)
			expect(Data.PISANG_GROUPS):toBe(2)
			expect(Data.PISANG_GROUP_SIZE):toBe(3)
			expect(Data.BAMBU_CLUMPS):toBe(2)
			expect(Data.BAMBU_CLUMP_MIN):toBe(5)
			expect(Data.BAMBU_CLUMP_MAX):toBe(7)
			expect(Data.BAMBU_CULM_HEIGHT_MIN):toBe(10)
			expect(Data.MIN_SPECIES_PER_HUB):toBe(4)
			expect(#slots):toBe(6 * Data.TARGET_PER_HUB)
		end)

		t:it("places at least 30 allowed slots and 4 species inside 40 studs of every hub", function()
			for _, key in ipairs(Data.hubKeys) do
				local hub = MapSpec.hub(key)
				local list = Data.slotsForHub(key)
				expect(#list >= Data.MIN_PER_HUB):toBe(true)
				expect(Data.countForHub(key, zones)):toBe(#list)
				expect(#Data.speciesForHub(key, zones) >= Data.MIN_SPECIES_PER_HUB):toBe(true)
				for _, slot in ipairs(list) do
					expect(slot.hub):toBe(key)
					local dx, dz = slot.x - hub.x, slot.z - hub.z
					expect(dx * dx + dz * dz <= Data.RADIUS ^ 2):toBe(true)
					expect(Data.slotAllowed(slot, zones)):toBe(true)
					expect(Data.clearOfLane(slot)):toBe(true)
				end
			end
		end)

		t:it("keeps every pair of slots at least 2 studs apart", function()
			local minimum = math.huge
			for i = 1, #slots do
				for j = i + 1, #slots do
					local dx, dz = slots[i].x - slots[j].x, slots[i].z - slots[j].z
					minimum = math.min(minimum, math.sqrt(dx * dx + dz * dz))
				end
			end
			expect(minimum >= Data.MIN_SPACING):toBe(true)
		end)

		t:it("uses only real R7 asset IDs and the documented species set", function()
			local required = {
				bambu = true,
				["teh-tehan"] = true,
				["kembang sepatu"] = true,
				["alang-alang"] = true,
				talas = true,
				keladi = true,
				bunga = true,
				puring = true,
				["lidah mertua"] = true,
				mangga_tree = true,
				pisang_group = true,
				bambu_clump = true,
				bunga_bed = true,
				shrub_bed = true,
			}
			local seen = {}
			for _, slot in ipairs(slots) do
				expect(required[slot.species]):toBe(true)
				expect(MEASURED_XZ_SPAN[slot.species] ~= nil):toBe(true)
				expect(Data.speciesAsset[slot.species]):toBe(slot.slot)
				expect(type(Data.ids[slot.slot])):toBe("number")
				expect(Data.ids[slot.slot] > 0):toBe(true)
				expect(slot.rotX):toBe(0)
				expect(slot.targetHeight > 0):toBe(true)
				seen[slot.species] = true
			end
			for species in pairs(required) do
				expect(seen[species]):toBe(true)
			end
			expect(#Data.speciesOrder):toBe(9)
			for _, name in ipairs(Data.speciesOrder) do
				expect(name ~= "mangga" and name ~= "pisang"):toBe(true)
				expect(required[name]):toBe(true)
			end
		end)

		t:it("gives every slot a footprint covering its measured scaled bbox", function()
			for species, measured in pairs(MEASURED_XZ_SPAN) do
				if species ~= "mangga" and species ~= "pisang" then
					local footprint = Data.footprints[species]
					expect(footprint ~= nil):toBe(true)
					if not footprint then
						continue
					end
					local conservative = measured.max * 0.5 * 1.41 + 0.05
					expect(footprint.halfX >= conservative):toBe(true)
					expect(footprint.halfZ >= conservative):toBe(true)
				end
			end
			for _, slot in ipairs(slots) do
				local footprint = Data.footprints[slot.species]
				expect(footprint ~= nil):toBe(true)
				if not footprint then
					continue
				end
				expect(slot.footprint.halfX):toBe(footprint.halfX)
				expect(slot.footprint.halfZ):toBe(footprint.halfZ)
			end
		end)

		t:it("gives every hub 2 canopy trees at 8-12 studs", function()
			for _, key in ipairs(Data.hubKeys) do
				expect(Data.treesForHub(key, zones)):toBeAtLeast(Data.MIN_TREES)
				local trees = {}
				for _, slot in ipairs(Data.slotsForHub(key)) do
					if slot.kind == "tree" then
						trees[#trees + 1] = slot
						expect(slot.species):toBe("mangga_tree")
						expect(slot.targetHeight >= Data.TREE_HEIGHT_MIN):toBe(true)
						expect(slot.targetHeight <= Data.TREE_HEIGHT_MAX):toBe(true)
						expect(slot.footprint.halfX):toBe(Data.footprints.mangga_tree.halfX)
					end
				end
				expect(#trees >= Data.MIN_TREES):toBe(true)
			end
		end)

		t:it("gives every hub 2 pisang groups of 3 and 2 bamboo clumps of 5-7 culms >=10 studs", function()
			for _, key in ipairs(Data.hubKeys) do
				expect(Data.pisangGroupsForHub(key, zones)):toBe(Data.PISANG_GROUPS)
				expect(Data.bambuClumpsForHub(key, zones)):toBe(Data.BAMBU_CLUMPS)
				local groups, clumps = {}, {}
				for _, slot in ipairs(Data.slotsForHub(key)) do
					if slot.kind == "pisang_group" then
						groups[slot.group] = (groups[slot.group] or 0) + #slot.members
						expect(#slot.members):toBe(Data.PISANG_GROUP_SIZE)
						for _, member in ipairs(slot.members) do
							local dx, dz = member.x - slot.x, member.z - slot.z
							expect(dx * dx + dz * dz <= 0.3 ^ 2 + 0.0001):toBe(true)
						end
					elseif slot.kind == "bambu_clump" then
						clumps[slot.group] = (clumps[slot.group] or 0) + #slot.members
						expect(#slot.members >= Data.BAMBU_CLUMP_MIN):toBe(true)
						expect(#slot.members <= Data.BAMBU_CLUMP_MAX):toBe(true)
						for _, member in ipairs(slot.members) do
							expect(member.targetHeight >= Data.BAMBU_CULM_HEIGHT_MIN):toBe(true)
							local dx, dz = member.x - slot.x, member.z - slot.z
							expect(dx * dx + dz * dz <= 1.01 ^ 2):toBe(true)
						end
					end
				end
				local nGroups, nClumps = 0, 0
				for _, count in pairs(groups) do
					expect(count):toBe(Data.PISANG_GROUP_SIZE)
					nGroups += 1
				end
				for _, count in pairs(clumps) do
					expect(count >= Data.BAMBU_CLUMP_MIN):toBe(true)
					expect(count <= Data.BAMBU_CLUMP_MAX):toBe(true)
					nClumps += 1
				end
				expect(nGroups):toBe(Data.PISANG_GROUPS)
				expect(nClumps):toBe(Data.BAMBU_CLUMPS)
			end
		end)

		t:it("puts flower beds and shrubs near every door, clear of the 6-stud lane", function()
			expect(#Data.doorLanes):toBe(6)
			for _, key in ipairs(Data.hubKeys) do
				local flowers, shrubs = 0, 0
				for _, slot in ipairs(Data.slotsForHub(key)) do
					if slot.kind == "door_bed" then
						expect(Data.clearOfLane(slot)):toBe(true)
						if slot.species == "bunga_bed" then
							flowers += 1
						elseif slot.species == "shrub_bed" then
							shrubs += 1
						end
					end
				end
				expect(flowers >= 2):toBe(true)
				expect(shrubs >= 2):toBe(true)
			end
		end)

		t:it("rebuilds the identical slot table from a fresh module instance", function()
			local other = Env.new():require("shared/ModelMapVegetationHubR8")
			expect(other.slots()):toEqual(slots)
		end)
	end)

	t:describe("hubveg_r8 server LookDev wiring", function()
		t:it("registers as candidate 47 (of 58) with a plan and a server review path", function()
			expect(#LookDev.IDS):toBe(111)
			expect(LookDev.IDS[47]):toBe("hubveg_r8")
			expect(LookDev.candidates.hubveg_r8.status):toBe("candidate, awaiting designer yes")
			expect(LookDev.candidates.hubveg_r8.idsSource):toBe("Shared.ModelMapVegetationHubR8")
			local plan = LookDev.plan("hubveg_r8")
			expect(plan ~= nil):toBe(true)
			expect(plan.id):toBe("hubveg_r8")
			expect(Review.paths.hubveg_r8.datamodel):toBe("server")
			expect(Review.paths.hubveg_r8.path):toEqual({ "World", "LookDevModelsVegetationHubR8" })
		end)

		t:it("clones first, filters at apply time, tags hubs and restores only its folder", function()
			local applier = fs.readFile("src/server/World/LookDevModelsVegetationHubR8.luau")
			expect(string.find(applier, "LookDev.register(FAMILY_ID", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "LookDevAssetLoader.get(modelId, FAMILY_ID)", 1, true) ~= nil):toBe(true)
			expect(
				string.find(applier, "Data.exclusionZones(require(script.Parent.MapSpec), plotRects())", 1, true) ~= nil
			):toBe(true)
			expect(string.find(applier, "Data.slotAllowed(slot, zones)", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, 'SetAttribute("LookDevHubVegR8", FAMILY_ID)', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, 'SetAttribute("Hub", slot.hub)', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, 'SetAttribute("Species", slot.species)', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, 'SetAttribute("HubVegTree", true)', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, 'SetAttribute("HubVegTreeHeight", slot.targetHeight)', 1, true) ~= nil):toBe(
				true
			)
			expect(string.find(applier, 'SetAttribute("HubVegGroup", slot.group)', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, 'SetAttribute("HubVegGroupKind", slot.groupKind)', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, 'SetAttribute("HubVegCulmHeight", member.targetHeight)', 1, true) ~= nil):toBe(
				true
			)
			expect(string.find(applier, "LookDevFailures).set(FAMILY_ID, failures)", 1, true) ~= nil):toBe(true)
			local main = fs.readFile("src/server/Main.server.luau")
			expect(
				string.find(main, "pcall(require, script.Parent.World.LookDevModelsVegetationHubR8)", 1, true) ~= nil
			):toBe(true)
		end)
	end)

	t:describe("hubveg_r8 Studio harness targets", function()
		t:it("raises VEG_HUB to 30 and adds read-only HUB_TREES and PATH_REACH", function()
			expect(string.find(harnessSrc, "local HUB_VEG_MIN_COUNT = 30", 1, true) ~= nil):toBe(true)
			expect(
				string.find(harnessSrc, "local HUB_TREE_MIN, TREE_HEIGHT_MIN, TREE_HEIGHT_MAX = 2, 8, 12", 1, true)
					~= nil
			):toBe(true)
			expect(string.find(harnessSrc, 'emit(\n\t"HUB_TREES"', 1, true) ~= nil):toBe(true)
			expect(
				string.find(harnessSrc, 'emit("PATH_REACH", pathLaneOk and blockedLanes == 0, blockedLanes, 0', 1, true)
					~= nil
			):toBe(true)
			local orderStart = string.find(harnessSrc, "local ORDER = {", 1, true)
			local orderEnd = string.find(harnessSrc, "\n}\n", orderStart, true)
			expect(orderStart ~= nil and orderEnd ~= nil):toBe(true)
			local order = string.sub(harnessSrc, orderStart, orderEnd)
			for _, name in ipairs({
				"VEG_HUB_pasar",
				"VEG_SPECIES_HUB",
				"HUB_TREES",
				"VEG_OVERLAP",
				"PATH_REACH",
				"DOOR_CLEAR",
			}) do
				expect(string.find(order, '"' .. name .. '"', 1, true) ~= nil):toBe(true)
			end
		end)
	end)
end
