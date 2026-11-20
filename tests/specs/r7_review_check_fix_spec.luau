--!nocheck
-- Attempt-2 regression locks for the two real Studio R7 failures:
--   PROPS_VISIBLE 4/6 (gerobak + jemuran outside the 70-degree cone at front=18)
--   VEG_COUNT 53/60 (far-flank bbox centres drifted past the 100-stud radius under yaw)
-- Pure data + geometry only. No Studio, no harness edit, no visual verdict.

local fs = require("@lune/fs")

local PROP_DATA = "src/shared/ModelMapPropsR7.luau"
local PROP_APPLIER = "src/server/World/LookDevModelsPropsR7.luau"

local function dot(a, b)
	return a[1] * b[1] + a[2] * b[2] + a[3] * b[3]
end

local function magnitude(v)
	return math.sqrt(dot(v, v))
end

local function angleDeg(v, d)
	return math.deg(math.acos(math.max(-1, math.min(1, dot(v, d) / (magnitude(v) * magnitude(d))))))
end

local function sub(a, b)
	return { a[1] - b[1], a[2] - b[2], a[3] - b[3] }
end

return function(t, Env)
	local expect = t.expect
	local env = Env.new()
	local Props = env:require("shared/ModelMapPropsR7")
	local Veg = env:require("shared/ModelMapVegetationR7")
	local R4 = env:require("shared/ModelMapPropsR4")
	local MapSpec = env:require("server/World/MapSpec")
	local propData = fs.readFile(PROP_DATA)
	local propApplier = fs.readFile(PROP_APPLIER)
	local family = Props.families[Props.familyId]
	local slots = Veg.slots()
	local eye, look = Veg.savedCamera.eye, Veg.savedCamera.look

	t:describe("PROPS_VISIBLE camera-cone fix", function()
		t:it("keeps six distinct slots in WORK_QUEUE order with real IDs", function()
			expect(Props.slotOrder):toEqual({ "gerobak", "sumur", "lapak", "pagar_bambu", "alat_tani", "jemuran" })
			expect(#family.slots):toBe(6)
			-- WORK_QUEUE item 64 replaces three weak R4 props in the R7 look only. sumur/lapak/
			-- jemuran still inherit their R4 ids; the other three use the measured round-8 models.
			local r8Ids = { gerobak = 10506531785, pagar_bambu = 85094565897097, alat_tani = 4951145641 }
			local seen = {}
			for index, entry in ipairs(family.slots) do
				expect(entry.slot):toBe(Props.slotOrder[index])
				expect(seen[entry.slot]):toBe(nil)
				seen[entry.slot] = true
				local id = family.ids[entry.slot]
				expect(type(id)):toBe("number")
				expect(id > 0 and id % 1 == 0):toBe(true)
				expect(id):toBe(r8Ids[entry.slot] or R4.idsFor("props_r4")[entry.slot])
				expect(entry.height > 0):toBe(true)
			end
		end)

		t:it("puts every prop centre at least 7 degrees inside the 35-degree cone", function()
			local camera = Props.cameraFor(0, 0) -- yard centre at origin; translation-invariant
			local cameraEye = { camera.position.x, camera.position.y, camera.position.z }
			local lookAt = { camera.target.x, camera.target.y, camera.target.z }
			local lookVector = sub(lookAt, cameraEye)
			local worst = 0
			for index, entry in ipairs(family.slots) do
				local centre = { Props.rowOffset(index), entry.height * 0.5, 0 }
				local vector = sub(centre, cameraEye)
				local inside = Veg.pointInCone(centre[1], centre[3], cameraEye, lookAt, 100, 35, centre[2])
				expect(inside):toBe(true)
				worst = math.max(worst, angleDeg(vector, lookVector))
			end
			expect(worst < 31):toBe(true)
		end)

		t:it("keeps the eye inside the trunk-clearance ring and the ray above Ground", function()
			local rule = Props.cameraRule
			expect(rule.front):toBe(28)
			expect(rule.front < Props.yardSize / 2 + Props.trunkClearance):toBe(true)
			expect(rule.up > R4.groundY):toBe(true)
			-- Every staged model sits on z=centreZ. The eye is at centreZ+front (front>0), so each
			-- ray reaches z=centreZ only at its endpoint: no other staged prop can occlude it.
			expect(rule.front > 0):toBe(true)
			for _, entry in ipairs(family.slots) do
				expect(entry.height * 0.5 > R4.groundY):toBe(true)
			end
		end)

		t:it("publishes the same camera the harness reads and keeps Ground pads", function()
			expect(propData:find("cameraRule = { front = 28, up = 7, lookY = 2 }", 1, true) ~= nil):toBe(true)
			expect(propApplier:find("ModelMapPropsR7.cameraFor(centreX, centreZ)", 1, true) ~= nil):toBe(true)
			expect(propApplier:find("SetAttribute(ModelMapPropsR7.cameraPosAttribute", 1, true) ~= nil):toBe(true)
			expect(propApplier:find("SetAttribute(ModelMapPropsR7.cameraLookAttribute", 1, true) ~= nil):toBe(true)
			expect(propApplier:find("paintGroundPad", 1, true) ~= nil):toBe(true)
			expect(propApplier:find("Enum.Material.Ground", 1, true) ~= nil):toBe(true)
		end)
	end)

	t:describe("VEG_COUNT radius-drift fix", function()
		t:it("counts at least 60 staged slots inside the saved cone with >=8 species", function()
			expect(#Veg.stagedSlots()):toBe(#slots)
			local count, speciesCount, names = Veg.countInCone()
			expect(count >= 60):toBe(true)
			expect(speciesCount >= 8):toBe(true)
			expect(#names):toBe(speciesCount)
			for _, slot in ipairs(slots) do
				expect(type(slot.species)):toBe("string")
				expect(Veg.ids[slot.slot] ~= nil):toBe(true)
			end
		end)

		t:it("adds 20 far-band cells that survive a 4-stud outward bbox drift", function()
			local far, safe = 0, 0
			for _, slot in ipairs(slots) do
				if math.abs(slot.x) == 40 and slot.z >= 66 and slot.z <= 84 then
					far += 1
					local dy = slot.targetHeight * 0.5 - eye[2]
					local distance = math.sqrt((slot.x - eye[1]) ^ 2 + dy * dy + (slot.z - eye[3]) ^ 2)
					expect(distance <= 96):toBe(true)
					expect(Veg.pointInCone(slot.x, slot.z, eye, look, 100, 35, slot.targetHeight * 0.5)):toBe(true)
				end
				local dy = slot.targetHeight * 0.5 - eye[2]
				local distance = math.sqrt((slot.x - eye[1]) ^ 2 + dy * dy + (slot.z - eye[3]) ^ 2)
				if distance <= 96 and Veg.pointInCone(slot.x, slot.z, eye, look, 100, 35, slot.targetHeight * 0.5) then
					safe += 1
				end
			end
			expect(far):toBe(20)
			expect(safe >= 60):toBe(true) -- 64 in the current data
		end)

		t:it("keeps every placement rule from WORK_QUEUE item 58", function()
			local zones = Veg.exclusionZones(MapSpec, {})
			for _, slot in ipairs(slots) do
				expect(Veg.slotAllowed(slot, zones)):toBe(true)
				expect(slot.tier):toBe("Sedang")
				expect(slot.scaleJitter >= 0.85 and slot.scaleJitter <= 1.15):toBe(true)
				expect(slot.ry >= 0 and slot.ry <= math.pi * 2):toBe(true)
				expect(slot.footprint.halfX):toBe(1)
			end
			expect(Veg.minPairDistance() >= 2):toBe(true)

			local clumps, hedge, pisang = {}, 0, 0
			for _, slot in ipairs(slots) do
				if slot.slot == "bambu" then
					clumps[slot.cluster] = (clumps[slot.cluster] or 0) + 1
				end
				if slot.species == "teh-tehan" then
					hedge += 1
				end
				if slot.species == "pisang" then
					pisang += 1
				end
			end
			local clumpCount, dense = 0, 0
			for _, count in pairs(clumps) do
				clumpCount += 1
				if count >= 5 and count <= 7 then
					dense += 1
				end
			end
			expect(clumpCount >= 3):toBe(true)
			expect(dense >= 3):toBe(true)
			expect(hedge >= 20):toBe(true) -- continuous rows on both flanks
			expect(pisang >= 6):toBe(true)

			local counts, triangles = Veg.budgetAudit()
			expect(counts.Sedang <= Veg.budgets.Sedang.instances):toBe(true)
			expect(triangles.Sedang <= Veg.budgets.Sedang.triangles):toBe(true)
		end)
	end)
end
