--!nocheck
-- Game passes (v2 PLAN §3.7): benefits become server-owned attributes, and a pass still at
-- id 0 must never ask Roblox anything.

return function(t, Env, Fakes)
	local expect = t.expect
	local env, Passes, Products, playerData, notify, marketplace, player, data
	local storagePublished, workerPublished

	local GUDANG_ID = 777
	local AUTO_ID = 888

	t:describe("Passes", function()
		t:beforeEach(function()
			env = Env.new()
			playerData = Fakes.playerData()
			notify = Fakes.notify()
			storagePublished = 0
			workerPublished = 0
			marketplace = {
				ownsCalls = 0,
				PromptGamePassPurchaseFinished = env.newSignal(),
				UserOwnsGamePassAsync = function()
					marketplace.ownsCalls += 1
					return false
				end,
			}
			env.services.MarketplaceService = marketplace
			env:mock("server/Data/PlayerData", playerData)
			env:mock("server/Net/Notify", notify)
			env:mock("server/Farm/FarmService", { refresh = function() end })
			env:mock("server/Farm/StorageService", {
				publish = function()
					storagePublished += 1
				end,
			})
			env:mock("server/Farm/WorkerService", {
				publish = function()
					workerPublished += 1
				end,
			})
			env:mock("shared/Remotes", Fakes.remotes(env))

			Passes = env:require("server/Monetization/Passes")
			Products = env:require("shared/Config/Products")
			player = Fakes.player(env)
			data = playerData.set(player, Fakes.newData(env))
		end)

		t:it("never asks Roblox about a pass still at id 0", function()
			Passes.start()
			playerData.fireLoaded(player, data)
			expect(marketplace.ownsCalls):toBe(0)
			expect(Passes.has(player, "gudangBesar")):toBe(false)
			expect(Passes.has(player, "autoPanen")):toBe(false)
		end)

		t:it("turns an owned pass into an attribute on load", function()
			Products.passes.gudangBesar.id = GUDANG_ID
			marketplace.UserOwnsGamePassAsync = function(_, _, passId)
				marketplace.ownsCalls += 1
				return passId == GUDANG_ID
			end
			Passes.start()
			playerData.fireLoaded(player, data)
			expect(player:GetAttribute("Pass_GudangBesar")):toBe(true)
			expect(Passes.has(player, "gudangBesar")):toBe(true)
			expect(storagePublished):toBe(1)
			expect(workerPublished):toBe(0)
		end)

		t:it("grants auto-panen from a finished purchase and republishes the wage", function()
			Products.passes.autoPanen.id = AUTO_ID
			Passes.start()
			marketplace.PromptGamePassPurchaseFinished:Fire(player, AUTO_ID, true)
			expect(player:GetAttribute("Pass_AutoPanen")):toBe(true)
			expect(Passes.has(player, "autoPanen")):toBe(true)
			expect(workerPublished):toBe(1)
			expect(notify.keys(player)):toContain("n_purchase")
		end)

		t:it("ignores a finished purchase that was not bought", function()
			Products.passes.autoPanen.id = AUTO_ID
			Passes.start()
			marketplace.PromptGamePassPurchaseFinished:Fire(player, AUTO_ID, false)
			expect(Passes.has(player, "autoPanen")):toBe(false)
			expect(workerPublished):toBe(0)
		end)

		t:it("ignores an unknown pass id", function()
			Products.passes.autoPanen.id = AUTO_ID
			Passes.start()
			marketplace.PromptGamePassPurchaseFinished:Fire(player, 999999, true)
			expect(player:GetAttribute("Pass_AutoPanen")):toBe(nil)
			expect(#notify.keys(player)):toBe(0)
		end)
	end)
end
