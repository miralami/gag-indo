--!nocheck
-- SeasonService and AdminService failure-path specs.
-- AdminService (security): a non-admin gets nothing and changes nothing; malformed payloads,
-- out-of-range grants and rate-limited calls are refused without error; replies go only to the caller.
-- SeasonService: invalid override/anomaly values keep the last good state; NaN, huge and rewound
-- clocks never break growth; start() is idempotent.
-- Tests whose name starts with "[BUG]" are expected to fail and reveal real defects (see the report
-- that accompanies this spec). Do not edit AdminService, SeasonService, LiveConfig or Inventory to make
-- them pass in this file. Admins and LiveConfig are mocked where the test is about the admin gate.

return function(t, Env, Fakes)
	local expect = t.expect

	local function isFinite(n)
		return type(n) == "number" and n == n and n > -math.huge and n < math.huge
	end

	-- AdminService fixture -------------------------------------------------------------------

	local function makeAdmin(options)
		options = options or {}
		local env = Env.new()
		local playerData = Fakes.playerData()
		local remotes = Fakes.remotes(env)
		local rateLimit = Fakes.rateLimit(options.allow ~= false)
		local adminIds = {}
		local config = { updates = {}, refreshes = 0 }
		local grants = { cash = {}, synced = 0, touched = {} }
		local replies = {}

		env:mock("shared/Remotes", remotes)
		env:mock("server/Data/PlayerData", playerData)
		env:mock("server/Net/RateLimit", rateLimit)
		env:mock("server/Net/State", {
			touch = function(player, section)
				table.insert(grants.touched, { player = player, section = section })
			end,
		})
		env:mock("server/Economy/EconomyService", {
			sync = function()
				grants.synced += 1
			end,
			addCash = function(player, amount, _, opts)
				table.insert(grants.cash, { player = player, amount = amount, sku = opts and opts.sku })
			end,
		})
		env:mock("server/Live/LiveConfig", {
			update = function(patch, byUserId)
				table.insert(config.updates, { patch = patch, byUserId = byUserId })
				return patch
			end,
			get = function()
				return { seasonOverride = "auto", anomaly = "none" }
			end,
			getRuntime = function()
				return { musim = "kemarau", anomali = "none" }
			end,
			refresh = function()
				config.refreshes += 1
			end,
		})
		-- The Studio fake answers true for every user, so the admin gate is mocked explicitly.
		env:mock("server/Live/Admins", {
			isAdmin = function(userId)
				return adminIds[userId] == true
			end,
		})
		remotes.Admin_Result.FireClient = function(_, player, payload)
			table.insert(replies, { to = player, payload = payload })
		end

		local admin = Fakes.player(env, { name = "Admin" })
		adminIds[admin.UserId] = true
		local attacker = Fakes.player(env, { name = "Attacker" })
		local target = Fakes.player(env, { name = "Target" })
		local targetData = playerData.set(target, Fakes.newData(env))
		playerData.set(attacker, Fakes.newData(env))

		local AdminService = env:require("server/Live/AdminService")
		AdminService.start()

		return {
			env = env,
			admin = admin,
			attacker = attacker,
			target = target,
			targetData = targetData,
			playerData = playerData,
			rateLimit = rateLimit,
			config = config,
			grants = grants,
			replies = replies,
			inventory = env:require("shared/Inventory"),
			send = function(player, payload)
				remotes.Admin_Command.OnServerEvent:Fire(player, payload)
			end,
		}
	end

	local function lastReplyTo(fx, player)
		local last
		for _, reply in fx.replies do
			if reply.to == player then
				last = reply.payload
			end
		end
		return last
	end

	local function expectNoMutations(fx)
		expect(#fx.config.updates):toBe(0)
		expect(fx.config.refreshes):toBe(0)
		expect(#fx.grants.cash):toBe(0)
		expect(fx.grants.synced):toBe(0)
		expect(#fx.grants.touched):toBe(0)
	end

	-- SeasonService fixture ------------------------------------------------------------------

	local function makeSeason(options)
		options = options or {}
		local env = Env.new()
		if options.wallTime then
			env.wallTime = options.wallTime
		end
		-- The real LiveConfig: season/anomaly validation and clock resolution are what is under test.
		local LiveConfig = env:require("server/Live/LiveConfig")
		local SeasonService = env:require("server/Season/SeasonService")
		local Crops = env:require("shared/Config/Crops")
		local Seasons = env:require("shared/Config/Seasons")
		SeasonService.start()
		return {
			env = env,
			LiveConfig = LiveConfig,
			SeasonService = SeasonService,
			Crops = Crops,
			Seasons = Seasons,
		}
	end

	local function attrOf(fx, familyId)
		return fx.env.services.ReplicatedStorage:GetAttribute("Growth_" .. familyId)
	end

	-- Every published Growth_ attribute equals the pure Seasons.growth for the live runtime.
	local function expectGrowthMatchesRuntime(fx)
		local runtime = fx.LiveConfig.getRuntime()
		for _, familyId in fx.Crops.familyOrder do
			expect(attrOf(fx, familyId)):toBe(fx.Seasons.growth(runtime.musim, familyId, runtime.anomali))
		end
	end

	t:describe("AdminService failure paths", function()
		t:it("a non-admin gets only an access-denied reply and changes nothing, for every action", function()
			local fx = makeAdmin()
			local itemsBefore = fx.inventory.get(fx.targetData, "seed_padi")
			local payloads = {
				{ action = "inspect", value = { userId = fx.target.UserId } },
				{ action = "setSeason", value = "kemarau" },
				{ action = "setAnomaly", value = "elNino" },
				{ action = "setEvent", value = { event = "cabai", mode = "on" } },
				{ action = "grantItem", value = { userId = fx.target.UserId, itemId = "seed_padi", amount = 5 } },
				{ action = "grantCash", value = { userId = fx.target.UserId, amount = 100 } },
				{ action = "getConfig" },
				{ action = "refresh" },
			}
			for _, payload in payloads do
				fx.send(fx.attacker, payload)
			end
			expect(#fx.replies):toBe(#payloads)
			for _, reply in fx.replies do
				expect(reply.to):toBe(fx.attacker)
				expect(reply.payload.ok):toBe(false)
				expect(reply.payload.data):toBeNil()
			end
			expectNoMutations(fx)
			expect(fx.inventory.get(fx.targetData, "seed_padi")):toBe(itemsBefore)
		end)

		t:it("malformed command envelopes are refused without error and change nothing", function()
			local fx = makeAdmin()
			local bads = {
				42,
				"inspect",
				true,
				{},
				{ value = "kemarau" },
				{ action = 42 },
				{ action = "deleteAll" },
				{ action = "__index" },
				{ action = "" },
			}
			for _, bad in bads do
				local ok = pcall(fx.send, fx.admin, bad)
				expect(ok):toBe(true)
			end
			local ok = pcall(fx.send, fx.admin, nil)
			expect(ok):toBe(true)
			expect(#fx.replies):toBe(#bads + 1)
			for _, reply in fx.replies do
				expect(reply.to):toBe(fx.admin)
				expect(reply.payload.ok):toBe(false)
			end
			expectNoMutations(fx)
		end)

		t:it("invalid season, anomaly and chili-event values are refused and never reach LiveConfig", function()
			local fx = makeAdmin()
			for _, bad in { "salju", "Kemarau", "", 3, {}, true } do
				fx.send(fx.admin, { action = "setSeason", value = bad })
				fx.send(fx.admin, { action = "setAnomaly", value = bad })
			end
			fx.send(fx.admin, { action = "setSeason" })
			fx.send(fx.admin, { action = "setAnomaly" })
			for _, bad in { "elnino", "kiamat", 1, {} } do
				fx.send(fx.admin, { action = "setAnomaly", value = bad })
			end
			for _, bad in { "cabai", {}, { event = "pupuk", mode = "on" }, { event = "cabai", mode = "maybe" }, { event = "cabai", mode = 1 }, { event = "cabai" } } do
				fx.send(fx.admin, { action = "setEvent", value = bad })
			end
			expect(#fx.config.updates):toBe(0)
			for _, reply in fx.replies do
				expect(reply.payload.ok):toBe(false)
			end

			-- Valid values still work, so the refusals above come from the guard and not a broken handler.
			fx.send(fx.admin, { action = "setSeason", value = "auto" })
			fx.send(fx.admin, { action = "setAnomaly", value = "laNina" })
			fx.send(fx.admin, { action = "setEvent", value = { event = "cabai", mode = "off" } })
			expect(#fx.config.updates):toBe(3)
			expect(fx.config.updates[1].byUserId):toBe(fx.admin.UserId)
		end)

		t:it("grantItem refuses amounts outside 1..1000 and fractional, NaN or infinite counts", function()
			local fx = makeAdmin()
			local base = fx.inventory.get(fx.targetData, "seed_padi")
			local amounts = { 0, -1, 0.5, 1001, 0 / 0, math.huge, -math.huge, "5", true }
			for _, amount in amounts do
				fx.send(fx.admin, {
					action = "grantItem",
					value = { userId = fx.target.UserId, itemId = "seed_padi", amount = amount },
				})
			end
			fx.send(fx.admin, { action = "grantItem", value = { userId = fx.target.UserId, itemId = "seed_padi" } })
			expect(fx.inventory.get(fx.targetData, "seed_padi")):toBe(base)
			expect(fx.grants.synced):toBe(0)
			expect(lastReplyTo(fx, fx.admin).ok):toBe(false)

			fx.send(fx.admin, { action = "grantItem", value = { userId = fx.target.UserId, itemId = "seed_padi", amount = 1 } })
			fx.send(fx.admin, { action = "grantItem", value = { userId = fx.target.UserId, itemId = "seed_padi", amount = 1000 } })
			expect(fx.inventory.get(fx.targetData, "seed_padi")):toBe(base + 1001)
			expect(fx.grants.synced):toBe(2)
		end)

		t:it("grantItem refuses bad userId, unknown players and malformed itemId without error", function()
			local fx = makeAdmin()
			local base = fx.inventory.get(fx.targetData, "seed_padi")
			local bads = {
				{ userId = "1000", itemId = "seed_padi", amount = 1 },
				{ userId = 0 / 0, itemId = "seed_padi", amount = 1 },
				{ userId = 999999999, itemId = "seed_padi", amount = 1 },
				{ userId = nil, itemId = "seed_padi", amount = 1 },
				{ userId = fx.target.UserId, itemId = nil, amount = 1 },
				{ userId = fx.target.UserId, itemId = 7, amount = 1 },
				{ userId = fx.target.UserId, itemId = string.rep("x", 41), amount = 1 },
			}
			for _, bad in bads do
				local ok = pcall(fx.send, fx.admin, { action = "grantItem", value = bad })
				expect(ok):toBe(true)
			end
			local ok = pcall(fx.send, fx.admin, { action = "grantItem", value = "seed_padi" })
			expect(ok):toBe(true)
			expect(fx.inventory.get(fx.targetData, "seed_padi")):toBe(base)
			expect(#fx.grants.touched):toBe(0)
			expect(fx.grants.synced):toBe(0)
		end)

		t:it("grantItem refuses an itemId that is not a real item", function()
			-- AdminService.luau line 123 checks only type and length; Inventory.add (Inventory.luau
			-- line 21) stores any string. A typo or invented id lands in the save as a ghost item.
			local fx = makeAdmin()
			fx.send(fx.admin, {
				action = "grantItem",
				value = { userId = fx.target.UserId, itemId = "ghost_item_zzz", amount = 3 },
			})
			expect(fx.inventory.get(fx.targetData, "ghost_item_zzz")):toBe(0)
			expect(fx.grants.synced):toBe(0)
			expect(lastReplyTo(fx, fx.admin).ok):toBe(false)
		end)

		t:it("grantCash refuses amounts outside 1..10,000,000 and non-integers", function()
			local fx = makeAdmin()
			for _, amount in { 0, -5, 0.5, 0 / 0, math.huge, 10_000_001, 1e9, "100" } do
				fx.send(fx.admin, { action = "grantCash", value = { userId = fx.target.UserId, amount = amount } })
			end
			expect(#fx.grants.cash):toBe(0)
			fx.send(fx.admin, { action = "grantCash", value = { userId = fx.target.UserId, amount = 10_000_000 } })
			expect(#fx.grants.cash):toBe(1)
			expect(fx.grants.cash[1].amount):toBe(10_000_000)
			expect(fx.grants.cash[1].sku):toBe("admin_grant")
		end)

		t:it("a rate-limited admin command is dropped silently and runs nothing", function()
			local fx = makeAdmin({ allow = false })
			fx.send(fx.admin, { action = "setSeason", value = "kemarau" })
			fx.send(fx.admin, { action = "refresh" })
			fx.send(fx.admin, { action = "grantCash", value = { userId = fx.target.UserId, amount = 100 } })
			expect(#fx.replies):toBe(0)
			expectNoMutations(fx)
			expect(fx.rateLimit.calls[1]):toBe("Admin_Command")
		end)

		t:it("every reply, success or refusal, goes only to the calling admin", function()
			local fx = makeAdmin()
			local other = Fakes.player(fx.env, { name = "OtherAdmin" })
			fx.send(fx.admin, { action = "getConfig" })
			fx.send(fx.admin, { action = "setSeason", value = "nope" })
			fx.send(fx.admin, { action = "inspect", value = { userId = fx.target.UserId } })
			fx.send(fx.attacker, { action = "getConfig" })
			expect(#fx.replies):toBe(4)
			for _, reply in fx.replies do
				expect(reply.to ~= other):toBe(true)
				expect(reply.to ~= fx.target):toBe(true)
			end
			expect(lastReplyTo(fx, fx.target)):toBeNil()
		end)

		t:it("inspect of an offline or non-numeric userId is refused, and getConfig and refresh still answer", function()
			local fx = makeAdmin()
			fx.send(fx.admin, { action = "inspect", value = { userId = 123456789 } })
			fx.send(fx.admin, { action = "inspect", value = { userId = "1000" } })
			fx.send(fx.admin, { action = "inspect", value = nil })
			expect(#fx.replies):toBe(3)
			for _, reply in fx.replies do
				expect(reply.payload.ok):toBe(false)
				expect(reply.payload.data):toBeNil()
			end
			fx.send(fx.admin, { action = "getConfig" })
			expect(lastReplyTo(fx, fx.admin).ok):toBe(true)
			fx.send(fx.admin, { action = "refresh" })
			expect(fx.config.refreshes):toBe(1)
		end)
	end)

	t:describe("SeasonService failure paths", function()
		t:it("start publishes one finite Growth_ attribute per family, matching the live runtime", function()
			local fx = makeSeason({ wallTime = 1_700_000_000 })
			expectGrowthMatchesRuntime(fx)
			for _, familyId in fx.Crops.familyOrder do
				expect(isFinite(attrOf(fx, familyId))):toBe(true)
			end
		end)

		t:it("calling start twice leaves the same attributes and does not error", function()
			local fx = makeSeason({ wallTime = 1_700_000_000 })
			local before = {}
			for _, familyId in fx.Crops.familyOrder do
				before[familyId] = attrOf(fx, familyId)
			end
			fx.SeasonService.start()
			for _, familyId in fx.Crops.familyOrder do
				expect(attrOf(fx, familyId)):toBe(before[familyId])
			end
			expectGrowthMatchesRuntime(fx)
		end)

		t:it("an invalid season override keeps the last good season; a valid one takes effect", function()
			local fx = makeSeason({ wallTime = 1_700_000_000 })
			local calendar = fx.SeasonService.musim()
			expect(fx.Seasons.isMusim(calendar)):toBe(true)
			for _, bad in { "salju", 3, true, {} } do
				fx.LiveConfig.update({ seasonOverride = bad })
				expect(fx.SeasonService.musim()):toBe(calendar)
				expect(fx.LiveConfig.getRuntime().seasonSource):toBe("calendar")
			end
			expectGrowthMatchesRuntime(fx)

			fx.LiveConfig.update({ seasonOverride = "kemarau" })
			expect(fx.SeasonService.musim()):toBe("kemarau")
			expect(fx.LiveConfig.getRuntime().seasonSource):toBe("override")
			expectGrowthMatchesRuntime(fx)
		end)

		t:it("an unknown anomaly is dropped to none and leaves growth unchanged", function()
			local fx = makeSeason({ wallTime = 1_700_000_000 })
			local before = {}
			for _, familyId in fx.Crops.familyOrder do
				before[familyId] = attrOf(fx, familyId)
			end
			for _, bad in { "kiamat", "elnino", 1, {} } do
				fx.LiveConfig.update({ anomaly = bad })
				expect(fx.SeasonService.anomali()):toBe("none")
			end
			for _, familyId in fx.Crops.familyOrder do
				expect(attrOf(fx, familyId)):toBe(before[familyId])
			end

			fx.LiveConfig.update({ anomaly = "elNino" })
			expect(fx.SeasonService.anomali()):toBe("elNino")
			expectGrowthMatchesRuntime(fx)
		end)

		t:it("a NaN clock falls back to a valid season with finite growth", function()
			local fx = makeSeason({ wallTime = 1_700_000_000 })
			fx.env.wallTime = 0 / 0
			fx.LiveConfig.update({})
			expect(fx.Seasons.isMusim(fx.SeasonService.musim())):toBe(true)
			for _, familyId in fx.Crops.familyOrder do
				local growth = attrOf(fx, familyId)
				expect(isFinite(growth)):toBe(true)
				expect(growth >= 0.5 and growth <= 2):toBe(true)
			end
		end)

		t:it("a huge clock value falls back to a valid season with finite growth", function()
			local fx = makeSeason({ wallTime = 1_700_000_000 })
			for _, huge in { 1e15, math.huge, -1e15 } do
				fx.env.wallTime = huge
				fx.LiveConfig.update({})
				expect(fx.Seasons.isMusim(fx.SeasonService.musim())):toBe(true)
				for _, familyId in fx.Crops.familyOrder do
					expect(isFinite(attrOf(fx, familyId))):toBe(true)
				end
			end
		end)

		t:it("a rewound clock moves the calendar season back and republishes growth", function()
			-- 1_700_000_000 is mid-November (hujan); 1_690_000_000 is late July (kemarau).
			local fx = makeSeason({ wallTime = 1_700_000_000 })
			expect(fx.SeasonService.musim()):toBe("hujan")
			fx.env.wallTime = 1_690_000_000
			fx.LiveConfig.update({})
			expect(fx.SeasonService.musim()):toBe("kemarau")
			expectGrowthMatchesRuntime(fx)
		end)

		t:it("growSeconds floors at five seconds for NaN, negative and zero base times", function()
			local fx = makeSeason({ wallTime = 1_700_000_000 })
			local familyId = fx.Crops.familyOrder[1]
			for _, base in { 0 / 0, -100, 0, 1 } do
				local seconds = fx.SeasonService.growSeconds(base, familyId)
				expect(isFinite(seconds)):toBe(true)
				expect(seconds >= 5):toBe(true)
			end
		end)

		t:it("growth stays within 0.5..2 for every season and anomaly, and unknown families use the season base", function()
			local fx = makeSeason({ wallTime = 1_700_000_000 })
			for _, musim in fx.Seasons.musimOrder do
				for _, anomali in fx.Seasons.anomaliOrder do
					for _, familyId in fx.Crops.familyOrder do
						local growth = fx.Seasons.growth(musim, familyId, anomali)
						expect(growth >= 0.5 and growth <= 2):toBe(true)
					end
					local unknown = fx.Seasons.growth(musim, "no_such_family", anomali)
					expect(isFinite(unknown)):toBe(true)
				end
			end
			expect(fx.Seasons.growth("nonsense", nil, nil)):toBe(fx.Seasons.growth("pancaroba", nil, nil))
		end)
	end)
end
