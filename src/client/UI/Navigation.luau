--!strict
-- Pure navigation policy (WORK_QUEUE item 21). No Roblox services, no Instances: the tokens
-- below are opaque values (GuiObjects in Studio, plain tables in specs). The Studio bridge in
-- NavBridge.luau supplies the visibility predicate and applies the decisions to
-- GuiService.SelectedObject. Keeping the policy pure lets the stack/cancel/rescue rules be
-- pinned by LUNE-ONLY specs.
--
-- Two structures matter: `_byId` is the permanent registry (a screen registered at mount stays
-- known for its whole life), while `_stack` holds only the ACTUALLY OPEN screens. Toggling a
-- screen's Visible moves it between those two states. Keeping them separate is what lets a
-- screen be closed and reopened with its default selection restored.

local Navigation = {}
Navigation.__index = Navigation

-- A default may be a token or a function returning one, for phase-driven screens (the raid
-- overlay shows Skip during the intro and Fine/Amplop during the choice).
local function resolveDefault(value: any): any
	return if type(value) == "function" then value() else value
end

export type Screen = {
	id: string,
	root: any,
	default: any,
	onClose: (() -> ())?,
	closable: boolean,
}

function Navigation.new()
	return setmetatable({
		_stack = {} :: { Screen },
		_byId = {} :: { [string]: Screen },
	}, Navigation)
end

-- Remove an id from the active stack only; the registry entry survives so the screen can reopen.
local function removeFromStack(self, id: string): Screen?
	for i, screen in self._stack do
		if screen.id == id then
			return table.remove(self._stack, i)
		end
	end
	return nil
end

-- Register (or update) a screen. Registration alone does not open a screen; the bridge calls
-- open() when the root actually becomes visible. Re-registering a currently-open id keeps it open
-- and moves it to the top, without duplicating the record.
function Navigation:register(id: string, opts: Screen): Screen
	local wasOpen = removeFromStack(self, id) ~= nil
	local screen: Screen = {
		id = id,
		root = opts.root,
		default = opts.default,
		onClose = opts.onClose,
		closable = if opts.closable == nil then true else opts.closable,
	}
	self._byId[id] = screen
	if wasOpen then
		table.insert(self._stack, screen)
	end
	return screen
end

-- Fully forget a screen (used when the admin panel is destroyed).
function Navigation:unregister(id: string): Screen?
	local old = self._byId[id]
	self._byId[id] = nil
	removeFromStack(self, id)
	return old
end

-- Mark a registered screen as open (or move it to the top) and return its default selection token.
function Navigation:open(id: string): any?
	local screen = self._byId[id]
	if not screen then
		return nil
	end
	removeFromStack(self, id)
	table.insert(self._stack, screen)
	return resolveDefault(screen.default)
end

-- Mark a screen closed: remove it from the active stack but keep it registered for reopening.
-- Returns the default token of the next still-open screen to restore.
function Navigation:close(id: string): any?
	removeFromStack(self, id)
	local top = self:top()
	return if top then resolveDefault(top.default) else nil
end

function Navigation:top(): Screen?
	return self._stack[#self._stack]
end

function Navigation:count(): number
	return #self._stack
end

function Navigation:ids(): { string }
	local out = {}
	for _, s in self._stack do
		table.insert(out, s.id)
	end
	return out
end

-- The topmost open screen that is dismissable (closable AND has an onClose). Forced overlays such
-- as the raid cutscene are registered with closable=false so cancel skips them.
function Navigation:topClosable(): Screen?
	for i = #self._stack, 1, -1 do
		local s = self._stack[i]
		if s.closable and s.onClose then
			return s
		end
	end
	return nil
end

-- B/Escape decision. Returns true and the callback to invoke, or false and nil when nothing
-- dismissable is open. The bridge invokes the callback; the policy never touches the GUI.
function Navigation:cancel(): (boolean, (() -> ())?)
	local screen = self:topClosable()
	if screen and screen.onClose then
		-- Logically close now but LEAVE the screen registered, so it can reopen later. The bridge's
		-- Visible=false signal calls close() again as an idempotent backstop.
		removeFromStack(self, screen.id)
		return true, screen.onClose
	end
	return false, nil
end

-- Selection decision after any open/close/selection change. `isVisible` is supplied by the
-- bridge (or a spec). Keep a still-visible selection, else fall back to the topmost open screen
-- whose default is visible, else clear. This is what stops selection being stuck in a hidden frame.
function Navigation:rescue(current: any?, isVisible: (any) -> boolean): (any?, string)
	if current ~= nil and isVisible(current) then
		return current, "keep"
	end
	for i = #self._stack, 1, -1 do
		local default = resolveDefault(self._stack[i].default)
		if default ~= nil and isVisible(default) then
			return default, "default"
		end
	end
	return nil, "clear"
end

return Navigation
