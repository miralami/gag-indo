-- Analytics: the ONE owner of every AnalyticsService call (TECH.md §9, PLAN §7.1).
--
-- Why a wrapper:
-- * A failed analytics call must never break gameplay (Studio without "Enable Studio Access to
--   API Services", a service hiccup, a bad argument).
-- * The platform rate limit is global (120 + 20 * CCU calls per minute). We keep our own budget
--   so we drop events instead of letting the platform silently drop them.
-- * Every event is logged on the server, after the authoritative mutation, so a client cannot
--   fake it and a refused action never counts as a success.
--
-- No personal data is sent: names, UserIds, chat and free text never appear in an event or a
-- custom field. Custom fields are short config ids (crop, tier, sku, channel) chosen in code.

local AnalyticsService = game:GetService("AnalyticsService")
local Players = game:GetService("Players")

local Analytics = {}

local WINDOW_SECONDS = 60
local BASE_BUDGET = 120
local PER_PLAYER_BUDGET = 20
local MAX_CUSTOM_FIELDS = 3
local CURRENCY = "Cash"

-- Budget state. Reset lazily so the module never needs its own loop.
local windowStartedAt = os.time()
local callsThisWindow = 0

-- `once` memory: player -> { [key] = true }. Weak keys so a leaving player is collected.
local seen = setmetatable({}, { __mode = "k" })

-- How many calls the platform allows us in one minute for `playerCount` players.
function Analytics.budgetFor(playerCount: number): number
	local count = math.max(0, math.floor(playerCount))
	return BASE_BUDGET + PER_PLAYER_BUDGET * count
end

local function budgetNow(): number
	local ok, list = pcall(function()
		return Players:GetPlayers()
	end)
	return Analytics.budgetFor(if ok and type(list) == "table" then #list else 0)
end

-- Take one call from the minute budget. False means "drop this event".
local function reserve(): boolean
	local now = os.time()
	if now - windowStartedAt >= WINDOW_SECONDS then
		windowStartedAt = now
		callsThisWindow = 0
	end
	if callsThisWindow >= budgetNow() then
		return false
	end
	callsThisWindow += 1
	return true
end

-- Roblox takes at most 3 custom fields, keyed by "CustomField01".."CustomField03".
-- Passing a short list keeps every call site honest about that limit.
local function customFields(fields: { any }?): { [string]: string }?
	if not fields then
		return nil
	end
	local out = {}
	for index = 1, math.min(#fields, MAX_CUSTOM_FIELDS) do
		local value = fields[index]
		if value ~= nil then
			out["CustomField0" .. index] = tostring(value)
		end
	end
	if next(out) == nil then
		return nil
	end
	return out
end

local function finite(value: any): boolean
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

-- AnalyticsService errors are swallowed by design: telemetry is never gameplay.
local function send(fn: () -> ())
	local ok = pcall(fn)
	if not ok then
		local _ = ok
	end
end

-- A custom event. `value` aggregates on the dashboard; `fields` break it down.
function Analytics.track(player: Player?, name: string, value: number?, fields: { any }?)
	if player == nil or type(name) ~= "string" or name == "" then
		return
	end
	local payload = customFields(fields)
	if not reserve() then
		return
	end
	local amount = if finite(value) then value else 0
	send(function()
		AnalyticsService:LogCustomEvent(player, name, amount, payload)
	end)
end

-- A custom event that fires at most once per player (keyed by event name and first field).
function Analytics.once(player: Player?, name: string, value: number?, fields: { any }?)
	if player == nil or type(name) ~= "string" or name == "" then
		return
	end
	local playerSeen = seen[player]
	if not playerSeen then
		playerSeen = {}
		seen[player] = playerSeen
	end
	local key = name
	if fields and fields[1] ~= nil then
		key = name .. ":" .. tostring(fields[1])
	end
	if playerSeen[key] then
		return
	end
	if not reserve() then
		return -- dropped by the budget: leave the key free so a later attempt can land
	end
	playerSeen[key] = true
	local payload = customFields(fields)
	local amount = if finite(value) then value else 1
	send(function()
		AnalyticsService:LogCustomEvent(player, name, amount, payload)
	end)
end

-- A committed currency change. Call AFTER the mutation, with the balance it returned.
-- `flow` is "Source" (earned) or "Sink" (spent); `sku` says what triggered it.
function Analytics.economy(
	player: Player?,
	flow: string,
	amount: number?,
	balance: number?,
	transaction: string?,
	sku: string?,
	fields: { any }?
)
	if player == nil or not finite(amount) or amount <= 0 or not finite(balance) or balance < 0 then
		return
	end
	local payload = customFields(fields)
	if not reserve() then
		return
	end
	local flowType = if flow == "Sink"
		then Enum.AnalyticsEconomyFlowType.Sink
		else Enum.AnalyticsEconomyFlowType.Source
	-- transactionType is a string in the engine signature, not an enum (checked against the
	-- AnalyticsService docs, 2026-11-14); passing the enum raises "argument #6 expects a string".
	local transactionType = transaction or "Gameplay"
	local itemSku = tostring(sku or "unknown")
	send(function()
		AnalyticsService:LogEconomyEvent(
			player,
			flowType,
			CURRENCY,
			amount,
			balance,
			transactionType,
			itemSku,
			payload
		)
	end)
end

-- One completed step of the guided first session. Step numbers follow Onboarding.steps,
-- and `total + 1` is "finished".
function Analytics.onboarding(player: Player?, step: number?, stepName: string?)
	if player == nil or not finite(step) or step < 1 or type(stepName) ~= "string" then
		return
	end
	if not reserve() then
		return
	end
	-- `finite(step)` above guarantees a number at runtime; the assertion only restores that
	-- narrowing inside the closure for the type checker (no runtime change).
	local stepNumber = step :: number
	send(function()
		AnalyticsService:LogOnboardingFunnelStepEvent(player, math.floor(stepNumber), stepName)
	end)
end

-- One step of a recurring funnel (not onboarding). `session` must be stable for one attempt.
function Analytics.funnel(player: Player?, funnel: string?, session: any, step: any, stepName: any)
	if type(session) == "number" and type(step) == "string" and stepName == nil then
		stepName = step
		step = session
		session = if player and player.UserId then tostring(player.UserId) else "session"
	end
	if player == nil or type(funnel) ~= "string" or type(session) ~= "string" then
		return
	end
	if not finite(step) or step < 1 or type(stepName) ~= "string" then
		return
	end
	if not reserve() then
		return
	end
	send(function()
		AnalyticsService:LogFunnelStepEvent(player, funnel, session, math.floor(step), stepName)
	end)
end

-- Backwards-compatible alias for the old thin wrapper.
Analytics.log = Analytics.track

return Analytics
