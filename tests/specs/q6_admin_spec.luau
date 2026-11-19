--!nocheck
-- WORK_QUEUE item 0a: the published-place Q6 admin commands.
--
-- The gate is pure (no Studio field on purpose). The flow half wires the REAL Q6AdminGate,
-- Q6Admin and PersistenceCheck under Lune with only the service edges faked, so a published
-- server (RunService:IsStudio() = false) can be proven to capture, compare and refuse correctly.
-- JSONEncode/JSONDecode use Lune's serde; no hand-written JSON stand-in can hide a decode bug.

local serde = require("@lune/serde")

local function printed(prints, prefix)
	for index = #prints, 1, -1 do
		if string.sub(prints[index], 1, #prefix) == prefix then
			return prints[index]
		end
	end
	return nil
end

return function(t, Env, Fakes)
	local expect = t.expect

	local function makeWorld(options)
		options = options or {}
		local env = Env.new()
		-- Published place: the real Admins allowlist (not Studio's everybody-is-admin) decides.
		env.services.RunService.IsStudio = function()
			return options.studio == true
		end
		env.services.HttpService = {
			JSONEncode = function(_, value)
				return serde.encode("json", value)
			end,
			JSONDecode = function(_, text)
				return serde.decode("json", text)
			end,
		}

		local prints = {}
		env.globals.print = function(...)
			local parts = table.pack(...)
			for index = 1, parts.n do
				parts[index] = tostring(parts[index])
			end
			table.insert(prints, table.concat(parts, " "))
		end

		local playerData = Fakes.playerData()
		local rate = { ok = options.rateOk ~= false, calls = {} }
		function rate.allow(player, key, perSecond)
			table.insert(rate.calls, { player = player, key = key, perSecond = perSecond })
			return rate.ok
		end

		env:mock("shared/Remotes", Fakes.remotes(env))
		env:mock("server/Data/PlayerData", playerData)
		env:mock("server/Net/RateLimit", rate)
		env:mock("server/Farm/PlotService", {
			getPlotOf = function()
				return { index = 1 }
			end,
		})
		env:mock("server/Farm/StorageService", {
			used = function()
				return 3
			end,
		})
		env:mock("server/Economy/ShopService", {
			stock = function()
				return { padi = 2 }
			end,
		})
		env:mock("server/Progression/OnboardingService", {
			current = function()
				return { id = "jual" }
			end,
		})

		-- Admins, Q6AdminGate, Q6Admin and PersistenceCheck are deliberately NOT mocked.
		local Admins = env:require("server/Live/Admins")
		local Q6Admin = env:require("server/Testing/Q6Admin")
		local Check = env:require("server/Testing/PersistenceCheck")

		local player = Fakes.player(env, { name = options.name or "Designer" })
		if options.admin ~= false then
			player.UserId = Admins.userIds[1] -- shipped allowlist id, never an invented one
		end
		local data = Fakes.newData(env)
		data.cash = options.cash or 500
		data.lifetimeEarned = 1200
		data.tiles.t1 = { crop = "padi", plantedAt = env.wallTime - 10, growSeconds = 100, hot = false }
		playerData.set(player, data)

		local world = {
			env = env,
			prints = prints,
			player = player,
			data = data,
			playerData = playerData,
			rate = rate,
			Admins = Admins,
			Q6Admin = Q6Admin,
			Check = Check,
		}
		return world
	end

	t:describe("Q6 admin gate (published place, no Studio field)", function()
		local gate
		t:beforeEach(function()
			local env = Env.new()
			env.services.RunService.IsStudio = function()
				return false
			end
			gate = env:require("server/Testing/Q6AdminGate")
		end)

		t:it("refuses a non-admin even with rate allowance and a known action", function()
			expect(gate.canUse({ admin = false, rateAllowed = true, action = "q6Capture" })):toBe(false)
			expect(gate.canUse({ admin = nil, rateAllowed = true, action = "q6Compare" })):toBe(false)
			expect(gate.canUse({ admin = true, rateAllowed = true, action = "q6Capture" })):toBe(true)
		end)

		t:it("refuses a rate-blocked admin", function()
			expect(gate.canUse({ admin = true, rateAllowed = false, action = "q6Capture" })):toBe(false)
			expect(gate.canUse({ admin = true, rateAllowed = nil, action = "q6Compare" })):toBe(false)
			expect(gate.canUse({ admin = true, rateAllowed = true, action = "q6Capture" })):toBe(true)
		end)

		t:it("refuses unknown actions, malformed opts and truthy non-booleans", function()
			expect(gate.canUse({ admin = true, rateAllowed = true, action = "save" })):toBe(false)
			expect(gate.canUse({ admin = true, rateAllowed = true })):toBe(false)
			expect(gate.canUse(nil)):toBe(false)
			expect(gate.canUse("q6Capture")):toBe(false)
			expect(gate.canUse(1)):toBe(false)
			expect(gate.canUse({ admin = 1, rateAllowed = true, action = "q6Capture" })):toBe(false)
			expect(gate.canUse({ admin = true, rateAllowed = "yes", action = "q6Capture" })):toBe(false)
		end)

		t:it("allows a published admin for both actions and never asks about Studio", function()
			expect(gate.canUse({ admin = true, rateAllowed = true, action = "q6Capture" })):toBe(true)
			expect(gate.canUse({ admin = true, rateAllowed = true, action = "q6Compare" })):toBe(true)
			expect(gate.canUse({ admin = true, rateAllowed = true, action = "q6Capture", studio = false })):toBe(true)
			expect(gate.canUse({ admin = true, rateAllowed = true, action = "q6Capture", studio = true })):toBe(true)
			expect(gate.ACTIONS):toEqual({ q6Capture = true, q6Compare = true })
		end)
	end)

	t:describe("Q6 admin flow (real gate + real comparator, published server)", function()
		t:it("capture stores the before snapshot and prints Q6_BEFORE_JSON without saving", function()
			local world = makeWorld()
			local snapshot, err = world.Q6Admin.capture(world.player)
			expect(err):toBeNil()
			expect(type(snapshot)):toBe("table")
			expect(snapshot.cash):toBe(500)
			expect(snapshot.userId):toBe(world.player.UserId)
			expect(snapshot.seeds.padi):toBe(world.data.items["seed_padi"])
			expect(snapshot.tiles[1].crop):toBe("padi")
			expect(snapshot.gudang):toBe(3)
			expect(snapshot.shop.padi):toBe(2)
			expect(printed(world.prints, "Q6_BEFORE_JSON=")):toBe("Q6_BEFORE_JSON=" .. serde.encode("json", snapshot))
			expect(#world.playerData.saveCalls):toBe(0) -- read-only: no save, no mutation
		end)

		t:it("compare of identical before/after passes and prints the verdict and result JSON", function()
			local world = makeWorld()
			world.Q6Admin.capture(world.player)
			local results, err = world.Q6Admin.compare(world.player)
			expect(err):toBeNil()
			expect(results.ok):toBe(true)
			expect(#results.mismatches):toBe(0)
			expect(#results.matches):toBe(#world.Check.FIELDS)
			expect(world.Q6Admin.lastResult):toBe(results)
			expect(printed(world.prints, "Q6 persistence:")):toBe("Q6 persistence: 10/10 fields match; PASS")
			expect(printed(world.prints, "Q6_RESULT_JSON=")):toBe("Q6_RESULT_JSON=" .. serde.encode("json", results))
			expect(world.Q6Admin.canUse):toBe(world.env:require("server/Testing/Q6AdminGate").canUse)
		end)

		t:it("compare catches lost cash after rejoin instead of reporting a pass", function()
			local world = makeWorld()
			world.Q6Admin.capture(world.player)
			world.data.cash = 0
			local results, err = world.Q6Admin.compare(world.player)
			expect(err):toBeNil()
			expect(results.ok):toBe(false)
			expect(#results.mismatches):toBe(1)
			expect(results.mismatches[1].field):toBe("cash")
			expect(results.mismatches[1].before):toBe(500)
			expect(results.mismatches[1].after):toBe(0)
			expect(printed(world.prints, "Q6 persistence:")):toBe("Q6 persistence: 9/10 fields match; FAIL")
			expect(string.find(printed(world.prints, "Q6_RESULT_JSON=") or "", '"cash"', 1, true) ~= nil):toBe(true)
		end)

		t:it("compare with no stored before and no override errors instead of inventing a pass", function()
			local world = makeWorld()
			local results, err = world.Q6Admin.compare(world.player)
			expect(results):toBeNil()
			expect(type(err)):toBe("string")
			expect(world.Q6Admin.lastResult):toBeNil()
			expect(#world.prints):toBe(0)
		end)

		t:it("a pasted Q6_BEFORE_JSON works in a fresh module after a server restart", function()
			local first = makeWorld({ cash = 777 })
			first.Q6Admin.capture(first.player)
			local json = string.sub(printed(first.prints, "Q6_BEFORE_JSON="), #"Q6_BEFORE_JSON=" + 1)

			local rejoin = makeWorld({ cash = 777, name = "Rejoined" })
			local results, err = rejoin.Q6Admin.compare(rejoin.player, json)
			expect(err):toBeNil()
			expect(results.ok):toBe(true)
			expect(#results.mismatches):toBe(0)
			expect(printed(rejoin.prints, "Q6_RESULT_JSON=") ~= nil):toBe(true)
			expect(printed(rejoin.prints, "Q6_BEFORE_JSON=")):toBeNil() -- override never re-captures

			local bad, badErr = rejoin.Q6Admin.compare(rejoin.player, "not json")
			expect(bad):toBeNil()
			expect(type(badErr)):toBe("string")
		end)

		t:it("handle refuses non-admins and rate-blocked admins without printing anything", function()
			local stranger = makeWorld({ admin = false })
			local result, err = stranger.Q6Admin.handle(stranger.player, "q6Capture", nil)
			expect(result):toBeNil()
			expect(err):toBe("Q6 command refused: admin only, rate limited.")
			expect(#stranger.prints):toBe(0)
			expect(#stranger.rate.calls):toBe(1)
			expect(stranger.rate.calls[1].key):toBe("Q6_Command")
			expect(stranger.rate.calls[1].perSecond):toBe(2)

			local blocked = makeWorld({ rateOk = false })
			local blockedResult, blockedErr = blocked.Q6Admin.handle(blocked.player, "q6Compare", nil)
			expect(blockedResult):toBeNil()
			expect(blockedErr):toBe(err)
			expect(#blocked.prints):toBe(0)

			local allowed = makeWorld()
			local snapshot, okErr = allowed.Q6Admin.handle(allowed.player, "q6Capture", nil)
			expect(okErr):toBeNil()
			expect(snapshot.cash):toBe(500)
			expect(printed(allowed.prints, "Q6_BEFORE_JSON=") ~= nil):toBe(true)
		end)
	end)
end
