--!nocheck
-- WORK_QUEUE section M item 83: flyers_r8 birds, butterflies and dragonflies. Pure MapSpec-derived
-- home bands, a deterministic 60-second flight sim (caps / bounds / os.clock cost), LookDev +
-- review wiring, the two new read-only harness checks and the client applier's source guards.
-- No Studio claim: CHECK evidence, tracker ticks and the visual verdict belong to the main session
-- / designer.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect

	local env = Env.new()
	local Data = env:require("shared/ModelMapFlyersR8")
	local MapSpec = env:require("server/World/MapSpec")
	local LookDev = env:require("shared/LookDev")
	local Review = env:require("shared/LookDevReview")
	local Applier = env:require("client/World/LookDevFlyersR8")

	local dataSrc = fs.readFile("src/shared/ModelMapFlyersR8.luau")
	local applierSrc = fs.readFile("src/client/World/LookDevFlyersR8.luau")
	local harnessSrc = fs.readFile("tools/studio/review_check_r8.luau")
	local gallerySrc = fs.readFile("docs/v2/visual/CANDIDATES.md")

	local bounds = Data.bounds(MapSpec)
	local function fresh(tier: string?)
		return Data.spawn(MapSpec, tier or "Tinggi")
	end

	t:describe("flyers_r8 pure data", function()
		t:it("locks the three tiers and their per-kind caps", function()
			expect(Data.id):toBe("flyers_r8")
			expect(Data.folder):toBe("LookDevFlyersR8_flyers_r8")
			expect(Data.MAX_BIRD):toBe(6)
			expect(Data.MAX_KUPU):toBe(10)
			expect(Data.MAX_CAPUNG_BY_TIER.Rendah):toBe(4)
			expect(Data.MAX_CAPUNG_BY_TIER.Sedang):toBe(6)
			expect(Data.MAX_CAPUNG_BY_TIER.Tinggi):toBe(8)
			expect(Data.SIM_SECONDS):toBe(60)
			expect(Data.MAX_STEP_MS):toBe(0.3)
			expect(#Data.KINDS):toBe(3)
			for _, tier in ipairs(Data.TIERS) do
				local cap = Data.caps(tier)
				expect(cap.burung):toBe(Data.MAX_BIRD)
				expect(cap.kupu):toBe(Data.MAX_KUPU)
				expect(cap.capung):toBe(Data.MAX_CAPUNG_BY_TIER[tier])
				local states = fresh(tier)
				expect(#states):toBe(cap.burung + cap.kupu + cap.capung)
				local counts = Data.kindCounts(states)
				for _, kind in ipairs(Data.KINDS) do
					expect(counts[kind] >= 1):toBe(true)
					expect(counts[kind] <= cap[kind]):toBe(true)
				end
			end
			-- Unknown tiers fall back to the conservative Rendah cap.
			expect(Data.caps("unknown").capung):toBe(Data.MAX_CAPUNG_BY_TIER.Rendah)
			expect(#fresh("unknown")):toBe(6 + 10 + 4)
		end)

		t:it("gives every flyer a body and two flapping wings", function()
			local seen = {}
			for _, state in ipairs(fresh()) do
				expect(seen[state.id] == nil):toBe(true)
				seen[state.id] = true
				expect(type(state.position) == "table"):toBe(true)
				expect(type(state.seed) == "number"):toBe(true)
				expect(type(state.phase) == "number"):toBe(true)
				local parts = Data.PARTS[state.kind]
				expect(parts ~= nil):toBe(true)
				expect(#parts):toBe(3)
				expect(parts[1][1]):toBe("Body")
				expect(parts[2][1]):toBe("WingL")
				expect(parts[3][1]):toBe("WingR")
			end
		end)

		t:it("derives every home band from MapSpec geometry", function()
			local first = {}
			for _, state in ipairs(fresh()) do
				if first[state.kind] == nil then
					first[state.kind] = state
				end
			end
			local bird = first.burung
			expect(math.abs(bird.home.x - MapSpec.PLAZA.x) < 1e-6):toBe(true)
			expect(math.abs(bird.home.z - MapSpec.PLAZA.z) < 1e-6):toBe(true)
			expect(bird.home.radius):toBe(MapSpec.PLAZA.width / 2 + MapSpec.ROAD.radius / 2)
			expect(bird.home.y > MapSpec.GROUND_Y + 30):toBe(true)
			expect(bird.home.y <= bounds.maxY):toBe(true)

			local kupu = first.kupu
			expect(math.abs(kupu.home.x - MapSpec.PLAZA.x) <= MapSpec.PLAZA.width / 2):toBe(true)
			expect(math.abs(kupu.home.z - MapSpec.PLAZA.z) <= MapSpec.PLAZA.depth / 2):toBe(true)
			expect(kupu.home.radius):toBe(MapSpec.ROAD.halfWidth)

			local capung = first.capung
			expect(math.abs(capung.home.x - MapSpec.BRIDGE.x) < 1e-6):toBe(true)
			expect(math.abs(capung.home.z - MapSpec.riverCentreZ(capung.home.x)) < 1e-6):toBe(true)
			expect(type(capung.home.riverZ) == "function"):toBe(true)
			expect(math.abs(capung.home.zOff) > MapSpec.BRIDGE.width / 2):toBe(true)
		end)

		t:it("carries no engine API or asset ID in the pure module", function()
			expect(string.find(dataSrc, "game.", 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, "Enum.", 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, "Instance.", 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, "rbxassetid://", 1, true) == nil):toBe(true)
		end)
	end)

	t:describe("flyers_r8 deterministic simulation", function()
		t:it("keeps every intermediate position inside MapSpec bounds for 60 s", function()
			local states = fresh()
			local half, ground = MapSpec.TERRAIN_HALF, MapSpec.GROUND_Y
			local offenders = {}
			local minY, maxY = math.huge, -math.huge
			local steps = math.ceil(Data.SIM_SECONDS / Data.DT)
			expect(steps):toBe(3600)
			for _ = 1, steps do
				Data.stepAll(states, Data.DT, bounds)
				for _, state in ipairs(states) do
					local p = state.position
					minY, maxY = math.min(minY, p.y), math.max(maxY, p.y)
					if
						math.abs(p.x) > half + Data.BOUND_TOLERANCE
						or math.abs(p.z) > half + Data.BOUND_TOLERANCE
						or p.y < ground - Data.BOUND_TOLERANCE
						or p.y > bounds.maxY + Data.BOUND_TOLERANCE
					then
						offenders[#offenders + 1] = state.id
					end
				end
			end
			expect(#offenders):toBe(0)
			expect(minY >= ground - Data.BOUND_TOLERANCE):toBe(true)
			expect(maxY <= bounds.maxY + Data.BOUND_TOLERANCE):toBe(true)
		end)

		t:it("is reproducible without global random state", function()
			local a, b = fresh(), fresh()
			Data.simulate(a, Data.SIM_SECONDS, Data.DT, bounds)
			Data.simulate(b, Data.SIM_SECONDS, Data.DT, bounds)
			for i = 1, #a do
				expect(a[i].position.x):toBe(b[i].position.x)
				expect(a[i].position.y):toBe(b[i].position.y)
				expect(a[i].position.z):toBe(b[i].position.z)
				expect(a[i].wing):toBe(b[i].wing)
				expect(a[i].seed):toBe(b[i].seed)
			end
		end)

		t:it("costs under 0.3 ms per 24-flyer step (measured with os.clock)", function()
			local states = fresh()
			local started = os.clock()
			local finalStates, steps = Data.simulate(states, Data.SIM_SECONDS, Data.DT, bounds)
			local elapsed = os.clock() - started
			local averageMs = elapsed * 1000 / steps
			print(string.format("flyers_r8 cost: %.4f ms/step (%d steps, %d flyers)", averageMs, steps, #finalStates))
			expect(steps):toBe(3600)
			expect(#finalStates):toBe(24)
			expect(averageMs < Data.MAX_STEP_MS):toBe(true)
		end)
	end)

	t:describe("flyers_r8 wiring, harness and applier", function()
		t:it("ships candidate 68 with a client review path", function()
			expect(#LookDev.IDS):toBe(79)
			expect(LookDev.IDS[68]):toBe("flyers_r8")
			local candidate = LookDev.candidates.flyers_r8
			expect(candidate.id):toBe("flyers_r8")
			expect(candidate.status):toBe("candidate, awaiting designer yes")
			expect(candidate.style):toBe("cartoonish-realism")
			expect(candidate.idsSource):toBe("Shared.ModelMapFlyersR8")
			expect(candidate.tier):toBe("Tinggi")
			expect(candidate.maxFlyers):toBe(24)
			local plan = LookDev.plan("flyers_r8")
			expect(plan ~= nil):toBe(true)
			expect(plan.id):toBe("flyers_r8")
			expect(plan.tier):toBe("Tinggi")
			expect(type(plan.render)):toBe("string")
			local entry = Review.paths.flyers_r8
			expect(entry ~= nil):toBe(true)
			expect(entry.datamodel):toBe("client")
			expect(entry.path):toEqual({ "World", "LookDevFlyersR8" })
		end)

		t:it("adds two read-only checks after ANIMAL_COST inside their own block", function()
			local animalAt = harnessSrc:find('"ANIMAL_COST",', 1, true)
			local flyerCountAt = harnessSrc:find('"FLYER_COUNT",', 1, true)
			local flyerCostAt = harnessSrc:find('"FLYER_COST",', 1, true)
			expect(animalAt ~= nil and flyerCountAt ~= nil and flyerCostAt ~= nil):toBe(true)
			expect(animalAt < flyerCountAt and flyerCountAt < flyerCostAt):toBe(true)
			for _, name in ipairs({ "FLYER_COUNT", "FLYER_COST" }) do
				local _, emitted = string.gsub(harnessSrc, 'emit%(.-"' .. name .. '"', "")
				expect(emitted):toBe(1)
			end
			expect(harnessSrc:find("do\n%-%- 9h%-4%. WORK_QUEUE section M item 83", 1) ~= nil):toBe(true)
			expect(harnessSrc:find("FR8.stepAll", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("os.clock()", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("ServerScriptService.Server.World", 1, true) ~= nil):toBe(true)
		end)

		t:it("uses one injected Heartbeat loop and a deterministic simulate helper", function()
			expect(applierSrc:find("require(Shared.ModelMapFlyersR8)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("LookDev.register(Flyers.id", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("heartbeat:Connect(tick)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Flyers.stepAll(states, dt, bounds)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Anchored = true", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("folder:Destroy()", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("rbxassetid://", 1, true) == nil):toBe(true)
			local states = fresh()
			local finalStates, steps, elapsed = Applier.simulate(states, 1, Data.DT, bounds)
			expect(#finalStates):toBe(#states)
			expect(steps):toBe(60)
			expect(type(elapsed)):toBe("number")
		end)

		t:it("names a pending gallery row with an existing render path and fps note", function()
			local row = string.match(gallerySrc, "\n(| `flyers_r8` |[^\r\n]+)")
			expect(row ~= nil):toBe(true)
			expect(string.find(row, 'LookDev.enable("flyers_r8")', 1, true) ~= nil):toBe(true)
			local render = string.match(row, "`[^`]+` | [^|]+ | `[^`]+` | `([^`]+)`")
			expect(render ~= nil):toBe(true)
			expect(fs.isFile(render) or fs.isDir(render)):toBe(true)
			expect(string.find(row, "| pending", 1, true) ~= nil):toBe(true)
			expect(string.find(string.lower(row), "fps", 1, true) ~= nil):toBe(true)
		end)
	end)
end
