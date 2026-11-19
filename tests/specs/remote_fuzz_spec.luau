--!nocheck
-- WORK_QUEUE round-2 item 15: REMOTE FUZZING.
-- Feed every client->server remote handler deterministic malformed payloads (wrong types,
-- NaN/inf, huge strings, deep/cyclic tables, nil) and assert:
--   1. no error escapes any handler, and
--   2. malformed payloads never corrupt a player's save data or attributes.
--
-- Real server services are loaded and started under the Env harness so their actual
-- OnServerEvent handlers are connected. Leaf infrastructure (profiles, notify, rate limit,
-- analytics, world, plot, live config) is mocked; every service start is pcall-guarded so a
-- mock gap in one service can never hide the sweep over the others. Coverage is asserted
-- non-vacuously: a floor of connected handlers must be observed before the sweep counts.

local fs = require("@lune/fs")

local function read(path: string): string
	return fs.readFile(path)
end

local function parseRemoteNames(): { string }
	local src = read("src/shared/Remotes.luau")
	local block = string.match(src, "local NAMES = {%s*(.-)%s*}[\r\n]+local Remotes") or ""
	local names = {}
	for line in string.gmatch(block, "[^\r\n]+") do
		local name = string.match(line, '^%s*"([A-Za-z0-9_]+)"')
		if name then
			table.insert(names, name)
		end
	end
	return names
end

-- These names sit under the "server -> client" comment in Remotes.luau but are actually
-- C->S handlers (the existing remote_audit_spec treats them the same way).
local S2C = {
	Notify = true,
	Minigame_Start = true,
	Minigame_Cancel = true,
	Evidence_Offer = true,
	Evidence_Token = true,
	Evidence_Remove = true,
	Leaderboard_Data = true,
	Raid_Start = true,
	Raid_End = true,
	Jail_State = true,
	State_Snapshot = true,
	State_Patch = true,
	Admin_Result = true,
	Harness_Result = true,
}

local function isC2S(name: string): boolean
	return not S2C[name]
end

