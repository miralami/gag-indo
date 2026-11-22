--!nocheck
-- WORK_QUEUE item 136: additive review staging. enable() still keeps one candidate active;
-- enableAdditive() stages a candidate beside the others and disableAll() restores everything.
-- Pure Lune spec: fake appliers registered through the real LookDev.register gate, no game API.

local IDS = { "hubveg_r8", "plots_r8", "facades_r8" }

return function(t, Env)
	local expect = t.expect

	local function fresh()
		return Env.new():require("shared/LookDev")
	end

	local function newLog()
		return { applied = {}, restored = {}, applyOrder = {}, restoreOrder = {}, plans = {} }
	end

	local function registerFakes(LookDev, log)
		for _, id in IDS do
			LookDev.register(id, {
				apply = function(plan)
					log.applied[id] = (log.applied[id] or 0) + 1
					log.applyOrder[#log.applyOrder + 1] = id
					log.plans[id] = plan
				end,
				restore = function()
					log.restored[id] = (log.restored[id] or 0) + 1
					log.restoreOrder[#log.restoreOrder + 1] = id
				end,
			})
			expect(LookDev.hasApplier(id)):toBe(true)
		end
	end

	t:describe("LookDev additive staging (item 136)", function()
		t:it("stages three candidates together without changing current() or restoring anything", function()
			local LookDev = fresh()
			local log = newLog()
			registerFakes(LookDev, log)
			for _, id in IDS do
				local ok, why = LookDev.enableAdditive(id, { studio = true })
				expect(ok):toBe(true)
				expect(why):toBe(nil)
			end
			expect(LookDev.current()):toBe(nil)
			for _, id in IDS do
				expect(log.applied[id]):toBe(1)
				expect(log.plans[id].id):toBe(id)
				expect(log.restored[id]):toBe(nil)
			end
			expect(#log.applyOrder):toBe(3)
			expect(log.applyOrder[1]):toBe("hubveg_r8")
			expect(log.applyOrder[2]):toBe("plots_r8")
			expect(log.applyOrder[3]):toBe("facades_r8")
			expect(#log.restoreOrder):toBe(0)
			local staged = LookDev.additiveIds()
			expect(#staged):toBe(3)
			staged[1] = "tampered"
			expect(LookDev.additiveIds()[1]):toBe("hubveg_r8") -- accessor is a copy
		end)

		t:it("re-enabling an already staged id is idempotent", function()
			local LookDev = fresh()
			local log = newLog()
			registerFakes(LookDev, log)
			expect(LookDev.enableAdditive("hubveg_r8", { studio = true })):toBe(true)
			expect(LookDev.enableAdditive("hubveg_r8", { studio = true })):toBe(true)
			expect(log.applied.hubveg_r8):toBe(1)
			expect(#log.applyOrder):toBe(1)
			expect(#LookDev.additiveIds()):toBe(1)
			expect(LookDev.current()):toBe(nil)
		end)

		t:it("disableAll restores each staged id once in reverse order and is repeatable", function()
			local LookDev = fresh()
			local log = newLog()
			registerFakes(LookDev, log)
			for _, id in IDS do
				LookDev.enableAdditive(id, { studio = true })
			end
			expect(LookDev.disableAll()):toBe(true)
			for _, id in IDS do
				expect(log.restored[id]):toBe(1)
			end
			expect(log.restoreOrder[1]):toBe("facades_r8")
			expect(log.restoreOrder[2]):toBe("plots_r8")
			expect(log.restoreOrder[3]):toBe("hubveg_r8")
			expect(#LookDev.additiveIds()):toBe(0)
			expect(LookDev.current()):toBe(nil)
			expect(LookDev.disableAll()):toBe(false)
			expect(#log.restoreOrder):toBe(3)
		end)

		t:it("leaves the existing single-active enable/disable behaviour unchanged", function()
			local LookDev = fresh()
			local log = newLog()
			registerFakes(LookDev, log)
			expect(LookDev.enable("hubveg_r8", { studio = true })):toBe(true)
			expect(LookDev.current()):toBe("hubveg_r8")
			expect(LookDev.enable("plots_r8", { studio = true })):toBe(true)
			expect(log.restored.hubveg_r8):toBe(1) -- switching restores the first
			expect(LookDev.current()):toBe("plots_r8")
			expect(LookDev.disable()):toBe(true)
			expect(log.restored.plots_r8):toBe(1)
			expect(LookDev.current()):toBe(nil)
			expect(LookDev.disable()):toBe(false)
			expect(#LookDev.additiveIds()):toBe(0)
		end)

		t:it("refuses non-Studio callers and unknown ids exactly like enable", function()
			local LookDev = fresh()
			local log = newLog()
			registerFakes(LookDev, log)
			local ok, why = LookDev.enableAdditive("hubveg_r8", { studio = false })
			expect(ok):toBe(false)
			expect(why):toBe("look-dev candidates are Studio-only")
			expect(log.applied.hubveg_r8):toBe(nil)
			expect(#LookDev.additiveIds()):toBe(0)
			expect(LookDev.current()):toBe(nil)
			local unknownOk, unknownWhy = LookDev.enableAdditive("nope", { studio = true })
			expect(unknownOk):toBe(false)
			expect(unknownWhy):toBe("unknown candidate")
		end)
	end)
end
