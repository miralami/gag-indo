--!nocheck
-- WORK_QUEUE item 16: admin and season tools.
--
-- season_admin_failure_spec already pins payload validation with Admins and LiveConfig MOCKED.
-- This spec complements it by wiring the REAL Admins allowlist, the REAL LiveConfig and the REAL
-- AdminService together, so the gate itself (not a stand-in) is proven:
--   * a non-allowlisted player is refused on a published server;
--   * forging the client-visible IsAdmin attribute grants nothing;
--   * the allowlisted designer can actually change the live config and grant a bounded cash sum;
--   * Studio's "everyone is an admin" convenience still enforces every payload bound.
-- No ids are invented: the designer UserId is read from the shipped allowlist.

return function(t, Env, Fakes)
	local expect = t.expect

	local function makeWorld(options)
		options = options or {}
		local env = Env.new()
		-- Published by default: RunService:IsStudio() is false, so the real allowlist decides.
		env.services.RunService.IsStudio = function()
			return options.studio == true
		end
		-- Real LiveConfig persistence is a no-op here; the config change is applied locally.
		env.services.DataStoreService.GetDataStore = function()
			return {
				GetAsync = function()
					return nil
				end,
				SetAsync = function() end,
			}
		end
		env.services.MessagingService = {
			PublishAsync = function() end,
			SubscribeAsync = function()
				return { Disconnect = function() end }
			end,
		}

		local playerData = Fakes.playerData()
		local remotes = Fakes.remotes(env)
		local cashGrants = {}
		local replies = {}

		env:mock("shared/Remotes", remotes)
		env:mock("server/Data/PlayerData", playerData)
		env:mock("server/Net/RateLimit", Fakes.rateLimit(options.allow ~= false))
		env:mock("server/Net/State", { touch = function() end })
		env:mock("server/Economy/EconomyService", {
			sync = function() end,
			addCash = function(_, amount, earned, opts)
				table.insert(cashGrants, { amount = amount, earned = earned, sku = opts and opts.sku })
			end,
		})

		-- Deliberately NOT mocked: Admins, LiveConfig, AdminService, Inventory.
		local Admins = env:require("server/Live/Admins")
		local LiveConfig = env:require("server/Live/LiveConfig")
		local Inventory = env:require("shared/Inventory")
		local AdminService = env:require("server/Live/AdminService")
		AdminService.start()

		local designer = Fakes.player(env, { name = "Designer" })
		designer.UserId = Admins.userIds[1] -- the shipped allowlist id, not an invented one
		local attacker = Fakes.player(env, { name = "Attacker" })
		local target = Fakes.player(env, { name = "Target" })
		local targetData = playerData.set(target, Fakes.newData(env))
		playerData.set(attacker, Fakes.newData(env))

		remotes.Admin_Result.FireClient = function(_, player, payload)
			table.insert(replies, { to = player, payload = payload })
		end

		local w = {
			env = env,
			Admins = Admins,
			LiveConfig = LiveConfig,
			Inventory = Inventory,
			designer = designer,
			attacker = attacker,
			target = target,
			targetData = targetData,
			cashGrants = cashGrants,
			replies = replies,
		}
		function w:send(player, payload)
			remotes.Admin_Command.OnServerEvent:Fire(player, payload)
		end
		function w:lastTo(player)
			for i = #replies, 1, -1 do
				if replies[i].to == player then
					return replies[i].payload
				end
			end
		end
		return w
	end

	local PRIVILEGED = {
		{ action = "setSeason", value = "kemarau" },
		{ action = "setAnomaly", value = "elNino" },
		{ action = "setEvent", value = { event = "cabai", mode = "on" } },
		{ action = "grantCash", value = { userId = "TARGET", amount = 500 } },
		{ action = "grantItem", value = { userId = "TARGET", itemId = "seed_padi", amount = 5 } },
	}

	t:describe("Admin authority with the real allowlist (item 16)", function()
		t:it("a non-allowlisted player is refused by the real gate on a published server", function()
			local w = makeWorld()
			expect(w.Admins.isAdmin(w.attacker.UserId)):toBe(false)
			local seasonBefore = w.LiveConfig.get().seasonOverride
			local cashBefore = w.targetData.cash
			local itemsBefore = w.Inventory.get(w.targetData, "seed_padi")
			for _, template in PRIVILEGED do
				local payload = {
					action = template.action,
					value = template.value,
				}
				if type(payload.value) == "table" and payload.value.userId == "TARGET" then
					payload.value = table.clone(payload.value)
					payload.value.userId = w.target.UserId
				end
				w:send(w.attacker, payload)
			end
			expect(w.LiveConfig.get().seasonOverride):toBe(seasonBefore)
			expect(w.targetData.cash):toBe(cashBefore)
			expect(#w.cashGrants):toBe(0)
			expect(w.Inventory.get(w.targetData, "seed_padi")):toBe(itemsBefore)
			expect(#w.replies):toBe(#PRIVILEGED)
			for _, reply in w.replies do
				expect(reply.to):toBe(w.attacker)
				expect(reply.payload.ok):toBe(false)
			end
		end)

		t:it("forging the IsAdmin attribute does not grant any admin power", function()
			local w = makeWorld()
			w.attacker:SetAttribute("IsAdmin", true)
			local seasonBefore = w.LiveConfig.get().seasonOverride
			w:send(w.attacker, { action = "setSeason", value = "kemarau" })
			w:send(w.attacker, { action = "grantCash", value = { userId = w.target.UserId, amount = 500 } })
			expect(w.LiveConfig.get().seasonOverride):toBe(seasonBefore)
			expect(#w.cashGrants):toBe(0)
			expect(w:lastTo(w.attacker).ok):toBe(false)
		end)

		t:it("the allowlisted designer changes the real live config and grants bounded cash", function()
			local w = makeWorld()
			expect(w.Admins.isAdmin(w.designer.UserId)):toBe(true)
			w:send(w.designer, { action = "setSeason", value = "kemarau" })
			expect(w.LiveConfig.get().seasonOverride):toBe("kemarau")
			expect(w.LiveConfig.getRuntime().musim):toBe("kemarau")

			w:send(w.designer, { action = "setAnomaly", value = "elNino" })
			expect(w.LiveConfig.get().anomaly):toBe("elNino")
			expect(w.LiveConfig.getRuntime().anomali):toBe("elNino")

			w:send(w.designer, { action = "setEvent", value = { event = "cabai", mode = "off" } })
			expect(w.LiveConfig.get().events.cabai):toBe("off")

			w:send(w.designer, { action = "grantCash", value = { userId = w.target.UserId, amount = 500 } })
			expect(#w.cashGrants):toBe(1)
			expect(w.cashGrants[1].amount):toBe(500)
			expect(w.cashGrants[1].earned):toBe(false) -- never inflates rank or leaderboard
			expect(w.cashGrants[1].sku):toBe("admin_grant")
		end)

		t:it("Studio's everyone-is-admin convenience still enforces every payload bound", function()
			local w = makeWorld({ studio = true })
			expect(w.Admins.isAdmin(w.attacker.UserId)):toBe(true)
			local seasonBefore = w.LiveConfig.get().seasonOverride
			w:send(w.attacker, { action = "setSeason", value = "salju" })
			expect(w.LiveConfig.get().seasonOverride):toBe(seasonBefore)
			expect(w:lastTo(w.attacker).ok):toBe(false)
			w:send(w.attacker, { action = "grantCash", value = { userId = w.target.UserId, amount = 1e9 } })
			expect(#w.cashGrants):toBe(0)
			-- A valid command from the same non-allowlisted player still works in Studio.
			w:send(w.attacker, { action = "setSeason", value = "hujan" })
			expect(w.LiveConfig.get().seasonOverride):toBe("hujan")
		end)
	end)
end
