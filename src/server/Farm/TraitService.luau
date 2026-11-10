-- TraitService: which "Sifat" a harvest carries (v2 PLAN §3.2).
--
-- Traits come from conditions, not luck alone:
--   oplosan       the tile was force-fed (hot), always
--   basah         harvested in rain, rolled on the trait's chance
--   kering        harvested during El Nino, rolled on the trait's chance
--   organik       the plot was never fertilised this cycle, rolled on the trait's chance
--   bersertifikat a Balai Desa stamp was applied, always
--
-- Pure and rng-injected so tests can pin the rolls. FarmService builds the context from the
-- tile entry plus LiveConfig's resolved weather/anomaly.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Traits = require(Shared.Config.Traits)

local TraitService = {}

local function met(condition: string?, context): boolean
	if condition == "rain" then
		return context.weather == "hujan" or context.weather == "badai"
	elseif condition == "elNino" then
		return context.anomaly == "elNino"
	elseif condition == "unfertilised" then
		return context.fertilised ~= true
	elseif condition == "certified" then
		return context.certified == true
	end
	return false
end

-- Every trait whose condition is met, before the chance roll. Useful for UI/debug.
function TraitService.eligible(context: any?): { string }
	local ctx = context or {}
	local list = {}
	if ctx.hot == true then
		table.insert(list, Traits.hotTrait)
	end
	for _, traitId in Traits.order do
		local trait = Traits.list[traitId]
		if trait and trait.condition and met(trait.condition, ctx) then
			table.insert(list, traitId)
		end
	end
	return list
end

-- Roll the traits for one harvest. Always returns a new, sorted list.
function TraitService.roll(context: any?, rng: (() -> number)?): { string }
	local ctx = context or {}
	local random = rng or math.random
	local rolled = {}
	if ctx.hot == true then
		table.insert(rolled, Traits.hotTrait)
	end
	for _, traitId in Traits.order do
		local trait = Traits.list[traitId]
		if trait and trait.condition and met(trait.condition, ctx) then
			local chance = trait.chance or 1
			if chance >= 1 or random() < chance then
				table.insert(rolled, traitId)
			end
		end
	end
	table.sort(rolled)
	return rolled
end

return TraitService
