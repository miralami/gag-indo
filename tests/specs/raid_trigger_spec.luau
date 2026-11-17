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
end
