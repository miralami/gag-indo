--!nocheck
-- Q6 before/after comparator (WORK_QUEUE item 23). Pure, so Lune proves every verdict; only the
-- real published-place leave/rejoin needs a human (docs/testing/Q6_PUBLISHED_PLACE.md).
return function(t, Env, Fakes)
	local expect = t.expect
	local Check

	local function snapshot(overrides)
		local base = {
			cash = 48,
			lifetimeEarned = 260,
			rank = "gurem",
			seeds = { padi = 6, jagung = 0 },
			tilesOwned = 6,
			tiles = { [1] = { crop = "padi", ready = false, hot = false } },
			sack = 0,
			gudang = 3,
			tutorialStep = "sell",
			quests = { login = { progress = 1, target = 1, done = true } },
			name = "Player1",
			userId = 100,
			position = { X = 1, Y = 0, Z = 0 },
			shop = { padi = 2 },
			tutorialId = "jual",
		}
		for key, value in overrides or {} do
			base[key] = value
		end
		return base
	end

	t:describe("Q6 persistence comparator", function()
		t:beforeEach(function()
			local env = Env.new()
			Check = env:require("server/Testing/PersistenceCheck")
		end)

		t:it("passes when every compared field survives a rejoin", function()
			local results = Check.compare(snapshot(), snapshot())
			expect(results.ok):toBe(true)
			expect(#results.mismatches):toBe(0)
			expect(#results.matches):toBe(#Check.FIELDS)
		end)

		t:it("ignores identity, position, shop and hint changes after rejoin", function()
			local after = snapshot({
				name = "SomeoneElse",
				userId = 999,
				position = { X = 200, Y = 0, Z = 0 },
				shop = { jagung = 5 },
				tutorialId = "panen",
			})
			expect(Check.compare(snapshot(), after).ok):toBe(true)
		end)

		t:it("does not treat a growing crop becoming ready as data loss", function()
			local before = snapshot()
			local after = snapshot({ tiles = { [1] = { crop = "padi", ready = true, hot = false } } })
			expect(Check.compare(before, after).ok):toBe(true)
		end)

		t:it("catches lost cash, seeds, tiles and tile crops", function()
			local after = snapshot({
				cash = 0,
				seeds = { padi = 0, jagung = 0 },
				tilesOwned = 6,
				tiles = { [1] = { crop = "jagung", ready = false, hot = false } },
			})
			local results = Check.compare(snapshot(), after)
			expect(results.ok):toBe(false)
			local fields = {}
			for _, item in ipairs(results.mismatches) do
				fields[item.field] = true
			end
			expect(fields.cash):toBe(true)
			expect(fields.seeds):toBe(true)
			expect(fields.tiles):toBe(true)
			expect(fields.tilesOwned):toBeNil()
		end)

		t:it("records one row per mismatch with the before and after values", function()
			local results = Check.compare(snapshot(), snapshot({ cash = 0, gudang = 0 }))
			expect(#results.mismatches):toBe(2)
			expect(results.mismatches[1].field):toBe("cash")
			expect(results.mismatches[1].before):toBe(48)
			expect(results.mismatches[1].after):toBe(0)
			expect(results.mismatches[2].field):toBe("gudang")
			expect(results.mismatches[2].before):toBe(3)
			expect(results.mismatches[2].after):toBe(0)
		end)

		t:it("treats a missing before or after snapshot as a failure, without erroring", function()
			local noBefore = Check.compare(nil, snapshot())
			expect(noBefore.ok):toBe(false)
			expect(noBefore.missingBefore):toBe(true)
			expect(Check.lines(noBefore)[2]):toBe("  NO BEFORE SNAPSHOT (capture before leaving)")
			local noAfter = Check.compare(snapshot(), nil)
			expect(noAfter.ok):toBe(false)
			expect(noAfter.missingAfter):toBe(true)
			expect(Check.lines(noAfter)[2]):toBe("  NO AFTER SNAPSHOT (status could not be read after rejoin)")
			-- Two absent saves agreeing on nil is not persistence.
			local neither = Check.compare(nil, nil)
			expect(neither.ok):toBe(false)
			expect(#neither.matches):toBe(#Check.FIELDS)
		end)

		t:it("formats PASS and one line per lost field", function()
			expect(Check.lines(Check.compare(snapshot(), snapshot()))):toEqual({
				"Q6 persistence: 10/10 fields match; PASS",
			})
			local lines = Check.lines(Check.compare(snapshot(), snapshot({ cash = 0 })))
			expect(lines[1]):toBe("Q6 persistence: 9/10 fields match; FAIL")
			expect(lines[2]):toBe("  LOST/CHANGED cash: before=48 after=0")
		end)

		t:it("keeps the compared-field list explicit so drift is caught", function()
			expect(Check.FIELDS):toEqual({
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
