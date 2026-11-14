--!nocheck
-- Analytics wrapper (v2 PLAN §7.1): one owner, server-side only, budgeted, never fatal.
--
-- These tests pin the wrapper's contract, not the Roblox dashboard: what is sent, what is
-- dropped, and what must never reach AnalyticsService (personal data, failed mutations).

return function(t, Env, Fakes)
	local expect = t.expect
	local env, Analytics, recorder, player

	local function newRecorder()
		local rec = { custom = {}, economy = {}, onboarding = {}, funnel = {} }
		rec.service = {
			LogCustomEvent = function(_, who, name, value, fields)
				table.insert(rec.custom, { player = who, name = name, value = value, fields = fields })
			end,
			LogEconomyEvent = function(_, who, flow, currency, amount, balance, transaction, sku, fields)
				table.insert(rec.economy, {
					player = who,
					flow = flow,
					currency = currency,
					amount = amount,
					balance = balance,
					transaction = transaction,
					sku = sku,
					fields = fields,
				})
			end,
			LogOnboardingFunnelStepEvent = function(_, who, step, stepName)
				table.insert(rec.onboarding, { player = who, step = step, name = stepName })
			end,
			LogFunnelStepEvent = function(_, who, funnel, session, step, stepName)
				table.insert(rec.funnel, { player = who, funnel = funnel, session = session, step = step, name = stepName })
			end,
		}
		return rec
	end

	t:describe("Analytics", function()
		t:beforeEach(function()
			env = Env.new()
			recorder = newRecorder()
			env.services.AnalyticsService = recorder.service
			player = Fakes.player(env)
			Analytics = env:require("server/Analytics/Analytics")
		end)

		t:describe("budget", function()
			t:it("grows with the number of players", function()
				expect(Analytics.budgetFor(0)):toBe(120)
				expect(Analytics.budgetFor(1)):toBe(140)
				expect(Analytics.budgetFor(10)):toBe(320)
			end)

			t:it("drops calls past the minute budget instead of spamming the service", function()
				for index = 1, 200 do
					Analytics.track(player, "spam", index)
				end
				expect(#recorder.custom):toBe(140)
			end)

			t:it("reopens the budget after a minute", function()
				for index = 1, 200 do
					Analytics.track(player, "spam", index)
				end
				expect(#recorder.custom):toBe(140)
				env:advance(61)
				Analytics.track(player, "after_window", 1)
				expect(#recorder.custom):toBe(141)
				expect(recorder.custom[141].name):toBe("after_window")
			end)
		end)

		t:describe("track", function()
			t:it("sends a custom event with a value", function()
				Analytics.track(player, "harvest", 1)
				expect(#recorder.custom):toBe(1)
				expect(recorder.custom[1].name):toBe("harvest")
				expect(recorder.custom[1].value):toBe(1)
			end)

			t:it("caps custom fields at three and stringifies them", function()
				Analytics.track(player, "harvest", 1, { "padi", "sultan", "gudang", "ignored" })
				expect(recorder.custom[1].fields):toEqual({
					CustomField01 = "padi",
					CustomField02 = "sultan",
					CustomField03 = "gudang",
				})
			end)

			t:it("ignores a missing player or empty event name", function()
				Analytics.track(nil, "harvest", 1)
				Analytics.track(player, "", 1)
				expect(#recorder.custom):toBe(0)
			end)

			t:it("never throws when the analytics service fails", function()
				recorder.service.LogCustomEvent = function()
					error("API access is off")
				end
				expect(function()
					Analytics.track(player, "harvest", 1)
				end).never:toThrow()
			end)
		end)

		t:describe("once", function()
			t:it("fires at most once per player and event", function()
				Analytics.once(player, "first_harvest", 1)
				Analytics.once(player, "first_harvest", 1)
				Analytics.once(player, "first_harvest", 1)
				expect(#recorder.custom):toBe(1)
			end)

			t:it("keeps a separate key per first field", function()
				Analytics.once(player, "channel_sale", 1, { "pasar" })
				Analytics.once(player, "channel_sale", 1, { "pasar" })
				Analytics.once(player, "channel_sale", 1, { "gelap" })
				expect(#recorder.custom):toBe(2)
			end)

			t:it("does not share the once memory between players", function()
				local other = Fakes.player(env)
				Analytics.once(player, "first_harvest", 1)
				Analytics.once(other, "first_harvest", 1)
				expect(#recorder.custom):toBe(2)
			end)
		end)

		t:describe("economy", function()
			t:it("reports a committed source with its balance", function()
				Analytics.economy(player, "Source", 50, 150, "IAP", "rupiah_kecil")
				expect(#recorder.economy):toBe(1)
				local event = recorder.economy[1]
				expect(event.flow):toBe("AnalyticsEconomyFlowType.Source")
				expect(event.currency):toBe("Cash")
				expect(event.amount):toBe(50)
				expect(event.balance):toBe(150)
				-- BUG-005: the engine takes transactionType as a string; an EnumItem raised
				-- "argument #6 expects a string" on every sell and buy in Studio.
				expect(type(event.transaction)):toBe("string")
				expect(event.transaction):toBe("IAP")
				expect(event.sku):toBe("rupiah_kecil")
			end)

			t:it("reports a sink separately", function()
				Analytics.economy(player, "Sink", 200, 800, "Shop", "bibit_padi")
				expect(recorder.economy[1].flow):toBe("AnalyticsEconomyFlowType.Sink")
				expect(recorder.economy[1].transaction):toBe("Shop")
			end)

			t:it("drops zero, negative and broken amounts", function()
				Analytics.economy(player, "Source", 0, 100, "Gameplay", "x")
				Analytics.economy(player, "Sink", -5, 100, "Gameplay", "x")
				Analytics.economy(player, "Source", 5, -1, "Gameplay", "x")
				Analytics.economy(player, "Source", 5, 0 / 0, "Gameplay", "x")
				expect(#recorder.economy):toBe(0)
			end)
		end)

		t:describe("funnels", function()
			t:it("reports onboarding steps in order", function()
				Analytics.onboarding(player, 1, "plant")
				Analytics.onboarding(player, 2, "harvest")
				expect(#recorder.onboarding):toBe(2)
				expect(recorder.onboarding[2].step):toBe(2)
				expect(recorder.onboarding[2].name):toBe("harvest")
			end)

			t:it("ignores an invalid step", function()
				Analytics.onboarding(player, 0, "plant")
				Analytics.onboarding(player, nil, "plant")
				expect(#recorder.onboarding):toBe(0)
			end)

			t:it("reports a recurring funnel with its session", function()
				Analytics.funnel(player, "ShopPurchase", "session-1", 1, "OpenedShop")
				expect(recorder.funnel[1].funnel):toBe("ShopPurchase")
				expect(recorder.funnel[1].session):toBe("session-1")
			end)
		end)
	end)
end
