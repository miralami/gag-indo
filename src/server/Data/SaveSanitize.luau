-- SaveSanitize: one-shot repair of damaged saves right after Reconcile + migrate.
-- Pure: no Roblox services, so it runs under lune. See tests/specs/save_reconcile_spec.luau.
--
-- Rules:
--   * top-level field whose type differs from the template's -> template default (deep copy);
--   * number that is NaN or +-inf -> template default;
--   * for the known nested tables below, template keys get the same two rules one level down;
--   * unknown keys are NEVER touched or deleted (cooldowns["steal_123"], nbDay_*, tiles t1..tN);
--   * negative numbers are left alone (cash may be negative: debt/wage code owns that rule).
-- Returns the list of repaired field paths, sorted, so callers can log a count.

local SaveSanitize = {}

-- Nested tables whose template keys are fixed fields. items/produce/tiles/almanak hold dynamic
-- keys and are deliberately absent.
local NESTED = {
	cooldowns = true,
	stats = true,
	quests = true,
	worker = true,
	gudang = true,
	debt = true,
	shop = true,
	tutorial = true,
	story = true,
	prestige = true,
}

local function deepCopy(value: any): any
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for k, v in value do
		copy[k] = deepCopy(v)
	end
	return copy
end

local function isBad(value: any, default: any): boolean
	if type(value) ~= type(default) then
		return true
	end
	if type(value) == "number" then
		return value ~= value or value == math.huge or value == -math.huge
	end
	return false
end

local function sortedKeys(t: { [any]: any }): { string }
	local keys = {}
	for k in t do
		if type(k) == "string" then
			table.insert(keys, k)
		end
	end
	table.sort(keys)
	return keys
end

function SaveSanitize.sanitize(data: any, template: any): { string }
	local repaired: { string } = {}
	if type(data) ~= "table" or type(template) ~= "table" then
		return repaired
	end

	for _, key in sortedKeys(template) do
		local default = template[key]
		local value = data[key]
		if isBad(value, default) then
			data[key] = deepCopy(default)
			table.insert(repaired, key)
		elseif NESTED[key] and type(default) == "table" then
			for _, nestedKey in sortedKeys(default) do
				local nestedDefault = default[nestedKey]
				if isBad(value[nestedKey], nestedDefault) then
					value[nestedKey] = deepCopy(nestedDefault)
					table.insert(repaired, key .. "." .. nestedKey)
				end
			end
		end
	end

	return repaired
end

return SaveSanitize
