-- Produce: the v3 harvest sack (v2 PLAN §7.1). One stack per crop + tier + trait combo.
--
--   produce["padi|biasa|"]              clean common rice
--   produce["padi|sultan|oplosan"]      hot (oplosan) sultan rice
--
-- Keys are strings so ProfileStore can save them; the key order is crop | tier | traits,
-- with traits sorted and joined by "+" so two identical stacks always share one key.
--
-- Pure module: no Roblox APIs, safe to require from the client and from lune tests.

local Tiers = require(script.Parent.Config.Tiers)
local Traits = require(script.Parent.Config.Traits)

local Produce = {}

export type Stack = {
	crop: string,
	tier: string,
	traits: { string },
	count: number,
	qualitySum: number,
}

export type Sack = { [string]: Stack }

local SEP = "|"
local TRAIT_SEP = "+"

-- Keep only known traits, de-duplicated and sorted.
function Produce.sortTraits(traits: { string }?): { string }
	local seen = {}
	local list = {}
	local source = traits or {}
	for _, traitId in source do
		if Traits.exists(traitId) and not seen[traitId] then
			seen[traitId] = true
			table.insert(list, traitId)
		end
	end
	table.sort(list)
	return list
end

function Produce.traitKey(traits: { string }?): string
	return table.concat(Produce.sortTraits(traits), TRAIT_SEP)
end

function Produce.key(cropId: string, tier: string?, traits: { string }?): string
	local resolvedTier = if Tiers.exists(tier) then (tier :: string) else Tiers.default
	return cropId .. SEP .. resolvedTier .. SEP .. Produce.traitKey(traits)
end

function Produce.parse(key: string): (string?, string?, { string })
	local cropId, tier, traitPart = string.match(key, "^([^|]+)|([^|]*)|(.*)$")
	if not cropId then
		return nil, nil, {}
	end
	local traits = {}
	for traitId in string.gmatch(traitPart or "", "[^+]+") do
		if Traits.exists(traitId) then
			table.insert(traits, traitId)
		end
	end
	return cropId, if Tiers.exists(tier) then tier else Tiers.default, traits
end

-- Add one harvested item. Returns the stack it landed in.
function Produce.add(sack: Sack, cropId: string, quality: number, options: { tier: string?, traits: { string }? }?): Stack
	local opts = options or {}
	local tier = if Tiers.exists(opts.tier) then (opts.tier :: string) else Tiers.default
	local traits = Produce.sortTraits(opts.traits)
	local key = Produce.key(cropId, tier, traits)
	local stack = sack[key]
	if not stack then
		stack = {
			crop = cropId,
			tier = tier,
			traits = traits,
			count = 0,
			qualitySum = 0,
		}
		sack[key] = stack
	end
	stack.count += 1
	stack.qualitySum += quality
	return stack
end

function Produce.hasTrait(stack: Stack, traitId: string): boolean
	return table.find(stack.traits or {}, traitId) ~= nil
end

-- Hot produce: the Pasar refuses it and a raid confiscates it.
function Produce.isHot(stack: Stack): boolean
	local traits = stack.traits or {}
	for _, traitId in traits do
		local trait = Traits.list[traitId]
		if trait and trait.hot then
			return true
		end
	end
	return false
end

function Produce.count(sack: Sack): number
	local total = 0
	for _, stack in sack do
		total += stack.count or 0
	end
	return total
end

-- Remove every hot stack; returns how many items were confiscated.
function Produce.removeHot(sack: Sack): number
	local removed = 0
	for key, stack in sack do
		if Produce.isHot(stack) then
			removed += stack.count or 0
			sack[key] = nil
		end
	end
	return removed
end

-- Remove the clean stacks, leaving hot produce behind (Pasar sale).
function Produce.removeClean(sack: Sack): number
	local removed = 0
	for key, stack in sack do
		if not Produce.isHot(stack) then
			removed += stack.count or 0
			sack[key] = nil
		end
	end
	return removed
end

function Produce.clear(sack: Sack)
	for key in sack do
		sack[key] = nil
	end
end

-- Deep-ish copy for the replicated state snapshot.
function Produce.snapshot(sack: Sack): Sack
	local out = {}
	for key, stack in sack do
		out[key] = {
			crop = stack.crop,
			tier = stack.tier,
			traits = table.clone(stack.traits or {}),
			count = stack.count,
			qualitySum = stack.qualitySum,
		}
	end
	return out
end

return Produce
