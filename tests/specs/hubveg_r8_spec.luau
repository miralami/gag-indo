--!nocheck
-- WORK_QUEUE section M item 70: hubveg_r8 per-hub vegetation. Pure-data contract plus the
-- server LookDev wiring. No Studio claim: visual verdict and CHECK evidence belong to the main
-- session. Every slot must survive the same R5 exclusion zones the applier uses at runtime.

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

	-- Measured in a real Studio Play probe (main session, 2026-11-21): max/avg XZ AABB spans of
	-- the scaled r8 instances. A rotated AABB can be up to ~1.41x the unrotated span, and the
	-- harness VEG_OVERLAP check uses a 0.05 stud tolerance, so the conservative half-span floor
	-- below is max/2 * 1.41 + 0.05. Data.footprints must meet or exceed it for every species.
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
	}

	t:describe("hubveg_r8 per-hub vegetation data", function()
		t:it("derives all six hubs from MapSpec and keeps the server staging name", function()
			expect(Data.id):toBe("hubveg_r8")
			expect(Data.folderName):toBe("LookDevModelsVegetationHubR8_hubveg_r8")
			expect(Data.hubKeys):toEqual(MapSpec.HUB_ORDER)
			expect(#Data.hubKeys):toBe(6)
			expect(Data.RADIUS):toBe(40)
			expect(Data.MIN_SPACING):toBe(2)
			expect(Data.MIN_PER_HUB):toBe(12)
			expect(Data.MIN_SPECIES_PER_HUB):toBe(4)
			expect(#slots):toBe(96)
		end)

		t:it("places at least 12 allowed slots and 4 species inside 40 studs of every hub", function()
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
			-- Mangga and pisang stay documented in MEASURED_XZ_SPAN but are not placed: their
			-- 16-24 stud canopies cannot fit outside a hub/road inside RADIUS=40.
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

		t:it("rebuilds the identical slot table from a fresh module instance", function()
			local other = Env.new():require("shared/ModelMapVegetationHubR8")
			expect(other.slots()):toEqual(slots)
		end)
	end)

	t:describe("hubveg_r8 server LookDev wiring", function()
		t:it("registers as candidate 47 (of 48) with a plan and a server review path", function()
			expect(#LookDev.IDS):toBe(48)
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
			expect(string.find(applier, "LookDevFailures).set(FAMILY_ID, failures)", 1, true) ~= nil):toBe(true)
			local main = fs.readFile("src/server/Main.server.luau")
			expect(
				string.find(main, "pcall(require, script.Parent.World.LookDevModelsVegetationHubR8)", 1, true) ~= nil
			):toBe(true)
		end)
	end)
end
