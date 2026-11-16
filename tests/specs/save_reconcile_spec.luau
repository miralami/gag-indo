--!nocheck
-- Load-path save repair: PlayerData.sanitize runs after Reconcile + migrate.

return function(t, Env)
	local expect = t.expect
	local env, PlayerData

	local function fresh()
		local copy = function(v)
			local function deep(x)
				if type(x) ~= "table" then
					return x
				end
				local c = {}
				for k, val in x do
					c[k] = deep(val)
				end
				return c
			end
			return deep(v)
		end
		return copy(PlayerData.TEMPLATE)
	end

	local function has(list, path)
		return table.find(list, path) ~= nil
	end

	t:describe("PlayerData.sanitize", function()
		t:beforeEach(function()
			env = Env.new()
			env:mock("server/Packages/ProfileStore", {
				New = function()
					return {}
				end,
			})
			PlayerData = env:require("server/Data/PlayerData")
		end)

		t:it("leaves a clean template-shaped save untouched", function()
			local data = fresh()
			data.cash = -500 -- debt: negative cash is legitimate
			data.cooldowns["steal_123"] = 42
			local before = fresh()
			before.cash = -500
			before.cooldowns["steal_123"] = 42
			local repaired = PlayerData.sanitize(data)
			expect(#repaired):toBe(0)
			expect(data.cash):toBe(-500)
			expect(data.stats.raids):toBe(before.stats.raids)
			expect(data.cooldowns["steal_123"]):toBe(42)
			expect(data.namaBaik):toBe(before.namaBaik)
		end)

		t:it("replaces wrong-typed top-level fields with a fresh default", function()
			local data = fresh()
			data.cooldowns = "oops"
			data.stats = 5
			data.tiles = false
			data.rank = 7
			data.worker = nil
			local repaired = PlayerData.sanitize(data)
			expect(type(data.cooldowns)):toBe("table")
			expect(type(data.stats)):toBe("table")
			expect(data.stats.raids):toBe(0)
			expect(type(data.tiles)):toBe("table")
			expect(data.rank):toBe("gurem")
			expect(data.worker.hiredUntil):toBe(0)
			expect(has(repaired, "cooldowns")):toBe(true)
			expect(has(repaired, "stats")):toBe(true)
			expect(has(repaired, "tiles")):toBe(true)
			expect(has(repaired, "rank")):toBe(true)
			expect(has(repaired, "worker")):toBe(true)
		end)

		t:it("gives replaced tables their own copy, not the shared template", function()
			local data = fresh()
			data.stats = "bad"
			PlayerData.sanitize(data)
			data.stats.raids = 99
			expect(PlayerData.TEMPLATE.stats.raids):toBe(0)
		end)

		t:it("resets NaN and infinite top-level numbers to the template default", function()
			local data = fresh()
			data.cash = 0 / 0
			data.namaBaik = 0 / 0
			data.sus = math.huge
			data.lifetimeEarned = -math.huge
			local repaired = PlayerData.sanitize(data)
			expect(data.cash):toBe(PlayerData.TEMPLATE.cash)
			expect(data.namaBaik):toBe(PlayerData.TEMPLATE.namaBaik)
			expect(data.sus):toBe(0)
			expect(data.lifetimeEarned):toBe(0)
			expect(#repaired):toBe(4)
		end)

		t:it("leaves negative cash alone", function()
			local data = fresh()
			data.cash = -1234
			local repaired = PlayerData.sanitize(data)
			expect(data.cash):toBe(-1234)
			expect(has(repaired, "cash")):toBe(false)
		end)

		t:it("repairs nested template fields and keeps unknown keys", function()
			local data = fresh()
			data.stats.raids = 0 / 0
			data.stats.cheats = "many"
			data.quests.loginStreak = math.huge
			data.worker.hiredUntil = 0 / 0
			data.gudang.capacity = 0 / 0
			data.cooldowns["steal_123"] = 7
			data.cooldowns["nbDay_9"] = 0 / 0 -- unknown key: never touched
			data.cooldowns.extra = "x"
			data.tiles.t1 = { crop = "padi" }
			local repaired = PlayerData.sanitize(data)
			expect(data.stats.raids):toBe(0)
			expect(data.stats.cheats):toBe(0)
			expect(data.quests.loginStreak):toBe(0)
			expect(data.worker.hiredUntil):toBe(0)
			expect(data.gudang.capacity):toBe(PlayerData.TEMPLATE.gudang.capacity)
			expect(has(repaired, "stats.raids")):toBe(true)
			expect(has(repaired, "quests.loginStreak")):toBe(true)
			expect(has(repaired, "gudang.capacity")):toBe(true)
			expect(data.cooldowns["steal_123"]):toBe(7)
			expect(data.cooldowns.extra):toBe("x")
			expect(data.cooldowns["nbDay_9"] ~= data.cooldowns["nbDay_9"]):toBe(true)
			expect(data.tiles.t1.crop):toBe("padi")
		end)

		t:it("is idempotent", function()
			local data = fresh()
			data.cash = 0 / 0
			data.stats = "x"
			data.quests.loginStreak = math.huge
			data.worker = 3
			local first = PlayerData.sanitize(data)
			expect(#first > 0):toBe(true)
			local second = PlayerData.sanitize(data)
			expect(#second):toBe(0)
		end)

		t:it("returns repaired paths without touching a non-table save", function()
			expect(#PlayerData.sanitize(nil)):toBe(0)
		end)

		t:it("does not overwrite migrated v2 data", function()
			local data = {
				version = 2,
				cash = 321,
				inventory = { amplopPremium = 3 },
				seeds = { padi = 4 },
				harvest = {},
			}
			PlayerData.migrate(data)
			-- Reconcile would have filled the rest of the template; do it by hand.
			local template = fresh()
			for k, v in template do
				if data[k] == nil then
					data[k] = v
				end
			end
			local repaired = PlayerData.sanitize(data)
			expect(#repaired):toBe(0)
			expect(data.cash):toBe(321)
			expect(data.items.amplopPremium):toBe(3)
			expect(data.items.seed_padi):toBe(4)
		end)
	end)
end
