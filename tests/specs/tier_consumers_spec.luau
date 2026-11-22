--!nocheck
-- TierScale: the pure math behind the first fidelity-tier consumers (ActionFeel bursts, Wind sway).

return function(t, Env)
	local expect = t.expect
	local env, TierScale, FidelityTier

	local function settings(tier)
		return FidelityTier.settingsFor(tier)
	end

	t:describe("TierScale", function()
		t:beforeEach(function()
			env = Env.new()
			TierScale = env:require("client/Feel/TierScale")
			FidelityTier = env:require("client/Feel/FidelityTier")
		end)

		t:describe("emitCount", function()
			t:it("scales by the tier particle rate", function()
				expect(TierScale.emitCount(30, settings("Tinggi"))):toBe(30)
				expect(TierScale.emitCount(30, settings("Sedang"))):toBe(21)
				expect(TierScale.emitCount(30, settings("Rendah"))):toBe(12)
			end)

			t:it("never drops below 1 particle", function()
				for _, tier in FidelityTier.TIERS do
					expect(TierScale.emitCount(1, settings(tier))):toBeAtLeast(1)
					expect(TierScale.emitCount(0, settings(tier))):toBe(1)
					expect(TierScale.emitCount(-5, settings(tier))):toBe(1)
				end
			end)

			t:it("keeps rarity ordering Biasa to Sultan on every tier", function()
				for _, tier in FidelityTier.TIERS do
					local biasa = TierScale.emitCount(20, settings(tier))
					local sultan = TierScale.emitCount(30, settings(tier))
					expect(sultan >= biasa):toBeTruthy()
				end
			end)

			t:it("treats nil or malformed settings as Sedang", function()
				expect(TierScale.emitCount(20, nil)):toBe(TierScale.emitCount(20, settings("Sedang")))
				expect(TierScale.emitCount(20, "bad")):toBe(14)
				expect(TierScale.emitCount(20, { particleRate = 0 / 0 })):toBe(14)
				expect(TierScale.emitCount(20, { particleRate = -1 })):toBe(1)
			end)

			t:it("survives bad bases", function()
				expect(TierScale.emitCount(nil, nil)):toBe(1)
				expect(TierScale.emitCount(0 / 0, nil)):toBe(1)
				expect(TierScale.emitCount(math.huge, { particleRate = 0.5 }) >= 1):toBeTruthy()
			end)
		end)

		t:describe("rate", function()
			t:it("scales a positive rate and keeps zero at zero", function()
				expect(TierScale.rate(10, settings("Rendah"))):toBeNear(4, 1e-9)
				expect(TierScale.rate(10, settings("Tinggi"))):toBeNear(10, 1e-9)
				expect(TierScale.rate(0, settings("Rendah"))):toBe(0)
				expect(TierScale.rate(10, nil)):toBeNear(7, 1e-9)
			end)
		end)

		t:describe("lifetime", function()
			t:it("shortens life on Rendah only", function()
				local lo, hi = TierScale.lifetime(0.5, 1, settings("Rendah"))
				expect(lo):toBeNear(0.3, 1e-9)
				expect(hi):toBeNear(0.6, 1e-9)
				lo, hi = TierScale.lifetime(0.5, 1, settings("Sedang"))
				expect(lo):toBe(0.5)
				expect(hi):toBe(1)
				lo, hi = TierScale.lifetime(0.5, 1, settings("Tinggi"))
				expect(hi):toBe(1)
			end)

			t:it("keeps min <= max and positive for bad inputs", function()
				for _, case in { { nil, nil }, { 0 / 0, 0 / 0 }, { 1, 0.2 }, { -3, -1 } } do
					local lo, hi = TierScale.lifetime(case[1], case[2], nil)
					expect(lo > 0):toBeTruthy()
					expect(lo <= hi):toBeTruthy()
				end
				local lo = TierScale.lifetime(0.5, 1, { particleLifeScale = 0 })
				expect(lo):toBe(0.5)
			end)
		end)

		t:describe("swayWeight", function()
			t:it("is full up close and zero beyond each tier's range", function()
				for _, tier in FidelityTier.TIERS do
					local s = settings(tier)
					expect(TierScale.swayWeight(0, s)):toBe(1)
					expect(TierScale.swayWeight(s.foliageSwayRange, s)):toBe(0)
					expect(TierScale.swayWeight(s.foliageSwayRange + 100, s)):toBe(0)
				end
			end)

			t:it("is monotonic non-increasing in distance and stays in 0..1", function()
				for _, tier in FidelityTier.TIERS do
					local s = settings(tier)
					local previous = 1
					for d = 0, 120, 2 do
						local w = TierScale.swayWeight(d, s)
						expect(w >= 0 and w <= 1):toBeTruthy()
						expect(w <= previous):toBeTruthy()
						previous = w
					end
				end
			end)

			t:it("reaches farther on higher tiers", function()
				local d = 40
				expect(TierScale.swayWeight(d, settings("Rendah")) < TierScale.swayWeight(d, settings("Sedang"))):toBeTruthy()
				expect(TierScale.swayWeight(d, settings("Sedang")) <= TierScale.swayWeight(d, settings("Tinggi"))):toBeTruthy()
			end)

			t:it("handles bad distances and settings", function()
				expect(TierScale.swayWeight(0 / 0, nil)):toBe(0)
				expect(TierScale.swayWeight(nil, nil)):toBe(0)
				expect(TierScale.swayWeight("far", nil)):toBe(0)
				expect(TierScale.swayWeight(math.huge, nil)):toBe(0)
				expect(TierScale.swayWeight(-10, nil)):toBe(1)
				expect(TierScale.swayWeight(10, nil)):toBe(TierScale.swayWeight(10, settings("Sedang")))
				expect(TierScale.swayWeight(10, { foliageSwayRange = 0 })):toBe(0)
				expect(TierScale.swayWeight(10, { foliageSwayRange = 0 / 0 })):toBe(1)
			end)
		end)

		t:describe("swayRange", function()
			t:it("matches the tier table and defaults to Sedang", function()
				expect(TierScale.swayRange(settings("Rendah"))):toBe(25)
				expect(TierScale.swayRange(settings("Tinggi"))):toBe(80)
				expect(TierScale.swayRange(nil)):toBe(50)
			end)
		end)
	end)
end
