--!nocheck
-- WORK_QUEUE section O item 145: blocks_r9 village-block trees and shrubs.
-- Pure-data contract plus LookDev/review wiring and read-only Studio harness targets.
-- No Studio claim: CHECK evidence, tracker ticks and the visual verdict belong to the main session
-- and the designer respectively.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect

	local env = Env.new()
	local Data = env:require("shared/ModelMapBlocksR9")
	local R5 = env:require("shared/ModelMapVegetationR5")
	local R7 = env:require("shared/ModelMapVegetationR7")
	local LookDev = env:require("shared/LookDev")
	local Review = env:require("shared/LookDevReview")
	local slots = Data.slots()
	local trees = Data.trees()
	local shrubs = Data.shrubs()
	local zones = Data.exclusionZones()
	local harnessSrc = fs.readFile("tools/studio/review_check_r8.luau")
	local applierSrc = fs.readFile("src/server/World/LookDevBlocksR9.luau")
	local gallerySrc = fs.readFile("docs/v2/visual/CANDIDATES.md")

	t:describe("blocks_r9 pure data", function()
		t:it("locks the item-145 targets and the server staging name", function()
			expect(Data.id):toBe("blocks_r9")
			expect(Data.folderName):toBe("LookDevBlocksR9_blocks_r9")
			expect(Data.MIN_TREES):toBe(60)
			expect(Data.MIN_SHRUBS):toBe(80)
			expect(Data.MIN_SPECIES):toBe(4)
			expect(Data.TREE_HEIGHT_MIN):toBe(6)
			expect(Data.TREE_HEIGHT_MAX):toBe(12)
			expect(Data.MIN_SPACING):toBe(3)
			expect(Data.SCALE_JITTER):toBe(0.15)
			expect(#slots):toBe(#trees + #shrubs)
		end)

		t:it("places at least 60 trees and 80 shrubs with four tree species", function()
			expect(#trees >= 60):toBe(true)
			expect(#shrubs >= 80):toBe(true)
			expect(Data.speciesCount("tree") >= 4):toBe(true)
			local seen = {}
			for _, slot in ipairs(trees) do
				seen[slot.species] = true
			end
			for _, species in ipairs({ "mangga", "bambu", "pisang", "teh-tehan" }) do
				expect(seen[species]):toBe(true)
			end
		end)

		t:it("keeps tree heights in 6..12 with random yaw and +-15% scale", function()
			local yawBuckets, scaleMin, scaleMax = {}, math.huge, -math.huge
			for _, slot in ipairs(trees) do
				expect(slot.height >= 6 and slot.height <= 12):toBe(true)
				expect(slot.yaw >= 0 and slot.yaw < math.pi * 2):toBe(true)
				expect(slot.scale >= 0.85 and slot.scale <= 1.15):toBe(true)
				yawBuckets[math.floor(slot.yaw / (math.pi / 4)) + 1] = true
				scaleMin = math.min(scaleMin, slot.scale)
				scaleMax = math.max(scaleMax, slot.scale)
			end
			local buckets = 0
			for _ in pairs(yawBuckets) do
				buckets += 1
			end
			expect(buckets >= 4):toBe(true)
			expect(scaleMax - scaleMin >= 0.2):toBe(true)
		end)

		t:it("keeps every slot 3 studs apart, footprint-disjoint and outside R5 zones", function()
			expect(Data.minSpacing() >= 3):toBe(true)
			for _, slot in ipairs(slots) do
				expect(R5.slotAllowed(slot, zones)):toBe(true)
				expect(Data.slotAllowed(slot, zones)):toBe(true)
				expect(slot.footprint.halfX > 0 and slot.footprint.halfZ > 0):toBe(true)
			end
			for i = 1, #slots do
				for j = i + 1, #slots do
					local a, b = slots[i], slots[j]
					local disjoint = math.abs(a.x - b.x) >= a.footprint.halfX + b.footprint.halfX
						or math.abs(a.z - b.z) >= a.footprint.halfZ + b.footprint.halfZ
					expect(disjoint):toBe(true)
				end
			end
		end)

		t:it("uses only verified R7 asset keys and documented stand-ins", function()
			expect(Data.ids):toBe(R7.ids)
			for _, entry in ipairs(Data.treePlan) do
				expect(type(R7.ids[entry.key])):toBe("number")
			end
			for _, entry in ipairs(Data.shrubPlan) do
				expect(type(R7.ids[entry.key])):toBe("number")
			end
			for _, slot in ipairs(slots) do
				expect(type(R7.ids[slot.slot])):toBe("number")
			end
		end)
	end)

	t:describe("blocks_r9 LookDev wiring and review harness", function()
		t:it("ships candidate 59 with a plan, descriptor and server review path", function()
			expect(#LookDev.IDS):toBe(115)
			expect(LookDev.IDS[59]):toBe("blocks_r9")
			local candidate = LookDev.candidates.blocks_r9
			expect(candidate.id):toBe("blocks_r9")
			expect(candidate.status):toBe("candidate, awaiting designer yes")
			expect(candidate.idsSource):toBe("Shared.ModelMapBlocksR9")
			local plan = LookDev.plan("blocks_r9")
			expect(plan ~= nil):toBe(true)
			expect(plan.id):toBe("blocks_r9")
			expect(plan.idsSource):toBe("Shared.ModelMapBlocksR9")
			local entry = Review.paths.blocks_r9
			expect(entry ~= nil):toBe(true)
			expect(entry.datamodel):toBe("server")
			expect(entry.path):toEqual({ "World", "LookDevBlocksR9" })
		end)

		t:it("adds BLOCK_TREES >=60, BLOCK_SPECIES >=4 and AVATAR_FIT target 0 to ORDER", function()
			for _, name in ipairs({ "BLOCK_TREES", "BLOCK_SPECIES", "AVATAR_FIT" }) do
				expect(harnessSrc:find('"' .. name .. '"', 1, true) ~= nil):toBe(true)
			end
			expect(
				harnessSrc:find('"PATH_REACH",\n\t"BLOCK_TREES",\n\t"BLOCK_SPECIES",\n\t"AVATAR_FIT",', 1, true) ~= nil
			):toBe(true)
			expect(harnessSrc:find("blockTreeCount >= 60", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("blockSpeciesCount >= 4", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('"BLOCK_TREES",', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("60,\n\t{ folder = blocksFolder", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("4,\n\t{ folder = blocksFolder", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('"AVATAR_FIT",', 1, true) ~= nil):toBe(true)
			expect(
				harnessSrc:find("avatarGaugeWidth, avatarGaugeHeight, avatarGaugeDepth = 7, 7.25, 4", 1, true) ~= nil
			):toBe(true)
			expect(harnessSrc:find("avatarErrors == 0 and unreadableParts == 0 and avatarBlocked == 0", 1, true) ~= nil):toBe(
				true
			)
		end)

		t:it("stages clone-first, tagged, non-collidable models with a full restore", function()
			expect(applierSrc:find("LookDevAssetLoader.get(modelId, FAMILY_ID)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('SetAttribute("LookDevBlocksR9", FAMILY_ID)', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('SetAttribute("BlockTree", true)', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('SetAttribute("BlockTreeHeight", slot.height)', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('SetAttribute("BlockSpecies", slot.species)', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('SetAttribute("BlockShrub", true)', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("part.CanCollide = false", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("activeFolder:Destroy()", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("LookDev.register(FAMILY_ID", 1, true) ~= nil):toBe(true)
		end)

		t:it("records a pending, flagged gallery row", function()
			expect(gallerySrc:find("| `blocks_r9` |", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find('LookDev.enable("blocks_r9")', 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("pending — Studio checks `BLOCK_TREES`", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("no measured fps cost yet", 1, true) ~= nil):toBe(true)
		end)
	end)
end
