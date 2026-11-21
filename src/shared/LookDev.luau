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
--   src/client/World/LookDevSounds.luau   -- candidate "sounds" (free Creator Store music CANDIDATES)
--   src/client/World/LookDevCorner.luau   -- candidate "corner" (60x60 warung/road/sawah corner)
--   src/client/World/LookDevTexturesR3.luau -- candidate "textures_r3" (real CC0 PBR MaterialVariants)
--   src/client/World/LookDevDayCycle.luau -- candidate "day_cycle" (live phase tweens, lamps, silent beds)
--   src/client/UI/LookDevIconsR3.luau  -- candidate "icons_r3" (27 revised original icon CANDIDATES)
--   src/server/World/LookDevModelsR3.luau -- candidates "buildings_r3", "vegetation_r3", "props_r3", "npcs_r3"
--   src/client/World/LookDevSkyR3.luau -- candidate "sky_r3" (CC0 HDRI cube faces + ridge + haze)
--   src/client/World/LookDevTexturesR4.luau -- candidate "textures_r4" (12 CC0 PBR MaterialVariants)
--   src/client/World/LookDevSkyR4.luau -- candidates "sky_r4_a", "sky_r4_b", "sky_r4_c" (3 CC0 HDRI skies)
--   src/client/World/LookDevSkyR6.luau -- candidates "sky_r6_a".."sky_r6_f" (6 Creator Store skies)
--   src/server/World/LookDevSpawnGroundR6.luau -- candidate "spawn_ground_r6" (full dirt road corridor + grass mask)
--   src/client/World/LookDevTerrainR6.luau -- candidates "terrain_r6_a"/"terrain_r6_b" (Terrain colours, no Terrain texture)
--   src/server/World/LookDevModelsBuildingsR4.luau -- candidate "buildings_r4" (server-only)
--   src/server/World/LookDevModelsVegetationR4.luau -- candidate "vegetation_r4" (server-only)
--   src/server/World/LookDevModelsVegetationR6.luau -- candidate "vegetation_r6" (server-only)
--   src/server/World/LookDevModelsNpcsR6.luau -- candidate "npcs_r6" (server-only)
--   src/server/World/LookDevModelsPropsR6.luau -- candidate "props_r6" (server-only)
--   src/server/World/LookDevModelsPropsR4.luau -- candidate "props_r4" (server-only)
--   src/server/World/LookDevModelsNpcsR4.luau -- candidate "npcs_r4" (server-only)
--   src/server/World/LookDevPlotsR8.luau -- candidate "plots_r8" (plot fences and gates, server-only)
--   src/server/World/LookDevRiverR8.luau -- candidate "river_r8" (banks and bridge rails, server-only)
--   src/server/World/LookDevPathEdgeR8.luau -- candidate "pathedge_r8" (path edge dressing, server-only)
--   src/client/World/LookDevWaterR8.luau -- candidates "water_r8_a/b/c" (river water, client-only)
--   src/server/World/LookDevBuildingsR8.luau -- candidate "buildings_r8" (six Creator Store buildings, server-only)
--   src/server/World/LookDevFacadesR8.luau -- candidate "facades_r8" (hub facade details, server-only)
--   src/server/World/LookDevHubPropsR8.luau -- candidate "hubprops_r8" (hub vernacular props, server-only)
-- Each registers itself with LookDev.register() at boot. Model families MUST be enabled from the
-- Server datamodel: InsertService:LoadAsset is blocked on the client. Enable from the Studio command bar:
--   require(game.ReplicatedStorage.Shared.LookDev).enable("plaza_lighting")
--   require(game.ReplicatedStorage.Shared.LookDev).enable("police_walkin")
--   require(game.ReplicatedStorage.Shared.LookDev).enable("icons")
--   require(game.ReplicatedStorage.Shared.LookDev).enable("textures")
--   require(game.ReplicatedStorage.Shared.LookDev).enable("npcs")
--   require(game.ReplicatedStorage.Shared.LookDev).enable("crops")
--   require(game.ReplicatedStorage.Shared.LookDev).enable("hubprops")
--   require(game.ReplicatedStorage.Shared.LookDev).enable("sounds")
--   require(game.ReplicatedStorage.Shared.LookDev).enable("corner")
--   require(game.ReplicatedStorage.Shared.LookDev).enable("textures_r3")
--   require(game.ReplicatedStorage.Shared.LookDev).enable("day_cycle")
--   require(game.ReplicatedStorage.Shared.LookDev).enable("icons_r3")
--   require(game.ReplicatedStorage.Shared.LookDev).enable("sky_r3")
--   -- from the Server datamodel: buildings_r3 / vegetation_r3 / props_r3 / npcs_r3
--   LookDev.enable("textures_r4")
--   LookDev.enable("sky_r4_a") -- or LookDev.enable("sky_r4_b") / LookDev.enable("sky_r4_c")
--   LookDev.enable("sky_r6_a") -- or sky_r6_b / sky_r6_c / sky_r6_d / sky_r6_e / sky_r6_f
--   -- from the Server datamodel: LookDev.enable("buildings_r8") / LookDev.enable("facades_r8") / LookDev.enable("hubprops_r8")
--   LookDev.enable("spawn_ground_r6")
--   LookDev.enable("terrain_r6_a") -- or LookDev.enable("terrain_r6_b")
--   -- server-only: LookDev.enable("buildings_r4") / LookDev.enable("vegetation_r4") / LookDev.enable("props_r4") / LookDev.enable("npcs_r4")
--   -- round-6 server-only: LookDev.enable("vegetation_r6") / LookDev.enable("npcs_r6") / LookDev.enable("props_r6")
--   require(game.ReplicatedStorage.Shared.LookDev).disable()   -- restores the original look
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
LookDev.IDS = {
	"plaza_lighting",
	"police_walkin",
	"icons",
	"textures",
	"npcs",
	"crops",
	"hubprops",
	"sounds",
	"corner",
	"textures_r3",
	"day_cycle",
	"icons_r3",
	"buildings_r3",
	"vegetation_r3",
	"props_r3",
	"npcs_r3",
	"sky_r3",
	"textures_r4",
	"sky_r4_a",
	"sky_r4_b",
	"sky_r4_c",
	"buildings_r4",
	"vegetation_r4",
	"props_r4",
	"npcs_r4",
	"spawn_ground_r5",
	"vegetation_r5",
	"sky_r5",
	"props_r5",
	"npcs_r5",
	"spawn_r5",
	"sky_r6_a",
	"sky_r6_b",
	"sky_r6_c",
	"sky_r6_d",
	"sky_r6_e",
	"sky_r6_f",
	"spawn_ground_r6",
	"terrain_r6_a",
	"terrain_r6_b",
	"vegetation_r6",
	"npcs_r6",
	"props_r6",
	"vegetation_r7",
	"npcs_r7",
	"props_r7",
	"hubveg_r8",
	"plots_r8",
	"sawah_r8",
	"river_r8",
	"pathedge_r8",
	"water_r8_a",
	"water_r8_b",
	"water_r8_c",
	"buildings_r8",
	"facades_r8",
	"hubprops_r8",
}

