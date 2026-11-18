--!nocheck
-- WORK_QUEUE item 17: analytics audit against docs/v2/plan/ANALYTICS.md.
--
-- analytics_spec pins the WRAPPER contract (budget, once, field cap, never fatal). This file adds
-- what that spec cannot: proof that the documented events are actually called by their owning
-- services, that AnalyticsService has a single owner, and that the two funnel guarantees the plan
-- promises (onboarding steps in order + once, economy balance after the mutation) hold with the
-- REAL Analytics module wired to the REAL OnboardingService / EconomyService.
--
-- Static checks are `LUNE-ONLY` (they read source via @lune/fs, like remote_audit_spec). Behavioural
-- checks drive real modules with a fake AnalyticsService recorder — no platform calls.

local fs = require("@lune/fs")

local function read(path: string): string
	return fs.readFile(path)
end

local function listLuau(dir: string): { string }
	local out = {}
	local function walk(d)
		for _, name in fs.readDir(d) do
			local p = d .. "/" .. name
			if fs.isDir(p) then
				walk(p)
			elseif string.sub(name, -5) == ".luau" then
				table.insert(out, p)
			end
		end
	end
	walk(dir)
	table.sort(out)
	return out
end

local function has(path: string, needle: string): boolean
	return string.find(read(path), needle, 1, true) ~= nil
end

local SRC_FILES = listLuau("src")

local function filesContaining(needle: string): { string }
	local found = {}
	for _, path in SRC_FILES do
		if has(path, needle) then
			table.insert(found, path)
		end
	end
	return found
end

