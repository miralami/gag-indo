-- Studio bridge for WORK_QUEUE item 21. Connects the pure Navigation policy to Roblox input and
-- selection: B/Escape close the topmost dismissable screen, a default is selected on open, and a
-- selection left inside a hidden frame is rescued. All platform calls live here; Navigation.luau
-- stays pure and is pinned by LUNE-ONLY specs.

local GuiService = game:GetService("GuiService")
local ContextActionService = game:GetService("ContextActionService")

local Navigation = require(script.Parent.Navigation)

local NavBridge = {}

local nav = Navigation.new()
local started = false
local CANCEL_ACTION = "NavCancel"

-- A token is selectable only while it is a live GuiObject with no hidden ancestor and it still
-- sits under a ScreenGui. This is the predicate the pure policy asks about on every rescue.
local function isVisible(token: any): boolean
	if typeof(token) ~= "Instance" or not token:IsA("GuiObject") then
		return false
	end
	if not token:FindFirstAncestorOfClass("ScreenGui") then
		return false
	end
	local node: Instance? = token
	while node do
		if node:IsA("GuiObject") and not node.Visible then
			return false
		end
		node = node.Parent
	end
	return true
end

local function setSelected(token: any?)
	if GuiService.SelectedObject ~= token then
		GuiService.SelectedObject = token
	end
end

-- Re-pick the selection using the pure policy. Called after every open/close and whenever the
-- engine moves the selection. Converges because a rescued target is visible, so a second pass
-- returns "keep"; a nil target with no screens open is a no-op.
local function rescue(): string
	local current = GuiService.SelectedObject
	local target, reason = nav:rescue(current, isVisible)
	if target ~= current then
		setSelected(target)
	end
	return reason
end

-- Public for screens with phase-driven buttons (the raid overlay) that need to re-evaluate the
-- selection after a phase change without toggling their root's Visible.
function NavBridge.rescue()
	return rescue()
end

function NavBridge.register(id: string, opts: {
	root: GuiObject,
	default: any,
	onClose: (() -> ())?,
	closable: boolean?,
})
	nav:register(id, {
		root = opts.root,
		default = opts.default,
		onClose = opts.onClose,
		closable = opts.closable,
	})

	local root = opts.root
	root:GetPropertyChangedSignal("Visible"):Connect(function()
		if root.Visible then
			local default = nav:open(id)
			if isVisible(default) then
				setSelected(default)
			else
				rescue() -- default hidden for this phase; fall back to a visible one
			end
		else
			nav:close(id)
			rescue()
		end
	end)

	-- Sync the initial state in case the screen was already visible at mount.
	if root.Visible then
		local default = nav:open(id)
		if isVisible(default) then
			setSelected(default)
		end
	end
end

function NavBridge.unregister(id: string)
	nav:unregister(id)
	rescue()
end

local function handleCancel(_action: string, state: Enum.UserInputState, _input: InputObject)
	if state ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	local handled, closeFn = nav:cancel()
	if handled and closeFn then
		closeFn()
		task.defer(rescue)
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass -- nothing to close: let Escape reach the core menu
end

function NavBridge.start()
	if started then
		return
	end
	started = true
	ContextActionService:BindActionAtPriority(
		CANCEL_ACTION,
		handleCancel,
		false,
		Enum.ContextActionPriority.High.Value,
		Enum.KeyCode.Escape,
		Enum.KeyCode.ButtonB
	)
	-- The engine can move the selection (gamepad D-pad, a button being hidden). Rescue whenever
	-- the property changes so it never points into a hidden frame.
	GuiService:GetPropertyChangedSignal("SelectedObject"):Connect(rescue)
end

-- Exposed read-only for the Studio verification pass (no mutation of game state).
function NavBridge.debugState(): { ids: { string }, selected: any? }
	return { ids = nav:ids(), selected = GuiService.SelectedObject }
end

return NavBridge
