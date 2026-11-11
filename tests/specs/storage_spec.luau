--!nocheck
-- Gudang storage (v2 PLAN §3.4): capacity, clean-only deposits, quality-preserving moves.

return function(t, Env, Fakes)
	local expect = t.expect
	local env, Game, Produce, StorageService
	local playerData, notify, rateLimit, player, data

	local function addStack(sack, cropId, count, quality, traits)
		for _ = 1, count do
			Produce.add(sack, cropId, quality, { traits = traits })
		end
	end

	t:describe("StorageService", function()
		t:beforeEach(function()
			env = Env.new()
			Game = env:require("shared/Config/Game")
			Produce = env:require("shared/Produce")

			playerData = Fakes.playerData()
			notify = Fakes.notify()
			rateLimit = Fakes.rateLimit(true)

			env:mock("shared/Remotes", Fakes.remotes(env))
			env:mock("server/Data/PlayerData", playerData)
			env:mock("server/Net/Notify", notify)
			env:mock("server/Net/RateLimit", rateLimit)
			env:mock("server/Economy/EconomyService", {
				sync = function() end,
			})

			StorageService = env:require("server/Farm/StorageService")
			player = Fakes.player(env)
			data = playerData.set(player, Fakes.newData(env))
		end)

		t:describe("capacity", function()
			t:it("uses the base capacity for a new player", function()
				expect(StorageService.capacity(player, data)):toBe(Game.gudangBaseCapacity)
				expect(StorageService.used(data)):toBe(0)
			end)

			t:it("lets the Gudang Besar pass raise the capacity", function()
				player:SetAttribute("Pass_GudangBesar", true)
				expect(StorageService.capacity(player, data)):toBe(Game.gudangPassCapacity)
			end)

			t:it("keeps a saved larger capacity", function()
				data.gudang.capacity = 120
				expect(StorageService.capacity(player, data)):toBe(120)
			end)
		end)

		t:describe("depositAll", function()
			t:it("moves clean produce into the gudang", function()
				addStack(data.produce, "padi", 3, 0.9)
				expect(StorageService.depositAll(player)):toBe(3)
				expect(Produce.count(data.produce)):toBe(0)
				expect(Produce.count(data.gudang.stacks)):toBe(3)
				expect(notify.keys(player)):toContain("n_gudang_deposit")
			end)

			t:it("refuses to hide hot produce", function()
				addStack(data.produce, "padi", 2, 0.9)
				addStack(data.produce, "padi", 1, 0.9, { "oplosan" })
				expect(StorageService.depositAll(player)):toBe(2)
				expect(Produce.count(data.gudang.stacks)):toBe(2)
				expect(Produce.count(data.produce)):toBe(1)
				local _, remaining = next(data.produce)
				expect(Produce.isHot(remaining)):toBe(true)
			end)

			t:it("keeps the average quality of the moved stack", function()
				addStack(data.produce, "padi", 2, 0.9)
				StorageService.depositAll(player)
				local _, stack = next(data.gudang.stacks)
				expect(stack.qualitySum):toBeNear(1.8)
			end)

			t:it("fills up to the capacity and leaves the rest in the sack", function()
				addStack(data.produce, "padi", Game.gudangBaseCapacity + 5, 1)
				expect(StorageService.depositAll(player)):toBe(Game.gudangBaseCapacity)
				expect(Produce.count(data.gudang.stacks)):toBe(Game.gudangBaseCapacity)
				expect(Produce.count(data.produce)):toBe(5)
			end)

			t:it("reports a full gudang", function()
				addStack(data.gudang.stacks, "padi", Game.gudangBaseCapacity, 1)
				addStack(data.produce, "padi", 1, 1)
				expect(StorageService.depositAll(player)):toBe(0)
				expect(notify.keys(player)):toContain("n_gudang_full")
			end)

			t:it("reports when there is nothing clean to store", function()
				addStack(data.produce, "padi", 1, 1, { "oplosan" })
				expect(StorageService.depositAll(player)):toBe(0)
				expect(notify.keys(player)):toContain("n_gudang_nothing")
			end)
		end)

		t:describe("withdrawAll", function()
			t:it("moves everything back into the sack", function()
				addStack(data.gudang.stacks, "padi", 4, 1)
				addStack(data.gudang.stacks, "jagung", 2, 1)
				expect(StorageService.withdrawAll(player)):toBe(6)
				expect(Produce.count(data.gudang.stacks)):toBe(0)
				expect(Produce.count(data.produce)):toBe(6)
				expect(notify.keys(player)):toContain("n_gudang_withdraw")
			end)

			t:it("reports an empty gudang", function()
				expect(StorageService.withdrawAll(player)):toBe(0)
				expect(notify.keys(player)):toContain("n_gudang_empty")
			end)

			t:it("round-trips produce without losing quality", function()
				addStack(data.produce, "padi", 3, 0.8)
				StorageService.depositAll(player)
				StorageService.withdrawAll(player)
				local _, stack = next(data.produce)
				expect(stack.count):toBe(3)
				expect(stack.qualitySum):toBeNear(2.4)
			end)
		end)

		t:describe("publish", function()
			t:it("mirrors the used and capacity values for the phone", function()
				addStack(data.produce, "padi", 2, 1)
				StorageService.depositAll(player)
				expect(player:GetAttribute("GudangUsed")):toBe(2)
				expect(player:GetAttribute("GudangCapacity")):toBe(Game.gudangBaseCapacity)
			end)
		end)
	end)
end