return function(t, Env, Fakes)
	local expect = t.expect

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
				table.insert(rec.funnel, {
					player = who,
					funnel = funnel,
					session = session,
					step = step,
					name = stepName,
				})
			end,
		}
		return rec
	end

	t:describe("Analytics audit — documented events have call sites (item 17)", function()
		t:it("only the Analytics module ever obtains AnalyticsService", function()
			local owners = filesContaining('GetService("AnalyticsService")')
			expect(owners):toEqual({ "src/server/Analytics/Analytics.luau" })
		end)

		-- Every row of ANALYTICS.md §2, mapped to the service that owns the mutation it reports.
		local documented = {
			{ "harvest", "src/server/Farm/FarmService.luau", '"harvest"' },
			{ "raid_started", "src/server/Law/RaidService.luau", '"raid_started"' },
			{ "cheat_used", "src/server/Law/CheatService.luau", '"cheat_used"' },
			{ "report_made", "src/server/Law/EvidenceService.luau", '"report_made"' },
			{ "debt_borrowed", "src/server/Economy/DebtService.luau", '"debt_borrowed"' },
			{ "debt_overdue", "src/server/Economy/DebtService.luau", '"debt_overdue"' },
			{ "debt_cleared", "src/server/Economy/DebtService.luau", '"debt_cleared"' },
			{ "debt_seized", "src/server/Economy/DebtService.luau", '"debt_seized"' },
			{ "purchase", "src/server/Monetization/Receipts.luau", '"purchase"' },
			{ "login_streak", "src/server/Progression/QuestService.luau", '"login_streak"' },
			{ "task_claimed", "src/server/Progression/QuestService.luau", '"task_claimed"' },
			{ "rank_up", "src/server/Progression/RankService.luau", '"rank_up"' },
			{ "badge_awarded", "src/server/Progression/BadgeService.luau", '"badge_awarded"' },
			{ "risk_banjir", "src/server/Farm/FarmService.luau", '"risk_banjir"' },
			{ "risk_hama", "src/server/Farm/FarmService.luau", '"risk_hama"' },
			{ "risk_gagal", "src/server/Farm/FarmService.luau", '"risk_gagal"' },
		}
		for _, row in documented do
			t:it("'" .. row[1] .. "' is called from " .. row[2], function()
				expect(has(row[2], row[3])):toBe(true)
			end)
		end

		t:it("economy events are emitted by EconomyService", function()
			expect(has("src/server/Economy/EconomyService.luau", "Analytics.economy(")):toBe(true)
		end)

		t:it("the onboarding funnel is emitted by OnboardingService", function()
			expect(has("src/server/Progression/OnboardingService.luau", "Analytics.onboarding(")):toBe(true)
		end)

		t:it("first_harvest is an example only and has no call site in src/", function()
			-- ANALYTICS.md §2 lists it as "(example `once`)". analytics_spec uses it as a sample
			-- name, but no gameplay service calls it. Tracked in WORK_QUEUE > Decisions for designer.
			expect(filesContaining('"first_harvest"')):toEqual({})
		end)

		t:it("ShopPurchase stays intentionally unwired in M4", function()
			-- ANALYTICS.md §4: "Reserved for the client purchase funnel; not wired in M4."
			expect(filesContaining('"ShopPurchase"')):toEqual({})
		end)

		t:it("the extra first_session funnel is present but not documented", function()
			-- FirstSession reports steps 5/7/8/9; ANALYTICS.md §4 only lists Onboarding and
			-- ShopPurchase. Listed in Decisions for designer rather than removed silently.
			expect(has("src/server/Progression/FirstSession.luau", '"first_session"')):toBe(true)
		end)
	end)

	t:describe("Analytics audit — funnel wiring with the real wrapper (item 17)", function()
		t:it("onboarding steps fire in order, once, then finished", function()
			local env = Env.new()
			local rec = newRecorder()
			env.services.AnalyticsService = rec.service
			local playerData = Fakes.playerData()
			env:mock("shared/Remotes", Fakes.remotes(env))
			env:mock("server/Data/PlayerData", playerData)
			env:mock("server/Net/Notify", Fakes.notify())
			env:mock("server/Net/State", { touch = function() end })

			local Onboarding = env:require("shared/Config/Onboarding")
			local OnboardingService = env:require("server/Progression/OnboardingService")
			local player = Fakes.player(env)
			playerData.set(player, Fakes.newData(env))

			expect(OnboardingService.advance(player, Onboarding.steps[1].id)):toBe(true)
			-- A repeated or out-of-order action must not log a step that never happened.
			expect(OnboardingService.advance(player, Onboarding.steps[1].id)):toBe(false)
			if Onboarding.total >= 3 then
				expect(OnboardingService.advance(player, Onboarding.steps[3].id)):toBe(false)
			end
			for index = 2, Onboarding.total do
				expect(OnboardingService.advance(player, Onboarding.steps[index].id)):toBe(true)
			end
			expect(OnboardingService.advance(player, Onboarding.steps[Onboarding.total].id)):toBe(false)

			-- One event per committed step (steps are never logged twice), then "finished" once.
			expect(#rec.onboarding):toBe(Onboarding.total + 1)
			local expected = {}
			for index, step in Onboarding.steps do
				table.insert(expected, { name = step.id, step = index })
			end
			table.insert(expected, { name = "finished", step = Onboarding.total + 1 })
			for index, step in expected do
				expect(rec.onboarding[index].name):toBe(step.name)
				expect(rec.onboarding[index].step):toBe(step.step)
				expect(rec.onboarding[index].player):toBe(player)
			end
			-- The funnel carries only step numbers and config ids — no names or UserIds.
			expect(#rec.funnel):toBe(0)
		end)

		t:it("economy events report the balance after the committed mutation", function()
			local env = Env.new()
			local rec = newRecorder()
			env.services.AnalyticsService = rec.service
			local playerData = Fakes.playerData()
			env:mock("shared/Remotes", Fakes.remotes(env))
			env:mock("server/Data/PlayerData", playerData)
			env:mock("server/Net/Notify", Fakes.notify())
			env:mock("server/Net/RateLimit", Fakes.rateLimit(true))
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
			local Economy = env:require("server/Economy/EconomyService")
			local player = Fakes.player(env)
			local data = playerData.set(player, Fakes.newData(env))
			local before = data.cash

			Economy.addCash(player, 100, false, { sku = "pasar", transaction = "Gameplay" })
			expect(#rec.economy):toBe(1)
			expect(rec.economy[1].flow):toBe("AnalyticsEconomyFlowType.Source")
			expect(rec.economy[1].amount):toBe(100)
			expect(rec.economy[1].balance):toBe(before + 100)
			expect(rec.economy[1].balance):toBe(data.cash)
			expect(rec.economy[1].currency):toBe("Cash")
			expect(rec.economy[1].sku):toBe("pasar")
			expect(rec.economy[1].transaction):toBe("Gameplay")

			expect(Economy.trySpend(player, 40, { sku = "bibit_padi" })):toBe(true)
			expect(#rec.economy):toBe(2)
			expect(rec.economy[2].flow):toBe("AnalyticsEconomyFlowType.Sink")
			expect(rec.economy[2].amount):toBe(40)
			expect(rec.economy[2].balance):toBe(data.cash)
			expect(rec.economy[2].sku):toBe("bibit_padi")

			-- A refused mutation logs nothing.
			expect(Economy.trySpend(player, data.cash + 1)):toBe(false)
			expect(#rec.economy):toBe(2)
		end)
	end)
end
