--!nocheck
-- ModelMapNpcsIdleR8: PURE data + deterministic sway simulation for WORK_QUEUE section M item 87.
-- No engine APIs, no Instances and no Enum: everything here runs under Lune. The ten villager
-- outfits come from the two already-verified pure catalog maps (R7 + R8, 5 roles each); the single
-- real catalog idle animation ID is sourced from the catalog API and recorded in ASSET_MANIFEST.md.
-- The server applier owns the rigs, the Animator track and ONE Heartbeat loop; the harness measures
-- the very same step() function that loop calls, so the cost figure is the real per-frame cost.

local R7 = require(script.Parent.ModelMapNpcsR7)
local R8 = require(script.Parent.ModelMapNpcsR8)

local Idle = {}

Idle.id = "npcs_idle_r8"
Idle.familyId = "npcs_idle_r8"
Idle.lookDevId = "npcs_idle_r8"
Idle.folder = "LookDevNpcsIdleR8_npcs_idle_r8"

-- "Standing Idle", AssetTypeId 61, sourced via catalog search API + economy GET and proven to
-- load/play on R15 rigs in the Studio Server VM. Never invent another ID.
Idle.animationId = 71483261700852
Idle.animationAsset = "rbxassetid://71483261700852"
Idle.animationName = "Standing Idle"
Idle.animationSource = "docs/v2/visual/art/ASSET_MANIFEST.md"

Idle.MAX_STEP_MS = 0.3
Idle.MAX_SWAY_DEG = 1 -- the brief's ceiling: <=1 degree reads as breathing, not walking
Idle.SWAY_SPEED = 0.6 -- rad/s, slow enough that a full cycle takes about 10 seconds
Idle.MAX_DT = 0.25
Idle.DT = 1 / 60
Idle.SIM_SECONDS = 60
Idle.STEPS = 3600
Idle.VILLAGER_COUNT = 10
Idle.SPACING = 6

-- Accept either a full source map (with .roles/.roleIds/.catalog) or a bare .catalog table; the
-- role/colour data always comes from the two verified maps, never from a made-up descriptor.
local function split(value, fallback)
	if type(value) == "table" and type(value.roles) == "table" and type(value.roleIds) == "table" then
		return value, value.catalog or {}
	end
	if type(value) == "table" then
		return fallback, value
	end
	return fallback, fallback.catalog or {}
end

-- Ordered 5 + 5 role descriptors. Each entry holds the verified catalog outfit and plain colour
-- triples copied from the existing role maps.
function Idle.roles(catalogR7, catalogR8)
	local r7, outfitsR7 = split(catalogR7, R7)
	local r8, outfitsR8 = split(catalogR8, R8)
	local out = {}
	local function collect(source, outfits, isR7)
		local roles = source.roles or {}
		for _, roleName in ipairs(source.roleIds or {}) do
			local role = roles[roleName] or {}
			out[#out + 1] = {
				role = roleName,
				isR7 = isR7,
				source = if isR7 then "r7" else "r8",
				catalog = outfits[roleName] or {},
				colours = {
					skin = role.skin,
					shirt = role.shirt,
					pants = role.pants,
				},
				bodyHeightScale = role.bodyHeightScale,
				headScale = role.headScale,
			}
		end
	end
	collect(r7, outfitsR7, true)
	collect(r8, outfitsR8, false)
	return out
end

-- Two five-wide rows: the original z=8 row and the second z=14 row. X, y, yaw and target height
-- are copied verbatim from the existing pure slot maps.
function Idle.slots(slotsR7, slotsR8)
	local a = slotsR7 or R7.slots
	local b = slotsR8 or R8.slots
	local out = {}
	for index = 1, 5 do
		local slot = a[index]
		out[index] = {
			slot = slot.slot,
			x = (index - 3) * Idle.SPACING,
			y = slot.y,
			z = slot.z,
			ry = slot.ry,
			targetHeight = slot.targetHeight,
			source = "r7",
		}
	end
	for index = 1, 5 do
		local slot = b[index]
		out[5 + index] = {
			slot = slot.slot,
			x = (index - 3) * Idle.SPACING,
			y = slot.y,
			z = slot.z,
			ry = slot.ry,
			targetHeight = slot.targetHeight,
			source = "r8",
		}
	end
	return out
end

-- Deterministic sine in degrees, clamped to MAX_SWAY_DEG (never a walking stride).
function Idle.swayFor(seed, t)
	local phase = (type(seed) == "number" and seed or 0) * 0.37
	local time = type(t) == "number" and t or 0
	local value = math.sin(time * Idle.SWAY_SPEED + phase) * Idle.MAX_SWAY_DEG
	return math.max(-Idle.MAX_SWAY_DEG, math.min(Idle.MAX_SWAY_DEG, value))
end

-- Fresh per-villager state. `seed` is deterministic: no math.random and no global state.
function Idle.entries(slots)
	local list = {}
	for index, slot in ipairs(slots or Idle.slots()) do
		list[index] = { seed = index, slot = slot.slot, t = 0, sway = Idle.swayFor(index, 0) }
	end
	return list
end

-- The real hot path. Mutates each entry's phase in place (no per-step allocation) and returns the
-- degree list. The applier's Heartbeat and the 3600-step cost harness both call this function.
function Idle.step(entries, dt)
	local stepDt = math.max(0, math.min(type(dt) == "number" and dt or 0, Idle.MAX_DT))
	local angles = {}
	for index, entry in ipairs(entries) do
		entry.t += stepDt
		local angle = Idle.swayFor(entry.seed, entry.t)
		entry.sway = angle
		angles[index] = angle
	end
	return angles
end

-- Convenience horizon for the specs/harness. Returns the last angle list and the step count.
function Idle.simulate(entries, seconds, dt)
	local stepDt = type(dt) == "number" and dt or Idle.DT
	local count = math.max(1, math.ceil((type(seconds) == "number" and seconds or Idle.SIM_SECONDS) / stepDt))
	local angles
	for _ = 1, count do
		angles = Idle.step(entries, stepDt)
	end
	return angles, count
end

return Idle
