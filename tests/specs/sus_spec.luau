--!nocheck
return function(t, Env, Fakes)
	local expect = t.expect
	local env, Law, SusService, notify, raid, player, data

	t:describe("SusService", function()
		t:beforeEach(function()
			env = Env.new()
			Law = env:require("shared/Config/Law")

			local playerData = Fakes.playerData()
			notify = Fakes.notify()
			raid = { started = {} }
			function raid.start(who, respectCooldown)
				table.insert(raid.started, { player = who, respectCooldown = respectCooldown })
			end

			env:mock("server/Data/PlayerData", playerData)
			env:mock("server/Net/Notify", notify)
			env:mock("server/Law/RaidService", raid)
			SusService = env:require("server/Law/SusService")

			player = Fakes.player(env)
			data = playerData.set(player, Fakes.newData(env))
		end)

		t:describe("add", function()
			t:it("raises Sus and mirrors it to the player attribute", function()
				expect(SusService.add(player, 15)):toBe(15)
				expect(SusService.get(player)):toBe(15)
				expect(player:GetAttribute("Sus")):toBe(15)
			end)

			t:it("never goes above the maximum", function()
				expect(SusService.add(player, 500)):toBe(Law.susMax)
			end)

			t:it("never goes below zero", function()
				SusService.add(player, 10)
				expect(SusService.add(player, -500)):toBe(0)
			end)

			t:it("floors fractional amounts", function()
				expect(SusService.add(player, 10.9)):toBe(10)
			end)

			t:it("ignores NaN and non-numbers", function()
				expect(SusService.add(player, 0 / 0)):toBe(0)
				expect(SusService.add(player, "20")):toBe(0)
				expect(SusService.get(player)):toBe(0)
			end)

			t:it("does nothing for a player with no loaded data", function()
				local stranger = Fakes.player(env)
				expect(SusService.add(stranger, 20)):toBe(0)
				expect(SusService.get(stranger)):toBe(0)
			end)
		end)

		t:describe("Surat Panggilan warning", function()
			t:it("fires once when Sus crosses the letter threshold", function()
				SusService.add(player, Law.letterSus - 1)
				expect(#notify.keys(player)):toBe(0)
				SusService.add(player, 1)
				expect(notify.keys(player)):toEqual({ "n_letter" })
			end)

			t:it("does not repeat while Sus stays above the threshold", function()
				SusService.add(player, Law.letterSus)
				SusService.add(player, 5)
				expect(#notify.keys(player)):toBe(1)
			end)

			t:it("fires again after Sus drops below and climbs back", function()
				SusService.add(player, Law.letterSus)
				SusService.add(player, -20)
				SusService.add(player, 20)
				expect(#notify.keys(player)):toBe(2)
			end)
		end)

		t:describe("raid at maximum Sus", function()
			t:it("starts a raid that ignores the cooldown, after the current frame", function()
				SusService.add(player, Law.susMax)
				expect(#raid.started):toBe(0) -- deferred, not immediate
				env:flush()
				expect(#raid.started):toBe(1)
				expect(raid.started[1].player):toBe(player)
				expect(raid.started[1].respectCooldown):toBe(false)
			end)

			t:it("does not start a raid below the maximum", function()
				SusService.add(player, Law.susMax - 1)
				env:flush()
				expect(#raid.started):toBe(0)
			end)
		end)

		t:describe("reduce", function()
			t:it("lowers Sus by the given amount", function()
				SusService.add(player, 40)
				expect(SusService.reduce(player, 10)):toBe(30)
			end)

			t:it("ignores zero, negative and non-number amounts", function()
				SusService.add(player, 40)
				expect(SusService.reduce(player, 0)):toBe(40)
				expect(SusService.reduce(player, -5)):toBe(40)
				expect(SusService.reduce(player, "5")):toBe(40)
			end)
		end)

		t:describe("setSus", function()
			t:it("sets an exact value (raid reset) and clamps it", function()
				SusService.setSus(player, Law.raidResetSus)
				expect(SusService.get(player)):toBe(Law.raidResetSus)
				SusService.setSus(player, 9999)
				expect(SusService.get(player)):toBe(Law.susMax)
			end)

			t:it("ignores NaN", function()
				SusService.setSus(player, 20)
				SusService.setSus(player, 0 / 0)
				expect(SusService.get(player)):toBe(20)
			end)
		end)
	end)
end
