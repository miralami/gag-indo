-- LookDev: opt-in, OFF-BY-DEFAULT look-development candidates for designer review (WORK_QUEUE item 9).
--
-- This module is the single source of truth for BOTH candidates and the toggle that reveals them.
-- It is pure (no game APIs at load time) so tests/specs/lookdev_candidates_spec.luau can prove the
-- gate and the plans. The real-world appliers live in the thin adapters:
--   src/client/World/LookDevPlaza.luau   -- candidate "plaza_lighting"
--   src/server/World/LookDevWalkin.luau  -- candidate "police_walkin"
--   src/client/UI/LookDevIcons.luau       -- candidate "icons" (agent-made icon CANDIDATES)
--   src/client/World/LookDevTextures.luau -- candidate "textures" (seamless texture CANDIDATES)
--   src/client/World/LookDevNpcs.luau     -- candidate "npcs" (procedural caricature detail CANDIDATES)
--   src/client/World/LookDevCrops.luau    -- candidate "crops" (low-poly crop growth-stage CANDIDATES)
--   src/client/World/LookDevHubProps.luau -- candidate "hubprops" (hub counter/desk/stall detail CANDIDATES)
-- Each registers itself with LookDev.register() at boot. Enable from the Studio command bar:
--   require(game.ReplicatedStorage.Shared.LookDev):enable("plaza_lighting")
--   require(game.ReplicatedStorage.Shared.LookDev):enable("police_walkin")
--   require(game.ReplicatedStorage.Shared.LookDev):enable("icons")
--   require(game.ReplicatedStorage.Shared.LookDev):enable("textures")
--   require(game.ReplicatedStorage.Shared.LookDev):enable("npcs")
--   require(game.ReplicatedStorage.Shared.LookDev):enable("crops")
--   require(game.ReplicatedStorage.Shared.LookDev):enable("hubprops")
--   require(game.ReplicatedStorage.Shared.LookDev):disable()   -- restores the original look
--
-- The gate needs an explicit Studio-only opt-in, is never persisted, and can never be on in a
-- published server (RunService:IsStudio() is false there). Nothing is applied until enable() is
-- called with a registered applier, so the shipping game is byte-for-byte unaffected.
--
-- "No asset IDs": materials are names from a built-in Enum.Material allowlist and all colours are
-- plain {r,g,b} arrays consumed by Color3.fromRGB at apply time. No asset IDs of any kind are used.
--
-- STATUS: every candidate below is a candidate AWAITING DESIGNER YES. None is approved or shipped.

local RaidCutscene = require(script.Parent.Config.RaidCutscene)

local LookDev = {}

LookDev.STATUS = "candidate, awaiting designer yes"
LookDev.STYLE = "cartoonish-realism"
LookDev.IDS = { "plaza_lighting", "police_walkin", "icons", "textures", "npcs", "crops", "hubprops" }

-- Built-in Roblox materials only. This is also the guard the spec checks: a value outside this
-- list is rejected because it could be an asset-backed or otherwise non-procedural material.
local BUILTIN_MATERIALS = {
	Grass = true, Ground = true, Sand = true, Mud = true, Rock = true, Basalt = true,
	Sandstone = true, Limestone = true, Slate = true, Granite = true, Marble = true,
	Cobblestone = true, Brick = true, Concrete = true, Asphalt = true,
	WoodPlanks = true, Wood = true, Fabric = true, Paper = true,
	SmoothPlastic = true, Plastic = true, Painted = true, Metal = true,
	Water = true, Ice = true, Snow = true, Glacier = true, Leaf = true,
}

function LookDev.isBuiltinMaterial(name: any): boolean
	return type(name) == "string" and BUILTIN_MATERIALS[name] == true
end

