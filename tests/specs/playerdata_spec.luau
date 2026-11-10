--!nocheck
-- Save-data migrations. A mistake here silently corrupts real players' progress.

return function(t, Env)
	local expect = t.expect
	local env, PlayerData

	t:describe("PlayerData.migrate", function()
		t:beforeEach(function()
			env = Env.new()
			env:mock("server/Packages/ProfileStore", {
				New = function()
					return {}
				end,
			})
			PlayerData = env:require("server/Data/PlayerData")
		end)

		t:it("treats a save with no version as version 1 and upgrades it", function()
			local data = { harvest = {} }
			PlayerData.migrate(data)
			expect(data.version):toBe(2)
		end)

		t:it("leaves an up-to-date save untouched", function()
			local data = {
				version = 2,
				harvest = { padi = { count = 4, qualitySum = 3.6, hotCount = 1, hotQualitySum = 0.9 } },
			}
			PlayerData.migrate(data)
			expect(data.harvest.padi.count):toBe(4)
			expect(data.harvest.padi.qualitySum):toBeNear(3.6)
			expect(data.harvest.padi.hotQualitySum):toBeNear(0.9)
		end)

		t:describe("v1 -> v2 hot produce split", function()
			t:it("moves the average quality of hot items out of the clean sum", function()
				-- 4 items, average quality 0.9, 2 of them hot.
				local data = {
					version = 1,
					harvest = { padi = { count = 4, qualitySum = 3.6, hotCount = 2 } },
				}
				PlayerData.migrate(data)
				local padi = data.harvest.padi
				expect(padi.hotQualitySum):toBeNear(1.8)
				expect(padi.qualitySum):toBeNear(1.8)
				expect(padi.count):toBe(4)
			end)

			t:it("keeps total quality unchanged", function()
				local data = {
					version = 1,
					harvest = { jagung = { count = 5, qualitySum = 4.0, hotCount = 3 } },
				}
				PlayerData.migrate(data)
				local jagung = data.harvest.jagung
				expect(jagung.qualitySum + jagung.hotQualitySum):toBeNear(4.0)
			end)

			t:it("gives a sack with no hot items a zero hot sum", function()
				local data = { version = 1, harvest = { padi = { count = 2, qualitySum = 1.8 } } }
				PlayerData.migrate(data)
				expect(data.harvest.padi.hotQualitySum):toBe(0)
				expect(data.harvest.padi.qualitySum):toBeNear(1.8)
			end)

			t:it("does not divide by zero on an empty sack", function()
				local data = { version = 1, harvest = { padi = { count = 0, qualitySum = 0, hotCount = 0 } } }
				PlayerData.migrate(data)
				expect(data.harvest.padi.hotQualitySum):toBe(0)
			end)

			t:it("skips malformed sack entries instead of crashing", function()
				local data = { version = 1, harvest = { padi = "broken" } }
				PlayerData.migrate(data)
				expect(data.version):toBe(2)
			end)
		end)
	end)
end
