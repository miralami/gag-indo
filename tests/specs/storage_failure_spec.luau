--!nocheck
-- StorageService failure-path specs (gudang). Refused moves change nothing, a bad or damaged
-- stack is never moved, deleted or duplicated, and a damaged save never errors.
-- Happy-path behaviour lives in storage_spec.luau.
-- Tests whose name starts with "[BUG]" are expected to fail: they reveal real defects in
-- StorageService.luau (see the report that accompanies this spec). Do not edit StorageService
-- to make them pass in this file.

return function(t, Env, Fakes)
	local expect = t.expect
	local currentProduce

	local function makeStorage(options)
		options = options or {}
		local env = Env.new()
		local Game = env:require("shared/Config/Game")
		local Produce = env:require("shared/Produce")
		currentProduce = Produce

		local playerData = Fakes.playerData()
		local notify = Fakes.notify()
		local rateLimit = Fakes.rateLimit(options.allow ~= false)
		local remotes = Fakes.remotes(env)

		env:mock("shared/Remotes", remotes)
		env:mock("server/Data/PlayerData", playerData)
		env:mock("server/Net/Notify", notify)
		env:mock("server/Net/RateLimit", rateLimit)
		env:mock("server/Economy/EconomyService", {
			sync = function() end,
		})

		local StorageService = env:require("server/Farm/StorageService")
		local player = Fakes.player(env)
		local data = playerData.set(player, Fakes.newData(env))

		return {
			env = env,
			Game = Game,
			Produce = Produce,
			StorageService = StorageService,
			playerData = playerData,
			notify = notify,
			rateLimit = rateLimit,
			remotes = remotes,
			player = player,
			data = data,
		}
	end

	local function addStack(sack, cropId, count, quality, traits)
		local Produce = currentProduce
		for _ = 1, count do
			Produce.add(sack, cropId, quality, { traits = traits })
		end
	end

	t:describe("Storage failure paths", function()
		t:it("a remote call with junk arguments only runs the rate-limited deposit", function()
			local fx = makeStorage()
			fx.StorageService.start()
			addStack(fx.data.produce, "padi", 2, 1)
			fx.remotes.Storage_Deposit.OnServerEvent:Fire(fx.player, "junk", { count = 1e9 }, 0 / 0)
			expect(fx.Produce.count(fx.data.gudang.stacks)):toBe(2)
			expect(fx.Produce.count(fx.data.produce)):toBe(0)
			expect(#fx.rateLimit.calls):toBe(1)
			expect(fx.rateLimit.calls[1]):toBe("Storage_Deposit")
		end)

		t:it("rate-limited deposit and withdraw requests change nothing", function()
			local fx = makeStorage({ allow = false })
			fx.StorageService.start()
			addStack(fx.data.produce, "padi", 3, 1)
			addStack(fx.data.gudang.stacks, "jagung", 2, 1)
			fx.remotes.Storage_Deposit.OnServerEvent:Fire(fx.player)
			fx.remotes.Storage_Withdraw.OnServerEvent:Fire(fx.player)
			expect(fx.Produce.count(fx.data.produce)):toBe(3)
			expect(fx.Produce.count(fx.data.gudang.stacks)):toBe(2)
			expect(#fx.notify.sent):toBe(0)
			expect(#fx.rateLimit.calls):toBe(2)
		end)

		t:it("moves nothing and reports nothing for a player with no save", function()
			local fx = makeStorage()
			local ghost = Fakes.player(fx.env)
			expect(fx.StorageService.depositAll(ghost)):toBe(0)
			expect(fx.StorageService.withdrawAll(ghost)):toBe(0)
			expect(#fx.notify.sent):toBe(0)
		end)

		t:it("a removed pass keeps stored items and refuses new deposits over the base capacity", function()
			local fx = makeStorage()
			fx.data.gudang.capacity = 60
			addStack(fx.data.gudang.stacks, "padi", 60, 1)
			addStack(fx.data.produce, "padi", 5, 1)
			expect(fx.StorageService.capacity(fx.player, fx.data)):toBe(60)
			expect(fx.StorageService.depositAll(fx.player)):toBe(0)
			expect(fx.Produce.count(fx.data.gudang.stacks)):toBe(60)
			expect(fx.Produce.count(fx.data.produce)):toBe(5)
			expect(fx.notify.keys(fx.player)[1]):toBe("n_gudang_full")
		end)

		t:it("NaN and negative stack counts are never moved, deleted or counted", function()
			local fx = makeStorage()
			local Produce = fx.Produce
			local sack = fx.data.produce
			sack[Produce.key("bayam", "biasa", {})] = {
				crop = "bayam", tier = "biasa", traits = {}, count = 0 / 0, qualitySum = 0,
			}
			sack[Produce.key("cabai", "biasa", {})] = {
				crop = "cabai", tier = "biasa", traits = {}, count = -3, qualitySum = -3,
			}
			addStack(sack, "padi", 2, 1)

			expect(fx.StorageService.depositAll(fx.player)):toBe(2)
			expect(Produce.count(fx.data.gudang.stacks)):toBe(2)
			expect(sack[Produce.key("bayam", "biasa", {})] ~= nil):toBe(true)
			expect(sack[Produce.key("cabai", "biasa", {})].count):toBe(-3)
			expect(fx.StorageService.used(fx.data)):toBe(2)
		end)

		t:it("an infinite stack count moves only the free space", function()
			local fx = makeStorage()
			local Produce = fx.Produce
			fx.data.produce[Produce.key("padi", "biasa", {})] = {
				crop = "padi", tier = "biasa", traits = {}, count = math.huge, qualitySum = 0,
			}
			expect(fx.StorageService.depositAll(fx.player)):toBe(fx.Game.gudangBaseCapacity)
			expect(Produce.count(fx.data.gudang.stacks)):toBe(fx.Game.gudangBaseCapacity)
			expect(fx.StorageService.used(fx.data)):toBe(fx.Game.gudangBaseCapacity)
		end)

		t:it("a fractional capacity lets a half item into the gudang", function()
			-- StorageService.lua line 139: amount = math.min(stack.count, free) with free = 40.5
			-- moves 40.5 items, so a whole item is split across the sack and the gudang.
			local fx = makeStorage()
			fx.data.gudang.capacity = 40.5
			addStack(fx.data.produce, "padi", 50, 1)
			local moved = fx.StorageService.depositAll(fx.player)
			expect(moved % 1):toBe(0)
		end)

		t:it("a corrupt infinite capacity in the save makes the gudang unlimited", function()
			-- StorageService.lua line 56-59: math.max(base, math.huge) returns math.huge, so
			-- capacity() reports an unlimited gudang instead of falling back to the base.
			local fx = makeStorage()
			fx.data.gudang.capacity = math.huge
			local capacity = fx.StorageService.capacity(fx.player, fx.data)
			expect(capacity < math.huge):toBe(true)
		end)

		t:it("a NaN or negative capacity in the save falls back to the base capacity", function()
			local fx = makeStorage()
			fx.data.gudang.capacity = 0 / 0
			expect(fx.StorageService.capacity(fx.player, fx.data)):toBe(fx.Game.gudangBaseCapacity)
			fx.data.gudang.capacity = -10
			expect(fx.StorageService.capacity(fx.player, fx.data)):toBe(fx.Game.gudangBaseCapacity)
		end)

		t:it("a save missing the gudang or its stacks is repaired and never errors", function()
			local fx = makeStorage()
			addStack(fx.data.produce, "padi", 2, 1)
			fx.data.gudang = nil
			local ok, moved = pcall(fx.StorageService.depositAll, fx.player)
			expect(ok):toBe(true)
			expect(moved):toBe(2)

			expect(fx.Produce.count(fx.data.produce)):toBe(0)

			fx.data.gudang = { capacity = 40 }
			local okWithdraw, back = pcall(fx.StorageService.withdrawAll, fx.player)
			expect(okWithdraw):toBe(true)
			expect(back):toBe(0)
			expect(fx.Produce.count(fx.data.produce)):toBe(0)
		end)

		t:it("withdrawing with a save missing the sack table loses the items", function()
			-- StorageService.lua line 165: `local sack = data.produce or {}` builds a detached
			-- table when the save has no produce table, so the withdrawn items vanish.
			local fx = makeStorage()
			fx.data.produce = nil
			addStack(fx.data.gudang.stacks, "padi", 3, 1)
			fx.StorageService.withdrawAll(fx.player)
			expect(fx.Produce.count(fx.data.produce or {})):toBe(3)
		end)

		t:it("store then withdraw keeps every clean item, keeps hot items put and never duplicates a stack", function()
			local fx = makeStorage()
			local Produce = fx.Produce
			local sack = fx.data.produce
			addStack(sack, "padi", 3, 0.8)
			addStack(sack, "jagung", 4, 1)
			addStack(sack, "padi", 2, 1, { "oplosan" })
			local keysBefore = 0
			for _ in sack do
				keysBefore += 1
			end

			expect(fx.StorageService.depositAll(fx.player)):toBe(7)
			expect(Produce.count(fx.data.produce) + Produce.count(fx.data.gudang.stacks)):toBe(9)
			for key in fx.data.gudang.stacks do
				expect(Produce.isHot(fx.data.gudang.stacks[key])):toBe(false)
			end

			expect(fx.StorageService.withdrawAll(fx.player)):toBe(7)
			expect(Produce.count(fx.data.produce)):toBe(9)
			expect(Produce.count(fx.data.gudang.stacks)):toBe(0)
			local keysAfter = 0
			for _ in fx.data.produce do
				keysAfter += 1
			end
			expect(keysAfter):toBe(keysBefore)
		end)

		t:it("a NaN stack in the gudang is never withdrawn or deleted", function()
			local fx = makeStorage()
			local Produce = fx.Produce
			local shed = fx.data.gudang.stacks
			shed[Produce.key("bayam", "biasa", {})] = {
				crop = "bayam", tier = "biasa", traits = {}, count = 0 / 0, qualitySum = 0,
			}
			addStack(shed, "padi", 2, 1)
			expect(fx.StorageService.withdrawAll(fx.player)):toBe(2)
			expect(shed[Produce.key("bayam", "biasa", {})] ~= nil):toBe(true)
			expect(Produce.count(fx.data.produce)):toBe(2)
		end)

		t:it("an unknown crop id moves intact through a store and withdraw round trip", function()
			local fx = makeStorage()
			addStack(fx.data.produce, "bogus", 2, 1)
			expect(fx.StorageService.depositAll(fx.player)):toBe(2)
			expect(fx.StorageService.withdrawAll(fx.player)):toBe(2)
			local _, stack = next(fx.data.produce)
			expect(stack.crop):toBe("bogus")
			expect(stack.count):toBe(2)
		end)

		-- WORK_QUEUE item 14 mutations I09 and I12. I09 drops `not gudang.stacks`, passing nil
		-- to Produce.count; I12 changes `count <= 0` to `count < 0`, leaving a zero-count stack
		-- in the source sack after the last item moves.
		t:it("used() reports zero when gudang exists but its stacks table is missing", function()
			local fx = makeStorage()
			local ok, count = pcall(fx.StorageService.used, { gudang = { capacity = 40 } })
			expect(ok):toBe(true)
			expect(count):toBe(0)
		end)

		t:it("depositAll deletes the source stack key when its last item moves", function()
			local fx = makeStorage()
			local Produce = fx.Produce
			local key = Produce.key("padi", "biasa", {})
			addStack(fx.data.produce, "padi", 1, 1)
			expect(fx.StorageService.depositAll(fx.player)):toBe(1)
			expect(fx.data.produce[key]):toBeNil()
			expect(Produce.count(fx.data.gudang.stacks)):toBe(1)
		end)
	end)
end
