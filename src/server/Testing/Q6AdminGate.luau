--!strict
-- Q6AdminGate: the permission rule for the published-place Q6 admin commands.
--
-- There is deliberately NO studio flag here. The Q6 save → leave → rejoin check has to run in a
-- PUBLISHED place, where the Studio-only harness Gate can never open, so the published players
-- themselves must be able to fire these two read-only commands. Admin allowlist + rate limit are
-- the whole gate; the commands never save, mutate or dispatch anything.
--
-- Pure module, no game APIs, so tests/specs/q6_admin_spec.luau can prove every branch.

local Q6AdminGate = {}

Q6AdminGate.ACTIONS = {
	q6Capture = true,
	q6Compare = true,
}

-- Strict `== true` on every input: truthy-but-not-boolean values are refused.
function Q6AdminGate.canUse(opts): boolean
	if type(opts) ~= "table" then
		return false
	end
	return opts.admin == true and opts.rateAllowed == true and Q6AdminGate.ACTIONS[opts.action] == true
end

return Q6AdminGate
