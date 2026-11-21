--!nocheck
-- WORK_QUEUE item 9: look-dev candidates for designer review. These candidates are recorded as
-- "candidate, awaiting designer yes" and are OFF by default. This spec locks the gate, the two
-- candidate plans, the built-in-material/asset-ID guard, and the thin-adapter wiring. It never
-- marks a candidate approved: that is the designer's decision.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect

	local function fresh()
		return Env.new():require("shared/LookDev")
	end

	t:describe("LookDev candidates (candidate, awaiting designer yes)", function()
		t:it("ships fifty-seven candidates, all unapproved and cartoonish-realism", function()
			local LookDev = fresh()
			expect(#LookDev.IDS):toBe(73)
			expect(LookDev.IDS[1]):toBe("plaza_lighting")
			expect(LookDev.IDS[2]):toBe("police_walkin")
			expect(LookDev.IDS[3]):toBe("icons")
			expect(LookDev.IDS[4]):toBe("textures")
			expect(LookDev.IDS[5]):toBe("npcs")
			expect(LookDev.IDS[6]):toBe("crops")
			expect(LookDev.IDS[7]):toBe("hubprops")
			expect(LookDev.IDS[8]):toBe("sounds")
			expect(LookDev.IDS[9]):toBe("corner")
			expect(LookDev.IDS[10]):toBe("textures_r3")
			expect(LookDev.IDS[11]):toBe("day_cycle")
			expect(LookDev.IDS[12]):toBe("icons_r3")
			expect(LookDev.IDS[13]):toBe("buildings_r3")
			expect(LookDev.IDS[14]):toBe("vegetation_r3")
			expect(LookDev.IDS[15]):toBe("props_r3")
			expect(LookDev.IDS[16]):toBe("npcs_r3")
			expect(LookDev.IDS[17]):toBe("sky_r3")
			expect(LookDev.IDS[18]):toBe("textures_r4")
			expect(LookDev.IDS[19]):toBe("sky_r4_a")
			expect(LookDev.IDS[20]):toBe("sky_r4_b")
			expect(LookDev.IDS[21]):toBe("sky_r4_c")
			expect(LookDev.IDS[22]):toBe("buildings_r4")
			expect(LookDev.IDS[23]):toBe("vegetation_r4")
			expect(LookDev.IDS[24]):toBe("props_r4")
			expect(LookDev.IDS[25]):toBe("npcs_r4")
			expect(LookDev.IDS[26]):toBe("spawn_ground_r5")
			expect(LookDev.IDS[27]):toBe("vegetation_r5")
			expect(LookDev.IDS[28]):toBe("sky_r5")
			expect(LookDev.IDS[29]):toBe("props_r5")
			expect(LookDev.IDS[30]):toBe("npcs_r5")
			expect(LookDev.IDS[31]):toBe("spawn_r5")
			expect(LookDev.IDS[32]):toBe("sky_r6_a")
			expect(LookDev.IDS[33]):toBe("sky_r6_b")
			expect(LookDev.IDS[34]):toBe("sky_r6_c")
			expect(LookDev.IDS[35]):toBe("sky_r6_d")
			expect(LookDev.IDS[36]):toBe("sky_r6_e")
			expect(LookDev.IDS[37]):toBe("sky_r6_f")
			expect(LookDev.IDS[38]):toBe("spawn_ground_r6")
			expect(LookDev.IDS[39]):toBe("terrain_r6_a")
			expect(LookDev.IDS[40]):toBe("terrain_r6_b")
			expect(LookDev.IDS[41]):toBe("vegetation_r6")
			expect(LookDev.IDS[42]):toBe("npcs_r6")
			expect(LookDev.IDS[43]):toBe("props_r6")
			expect(LookDev.IDS[44]):toBe("vegetation_r7")
			expect(LookDev.IDS[45]):toBe("npcs_r7")
			expect(LookDev.IDS[46]):toBe("props_r7")
			expect(LookDev.IDS[47]):toBe("hubveg_r8")
			expect(LookDev.IDS[48]):toBe("plots_r8")
			expect(LookDev.IDS[49]):toBe("sawah_r8")
			expect(LookDev.IDS[50]):toBe("river_r8")
			expect(LookDev.IDS[51]):toBe("pathedge_r8")
			expect(LookDev.IDS[52]):toBe("water_r8_a")
			expect(LookDev.IDS[53]):toBe("water_r8_b")
			expect(LookDev.IDS[54]):toBe("water_r8_c")
			expect(LookDev.IDS[55]):toBe("buildings_r8")
			expect(LookDev.IDS[56]):toBe("facades_r8")
			for _, id in LookDev.IDS do
				local c = LookDev.candidates[id]
				expect(c.id):toBe(id)
				expect(c.status):toBe("candidate, awaiting designer yes")
				expect(c.style):toBe("cartoonish-realism")
				expect(type(c.title)):toBe("string")
			end
		end)

		t:it("contains no asset IDs in the registry or any adapter", function()
			for _, path in
				{
					"src/shared/LookDev.luau",
					"src/client/World/LookDevPlaza.luau",
					"src/server/World/LookDevWalkin.luau",
					"src/client/UI/LookDevIcons.luau",
					"src/client/World/LookDevTextures.luau",
					"src/client/World/LookDevNpcs.luau",
					"src/client/World/LookDevCrops.luau",
					"src/client/World/LookDevHubProps.luau",
					"src/client/World/LookDevSounds.luau",
					"src/client/World/LookDevCorner.luau",
					"src/client/World/LookDevTexturesR3.luau",
					"src/client/World/LookDevDayCycle.luau",
					"src/client/UI/LookDevIconsR3.luau",
					"src/server/World/LookDevModelsR3.luau",
					"src/client/World/LookDevSkyR3.luau",
					"src/client/World/LookDevTexturesR4.luau",
					"src/client/World/LookDevSkyR4.luau",
					"src/server/World/LookDevModelsBuildingsR4.luau",
					"src/server/World/LookDevModelsVegetationR4.luau",
					"src/server/World/LookDevModelsPropsR4.luau",
					"src/server/World/LookDevModelsNpcsR4.luau",
					"src/server/World/LookDevSpawnGroundR5.luau",
					"src/server/World/LookDevSpawnGroundR6.luau",
					"src/server/World/LookDevModelsVegetationR5.luau",
					"src/server/World/LookDevModelsVegetationR6.luau",
					"src/server/World/LookDevModelsNpcsR6.luau",
					"src/server/World/LookDevModelsPropsR6.luau",
					"src/client/World/LookDevSkyR5.luau",
					"src/client/World/LookDevSkyR6.luau",
					"src/client/World/LookDevTerrainR6.luau",
					"src/server/World/LookDevModelsPropsR5.luau",
					"src/server/World/LookDevModelsNpcsR5.luau",
					"src/server/World/LookDevSpawnDressingR5.luau",
					"src/shared/LookDevCorner.luau",
					"src/server/World/LookDevFacadesR8.luau",
				}
			do
				local src = fs.readFile(path)
				-- The sky adapter may build "rbxassetid://" .. id at apply time; ban only an
				-- embedded ID after the scheme, never the scheme prefix itself.
				expect(string.find(src, "rbxassetid://%d") ~= nil):toBe(false)
				expect(string.find(src, "assetId", 1, true) ~= nil):toBe(false)
				-- A 7+ digit literal is the shape of a Roblox asset/product ID.
				expect(string.find(src, "%d%d%d%d%d%d%d") ~= nil):toBe(false)
			end
		end)

		t:it("every plaza material is a built-in Enum.Material name", function()
			local LookDev = fresh()
			for category, name in LookDev.candidates.plaza_lighting.materials do
				expect(LookDev.isBuiltinMaterial(name)):toBe(true)
			end
			expect(LookDev.isBuiltinMaterial("Sandstone")):toBe(true)
			expect(LookDev.isBuiltinMaterial("NotAMaterial")):toBe(false)
			expect(LookDev.isBuiltinMaterial(nil)):toBe(false)
		end)
	end)

	t:describe("LookDev opt-in gate", function()
		t:it("is off by default and refuses non-Studio callers", function()
			local LookDev = fresh()
			expect(LookDev.current()):toBe(nil)
			expect(LookDev.canEnable(nil)):toBe(false)
			expect(LookDev.canEnable({})):toBe(false)
			expect(LookDev.canEnable({ studio = 1 })):toBe(false)
			expect(LookDev.canEnable({ studio = "true" })):toBe(false)
			expect(LookDev.canEnable({ studio = false })):toBe(false)
			expect(LookDev.canEnable({ studio = true })):toBe(true)
		end)

		t:it("enable refuses an unknown candidate even in Studio", function()
			local LookDev = fresh()
			local ok, why = LookDev.enable("nope", { studio = true })
			expect(ok):toBe(false)
			expect(why):toBe("unknown candidate")
			expect(LookDev.current()):toBe(nil)
		end)

		t:it("enable/disable round-trips and only one candidate is active", function()
			local LookDev = fresh()
			expect(LookDev.enable("plaza_lighting", { studio = true })):toBe(true)
			expect(LookDev.current()):toBe("plaza_lighting")
			expect(LookDev.enable("plaza_lighting", { studio = true })):toBe(true)
			expect(LookDev.disable()):toBe(true)
			expect(LookDev.current()):toBe(nil)
			expect(LookDev.disable()):toBe(false) -- idempotent
			expect(LookDev.enable("police_walkin", { studio = true })):toBe(true)
			expect(LookDev.current()):toBe("police_walkin")
			LookDev.disable()
		end)

		t:it("registered appliers run with the plan and restore on disable", function()
			local LookDev = fresh()
			local applied, restored = nil, 0
			LookDev.register("plaza_lighting", {
				apply = function(plan)
					applied = plan
				end,
				restore = function()
					restored += 1
				end,
			})
			expect(LookDev.hasApplier("plaza_lighting")):toBe(true)
			expect(LookDev.enable("plaza_lighting", { studio = true })):toBe(true)
			expect(applied.id):toBe("plaza_lighting")
			expect(LookDev.disable()):toBe(true)
			expect(restored):toBe(1)
		end)

		t:it("a throwing applier is contained and enable reports the failure", function()
			local LookDev = fresh()
			LookDev.register("plaza_lighting", {
				apply = function()
					error("boom")
				end,
				restore = function() end,
			})
			local ok, why = LookDev.enable("plaza_lighting", { studio = true })
			expect(ok):toBe(false)
			expect(string.find(why or "", "boom", 1, true) ~= nil):toBe(true)
			expect(LookDev.disable()):toBe(true) -- still enabled, restore is pcall-safe
		end)

		t:it("only well-formed appliers register", function()
			local LookDev = fresh()
			LookDev.register("plaza_lighting", { apply = function() end })
			expect(LookDev.hasApplier("plaza_lighting")):toBe(false)
			LookDev.register("unknown", { apply = function() end, restore = function() end })
			expect(LookDev.hasApplier("unknown")):toBe(false)
		end)
	end)

	t:describe("LookDev plans", function()
		t:it("plaza plan carries the hub, material map and lighting grade", function()
			local LookDev = fresh()
			local plan = LookDev.plan("plaza_lighting")
			expect(plan.id):toBe("plaza_lighting")
			expect(plan.hub):toBe("pasar")
			expect(plan.materials.ground):toBe("Sandstone")
			expect(plan.lighting.clockTime):toBe(11.4)
			expect(#plan.lighting.fogColor):toBe(3)
			expect(LookDev.plan("unknown")):toBe(nil)
		end)

		t:it("walk-in plan is timed to the real walkin shot and aims at the road anchor", function()
			local LookDev = fresh()
			local RaidCutscene = Env.new():require("shared/Config/RaidCutscene")
			local shotDuration = 1.8
			for _, shot in RaidCutscene.shots do
				if shot.id == "walkin" then
					shotDuration = shot.duration
				end
			end
			local plan = LookDev.plan("police_walkin")
			expect(plan.id):toBe("police_walkin")
			expect(plan.npc):toBe("polisi")
			expect(plan.shotId):toBe("walkin")
			expect(plan.duration):toBe(shotDuration)
			local anchor = RaidCutscene.anchorFor("road")
			expect(plan.anchor.x):toBe(anchor.x)
			expect(plan.anchor.z):toBe(anchor.z)
			expect(plan.speed > 0):toBe(true)
			-- distance / duration, so the walk lands exactly when the shot ends.
			local ox, oz = -34, -16
			expect(math.abs(plan.speed - math.sqrt(ox * ox + oz * oz) / shotDuration)):toBeLessThan(0.0001)
		end)

		t:it("icons plan points at the IconMap data source and never embeds IDs", function()
			local LookDev = fresh()
			local plan = LookDev.plan("icons")
			expect(plan.id):toBe("icons")
			expect(plan.idsSource):toBe("Shared.IconMap.candidateIds")
			expect(type(plan.render)):toBe("string")
		end)

		t:it("textures plan points at the TextureMap data source and never embeds IDs", function()
			local LookDev = fresh()
			local plan = LookDev.plan("textures")
			expect(plan.id):toBe("textures")
			expect(plan.idsSource):toBe("Shared.TextureMap.candidateIds")
			expect(plan.slotCount):toBe(7)
			expect(type(plan.render)):toBe("string")
		end)

		t:it("npcs plan points at the procedural recipe source and never embeds IDs", function()
			local LookDev = fresh()
			local plan = LookDev.plan("npcs")
			expect(plan.id):toBe("npcs")
			expect(plan.idsSource):toBe("Shared.NpcModelCandidates.recipes")
			expect(type(plan.render)):toBe("string")
		end)

		t:it("crops plan covers 12 crops x 3 stages from the pure recipe source", function()
			local LookDev = fresh()
			local plan = LookDev.plan("crops")
			expect(plan.id):toBe("crops")
			expect(plan.idsSource):toBe("Shared.CropModelCandidates.partsFor")
			expect(plan.cropCount):toBe(12)
			expect(plan.stageCount):toBe(3)
			expect(type(plan.render)):toBe("string")
		end)

		t:it("hubprops plan points at the pure recipe source and never embeds IDs", function()
			local LookDev = fresh()
			local plan = LookDev.plan("hubprops")
			expect(plan.id):toBe("hubprops")
			expect(plan.idsSource):toBe("Shared.HubPropCandidates.partsFor")
			expect(plan.hubCount):toBe(4)
			expect(type(plan.render)):toBe("string")
		end)

		t:it("sounds plan points at the SoundMap data source and never embeds IDs", function()
			local LookDev = fresh()
			local plan = LookDev.plan("sounds")
			expect(plan.id):toBe("sounds")
			expect(plan.idsSource):toBe("Shared.SoundMap.candidateIds")
			expect(plan.soundCount):toBe(2)
			expect(type(plan.render)):toBe("string")
		end)

		t:it("textures_r3 plan points at the real PBR ID map without embedding IDs", function()
			local LookDev = fresh()
			local plan = LookDev.plan("textures_r3")
			expect(plan.id):toBe("textures_r3")
			expect(plan.idsSource):toBe("Shared.TextureMapR3.ids")
			expect(plan.variantCount):toBe(9)
			expect(plan.mapCount):toBe(27)
			expect(type(plan.render)):toBe("string")
		end)

		t:it("day_cycle plan points at the pure live-cycle module", function()
			local LookDev = fresh()
			local plan = LookDev.plan("day_cycle")
			expect(plan.id):toBe("day_cycle")
			expect(plan.idsSource):toBe("Shared.World.DayCycleLive")
			expect(type(plan.render)):toBe("string")
		end)

		t:it("icons_r3 plan points at the r3 ID map without embedding IDs", function()
			local LookDev = fresh()
			local plan = LookDev.plan("icons_r3")
			expect(plan.id):toBe("icons_r3")
			expect(plan.idsSource):toBe("Shared.IconMapR3.ids")
			expect(plan.iconCount):toBe(27)
			expect(type(plan.render)):toBe("string")
		end)

		t:it("model family plans point at the shared model map without embedding IDs", function()
			local LookDev = fresh()
			local expected = {
				buildings_r3 = 3,
				vegetation_r3 = 6,
				props_r3 = 5,
				npcs_r3 = 6,
			}
			for id, count in expected do
				local plan = LookDev.plan(id)
				expect(plan.id):toBe(id)
				expect(plan.idsSource):toBe("Shared.ModelMapR3.families." .. id)
				expect(plan.modelCount):toBe(count)
				expect(type(plan.render)):toBe("string")
			end
		end)

		t:it("sky_r3 plan points at the cube-face ID map without embedding IDs", function()
			local LookDev = fresh()
			local plan = LookDev.plan("sky_r3")
			expect(plan.id):toBe("sky_r3")
			expect(plan.idsSource):toBe("Shared.SkyMapR3.ids")
			expect(plan.faceCount):toBe(6)
			expect(type(plan.render)):toBe("string")
		end)

		t:it("all six sky_r6 plans point at SkyMapR6 sets without embedding IDs", function()
			local LookDev = fresh()
			for _, key in ipairs({ "a", "b", "c", "d", "e", "f" }) do
				local id = "sky_r6_" .. key
				local plan = LookDev.plan(id)
				expect(plan.id):toBe(id)
				expect(plan.idsSource):toBe("Shared.SkyMapR6.sets." .. key .. ".ids")
				expect(plan.render):toBe("docs/v2/visual/art/sky_r6/README.md")
				expect(plan.faceCount):toBe(6)
			end
		end)
	end)

	t:describe("LookDev adapter wiring", function()
		t:it("all thin adapters register with the shared toggle", function()
			local plaza = fs.readFile("src/client/World/LookDevPlaza.luau")
			local walkin = fs.readFile("src/server/World/LookDevWalkin.luau")
			local icons = fs.readFile("src/client/UI/LookDevIcons.luau")
			local textures = fs.readFile("src/client/World/LookDevTextures.luau")
			local npcs = fs.readFile("src/client/World/LookDevNpcs.luau")
			local crops = fs.readFile("src/client/World/LookDevCrops.luau")
			local hubprops = fs.readFile("src/client/World/LookDevHubProps.luau")
			local sounds = fs.readFile("src/client/World/LookDevSounds.luau")
			local texturesR3 = fs.readFile("src/client/World/LookDevTexturesR3.luau")
			local dayCycle = fs.readFile("src/client/World/LookDevDayCycle.luau")
			local iconsR3 = fs.readFile("src/client/UI/LookDevIconsR3.luau")
			local modelsR3 = fs.readFile("src/server/World/LookDevModelsR3.luau")
			local skyR3 = fs.readFile("src/client/World/LookDevSkyR3.luau")
			local skyR6 = fs.readFile("src/client/World/LookDevSkyR6.luau")
			expect(string.find(plaza, 'LookDev.register("plaza_lighting"', 1, true) ~= nil):toBe(true)
			expect(string.find(walkin, 'LookDev.register("police_walkin"', 1, true) ~= nil):toBe(true)
			expect(string.find(icons, 'LookDev.register("icons"', 1, true) ~= nil):toBe(true)
			expect(string.find(textures, 'LookDev.register("textures"', 1, true) ~= nil):toBe(true)
			expect(string.find(npcs, 'LookDev.register("npcs"', 1, true) ~= nil):toBe(true)
			expect(string.find(crops, 'LookDev.register("crops"', 1, true) ~= nil):toBe(true)
			expect(string.find(hubprops, 'LookDev.register("hubprops"', 1, true) ~= nil):toBe(true)
			expect(string.find(sounds, 'LookDev.register("sounds"', 1, true) ~= nil):toBe(true)
			expect(string.find(texturesR3, 'LookDev.register("textures_r3"', 1, true) ~= nil):toBe(true)
			expect(string.find(dayCycle, 'LookDev.register("day_cycle"', 1, true) ~= nil):toBe(true)
			expect(string.find(iconsR3, 'LookDev.register("icons_r3"', 1, true) ~= nil):toBe(true)
			expect(string.find(modelsR3, 'LookDev.register("buildings_r3"', 1, true) ~= nil):toBe(true)
			expect(string.find(modelsR3, 'LookDev.register("vegetation_r3"', 1, true) ~= nil):toBe(true)
			expect(string.find(modelsR3, 'LookDev.register("props_r3"', 1, true) ~= nil):toBe(true)
			expect(string.find(modelsR3, 'LookDev.register("npcs_r3"', 1, true) ~= nil):toBe(true)
			expect(string.find(skyR3, 'LookDev.register("sky_r3"', 1, true) ~= nil):toBe(true)
			expect(string.find(skyR6, 'LookDev.register("sky_r6_" .. key', 1, true) ~= nil):toBe(true)
			for _, key in ipairs({ "a", "b", "c", "d", "e", "f" }) do
				expect(string.find(skyR6, 'make("sky_r6_' .. key .. '", "' .. key .. '")', 1, true) ~= nil):toBe(true)
			end
		end)

		t:it("icons applier toggles IconMap candidate ids and restores fallbacks", function()
			local icons = fs.readFile("src/client/UI/LookDevIcons.luau")
			expect(string.find(icons, "IconMap.applyCandidates(Visuals, true)", 1, true) ~= nil):toBe(true)
			expect(string.find(icons, "IconMap.applyCandidates(Visuals, false)", 1, true) ~= nil):toBe(true)
		end)

		t:it("textures applier toggles TextureMap slots and restores originals", function()
			local textures = fs.readFile("src/client/World/LookDevTextures.luau")
			expect(string.find(textures, "TextureMap.applyCandidates(Visuals, true)", 1, true) ~= nil):toBe(true)
			expect(string.find(textures, "TextureMap.applyCandidates(Visuals, false)", 1, true) ~= nil):toBe(true)
			expect(string.find(textures, "Visuals.applySurface(part, slot", 1, true) ~= nil):toBe(true)
			expect(string.find(textures, "local function restore()", 1, true) ~= nil):toBe(true)
		end)

		t:it("textures_r3 applier builds MaterialVariants and restores MeshParts", function()
			local r3 = fs.readFile("src/client/World/LookDevTexturesR3.luau")
			expect(string.find(r3, 'Instance.new("MaterialVariant")', 1, true) ~= nil):toBe(true)
			expect(string.find(r3, "part.MaterialVariant = variant.name", 1, true) ~= nil):toBe(true)
			expect(string.find(r3, "entry.part.MaterialVariant = entry.variant", 1, true) ~= nil):toBe(true)
			expect(string.find(r3, "local function restore()", 1, true) ~= nil):toBe(true)
		end)

		t:it("npcs applier adds procedural details and removes them on restore", function()
			local npcs = fs.readFile("src/client/World/LookDevNpcs.luau")
			expect(string.find(npcs, "NpcModelCandidates.recipeFor", 1, true) ~= nil):toBe(true)
			expect(string.find(npcs, 'CollectionService:GetTagged("NpcSpawn")', 1, true) ~= nil):toBe(true)
			expect(string.find(npcs, "Detail", 1, true) ~= nil or string.find(npcs, "decorate", 1, true) ~= nil):toBe(
				true
			)
			expect(string.find(npcs, ":Destroy()", 1, true) ~= nil):toBe(true)
		end)

		t:it("crops applier builds a showcase from partsFor and removes it on restore", function()
			local crops = fs.readFile("src/client/World/LookDevCrops.luau")
			expect(string.find(crops, "CropModelCandidates.partsFor", 1, true) ~= nil):toBe(true)
			expect(string.find(crops, "CropModelCandidates.cropIds", 1, true) ~= nil):toBe(true)
			expect(string.find(crops, "CropModelCandidates.stages", 1, true) ~= nil):toBe(true)
			expect(string.find(crops, ":Destroy()", 1, true) ~= nil):toBe(true)
		end)

		t:it("hubprops applier builds from partsFor and removes it on restore", function()
			local hubprops = fs.readFile("src/client/World/LookDevHubProps.luau")
			expect(string.find(hubprops, "HubPropCandidates.partsFor", 1, true) ~= nil):toBe(true)
			expect(string.find(hubprops, "HubPropCandidates.hubOrder", 1, true) ~= nil):toBe(true)
			expect(string.find(hubprops, "anchor.CFrame", 1, true) ~= nil):toBe(true)
			expect(string.find(hubprops, ":Destroy()", 1, true) ~= nil):toBe(true)
		end)

		t:it(
			"sounds applier uses SoundMap, round-1 SoundGroups + AudioPolicy and removes its Sounds on restore",
			function()
				local sounds = fs.readFile("src/client/World/LookDevSounds.luau")
				expect(string.find(sounds, "SoundMap.candidateOrder", 1, true) ~= nil):toBe(true)
				expect(string.find(sounds, "SoundMap.assetUrl", 1, true) ~= nil):toBe(true)
				expect(string.find(sounds, "SoundMap.playable", 1, true) ~= nil):toBe(true)
				expect(string.find(sounds, "AudioPolicy.new", 1, true) ~= nil):toBe(true)
				expect(string.find(sounds, ":transition(def.group, key)", 1, true) ~= nil):toBe(true)
				expect(string.find(sounds, 'def.group == "music"', 1, true) ~= nil):toBe(true)
				expect(string.find(sounds, '"JD_" .. name', 1, true) ~= nil):toBe(true)
				expect(string.find(sounds, "sound.SoundGroup = group", 1, true) ~= nil):toBe(true)
				expect(string.find(sounds, ":Destroy()", 1, true) ~= nil):toBe(true)
			end
		)

		t:it("plaza applier uses built-in Enum.Material only", function()
			local plaza = fs.readFile("src/client/World/LookDevPlaza.luau")
			expect(string.find(plaza, "Enum.Material[materialName]", 1, true) ~= nil):toBe(true)
			expect(string.find(plaza, "isBuiltinMaterial", 1, true) ~= nil):toBe(true)
			-- Originals are saved so disable() restores the exact live look.
			expect(string.find(plaza, "local function restore()", 1, true) ~= nil):toBe(true)
		end)

		t:it("walk-in applier reuses the existing police model and pathing", function()
			local walkin = fs.readFile("src/server/World/LookDevWalkin.luau")
			expect(string.find(walkin, "Village.police", 1, true) ~= nil):toBe(true)
			expect(string.find(walkin, ":walkTo(", 1, true) ~= nil):toBe(true)
			expect(string.find(walkin, ":teleport(", 1, true) ~= nil):toBe(true)
			expect(string.find(walkin, "local function restore()", 1, true) ~= nil):toBe(true)
		end)

		t:it("Main bootstraps register the appliers behind a failure-isolating pcall", function()
			local client = fs.readFile("src/client/Main.client.luau")
			local server = fs.readFile("src/server/Main.server.luau")
			expect(string.find(client, "pcall(require, script.Parent.World.LookDevPlaza)", 1, true) ~= nil):toBe(true)
			expect(string.find(client, "pcall(require, script.Parent.UI.LookDevIcons)", 1, true) ~= nil):toBe(true)
			expect(string.find(client, "pcall(require, script.Parent.World.LookDevTextures)", 1, true) ~= nil):toBe(
				true
			)
			expect(string.find(client, "pcall(require, script.Parent.World.LookDevNpcs)", 1, true) ~= nil):toBe(true)
			expect(string.find(client, "pcall(require, script.Parent.World.LookDevCrops)", 1, true) ~= nil):toBe(true)
			expect(string.find(client, "pcall(require, script.Parent.World.LookDevHubProps)", 1, true) ~= nil):toBe(
				true
			)
			expect(string.find(client, "pcall(require, script.Parent.World.LookDevSounds)", 1, true) ~= nil):toBe(true)
			expect(string.find(client, "pcall(require, script.Parent.World.LookDevSkyR6)", 1, true) ~= nil):toBe(true)
			expect(string.find(server, "pcall(require, script.Parent.World.LookDevWalkin)", 1, true) ~= nil):toBe(true)
		end)
	end)
end
