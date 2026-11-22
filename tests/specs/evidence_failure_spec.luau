--!nocheck
-- EvidenceService failure-path specs (Lapor and VIRAL). A refused record or report never pays,
-- never adds Nama Baik or Sus and never starts a raid; a cheat event pays its reporter at most
-- once; a damaged save or a NaN or negative value never errors and never pays out.
-- Tests whose name starts with "[BUG]" are expected to fail: they reveal real defects (see the
-- report that accompanies this spec). Do not edit EvidenceService to make them pass in this file.
-- EconomyService.transfer is mocked with the same guards as the real function
-- (EconomyService.luau lines 129-143).

return function(t, Env, Fakes)
	local expect = t.expect

	local function isFinite(n)
		return type(n) == "number" and n == n and n > -math.huge and n < math.huge
	end

	local function makeEvidence()
		local env = Env.new()
		local playerData = Fakes.playerData()
		local notify = Fakes.notify()
		local remotes = Fakes.remotes(env)
		local rateLimit = Fakes.rateLimit(true)
		local log = { offers = {}, tokens = {}, removes = {}, transfers = {}, namaBaik = {}, sus = {}, raids = {} }
		local guids = 0
		env.services.HttpService = {
			GenerateGUID = function()
				guids += 1
				return `guid-{guids}`
			end,
		}

		env:mock("shared/Remotes", remotes)
		env:mock("server/Data/PlayerData", playerData)
		env:mock("server/Net/Notify", notify)
		env:mock("server/Net/RateLimit", rateLimit)
		env:mock("server/Analytics/Analytics", Fakes.analytics())
		env:mock("server/Economy/EconomyService", {
			transfer = function(from, to, amount, sku)
				local fromData = playerData.get(from)
				local toData = playerData.get(to)
				if not fromData or not toData or not isFinite(amount) then
					return 0
				end
				local moved = math.clamp(math.floor(amount), 0, fromData.cash)
				if moved <= 0 then
					return 0
				end
				fromData.cash -= moved
				toData.cash += moved
				table.insert(log.transfers, { from = from, to = to, amount = amount, moved = moved, sku = sku })
				return moved
			end,
		})
		env:mock("server/Progression/RankService", {
			addNamaBaik = function(player, amount)
				table.insert(log.namaBaik, { player = player, amount = amount })
			end,
		})
		env:mock("server/Law/SusService", {
			add = function(player, amount)
				table.insert(log.sus, { player = player, amount = amount })
			end,
		})
		env:mock("server/Law/RaidService", {
			start = function(player, isViral)
				table.insert(log.raids, { player = player, isViral = isViral })
			end,
		})
		env:mock("server/World/Village", {
			getPosition = function()
				return env.Vector3.new(0, 0, 0) -- the Pos Polisi sits at the origin
			end,
			onReport = function() end,
		})

		-- start() runs an expiry loop through task.spawn; a no-op keeps each test deterministic.
		env.globals.task.spawn = function() end
		local EvidenceService = env:require("server/Law/EvidenceService")
		EvidenceService.start()

		remotes.Evidence_Offer.FireClient = function(_, player, eventId)
			table.insert(log.offers, { player = player, eventId = eventId })
		end
		remotes.Evidence_Token.FireClient = function(_, player, tokenId)
			table.insert(log.tokens, { player = player, tokenId = tokenId })
		end
		remotes.Evidence_Remove.FireClient = function(_, player, tokenId)
			table.insert(log.removes, { player = player, tokenId = tokenId })
		end

		local cheater = Fakes.player(env, { position = env.Vector3.new(5, 0, 0) })
		local reporter = Fakes.player(env, { position = env.Vector3.new(0, 0, 0) })
		local witness = Fakes.player(env, { position = env.Vector3.new(10, 0, 0) })
		local far = Fakes.player(env, { position = env.Vector3.new(100, 0, 0) })
		local cheaterData = playerData.set(cheater, Fakes.newData(env))
		cheaterData.cash = 200
		playerData.set(reporter, Fakes.newData(env))
		playerData.set(witness, Fakes.newData(env))
		playerData.set(far, Fakes.newData(env))

		return {
			env = env,
			EvidenceService = EvidenceService,
			players = env.services.Players,
			cheater = cheater,
			cheaterData = cheaterData,
			reporter = reporter,
			witness = witness,
			far = far,
			playerData = playerData,
			notify = notify,
			remotes = remotes,
			rateLimit = rateLimit,
			log = log,
			Law = env:require("shared/Config/Law"),
		}
	end

	-- Latest event id offered to `player`, or nil.
	local function offerTo(fx, player)
		for i = #fx.log.offers, 1, -1 do
			if fx.log.offers[i].player == player then
				return fx.log.offers[i].eventId
			end
		end
		return nil
	end

	-- Latest token handed to `player`, or nil.
	local function tokenTo(fx, player)
		for i = #fx.log.tokens, 1, -1 do
			if fx.log.tokens[i].player == player then
				return fx.log.tokens[i].tokenId
			end
		end
		return nil
	end

	local function recordEvent(fx, player, eventId)
		fx.remotes.Evidence_Record.OnServerEvent:Fire(player, eventId)
	end

	local function reportToken(fx, player, tokenId)
		fx.remotes.Evidence_Report.OnServerEvent:Fire(player, tokenId)
	end

	-- A new cheat by fx.cheater. Witnesses within the radius are offered it.
	local function newCase(fx, value, victim)
		fx.EvidenceService.logCheat(fx.cheater, "curi_air", value, nil, victim)
	end

	-- A new cheat that `player` witnesses: they record the offer and get a token back.
	local function witnessed(fx, player, value)
		newCase(fx, value or 100)
		recordEvent(fx, player, offerTo(fx, player))
		return tokenTo(fx, player)
	end

	t:describe("EvidenceService failure paths", function()
		t:it("bad remote args are ignored, and a valid offer survives them", function()
			local fx = makeEvidence()
			newCase(fx, 100)
			local eventId = offerTo(fx, fx.reporter)
			recordEvent(fx, fx.reporter, nil)
			reportToken(fx, fx.reporter, nil)
			for _, bad in { 42, {}, true, 0 / 0 } do
				recordEvent(fx, fx.reporter, bad)
				reportToken(fx, fx.reporter, bad)
			end
			expect(#fx.log.tokens):toBe(0)
			expect(#fx.log.transfers):toBe(0)
			expect(fx.cheaterData.cash):toBe(200)
			-- the bad calls did not spend the offer, so the real id still works
			recordEvent(fx, fx.reporter, eventId)
			expect(#fx.log.tokens):toBe(1)
		end)

		t:it("unknown event and token ids grant nothing; reporting an unknown token says it is gone", function()
			local fx = makeEvidence()
			recordEvent(fx, fx.reporter, "not-a-real-event")
			reportToken(fx, fx.reporter, "not-a-real-token")
			expect(#fx.log.tokens):toBe(0)
			expect(#fx.log.transfers):toBe(0)
			expect(fx.notify.last().key):toBe("n_token_gone")
		end)

		t:it("the cheater is never offered their own cheat and cannot record it, even as the victim", function()
			local fx = makeEvidence()
			newCase(fx, 100, fx.cheater)
			expect(offerTo(fx, fx.cheater)):toBeNil()
			recordEvent(fx, fx.cheater, offerTo(fx, fx.reporter))
			expect(#fx.log.tokens):toBe(0)
			expect(#fx.log.transfers):toBe(0)
			expect(fx.cheaterData.stats.timesReported or 0):toBe(0)
		end)

		t:it("a player without an offer cannot record, and cannot report someone else's token", function()
			local fx = makeEvidence()
			newCase(fx, 100)
			recordEvent(fx, fx.far, offerTo(fx, fx.reporter))
			expect(#fx.log.tokens):toBe(0)

			recordEvent(fx, fx.witness, offerTo(fx, fx.witness))
			local witnessToken = tokenTo(fx, fx.witness)
			reportToken(fx, fx.reporter, witnessToken)
			expect(#fx.log.transfers):toBe(0)
			expect(fx.notify.last().key):toBe("n_token_gone")

			reportToken(fx, fx.witness, witnessToken)
			expect(#fx.log.transfers):toBe(1)
			expect(fx.log.transfers[1].to):toBe(fx.witness)
		end)

		t:it("witnesses inside the evidence radius get an offer; a far player does not, but a far victim always does", function()
			local fx = makeEvidence()
			newCase(fx, 100)
			expect(offerTo(fx, fx.witness) ~= nil):toBe(true)
			expect(offerTo(fx, fx.far)):toBeNil()
			fx.EvidenceService.logCheat(fx.cheater, "curi_air", 100, nil, fx.far)
			expect(offerTo(fx, fx.far) ~= nil):toBe(true)
		end)

		t:it("reporting from outside the police radius is refused and keeps the token for a retry", function()
			local fx = makeEvidence()
			local token = witnessed(fx, fx.reporter, 100)
			fx.reporter.Character.HumanoidRootPart.Position = fx.env.Vector3.new(200, 0, 0)
			reportToken(fx, fx.reporter, token)
			expect(fx.notify.last().key):toBe("n_report_near")
			expect(#fx.log.transfers):toBe(0)

			fx.reporter.Character.HumanoidRootPart.Position = fx.env.Vector3.new(0, 0, 0)
			reportToken(fx, fx.reporter, token)
			expect(#fx.log.transfers):toBe(1)
		end)

		t:it("a report during the cooldown is refused and keeps its token until the cooldown ends", function()
			local fx = makeEvidence()
			reportToken(fx, fx.reporter, witnessed(fx, fx.reporter, 100))
			local second = witnessed(fx, fx.reporter, 100)
			reportToken(fx, fx.reporter, second)
			expect(fx.notify.last().key):toBe("n_report_cooldown")
			expect(#fx.log.transfers):toBe(1)

			fx.env:advance(fx.Law.reportCooldown + 1)
			reportToken(fx, fx.reporter, second)
			expect(#fx.log.transfers):toBe(2)
		end)

		t:it("rate-limited record and report calls do nothing, and the same calls work once the limit clears", function()
			local fx = makeEvidence()
			newCase(fx, 100)
			local eventId = offerTo(fx, fx.reporter)
			fx.rateLimit.allow = function()
				return false
			end
			recordEvent(fx, fx.reporter, eventId)
			expect(#fx.log.tokens):toBe(0)

			fx.rateLimit.allow = function()
				return true
			end
			recordEvent(fx, fx.reporter, eventId)
			expect(#fx.log.tokens):toBe(1)

			fx.rateLimit.allow = function()
				return false
			end
			reportToken(fx, fx.reporter, tokenTo(fx, fx.reporter))
			expect(#fx.log.transfers):toBe(0)
			expect(#fx.log.removes):toBe(0)
		end)

		t:it("a cheater who left pays nothing: the token is dropped, with no cooldown, Nama Baik or Sus", function()
			local fx = makeEvidence()
			local token = witnessed(fx, fx.reporter, 100)
			for i, player in fx.players._players do
				if player == fx.cheater then
					table.remove(fx.players._players, i)
					break
				end
			end
			reportToken(fx, fx.reporter, token)
			expect(#fx.log.transfers):toBe(0)
			expect(#fx.log.namaBaik):toBe(0)
			expect(#fx.log.sus):toBe(0)
			expect(#fx.log.removes):toBe(1)
			expect(fx.notify.last().key):toBe("n_token_expired")
			expect(fx.playerData.get(fx.reporter).cooldowns.reportReadyAt):toBeNil()
		end)

		t:it("an expired token or an expired offer pays nothing and is not recorded", function()
			local fx = makeEvidence()
			local token = witnessed(fx, fx.reporter, 100)
			fx.env:advance(181)
			reportToken(fx, fx.reporter, token)
			expect(#fx.log.transfers):toBe(0)
			expect(fx.notify.last().key):toBe("n_token_expired")

			newCase(fx, 100)
			local eventId = offerTo(fx, fx.witness)
			fx.env:advance(181)
			recordEvent(fx, fx.witness, eventId)
			expect(#fx.log.tokens):toBe(1)
		end)

		t:it("the first reporter is paid once, Nama Baik and Sus land once, and later reports pay nothing more", function()
			local fx = makeEvidence()
			newCase(fx, 100)
			local reporterBefore = fx.playerData.get(fx.reporter).cash
			local witnessBefore = fx.playerData.get(fx.witness).cash

			recordEvent(fx, fx.reporter, offerTo(fx, fx.reporter))
			reportToken(fx, fx.reporter, tokenTo(fx, fx.reporter))
			recordEvent(fx, fx.witness, offerTo(fx, fx.witness))
			reportToken(fx, fx.witness, tokenTo(fx, fx.witness))

			expect(#fx.log.transfers):toBe(1)
			expect(fx.log.transfers[1].moved):toBe(50)
			expect(fx.cheaterData.cash):toBe(150)
			expect(fx.playerData.get(fx.reporter).cash - reporterBefore):toBe(50)
			expect(fx.playerData.get(fx.witness).cash):toBe(witnessBefore)
			expect(#fx.log.namaBaik):toBe(1)
			expect(fx.log.namaBaik[1].amount):toBe(fx.Law.namaBaikPerReport)
			expect(#fx.log.sus):toBe(1)
			expect(fx.log.sus[1].amount):toBe(fx.Law.cheaterSusPerReport)
			expect(fx.cheaterData.stats.timesReported):toBe(2)
			expect(fx.playerData.get(fx.reporter).stats.reportsMade):toBe(1)
			expect(fx.playerData.get(fx.witness).stats.reportsMade):toBe(1)
		end)

		t:it("two different reporters inside the viral window start one viral raid; one reporter twice does not", function()
			local fx = makeEvidence()
			reportToken(fx, fx.reporter, witnessed(fx, fx.reporter, 100))
			expect(#fx.log.raids):toBe(0)

			fx.env:advance(fx.Law.reportCooldown + 1)
			reportToken(fx, fx.reporter, witnessed(fx, fx.reporter, 100))
			expect(#fx.log.raids):toBe(0)

			reportToken(fx, fx.witness, witnessed(fx, fx.witness, 100))
			expect(#fx.log.raids):toBe(1)
			expect(fx.log.raids[1].player):toBe(fx.cheater)
			expect(fx.log.raids[1].isViral):toBe(true)
		end)

		t:it("a reporter whose save has no cooldowns table is repaired, paid once and put on cooldown", function()
			local fx = makeEvidence()
			local token = witnessed(fx, fx.reporter, 100)
			fx.playerData.get(fx.reporter).cooldowns = nil
			local ok = pcall(reportToken, fx, fx.reporter, token)
			expect(ok):toBe(true)
			expect(#fx.log.transfers):toBe(1)
			expect(type(fx.playerData.get(fx.reporter).cooldowns)):toBe("table")
		end)

		t:it("a cheat logged against a save with no stats table does not error", function()
			local fx = makeEvidence()
			fx.cheaterData.stats = nil
			local ok = pcall(newCase, fx, 100)
			expect(ok):toBe(true)
		end)

		t:it("NaN or negative cheat values pay nothing, and the cheater's cash never becomes NaN or negative", function()
			local fx = makeEvidence()
			local reporterBefore = fx.playerData.get(fx.reporter).cash
			for _, bad in { -5, 0 / 0, -math.huge } do
				fx.env:advance(fx.Law.reportCooldown + 1)
				reportToken(fx, fx.reporter, witnessed(fx, fx.reporter, bad))
			end
			for _, transfer in fx.log.transfers do
				expect(isFinite(transfer.moved)):toBe(true)
				expect(transfer.moved > 0):toBe(true)
			end
			expect(#fx.log.transfers):toBe(0)
			expect(fx.cheaterData.cash == fx.cheaterData.cash):toBe(true)
			expect(fx.cheaterData.cash >= 0):toBe(true)
			expect(fx.playerData.get(fx.reporter).cash):toBe(reporterBefore)
		end)
	end)
end
