--!nocheck
-- WORK_QUEUE section M item 87: npcs_idle_r8, calm villager idle. Locks the one real catalog
-- animation ID, the 5+5 role/slot composition from the verified R7/R8 maps, the sway bound and
-- the deterministic 3600-step cost. The applier and Studio harness need Roblox APIs, so Lune
-- checks their SOURCE TEXT only; no Studio result or visual verdict is claimed here.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect
	local env = Env.new()
	local Idle = env:require("shared/ModelMapNpcsIdleR8")
	local R7 = env:require("shared/ModelMapNpcsR7")
	local R8 = env:require("shared/ModelMapNpcsR8")
	local LookDev = env:require("shared/LookDev")
	local Review = env:require("shared/LookDevReview")
	local applier = fs.readFile("src/server/World/LookDevNpcsIdleR8.luau")
	local harness = fs.readFile("tools/studio/review_check_r8.luau")

	t:describe("npcs_idle_r8 pure data", function()
		t:it("locks the one real catalog Standing Idle animation", function()
			expect(Idle.id):toBe("npcs_idle_r8")
			expect(Idle.animationId):toBe(71483261700852)
			expect(Idle.animationAsset):toBe("rbxassetid://71483261700852")
			expect(Idle.animationName):toBe("Standing Idle")
			expect(Idle.MAX_STEP_MS):toBe(0.3)
			expect(Idle.MAX_SWAY_DEG):toBe(1)
			expect(Idle.VILLAGER_COUNT):toBe(10)
			expect(Idle.SWAY_SPEED):toBeGreaterThan(0)
			expect(Idle.SWAY_SPEED):toBeLessThan(1)
		end)

		t:it("merges the two verified five-role catalogs in order", function()
			local roles = Idle.roles(R7, R8)
			expect(#roles):toBe(10)
			for index, descriptor in ipairs(roles) do
				local isR7 = index <= 5
				local source = if isR7 then R7 else R8
				local roleName = source.roleIds[isR7 and index or index - 5]
				expect(descriptor.role):toBe(roleName)
				expect(descriptor.isR7):toBe(isR7)
				expect(descriptor.source):toBe(if isR7 then "r7" else "r8")
				expect(descriptor.catalog):toBe(source.catalog[roleName])
				expect(descriptor.colours.skin):toBe(source.roles[roleName].skin)
				expect(descriptor.colours.shirt):toBe(source.roles[roleName].shirt)
				expect(descriptor.colours.pants):toBe(source.roles[roleName].pants)
			end
			-- A bare catalog table is accepted too, without inventing role/colour data.
			local bare = Idle.roles(R7.catalog, R8.catalog)
			expect(#bare):toBe(10)
			expect(bare[1].catalog):toBe(R7.catalog[R7.roleIds[1]])
			expect(bare[6].catalog):toBe(R8.catalog[R8.roleIds[1]])
		end)

		t:it("stages two five-wide rows from the existing pure slots", function()
			local slots = Idle.slots(R7.slots, R8.slots)
			expect(#slots):toBe(10)
			for index, slot in ipairs(slots) do
				local source = if index <= 5 then R7.slots[index] else R8.slots[index - 5]
				expect(slot.slot):toBe(source.slot)
				expect(slot.x):toBe(((if index <= 5 then index else index - 5) - 3) * Idle.SPACING)
				expect(slot.y):toBe(source.y)
				expect(slot.z):toBe(if index <= 5 then 8 else 14)
				expect(slot.ry):toBe(source.ry)
				expect(slot.targetHeight):toBe(source.targetHeight)
				expect(slot.source):toBe(if index <= 5 then "r7" else "r8")
			end
			expect(slots[1].x):toBe(-12)
			expect(slots[5].x):toBe(12)
			expect(slots[6].x):toBe(-12)
			expect(slots[10].x):toBe(12)
		end)
	end)

	t:describe("npcs_idle_r8 sway and cost", function()
		t:it("keeps every sway angle inside the <=1 degree bound", function()
			for seed = 1, 10 do
				for tick = 0, 600 do
					local angle = Idle.swayFor(seed, tick / 60)
					expect(angle >= -Idle.MAX_SWAY_DEG):toBe(true)
					expect(angle <= Idle.MAX_SWAY_DEG):toBe(true)
				end
			end
			expect(Idle.swayFor(1, 0)):toBe(Idle.swayFor(1, 0))
		end)

		t:it("advances ten entries deterministically for 3600 steps", function()
			local function fresh()
				return Idle.entries(Idle.slots(R7.slots, R8.slots))
			end
			local a, b = fresh(), fresh()
			expect(#a):toBe(10)
			local lastA, stepsA = Idle.simulate(a, Idle.SIM_SECONDS, Idle.DT)
			local lastB, stepsB = Idle.simulate(b, Idle.SIM_SECONDS, Idle.DT)
			expect(stepsA):toBe(3600)
			expect(stepsB):toBe(3600)
			expect(#lastA):toBe(10)
			for index = 1, 10 do
				expect(lastA[index]):toBe(lastB[index])
				expect(a[index].t):toBe(b[index].t)
				expect(a[index].sway):toBe(lastA[index])
			end
		end)

		t:it("costs under 0.3 ms per 10-villager step (os.clock)", function()
			local entries = Idle.entries(Idle.slots(R7.slots, R8.slots))
			local started = os.clock()
			Idle.simulate(entries, Idle.SIM_SECONDS, Idle.DT)
			local elapsed = os.clock() - started
			local averageMs = elapsed * 1000 / Idle.STEPS
			print(
				string.format(
					"npcs_idle_r8 cost: %.4f ms/step (%d steps, %d villagers)",
					averageMs,
					Idle.STEPS,
					#entries
				)
			)
			expect(averageMs >= 0):toBe(true)
			expect(averageMs < Idle.MAX_STEP_MS):toBe(true)
		end)
	end)

	t:describe("npcs_idle_r8 LookDev and applier wiring", function()
		t:it("registers candidate 72 with a server review path", function()
			expect(#LookDev.IDS):toBe(108)
			expect(LookDev.IDS[72]):toBe("npcs_idle_r8")
			expect(LookDev.isCandidate("npcs_idle_r8")):toBe(true)
			local candidate = LookDev.candidates.npcs_idle_r8
			expect(candidate.id):toBe("npcs_idle_r8")
			expect(candidate.status):toBe("candidate, awaiting designer yes")
			expect(candidate.villagerCount):toBe(10)
			expect(candidate.maxSwayDeg):toBe(1)
			local plan = LookDev.plan("npcs_idle_r8")
			expect(plan.id):toBe("npcs_idle_r8")
			expect(plan.idsSource):toBe("Shared.ModelMapNpcsIdleR8")
			expect(plan.villagerCount):toBe(10)
			expect(type(plan.render)):toBe("string")
			local entry = Review.pathsFor("npcs_idle_r8")
			expect(entry.datamodel):toBe("server")
			expect(entry.path):toEqual({ "World", "LookDevNpcsIdleR8" })
		end)

		t:it("applier creates an Animator, plays one real track and drives ONE sway loop", function()
			expect(applier:find('Instance.new("Animator")', 1, true) ~= nil):toBe(true)
			expect(applier:find(":LoadAnimation(animation)", 1, true) ~= nil):toBe(true)
			expect(applier:find("track.Looped = true", 1, true) ~= nil):toBe(true)
			expect(applier:find("track:Play()", 1, true) ~= nil):toBe(true)
			expect(applier:find("Data.animationAsset", 1, true) ~= nil):toBe(true)
			expect(applier:find("Heartbeat:Connect(tick)", 1, true) ~= nil):toBe(true)
			local _, heartbeats = string.gsub(applier, "Heartbeat:Connect%(", "")
			expect(heartbeats):toBe(1)
			expect(applier:find("Data.step(entries, dt)", 1, true) ~= nil):toBe(true)
			expect(applier:find("CFrame.Angles(math.rad(angles[index])", 1, true) ~= nil):toBe(true)
		end)

		t:it("applier restores exact base pivots, tracks and folder, and publishes failures", function()
			expect(applier:find("basePivots[rig] = pivot", 1, true) ~= nil):toBe(true)
			expect(applier:find("rig:PivotTo(base)", 1, true) ~= nil):toBe(true)
			expect(applier:find("audit.maxDelta <= 1e-4", 1, true) == nil):toBe(true) -- harness owns this bound
			expect(applier:find("disconnectLoop()", 1, true) ~= nil):toBe(true)
			expect(applier:find("stopTracks()", 1, true) ~= nil):toBe(true)
			expect(applier:find("track:Stop()", 1, true) ~= nil):toBe(true)
			expect(applier:find("track:Destroy()", 1, true) ~= nil):toBe(true)
			expect(applier:find("previous.Parent = Workspace", 1, true) ~= nil):toBe(true)
			expect(applier:find(".reset(FAMILY_ID)", 1, true) ~= nil):toBe(true)
			expect(applier:find("LookDevFailures.set(FAMILY_ID, failures)", 1, true) ~= nil):toBe(true)
			expect(applier:find('LookDev.register("npcs_idle_r8"', 1, true) ~= nil):toBe(true)
		end)
	end)

	t:describe("npcs_idle_r8 Studio harness", function()
		t:it("adds three ordered SERVER-only checks in one new do...end scope", function()
			expect(harness:find('"NPC8_OUTFITS",\n\t"IDLE_TRACKS",\n\t"IDLE_SWAY",\n\t"IDLE_COST",', 1, true) ~= nil):toBe(
				true
			)
			expect(harness:find("-- 12d. WORK_QUEUE item 87", 1, true) ~= nil):toBe(true)
			expect(harness:find("if not isServer then", 1, true) ~= nil):toBe(true)
			expect(harness:find('idleFail("server VM required")', 1, true) ~= nil):toBe(true)
			expect(harness:find("if isClient then", 1, true) ~= nil):toBe(true) -- other families are client-only
			for _, name in ipairs({ "IDLE_TRACKS", "IDLE_SWAY", "IDLE_COST" }) do
				local _, emitted = string.gsub(harness, 'emit%("' .. name .. '"', "")
				expect(emitted):toBeGreaterThan(0)
			end
		end)

		t:it("proves playing tracks, sway, restore and real per-frame cost", function()
			expect(
				harness:find(
					'ipairs({ "vegetation_r7", "npcs_r7", "props_r7", "npcs_r8", "npcs_idle_r8", "ambient_walkers_r8" })',
					1,
					true
				) ~= nil
			):toBe(true)
			expect(harness:find("track.IsPlaying", 1, true) ~= nil):toBe(true)
			expect(harness:find("applier.connectionCount()", 1, true) ~= nil):toBe(true)
			expect(harness:find("applier.restoreAudit()", 1, true) ~= nil):toBe(true)
			expect(harness:find("audit.maxDelta <= 1e-4", 1, true) ~= nil):toBe(true)
			expect(harness:find("map.simulate(simEntries, map.SIM_SECONDS, map.DT)", 1, true) ~= nil):toBe(true)
			expect(harness:find("os.clock()", 1, true) ~= nil):toBe(true)
			expect(harness:find("real catalog animation ", 1, true) ~= nil):toBe(true)
			expect(harness:find('review.enable("npcs_idle_r8", game, { studio = true })', 1, true) ~= nil):toBe(true)
		end)
	end)
end
