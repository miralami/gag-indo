--!nocheck
-- WORK_QUEUE section M item 88: ambient_walkers_r8, up to 8 ambient villagers walking looped road
-- routes via NpcWalk. Locks the pure route/sim data and the LookDev/harness/applier wiring. The
-- applier and the Studio harness need Roblox APIs, so Lune reads their SOURCE TEXT only; no Studio
-- result or visual verdict is claimed here. The 90 s horizon is a pure deterministic sim because
-- the real NpcWalk yields via task.wait(0.05) every step.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect
	local env = Env.new()
	local Walkers = env:require("shared/ModelMapAmbientWalkersR8")
	local LookDev = env:require("shared/LookDev")
	local Review = env:require("shared/LookDevReview")
	local applier = fs.readFile("src/server/World/LookDevAmbientWalkersR8.luau")
	local npcWalk = fs.readFile("src/server/World/NpcWalk.luau")
	local harness = fs.readFile("tools/studio/review_check_r8.luau")

	t:describe("ambient_walkers_r8 constants and routes", function()
		t:it("locks the family ids, caps and step math", function()
			expect(Walkers.id):toBe("ambient_walkers_r8")
			expect(Walkers.familyId):toBe("ambient_walkers_r8")
			expect(Walkers.lookDevId):toBe("ambient_walkers_r8")
			expect(Walkers.folder):toBe("LookDevAmbientWalkersR8_ambient_walkers_r8")
			expect(Walkers.MAX_WALKERS):toBe(8)
			expect(Walkers.WALK_SPEED):toBe(6)
			expect(Walkers.WALK_SPEED <= 8):toBe(true)
			expect(Walkers.STEP_SECONDS):toBe(0.05)
			expect(Walkers.SIM_SECONDS):toBe(90)
			expect(Walkers.ARRIVAL_EPS):toBe(0.5)
			expect(Walkers.MAX_STUCK_SECONDS):toBe(10)
			expect(Walkers.MAX_ROAD_DEVIATION):toBe(8)
			expect(Walkers.GROUND_Y):toBe(0.5)
			expect(Walkers.STUCK_EPSILON):toBe(0.05)
			-- NpcWalk's own constants are the ones the sim is meant to mirror.
			expect(npcWalk:find("local STEP_SECONDS = 0.05", 1, true) ~= nil):toBe(true)
			expect(npcWalk:find("local STUCK_EPSILON = 0.05", 1, true) ~= nil):toBe(true)
			expect(npcWalk:find("local ARRIVE_EPSILON = 0.5", 1, true) ~= nil):toBe(true)
		end)

		t:it("returns eight named looped routes of at least three on-road waypoints", function()
			local routes = Walkers.routes()
			expect(#routes <= Walkers.MAX_WALKERS):toBe(true)
			expect(#routes):toBe(8)
			local seen = {}
			for _, route in ipairs(routes) do
				expect(type(route.name)):toBe("string")
				expect(#route.name > 0):toBe(true)
				expect(seen[route.name] == nil):toBe(true)
				seen[route.name] = true
				expect(#route.waypoints >= 3):toBe(true)
				for _, point in ipairs(route.waypoints) do
					expect(point.y):toBe(Walkers.GROUND_Y)
					expect(Walkers.distanceToRoad(point.x, point.z) <= Walkers.MAX_ROAD_DEVIATION):toBe(true)
				end
				-- The wrap segment (last -> first) must also stay on the road corridor.
				local last, first = route.waypoints[#route.waypoints], route.waypoints[1]
				local mx, mz = (last.x + first.x) / 2, (last.z + first.z) / 2
				expect(Walkers.distanceToRoad(mx, mz) <= Walkers.MAX_ROAD_DEVIATION):toBe(true)
			end
		end)

		t:it("computes pure road distance without mutating its inputs", function()
			expect(Walkers.distanceToRoad(0, 0)):toBe(0)
			expect(Walkers.distanceToRoad(136, 3)):toBe(0)
			expect(Walkers.distanceToRoad(3, -136)):toBe(0)
			expect(Walkers.distanceToRoad(200, 200) > Walkers.MAX_ROAD_DEVIATION):toBe(true)
			local routes = Walkers.routes()
			local snapshot = routes[1].waypoints[2].x
			Walkers.simulate(Walkers.SIM_SECONDS, routes)
			expect(routes[1].waypoints[2].x):toBe(snapshot)
		end)
	end)

	t:describe("ambient_walkers_r8 90 s deterministic sim", function()
		t:it("gives every walker >=3 waypoints, <=10 s stuck and <=8 studs deviation", function()
			local result = Walkers.simulate(90, Walkers.routes())
			expect(result.seconds):toBe(90)
			expect(result.steps):toBe(1800)
			expect(#result.walkers):toBe(Walkers.MAX_WALKERS)
			for _, walker in ipairs(result.walkers) do
				expect(walker.waypointsReached >= 3):toBe(true)
				expect(walker.maxStuckSeconds <= Walkers.MAX_STUCK_SECONDS):toBe(true)
				expect(walker.maxRoadDeviation <= Walkers.MAX_ROAD_DEVIATION):toBe(true)
				expect(Walkers.distanceToRoad(walker.finalPos.x, walker.finalPos.z) <= Walkers.MAX_ROAD_DEVIATION):toBe(
					true
				)
			end
			expect(result.minWaypointsReached):toBeAtLeast(3)
			expect(result.maxStuckSeconds):toBeAtMost(10)
			expect(result.maxRoadDeviation):toBeAtMost(8)
		end)

		t:it("is deterministic and accepts the default walker list", function()
			local a = Walkers.simulate(90, Walkers.routes())
			local b = Walkers.simulate(90, Walkers.routes())
			expect(a):toEqual(b)
			expect(Walkers.simulate(90)):toEqual(a)
			expect(Walkers.simulate(0).steps):toBe(0)
		end)
	end)

	t:describe("ambient_walkers_r8 LookDev wiring", function()
		t:it("registers candidate 73 with a server review path", function()
			expect(#LookDev.IDS):toBe(86)
			expect(LookDev.IDS[73]):toBe("ambient_walkers_r8")
			expect(LookDev.isCandidate("ambient_walkers_r8")):toBe(true)
			local candidate = LookDev.candidates.ambient_walkers_r8
			expect(candidate.id):toBe("ambient_walkers_r8")
			expect(candidate.status):toBe("candidate, awaiting designer yes")
			expect(candidate.maxWalkers):toBe(8)
			expect(candidate.walkSpeed):toBe(6)
			expect(candidate.simSeconds):toBe(90)
			local plan = LookDev.plan("ambient_walkers_r8")
			expect(plan.id):toBe("ambient_walkers_r8")
			expect(plan.idsSource):toBe("Shared.ModelMapAmbientWalkersR8")
			expect(plan.maxWalkers):toBe(8)
			expect(plan.walkSpeed):toBe(6)
			expect(plan.simSeconds):toBe(90)
			expect(type(plan.render)):toBe("string")
			local entry = Review.pathsFor("ambient_walkers_r8")
			expect(entry.datamodel):toBe("server")
			expect(entry.path):toEqual({ "World", "LookDevAmbientWalkersR8" })
		end)
	end)

	t:describe("ambient_walkers_r8 applier source", function()
		t:it("drives real NpcWalk loops with cancellation and no gameplay hooks", function()
			expect(applier:find("NpcWalk.walkTo(rig, target, Data.WALK_SPEED", 1, true) ~= nil):toBe(true)
			expect(applier:find("task.spawn(function()", 1, true) ~= nil):toBe(true)
			expect(applier:find("token.cancelled", 1, true) ~= nil):toBe(true)
			expect(applier:find("pcall(task.cancel, thread)", 1, true) ~= nil):toBe(true)
			expect(applier:find("humanoid.WalkSpeed = Data.WALK_SPEED", 1, true) ~= nil):toBe(true)
			expect(applier:find('rig:SetAttribute("LookDevWalkers", FAMILY_ID)', 1, true) ~= nil):toBe(true)
			expect(applier:find('rig:SetAttribute("RouteName", routeName)', 1, true) ~= nil):toBe(true)
			expect(applier:find('rig:SetAttribute("WalkSpeed", Data.WALK_SPEED)', 1, true) ~= nil):toBe(true)
			for _, forbidden in ipairs({ "ProximityPrompt", "Dialogue", "Touched", "Triggered", "Prompt" }) do
				expect(applier:find(forbidden, 1, true) == nil):toBe(true)
			end
			expect(applier:find("CreateHumanoidModelFromDescription", 1, true) ~= nil):toBe(true)
			expect(applier:find("Enum.HumanoidRigType.R15", 1, true) ~= nil):toBe(true)
			expect(applier:find("Data.MAX_WALKERS", 1, true) ~= nil):toBe(true)
		end)

		t:it("restores exact pivots, folder and prior state, and publishes failures", function()
			expect(applier:find("basePivots[rig] = pivot", 1, true) ~= nil):toBe(true)
			expect(applier:find("rig:PivotTo(base)", 1, true) ~= nil):toBe(true)
			expect(applier:find("previous.Parent = Workspace", 1, true) ~= nil):toBe(true)
			expect(applier:find("clearActive()", 1, true) ~= nil):toBe(true)
			expect(applier:find("resetDiagnostics()", 1, true) ~= nil):toBe(true)
			expect(applier:find(".reset(FAMILY_ID)", 1, true) ~= nil):toBe(true)
			expect(applier:find("LookDevFailures.set(FAMILY_ID, failures)", 1, true) ~= nil):toBe(true)
			expect(applier:find("LookDev.register(FAMILY_ID", 1, true) ~= nil):toBe(true)
		end)
	end)

	t:describe("ambient_walkers_r8 Studio harness", function()
		t:it("adds five ordered SERVER-only checks in one new do...end scope", function()
			expect(
				harness:find(
					'"WALKER_SPEED",\n\t"WALKER_MOVE",\n\t"WALKER_WAYPOINTS",\n\t"WALKER_STUCK",\n\t"WALKER_ROAD",',
					1,
					true
				) ~= nil
			):toBe(true)
			expect(harness:find("-- 12e. WORK_QUEUE item 88", 1, true) ~= nil):toBe(true)
			expect(harness:find("if not isServer then", 1, true) ~= nil):toBe(true)
			expect(harness:find('walkerFail("server VM required")', 1, true) ~= nil):toBe(true)
			for _, name in ipairs({ "WALKER_SPEED", "WALKER_MOVE", "WALKER_WAYPOINTS", "WALKER_STUCK", "WALKER_ROAD" }) do
				local _, emitted = string.gsub(harness, 'emit%("' .. name .. '"', "")
				expect(emitted):toBeGreaterThan(0)
			end
		end)

		t:it("reads live WalkSpeed and movement, then runs the pure 90 s sim", function()
			expect(
				harness:find(
					'"vegetation_r7", "npcs_r7", "props_r7", "npcs_r8", "npcs_idle_r8", "ambient_walkers_r8"',
					1,
					true
				) ~= nil
			):toBe(true)
			expect(harness:find('review.enable("ambient_walkers_r8", game, { studio = true })', 1, true) ~= nil):toBe(
				true
			)
			expect(harness:find("applier.walkSpeed(rig)", 1, true) ~= nil):toBe(true)
			expect(harness:find("task.wait(0.05)", 1, true) ~= nil):toBe(true)
			expect(harness:find("applier.basePivot(rig)", 1, true) ~= nil):toBe(true)
			expect(harness:find("applier.loopCount()", 1, true) ~= nil):toBe(true)
			expect(harness:find("map.simulate(map.SIM_SECONDS, map.routes())", 1, true) ~= nil):toBe(true)
		end)
	end)
end
