--!nocheck
-- Reusable fakes for tests: players, save data, and recorders for Notify / Analytics / Remotes.

local Fakes = {}

local nextUserId = 1000

-- A fake Player with attributes and a character standing at `position`.
function Fakes.player(env, options: { name: string?, position: any?, attributes: { [string]: any }? }?)
	options = options or {}
	nextUserId += 1
	local position = options.position or env.Vector3.new(0, 0, 0)
	local attributes = {}
	for key, value in options.attributes or {} do
		attributes[key] = value
	end

	local root = { Position = position }
	local character = {
		HumanoidRootPart = root,
		FindFirstChild = function(self, name)
			return self[name]
		end,
	}
	local player = {
		Name = options.name or ("Player" .. nextUserId),
		UserId = nextUserId,
		Character = character,
		Parent = env.services.Players,
		_attributes = attributes,
		SetAttribute = function(self, key, value)
			self._attributes[key] = value
		end,
		GetAttribute = function(self, key)
			return self._attributes[key]
		end,
		Kick = function(self, reason)
			self.kicked = reason
		end,
	}
	table.insert(env.services.Players._players, player)
	return player
end

-- Fresh save data with the same defaults as PlayerData's TEMPLATE, built from the real config.
function Fakes.newData(env)
	local Game = env:require("shared/Config/Game")
	local Law = env:require("shared/Config/Law")
	local items = { amplopPremium = 0, jaminanKilat = 0 }
	for cropId, count in Game.startSeeds do
		items["seed_" .. cropId] = count
	end
	return {
		version = 3,
		cash = Game.startCash,
		lifetimeEarned = 0,
		tilesOwned = Game.startTiles,
		tiles = {},
		produce = {},
		items = items,
		tools = {},
		shop = { cycle = 0, restockAt = 0, musim = "", stock = {} },
		worker = { hiredUntil = 0 },
		gudang = { capacity = Game.gudangBaseCapacity, stacks = {} },
		debt = { active = false, principal = 0, owed = 0, takenAt = 0, dueAt = 0 },
		quests = { daily = {}, loginStreak = 0, lastLoginDay = 0 },
		almanak = {},
		story = { chapter = 0, flags = {} },
		tutorial = { step = 1, done = {} },
		housing = {},
		prestige = { level = 0 },
		sus = 0,
		namaBaik = Law.namaBaikStart,
		rank = "gurem",
		timesElected = 0,
		cooldowns = {},
		cosmetics = {},
		equipped = {},
		stats = { raids = 0, reportsMade = 0, timesReported = 0, cheats = 0 },
		receipts = {},
	}
end

-- PlayerData stand-in: `fake.set(player, data)` registers a player.
function Fakes.playerData()
	local datas = {}
	local profiles = {}
	local fake = {
		confirmSaves = true, -- flip to false to simulate a failed save
		saveCalls = {},
	}
	function fake.get(player)
		return datas[player]
	end
	function fake.getProfile(player)
		return profiles[player]
	end
	function fake.onLoaded() end
	function fake.onBeforeRelease() end
	function fake.saveAndConfirm(profile, purchaseId, timeout)
		table.insert(fake.saveCalls, { profile = profile, purchaseId = purchaseId, timeout = timeout })
		return fake.confirmSaves
	end
	function fake.set(player, data)
		datas[player] = data
		profiles[player] = { Data = data, IsActive = function() return true end }
		return data
	end
	return fake
end

-- Notify stand-in that records every toast: { player, key, args }.
function Fakes.notify()
	local fake = { sent = {}, broadcasts = {} }
	function fake.send(player, key, ...)
		table.insert(fake.sent, { player = player, key = key, args = table.pack(...) })
	end
	function fake.broadcast(key, ...)
		table.insert(fake.broadcasts, { key = key, args = table.pack(...) })
	end
	function fake.keys(player)
		local keys = {}
		for _, item in fake.sent do
			if player == nil or item.player == player then
				table.insert(keys, item.key)
			end
		end
		return keys
	end
	function fake.last()
		return fake.sent[#fake.sent]
	end
	return fake
end

function Fakes.analytics()
	local fake = { events = {} }
	function fake.log(player, name, value)
		table.insert(fake.events, { player = player, name = name, value = value })
	end
	return fake
end

-- Remotes stand-in: any remote name gives a RemoteEvent-like object.
function Fakes.remotes(env)
	local created = {}
	return setmetatable({}, {
		__index = function(_, name)
			if not created[name] then
				created[name] = {
					OnServerEvent = env.newSignal(),
					FireClient = function() end,
					FireAllClients = function() end,
				}
			end
			return created[name]
		end,
	})
end

-- A RateLimit that always allows (or denies) so a test can focus on the rule under test.
function Fakes.rateLimit(allow: boolean?)
	local fake = { calls = {} }
	function fake.allow(_, key)
		table.insert(fake.calls, key)
		return allow ~= false
	end
	return fake
end

return Fakes
