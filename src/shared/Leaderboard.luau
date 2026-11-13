-- Leaderboard: pure rules shared by the server and the client (v2 PLAN §3.6).
--
-- No Roblox APIs, so the same code runs in Lune tests, on the server (sanitising what
-- OrderedDataStore returns) and on the client (validating the Leaderboard_Data payload
-- before rendering it). A score is only accepted when it is a finite positive integer;
-- ties break on the lower UserId so every client sees the same order.

local Leaderboard = {}

Leaderboard.categories = { "richest", "sultan", "raids" }
Leaderboard.topCount = 10
Leaderboard.maxNameLength = 32
Leaderboard.maxValue = 1e12

-- Returns a whole positive number, or nil for anything the boards must not show
-- (negative, zero, NaN, infinity, strings, tables).
function Leaderboard.sanitizeValue(value: any): number?
	if type(value) ~= "number" then
		return nil
	end
	if value ~= value or value == math.huge or value == -math.huge then
		return nil
	end
	if value <= 0 or value > Leaderboard.maxValue then
		return nil
	end
	return math.floor(value)
end

function Leaderboard.sanitizeName(name: any): string?
	if type(name) ~= "string" then
		return nil
	end
	name = string.gsub(name, "^%s*(.-)%s*$", "%1")
	if name == "" then
		return nil
	end
	if #name > Leaderboard.maxNameLength then
		name = string.sub(name, 1, Leaderboard.maxNameLength)
	end
	return name
end

-- One board row: { userId, name, value }. Invalid rows are dropped, never clamped,
-- so a broken store entry cannot silently take someone else's place.
function Leaderboard.sanitizeEntry(entry: any): { userId: number, name: string, value: number }?
	if type(entry) ~= "table" then
		return nil
	end
	local userId = tonumber(entry.userId)
	if not userId or userId ~= math.floor(userId) or userId <= 0 then
		return nil
	end
	local value = Leaderboard.sanitizeValue(entry.value)
	if not value then
		return nil
	end
	local name = Leaderboard.sanitizeName(entry.name)
	if not name then
		return nil
	end
	return { userId = userId, name = name, value = value }
end

-- Descending score, then ascending UserId. Deterministic on every client.
function Leaderboard.sort(entries: { any }?): { { userId: number, name: string, value: number } }
	local clean = {}
	for _, entry in entries or {} do
		local sanitized = Leaderboard.sanitizeEntry(entry)
		if sanitized then
			table.insert(clean, sanitized)
		end
	end
	table.sort(clean, function(a, b)
		if a.value ~= b.value then
			return a.value > b.value
		end
		return a.userId < b.userId
	end)
	return clean
end

function Leaderboard.top(entries: { any }?, count: number?): { { userId: number, name: string, value: number } }
	local sorted = Leaderboard.sort(entries)
	local limit = math.max(0, math.floor(count or Leaderboard.topCount))
	local out = {}
	for index = 1, math.min(limit, #sorted) do
		out[index] = sorted[index]
	end
	return out
end

function Leaderboard.emptyBoards(): { [string]: { { userId: number, name: string, value: number } } }
	local boards = {}
	for _, category in Leaderboard.categories do
		boards[category] = {}
	end
	return boards
end

-- Client-side guard for the Leaderboard_Data remote. Returns nil when the payload is
-- malformed; otherwise a fresh table with every category present and sanitised.
function Leaderboard.validatePayload(payload: any): { [string]: { { userId: number, name: string, value: number } } }?
	if type(payload) ~= "table" then
		return nil
	end
	local boards = {}
	local found = false
	for _, category in Leaderboard.categories do
		local list = payload[category]
		if list == nil then
			boards[category] = {}
		elseif type(list) == "table" then
			boards[category] = Leaderboard.top(list, Leaderboard.topCount)
			found = true
		else
			return nil
		end
	end
	if not found then
		return nil
	end
	return boards
end

return Leaderboard
