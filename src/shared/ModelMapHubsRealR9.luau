--!strict
-- ModelMapHubsRealR9: PURE data for the OFF-BY-DEFAULT "hubs_real_r9" LookDev candidate
-- (WORK_QUEUE section O item 147). No game APIs, no Instances, no Enum at load: Lune specs can
-- require this module directly.
--
-- The six hub -> building matches are the PROPOSAL in docs/v2/visual/art/BUILDING_KIT.md. They are
-- awaiting the designer and are NOT a shipping decision. No asset ID is written here: every id is
-- resolved from Shared.ModelMapBuildingsR8, so only already-verified reusable IDs can be staged.
--
-- Fit rule: a building's staged world AABB (R8 staged bbox, rotated by the hub yaw) is scaled DOWN
-- (never up) to sit inside the hub's MapSpec footprint with a small inset. HUB_FIT allows the
-- footprint to be grown by FIT_MARGIN studs on each side; the inset keeps float error well inside
-- that allowance.

local Buildings = require(script.Parent.ModelMapBuildingsR8)

local ModelMapHubsRealR9 = {}

ModelMapHubsRealR9.familyId = "hubs_real_r9"
ModelMapHubsRealR9.folderName = "LookDevHubsRealR9_hubs_real_r9"
ModelMapHubsRealR9.tagAttribute = "HubRealR9"
ModelMapHubsRealR9.hubAttribute = "HubRealR9Hub"
ModelMapHubsRealR9.slotAttribute = "HubRealR9Slot"
ModelMapHubsRealR9.scaleAttribute = "HubRealR9Scale"
ModelMapHubsRealR9.proposalAttribute = "HubRealR9Proposal"
ModelMapHubsRealR9.greyboxTag = "GreyboxWorld"
ModelMapHubsRealR9.prevTransparencyAttribute = "HubRealR9PrevTransparency"
ModelMapHubsRealR9.prevCollideAttribute = "HubRealR9PrevCanCollide"

-- Inset from the raw footprint edge on each side when computing the fit scale.
ModelMapHubsRealR9.FIT_INSET = 0.25
-- The HUB_FIT harness grows the MapSpec footprint by this much on each side.
ModelMapHubsRealR9.FIT_MARGIN = 2
-- A small building is never inflated to fill a big hub: fit means downscale only.
ModelMapHubsRealR9.MAX_SCALE = 1

ModelMapHubsRealR9.proposal = true -- pending designer yes; see BUILDING_KIT.md

-- Exact MapSpec.HUB_ORDER. One staged building per hub, in this order.
ModelMapHubsRealR9.hubOrder = { "pasar", "gelap", "warung", "ronda", "polisi", "pakrt" }

-- PROPOSAL hub -> R8 building slot. No id literals: ids come from ModelMapBuildingsR8.ids.
ModelMapHubsRealR9.mapping = {
	pasar = "indonesian_house",
	gelap = "rumah_joglo",
	warung = "warung_penyetan",
	ronda = "nipa_hut",
	polisi = "pendopo_jawa",
	pakrt = "rumah_4",
}

function ModelMapHubsRealR9.slotFor(hubKey: string): string?
	return ModelMapHubsRealR9.mapping[hubKey]
end

function ModelMapHubsRealR9.entryFor(hubKey: string): any?
	local slot = ModelMapHubsRealR9.slotFor(hubKey)
	if not slot then
		return nil
	end
	for _, entry in ipairs(Buildings.slots) do
		if entry.slot == slot then
			return entry
		end
	end
	return nil
end

-- Hub key -> verified id, resolved from the R8 map. Never invent an id here.
function ModelMapHubsRealR9.idsFor(family: string): { [string]: number }?
	if family ~= ModelMapHubsRealR9.familyId then
		return nil
	end
	local ids: { [string]: number } = {}
	for hubKey, slot in pairs(ModelMapHubsRealR9.mapping) do
		local id = Buildings.ids[slot]
		if type(id) == "number" then
			ids[hubKey] = id
		end
	end
	return ids
end

function ModelMapHubsRealR9.count(): number
	return #ModelMapHubsRealR9.hubOrder
end