-- The two candidates. Pure data only.
LookDev.candidates = {
	plaza_lighting = {
		id = "plaza_lighting",
		title = "Pasar hub — alternative material + lighting preset",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		hub = "pasar",
		-- Part-name keyword -> built-in material. Only matching parts under the Pasar model change.
		materials = {
			ground = "Sandstone",
			wood = "WoodPlanks",
			roof = "Brick",
			road = "Cobblestone",
		},
		-- An alternative cartoonish-realism grade: brighter, cleaner midday warmth with a gentle
		-- teal bounce, deliberately distinct from the golden-hour Seasons preset so the designer
		-- can compare the two. Colour channels are plain {r,g,b} arrays (no Color3 at load).
		lighting = {
			clockTime = 11.4,
			brightness = 2.2,
			fogEnd = 2600,
			fogColor = { 214, 226, 224 },
			ambient = { 96, 112, 116 },
			outdoorAmbient = { 150, 168, 170 },
			colorShiftTop = { 210, 232, 255 },
			colorShiftBottom = { 122, 116, 96 },
			atmosphereDensity = 0.22,
			atmosphereHaze = 1.1,
			atmosphereColor = { 208, 230, 232 },
			atmosphereDecay = { 120, 150, 160 },
			tint = { 255, 250, 238 },
			saturation = 0.16,
			contrast = 0.06,
			bloom = 0.22,
		},
	},

	police_walkin = {
		id = "police_walkin",
		title = "Police NPC walk-in timed to the raid cutscene walkin shot",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		-- Reuses the existing police model + NpcFactory walk API through Village.police[1]; no new
		-- model and no asset IDs. The server adapter teleports it off-frame, walks it to the road
		-- anchor while the "walkin" shot plays, then teleports it home on disable().
		npc = "polisi",
		walkinShotId = "walkin",
		focusAnchor = "road",
		spawnOffset = { x = -34, z = -16 }, -- start, relative to the road focus anchor
	},

	icons = {
		id = "icons",
		title = "Agent-made painted icon set for all IconMap slots (crops, tiers, currency, phone apps)",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		-- IDs deliberately NOT here: they live in Shared.IconMap.candidateIds so this module and
		-- its adapters stay ID-free. The adapter swaps Visuals.icons[*].id only while enabled.
		idsSource = "Shared.IconMap.candidateIds",
		render = "docs/v2/visual/art/icons/render/contact_sheet.png",
	},

	textures = {
		id = "textures",
		title = "Agent-made seamless painted textures for the Pasar surface preset",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		-- IDs deliberately NOT here: they live in Shared.TextureMap.candidateIds. The adapter
		-- sets Visuals.textures slots only while enabled and restores them to 0 on disable.
		idsSource = "Shared.TextureMap.candidateIds",
		render = "docs/v2/visual/art/textures/render/contact_sheet.png",
		slotCount = 7,
	},

	npcs = {
		id = "npcs",
		title = "Caricature detail meshes for the box NPCs (Pak RT, Tengkulak, Polisi, collector)",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		-- Procedural geometry, no uploaded asset IDs. Recipe source is pure data in
		-- Shared.NpcModelCandidates so the no-ID guard still holds.
		idsSource = "Shared.NpcModelCandidates.recipes",
		render = "docs/v2/visual/CANDIDATES.md",
	},

	crops = {
		id = "crops",
		title = "Low-poly growth-stage models (bibit/tumbuh/siap) for all 12 crops",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		-- Pure-data recipe source, no uploaded asset IDs. partsFor() is the single source used by
		-- the Studio adapter and the gallery preview generator.
		idsSource = "Shared.CropModelCandidates.partsFor",
		render = "docs/v2/visual/art/crops/render/contact_sheet.png",
		stageCount = 3,
		cropCount = 12,
	},

	hubprops = {
		id = "hubprops",
		title = "Hero-prop details (counter, stall, desk, table, lantern, sign) for the four shop hubs",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		-- Pure-data recipe source, no uploaded asset IDs. partsFor() is the single source used by
		-- the Studio adapter and the gallery preview generator.
		idsSource = "Shared.HubPropCandidates.partsFor",
		render = "docs/v2/visual/art/hubprops/render/contact_sheet.png",
		hubCount = 4,
	},
}

function LookDev.isCandidate(id: any): boolean
	return type(id) == "string" and LookDev.candidates[id] ~= nil
end

