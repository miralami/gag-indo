--!nocheck
-- ToolService and Items failure-path specs. A refused buy or use never spends cash, never
-- changes tools or items, never adds Sus and never sets a cooldown; a consumable is consumed
-- exactly once and its effect applied once; a damaged save or a rate-limited call never errors.
-- Tests whose name starts with "[BUG]" are expected to fail: they reveal real defects (see the
-- report that accompanies this spec). Do not edit ToolService or Items to make them pass here.
-- EconomyService.trySpend is mocked with the same guards as the real function
-- (EconomyService.luau lines 106-118), so the NaN-cash test reflects the real guard.

return function(t, Env, Fakes)
	local expect = t.expect

	local function isFinite(n)
		return type(n) == "number" and n == n and n > -math.huge and n < math.huge
	end

	-- Runs fn and reports whether it threw; a refused call must never throw.
	local function throws(fn)
		local ok = pcall(fn)
		return not ok
	end

	-- ---------------------------------------------------------------------------
	-- ToolService
	-- ---------------------------------------------------------------------------

	local function makeTools(options)
		options = options or {}
		local env = Env.new()
		local Game = env:require("shared/Config/Game")
		local playerData = Fakes.playerData()
		local notify = Fakes.notify()
		local rateLimit = Fakes.rateLimit(options.allow ~= false)
		local remotes = Fakes.remotes(env)
		local state = { touched = {} }

		env:mock("shared/Remotes", remotes)
		env:mock("server/Data/PlayerData", playerData)
		env:mock("server/Net/Notify", notify)
		env:mock("server/Net/RateLimit", rateLimit)
		env:mock("server/Net/State", {
			touch = function(_, section)
				table.insert(state.touched, section)
			end,
		})
		env:mock("server/Season/SeasonService", {
			growSeconds = function(base)
				return base
			end,
		})
		env:mock("server/Economy/EconomyService", {
			hasRank = function(data, rank)
				return (Game.rankIndex[data.rank] or 1) >= (Game.rankIndex[rank] or 1)
			end,
			trySpend = function(player, amount)
				local data = playerData.get(player)
				if not data or not isFinite(amount) or amount < 0 then
					return false
				end
				amount = math.floor(amount)
				if not isFinite(data.cash) or data.cash < amount then
					notify.send(player, "n_not_enough_cash")
					return false
				end
				data.cash -= amount
				return true
			end,
		})

		local ToolService = env:require("server/Farm/ToolService")
		ToolService.start()

		local player = Fakes.player(env)
		local data = playerData.set(player, Fakes.newData(env))
		data.cash = options.cash or 2000

		return {
			env = env,
			Game = Game,
			ToolService = ToolService,
			player = player,
			data = data,
			playerData = playerData,
			notify = notify,
			rateLimit = rateLimit,
			state = state,
			remotes = remotes,
			fire = function(...)
				remotes.Tool_Buy.OnServerEvent:Fire(...)
			end,
		}
	end

	t:describe("ToolService failure paths", function()
		t:it("bad remote arguments and unknown line ids change nothing", function()
			local fx = makeTools()
			for _, bad in { nil, 42, {}, true, "", "nope", "__index" } do
				expect(throws(function()
					fx.fire(fx.player, bad)
				end)):toBe(false)
			end
			expect(fx.data.cash):toBe(2000)
			expect(fx.data.tools.cangkul):toBeNil()
			expect(#fx.state.touched):toBe(0)
			expect(fx.player:GetAttribute("Tool_cangkul")):toBeNil()
		end)

		t:it("buys at exactly the tier cost and refuses one coin short", function()
			local fx = makeTools({ cash = 59 })
			expect(fx.ToolService.buy(fx.player, "cangkul")):toBe(false)
			expect(fx.data.cash):toBe(59)
			expect(fx.data.tools.cangkul):toBeNil()

			fx.data.cash = 60
			expect(fx.ToolService.buy(fx.player, "cangkul")):toBe(true)
			expect(fx.data.cash):toBe(0)
			expect(fx.data.tools.cangkul):toBe("bambu")
		end)

		t:it("replaces a tier id from a removed config and applies the new effect once", function()
			local fx = makeTools()
			fx.data.tools.cangkul = "dariMasaDepan"
			expect(fx.ToolService.buy(fx.player, "cangkul")):toBe(true)
			expect(fx.data.tools.cangkul):toBe("bambu")
			expect(fx.data.cash):toBe(2000 - 60)

			expect(fx.ToolService.buy(fx.player, "cangkul")):toBe(true)
			expect(fx.data.tools.cangkul):toBe("baja")
			expect(fx.data.cash):toBe(2000 - 60 - 350)
			-- Two purchases of one line never stack: the bonus is the top tier's, once.
			expect(fx.ToolService.plantBonus(fx.data)):toBeNear(0.12)
		end)

		t:it("a rate-limited buy changes nothing and publishes nothing", function()
			local fx = makeTools({ allow = false })
			expect(fx.ToolService.buy(fx.player, "cangkul")):toBe(false)
			expect(fx.data.cash):toBe(2000)
			expect(fx.data.tools.cangkul):toBeNil()
			expect(fx.player:GetAttribute("Tool_cangkul")):toBeNil()
			expect(#fx.state.touched):toBe(0)
			expect(fx.rateLimit.calls[1]):toBe("Tool_Buy")
		end)

		t:it("a missing save refuses cleanly and a nil tools table is created on buy", function()
			local fx = makeTools()
			local stranger = Fakes.player(fx.env)
			expect(throws(function()
				fx.ToolService.buy(stranger, "cangkul")
			end)):toBe(false)
			expect(fx.ToolService.buy(stranger, "cangkul")):toBe(false)

			fx.data.tools = nil
			expect(throws(function()
				fx.ToolService.buy(fx.player, "cangkul")
			end)):toBe(false)
			expect(fx.data.tools.cangkul):toBe("bambu")
		end)

		t:it("a non-table tools field in a damaged save does not throw on buy", function()
			-- Throws at ToolService.luau:80 (nextTier: `(data.tools or {})[lineId]` indexes a number),
			-- reached from buy at line 108 before any spend. Expected: no throw.
			local fx = makeTools()
			fx.data.tools = 5
			expect(throws(function()
				fx.ToolService.buy(fx.player, "cangkul")
			end)):toBe(false)
		end)

		t:it("never buys with NaN or negative cash and never publishes a refused buy", function()
			local fx = makeTools({ cash = 0 / 0 })
			expect(fx.ToolService.buy(fx.player, "cangkul")):toBe(false)
			expect(fx.data.cash ~= fx.data.cash):toBe(true)
			expect(fx.data.tools.cangkul):toBeNil()

			fx.data.cash = -5
			expect(fx.ToolService.buy(fx.player, "cangkul")):toBe(false)
			expect(fx.data.cash):toBe(-5)
			expect(fx.player:GetAttribute("Tool_cangkul")):toBeNil()
			expect(#fx.state.touched):toBe(0)
		end)

		t:it("damaged tier values read as no bonus instead of throwing", function()
			local fx = makeTools()
			fx.data.tools.cangkul = {}
			fx.data.tools.gembor = 99
			fx.data.tools.karung = "besar junk"
			expect(throws(function()
				fx.ToolService.plantBonus(fx.data)
				fx.ToolService.growMultiplier(fx.data)
				fx.ToolService.sackCapacity(fx.data)
				fx.ToolService.growSeconds(100, "palawija", fx.data)
			end)):toBe(false)
			expect(fx.ToolService.plantBonus(fx.data)):toBe(0)
			expect(fx.ToolService.growMultiplier(fx.data)):toBe(1)
			expect(fx.ToolService.sackCapacity(fx.data)):toBe(fx.Game.sackBaseCapacity)
		end)
	end)

	-- ---------------------------------------------------------------------------
	-- Items
	-- ---------------------------------------------------------------------------

	local function makeItems(options)
		options = options or {}
		local env = Env.new()
		local Law = env:require("shared/Config/Law")
		local playerData = Fakes.playerData()
		local notify = Fakes.notify()
		local rateLimit = Fakes.rateLimit(options.allow ~= false)
		local remotes = Fakes.remotes(env)
		local state = { touched = {} }
		local fx = {
			sus = { added = {} },
			syncs = 0,
			raid = { busy = options.busy == true, inJail = options.inJail == true, releases = 0 },
		}

		env:mock("shared/Remotes", remotes)
		env:mock("server/Data/PlayerData", playerData)
		env:mock("server/Net/Notify", notify)
		env:mock("server/Net/RateLimit", rateLimit)
		env:mock("server/Net/State", {
			touch = function(_, section)
				table.insert(state.touched, section)
			end,
		})
		env:mock("server/Economy/EconomyService", {
			sync = function()
				fx.syncs += 1
			end,
		})
		env:mock("server/Law/SusService", {
			add = function(player, amount, reason)
				table.insert(fx.sus.added, { player = player, amount = amount, reason = reason })
			end,
		})
		env:mock("server/Law/RaidService", {
			isBusy = function()
				return fx.raid.busy
			end,
			releaseFromJail = function()
				fx.raid.releases += 1
				if fx.raid.inJail then
					fx.raid.inJail = false
					return true
				end
				return false
			end,
		})

		local Items = env:require("server/Monetization/Items")
		Items.start()

		local player = Fakes.player(env)
		local data = playerData.set(player, Fakes.newData(env))
		data.items.amplopPremium = options.amplop or 0
		data.items.jaminanKilat = options.jaminan or 0

		fx.env = env
		fx.Law = Law
		fx.player = player
		fx.data = data
		fx.playerData = playerData
		fx.notify = notify
		fx.rateLimit = rateLimit
		fx.state = state
		fx.remotes = remotes
		fx.fire = function(...)
			remotes.Item_Use.OnServerEvent:Fire(...)
		end
		return fx
	end

	t:describe("Items failure paths", function()
		t:it("bad remote arguments and unknown item ids change nothing", function()
			local fx = makeItems({ amplop = 1, jaminan = 1 })
			fx.data.items.seed_padi = 3
			for _, bad in { nil, 42, {}, true, "", "AMPLOPPREMIUM", "amplopPremium ", "seed_padi", "bogus" } do
				expect(throws(function()
					fx.fire(fx.player, bad)
				end)):toBe(false)
			end
			expect(fx.data.items.amplopPremium):toBe(1)
			expect(fx.data.items.jaminanKilat):toBe(1)
			expect(fx.data.items.seed_padi):toBe(3)
			expect(#fx.sus.added):toBe(0)
			expect(fx.syncs):toBe(0)
			expect(fx.data.cooldowns.amplopPremiumReadyAt):toBeNil()
		end)

		t:it("using a consumable you do not own notifies and changes nothing", function()
			local fx = makeItems({ amplop = 0, jaminan = 0 })
			fx.fire(fx.player, "amplopPremium")
			fx.fire(fx.player, "jaminanKilat")
			expect(fx.notify.keys(fx.player)):toContain("n_item_none")
			expect(#fx.sus.added):toBe(0)
			expect(fx.raid.releases):toBe(0)
			expect(fx.syncs):toBe(0)
			expect(fx.data.cooldowns.amplopPremiumReadyAt):toBeNil()
		end)

		t:it("jaminanKilat outside a raid is refused and the item is kept", function()
			local fx = makeItems({ jaminan = 1 })
			fx.fire(fx.player, "jaminanKilat")
			expect(fx.raid.releases):toBe(1)
			expect(fx.data.items.jaminanKilat):toBe(1)
			expect(fx.notify.keys(fx.player)):toContain("n_item_blocked")
			expect(fx.syncs):toBe(0)
			expect(#fx.state.touched):toBe(0)
		end)

		t:it("jaminanKilat in jail is consumed exactly once and frees the player once", function()
			local fx = makeItems({ jaminan = 2, inJail = true })
			fx.fire(fx.player, "jaminanKilat")
			expect(fx.data.items.jaminanKilat):toBe(1)
			expect(fx.syncs):toBe(1)
			expect(fx.notify.keys(fx.player)):toContain("n_item_used")

			-- Second press: no longer in jail, so the release is refused and nothing is spent.
			fx.fire(fx.player, "jaminanKilat")
			expect(fx.data.items.jaminanKilat):toBe(1)
			expect(fx.raid.releases):toBe(2)
			expect(fx.syncs):toBe(1)
		end)

		t:it("amplopPremium while a raid is busy is refused with no Sus or cooldown", function()
			local fx = makeItems({ amplop = 1, busy = true })
			fx.fire(fx.player, "amplopPremium")
			expect(fx.data.items.amplopPremium):toBe(1)
			expect(#fx.sus.added):toBe(0)
			expect(fx.data.cooldowns.amplopPremiumReadyAt):toBeNil()
			expect(fx.notify.keys(fx.player)):toContain("n_item_blocked")
		end)

		t:it("amplopPremium is consumed once, lowers Sus once and respects its cooldown", function()
			local fx = makeItems({ amplop = 2 })
			fx.fire(fx.player, "amplopPremium")
			expect(fx.data.items.amplopPremium):toBe(1)
			expect(#fx.sus.added):toBe(1)
			expect(fx.sus.added[1].amount):toBe(fx.Law.amplopPremiumSus)
			expect(fx.data.cooldowns.amplopPremiumReadyAt):toBe(fx.env.wallTime + fx.Law.amplopPremiumCooldown)

			fx.fire(fx.player, "amplopPremium")
			expect(fx.data.items.amplopPremium):toBe(1)
			expect(#fx.sus.added):toBe(1)
			expect(fx.notify.keys(fx.player)):toContain("n_item_cooldown")

			fx.env:advance(fx.Law.amplopPremiumCooldown)
			fx.fire(fx.player, "amplopPremium")
			expect(fx.data.items.amplopPremium):toBe(0)
			expect(#fx.sus.added):toBe(2)
		end)

		t:it("a rate-limited use changes nothing", function()
			local fx = makeItems({ amplop = 1, jaminan = 1, allow = false })
			fx.fire(fx.player, "amplopPremium")
			fx.fire(fx.player, "jaminanKilat")
			expect(fx.data.items.amplopPremium):toBe(1)
			expect(fx.data.items.jaminanKilat):toBe(1)
			expect(#fx.sus.added):toBe(0)
			expect(fx.raid.releases):toBe(0)
			expect(fx.rateLimit.calls[1]):toBe("Item_Use")
		end)

		t:it("a missing save or damaged items field never throws", function()
			local fx = makeItems({ amplop = 1 })
			local stranger = Fakes.player(fx.env)
			expect(throws(function()
				fx.fire(stranger, "amplopPremium")
			end)):toBe(false)

			fx.data.items = nil
			expect(throws(function()
				fx.fire(fx.player, "amplopPremium")
			end)):toBe(false)
			expect(#fx.sus.added):toBe(0)

			fx.data.items = "junk"
			expect(throws(function()
				fx.fire(fx.player, "jaminanKilat")
			end)):toBe(false)
			expect(fx.raid.releases):toBe(0)
		end)

		t:it("a NaN consumable count is refused, not used, and cash is never touched", function()
			-- Items.luau:20 `Inventory.get(...) < 1` is false for NaN, so the use goes through;
			-- Inventory.take (shared/Inventory.luau `have < whole`) is also false, so it "succeeds".
			local fx = makeItems({})
			fx.data.items.amplopPremium = 0 / 0
			fx.data.cash = 500
			fx.fire(fx.player, "amplopPremium")
			expect(#fx.sus.added):toBe(0)
			expect(fx.data.cash):toBe(500)
			expect(fx.data.items.amplopPremium ~= fx.data.items.amplopPremium):toBe(true)
		end)
	end)
end