return function(t, Env, Fakes)
	local expect = t.expect

	-- A permissive stub answers any method call with a no-op. Used only for cross-service
	-- dependencies that are not the fuzz target; it keeps a handler from throwing
	-- "attempt to call a nil value" for a dependency that is out of scope for this spec.
	local function permissive()
		return setmetatable({}, {
			__index = function(tbl, key)
				local fn = function() return nil end
				tbl[key] = fn
				return fn
			end,
		})
	end

	-- Deterministic argument lists. Deliberately avoid plausible-valid ids (e.g. "padi")
	-- so the no-state-change assertion is not confused by a legitimately accepted action.
	local function makePayloads()
		local cyclic = {}
		cyclic.self = cyclic
		cyclic.nested = { back = cyclic }

		local deep = {}
		local cursor = deep
		for _ = 1, 100 do
			cursor.next = {}
			cursor = cursor.next
		end
		deep.leaf = { cyclic = cyclic }

		local huge = string.rep("x", 10000)
		local nan = 0 / 0
		local inf = math.huge
		local ninf = -math.huge

		return {
			{}, -- no args
			{ nil },
			{ true },
			{ false },
			{ nan },
			{ inf },
			{ ninf },
			{ -1 },
			{ huge },
			{ "" },
			{ {} },
			{ deep },
			{ cyclic },
			{ "", nan },
			{ huge, inf },
			{ cyclic, {} },
			{ {}, {}, {}, {} },
			{ nan, ninf, huge, cyclic },
			{ true, false, nil, {} },
		}
	end

	-- Canonical, cycle-safe serialization of a save table for before/after comparison.
	local function snapshot(value)
		local seen = {}
		local out = {}
		local function write(v, depth)
			local kind = type(v)
			if kind == "number" then
				if v ~= v then
					out[#out + 1] = "NaN"
				elseif v == math.huge then
					out[#out + 1] = "+inf"
				elseif v == -math.huge then
					out[#out + 1] = "-inf"
				else
					out[#out + 1] = string.format("%.17g", v)
				end
			elseif kind == "string" then
				out[#out + 1] = "s" .. #v .. ":" .. (string.len(v) > 64 and v:sub(1, 64) or v)
			elseif kind == "boolean" then
				out[#out + 1] = tostring(v)
			elseif kind == "nil" then
				out[#out + 1] = "nil"
			elseif kind == "table" then
				if seen[v] then
					out[#out + 1] = "<cycle>"
					return
				end
				if depth >= 8 then
					out[#out + 1] = "<deep>"
					return
				end
				seen[v] = true
				out[#out + 1] = "{"
				local keys = {}
				for k in pairs(v) do
					table.insert(keys, k)
				end
				table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
				for _, k in keys do
					write(k, depth + 1)
					out[#out + 1] = "="
					write(v[k], depth + 1)
					out[#out + 1] = ";"
				end
				out[#out + 1] = "}"
			else
				out[#out + 1] = kind
			end
		end
		write(value, 0)
		return table.concat(out)
	end

	local function attributeSnapshot(player)
		local attrs = player._attributes or {}
		local keys = {}
		for k in pairs(attrs) do
			table.insert(keys, tostring(k))
		end
		table.sort(keys)
		local parts = {}
		for _, k in keys do
			parts[#parts + 1] = k .. "=" .. tostring(attrs[k])
		end
		return table.concat(parts, "|")
	end

	local function makeFuzzWorld()
		local env = Env.new()
		-- Many start() calls own `while true do task.wait() end` loops via task.spawn;
		-- a no-op keeps the sweep deterministic and finite.
		env.globals.task.spawn = function() end

		-- World-building globals used by visual helpers in some handlers/callbacks.
		local cf = setmetatable({}, { __mul = function() return cf end })
		env.globals.CFrame = { new = function() return cf end }
		env.globals.Instance = { new = function(className)
			local node = { Name = className, _children = {}, _attributes = {}, CFrame = cf }
			function node:SetAttribute(key, val) self._attributes[key] = val end
			function node:GetAttribute(key) return self._attributes[key] end
			function node:FindFirstChild() return nil end
			function node:Destroy() end
			return node
		end }
		if env.globals.Color3 then
			env.globals.Color3.fromHex = function() return {} end
		end
		if env.globals.Vector3 then
			local vectorMeta = getmetatable(env.Vector3.new(0, 0, 0))
			if vectorMeta then
				vectorMeta.__mul = function(a, b)
					return env.Vector3.new(a.X * b, a.Y * b, a.Z * b)
				end
			end
		end

		local remotes = Fakes.remotes(env)
		local playerData = Fakes.playerData()
		env:mock("shared/Remotes", remotes)
		env:mock("server/Data/PlayerData", playerData)
		env:mock("server/Net/Notify", Fakes.notify())
		env:mock("server/Net/RateLimit", Fakes.rateLimit(true))
		env:mock("server/Analytics/Analytics", Fakes.analytics())
		env:mock("server/World/Village", setmetatable({
			getPosition = function() return env.Vector3.new(0, 0, 0) end,
			onPasar = function() end,
			onReport = function() end,
			build = function() end,
		}, { __index = permissive() }))
		env:mock("server/Farm/PlotService", setmetatable({
			getPlotOf = function() return nil end,
			onTilePrompt = function() end,
			build = function() end,
			teleportToPlot = function() end,
		}, { __index = permissive() }))
		env:mock("server/Live/LiveConfig", {
			get = function() return { seasonOverride = "auto", anomaly = "none" } end,
			getRuntime = function() return { musim = "kemarau", anomali = "none" } end,
			update = function() end,
			refresh = function() end,
			onChanged = function() end,
		})
		env:mock("server/Live/Admins", { isAdmin = function() return false end })
		local guidCounter = 0
		env.services.HttpService = {
			GenerateGUID = function()
				guidCounter += 1
				return "fuzz-guid-" .. guidCounter
			end,
		}
		env.services.MarketplaceService.PromptGamePassPurchaseFinished = env.newSignal()
		env:mock("server/Progression/BadgeService", permissive())
		env:mock("server/Progression/RankService", permissive())

		-- Load + start every handler-owning service. Each is isolated in pcall so a mock
		-- gap in one service can never abort the sweep of the others.
		local started, failed, mods = {}, {}, {}
		local function boot(path, after)
			local ok, result = pcall(function()
				local mod = env:require(path)
				mods[path] = mod
				if after then after(mod) end
				if type(mod.start) == "function" then mod.start() end
				return mod
			end)
			if ok then
				table.insert(started, path)
			else
				table.insert(failed, path .. ": " .. tostring(result))
			end
		end

		boot("server/Net/State")
		boot("server/Economy/EconomyService")
		boot("server/Economy/MarketService")
		boot("server/Economy/ShopService")
		boot("server/Farm/ToolService")
		boot("server/Farm/StorageService")
		boot("server/Farm/FarmService")
		boot("server/Farm/WorkerService")
		boot("server/Progression/RankService")
		boot("server/Law/SusService")
		boot("server/Law/CheatService")
		boot("server/Law/EvidenceService")
		boot("server/Law/BribeService")
		boot("server/Law/RaidService", function(mod)
			if type(mod.bindSus) == "function" then
				mod.bindSus({ set = function() end, add = function() end })
			end
			if type(mod.init) == "function" then mod.init() end
		end)
		boot("server/Progression/NeighborService")
		boot("server/Progression/OnboardingService")
		boot("server/Progression/FirstSession")
		boot("server/Progression/QuestService")
		boot("server/Economy/DebtService", function(mod)
			if type(mod.bindRaid) == "function" then
				mod.bindRaid({ isBusy = function() return false end })
			end
			if type(mod.bindCollector) == "function" then
				mod.bindCollector({ summon = function() end, dismiss = function() end })
			end
		end)
		boot("server/World/WarungService")
		boot("server/Events/CabaiEvent")
		boot("server/Monetization/Passes")
		boot("server/Monetization/Receipts")
		boot("server/Monetization/Items")
		boot("server/Monetization/Cosmetics")
		boot("server/Social/LeaderboardService")
		boot("server/Live/AdminService")
		boot("server/Testing/Harness")

		-- RemoteGuards owns the otherwise-unhandled trade/event remotes.
		boot("server/Net/RemoteGuards", function(mod)
			-- start(remotes, rateLimit) is called explicitly below; do nothing here.
		end)
		local rateLimit = Fakes.rateLimit(true)
		pcall(function() env:require("server/Net/RemoteGuards").start(remotes, rateLimit) end)

		local player = Fakes.player(env)
		playerData.set(player, Fakes.newData(env))

		return {
			env = env, remotes = remotes, playerData = playerData, player = player,
			started = started, failed = failed, mods = mods,
		}
	end

	-- A fresh save has only the TEMPLATE fields; service ensure()/sync() functions fill in
	-- derived fields (debt.stage, quest daily rollover, cosmetic attributes) on first touch.
	-- Drive every such normalizer to a fixed point BEFORE the state snapshots so the strict
	-- "malformed payload changed nothing" assertion measures the fuzz, not first-use schema
	-- settlement (which is expected and is covered by its own specs).
	local function settleSchema(w)
		local data = w.playerData.get(w.player)
		for _ = 1, 6 do
			local before = snapshot(data)
			for _, mod in pairs(w.mods) do
				if type(mod.ensure) == "function" then pcall(mod.ensure, data) end
				if type(mod.sync) == "function" then pcall(mod.sync, w.player) end
			end
			if snapshot(data) == before then break end
		end
	end

	-- Count connected handlers for every C->S remote.
	local function coverage(world)
		local handlers = {}
		local total = 0
		for _, name in ipairs(parseRemoteNames()) do
			if isC2S(name) then
				local remote = world.remotes[name]
				local count = remote and remote.OnServerEvent and #remote.OnServerEvent._handlers or 0
				handlers[name] = count
				total += count
			end
		end
		return handlers, total
	end

	t:describe("Remote fuzzing (round-2 item 15)", function()
		t:it("connects a non-vacuous set of real C->S handlers", function()
			local w = makeFuzzWorld()
			local handlers, total = coverage(w)
			expect(total >= 20):toBe(true)
			local covered = 0
			for _, n in pairs(handlers) do
				if n > 0 then covered += 1 end
			end
			expect(covered >= 18):toBe(true)
		end)

		t:it("no malformed payload makes any handler throw", function()
			local w = makeFuzzWorld()
			local handlers, _ = coverage(w)
			local payloads = makePayloads()
			local fired = 0
			local failures = {}
			for _, name in ipairs(parseRemoteNames()) do
				if isC2S(name) and (handlers[name] or 0) > 0 then
					local remote = w.remotes[name]
					for i, args in ipairs(payloads) do
						fired += 1
						local ok, err = pcall(function()
							remote.OnServerEvent:Fire(w.player, table.unpack(args, 1, #args))
						end)
						if not ok then
							table.insert(failures, name .. " payload#" .. i .. ": " .. tostring(err))
						end
					end
				end
			end
			expect(fired > 0):toBe(true)
			if #failures > 0 then
				error("remote fuzz threw:\n" .. table.concat(failures, "\n"))
			end
			expect(true):toBe(true)
		end)

		t:it("malformed payloads never corrupt save data or attributes", function()
			-- No-arg action remotes legitimately act when fired at all (Worker_Hire,
			-- Storage_Deposit/Withdraw, State_Request, Quest_ClaimDaily, Bribe_RT,
			-- Admin_Command, Harness_Command, Trade_Request/Respond/Event_Claim). They are
			-- still swept by the no-throw case above; state invariance is asserted for the
			-- typed-argument remotes where malformed values must simply be refused.
			local actionOnly = {
				Worker_Hire = true, Storage_Deposit = true, Storage_Withdraw = true,
				State_Request = true, Quest_ClaimDaily = true, Bribe_RT = true,
				Admin_Command = true, Harness_Command = true,
				Trade_Request = true, Trade_Respond = true, Event_Claim = true,
			}

			local w = makeFuzzWorld()
			settleSchema(w)
			local handlers, _ = coverage(w)
			local payloads = makePayloads()
			local checked = 0
			local failures = {}
			for _, name in ipairs(parseRemoteNames()) do
				if isC2S(name) and not actionOnly[name] and (handlers[name] or 0) > 0 then
					local remote = w.remotes[name]
					for i, args in ipairs(payloads) do
						local before = snapshot(w.playerData.get(w.player))
						local attrsBefore = attributeSnapshot(w.player)
						local ok = pcall(function()
							remote.OnServerEvent:Fire(w.player, table.unpack(args, 1, #args))
						end)
						checked += 1
						if not ok then
							table.insert(failures, name .. " payload#" .. i .. " errored")
						end
						local after = snapshot(w.playerData.get(w.player))
						local attrsAfter = attributeSnapshot(w.player)
						if before ~= after then
							table.insert(failures, name .. " payload#" .. i .. " changed save data")
						end
						if attrsBefore ~= attrsAfter then
							table.insert(failures, name .. " payload#" .. i .. " changed attributes")
						end
					end
				end
			end
			expect(checked > 0):toBe(true)
			if #failures > 0 then
				error("remote fuzz mutated state:\n" .. table.concat(failures, "\n"))
			end
			expect(true):toBe(true)
		end)
	end)
end