-- Built-in Roblox materials only. This is also the guard the spec checks: a value outside this
-- list is rejected because it could be an asset-backed or otherwise non-procedural material.
local BUILTIN_MATERIALS = {
	Grass = true,
	Ground = true,
	Sand = true,
	Mud = true,
	Rock = true,
	Basalt = true,
	Sandstone = true,
	Limestone = true,
	Slate = true,
	Granite = true,
	Marble = true,
	Cobblestone = true,
	Brick = true,
	Concrete = true,
	Asphalt = true,
	WoodPlanks = true,
	Wood = true,
	Fabric = true,
	Cardboard = true,
	Paper = true,
	SmoothPlastic = true,
	Plastic = true,
	Painted = true,
	Metal = true,
	Water = true,
	Ice = true,
	Snow = true,
	Glacier = true,
	Leaf = true,
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

	sounds = {
		id = "sounds",
		title = "Free Creator Store music beds for the sawah and hutan zones",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		-- IDs deliberately NOT here: they live in Shared.SoundMap.candidateIds (assetUrl builds the
		-- Roblox asset URL string). The adapter creates Sounds into the round-1 JD_<group> SoundGroups
		-- only while enabled and destroys them on disable; Config/Audio id slots stay 0.
		idsSource = "Shared.SoundMap.candidateIds",
		render = "docs/v2/evidence/h/2026-11-19-sound-candidates/REPORT.md",
		soundCount = 2,
	},

	corner = {
		id = "corner",
		title = "60x60 warung / road bend / sawah edge corner at golden hour",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		-- Pure-data recipe source, no uploaded asset IDs. The adapter builds it in its own
		-- Workspace Folder and restores the previous Lighting.ClockTime on disable.
		idsSource = "Shared.LookDevCorner.parts",
		render = "docs/v2/visual/art/corner/README.md",
		size = 60,
		featureCount = 3,
		cameraCount = 3,
	},

	textures_r3 = {
		id = "textures_r3",
		title = "Nine real CC0 Poly Haven PBR MaterialVariants for village surfaces",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		-- IDs deliberately NOT here: they live in Shared.TextureMapR3.ids. The adapter creates
		-- temporary MaterialVariants and restores every MeshPart on disable.
		idsSource = "Shared.TextureMapR3.ids",
		render = "docs/v2/visual/art/textures_r3/render/contact_sheet.png",
		variantCount = 9,
		mapCount = 27,
	},

	day_cycle = {
		id = "day_cycle",
		title = "Day cycle — 20–40 s phase tweens, Rendah night lamps, five silent beds",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		idsSource = "Shared.World.DayCycleLive",
		render = "docs/v2/visual/art/daycycle/README.md",
	},

	icons_r3 = {
		id = "icons_r3",
		title = "Revised original icon set — 27 r3 redraws behind a Studio-only toggle",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		-- IDs deliberately NOT here: they live in Shared.IconMapR3.ids. The adapter swaps
		-- Visuals.icons slots and restores their previous values on disable.
		idsSource = "Shared.IconMapR3.ids",
		render = "docs/v2/visual/art/icons/render_r3/contact_after.png",
		iconCount = 27,
	},

	buildings_r3 = {
		id = "buildings_r3",
		title = "Village buildings — stilt house, coop, sawmill shed in the 60x60 corner",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		idsSource = "Shared.ModelMapR3.families.buildings_r3",
		render = "docs/v2/visual/art/models_r3/INTEGRATION.md",
		modelCount = 3,
	},

	vegetation_r3 = {
		id = "vegetation_r3",
		title = "Tropical vegetation — CC0 palm/bamboo plus designer-build banana, mango, shrubs",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		idsSource = "Shared.ModelMapR3.families.vegetation_r3",
		render = "docs/v2/visual/art/models_r3/INTEGRATION.md",
		modelCount = 6,
	},

	props_r3 = {
		id = "props_r3",
		title = "Village props — gerobak, well, market stall, bamboo fence, tools",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		idsSource = "Shared.ModelMapR3.families.props_r3",
		render = "docs/v2/visual/art/models_r3/INTEGRATION.md",
		modelCount = 5,
	},

	npcs_r3 = {
		id = "npcs_r3",
		title = "Villagers — two CC0 rigged bodies plus four distinct original silhouettes",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		idsSource = "Shared.ModelMapR3.families.npcs_r3",
		render = "docs/v2/visual/art/models_r3/INTEGRATION.md",
		modelCount = 6,
	},

	sky_r3 = {
		id = "sky_r3",
		title = "Overcast tropical sunrise HDRI cube sky with ridge silhouette and Atmosphere haze",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		idsSource = "Shared.SkyMapR3.ids",
		render = "docs/v2/visual/art/sky_r3/README.md",
		faceCount = 6,
	},

	textures_r4 = {
		id = "textures_r4",
		title = "Twelve real CC0 Poly Haven PBR MaterialVariants for village surfaces (round 4)",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		-- IDs deliberately NOT here: they live in Shared.TextureMapR4.ids. The adapter creates
		-- temporary MaterialVariants and restores every MeshPart on disable.
		idsSource = "Shared.TextureMapR4.ids",
		render = "docs/v2/visual/art/textures_r4/README.md",
		variantCount = 12,
		mapCount = 36,
	},

	sky_r4_a = {
		id = "sky_r4_a",
		title = "Clear coastal afternoon CC0 HDRI cube sky (round 4, option a)",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		-- IDs deliberately NOT here: they live in Shared.SkyMapR4.sets.a.ids.
		idsSource = "Shared.SkyMapR4.sets.a.ids",
		render = "docs/v2/visual/art/sky_r4/README.md",
		faceCount = 6,
	},

	sky_r4_b = {
		id = "sky_r4_b",
		title = "Golden hour CC0 HDRI cube sky (round 4, option b)",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		-- IDs deliberately NOT here: they live in Shared.SkyMapR4.sets.b.ids.
		idsSource = "Shared.SkyMapR4.sets.b.ids",
		render = "docs/v2/visual/art/sky_r4/README.md",
		faceCount = 6,
	},

	sky_r4_c = {
		id = "sky_r4_c",
		title = "Light overcast CC0 HDRI cube sky (round 4, option c)",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		-- IDs deliberately NOT here: they live in Shared.SkyMapR4.sets.c.ids.
		idsSource = "Shared.SkyMapR4.sets.c.ids",
		render = "docs/v2/visual/art/sky_r4/README.md",
		faceCount = 6,
	},

	buildings_r4 = {
		id = "buildings_r4",
		title = "Village buildings (round 4) — real CC0 models, server-only review",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		idsSource = "Shared.ModelMapBuildingsR4",
		render = "docs/v2/visual/art/models_r4/buildings/HANDOFF.md",
		modelCount = 4,
	},

	vegetation_r4 = {
		id = "vegetation_r4",
		title = "Tropical vegetation (round 4) — real CC0 models, server-only review",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		idsSource = "Shared.ModelMapVegetationR4",
		render = "docs/v2/visual/art/models_r4/vegetation/HANDOFF.md",
		modelCount = 5,
	},

	props_r4 = {
		id = "props_r4",
		title = "Village props (round 4) — real CC0 models, server-only review",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		idsSource = "Shared.ModelMapPropsR4",
		render = "docs/v2/visual/art/models_r4/props/HANDOFF.md",
		modelCount = 7,
	},

	npcs_r4 = {
		id = "npcs_r4",
		title = "Villager models (round 4) — real CC0 models, server-only review",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		idsSource = "Shared.ModelMapNpcsR4",
		render = "docs/v2/visual/art/models_r4/npcs/HANDOFF.md",
		modelCount = 5,
	},

	spawn_ground_r5 = {
		id = "spawn_ground_r5",
		title = "Dirt tanah paths at spawn, no road kerbs (round 5, server-only review)",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		-- Pure geometry/colour data; the default Greybox road design stays untouched.
		idsSource = "Shared.SpawnGroundMapR5",
		render = "docs/v2/visual/SPAWN_DRESSING.md",
	},

	vegetation_r5 = {
		id = "vegetation_r5",
		title = "Cleaned spawn vegetation: pisang clusters, dense bamboo, no kelapa or pines (round 5)",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		-- IDs are reused from Shared.ModelMapVegetationR4 through this module.
		idsSource = "Shared.ModelMapVegetationR5",
		render = "docs/v2/visual/art/vegetation_r5/MANIFEST.md",
	},

	sky_r5 = {
		id = "sky_r5",
		title = "Bright humid Indonesian sky, low cloud cover and no plaza ridge (round 5)",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		-- IDs are reused from Shared.SkyMapR4; no new asset ID is invented.
		idsSource = "Shared.SkyMapR5.sets",
		render = "docs/v2/visual/art/sky_r5/README.md",
		faceCount = 6,
	},

	props_r5 = {
		id = "props_r5",
		title = "Right-sized village props and contextual karung semen stack (round 5, server-only)",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		-- IDs are reused from Shared.ModelMapPropsR4 and ModelMapBuildingsR4.
		idsSource = "Shared.ModelMapPropsR5",
		render = "docs/v2/visual/art/models_r4/props/HANDOFF.md",
	},

	npcs_r5 = {
		id = "npcs_r5",
		title = "Solid upright Roblox R15 villagers from HumanoidDescription (round 5, server-only)",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		-- Only the three real Creator Store hat Model IDs live in Shared.ModelMapNpcsR5.
		idsSource = "Shared.ModelMapNpcsR5.accessories",
		render = "docs/v2/visual/art/models_r5/npcs/MANIFEST.md",
	},

	spawn_r5 = {
		id = "spawn_r5",
		title = "Spawn dressing pass — temporary buildings, pisang/bambu, contextual props and R15 villagers (round 5, server-only)",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		-- All IDs/positions are composed from the approved R4/R5 source maps.
		idsSource = "Shared.SpawnDressingMapR5",
		render = "docs/v2/visual/SPAWN_DRESSING_R5.md",
	},

	sky_r6_a = {
		id = "sky_r6_a",
		title = "Realistic Sky (Creator Store, Xeksworld08) with the shared humid atmosphere stack (round 6)",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		-- IDs deliberately NOT here: they live in Shared.SkyMapR6.sets.a.ids.
		idsSource = "Shared.SkyMapR6.sets.a.ids",
		render = "docs/v2/visual/art/sky_r6/README.md",
		faceCount = 6,
	},

	sky_r6_b = {
		id = "sky_r6_b",
		title = "Sky-Realistic (Creator Store, Dev_Flowey) with the shared humid atmosphere stack (round 6)",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		idsSource = "Shared.SkyMapR6.sets.b.ids",
		render = "docs/v2/visual/art/sky_r6/README.md",
		faceCount = 6,
	},

	sky_r6_c = {
		id = "sky_r6_c",
		title = "Realistic Clear Sky (Creator Store, HeyItzDaredevil) with the shared humid atmosphere stack (round 6)",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		idsSource = "Shared.SkyMapR6.sets.c.ids",
		render = "docs/v2/visual/art/sky_r6/README.md",
		faceCount = 6,
	},

	sky_r6_d = {
		id = "sky_r6_d",
		title = "Realistic Clear Skies SKYBOX (Creator Store, TrainMaker6) with the shared humid atmosphere stack (round 6)",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		idsSource = "Shared.SkyMapR6.sets.d.ids",
		render = "docs/v2/visual/art/sky_r6/README.md",
		faceCount = 6,
	},

	sky_r6_e = {
		id = "sky_r6_e",
		title = "Blue Sky W Scattered Clouds Daytime (Creator Store, Rozosere48) with the shared humid atmosphere stack (round 6)",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		idsSource = "Shared.SkyMapR6.sets.e.ids",
		render = "docs/v2/visual/art/sky_r6/README.md",
		faceCount = 6,
	},

	sky_r6_f = {
		id = "sky_r6_f",
		title = "Sunless blue sky skybox (Creator Store, f0xz08) with the shared humid atmosphere stack (round 6)",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		idsSource = "Shared.SkyMapR6.sets.f.ids",
		render = "docs/v2/visual/art/sky_r6/README.md",
		faceCount = 6,
	},

	spawn_ground_r6 = {
		id = "spawn_ground_r6",
		title = "Dirt over the full road corridor and no grass on beds/plots (round 6, server-only review)",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		-- Pure geometry/colour data; the default road and generator code stays untouched.
		idsSource = "Shared.SpawnGroundMapR6",
		render = "docs/v2/visual/SPAWN_DRESSING.md",
	},

	terrain_r6_a = {
		id = "terrain_r6_a",
		title = "Lush tropical Terrain colours with CC0 maps on parts/meshes only (round 6, option a)",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		-- No new IDs: colours are plain {r,g,b} data and map URLs come from TextureMapR4.
		idsSource = "Shared.TerrainMapR6",
		render = "docs/v2/visual/art/terrain_r6/README.md",
	},

	terrain_r6_b = {
		id = "terrain_r6_b",
		title = "Brighter olive Terrain colours with CC0 maps on parts/meshes only (round 6, option b)",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		-- Same part/mesh texture set as a; only the Terrain palette differs.
		idsSource = "Shared.TerrainMapR6",
		render = "docs/v2/visual/art/terrain_r6/README.md",
	},

	vegetation_r6 = {
		id = "vegetation_r6",
		title = "Dense kampung vegetation — real-model clusters along yard, hedge, fence and sawah edges (round 6, server-only)",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		-- IDs are R4 via require plus the real Creator Store shortlist in this data module.
		idsSource = "Shared.ModelMapVegetationR6",
		render = "docs/v2/visual/art/models_r6/vegetation/README.md",
	},

	npcs_r6 = {
		id = "npcs_r6",
		title = "Role-specific textured R15 villagers — per-role Shirt/Pants, hats, facing the camera (round 6, server-only)",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		-- Image IDs are pure data (Shared.ModelMapNpcsR6), applied to Shirt/Pants siblings.
		idsSource = "Shared.ModelMapNpcsR6",
		render = "docs/v2/visual/art/models_r6/npcs/COSTUMES.md",
	},

	props_r6 = {
		id = "props_r6",
		title = "Village tools at real size — gerobak/sumur/cangkul rescaled via GetBoundingBox (round 6, server-only)",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		-- IDs are R4 via require (Shared.ModelMapPropsR6) with corrected per-slot scales.
		idsSource = "Shared.ModelMapPropsR6",
		render = "docs/v2/visual/art/models_r6/props/README.md",
	},

	vegetation_r7 = {
		id = "vegetation_r7",
		title = "Dense kampung vegetation — 60+ instances, 8+ species, clone-first baked models (round 7, server-only)",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		idsSource = "Shared.ModelMapVegetationR7",
		render = "docs/v2/visual/art/models_r7/vegetation/README.md",
	},

	npcs_r7 = {
		id = "npcs_r7",
		title = "Villagers with baked hats, original peci and real batik/polisi templates (round 7, server-only)",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		idsSource = "Shared.ModelMapNpcsR7",
		render = "docs/v2/visual/art/models_r7/npcs/COSTUMES_SHEET.png",
	},

	props_r7 = {
		id = "props_r7",
		title = "Six props restaged in an open yard with a readable row camera (round 7, server-only)",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		idsSource = "Shared.ModelMapPropsR7",
		render = "docs/v2/visual/art/models_r7/props/README.md",
	},

	hubveg_r8 = {
		id = "hubveg_r8",
		title = "Per-hub vegetation dressing — 16 baked plants around each of the six hubs (round 9, server-only)",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		idsSource = "Shared.ModelMapVegetationHubR8",
		render = "docs/v2/evidence/h/2026-11-21-round9/CHECK_70.txt",
	},

	plots_r8 = {
		id = "plots_r8",
		title = "Plot fences and gates — procedural bamboo fence with an inner-side gate arch on all ten plots (round 9, server-only)",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		-- Procedural parts, no asset IDs. Pure fence/gate recipe in Shared.ModelMapPlotsR8.
		idsSource = "Shared.ModelMapPlotsR8",
		render = "docs/v2/evidence/h/2026-11-21-round9/CHECK_71.txt",
	},

	sawah_r8 = {
		id = "sawah_r8",
		title = "Terrace dressing — muddy water sheets, alang-alang bunds, one field hut and stepping stones (round 9, server-only)",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		-- Procedural parts, no asset IDs. Pure recipe in Shared.ModelMapSawahR8.
		idsSource = "Shared.ModelMapSawahR8",
		render = "docs/v2/evidence/h/2026-11-21-round9/CHECK_72.txt",
	},

	river_r8 = {
		id = "river_r8",
		title = "River banks and bridge dressing — bank vegetation, two-side rails and stepping stones (round 9, server-only)",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		-- Procedural parts, no asset IDs. Pure recipe in Shared.ModelMapRiverR8.
		idsSource = "Shared.ModelMapRiverR8",
		render = "docs/v2/evidence/h/2026-11-21-round9/CHECK_73.txt",
	},

	pathedge_r8 = {
		id = "pathedge_r8",
		title = "Dirt-path edge dressing — grass tufts, pebbles and puddles on both edges of every road (round 9, server-only)",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		-- Procedural parts, no asset IDs. Pure recipe in Shared.ModelMapPathEdgeR8.
		idsSource = "Shared.ModelMapPathEdgeR8",
		render = "docs/v2/evidence/h/2026-11-21-round9/CHECK_75.txt",
	},

	water_r8_a = {
		id = "water_r8_a",
		title = "River water — clear tropical green (round 9, client-only)",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		-- Terrain water properties only, no asset IDs. Pure palettes in Shared.ModelMapWaterR8.
		idsSource = "Shared.ModelMapWaterR8",
		render = "docs/v2/evidence/h/2026-11-21-round9/CHECK_76.txt",
	},

	water_r8_b = {
		id = "water_r8_b",
		title = "River water — murky brown after rain (round 9, client-only)",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		-- Terrain water properties only, no asset IDs. Pure palettes in Shared.ModelMapWaterR8.
		idsSource = "Shared.ModelMapWaterR8",
		render = "docs/v2/evidence/h/2026-11-21-round9/CHECK_76.txt",
	},

	water_r8_c = {
		id = "water_r8_c",
		title = "River water — bright turquoise (round 9, client-only)",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		-- Terrain water properties only, no asset IDs. Pure palettes in Shared.ModelMapWaterR8.
		idsSource = "Shared.ModelMapWaterR8",
		render = "docs/v2/evidence/h/2026-11-21-round9/CHECK_76.txt",
	},

	buildings_r8 = {
		id = "buildings_r8",
		title = "Six Creator Store buildings, staged 20 studs apart with avatar-fit door gauges (round 9, server-only)",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		-- Real free Creator Store model IDs in Shared.ModelMapBuildingsR8. Enable from the Server
		-- datamodel: InsertService is blocked on the client. Door grading is pending Studio review.
		idsSource = "Shared.ModelMapBuildingsR8",
		render = "docs/v2/visual/art/models_r8/buildings/README.md",
		modelCount = 6,
	},

	facades_r8 = {
		id = "facades_r8",
		title = "Hub facades — shuttered windows, porch roofs, ridge caps, lantern brackets, doorsteps and eaves on all six hubs (round 9, server-only)",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		-- Procedural parts, no asset IDs. Pure recipe in Shared.ModelMapFacadesR8. The six
		-- FacadeDoorGauge Parts grade the open-front avatar fit; visual grading is pending Studio.
		idsSource = "Shared.ModelMapFacadesR8",
		render = "docs/v2/visual/art/models_r8/facades/README.md",
		hubCount = 6,
	},

	hubprops_r8 = {
		id = "hubprops_r8",
		title = "Vernacular hub props — crates, baskets, benches, flags, kentongan and more on all six hubs (round 9, server-only)",
		style = LookDev.STYLE,
		status = LookDev.STATUS,
		-- Baked IDs live in Shared.ModelMapHubPropsR8.ALLOWED_IDS (nine verified IDs only);
		-- the other kinds are procedural Roblox parts. Grading is pending Studio review.
		idsSource = "Shared.ModelMapHubPropsR8",
		render = "docs/v2/visual/art/models_r8/hubprops/README.md",
		hubCount = 6,
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
	elseif id == "sounds" then
		local c = LookDev.candidates.sounds
		return {
			id = id,
			idsSource = c.idsSource,
			render = c.render,
			soundCount = c.soundCount,
		}
	elseif id == "textures_r3" then
		local c = LookDev.candidates.textures_r3
		return {
			id = id,
			idsSource = c.idsSource,
			render = c.render,
			variantCount = c.variantCount,
			mapCount = c.mapCount,
		}
	elseif id == "day_cycle" then
		local c = LookDev.candidates.day_cycle
		return {
			id = id,
			idsSource = c.idsSource,
			render = c.render,
		}
	elseif id == "icons_r3" then
		local c = LookDev.candidates.icons_r3
		return {
			id = id,
			idsSource = c.idsSource,
			render = c.render,
			iconCount = c.iconCount,
		}
	elseif
		id == "buildings_r3"
		or id == "vegetation_r3"
		or id == "props_r3"
		or id == "npcs_r3"
		or id == "buildings_r4"
		or id == "vegetation_r4"
		or id == "props_r4"
		or id == "npcs_r4"
		or id == "buildings_r8"
	then
		local c = LookDev.candidates[id]
		return {
			id = id,
			idsSource = c.idsSource,
			render = c.render,
			modelCount = c.modelCount,
		}
	elseif id == "sky_r3" then
		local c = LookDev.candidates.sky_r3
		return {
			id = id,
			idsSource = c.idsSource,
			render = c.render,
			faceCount = c.faceCount,
		}
	elseif id == "textures_r4" then
		local c = LookDev.candidates.textures_r4
		return {
			id = id,
			idsSource = c.idsSource,
			render = c.render,
			variantCount = c.variantCount,
			mapCount = c.mapCount,
		}
	elseif
		id == "sky_r4_a"
		or id == "sky_r4_b"
		or id == "sky_r4_c"
		or id == "sky_r5"
		or id == "sky_r6_a"
		or id == "sky_r6_b"
		or id == "sky_r6_c"
		or id == "sky_r6_d"
		or id == "sky_r6_e"
		or id == "sky_r6_f"
	then
		local c = LookDev.candidates[id]
		return {
			id = id,
			idsSource = c.idsSource,
			render = c.render,
			faceCount = c.faceCount,
		}
	elseif
		id == "spawn_ground_r5"
		or id == "spawn_ground_r6"
		or id == "vegetation_r5"
		or id == "props_r5"
		or id == "npcs_r5"
		or id == "spawn_r5"
		or id == "terrain_r6_a"
		or id == "terrain_r6_b"
		or id == "vegetation_r6"
		or id == "npcs_r6"
		or id == "props_r6"
		or id == "hubveg_r8"
		or id == "plots_r8"
		or id == "sawah_r8"
		or id == "river_r8"
		or id == "pathedge_r8"
		or id == "water_r8_a"
		or id == "water_r8_b"
		or id == "water_r8_c"
	then
		local c = LookDev.candidates[id]
		return {
			id = id,
			idsSource = c.idsSource,
			render = c.render,
		}
	elseif id == "facades_r8" then
		local c = LookDev.candidates.facades_r8
		return {
			id = id,
			idsSource = c.idsSource,
			render = c.render,
			hubCount = c.hubCount,
		}
	elseif id == "hubprops_r8" then
		local c = LookDev.candidates.hubprops_r8
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
-- WORK_QUEUE item 136: additively staged ids are tracked separately from the single enabledId.
local additiveIds: { string } = {}

-- The single gate rule: a LITERAL studio == true. A published server, a nil flag, or a truthy
-- non-boolean all refuse. Kept pure so the spec can prove every branch without Roblox.
function LookDev.canEnable(opts: any): boolean
	return type(opts) == "table" and opts.studio == true
end

-- A thin adapter registers its appliers here at boot. Unknown ids and non-tables are ignored.
function LookDev.register(id: string, applier: any)
	if
		LookDev.isCandidate(id)
		and type(applier) == "table"
		and type(applier.apply) == "function"
		and type(applier.restore) == "function"
	then
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

-- Stage a candidate additively (WORK_QUEUE item 136): same candidate + studio gate as enable(), but
-- it never touches enabledId and never restores another staged candidate. Re-staging an id is a
-- no-op. The restore side is driven exclusively by disableAll().
function LookDev.enableAdditive(id: string, opts: any?): (boolean, string?)
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
	for _, staged in additiveIds do
		if staged == id then
			return true, nil
		end
	end
	local applier = appliers[id]
	if applier then
		local ok, err = pcall(applier.apply, LookDev.plan(id))
		if not ok then
			return false, "applier failed: " .. tostring(err)
		end
	end
	additiveIds[#additiveIds + 1] = id
	return true, nil
end

-- Restore every additively staged candidate (reverse order), then the single enabled one. Safe to
-- call repeatedly; leaves current() == nil and no staged folders behind.
function LookDev.disableAll(): boolean
	local changed = false
	for i = #additiveIds, 1, -1 do
		local applier = appliers[additiveIds[i]]
		if applier then
			pcall(applier.restore)
		end
		additiveIds[i] = nil
		changed = true
	end
	if LookDev.disable() then
		changed = true
	end
	return changed
end

-- Read-only view for specs / harnesses (Luau table.clear is not guaranteed in every host, so the
-- backing list is cleared by loop above).
function LookDev.additiveIds(): { string }
	return table.clone(additiveIds)
end

return LookDev
