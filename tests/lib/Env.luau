--!nocheck
-- Fake Roblox environment so the REAL game modules in src/ can run under Lune.
--
-- * Builds a tree of fake Instances from the files in src/ (same layout as default.project.json).
-- * Each module is loaded with its own `script`, plus fake `game`, `task`, `os`, `Vector3`, ...
-- * Dependencies can be replaced per test:   env:mock("server/Net/Notify", fakeNotify)
-- * Time is fake:                            env:advance(seconds)
--
-- Run from the repository root (paths below are relative to it).

local fs = require("@lune/fs")
local luau = require("@lune/luau")

local Env = {}
Env.__index = Env

local SRC = "src"

-- ---------------------------------------------------------------------------
-- Signals and instances
-- ---------------------------------------------------------------------------

local function newSignal()
	local signal = { _handlers = {} }
	function signal:Connect(handler)
		table.insert(self._handlers, handler)
		return {
			Disconnect = function()
				local index = table.find(self._handlers, handler)
				if index then
					table.remove(self._handlers, index)
				end
			end,
		}
	end
	function signal:Fire(...)
		for _, handler in table.clone(self._handlers) do
			handler(...)
		end
	end
	return signal
end

local nodeMethods = {}

function nodeMethods.WaitForChild(self, name)
	local child = rawget(self, "_children")[name]
	assert(child, `WaitForChild("{name}") would hang forever: "{rawget(self, "Name")}" has no such child`)
	return child
end

function nodeMethods.FindFirstChild(self, name)
	return rawget(self, "_children")[name]
end

function nodeMethods.GetChildren(self)
	local list = {}
	for _, child in rawget(self, "_children") do
		table.insert(list, child)
	end
	return list
end

function nodeMethods.SetAttribute(self, name, value)
	rawget(self, "_attributes")[name] = value
end

function nodeMethods.GetAttribute(self, name)
	return rawget(self, "_attributes")[name]
end

local nodeMeta = {}
function nodeMeta.__index(self, key)
	local child = rawget(self, "_children")[key]
	if child ~= nil then
		return child
	end
	return nodeMethods[key]
end

local function newNode(name: string, className: string, parent)
	local node = setmetatable({
		Name = name,
		ClassName = className,
		Parent = parent,
		_children = {},
		_attributes = {},
	}, nodeMeta)
	if parent then
		rawget(parent, "_children")[name] = node
	end
	return node
end

-- Walk a directory of .luau files into Folder / ModuleScript nodes.
-- Scripts (.server / .client / .spec) are not modules and are skipped.
local function mountDirectory(path: string, node)
	for _, entry in fs.readDir(path) do
		local full = path .. "/" .. entry
		if fs.isDir(full) then
			mountDirectory(full, newNode(entry, "Folder", node))
		elseif string.match(entry, "%.luau$") and not string.match(entry, "%.server%.luau$") and not string.match(entry, "%.client%.luau$") then
			local name = string.gsub(entry, "%.luau$", "")
			local module = newNode(name, "ModuleScript", node)
			rawset(module, "_path", full)
		end
	end
end

-- ---------------------------------------------------------------------------
-- Roblox value types (only what the game code touches at runtime)
-- ---------------------------------------------------------------------------

local Vector3 = {}
local vectorMeta = {}
vectorMeta.__index = function(self, key)
	if key == "Magnitude" then
		return math.sqrt(self.X ^ 2 + self.Y ^ 2 + self.Z ^ 2)
	end
	return nil
end
vectorMeta.__sub = function(a, b)
	return Vector3.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z)
end
vectorMeta.__add = function(a, b)
	return Vector3.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z)
end
function Vector3.new(x: number?, y: number?, z: number?)
	return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, vectorMeta)
end

local Color3 = {
	fromRGB = function(r, g, b)
		return { R = r / 255, G = g / 255, B = b / 255 }
	end,
	new = function(r, g, b)
		return { R = r, G = g, B = b }
	end,
}

-- Enum.X.Y evaluates to the string "X.Y" so tests can compare it directly.
local Enum = setmetatable({}, {
	__index = function(_, enumName)
		return setmetatable({}, {
			__index = function(_, itemName)
				return `{enumName}.{itemName}`
			end,
		})
	end,
})

-- ---------------------------------------------------------------------------
-- Environment
-- ---------------------------------------------------------------------------

