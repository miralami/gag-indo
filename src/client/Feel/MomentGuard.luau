--!strict
-- MomentGuard: keeps FidelityRuntime.beginMoment()/endMoment() balanced for one UI hook moment
-- (rarity reveal, raid overlay). A guard holds at most one open moment:
--   begin()   opens a moment; if one is already open it is replaced (one end is issued for the old
--             one, so repeated or superseding starts never leak a count).
--   finish()  closes the open moment exactly once; a call with nothing open does nothing.
-- The runtime is injectable so a Lune spec can count calls; the default is FidelityRuntime.

local MomentGuard = {}

function MomentGuard.new(runtime: any?)
	local rt = runtime
	local function resolve(): any
		if not rt then
			rt = require(script.Parent.FidelityRuntime)
		end
		return rt
	end

	local open = false
	local guard = {}

	function guard.begin()
		local runtimeRef = resolve()
		local wasOpen = open
		runtimeRef.beginMoment()
		open = true
		if wasOpen then
			runtimeRef.endMoment()
		end
	end

	function guard.finish()
		if not open then
			return
		end
		open = false
		resolve().endMoment()
	end

	function guard.isOpen(): boolean
		return open
	end

	return guard
end

return MomentGuard
