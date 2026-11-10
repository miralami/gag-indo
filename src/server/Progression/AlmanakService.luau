-- AlmanakService: the discovery book (v2 PLAN §3.2).
--
-- Records every crop × tier × trait a player has harvested. A family page completes when
-- every crop in that family has been discovered at least once, and grants the page's
-- cosmetic for free (Cosmetics.grant).
--
-- Save shape (inside the `almanak` state section):
--   data.almanak.crops[cropId] = { tiers = { super = true }, traits = { basah = true }, count = 3 }
--   data.almanak.pages[familyId] = true

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Crops = require(Shared.Config.Crops)
local AlmanakConfig = require(Shared.Config.Almanak)
local Tiers = require(Shared.Config.Tiers)
local Traits = require(Shared.Config.Traits)

local PlayerData = require(script.Parent.Parent.Data.PlayerData)
local Cosmetics = require(script.Parent.Parent.Monetization.Cosmetics)
local State = require(script.Parent.Parent.Net.State)

local AlmanakService = {}

local function ensure(data)
	data.almanak = data.almanak or {}
	data.almanak.crops = data.almanak.crops or {}
	data.almanak.pages = data.almanak.pages or {}
	return data.almanak
end

export type Discovery = {
	first: boolean,
	newTier: boolean,
	newTraits: { string },
	pageCompleted: boolean,
	reward: string?,
	family: string,
}

-- How many crops of a family have been discovered. Returns found, total.
function AlmanakService.progress(data, familyId: string): (number, number)
	local crops = Crops.families[familyId] or {}
	local state = data.almanak or {}
	local entries = state.crops or {}
	local found = 0
	for _, cropId in crops do
		if entries[cropId] then
			found += 1
		end
	end
	return found, #crops
end

function AlmanakService.isPageComplete(data, familyId: string): boolean
	local found, total = AlmanakService.progress(data, familyId)
	return total > 0 and found >= total
end

-- Record one harvest. Returns what was new, for the reveal toast.
function AlmanakService.record(player: Player, cropId: string, tier: string?, traitList: { string }?): Discovery?
	local data = PlayerData.get(player)
	local crop = Crops.list[cropId]
	if not data or not crop then
		return nil
	end
	local almanak = ensure(data)

	local entry = almanak.crops[cropId]
	local first = entry == nil
	if not entry then
		entry = { tiers = {}, traits = {}, count = 0 }
		almanak.crops[cropId] = entry
	else
		entry.tiers = entry.tiers or {}
		entry.traits = entry.traits or {}
		entry.count = entry.count or 0
	end
	entry.count += 1

	local newTier = false
	if type(tier) == "string" and Tiers.exists(tier) and not entry.tiers[tier] then
		entry.tiers[tier] = true
		newTier = true
	end

	local newTraits = {}
	if traitList then
		for _, traitId in traitList do
			if Traits.exists(traitId) and not entry.traits[traitId] then
				entry.traits[traitId] = true
				table.insert(newTraits, traitId)
			end
		end
	end

	local pageCompleted = false
	local reward: string? = nil
	local page = AlmanakConfig.pages[crop.family]
	if page and not almanak.pages[page.family] and AlmanakService.isPageComplete(data, page.family) then
		almanak.pages[page.family] = true
		pageCompleted = true
		reward = page.reward
		if reward then
			Cosmetics.grant(player, reward)
		end
	end

	State.touch(player, "almanak")
	return {
		first = first,
		newTier = newTier,
		newTraits = newTraits,
		pageCompleted = pageCompleted,
		reward = reward,
		family = crop.family,
	}
end

return AlmanakService
