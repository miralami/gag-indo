--!nocheck
-- WORK_QUEUE section O item 138: the OLD pine backdrop as an OFF-BY-DEFAULT comparison candidate,
-- plus the four default-look harness checks that grade the new tropical forest. Pure Lune spec:
-- source assertions and pure modules only, no Roblox APIs and no Studio state.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect

	local function fresh(path)
		return Env.new():require(path)
	end

	t:describe("forest_pines_legacy candidate registration", function()
		t:it("is candidate 58, after hubprops_r8", function()
			local LookDev = fresh("shared/LookDev")
			expect(#LookDev.IDS):toBe(84)
			expect(LookDev.IDS[57]):toBe("hubprops_r8")
			expect(LookDev.IDS[58]):toBe("forest_pines_legacy")
		end)

		t:it("declares a candidate with the fixed idsSource and render path", function()
			local LookDev = fresh("shared/LookDev")
			local c = LookDev.candidates.forest_pines_legacy
			expect(type(c)):toBe("table")
			expect(c.id):toBe("forest_pines_legacy")
			expect(c.status):toBe("candidate, awaiting designer yes")
			expect(c.style):toBe("cartoonish-realism")
			expect(type(c.title)):toBe("string")
			expect(c.idsSource):toBe("Shared.ModelMapForestR9")
			expect(c.render):toBe("docs/v2/visual/art/models_r8/forest/README.md")
			expect(LookDev.isCandidate("forest_pines_legacy")):toBe(true)
		end)

		t:it("plans the candidate without embedding ids", function()
			local LookDev = fresh("shared/LookDev")
			local plan = LookDev.plan("forest_pines_legacy")
			expect(type(plan)):toBe("table")
			expect(plan.id):toBe("forest_pines_legacy")
			expect(plan.idsSource):toBe("Shared.ModelMapForestR9")
			expect(plan.render):toBe("docs/v2/visual/art/models_r8/forest/README.md")
		end)

		t:it("is reachable from the Server review path", function()
			local review = fresh("shared/LookDevReview")
			local entry = review.paths.forest_pines_legacy
			expect(type(entry)):toBe("table")
			expect(entry.datamodel):toBe("server")
			expect(#entry.path):toBe(2)
			expect(entry.path[1]):toBe("World")
			expect(entry.path[2]):toBe("LookDevForestPinesLegacy")
			expect(review.pathsFor("forest_pines_legacy") ~= nil):toBe(true)
			expect(review.pathsFor("forest_pines_legacy").datamodel):toBe("server")
		end)
	end)

	t:describe("forest_pines_legacy applier wiring", function()
		t:it("registers the candidate and boots from Main.server", function()
			local src = fs.readFile("src/server/World/LookDevForestPinesLegacy.luau")
			expect(string.find(src, "--!strict", 1, true) ~= nil):toBe(true)
			expect(string.find(src, "LookDev.register(CANDIDATE_ID, applier)", 1, true) ~= nil):toBe(true)
			expect(string.find(src, 'CANDIDATE_ID = "forest_pines_legacy"', 1, true) ~= nil):toBe(true)
			local server = fs.readFile("src/server/Main.server.luau")
			expect(string.find(server, "pcall(require, script.Parent.World.LookDevForestPinesLegacy)", 1, true) ~= nil):toBe(
				true
			)
		end)

		t:it("hides the tropical default, stages the exact pine folder and tags every part", function()
			local src = fs.readFile("src/server/World/LookDevForestPinesLegacy.luau")
			expect(string.find(src, 'FindFirstChild("BackgroundForest")', 1, true) ~= nil):toBe(true)
			expect(string.find(src, 'STAGED_FOLDER = "LookDevForestPinesLegacy_forest_pines_legacy"', 1, true) ~= nil):toBe(
				true
			)
			expect(string.find(src, 'FindFirstChild("Realistic Pine Tree")', 1, true) ~= nil):toBe(true)
			expect(string.find(src, 'Instance.new("Part")', 1, true) ~= nil):toBe(true)
			expect(string.find(src, '"Pine_" .. angleDeg .. "_" .. layer', 1, true) ~= nil):toBe(true)
			expect(string.find(src, 'TAG_KEY = "LookDevForestPinesLegacy"', 1, true) ~= nil):toBe(true)
			expect(string.find(src, "tree:SetAttribute(TAG_KEY, CANDIDATE_ID)", 1, true) ~= nil):toBe(true)
			expect(string.find(src, "part:SetAttribute(TAG_KEY, CANDIDATE_ID)", 1, true) ~= nil):toBe(true)
		end)

		t:it("restores each moved tree to its exact prior parent in order", function()
			local src = fs.readFile("src/server/World/LookDevForestPinesLegacy.luau")
			expect(string.find(src, "snapshot.moved[#snapshot.moved + 1]", 1, true) ~= nil):toBe(true)
			expect(string.find(src, "entry.child.Parent = entry.parent", 1, true) ~= nil):toBe(true)
			expect(string.find(src, "for _, entry in ipairs(snapshot.moved) do", 1, true) ~= nil):toBe(true)
			expect(string.find(src, "folder:Destroy()", 1, true) ~= nil):toBe(true)
			expect(string.find(src, "hold:Destroy()", 1, true) ~= nil):toBe(true)
			-- No new asset ID of any kind.
			expect(string.find(src, "rbxassetid://%d") ~= nil):toBe(false)
			expect(string.find(src, "%d%d%d%d%d%d%d") ~= nil):toBe(false)
		end)
	end)

	t:describe("default-look ring checks in the r8 harness", function()
		local function orderBlock(src)
			local start = string.find(src, "local ORDER = {", 1, true)
			expect(start ~= nil):toBe(true)
			local finish = string.find(src, "\n}", start, true)
			expect(finish ~= nil):toBe(true)
			return string.sub(src, start, finish)
		end

		local function emitTarget(src, name, target)
			local at = string.find(src, 'emit("' .. name .. '"', 1, true)
			expect(at ~= nil):toBe(true)
			local compact = string.gsub(string.sub(src, at, at + 300), "%s", "")
			expect(string.find(compact, "," .. target .. ",", 1, true) ~= nil):toBe(true)
		end

		t:it("adds NO_PINES, RING_COUNT, RING_SPECIES, PERF_BUDGET after LOAD_FAILURES", function()
			local src = fs.readFile("tools/studio/review_check_r8.luau")
			local block = orderBlock(src)
			local load = string.find(block, '"LOAD_FAILURES"', 1, true)
			expect(load ~= nil):toBe(true)
			local sky = string.find(block, '"SKY_DEFAULT"', 1, true)
			expect(sky ~= nil):toBe(true)
			local previous = load
			for _, name in ipairs({ "NO_PINES", "RING_COUNT", "RING_SPECIES", "PERF_BUDGET" }) do
				local at = string.find(block, '"' .. name .. '"', 1, true)
				expect(at ~= nil):toBe(true)
				expect(at > previous):toBe(true)
				expect(at < sky):toBe(true)
				previous = at
			end
		end)

		t:it("emits each new check with the mandated target", function()
			local src = fs.readFile("tools/studio/review_check_r8.luau")
			emitTarget(src, "NO_PINES", "0")
			emitTarget(src, "RING_COUNT", "250")
			emitTarget(src, "RING_SPECIES", "4")
			emitTarget(src, "PERF_BUDGET", "500")
		end)

		t:it("reads the default look only — no candidate enable in the new checks", function()
			local src = fs.readFile("tools/studio/review_check_r8.luau")
			local start = string.find(src, "-- 1b. O-section default-look forest checks", 1, true)
			expect(start ~= nil):toBe(true)
			local finish = string.find(src, "-- 2. SKY_DEFAULT", start, true)
			expect(finish ~= nil):toBe(true)
			local block = string.sub(src, start, finish)
			expect(string.find(block, "enable(", 1, true) == nil):toBe(true)
			expect(string.find(block, 'string.find(name, "Pine", 1, true)', 1, true) ~= nil):toBe(true)
			expect(string.find(block, 'attr(inst, "ForestTree") == true', 1, true) ~= nil):toBe(true)
			expect(string.find(block, 'attr(inst, "ForestSpecies")', 1, true) ~= nil):toBe(true)
			expect(string.find(block, 'inst:IsA("BasePart")', 1, true) ~= nil):toBe(true)
		end)
	end)
end
