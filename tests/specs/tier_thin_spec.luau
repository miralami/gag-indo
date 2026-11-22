--!nocheck
-- WORK_QUEUE item 104 lane A: TierThin (pure decorative thinning) and the optional tier that
-- LookDev.enable()/enableAdditive() forwards into an applier's plan. No Roblox services.

return function(t, Env)
	local expect = t.expect
	local TierThin

	local function keptIndexes(tier, total, structuralCount)
		local kept = 0
		for index = 1, total do
			if TierThin.shouldKeep(tier, index, index <= (structuralCount or 0)) then
				kept += 1
			end
		end
		return kept
	end

	t:describe("TierThin", function()
		t:beforeEach(function()
			TierThin = Env.new():require("shared/TierThin")
		end)

		t:describe("normalize", function()
			t:it("locks the three tiers and the conservative Tinggi default", function()
				expect(#TierThin.TIERS):toBe(3)
				expect(TierThin.TIERS[1]):toBe("Rendah")
				expect(TierThin.TIERS[2]):toBe("Sedang")
				expect(TierThin.TIERS[3]):toBe("Tinggi")
				expect(TierThin.DEFAULT):toBe("Tinggi")
				for _, tier in ipairs(TierThin.TIERS) do
					expect(TierThin.normalize(tier)):toBe(tier)
				end
			end)

			t:it("falls back to Tinggi for nil and unknown values", function()
				expect(TierThin.normalize(nil)):toBe("Tinggi")
				expect(TierThin.normalize()):toBe("Tinggi")
				for _, bad in ipairs({ "bogus", "", "tinggi", "Otomatis", 42, true, {} }) do
					expect(TierThin.normalize(bad)):toBe("Tinggi")
				end
			end)
		end)

		t:describe("shouldKeep", function()
			t:it("never thins structural instances at any tier", function()
				for _, tier in ipairs(TierThin.TIERS) do
					for index = 1, 12 do
						expect(TierThin.shouldKeep(tier, index, true)):toBe(true)
					end
				end
				expect(TierThin.shouldKeep("bogus", 3, true)):toBe(true)
			end)

			t:it("keeps every decorative instance on Tinggi and Sedang", function()
				for _, tier in ipairs({ "Tinggi", "Sedang" }) do
					for index = 1, 20 do
						expect(TierThin.shouldKeep(tier, index, false)):toBe(true)
					end
					expect(TierThin.keptCount(tier, 11, 0)):toBe(11)
					expect(TierThin.keptCount(tier, 11, 3)):toBe(11)
				end
			end)

			t:it("halves Rendah decoratives deterministically", function()
				for index = 1, 12 do
					expect(TierThin.shouldKeep("Rendah", index, false)):toBe(index % 2 == 0)
					expect(TierThin.shouldKeep("bogus", index, false)):toBe(true)
				end
				-- First two entries structural: 1,2 kept, 3 dropped, 4 kept, 5 dropped, 6 kept.
				for index = 1, 6 do
					expect(TierThin.shouldKeep("Rendah", index, index <= 2)):toBe(index <= 2 or index % 2 == 0)
				end
			end)
		end)

		t:describe("keptCount", function()
			t:it("matches floor(n/2) decorative for n = 1..11", function()
				for total = 1, 11 do
					expect(TierThin.keptCount("Rendah", total, 0)):toBe(math.floor(total / 2))
					expect(keptIndexes("Rendah", total, 0)):toBe(math.floor(total / 2))
				end
			end)

			t:it("mirrors shouldKeep exactly with structural entries first", function()
				for total = 1, 11 do
					for structural = 0, total do
						expect(TierThin.keptCount("Rendah", total, structural)):toBe(
							math.floor(total / 2) + math.ceil(structural / 2)
						)
						expect(keptIndexes("Rendah", total, structural)):toBe(
							TierThin.keptCount("Rendah", total, structural)
						)
					end
				end
				expect(TierThin.keptCount("Rendah", 6, 1)):toBe(4)
				expect(TierThin.keptCount("Rendah", 5, 2)):toBe(3)
				expect(keptIndexes("Rendah", 6, 1)):toBe(4)
			end)

			t:it("keeps Rendah decorative count under 55% of Tinggi", function()
				for total = 1, 40 do
					local low = TierThin.keptCount("Rendah", total, 0)
					local high = TierThin.keptCount("Tinggi", total, 0)
					expect(low <= 0.55 * high):toBeTruthy()
				end
			end)
		end)
	end)

	t:describe("LookDev optional tier", function()
		local LookDev

		t:beforeEach(function()
			LookDev = Env.new():require("shared/LookDev")
		end)

		local function capture(id, opts)
			local captured
			LookDev.register(id, {
				apply = function(plan)
					captured = plan
				end,
				restore = function() end,
			})
			local ok, err = LookDev.enable(id, opts)
			expect(ok):toBe(true)
			expect(err):toBeNil()
			return captured
		end

		t:it("forwards a valid opts.tier into the plan", function()
			expect(capture("rocks_r9", { studio = true, tier = "Rendah" }).tier):toBe("Rendah")
			LookDev.disable()
		end)

		t:it("leaves plan.tier unset for nil or bogus tiers", function()
			expect(capture("rocks_r9", { studio = true }).tier):toBeNil()
			LookDev.disable()
			expect(capture("rocks_r9", { studio = true, tier = "bogus" }).tier):toBeNil()
			LookDev.disable()
		end)

		t:it("does the same for additively staged candidates", function()
			local captured
			LookDev.register("rocks_r9", {
				apply = function(plan)
					captured = plan
				end,
				restore = function() end,
			})
			expect(LookDev.enableAdditive("rocks_r9", { studio = true, tier = "Sedang" })):toBe(true)
			expect(captured.tier):toBe("Sedang")
			LookDev.disableAll()
		end)
	end)
end