-- Pure plan for a candidate, or nil for an unknown id. No instances, no Enum lookups.
function LookDev.plan(id: string): any
	if id == "plaza_lighting" then
		local c = LookDev.candidates.plaza_lighting
		return {
			id = id,
			hub = c.hub,
			materials = table.clone(c.materials),
			lighting = table.clone(c.lighting),
		}
	elseif id == "police_walkin" then
		local c = LookDev.candidates.police_walkin
		local duration = 1.8 -- fallback if the cutscene timeline is unavailable
		for _, shot in RaidCutscene.shots do
			if shot.id == c.walkinShotId then
				duration = shot.duration
				break
			end
		end
		local anchor = RaidCutscene.anchorFor(c.focusAnchor) or { x = 0, y = 2, z = -28 }
		local ox, oz = c.spawnOffset.x, c.spawnOffset.z
		local distance = math.sqrt(ox * ox + oz * oz)
		return {
			id = id,
			npc = c.npc,
			shotId = c.walkinShotId,
			duration = duration,
			anchor = { x = anchor.x, y = anchor.y, z = anchor.z },
			spawn = { x = anchor.x + ox, y = anchor.y, z = anchor.z + oz },
			-- Match the walk-in distance to the shot so the NPC arrives as the letter slam lands.
			speed = distance / math.max(duration, 0.1),
		}
	elseif id == "icons" then
		local c = LookDev.candidates.icons
		return {
			id = id,
			idsSource = c.idsSource,
			render = c.render,
		}
	elseif id == "textures" then
		local c = LookDev.candidates.textures
		return {
			id = id,
			idsSource = c.idsSource,
			render = c.render,
			slotCount = c.slotCount,
		}
	elseif id == "npcs" then
		local c = LookDev.candidates.npcs
		return {
			id = id,
			idsSource = c.idsSource,
			render = c.render,
		}
	elseif id == "crops" then
		local c = LookDev.candidates.crops
		return {
			id = id,
			idsSource = c.idsSource,
			render = c.render,
			stageCount = c.stageCount,
			cropCount = c.cropCount,
		}
	elseif id == "hubprops" then
		local c = LookDev.candidates.hubprops
		return {
			id = id,
			idsSource = c.idsSource,
			render = c.render,
			hubCount = c.hubCount,
		}
	end
	return nil
end

-- Gate + applier registry -----------------------------------------------------------------------

local enabledId: string? = nil
local appliers: { [string]: { apply: (any) -> (), restore: () -> () } } = {}

-- The single gate rule: a LITERAL studio == true. A published server, a nil flag, or a truthy
-- non-boolean all refuse. Kept pure so the spec can prove every branch without Roblox.
function LookDev.canEnable(opts: any): boolean
	return type(opts) == "table" and opts.studio == true
end

-- A thin adapter registers its appliers here at boot. Unknown ids and non-tables are ignored.
function LookDev.register(id: string, applier: any)
	if LookDev.isCandidate(id) and type(applier) == "table"
		and type(applier.apply) == "function" and type(applier.restore) == "function" then
		appliers[id] = applier
	end
end

function LookDev.hasApplier(id: string): boolean
	return appliers[id] ~= nil
end

-- Enable a candidate. `opts.studio` defaults to RunService:IsStudio() when omitted so the Studio
-- command-bar call is one line; pass it explicitly in specs. Never persists the flag.
function LookDev.enable(id: string, opts: any?): (boolean, string?)
	if not LookDev.isCandidate(id) then
		return false, "unknown candidate"
	end
	opts = if type(opts) == "table" then table.clone(opts) else {}
	if opts.studio == nil then
		local ok, runService = pcall(function()
			return game:GetService("RunService")
		end)
		opts.studio = ok and runService and runService:IsStudio() == true or false
	end
	if not LookDev.canEnable(opts) then
		return false, "look-dev candidates are Studio-only"
	end
	-- Only one candidate is active at a time; switching restores the previous look first.
	if enabledId and enabledId ~= id then
		LookDev.disable()
	end
	enabledId = id
	local applier = appliers[id]
	if applier then
		local ok, err = pcall(applier.apply, LookDev.plan(id))
		if not ok then
			return false, "applier failed: " .. tostring(err)
		end
	end
	return true, nil
end

-- Restore the original look and turn the toggle off. Safe to call repeatedly.
function LookDev.disable(): boolean
	if not enabledId then
		return false
	end
	local applier = appliers[enabledId]
	if applier then
		pcall(applier.restore)
	end
	enabledId = nil
	return true
end

function LookDev.current(): string?
	return enabledId
end

return LookDev
