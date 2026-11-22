--!strict
-- LazyPages: pure bookkeeping for screens that are built on first open and torn down on close.
-- No Roblox types are used; the caller supplies `build` (returns the page instance), `apply`
-- (fills it from the latest state) and optionally `destroy`. Used by Phone.luau.
--
--   local pages = LazyPages.new({
--       kebun = { build = function(id) ... return frame end, apply = function(frame, state) ... end },
--   })
--   pages:open("kebun")          -- builds if needed, then apply(instance, state)
--   pages:setState("kebun", {})  -- merge; applied now if built, otherwise kept for the next build
--   pages:close("kebun")         -- destroy; the merged state is kept for the next build

local LazyPages = {}
LazyPages.__index = LazyPages

export type Def = {
	build: (id: string) -> any?,
	apply: ((instance: any, state: { [string]: any }) -> ())?,
	destroy: ((instance: any, id: string) -> ())?,
}

function LazyPages.new(defs: { [string]: Def })
	return setmetatable({
		_defs = defs,
		_instances = {} :: { [string]: any },
		_state = {} :: { [string]: { [string]: any } },
	}, LazyPages)
end

function LazyPages.has(self: any, id: string): boolean
	return self._defs[id] ~= nil
end

function LazyPages.isBuilt(self: any, id: string): boolean
	return self._instances[id] ~= nil
end

function LazyPages.get(self: any, id: string): any?
	return self._instances[id]
end

function LazyPages.builtCount(self: any): number
	local n = 0
	for _ in self._instances do
		n += 1
	end
	return n
end

-- The merged state for a page (live table; treat as read-only outside this module).
function LazyPages.getState(self: any, id: string): { [string]: any }
	local state = self._state[id]
	if not state then
		state = {}
		self._state[id] = state
	end
	return state
end

local function applyTo(self: any, id: string)
	local def = self._defs[id]
	local instance = self._instances[id]
	if def and instance ~= nil and def.apply then
		def.apply(instance, LazyPages.getState(self, id))
	end
end

-- Builds the page if needed, applies the latest state, returns the instance (nil for an unknown id).
function LazyPages.open(self: any, id: string): any?
	local def = self._defs[id]
	if not def then
		return nil
	end
	if self._instances[id] == nil then
		local built = def.build(id)
		if built == nil then
			return nil
		end
		self._instances[id] = built
	end
	applyTo(self, id)
	return self._instances[id]
end

-- Re-applies the state to an already built page; false when it is not built (nothing is built).
function LazyPages.refresh(self: any, id: string): boolean
	if self._instances[id] == nil then
		return false
	end
	applyTo(self, id)
	return true
end

-- Shallow-merges `patch` into the page state. A built page is re-applied at once; an unbuilt
-- page just keeps the latest values for its next open. Never errors for an unbuilt page.
function LazyPages.setState(self: any, id: string, patch: { [string]: any }): boolean
	if not self._defs[id] then
		return false
	end
	local state = LazyPages.getState(self, id)
	for key, value in patch do
		state[key] = value
	end
	return LazyPages.refresh(self, id)
end

-- Tears the page down (state is kept). Returns true when something was destroyed.
function LazyPages.close(self: any, id: string): boolean
	local instance = self._instances[id]
	if instance == nil then
		return false
	end
	self._instances[id] = nil
	local def = self._defs[id]
	if def and def.destroy then
		def.destroy(instance, id)
	end
	return true
end

function LazyPages.closeAll(self: any)
	local ids = {}
	for id in self._instances do
		table.insert(ids, id)
	end
	for _, id in ids do
		LazyPages.close(self, id)
	end
end

-- Screen transition: close every other page, then open `id` (nil or an unknown id = close all).
function LazyPages.show(self: any, id: string?): any?
	local ids = {}
	for builtId in self._instances do
		if builtId ~= id then
			table.insert(ids, builtId)
		end
	end
	for _, builtId in ids do
		LazyPages.close(self, builtId)
	end
	if id == nil then
		return nil
	end
	return LazyPages.open(self, id)
end

-- Wraps a one-time build: the first call runs `build(...)` and keeps its results; later calls
-- return the same results without building again. A build that errors is not recorded, so
-- the next call retries. Returns (ensure, isBuilt).
function LazyPages.once(build: (...any) -> ...any)
	local done = false
	local results: { any } = {}
	local count = 0
	local function ensure(...: any): ...any
		if not done then
			local packed = table.pack(build(...))
			results, count, done = packed, packed.n, true
		end
		return table.unpack(results, 1, count)
	end
	return ensure, function(): boolean
		return done
	end
end

return LazyPages
