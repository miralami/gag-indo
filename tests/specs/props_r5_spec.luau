--!nocheck
-- WORK_QUEUE item 39: coverage-first props_r5 candidate. Pure data + server applier source checks
-- under the Env harness. No Studio claim and no visual verdict here.

local fs = require("@lune/fs")

local DATA_PATH = "src/shared/ModelMapPropsR5.luau"
local ADAPTER_PATH = "src/server/World/LookDevModelsPropsR5.luau"

return function(t, Env)
	local expect = t.expect
	local env = Env.new()
	local R4 = env:require("shared/ModelMapPropsR4")
	local Buildings = env:require("shared/ModelMapBuildingsR4")
	local R5 = env:require("shared/ModelMapPropsR5")
	local family = R5.families[R5.familyId]
	local data = fs.readFile(DATA_PATH)
	local applier = fs.readFile(ADAPTER_PATH)

	local r4ids = R4.idsFor("props_r4")
	local r4slots = {}
	for _, slot in ipairs(R4.families.props_r4.slots) do
		r4slots[slot.slot] = slot
	end
	local gudang
	for _, slot in ipairs(Buildings.families.buildings_r4.slots) do
		if slot.slot == "gudang" then
			gudang = slot
		end
	end

	local function findSlot(name)
		for _, slot in ipairs(family.slots) do
			if slot.slot == name then
				return slot
			end
		end
		return nil
	end

	local function hasLongId(text)
		return string.match(text, "%d%d%d%d%d%d%d%d%d%d%d%d") ~= nil
	end

	t:describe("props_r5 registry and ID provenance", function()
		t:it("registers the props_r5 string through LookDev", function()
			expect(string.find(applier, 'LookDev.register("props_r5"', 1, true) ~= nil):toBe(true)
			expect(R5.familyId):toBe("props_r5")
			expect(family.id):toBe("props_r5")
			expect(#R5.familyIds()):toBe(1)
			expect(R5.familyIds()[1]):toBe("props_r5")
		end)

		t:it("reuses every real R4 ID with no new numeric ID literals", function()
			expect(hasLongId(data)):toBe(false)
			expect(hasLongId(applier)):toBe(false)
			local count = 0
			for slot, id in pairs(family.ids) do
				count += 1
				expect(type(slot)):toBe("string")
				expect(type(id)):toBe("number")
				expect(r4ids[slot]):toBe(id)
			end
			expect(count):toBe(7)
			expect(R5.count()):toBe(7)
			expect(R5.idsFor("props_r5")):toBe(family.ids)
			expect(R5.idsFor("not_a_family")):toBe(nil)
		end)

		t:it("stays pure data", function()
			expect(string.find(data, "GetService", 1, true)):toBe(nil)
			expect(string.find(data, "Instance.new", 1, true)):toBe(nil)
			expect(R5.groundY):toBe(R4.groundY)
			expect(R5.PLAYER_HEIGHT):toBe(5)
		end)
	end)

	t:describe("props_r5 scales", function()
		t:it("keeps jemuran exactly unchanged", function()
			local jemuran = findSlot("jemuran")
			expect(jemuran ~= nil):toBe(true)
			expect(jemuran.scale):toBe(1)
			expect(R5.effectiveHeight(jemuran)):toBe(r4slots.jemuran.targetHeight)
			expect(jemuran.x):toBe(r4slots.jemuran.x)
			expect(jemuran.z):toBe(r4slots.jemuran.z)
			expect(jemuran.ry):toBe(r4slots.jemuran.ry)
		end)

		t:it("gives every tool a positive sane scale at a real-world height", function()
			local bands = {
				alat_tani = 3, -- hand tool, well under the 5-stud player
				gerobak = 3.5, -- cart, about waist high
				sumur = 3.5, -- well, about waist high
				lapak = 5.2, -- market stall, about head high
			}
			for slotName, maxHeight in pairs(bands) do
				local entry = findSlot(slotName)
				expect(entry ~= nil):toBe(true)
				expect(type(entry.scale)):toBe("number")
				expect(entry.scale > 0 and entry.scale <= 2):toBe(true)
				local height = R5.effectiveHeight(entry)
				expect(height > 0 and height == height):toBe(true)
				expect(height <= maxHeight):toBe(true)
				if slotName ~= "lapak" then
					expect(height < R5.PLAYER_HEIGHT):toBe(true)
				end
			end
		end)

		t:it("sorts by final stud height: hand tool < cart/well < stall", function()
			local tool = R5.effectiveHeight(findSlot("alat_tani"))
			local cart = R5.effectiveHeight(findSlot("gerobak"))
			local well = R5.effectiveHeight(findSlot("sumur"))
			local stall = R5.effectiveHeight(findSlot("lapak"))
			expect(tool < cart):toBe(true)
			expect(cart < stall):toBe(true)
			expect(well < stall):toBe(true)
		end)

		t:it("leaves the staged rows on real R4 terrain and stops staging a loose sack", function()
			expect(#family.slots):toBe(6) -- seven R4 slots minus the relocated karung
			for _, slot in ipairs(family.slots) do
				expect(r4slots[slot.slot] ~= nil):toBe(true)
				expect(slot.x):toBe(r4slots[slot.slot].x)
				expect(slot.z):toBe(r4slots[slot.slot].z)
				expect(slot.targetHeight):toBe(r4slots[slot.slot].targetHeight)
				expect(slot.rotX):toBe(0)
			end
			expect(findSlot("karung")):toBe(nil)
			expect(family.ids.karung):toBe(r4ids.karung)
		end)
	end)

	t:describe("props_r5 karung context", function()
		t:it("stacks at least two sacks on the documented gudang front apron", function()
			local group = family.karung
			expect(group ~= nil):toBe(true)
			expect(group.slot):toBe("karung")
			expect(group.context):toBe("gudang")
			expect(type(group.note)):toBe("string")
			expect(gudang ~= nil):toBe(true)
			expect(group.x):toBe(gudang.x)
			expect(group.z):toBe(gudang.z + 6)
			expect(group.z ~= r4slots.karung.z):toBe(true) -- not the loose R4 spawn row
			expect(#group.stack >= 2):toBe(true)
			expect(group.scale):toBe(1)
			expect(R5.effectiveHeight(group)):toBe(r4slots.karung.targetHeight)
		end)

		t:it("uses small offsets with one sack stacked on top", function()
			local raised = 0
			for _, sack in ipairs(family.karung.stack) do
				expect(math.abs(sack.dx) <= 2):toBe(true)
				expect(math.abs(sack.dz) <= 2):toBe(true)
				expect(sack.dy >= 0 and sack.dy <= 2):toBe(true)
				if sack.dy > 0 then
					raised += 1
				end
			end
			expect(raised >= 1):toBe(true)
		end)
	end)

	t:describe("LookDevModelsPropsR5 server applier", function()
		t:it("uses the proven R4 mechanics without embedding asset IDs", function()
			expect(string.find(applier, 'service("InsertService")', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "local id = familyMap.ids[entry.slot]", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, 'if type(id) ~= "number"', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "InsertService:LoadAsset(id)", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, 'Instance.new("Folder")', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "warn(", 1, true) ~= nil):toBe(true)
		end)

		t:it("applies the per-slot scale and expands the karung stack", function()
			expect(string.find(applier, "ModelMapPropsR5.effectiveHeight(entry)", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "model:ScaleTo(target / bodySizeY)", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "karungEntries(familyMap.karung)", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "entry.yOffset or 0", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "CFrame.Angles(entry.rotX or 0, entry.ry, 0)", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "descendant.Anchored = true", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "descendant.CanCollide = false", 1, true) ~= nil):toBe(true)
		end)

		t:it("restores the exact prior folder and destroys the instances it created", function()
			local marker = "restore = function()"
			local start = string.find(applier, marker, 1, true)
			expect(start ~= nil):toBe(true)
			local restoreBody = string.sub(applier, start + #marker)
			expect(string.find(applier, "local function clearActive()", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "folder:Destroy()", 1, true) ~= nil):toBe(true)
			expect(string.find(restoreBody, "clearActive()", 1, true) ~= nil):toBe(true)
			expect(string.find(restoreBody, "previous.Parent = Workspace", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "previous.Parent = nil", 1, true) ~= nil):toBe(true)
		end)
	end)
end
