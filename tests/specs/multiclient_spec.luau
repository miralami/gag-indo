--!nocheck
-- Q5 multi-client comparator (WORK_QUEUE item 22). The comparator is pure, so every branch is
-- proven here under Lune; only the live ten-player run needs a human at Studio's Test tab.
return function(t, Env, Fakes)
	local expect = t.expect
	local Check

	-- A fresh-save snapshot with the fields the comparator looks at, plus the fields it must
	-- deliberately ignore (identity, position, UserId-seeded shop, onboarding hint id).
	local function snapshot(overrides)
		local base = {
			name = "Player1",
			userId = 100,
			cash = 50,
			lifetimeEarned = 0,
			rank = "gurem",
			seeds = { padi = 4, jagung = 0 },
			tilesOwned = 6,
			tiles = { [1] = { crop = "padi", ready = false, hot = false } },
			sack = 1,
			gudang = 0,
			tutorialStep = "harvest",
			tutorialId = "tanam",
			quests = { login = { progress = 1, target = 1, done = true } },
			shop = { padi = 3 },
			position = { X = 0, Y = 0, Z = 0 },
		}
		for key, value in overrides or {} do
			base[key] = value
		end
		return base
	end

	local function steps(overrides)
		local list = {
			{ action = "status", ok = true },
			{ action = "plant", ok = true },
			{ action = "ready", ok = true },
			{ action = "harvest", ok = true },
			{ action = "sell", ok = true },
			{ action = "buy", ok = true },
			{ action = "quest", ok = true },
			{ action = "save", ok = false, critical = false, error = "API services off" },
		}
		for _, change in overrides or {} do
			for index, step in list do
				if step.action == change.action then
					for key, value in change do
						if key ~= "action" then
							step[key] = value
						end
					end
				end
			end
		end
		return list
	end

	local function record(name, final, stepList)
		return { name = name, userId = 100, steps = stepList or steps(), final = final }
	end

	t:describe("Q5 multi-client comparator", function()
		t:beforeEach(function()
			local env = Env.new()
			Check = env:require("server/Testing/MultiClientCheck")
		end)

		t:it("digest is stable regardless of table key order", function()
			local a = { seeds = { padi = 4, jagung = 0 }, cash = 50 }
			local b = { cash = 50, seeds = { jagung = 0, padi = 4 } }
			expect(Check.digest(a)):toBe(Check.digest(b))
			expect(Check.digest(a)).never:toBe(Check.digest({ cash = 51, seeds = b.seeds }))
		end)

		t:it("digest prints NaN, infinity and nested tables instead of hiding them", function()
			expect(Check.digest(0 / 0)):toBe("nan")
			expect(Check.digest(math.huge)):toBe("inf")
			expect(Check.digest(-math.huge)):toBe("-inf")
			expect(Check.digest({ [1] = { crop = "padi" } })):toBe('{1={crop="padi",},}')
			expect(Check.digest(function() end)):toBe("<function>")
		end)

		t:it("passes with no stuck or desync when every player agrees", function()
			local results = Check.check({
				record("Player1", snapshot()),
				record("Player2", snapshot({ name = "Player2", userId = 200, shop = { padi = 9 } })),
				record("Player3", snapshot({ name = "Player3", position = { X = 5, Y = 0, Z = 0 } })),
			})
			expect(results.ok):toBe(true)
			expect(results.playerCount):toBe(3)
			expect(#results.stuck):toBe(0)
			expect(#results.desync):toBe(0)
			expect(#results.complete):toBe(3)
		end)

		t:it("does not desync on the excluded identity, shop or hint fields", function()
			local results = Check.check({
				record("A", snapshot()),
				record(
					"B",
					snapshot({
						name = "B",
						userId = 999,
						tutorialId = "panen",
						shop = { jagung = 2 },
						position = { X = 99, Y = 0, Z = 0 },
					})
				),
			})
			expect(results.ok):toBe(true)
			expect(#results.desync):toBe(0)
		end)

		t:it("reports a desync field with one value per player", function()
			local results = Check.check({
				record("A", snapshot()),
				record("B", snapshot({ name = "B", cash = 130 })),
				record("C", snapshot({ name = "C", cash = 50 })),
			})
			expect(results.ok):toBe(false)
			expect(#results.desync):toBe(1)
			expect(results.desync[1].field):toBe("cash")
			expect(results.desync[1].values.A):toBe(50)
			expect(results.desync[1].values.B):toBe(130)
			expect(results.desync[1].values.C):toBe(50)
			expect(#results.stuck):toBe(0)
		end)

		t:it("detects desync in a nested field such as seeds", function()
			local results = Check.check({
				record("A", snapshot()),
				record("B", snapshot({ name = "B", seeds = { padi = 5, jagung = 0 } })),
			})
			expect(#results.desync):toBe(1)
			expect(results.desync[1].field):toBe("seeds")
		end)

		t:it("marks a player stuck on a critical failure and names the action", function()
			local bad = steps({ { action = "harvest", ok = false, error = "no ready tile" } })
			local results = Check.check({
				record("A", snapshot(), bad),
				record("B", snapshot({ name = "B" })),
			})
			expect(results.ok):toBe(false)
			expect(#results.stuck):toBe(1)
			expect(results.stuck[1].name):toBe("A")
			expect(Check.digest(results.stuck[1].reason)):toBe(Check.digest("harvest: no ready tile"))
			expect(results.complete):toEqual({ "B" })
		end)

		t:it("ignores a non-critical save refusal when deciding stuck", function()
			local results = Check.check({ record("A", snapshot()) })
			expect(results.ok):toBe(true)
			expect(#results.stuck):toBe(0)
		end)

		t:it("marks a player with no snapshot stuck even if every step reported ok", function()
			local results = Check.check({ record("A", nil) })
			expect(results.ok):toBe(false)
			expect(#results.stuck):toBe(1)
			expect(Check.digest(results.stuck[1].reason)):toBe(
				Check.digest("no save snapshot (save not loaded or player left)")
			)
		end)

		t:it("is safe with zero or one player and never invents a desync", function()
			local empty = Check.check({})
			expect(empty.ok):toBe(true)
			expect(empty.playerCount):toBe(0)
			expect(#empty.desync):toBe(0)
			local one = Check.check({ record("A", snapshot()) })
			expect(one.ok):toBe(true)
			expect(#one.desync):toBe(0)
		end)

		t:it("formats PASS, OK, STUCK and DESYNC lines", function()
			local pass = Check.check({ record("A", snapshot()) })
			expect(Check.lines(pass)):toEqual({
				"Q5 multi-client: 1 player(s); PASS",
				"  OK A",
			})
			local fail = Check.check({
				record("A", snapshot(), steps({ { action = "plant", ok = false, error = "no seed" } })),
				record("B", snapshot({ name = "B", cash = 130 })),
			})
			local lines = Check.lines(fail)
			expect(lines[1]):toBe("Q5 multi-client: 2 player(s); FAIL")
			expect(Check.digest(lines[2])):toBe(Check.digest("  STUCK A: plant: no seed"))
			expect(lines[3]):toBe("  DESYNC cash: A=50 | B=130")
			expect(lines[4]):toBe("  OK B")
		end)

		t:it("keeps the comparison allowlist explicit so drift is caught", function()
			expect(Check.STATE_FIELDS):toEqual({
				"cash",
				"lifetimeEarned",
				"rank",
				"seeds",
				"tilesOwned",
				"tiles",
				"sack",
				"gudang",
				"tutorialStep",
				"quests",
			})
		end)
	end)
end
