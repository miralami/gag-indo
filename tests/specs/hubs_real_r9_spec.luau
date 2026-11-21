--!nocheck
-- WORK_QUEUE section O item 147: hubs_real_r9 real buildings on six hubs.
-- Pure-data contract plus LookDev/review wiring, clone-first staging guards and the read-only
-- HUB_FIT harness target. No Studio claim: CHECK evidence, tracker ticks and the visual verdict
-- belong to the main session and the designer respectively.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect

	local env = Env.new()
	local Data = env:require("shared/ModelMapHubsRealR9")
	local R8 = env:require("shared/ModelMapBuildingsR8")
	local LookDev = env:require("shared/LookDev")
	local Review = env:require("shared/LookDevReview")
	local MapSpec = env:require("server/World/MapSpec")

	local harnessSrc = fs.readFile("tools/studio/review_check_r8.luau")
	local applierSrc = fs.readFile("src/server/World/LookDevHubsRealR9.luau")
	local dataSrc = fs.readFile("src/shared/ModelMapHubsRealR9.luau")
	local gallerySrc = fs.readFile("docs/v2/visual/CANDIDATES.md")

	local hubs = MapSpec.HUBS
	local plans = Data.plans(hubs)
	local byHub = {}
	for _, plan in ipairs(plans) do
		byHub[plan.hub] = plan
	end

	t:describe("hubs_real_r9 pure data", function()
		t:it("locks the item-147 targets", function()
			expect(Data.familyId):toBe("hubs_real_r9")
			expect(Data.folderName):toBe("LookDevHubsRealR9_hubs_real_r9")
			expect(Data.tagAttribute):toBe("HubRealR9")
			expect(Data.FIT_INSET):toBe(0.25)
			expect(Data.FIT_MARGIN):toBe(2)
			expect(Data.MAX_SCALE):toBe(1)
			expect(Data.proposal):toBe(true) -- pending designer yes
			expect(Data.count()):toBe(6)
			expect(#Data.hubOrder):toBe(6)
			expect(Data.idsFor("buildings_r8")):toBe(nil)
		end)

		t:it("uses only the BUILDING_KIT proposal matches and verified R8 ids", function()
			local expected = {
				pasar = "indonesian_house",
				gelap = "rumah_joglo",
				warung = "warung_penyetan",
				ronda = "nipa_hut",
				polisi = "pendopo_jawa",
				pakrt = "rumah_4",
			}
			local ids = Data.idsFor("hubs_real_r9")
			for _, key in ipairs(Data.hubOrder) do
				expect(Data.slotFor(key)):toBe(expected[key])
				expect(type(ids[key])):toBe("number")
				local entry = Data.entryFor(key)
				expect(entry.slot):toBe(expected[key])
				expect(ids[key]):toBe(entry.id)
				expect(ids[key]):toBe(R8.ids[entry.slot])
			end
			expect(Data.slotFor("unknown")):toBe(nil)
			expect(Data.plan({ key = "unknown", x = 0, z = 0, width = 10, depth = 10, yaw = 0 })):toBe(nil)
		end)

		t:it("makes one plan per hub with a downscale-only fit inside the footprint", function()
			expect(#plans):toBe(6)
			for _, hub in ipairs(hubs) do
				local plan = byHub[hub.key]
				expect(plan ~= nil):toBe(true)
				expect(plan.slot):toBe(Data.slotFor(hub.key))
				expect(plan.hubModel):toBe(hub.model)
				expect(plan.yaw):toBe(hub.yaw)
				expect(plan.centreX):toBe(hub.x)
				expect(plan.centreZ):toBe(hub.z)
				expect(plan.scale <= 1):toBe(true)
				expect(plan.fitScale <= 1):toBe(true)
				expect(plan.scale > 0):toBe(true)
				expect(plan.width > 0 and plan.depth > 0 and plan.height > 0):toBe(true)
				local bounds = MapSpec.hubBounds(hub)
				expect(Data.fits(plan, bounds)):toBe(true)
				-- The inset keeps the building inside the RAW footprint, not just footprint + 2.
				expect(plan.centreX - plan.width / 2 >= bounds.minX - 0.001):toBe(true)
				expect(plan.centreX + plan.width / 2 <= bounds.maxX + 0.001):toBe(true)
				expect(plan.centreZ - plan.depth / 2 >= bounds.minZ - 0.001):toBe(true)
				expect(plan.centreZ + plan.depth / 2 <= bounds.maxZ + 0.001):toBe(true)
				expect(Data.fits(plan, {
					minX = bounds.minX - 100,
					maxX = bounds.maxX + 100,
					minZ = bounds.minZ - 100,
					maxZ = bounds.maxZ + 100,
				})):toBe(true)
			end
		end)

		t:it("keeps warung at native size and swaps world axes for yaw-90 ronda", function()
			expect(byHub.warung.scale):toBe(1) -- 24 x 13.82 fits 52 x 44
			local ronda = byHub.ronda
			expect(ronda.yaw):toBe(90)
			local entry = Data.entryFor("ronda")
			expect(entry.stagedWidth):toBe(22.72)
			expect(entry.stagedDepth):toBe(44.29)
			-- World X comes from the staged depth at yaw 90; world Z from the staged width.
			expect(math.abs(ronda.width - 44.29 * ronda.fitScale) < 0.001):toBe(true)
			expect(math.abs(ronda.depth - 22.72 * ronda.fitScale) < 0.001):toBe(true)
			expect(byHub.gelap.slot):toBe("rumah_joglo")
			expect(Data.entryFor("gelap").scale):toBe(0.75) -- baked into the staged bbox
			expect(math.abs(byHub.gelap.scale - 0.75 * byHub.gelap.fitScale) < 1e-9):toBe(true)
		end)

		t:it("declares no asset-id literals in the pure data module", function()
			expect(string.find(dataSrc, "%d%d%d%d%d%d%d") ~= nil):toBe(false)
			expect(string.find(dataSrc, "rbxassetid://", 1, true) ~= nil):toBe(false)
			expect(string.find(dataSrc, "assetId", 1, true) ~= nil):toBe(false)
		end)
	end)

	t:describe("hubs_real_r9 LookDev wiring and review harness", function()
		t:it("ships candidate 60 with a plan, descriptor and server review path", function()
			expect(#LookDev.IDS):toBe(82)
			expect(LookDev.IDS[60]):toBe("hubs_real_r9")
			local candidate = LookDev.candidates.hubs_real_r9
			expect(candidate.id):toBe("hubs_real_r9")
			expect(candidate.status):toBe("candidate, awaiting designer yes")
			expect(candidate.idsSource):toBe("Shared.ModelMapHubsRealR9")
			expect(candidate.hubCount):toBe(6)
			local plan = LookDev.plan("hubs_real_r9")
			expect(plan ~= nil):toBe(true)
			expect(plan.id):toBe("hubs_real_r9")
			expect(plan.idsSource):toBe("Shared.ModelMapHubsRealR9")
			local entry = Review.paths.hubs_real_r9
			expect(entry ~= nil):toBe(true)
			expect(entry.datamodel):toBe("server")
			expect(entry.path):toEqual({ "World", "LookDevHubsRealR9" })
		end)

		t:it("adds read-only HUB_FIT next to PATH_REACH/AVATAR_FIT in ORDER", function()
			expect(harnessSrc:find('"HUB_FIT"', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('"AVATAR_FIT",\n\t"HUB_FIT",\n\t"PLOT_FENCE",', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('"LookDevHubsRealR9_hubs_real_r9"', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('attr(child, "HubRealR9") == "hubs_real_r9"', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('"HubRealR9Hub"', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("HUBS_REAL_MARGIN = 2", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("hubs_real_r9 folder / MapSpec / bbox not readable", 1, true) ~= nil):toBe(true)
		end)

		t:it("stages clone-first, yawed, tagged, hidden-body models with a full restore", function()
			expect(applierSrc:find("LookDevAssetLoader.get(plan.id, FAMILY_ID)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("model:ScaleTo(plan.scale)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("CFrame.Angles(0, math.rad(plan.yaw), 0)", 1, true) ~= nil):toBe(true)
			expect(
				applierSrc:find("model.WorldPivot = CFrame.new(plan.centreX, groundY, plan.centreZ)", 1, true) ~= nil
			):toBe(true)
			expect(applierSrc:find("not isSignPart(part, hubModel)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("part.Transparency = 1", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("part.CanCollide = false", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Data.prevTransparencyAttribute", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Data.prevCollideAttribute", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("restoreBodies()", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("folder:Destroy()", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("LookDev.register(FAMILY_ID", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, "%d%d%d%d%d%d%d") ~= nil):toBe(false)
		end)

		t:it("records a pending, flagged gallery row", function()
			expect(gallerySrc:find("| `hubs_real_r9` |", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find('LookDev.enable("hubs_real_r9")', 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("pending —", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("`docs/v2/visual/art/BUILDING_KIT.md`", 1, true) ~= nil):toBe(true)
		end)
	end)
end