-- Pure XZ AABB of a hub footprint (same rotation math as MapSpec.hubBounds, no game APIs).
function ModelMapHubsRealR9.hubBounds(hub: any): { minX: number, maxX: number, minZ: number, maxZ: number }
	local hw, hd = hub.width / 2, hub.depth / 2
	local x0, z0 = hub.x, hub.z
	local a = math.rad(hub.yaw or 0)
	local cos, sin = math.cos(a), math.sin(a)
	local minX, maxX = math.huge, -math.huge
	local minZ, maxZ = math.huge, -math.huge
	for _, corner in { { -hw, -hd }, { hw, -hd }, { -hw, hd }, { hw, hd } } do
		local x = x0 + corner[1] * cos + corner[2] * sin
		local z = z0 - corner[1] * sin + corner[2] * cos
		minX, maxX = math.min(minX, x), math.max(maxX, x)
		minZ, maxZ = math.min(minZ, z), math.max(maxZ, z)
	end
	return { minX = minX, maxX = maxX, minZ = minZ, maxZ = maxZ }
end

-- World AABB extents of a staged R8 bbox after a Y yaw. At yaw 0/180 this is W x D; at yaw 90
-- the axes swap, which is exactly the ronda case.
function ModelMapHubsRealR9.worldExtents(entry: any, yaw: number?): (number, number)
	local a = math.rad(yaw or 0)
	local c, s = math.abs(math.cos(a)), math.abs(math.sin(a))
	return entry.stagedWidth * c + entry.stagedDepth * s, entry.stagedWidth * s + entry.stagedDepth * c
end

function ModelMapHubsRealR9.fitScale(hub: any, entry: any): number?
	if type(hub) ~= "table" or type(entry) ~= "table" then
		return nil
	end
	local bounds = ModelMapHubsRealR9.hubBounds(hub)
	local capX = bounds.maxX - bounds.minX - ModelMapHubsRealR9.FIT_INSET * 2
	local capZ = bounds.maxZ - bounds.minZ - ModelMapHubsRealR9.FIT_INSET * 2
	local worldX, worldZ = ModelMapHubsRealR9.worldExtents(entry, hub.yaw)
	if capX <= 0 or capZ <= 0 or worldX <= 0 or worldZ <= 0 then
		return nil
	end
	return math.max(0, math.min(ModelMapHubsRealR9.MAX_SCALE, capX / worldX, capZ / worldZ))
end

-- One placement plan for a MapSpec hub, or nil when there is no good match / no verified id.
function ModelMapHubsRealR9.plan(hub: any): any?
	if type(hub) ~= "table" or type(hub.key) ~= "string" then
		return nil
	end
	local entry = ModelMapHubsRealR9.entryFor(hub.key)
	if not entry then
		return nil
	end
	local id = Buildings.ids[entry.slot]
	if type(id) ~= "number" then
		return nil
	end
	local fit = ModelMapHubsRealR9.fitScale(hub, entry)
	if not fit or fit <= 0 then
		return nil
	end
	local worldX, worldZ = ModelMapHubsRealR9.worldExtents(entry, hub.yaw)
	return {
		hub = hub.key,
		hubModel = hub.model,
		slot = entry.slot,
		id = id,
		yaw = hub.yaw or 0,
		baseScale = entry.scale,
		fitScale = fit,
		scale = entry.scale * fit,
		width = worldX * fit,
		depth = worldZ * fit,
		height = entry.stagedHeight * fit,
		centreX = hub.x,
		centreZ = hub.z,
		note = "PROPOSAL pending designer",
	} :: any
end

-- Plans for the supplied MapSpec hubs, in HUB_ORDER. Unmatched hubs are skipped (the applier
-- reports each skip); the caller can compare #plans against count().
function ModelMapHubsRealR9.plans(hubs: any): { any }
	local byKey: { [string]: any } = {}
	if type(hubs) == "table" then
		for _, hub in ipairs(hubs) do
			if type(hub) == "table" and type(hub.key) == "string" then
				byKey[hub.key] = hub
			end
		end
	end
	local plans = {}
	for _, key in ipairs(ModelMapHubsRealR9.hubOrder) do
		local plan = ModelMapHubsRealR9.plan(byKey[key])
		if plan then
			plans[#plans + 1] = plan
		end
	end
	return plans
end

-- HUB_FIT predicate for a plan against a MapSpec footprint grown by FIT_MARGIN on each side.
function ModelMapHubsRealR9.fits(plan: any, bounds: any): boolean
	if type(plan) ~= "table" or type(bounds) ~= "table" then
		return false
	end
	local m = ModelMapHubsRealR9.FIT_MARGIN
	local halfX, halfZ = plan.width / 2, plan.depth / 2
	return plan.centreX - halfX >= bounds.minX - m
		and plan.centreX + halfX <= bounds.maxX + m
		and plan.centreZ - halfZ >= bounds.minZ - m
		and plan.centreZ + halfZ <= bounds.maxZ + m
end

return ModelMapHubsRealR9
