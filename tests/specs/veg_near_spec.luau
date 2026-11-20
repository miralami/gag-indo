--!nocheck
-- WORK_QUEUE section L item 63 (round 8): VEG_NEAR regression for the near-ground vegetation layer.
-- Pure data + applier source audit under the Env harness. No Studio, no harness edit, no visual verdict.

local fs = require("@lune/fs")

local APPLIER = "src/server/World/LookDevModelsVegetationR7.luau"

return function(t, Env)
	local expect = t.expect
	local env = Env.new()
	local Veg = env:require("shared/ModelMapVegetationR7")
	local R4 = env:require("shared/ModelMapVegetationR4")
	local R6 = env:require("shared/ModelMapVegetationR6")
	local MapSpec = env:require("server/World/MapSpec")
	local applier = fs.readFile(APPLIER)
	local slots = Veg.slots()
	local near = Veg.nearSlots()
	local zones = Veg.exclusionZones(MapSpec, {})
	local eye, look = Veg.savedCamera.eye, Veg.savedCamera.look

	t:describe("VEG_NEAR near-ground layer", function()
		t:it("puts at least 25 near slots inside 45 studs and the 70-degree cone", function()
			local count, speciesCount, names, undersized = Veg.countNear()
			expect(#near >= 25):toBe(true)
			expect(count >= 25):toBe(true)
			expect(speciesCount >= 6):toBe(true)
			expect(#names):toBe(speciesCount)
			expect(undersized):toBe(0)

			local measured = 0
			for _, slot in ipairs(near) do
				if
					Veg.pointInCone(
						slot.x,
						slot.z,
						eye,
						look,
						Veg.nearCone.radius,
						Veg.cone.halfAngleDeg,
						slot.targetHeight * 0.5
					)
				then
					measured += 1
				end
			end
			expect(measured):toBe(count)
		end)

		t:it("keeps every near bbox at least 2 studs tall after scale jitter", function()
			for _, slot in ipairs(near) do
				expect(slot.baseHeight * slot.scaleJitter >= 2):toBe(true)
				expect(slot.targetHeight >= 2):toBe(true)
				expect(slot.footprint.halfX):toBe(1)
				expect(slot.footprint.halfZ):toBe(1)
				expect(slot.tier):toBe("Sedang")
				expect(slot.scaleJitter >= 0.85 and slot.scaleJitter <= 1.15):toBe(true)
				expect(slot.ry >= 0 and slot.ry <= math.pi * 2):toBe(true)
			end
		end)

		t:it("reuses only baked R4/R6 vegetation IDs", function()
			local r4 = R4.families.vegetation_r4.ids
			local seen = {}
			for _, slot in ipairs(near) do
				local id = Veg.ids[slot.slot]
				expect(type(id)):toBe("number")
				expect(id > 0 and id % 1 == 0):toBe(true)
				local known = r4[slot.slot] == id or R6.ids[slot.slot] == id
				expect(known):toBe(true)
				expect(Veg.sources[slot.slot] ~= nil):toBe(true)
				seen[slot.species] = true
			end
			local count = 0
			for _ in pairs(seen) do
				count += 1
			end
			expect(count >= 6):toBe(true)
		end)

		t:it("keeps the 2-stud spacing and every R7 exclusion zone", function()
			expect(Veg.minPairDistance() >= 2):toBe(true)
			expect(Veg.minPairDistance(near) >= 2):toBe(true)
			for _, slot in ipairs(slots) do
				expect(Veg.slotAllowed(slot, zones)):toBe(true)
			end
		end)

		t:it("does not drop the existing 100-stud VEG_COUNT / VEG_SPECIES", function()
			expect(#Veg.stagedSlots()):toBe(#slots)
			local count, speciesCount, names = Veg.countInCone()
			expect(count >= 60):toBe(true)
			expect(speciesCount >= 8):toBe(true)
			expect(#names):toBe(speciesCount)
			local far, safe = 0, 0
			for _, slot in ipairs(slots) do
				if math.abs(slot.x) == 40 and slot.z >= 66 and slot.z <= 84 then
					far += 1
				end
				local dy = slot.targetHeight * 0.5 - eye[2]
				local distance = math.sqrt((slot.x - eye[1]) ^ 2 + dy * dy + (slot.z - eye[3]) ^ 2)
				if distance <= 96 and Veg.pointInCone(slot.x, slot.z, eye, look, 100, 35, slot.targetHeight * 0.5) then
					safe += 1
				end
			end
			expect(far):toBe(20)
			expect(safe >= 60):toBe(true)
		end)

		t:it("stays inside the published tier budget and floors the staged height", function()
			local counts, triangles = Veg.budgetAudit()
			expect(counts.Sedang <= Veg.budgets.Sedang.instances):toBe(true)
			expect(triangles.Sedang <= Veg.budgets.Sedang.triangles):toBe(true)
			expect(applier:find("MIN_NEAR_HEIGHT = 2.05", 1, true) ~= nil):toBe(true)
			expect(applier:find("slot.nearGround then math.max(slot.targetHeight, MIN_NEAR_HEIGHT)", 1, true) ~= nil):toBe(
				true
			)
			expect(applier:find('SetAttribute("NearGround", true)', 1, true) ~= nil):toBe(true)
		end)
	end)
end
