--!nocheck
-- Tools (v2 PLAN §3.4): tier lookup, purchase rules and the effects FarmService applies.

return function(t, Env, Fakes)
	local expect = t.expect
	local env, Tools, ToolService, Game
	local playerData, notify, rateLimit, player, data

	t:describe("Tool config", function()
		t:beforeEach(function()
			env = Env.new()
			Tools = env:require("shared/Config/Tools")
		end)

		t:it("lists a next tier for every line and stops at the end", function()
			for _, lineId in Tools.order do
				local line = Tools.list[lineId]
				expect(#line.tiers):toBeGreaterThan(0)
				expect(Tools.next(lineId, nil)):toBe(line.tiers[1])
				expect(Tools.next(lineId, line.tiers[#line.tiers].id)):toBeNil()
			end
		end)

		t:it("resolves a tier by id and rejects unknown ids", function()
			expect(Tools.tier("cangkul", "bambu").plantBonus):toBe(0.05)
			expect(Tools.tier("cangkul", "nope")):toBeNil()
			expect(Tools.tier("nope", "bambu")):toBeNil()
		end)

		t:it("rejects unknown line ids", function()
			expect(Tools.exists("cangkul")):toBe(true)
			expect(Tools.exists("nope")):toBe(false)
			expect(Tools.exists(nil)):toBe(false)
		end)
	end)

	t:describe("ToolService", function()
		t:beforeEach(function()
			env = Env.new()
			Tools = env:require("shared/Config/Tools")
			Game = env:require("shared/Config/Game")

			playerData = Fakes.playerData()
			notify = Fakes.notify()
			rateLimit = Fakes.rateLimit(true)

			env:mock("shared/Remotes", Fakes.remotes(env))
			env:mock("server/Data/PlayerData", playerData)
			env:mock("server/Net/Notify", notify)
			env:mock("server/Net/RateLimit", rateLimit)
			env:mock("server/Analytics/Analytics", Fakes.analytics())
			env:mock("server/Events/CabaiEvent", {
				multiplier = function()
					return 1
				end,
				isActive = function()
					return false
				end,
				start = function() end,
			})
			env:mock("server/World/Village", {
				getPosition = function()
					return env.Vector3.new(0, 0, 0)
				end,
				onPasar = function() end,
			})
			env:mock("server/Season/SeasonService", {
				growSeconds = function(base)
					return base
				end,
				musim = function()
					return "hujan"
				end,
			})

			ToolService = env:require("server/Farm/ToolService")
			player = Fakes.player(env)
			data = playerData.set(player, Fakes.newData(env))
			data.cash = 2000
		end)

		t:describe("effects", function()
			t:it("starts with no bonuses at the base capacity", function()
				expect(ToolService.growMultiplier(data)):toBe(1)
				expect(ToolService.plantBonus(data)):toBe(0)
				expect(ToolService.sackCapacity(data)):toBe(Game.sackBaseCapacity)
			end)

			t:it("adds the purchased tier's effects", function()
				data.tools.cangkul = "baja"
				data.tools.gembor = "sprinkler"
				data.tools.karung = "gerobak"
				expect(ToolService.plantBonus(data)):toBeNear(0.12)
				expect(ToolService.growMultiplier(data)):toBeNear(1.25)
				expect(ToolService.sackCapacity(data)):toBe(Game.sackBaseCapacity + 60)
			end)

			t:it("divides the season grow time by the tool multiplier", function()
				data.tools.gembor = "gembor"
				expect(ToolService.growSeconds(100, "palawija", data)):toBe(91)
			end)

			t:it("never drops below five seconds", function()
				data.tools.gembor = "sprinkler"
				expect(ToolService.growSeconds(1, "palawija", data)):toBe(5)
			end)

			t:it("ignores a tier id that no longer exists", function()
				data.tools.cangkul = "dariMasaDepan"
				expect(ToolService.plantBonus(data)):toBe(0)
				expect(ToolService.nextTier(data, "cangkul")):toBe(Tools.list.cangkul.tiers[1])
			end)
		end)

		t:describe("buy", function()
			t:it("buys the first tier and publishes it", function()
				expect(ToolService.buy(player, "cangkul")):toBe(true)
				expect(data.tools.cangkul):toBe("bambu")
				expect(data.cash):toBe(2000 - 60)
				expect(player:GetAttribute("Tool_cangkul")):toBe("bambu")
				expect(notify.keys(player)):toContain("n_tool_bought")
			end)

			t:it("buys the next tier, then reports the line as maxed", function()
				expect(ToolService.buy(player, "cangkul")):toBe(true)
				expect(ToolService.buy(player, "cangkul")):toBe(true)
				expect(data.tools.cangkul):toBe("baja")
				expect(ToolService.buy(player, "cangkul")):toBe(false)
				expect(notify.keys(player)):toContain("n_tool_maxed")
			end)

			t:it("refuses a tool above the player's rank", function()
				expect(ToolService.buy(player, "gembor")):toBe(false)
				expect(data.tools.gembor):toBeNil()
				expect(notify.keys(player)):toContain("n_rank_locked")
			end)

			t:it("refuses when the player cannot afford it", function()
				data.cash = 10
				expect(ToolService.buy(player, "cangkul")):toBe(false)
				expect(data.tools.cangkul):toBeNil()
				expect(notify.keys(player)):toContain("n_not_enough_cash")
			end)

			t:it("refuses unknown lines and rate-limited requests", function()
				expect(ToolService.buy(player, "nope")):toBe(false)
				rateLimit.allow = function()
					return false
				end
				expect(ToolService.buy(player, "cangkul")):toBe(false)
				expect(data.cash):toBe(2000)
			end)
		end)

		t:describe("publish", function()
			t:it("mirrors every line and the sack capacity", function()
				data.tools.karung = "besar"
				ToolService.publish(player, data)
				expect(player:GetAttribute("Tool_karung")):toBe("besar")
				expect(player:GetAttribute("Tool_cangkul")):toBeNil()
				expect(player:GetAttribute("SackCapacity")):toBe(Game.sackBaseCapacity + 20)
			end)
		end)
	end)
end
