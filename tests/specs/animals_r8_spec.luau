--!nocheck
-- WORK_QUEUE section M item 82: animals_r8 village animals. Pure MapSpec-derived home bands, a
-- deterministic 60-second wander sim (count / bounds / os.clock cost), LookDev + review wiring,
-- the three new read-only harness checks and the client applier's source guards. No Studio claim:
-- CHECK evidence, tracker ticks and the visual verdict belong to the main session / designer.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect

	local env = Env.new()
	local Data = env:require("shared/ModelMapAnimalsR8")
	local MapSpec = env:require("server/World/MapSpec")
	local LookDev = env:require("shared/LookDev")
	local Review = env:require("shared/LookDevReview")
	local Applier = env:require("client/World/LookDevAnimalsR8")

	local dataSrc = fs.readFile("src/shared/ModelMapAnimalsR8.luau")
	local applierSrc = fs.readFile("src/client/World/LookDevAnimalsR8.luau")
	local harnessSrc = fs.readFile("tools/studio/review_check_r8.luau")
	local gallerySrc = fs.readFile("docs/v2/visual/CANDIDATES.md")

	local bounds = Data.bounds(MapSpec)
	local function fresh()
		return Data.spawn(MapSpec)
	end

	t:describe("animals_r8 pure data", function()
		t:it("locks the Rendah cap and the four village kinds", function()
			expect(Data.id):toBe("animals_r8")
			expect(Data.folder):toBe("LookDevAnimalsR8_animals_r8")
			expect(Data.MAX_ANIMALS):toBe(14)
			expect(Data.SIM_SECONDS):toBe(60)
			expect(Data.MAX_STEP_MS):toBe(0.3)
			expect(#Data.KINDS):toBe(4)
			local states = fresh()
			expect(#states > 0):toBe(true)
			expect(#states <= Data.MAX_ANIMALS):toBe(true)
			local counts = Data.kindCounts(states)
			for _, kind in ipairs(Data.KINDS) do
				expect(counts[kind]):toBe(Data.COUNT[kind])
			end
			expect(counts.ayam + counts.bebek + counts.kambing + counts.kucing):toBe(11)
			local seen = {}
			for _, state in ipairs(states) do
				expect(seen[state.id] == nil):toBe(true)
				seen[state.id] = true
				expect(type(state.position) == "table"):toBe(true)
				expect(type(state.target) == "table"):toBe(true)
				expect(type(state.seed) == "number"):toBe(true)
				expect(Data.PARTS[state.kind] ~= nil):toBe(true)
			end
		end)

		t:it("derives every home band from MapSpec geometry", function()
			local warung = MapSpec.hub("warung")
			local terrace = MapSpec.TERRACES[1]
			local bridge = MapSpec.BRIDGE
			local ayam, bebek, kambing, kucing = nil, nil, nil, nil
			for _, state in ipairs(fresh()) do
				if state.kind == "ayam" and not ayam then
					ayam = state
				elseif state.kind == "bebek" and not bebek then
					bebek = state
				elseif state.kind == "kambing" and not kambing then
					kambing = state
				elseif state.kind == "kucing" and not kucing then
					kucing = state
				end
			end
			expect(math.abs(ayam.home.x - warung.x) <= ayam.home.radius + warung.width / 2):toBe(true)
			expect(math.abs(ayam.home.z - warung.z) <= ayam.home.radius + warung.depth / 2 + 12):toBe(true)
			expect(math.abs(bebek.home.z - MapSpec.riverCentreZ(bebek.home.x))):toBeLessThan(bridge.width / 2 + 6)
			expect(kambing.home.z > terrace.z1):toBe(true)
			expect(kambing.home.z < terrace.z1 + 24):toBe(true)
			expect(kambing.home.x < 0):toBe(true)
			expect(kucing.home.y > MapSpec.GROUND_Y + 10):toBe(true)
			expect(kucing.home.y <= bounds.maxY):toBe(true)
		end)

		t:it("carries no engine API or asset ID in the pure module", function()
			expect(string.find(dataSrc, "game.", 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, "Enum.", 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, "Instance.", 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, "rbxassetid://", 1, true) == nil):toBe(true)
		end)
	end)

	t:describe("animals_r8 deterministic simulation", function()
		t:it("keeps every intermediate position inside MapSpec bounds for 60 s", function()
			local states = fresh()
			local half, ground = MapSpec.TERRAIN_HALF, MapSpec.GROUND_Y
			local offenders = {}
			local minX, maxX, minY, minZ, maxZ = math.huge, -math.huge, math.huge, math.huge, -math.huge
			local steps = math.ceil(Data.SIM_SECONDS / Data.DT)
			expect(steps):toBe(3600)
			for _ = 1, steps do
				Data.stepAll(states, Data.DT, bounds)
				for _, state in ipairs(states) do
					local p = state.position
					minX, maxX = math.min(minX, p.x), math.max(maxX, p.x)
					minZ, maxZ = math.min(minZ, p.z), math.max(maxZ, p.z)
					minY = math.min(minY, p.y)
					if
						math.abs(p.x) > half + Data.BOUND_TOLERANCE
						or math.abs(p.z) > half + Data.BOUND_TOLERANCE
						or p.y < ground - Data.BOUND_TOLERANCE
					then
						offenders[#offenders + 1] = state.id
					end
				end
			end
			expect(#offenders):toBe(0)
			expect(minX >= -half and maxX <= half):toBe(true)
			expect(minZ >= -half and maxZ <= half):toBe(true)
			expect(minY >= ground - Data.BOUND_TOLERANCE):toBe(true)
		end)

		t:it("is reproducible without global random state", function()
			local a, b = fresh(), fresh()
			Data.simulate(a, Data.SIM_SECONDS, Data.DT, bounds)
			Data.simulate(b, Data.SIM_SECONDS, Data.DT, bounds)
			for i = 1, #a do
				expect(a[i].position.x):toBe(b[i].position.x)
				expect(a[i].position.y):toBe(b[i].position.y)
				expect(a[i].position.z):toBe(b[i].position.z)
				expect(a[i].seed):toBe(b[i].seed)
			end
		end)

		t:it("costs under 0.3 ms per 11-animal step (measured with os.clock)", function()
			local states = fresh()
			local steps = math.ceil(Data.SIM_SECONDS / Data.DT)
			local started = os.clock()
			Data.simulate(states, Data.SIM_SECONDS, Data.DT, bounds)
			local elapsed = os.clock() - started
			local averageMs = elapsed * 1000 / steps
			print(string.format("animals_r8 cost: %.4f ms/step (%d steps, %d animals)", averageMs, steps, #states))
			expect(averageMs < Data.MAX_STEP_MS):toBe(true)
		end)
	end)

	t:describe("animals_r8 wiring, harness and applier", function()
		t:it("ships candidate 67 with a client review path", function()
			expect(#LookDev.IDS):toBe(73)
			expect(LookDev.IDS[67]):toBe("animals_r8")
			local candidate = LookDev.candidates.animals_r8
			expect(candidate.id):toBe("animals_r8")
			expect(candidate.status):toBe("candidate, awaiting designer yes")
			expect(candidate.style):toBe("cartoonish-realism")
			expect(candidate.idsSource):toBe("Shared.ModelMapAnimalsR8")
			expect(candidate.maxAnimals):toBe(14)
			expect(candidate.animalCount):toBe(11)
			local plan = LookDev.plan("animals_r8")
			expect(plan ~= nil):toBe(true)
			expect(plan.id):toBe("animals_r8")
			expect(type(plan.render)):toBe("string")
			local entry = Review.paths.animals_r8
			expect(entry ~= nil):toBe(true)
			expect(entry.datamodel):toBe("client")
			expect(entry.path):toEqual({ "World", "LookDevAnimalsR8" })
		end)

		t:it("adds the three read-only checks after SIGN_FACING inside their own block", function()
			expect(
				harnessSrc:find('"SIGN_FACING",\n\t"ANIMAL_COUNT",\n\t"ANIMAL_BOUNDS",\n\t"ANIMAL_COST",', 1, true)
					~= nil
			):toBe(true)
			for _, name in ipairs({ "ANIMAL_COUNT", "ANIMAL_BOUNDS", "ANIMAL_COST" }) do
				local _, emitted = string.gsub(harnessSrc, 'emit%(.-"' .. name .. '"', "")
				expect(emitted):toBe(1)
			end
			expect(harnessSrc:find("do\n%-%- 9h%-3%. WORK_QUEUE section M item 82", 1) ~= nil):toBe(true)
			expect(harnessSrc:find("local AR8_MODULE", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("AR8_MODULE.stepAll", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("os.clock()", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("ServerScriptService.Server.World.MapSpec", 1, true) ~= nil):toBe(true)
		end)

		t:it("uses one injected Heartbeat loop and a deterministic simulate helper", function()
			expect(applierSrc:find("require(Shared.ModelMapAnimalsR8)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("LookDev.register(Animals.id", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("heartbeat:Connect(tick)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Animals.stepAll(states, dt, bounds)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Anchored = false", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("folder:Destroy()", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("rbxassetid://", 1, true) == nil):toBe(true)
			local states = fresh()
			local finalStates, elapsed, steps = Applier.simulate(states, 1, Data.DT, bounds)
			expect(#finalStates):toBe(#states)
			expect(steps):toBe(60)
			expect(type(elapsed)):toBe("number")
		end)

		t:it("names a pending gallery row with an existing render path and fps note", function()
			local row = string.match(gallerySrc, "\n(| `animals_r8` |[^\r\n]+)")
			expect(row ~= nil):toBe(true)
			expect(string.find(row, 'LookDev.enable("animals_r8")', 1, true) ~= nil):toBe(true)
			local render = string.match(row, "`[^`]+` | [^|]+ | `[^`]+` | `([^`]+)`")
			expect(render ~= nil):toBe(true)
			expect(fs.isFile(render) or fs.isDir(render)):toBe(true)
			expect(string.find(row, "| pending", 1, true) ~= nil):toBe(true)
			expect(string.find(string.lower(row), "fps", 1, true) ~= nil):toBe(true)
		end)
	end)
end
