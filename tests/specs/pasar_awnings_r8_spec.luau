--!nocheck
-- WORK_QUEUE section O item 148: pasar_awnings_r8 lapak stalls and striped awnings.
-- Pure-data contract plus LookDev/review wiring, the read-only harness checks and the applier's
-- Ground-pad/restore guards. No Studio claim: CHECK evidence, tracker ticks and the visual verdict
-- belong to the main session and the designer respectively.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect

	local env = Env.new()
	local Data = env:require("shared/ModelMapPasarAwningsR8")
	local LookDev = env:require("shared/LookDev")
	local Review = env:require("shared/LookDevReview")
	local MapSpec = env:require("server/World/MapSpec")

	local dataSrc = fs.readFile("src/shared/ModelMapPasarAwningsR8.luau")
	local applierSrc = fs.readFile("src/server/World/LookDevPasarAwningsR8.luau")
	local harnessSrc = fs.readFile("tools/studio/review_check_r8.luau")
	local gallerySrc = fs.readFile("docs/v2/visual/CANDIDATES.md")

	local stalls = Data.stalls()
	local lane = Data.lane()

	t:describe("pasar_awnings_r8 pure data", function()
		t:it("locks the item-148 counts and folder/tag contract", function()
			expect(Data.id):toBe("pasar_awnings_r8")
			expect(Data.familyId):toBe("pasar_awnings_r8")
			expect(Data.folderName):toBe("LookDevPasarAwningsR8_pasar_awnings_r8")
			expect(Data.stallAttribute):toBe("PasarStall")
			expect(Data.stripeAttribute):toBe("AwningStripe")
			expect(Data.stripeColourAttribute):toBe("StripeColour")
			expect(Data.MIN_STALLS):toBe(10)
			expect(Data.MIN_STRIPES):toBe(30)
			expect(Data.count()):toBe(#stalls)
			expect(#stalls >= 10):toBe(true)
			expect(Data.padMargin > 0):toBe(true)
		end)

		t:it("has unique local anchors around the Pasar frontage", function()
			local seen = {}
			for _, stall in ipairs(stalls) do
				expect(type(stall.name)):toBe("string")
				expect(seen[stall.name]):toBe(nil)
				seen[stall.name] = true
				expect(type(stall.lx)):toBe("number")
				expect(type(stall.lz)):toBe("number")
				expect(stall.yaw == 180 or stall.yaw == 90 or stall.yaw == -90):toBe(true)
				expect(stall.size[1]):toBe(10)
				expect(stall.size[2]):toBe(8)
			end
			local pasar = MapSpec.hub("pasar")
			expect(pasar ~= nil):toBe(true)
			expect(pasar.width):toBe(64)
			expect(pasar.depth):toBe(52)
			expect(pasar.yaw):toBe(0)
		end)

		t:it("makes >=30 alternating red/white/blue awning stripes", function()
			local total = 0
			for _, stall in ipairs(stalls) do
				local stripes = Data.stripeParts()
				expect(#stripes >= 3):toBe(true)
				for index, stripe in ipairs(stripes) do
					expect(stripe.colour):toBe(Data.STRIPE_ORDER[((index - 1) % 3) + 1])
					expect(Data.COLOURS[stripe.colour] ~= nil):toBe(true)
					expect(#stripe.colour > 0):toBe(true)
					expect(type(stripe.size[1])):toBe("number")
					expect(type(stripe.offset[3])):toBe("number")
					total += 1
				end
			end
			expect(total):toBe(#stalls * Data.AWNING.count)
			expect(total >= 30):toBe(true)
			expect(#Data.stripeParts(0)):toBe(0)
		end)

		t:it("declares a 6-stud lane clear of every stall footprint", function()
			expect(lane.width):toBe(76)
			expect(lane.depth):toBe(6)
			expect(lane.lx - lane.width / 2):toBe(-38)
			expect(lane.lx + lane.width / 2):toBe(38)
			expect(lane.lz - lane.depth / 2):toBe(30)
			expect(lane.lz + lane.depth / 2):toBe(36)
			for _, stall in ipairs(stalls) do
				local rotated = stall.yaw == 90 or stall.yaw == -90
				local halfX = rotated and stall.size[2] / 2 or stall.size[1] / 2
				local halfZ = rotated and stall.size[1] / 2 or stall.size[2] / 2
				local minX, maxX = stall.lx - halfX, stall.lx + halfX
				local minZ, maxZ = stall.lz - halfZ, stall.lz + halfZ
				local overlapsX = math.min(maxX, lane.lx + lane.width / 2) > math.max(minX, lane.lx - lane.width / 2)
				local overlapsZ = math.min(maxZ, lane.lz + lane.depth / 2) > math.max(minZ, lane.lz - lane.depth / 2)
				expect(overlapsX and overlapsZ):toBe(false)
			end
		end)

		t:it("declares no asset-id literals in the pure data module", function()
			expect(string.find(dataSrc, "%d%d%d%d%d%d%d") ~= nil):toBe(false)
			expect(string.find(dataSrc, "rbxassetid://", 1, true) ~= nil):toBe(false)
			expect(string.find(dataSrc, "assetId", 1, true) ~= nil):toBe(false)
			expect(string.find(dataSrc, "Enum.", 1, true) ~= nil):toBe(false)
			expect(string.find(dataSrc, "Instance.", 1, true) ~= nil):toBe(false)
		end)
	end)

	t:describe("pasar_awnings_r8 LookDev wiring and review harness", function()
		t:it("ships candidate 61 with a descriptor, plan and server review path", function()
			expect(#LookDev.IDS):toBe(68)
			expect(LookDev.IDS[61]):toBe("pasar_awnings_r8")
			local candidate = LookDev.candidates.pasar_awnings_r8
			expect(candidate.id):toBe("pasar_awnings_r8")
			expect(candidate.style):toBe("cartoonish-realism")
			expect(candidate.status):toBe("candidate, awaiting designer yes")
			expect(candidate.idsSource):toBe("Shared.ModelMapPasarAwningsR8")
			expect(candidate.stallCount):toBe(10)
			local plan = LookDev.plan("pasar_awnings_r8")
			expect(plan ~= nil):toBe(true)
			expect(plan.id):toBe("pasar_awnings_r8")
			expect(plan.idsSource):toBe("Shared.ModelMapPasarAwningsR8")
			expect(type(plan.render)):toBe("string")
			local entry = Review.paths.pasar_awnings_r8
			expect(entry ~= nil):toBe(true)
			expect(entry.datamodel):toBe("server")
			expect(entry.path):toEqual({ "World", "LookDevPasarAwningsR8" })
		end)

		t:it("adds the four read-only checks next to HUBPROPS_ON_GRASS in ORDER", function()
			expect(
				harnessSrc:find(
					'"HUBPROPS_ON_GRASS",\n\t"STALLS",\n\t"AWNING_STRIPES",\n\t"LANE_CLEAR",\n\t"PASAR_AWNING_ON_GRASS",',
					1,
					true
				) ~= nil
			):toBe(true)
			expect(harnessSrc:find('emit("STALLS"', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('"AWNING_STRIPES",', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('emit("LANE_CLEAR"', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('emit("PASAR_AWNING_ON_GRASS"', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('"LookDevPasarAwningsR8_pasar_awnings_r8"', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('attr(inst, "PasarStall") == true', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('attr(inst, "AwningStripe") == true', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("require(game.ReplicatedStorage.Shared.ModelMapPasarAwningsR8)", 1, true) ~= nil):toBe(
				true
			)
			expect(harnessSrc:find("local GRASS_Y = 4", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("bboxAABB(part)", 1, true) ~= nil):toBe(true)
		end)
	end)

	t:describe("pasar_awnings_r8 applier", function()
		t:it("paints and restores a Ground voxel pad under every stall", function()
			expect(applierSrc:find("require((Shared :: any).ModelMapPasarAwningsR8)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('MapSpec.hub("pasar")', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("MapSpec.hubPoint(hub, recipe.lx, recipe.lz)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("MapSpec.volumeForTop(bottom, MapSpec.GROUND_Y)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("local function voxelRegion(", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("terrain:ReadVoxels(region, VOXEL)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("terrain:FillBlock(", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Enum.Material.Ground", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("terrain:WriteVoxels(entry.region", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("restoreSavedVoxels()", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("folder:Destroy()", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("LookDev.register(Data.familyId", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("created:SetAttribute(Data.stripeAttribute, true)", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, "%d%d%d%d%d%d%d") ~= nil):toBe(false)
			expect(string.find(applierSrc, "rbxassetid://%d") ~= nil):toBe(false)
		end)

		t:it("records a pending gallery row with an existing path and fps cost", function()
			expect(gallerySrc:find("| `pasar_awnings_r8` |", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find('LookDev.enable("pasar_awnings_r8")', 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("`docs/v2/evidence/h/2026-11-21-round9/REVIEW_ROUND9.md`", 1, true) ~= nil):toBe(
				true
			)
			expect(gallerySrc:find("fps", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("pending —", 1, true) ~= nil):toBe(true)
		end)
	end)
end