function Env.new()
	local self = setmetatable({}, Env)

	self.now = 1000 -- os.clock()
	self.wallTime = 1_700_000_000 -- os.time()
	self.deferred = {} -- task.defer / task.delay queue
	self.warnings = {}
	self.cache = {} -- module node -> exports
	self.services = {}

	-- Instance tree: same shape as default.project.json.
	local dataModel = newNode("Game", "DataModel", nil)
	local replicated = newNode("ReplicatedStorage", "ReplicatedStorage", dataModel)
	local serverScripts = newNode("ServerScriptService", "ServerScriptService", dataModel)
	local starterPlayer = newNode("StarterPlayer", "StarterPlayer", dataModel)
	local playerScripts = newNode("StarterPlayerScripts", "StarterPlayerScripts", starterPlayer)

	self.roots = {
		shared = newNode("Shared", "Folder", replicated),
		server = newNode("Server", "Folder", serverScripts),
		client = newNode("Client", "Folder", playerScripts),
	}
	mountDirectory(SRC .. "/shared", self.roots.shared)
	mountDirectory(SRC .. "/server", self.roots.server)
	mountDirectory(SRC .. "/client", self.roots.client)

	-- Services. Unknown services fail loudly so a missing fake is obvious.
	self.services.ReplicatedStorage = replicated
	self.services.ServerScriptService = serverScripts
	self.services.Players = {
		PlayerAdded = newSignal(),
		PlayerRemoving = newSignal(),
		_players = {},
		GetPlayers = function(players)
			return table.clone(players._players)
		end,
		GetPlayerByUserId = function(players, userId)
			for _, player in players._players do
				if player.UserId == userId then
					return player
				end
			end
			return nil
		end,
	}
	self.services.RunService = {
		IsStudio = function()
			return true
		end,
		IsServer = function()
			return true
		end,
		IsClient = function()
			return false
		end,
	}
	self.services.AnalyticsService = {
		LogCustomEvent = function() end,
	}
	self.services.MarketplaceService = { ProcessReceipt = nil }

	local env = self
	local game = {
		GetService = function(_, name)
			local service = env.services[name]
			assert(service ~= nil, `Fake service "{name}" is not implemented. Add it in tests/lib/Env.luau or set env.services.{name} in the test.`)
			return service
		end,
	}

	local fakeOs = {
		clock = function()
			return env.now
		end,
		time = function()
			return env.wallTime
		end,
		date = os.date,
		difftime = os.difftime,
	}

	local fakeTask = {
		-- spawn runs right away; defer / delay wait for env:flush() / env:advance().
		spawn = function(fnOrThread, ...)
			if type(fnOrThread) == "function" then
				fnOrThread(...)
			end
		end,
		defer = function(fn, ...)
			table.insert(env.deferred, { at = env.now, fn = fn, args = table.pack(...) })
		end,
		delay = function(seconds, fn, ...)
			table.insert(env.deferred, { at = env.now + seconds, fn = fn, args = table.pack(...) })
		end,
		wait = function(seconds)
			env:advance(seconds or 0)
			return seconds or 0
		end,
	}

	self.globals = {
		game = game,
		Vector3 = Vector3,
		Color3 = Color3,
		Enum = Enum,
		os = fakeOs,
		task = fakeTask,
		warn = function(...)
			table.insert(env.warnings, table.concat(table.pack(...), " "))
		end,
		print = function() end,
		typeof = function(value)
			return type(value)
		end,
		-- Luau standard library
		math = math,
		string = string,
		table = table,
		utf8 = utf8,
		buffer = buffer,
		bit32 = bit32,
		coroutine = coroutine,
		type = type,
		tostring = tostring,
		tonumber = tonumber,
		pairs = pairs,
		ipairs = ipairs,
		next = next,
		select = select,
		pcall = pcall,
		xpcall = xpcall,
		error = error,
		assert = assert,
		setmetatable = setmetatable,
		getmetatable = getmetatable,
		rawget = rawget,
		rawset = rawset,
		rawequal = rawequal,
		unpack = table.unpack,
	}

	return self
end

-- ---------------------------------------------------------------------------
-- Module loading
-- ---------------------------------------------------------------------------

function Env:_nodeFromPath(path: string)
	local root, rest = string.match(path, "^(%a+)/(.+)$")
	local node = self.roots[root]
	assert(node, `Unknown root "{tostring(root)}" in "{path}" (use shared/..., server/... or client/...)`)
	for part in string.gmatch(rest, "[^/]+") do
		node = rawget(node, "_children")[part]
		assert(node, `No module "{part}" while resolving "{path}"`)
	end
	return node
end

function Env:_load(node)
	if self.cache[node] ~= nil then
		return self.cache[node].value
	end

	local path = rawget(node, "_path")
	assert(path, `require() target "{rawget(node, "Name")}" is not a module`)

	local moduleEnv = table.clone(self.globals)
	moduleEnv.script = node
	moduleEnv.require = function(target)
		assert(type(target) == "table" and rawget(target, "ClassName") ~= nil, "require() expects a ModuleScript")
		return self:_load(target)
	end

	local source = fs.readFile(path)
	local chunk = luau.load(source, { debugName = path, environment = moduleEnv, injectGlobals = false })
	local value = chunk()

	self.cache[node] = { value = value }
	return value
end

-- Load a real module from src/, e.g. env:require("server/Economy/EconomyService").
function Env:require(path: string)
	return self:_load(self:_nodeFromPath(path))
end

-- Replace a module with a fake BEFORE anything requires it.
function Env:mock(path: string, value)
	self.cache[self:_nodeFromPath(path)] = { value = value }
	return value
end

-- ---------------------------------------------------------------------------
-- Time
-- ---------------------------------------------------------------------------

-- Run everything queued by task.defer / task.delay that is due.
function Env:flush()
	local pending = self.deferred
	self.deferred = {}
	for _, item in pending do
		if item.at <= self.now then
			item.fn(table.unpack(item.args, 1, item.args.n))
		else
			table.insert(self.deferred, item)
		end
	end
end

function Env:advance(seconds: number)
	self.now += seconds
	self.wallTime += seconds
	self:flush()
end

-- Convenience for tests that need a real Signal.
Env.newSignal = newSignal
Env.Vector3 = Vector3

return Env
