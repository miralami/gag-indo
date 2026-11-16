--!nocheck
-- Counts must be finite and positive. NaN, infinity and negative counts are corrupt data and
-- count as nothing, in Produce.count and in overdue gudang seizure.

return function(t, Env, Fakes)
	local expect = t.expect

	local BAD = { 0 / 0, math.huge, -math.huge, -5, "3" }

	t:describe("Produce count guards (T5 prep)", function()
		t:it("Produce.count ignores NaN, infinite, negative and non-number counts", function()
			local env = Env.new()
			local Produce = env:require("shared/Produce")
			local sack = {
				good = { crop = "padi", tier = "biasa", traits = {}, count = 4 },
			}
			for i, bad in BAD do
				sack["bad" .. i] = { crop = "padi", tier = "biasa", traits = {}, count = bad }
			end
			expect(Produce.count(sack)):toBe(4)
		end)

		t:it("Produce.removeClean and removeHot report only finite positive counts", function()
			local env = Env.new()
			local Produce = env:require("shared/Produce")
			local sack = {
				good = { crop = "padi", tier = "biasa", traits = {}, count = 2 },
				nan = { crop = "padi", tier = "biasa", traits = {}, count = 0 / 0 },
			}
			expect(Produce.removeClean(sack)):toBe(2)
			expect(sack.nan ~= nil):toBe(true)
		end)

		t:it("overdue seizure takes nothing from NaN, infinite or negative stacks", function()
			local env = Env.new()
			local playerData = Fakes.playerData()
			env:mock("shared/Remotes", Fakes.remotes(env))
			env:mock("server/Data/PlayerData", playerData)
			env:mock("server/Net/Notify", Fakes.notify())
			env:mock("server/Net/RateLimit", Fakes.rateLimit(true))
			env:mock("server/Net/State", { touch = function() end })
			env:mock("server/World/Village", {
				getPosition = function() return env.Vector3.new(0, 0, 0) end,
				onPasar = function() end,
			})
			env:require("server/Economy/EconomyService").start()
			local DebtService = env:require("server/Economy/DebtService")
			DebtService.bindCollector({ summon = function() end, dismiss = function() end })
			local player = Fakes.player(env)
			local data = playerData.set(player, Fakes.newData(env))
			data.cash = 1000
			DebtService.borrow(player, 400)
			data.debt.dueAt = env.wallTime - 100000
			data.debt.stage = 3
			local owed = data.debt.owed
			data.gudang = {
				capacity = 100,
				stacks = {
					nan = { crop = "padi", count = 0 / 0, tier = "biasa", traits = {} },
					inf = { crop = "padi", count = math.huge, tier = "biasa", traits = {} },
					neg = { crop = "padi", count = -5, tier = "biasa", traits = {} },
				},
			}
			DebtService.tick(player)
			expect(data.debt.owed):toBe(owed)
			expect(data.gudang.stacks.nan ~= nil):toBe(true)
			expect(data.gudang.stacks.neg ~= nil):toBe(true)
		end)
	end)
end
