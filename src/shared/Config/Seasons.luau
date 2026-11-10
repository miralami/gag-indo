-- Seasons and weather (v2 PLAN §3.3). One global state, read by every server.
-- M0 ships the calendar fallback and the pure helpers; growth/shop effects arrive in M2,
-- and LiveConfig supplies the admin override.
--
-- Source priority: admin override -> live value -> this calendar.
-- (The live weather API hook is a later, optional change behind the same interface.)

local Seasons = {}

Seasons.musimOrder = { "hujan", "kemarau", "pancaroba" }
Seasons.anomaliOrder = { "none", "elNino", "laNina" }
Seasons.cuacaOrder = { "cerah", "hujan", "badai", "kabut" }

-- Growth multipliers per family; used by FarmService once M2 lands.
Seasons.list = {
	hujan = {
		growth = 1.1,
		labelKey = "season_hujan",
		rain = true,
	},
	kemarau = {
		growth = 0.9,
		labelKey = "season_kemarau",
		dry = true,
	},
	pancaroba = {
		growth = 1.0,
		labelKey = "season_pancaroba",
	},
}

-- Weighted weather table per season. `roll` is a number in [0, 1) — pass math.random()
-- in game, or a fixed value in tests.
Seasons.weatherWeights = {
	hujan = { cerah = 0.22, hujan = 0.58, badai = 0.12, kabut = 0.08 },
	kemarau = { cerah = 0.70, hujan = 0.06, badai = 0.02, kabut = 0.22 },
	pancaroba = { cerah = 0.38, hujan = 0.32, badai = 0.12, kabut = 0.18 },
}

function Seasons.isMusim(value: any): boolean
	return type(value) == "string" and Seasons.list[value] ~= nil
end

function Seasons.isAnomali(value: any): boolean
	return type(value) == "string" and table.find(Seasons.anomaliOrder, value) ~= nil
end

function Seasons.isCuaca(value: any): boolean
	return type(value) == "string" and table.find(Seasons.cuacaOrder, value) ~= nil
end

-- Roughly Nov-Mar hujan, May-Sep kemarau, the rest pancaroba (PLAN §3.3).
function Seasons.forMonth(month: number): string
	if month >= 11 or month <= 3 then
		return "hujan"
	elseif month >= 5 and month <= 9 then
		return "kemarau"
	end
	return "pancaroba"
end

function Seasons.fromUnix(timestamp: number): string
	local ok, date = pcall(function()
		return os.date("*t", timestamp)
	end)
	if ok and type(date) == "table" and type(date.month) == "number" then
		return Seasons.forMonth(date.month)
	end
	return "pancaroba"
end

-- Pure weighted pick: pass `math.random()` (or a fixture) as `roll`.
function Seasons.rollWeather(musim: string, roll: number?): string
	local weights = Seasons.weatherWeights[musim] or Seasons.weatherWeights.pancaroba
	local point = math.clamp(roll or math.random(), 0, 0.999999)
	local total = 0
	for _, cuaca in Seasons.cuacaOrder do
		total += weights[cuaca] or 0
		if point < total then
			return cuaca
		end
	end
	return "cerah"
end

return Seasons
