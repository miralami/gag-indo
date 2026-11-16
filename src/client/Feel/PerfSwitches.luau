-- PerfSwitches (VISUAL_MASTER_PLAN section 7, V0.2): admin-only LOCAL rendering toggles so the
-- designer can read an fps number per switch on a phone. Nothing here replicates or talks to the
-- server. Off is fully reversible: the original value of every touched property is remembered and
-- put back on "on". Instances that appear while a switch is off are switched off too.
--
-- Roots are injected so a Lune spec can drive it with fakes:
--   PerfSwitches.new({ lighting = Lighting, workspace = workspace, terrain = workspace.Terrain })
-- A fake root needs GetDescendants() and a DescendantAdded signal with :Connect; instances need
-- IsA(className). Lighting is scanned for BloomEffect, workspace for Highlight and ParticleEmitter.

local PerfSwitches = {}

PerfSwitches.NAMES = { "highlights", "shadows", "bloom", "decoration", "particles" }

local KNOWN = {}
for _, name in PerfSwitches.NAMES do
	KNOWN[name] = true
end

-- Instance-class switches: class to match and the boolean property to flip.
local INSTANCE_SWITCHES = {
	highlights = { class = "Highlight", prop = "Enabled" },
	bloom = { class = "BloomEffect", prop = "Enabled" },
	particles = { class = "ParticleEmitter", prop = "Enabled" },
}

function PerfSwitches.new(deps: any)
	deps = deps or {}
	local self = {}

	local state = {}
	for _, name in PerfSwitches.NAMES do
		state[name] = true
	end

	-- Per instance-switch: weak instance -> original value, recorded the first time we turn it off.
	local originals = {}
	for name in INSTANCE_SWITCHES do
		originals[name] = setmetatable({}, { __mode = "k" })
	end
	local scalarOriginals = {} -- shadows / decoration: { value = original }
	local connections = {}

	local function classMatch(instance: any, class: string): boolean
		local ok, result = pcall(function()
			return instance:IsA(class)
		end)
		return ok and result == true
	end

	local function disableInstance(name: string, instance: any)
		local spec = INSTANCE_SWITCHES[name]
		if not classMatch(instance, spec.class) then
			return
		end
		local saved = originals[name]
		if saved[instance] == nil then
			saved[instance] = instance[spec.prop]
		end
		instance[spec.prop] = false
	end

	local function eachRoot(): { any }
		local roots = {}
		for _, root in { deps.workspace, deps.lighting } do
			if root then
				table.insert(roots, root)
			end
		end
		return roots
	end

	local function sweep(name: string)
		for _, root in eachRoot() do
			for _, instance in root:GetDescendants() do
				disableInstance(name, instance)
			end
		end
	end

	local function restoreInstances(name: string)
		local spec = INSTANCE_SWITCHES[name]
		for instance, original in originals[name] do
			pcall(function()
				instance[spec.prop] = original
			end)
		end
		table.clear(originals[name])
	end

	local function onAdded(instance: any)
		for name in INSTANCE_SWITCHES do
			if not state[name] then
				disableInstance(name, instance)
			end
		end
	end

	local function ensureWatching()
		if #connections > 0 then
			return
		end
		for _, root in eachRoot() do
			if root.DescendantAdded then
				table.insert(connections, root.DescendantAdded:Connect(onAdded))
			end
		end
	end

	local function stopWatchingIfAllOn()
		for _, name in PerfSwitches.NAMES do
			if not state[name] then
				return
			end
		end
		for _, connection in connections do
			connection:Disconnect()
		end
		table.clear(connections)
	end

	local function applyScalar(name: string, enabled: boolean)
		local target, prop
		if name == "shadows" then
			target, prop = deps.lighting, "GlobalShadows"
		else
			target, prop = deps.terrain, "Decoration"
		end
		if not target then
			return
		end
		if enabled then
			local saved = scalarOriginals[name]
			if saved then
				target[prop] = saved.value
				scalarOriginals[name] = nil
			end
		else
			if not scalarOriginals[name] then
				scalarOriginals[name] = { value = target[prop] }
			end
			target[prop] = false
		end
	end

	-- Unknown names and non-boolean values are ignored; setting the current state is a no-op.
	function self.set(name: string, enabled: boolean)
		if not KNOWN[name] or type(enabled) ~= "boolean" or state[name] == enabled then
			return
		end
		state[name] = enabled
		if INSTANCE_SWITCHES[name] then
			if enabled then
				restoreInstances(name)
			else
				ensureWatching()
				sweep(name)
			end
		else
			applyScalar(name, enabled)
		end
		stopWatchingIfAllOn()
	end

	function self.get(name: string): boolean
		if not KNOWN[name] then
			return true
		end
		return state[name]
	end

	function self.toggle(name: string)
		if KNOWN[name] then
			self.set(name, not state[name])
		end
	end

	-- Puts everything back and drops the watchers.
	function self.restoreAll()
		for _, name in PerfSwitches.NAMES do
			self.set(name, true)
		end
	end

	return self
end

-- Shared real-world instance for the admin panel, built on first use.
local shared = nil
function PerfSwitches.get()
	if not shared then
		local workspaceService = game:GetService("Workspace")
		shared = PerfSwitches.new({
			lighting = game:GetService("Lighting"),
			workspace = workspaceService,
			terrain = workspaceService.Terrain,
		})
	end
	return shared
end

return PerfSwitches
