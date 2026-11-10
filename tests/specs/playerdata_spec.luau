--!nocheck
-- Save-data migrations. A mistake here silently corrupts real players' progress, so these
-- tests walk every schema version into v3 and check the produce / items shape.

return function(t, Env)
	local expect = t.expect
	local env, PlayerData, Produce, Game

	local function setup()
		env = Env.new()
		env:mock("server/Packages/ProfileStore", {
			New = function()
				return {}
			end,
		})
		PlayerData = env:require("server/Data/PlayerData")
		Produce = env:require("shared/Produce")
		Game = env:require("shared/Config/Game")
	end

	t:describe("PlayerData.migrate", function()
		t:beforeEach(setup)

		t:describe("versioning", function()
			t:it("treats a save with no version as version 1", function()
				local data = {}
				PlayerData.migrate(data)
				expect(data.version):toBe(PlayerData.CURRENT_VERSION)
			end)

			t:it("upgrades a v1 save all the way to the current version", function()
				local data = { harvest = {} }
				PlayerData.migrate(data)
				expect(data.version):toBe(3)
			end)

			t:it("leaves an up-to-date save on the same version", function()
				local data = { version = 3, produce = {} }
				PlayerData.migrate(data)
				expect(data.version):toBe(3)
			end)

			t:it("is idempotent", function()
				local data = { version = 1, harvest = { padi = { count = 2, qualitySum = 1.6, hotCount = 1 } } }
				PlayerData.migrate(data)
				local first = table.clone(data.produce[Produce.key("padi", "biasa", {})])
				PlayerData.migrate(data)
				expect(data.version):toBe(3)
				expect(data.produce[Produce.key("padi", "biasa", {})].count):toBe(first.count)
			end)
		end)

		t:describe("v1 -> v2 hot produce split", function()
			t:it("moves the average quality of hot items out of the clean sum", function()
				-- 4 items, average quality 0.9, 2 of them hot.
				local data = {
					version = 1,
					harvest = { padi = { count = 4, qualitySum = 3.6, hotCount = 2 } },
				}
				PlayerData.migrate(data)
				local clean = data.produce[Produce.key("padi", "biasa", {})]
				local hot = data.produce[Produce.key("padi", "biasa", { "oplosan" })]
				expect(clean.count):toBe(2)
				expect(clean.qualitySum):toBeNear(1.8)
				expect(hot.count):toBe(2)
				expect(hot.qualitySum):toBeNear(1.8)
			end)

			t:it("keeps total quality unchanged", function()
				local data = {
					version = 1,
					harvest = { jagung = { count = 5, qualitySum = 4.0, hotCount = 3 } },
				}
				PlayerData.migrate(data)
				local clean = data.produce[Produce.key("jagung", "biasa", {})]
				local hot = data.produce[Produce.key("jagung", "biasa", { "oplosan" })]
				expect(clean.qualitySum + hot.qualitySum):toBeNear(4.0)
			end)

			t:it("gives a sack with no hot items a single clean stack", function()
				local data = { version = 1, harvest = { padi = { count = 2, qualitySum = 1.8 } } }
				PlayerData.migrate(data)
				expect(data.produce[Produce.key("padi", "biasa", {})].count):toBe(2)
				expect(data.produce[Produce.key("padi", "biasa", { "oplosan" })]):toBeNil()
			end)

			t:it("does not divide by zero on an empty sack", function()
				local data = { version = 1, harvest = { padi = { count = 0, qualitySum = 0, hotCount = 0 } } }
				PlayerData.migrate(data)
				expect(next(data.produce)):toBeNil()
			end)

			t:it("skips malformed sack entries instead of crashing", function()
				local data = { version = 1, harvest = { padi = "broken" } }
				PlayerData.migrate(data)
				expect(data.version):toBe(3)
				expect(next(data.produce)):toBeNil()
			end)
		end)

		t:describe("v2 -> v3 produce", function()
			t:it("turns a v2 clean/hot sack into two stacks", function()
				local data = {
					version = 2,
					harvest = { padi = { count = 4, qualitySum = 3.6, hotCount = 1, hotQualitySum = 0.9 } },
				}
				PlayerData.migrate(data)
				local clean = data.produce[Produce.key("padi", "biasa", {})]
				local hot = data.produce[Produce.key("padi", "biasa", { "oplosan" })]
				expect(clean.count):toBe(3)
				expect(clean.qualitySum):toBeNear(3.6)
				expect(hot.count):toBe(1)
				expect(hot.qualitySum):toBeNear(0.9)
			end)

			t:it("marks hot stacks with the oplosan trait", function()
				local data = {
					version = 2,
					harvest = { padi = { count = 1, qualitySum = 0.9, hotCount = 1, hotQualitySum = 0.9 } },
				}
				PlayerData.migrate(data)
				local hot = data.produce[Produce.key("padi", "biasa", { "oplosan" })]
				expect(Produce.isHot(hot)):toBe(true)
				expect(hot.traits):toEqual({ "oplosan" })
				expect(data.produce[Produce.key("padi", "biasa", {})]):toBeNil()
			end)

			t:it("clamps a hot count larger than the total", function()
				local data = {
					version = 2,
					harvest = { padi = { count = 2, qualitySum = 1.8, hotCount = 5, hotQualitySum = 4.5 } },
				}
				PlayerData.migrate(data)
				expect(data.produce[Produce.key("padi", "biasa", {})]):toBeNil()
				expect(data.produce[Produce.key("padi", "biasa", { "oplosan" })].count):toBe(2)
			end)

			t:it("drops the old harvest table", function()
				local data = {
					version = 2,
					harvest = { padi = { count = 1, qualitySum = 0.9, hotCount = 0, hotQualitySum = 0 } },
				}
				PlayerData.migrate(data)
				expect(data.harvest):toBeNil()
			end)

			t:it("keeps several crops apart", function()
				local data = {
					version = 2,
					harvest = {
						padi = { count = 1, qualitySum = 1, hotCount = 0, hotQualitySum = 0 },
						jagung = { count = 2, qualitySum = 1.8, hotCount = 0, hotQualitySum = 0 },
					},
				}
				PlayerData.migrate(data)
				expect(Produce.count(data.produce)):toBe(3)
			end)
		end)

		t:describe("v2 -> v3 items", function()
			t:it("turns seeds into seed_<crop> items", function()
				local data = { version = 2, seeds = { padi = 4, jagung = 2 } }
				PlayerData.migrate(data)
				expect(data.items.seed_padi):toBe(4)
				expect(data.items.seed_jagung):toBe(2)
				expect(data.seeds):toBeNil()
			end)

			t:it("moves inventory consumables into items", function()
				local data = { version = 2, inventory = { amplopPremium = 2, jaminanKilat = 1 } }
				PlayerData.migrate(data)
				expect(data.items.amplopPremium):toBe(2)
				expect(data.items.jaminanKilat):toBe(1)
				expect(data.inventory):toBeNil()
			end)

			t:it("ignores the v3 TEMPLATE defaults Reconcile injects before migration", function()
				-- ProfileStore:Reconcile() adds `items` (starting seeds included) to an old
				-- profile before migrate() runs; those defaults must not stack on top.
				local data = {
					version = 2,
					items = { seed_padi = 5, amplopPremium = 0, jaminanKilat = 0 },
					seeds = { padi = 4 },
					inventory = { amplopPremium = 2 },
				}
				PlayerData.migrate(data)
				expect(data.items.seed_padi):toBe(4)
				expect(data.items.amplopPremium):toBe(2)
				expect(data.items.jaminanKilat):toBe(0)
			end)

			t:it("ignores non-numeric amounts", function()
				local data = { version = 2, seeds = { padi = "banyak" }, inventory = { amplopPremium = -3 } }
				PlayerData.migrate(data)
				expect(data.items.seed_padi):toBe(0)
				expect(data.items.amplopPremium):toBe(0)
			end)
		end)

		t:describe("v3 section defaults", function()
			t:it("fills every section a new release reads", function()
				local data = { version = 2 }
				PlayerData.migrate(data)
				expect(type(data.produce)):toBe("table")
				expect(type(data.items)):toBe("table")
				expect(type(data.tools)):toBe("table")
				expect(type(data.gudang)):toBe("table")
				expect(type(data.gudang.stacks)):toBe("table")
				expect(type(data.debt)):toBe("table")
				expect(type(data.quests)):toBe("table")
				expect(type(data.almanak)):toBe("table")
				expect(type(data.story)):toBe("table")
				expect(type(data.housing)):toBe("table")
				expect(type(data.prestige)):toBe("table")
			end)

			t:it("gives the gudang the configured base capacity", function()
				local data = { version = 2 }
				PlayerData.migrate(data)
				expect(data.gudang.capacity):toBe(Game.gudangBaseCapacity)
			end)

			t:it("repairs a malformed gudang without dropping its stacks", function()
				local data = { version = 2, gudang = { capacity = "big", stacks = "nope" } }
				PlayerData.migrate(data)
				expect(data.gudang.capacity):toBe(Game.gudangBaseCapacity)
				expect(type(data.gudang.stacks)):toBe("table")
			end)

			t:it("does not reset a valid gudang capacity", function()
				local data = { version = 2, gudang = { capacity = 120, stacks = {} } }
				PlayerData.migrate(data)
				expect(data.gudang.capacity):toBe(120)
			end)

			t:it("keeps the reserved housing and prestige tables", function()
				local data = { version = 2, housing = { level = 2 }, prestige = { level = 1 } }
				PlayerData.migrate(data)
				expect(data.housing.level):toBe(2)
				expect(data.prestige.level):toBe(1)
			end)

			t:it("does not touch gameplay scalars", function()
				local data = { version = 2, cash = 1234, rank = "juragan", sus = 40 }
				PlayerData.migrate(data)
				expect(data.cash):toBe(1234)
				expect(data.rank):toBe("juragan")
				expect(data.sus):toBe(40)
			end)
		end)
	end)
end
