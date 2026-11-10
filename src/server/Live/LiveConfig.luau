-- LiveConfig (v2 PLAN §7.1): one DataStore document, polled every 60 s, pushed to other
-- servers with MessagingService, and exposed to every service through get()/onChanged().
--
-- It owns: season override, anomaly flag, weather override, event switches (the cabai
-- event's auto timer can be forced on/off), price multipliers and feature switches.
-- Everything is validated here; a malformed document can never break a live server.
--
-- Start order: Main.server starts this before services that read it. start() does not
-- yield; it spawns the poll loop.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Seasons = require(Shared.Config.Seasons)

local LiveConfig = {}

local POLL_SECONDS = 60
local KEY = "current"
local TOPIC = "JuraganDesa_LiveConfig"

-- Studio and live use separate documents so testing never changes a live season.
local function storeName(): string
	local RunService = game:GetService("RunService")
	return if RunService:IsStudio() then "LiveConfig_v1_Studio" else "LiveConfig_v1"
end

local DEFAULTS = {
	seasonOverride = "auto", -- auto | hujan | kemarau | pancaroba
	anomaly = "none", -- none | elNino | laNina
	cuacaOverride = "auto", -- auto | cerah | hujan | badai | kabut
	priceMultipliers = {},
	features = {},
	events = { cabai = "auto" }, -- auto (old timer) | on | off
	updatedAt = 0,
}

local function copyConfig(source): any
	local out = {
		priceMultipliers = {},
		features = {},
		events = {},
	}
	for key, value in source or {} do
		if type(value) ~= "table" then
			out[key] = value
		end
	end
	for cropId, multiplier in (source and source.priceMultipliers) or {} do
		out.priceMultipliers[cropId] = multiplier
	end
	for flag, enabled in (source and source.features) or {} do
		out.features[flag] = enabled
	end
	for eventId, mode in (source and source.events) or {} do
		out.events[eventId] = mode
	end
	return out
end

-- Accepts a raw document/patch and returns only well-formed fields.
function LiveConfig.sanitize(raw): any
	local patch = {}
	if type(raw) ~= "table" then
		return patch
	end
	if raw.seasonOverride == "auto" or Seasons.isMusim(raw.seasonOverride) then
		patch.seasonOverride = raw.seasonOverride
	end
	if Seasons.isAnomali(raw.anomaly) then
		patch.anomaly = raw.anomaly
	end
	if raw.cuacaOverride == "auto" or Seasons.isCuaca(raw.cuacaOverride) then
		patch.cuacaOverride = raw.cuacaOverride
	end
	if type(raw.priceMultipliers) == "table" then
		patch.priceMultipliers = {}
		for cropId, multiplier in raw.priceMultipliers do
			if
				type(cropId) == "string"
				and type(multiplier) == "number"
				and multiplier == multiplier
				and multiplier > 0
				and multiplier <= 100
			then
				patch.priceMultipliers[cropId] = multiplier
			end
		end
	end
	if type(raw.features) == "table" then
		patch.features = {}
		for flag, enabled in raw.features do
			if type(flag) == "string" then
				patch.features[flag] = enabled == true
			end
		end
	end
	if type(raw.events) == "table" then
		local cabai = raw.events.cabai
		if cabai == "auto" or cabai == "on" or cabai == "off" then
			patch.events = { cabai = cabai }
		end
	end
	if type(raw.updatedAt) == "number" then
		patch.updatedAt = raw.updatedAt
	end
	return patch
end

function LiveConfig.merge(base, patch): any
	local out = copyConfig(base)
	for key, value in patch or {} do
		if key == "priceMultipliers" and type(value) == "table" then
			for cropId, multiplier in value do
				out.priceMultipliers[cropId] = multiplier
			end
		elseif key == "features" and type(value) == "table" then
			for flag, enabled in value do
				out.features[flag] = enabled
			end
		elseif key == "events" and type(value) == "table" then
			for eventId, mode in value do
				out.events[eventId] = mode
			end
		elseif key ~= "priceMultipliers" and key ~= "features" and key ~= "events" then
			out[key] = value
		end
	end
	return out
end

-- Resolves the global runtime state. Pure: pass `now` in tests.
function LiveConfig.resolve(config, now: number?): any
	local timestamp = now or os.time()
	local musim, seasonSource
	if Seasons.isMusim(config.seasonOverride) then
		musim = config.seasonOverride
		seasonSource = "override"
	else
		musim = Seasons.fromUnix(timestamp)
		seasonSource = "calendar"
	end

	local anomali = if Seasons.isAnomali(config.anomaly) then config.anomaly else "none"

	local cuaca
	if Seasons.isCuaca(config.cuacaOverride) then
		cuaca = config.cuacaOverride
	else
		-- Stable per day until the real weather hook (M2): one pick, not a new one per poll.
		local day = math.floor(timestamp / 86400)
		local roll = (day * 0.61803398875) % 1
		cuaca = Seasons.rollWeather(musim, roll)
	end

	return {
		musim = musim,
		anomali = anomali,
		cuaca = cuaca,
		seasonSource = seasonSource,
		priceMultipliers = copyConfig(config).priceMultipliers,
		features = copyConfig(config).features,
		events = copyConfig(config).events,
		updatedAt = config.updatedAt or 0,
	}
end

local current = copyConfig(DEFAULTS)
local runtime = LiveConfig.resolve(current)
local listeners: { (any, any) -> () } = {}
local store: any = nil
local warned = false

local function warnOnce(message: string)
	if warned then
		return
	end
	warned = true
	warn("[LiveConfig] " .. message)
end

local function apply(config, nextRuntime)
	current = config
	runtime = nextRuntime
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	ReplicatedStorage:SetAttribute("Musim", runtime.musim)
	ReplicatedStorage:SetAttribute("Anomali", runtime.anomali)
	ReplicatedStorage:SetAttribute("Cuaca", runtime.cuaca)
	ReplicatedStorage:SetAttribute("LiveConfigVersion", runtime.updatedAt)
	for _, callback in table.clone(listeners) do
		task.spawn(callback, current, runtime)
	end
end

local function getStore()
	if store then
		return store
	end
	local ok, result = pcall(function()
		local DataStoreService = game:GetService("DataStoreService")
		return DataStoreService:GetDataStore(storeName())
	end)
	if ok then
		store = result
	end
	return store
end

local function load()
	local dataStore = getStore()
	if not dataStore then
		return
	end
	local ok, raw = pcall(function()
		return dataStore:GetAsync(KEY)
	end)
	if not ok then
		warnOnce("DataStore read failed (Studio API access off?). Running on defaults.")
		return
	end
	if type(raw) == "table" then
		local config = LiveConfig.merge(DEFAULTS, LiveConfig.sanitize(raw))
		apply(config, LiveConfig.resolve(config))
	end
end

local function publish(config)
	pcall(function()
		local MessagingService = game:GetService("MessagingService")
		MessagingService:PublishAsync(TOPIC, config)
	end)
end

local function subscribe()
	pcall(function()
		local MessagingService = game:GetService("MessagingService")
		MessagingService:SubscribeAsync(TOPIC, function(message)
			local raw = if type(message) == "table" then message.Data else nil
			local config = LiveConfig.merge(current, LiveConfig.sanitize(raw))
			apply(config, LiveConfig.resolve(config))
		end)
	end)
end

-- The current document (read-only by convention) and the resolved global state.
function LiveConfig.get(): any
	return current
end

function LiveConfig.getRuntime(): any
	return runtime
end

-- Fires after every apply: callback(config, runtime).
function LiveConfig.onChanged(callback: (any, any) -> ())
	table.insert(listeners, callback)
end

-- Admin write: validate, apply locally now, then save + publish. Returns the new document.
function LiveConfig.update(patch, byUserId: number?): any
	local clean = LiveConfig.sanitize(patch)
	clean.updatedAt = os.time()
	local config = LiveConfig.merge(current, clean)
	apply(config, LiveConfig.resolve(config))

	local dataStore = getStore()
	if dataStore then
		task.spawn(function()
			local ok = pcall(function()
				dataStore:SetAsync(KEY, config)
			end)
			if not ok then
				warnOnce("DataStore write failed (Studio API access off?). Change is local only.")
			end
		end)
	end
	task.spawn(publish, config)
	if byUserId then
		warn(`[LiveConfig] updated by {byUserId}: season={config.seasonOverride} anomaly={config.anomaly}`)
	end
	return config
end

function LiveConfig.refresh()
	task.spawn(load)
end

function LiveConfig.start()
	apply(copyConfig(DEFAULTS), LiveConfig.resolve(DEFAULTS))
	task.spawn(function()
		load()
		subscribe()
		while true do
			task.wait(POLL_SECONDS)
			load()
		end
	end)
end

return LiveConfig
