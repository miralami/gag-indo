--!strict
-- Gate: the on/off switch for the playtest harness (MASTER_PLAN §3, task 0.3).
--
-- Three conditions must all hold, and the first one is impossible to fake in a published
-- server: RunService:IsStudio() is true only inside Studio. The flag lives in memory only
-- (never a DataStore), so a published place can never remember it as on either.
--
-- Pure module, no game APIs, so tests/specs/harness_spec.luau can prove every branch.

local Gate = {}

local open = false

-- The single rule. Strict `== true`: a truthy-but-not-boolean value is refused.
function Gate.allowed(opts): boolean
	if type(opts) ~= "table" then
		return false
	end
	return opts.studio == true and opts.flag == true and opts.admin == true
end

function Gate.isOpen(): boolean
	return open
end

-- Turn the harness on. Harness.luau only calls this for a Studio admin.
function Gate.enable(opts): boolean
	if not Gate.allowed({ studio = opts and opts.studio, flag = true, admin = opts and opts.admin }) then
		return false
	end
	open = true
	return true
end

function Gate.close()
	open = false
end

-- Called by every hook. The flag is read from here, never passed in by the caller.
function Gate.canCall(opts): boolean
	if type(opts) ~= "table" then
		return false
	end
	return Gate.allowed({ studio = opts.studio, flag = open, admin = opts.admin })
end

return Gate
