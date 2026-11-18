--!nocheck
-- The Studio-only force-raid hook gate (MASTER_PLAN "Next up" #1, 2026-11-17).
-- A raid can be triggered immediately in playtests, but only when Studio + the in-memory
-- harness flag + an admin all agree. A published server can never satisfy the Studio test,
-- and the flag is never saved, so the hook can never ship enabled. Pure: no game APIs.
return function(t, Env)
	local expect = t.expect
	local env, Gate, RaidTrigger

	local function setup()
		env = Env.new()
		Gate = env:require("server/Testing/Gate")
		RaidTrigger = env:require("server/Testing/RaidTrigger")
	end

	t:describe("RaidTrigger gate", function()
		t:beforeEach(setup)

		t:it("refuses a forced raid while the harness flag is off", function()
			expect(Gate.isOpen()):toBe(false)
			expect(RaidTrigger.allowed({ studio = true, flag = false, admin = true })):toBe(false)
			expect(RaidTrigger.allowed({ studio = true, admin = true })):toBe(false)
		end)

		t:it("refuses in a published server even with flag and admin", function()
			expect(RaidTrigger.allowed({ studio = false, flag = true, admin = true })):toBe(false)
		end)

		t:it("refuses a non-admin even with studio and flag", function()
			expect(RaidTrigger.allowed({ studio = true, flag = true, admin = false })):toBe(false)
		end)

		t:it("allows only a Studio admin with the flag open", function()
			expect(RaidTrigger.allowed({ studio = true, flag = true, admin = true })):toBe(true)
		end)

		t:it("takes booleans only, never truthy values", function()
			expect(RaidTrigger.allowed({ studio = 1, flag = true, admin = true })):toBe(false)
			expect(RaidTrigger.allowed({ studio = true, flag = "yes", admin = true })):toBe(false)
			expect(RaidTrigger.allowed({ studio = true, flag = true, admin = {} })):toBe(false)
			expect(RaidTrigger.allowed(nil)):toBe(false)
		end)

		t:it("matches the live gate once a Studio admin opens it", function()
			expect(Gate.enable({ studio = true, admin = true })):toBe(true)
			expect(RaidTrigger.allowed({
				studio = true,
				flag = Gate.isOpen(),
				admin = true,
			})):toBe(true)
			Gate.close()
			expect(RaidTrigger.allowed({
				studio = true,
				flag = Gate.isOpen(),
				admin = true,
			})):toBe(false)
		end)

		t:it("never ships enabled: flag starts closed and close() keeps it closed", function()
			expect(Gate.isOpen()):toBe(false)
			Gate.enable({ studio = true, admin = true })
			Gate.close()
			expect(RaidTrigger.allowed({ studio = true, flag = Gate.isOpen(), admin = true })):toBe(false)
		end)
	end)

	t:describe("RaidTrigger payload", function()
		t:beforeEach(setup)

		t:it("defaults to a normal (non-viral) raid", function()
			expect(RaidTrigger.viral(nil)):toBe(false)
			expect(RaidTrigger.viral("viral")):toBe(false)
			expect(RaidTrigger.viral({})):toBe(false)
			expect(RaidTrigger.viral({ viral = false })):toBe(false)
		end)

		t:it("only a literal viral = true forces a VIRAL raid", function()
			expect(RaidTrigger.viral({ viral = true })):toBe(true)
			expect(RaidTrigger.viral({ viral = 1 })):toBe(false)
		end)
	end)

	t:describe("RaidTrigger force cooldown override", function()
		t:beforeEach(setup)

		t:it("only a literal force = true takes the override branch", function()
			expect(RaidTrigger.force(nil)):toBe(false)
			expect(RaidTrigger.force("force")):toBe(false)
			expect(RaidTrigger.force({})):toBe(false)
			expect(RaidTrigger.force({ force = false })):toBe(false)
			expect(RaidTrigger.force({ force = 1 })):toBe(false)
			expect(RaidTrigger.force({ force = true })):toBe(true)
		end)

		t:it("shows start a zero cooldown and restores the old value on success", function()
			local data = { cooldowns = { raidSafeUntil = 999, other = "keep" } }
			local seen
			RaidTrigger.withTemporaryCooldown(data, function()
				seen = data.cooldowns.raidSafeUntil
			end)
			expect(seen):toBe(0)
			expect(data.cooldowns.raidSafeUntil):toBe(999)
			expect(data.cooldowns.other):toBe("keep")
		end)

		t:it("restores an absent cooldown table and an absent value exactly", function()
			local data = {}
			RaidTrigger.withTemporaryCooldown(data, function()
				expect(data.cooldowns.raidSafeUntil):toBe(0)
			end)
			expect(data.cooldowns):toBeNil() -- injected table removed again
			local withTable = { cooldowns = {} }
			RaidTrigger.withTemporaryCooldown(withTable, function()
				expect(withTable.cooldowns.raidSafeUntil):toBe(0)
			end)
			expect(withTable.cooldowns.raidSafeUntil):toBeNil() -- key removed, table kept
			expect(type(withTable.cooldowns)):toBe("table")
		end)

		t:it("restores a non-table cooldowns field verbatim", function()
			local sentinel = "broken"
			local data = { cooldowns = sentinel }
			RaidTrigger.withTemporaryCooldown(data, function()
				expect(type(data.cooldowns)):toBe("table")
			end)
			expect(data.cooldowns):toBe(sentinel)
		end)

		t:it("restores the cooldown and rethrows when start errors", function()
			local data = { cooldowns = { raidSafeUntil = 777 } }
			local ok = pcall(RaidTrigger.withTemporaryCooldown, data, function()
				error("boom")
			end)
			expect(ok):toBe(false)
			expect(data.cooldowns.raidSafeUntil):toBe(777)
		end)

		t:it("still calls start with no data table (no profile)", function()
			local called = 0
			RaidTrigger.withTemporaryCooldown(nil, function()
				called += 1
			end)
			expect(called):toBe(1)
		end)
	end)
end
