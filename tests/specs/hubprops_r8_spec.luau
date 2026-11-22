--!nocheck
-- WORK_QUEUE section M item 79: the OFF-BY-DEFAULT "hubprops_r8" SERVER candidate. Locks the pure
-- data recipes for all six Greybox hubs (6-10 props each), the verified-ID allow-list, real-world
-- bboxes, gauge avoidance, the baked/procedural applier contract, both Studio harness checks and
-- the registry/review/boot/gallery wiring. No Studio run and no visual verdict: main session owns it.

local fs = require("@lune/fs")

local RENDER = "docs/v2/visual/art/models_r8/hubprops/README.md"
local HUB_KEYS = { "pasar", "gelap", "warung", "ronda", "polisi", "pakrt" }
local COUNTS = { pasar = 9, gelap = 6, warung = 9, ronda = 7, polisi = 8, pakrt = 8 }
local GENERATED_BASKET = "generated_bamboo_basket"
local ALLOWED = {
	87487192428396,
	85094565897097,
	103341007913673,
	138444489439223,
	115924626989907,
	119426685469058,
	10506531785,
	95025959179405,
	106061905410704,
}
-- Real Enum.PartType names the r8 applier maps to. "Sphere" is NOT one (Roblox calls it Ball).
local SHAPES = { Block = true, Cylinder = true, Ball = true, Wedge = true }
-- Verified real Enum.Material members used by the r8 procedural recipes. "Paper" and "Leaf" are NOT ones.
local MATERIALS = {
	WoodPlanks = true,
	Wood = true,
	Grass = true,
	Metal = true,
	SmoothPlastic = true,
	Cardboard = true,
	Fabric = true,
}

local function closeTo(value, target, epsilon)
	return type(value) == "number" and math.abs(value - target) <= (epsilon or 1e-9)
end

return function(t, Env)
	local expect = t.expect

	local dataSrc = fs.readFile("src/shared/ModelMapHubPropsR8.luau")
	local applierSrc = fs.readFile("src/server/World/LookDevHubPropsR8.luau")
	local harnessSrc = fs.readFile("tools/studio/review_check_r8.luau")
	local mainSrc = fs.readFile("src/server/Main.server.luau")
	local runnerSrc = fs.readFile("tests/run.luau")
	local candidatesSrc = fs.readFile("docs/v2/visual/CANDIDATES.md")
	local manifestSrc = fs.readFile("docs/v2/visual/art/ASSET_MANIFEST.md")

	local Data = Env.new():require("shared/ModelMapHubPropsR8")
	local Facades = Env.new():require("shared/ModelMapFacadesR8")
	local LookDev = Env.new():require("shared/LookDev")
	local Review = Env.new():require("shared/LookDevReview")
	local MapSpec = Env.new():require("server/World/MapSpec")
	local Cameras = Env.new():require("shared/ReviewCameras")

	t:describe("ModelMapHubPropsR8 pure data", function()
		t:it("covers all six Greybox hubs with 6-10 stable recipes each", function()
			expect(Data.id):toBe("hubprops_r8")
			expect(Data.familyId):toBe("hubprops_r8")
			expect(Data.folderName):toBe("LookDevHubPropsR8_hubprops_r8")
			expect(Data.minPropsPerHub):toBe(6)
			expect(Data.maxPropsPerHub):toBe(10)
			expect(Data.HUB_KEYS):toEqual(HUB_KEYS)
			expect(Data.HUB_KEYS):toEqual(MapSpec.HUB_ORDER)
			for _, key in ipairs(HUB_KEYS) do
				local hub = MapSpec.hub(key)
				expect(hub ~= nil):toBe(true)
				local entry = Data.HUBS[key]
				expect(entry ~= nil):toBe(true)
				expect(entry.model):toBe(hub.model)
				expect(entry.width):toBe(hub.width)
				expect(entry.depth):toBe(hub.depth)
				expect(closeTo(entry.front, hub.depth / 2)):toBe(true)
				local recipes = Data.recipes[key]
				expect(#recipes):toBe(COUNTS[key])
				expect(#recipes >= Data.minPropsPerHub and #recipes <= Data.maxPropsPerHub):toBe(true)
				local names = {}
				for _, recipe in ipairs(recipes) do
					expect(type(recipe.name)):toBe("string")
					expect(#recipe.name > 0):toBe(true)
					expect(names[recipe.name]):toBe(nil)
					names[recipe.name] = true
					expect(type(recipe.kind)):toBe("string")
					expect(recipe.source == "baked" or recipe.source == "procedural"):toBe(true)
					expect(type(recipe.lx)):toBe("number")
					expect(recipe.lz > entry.front):toBe(true) -- local +Z front apron, never on the floor
				end
			end
		end)

		t:it("spans every requested vernacular kind in its hub", function()
			for _, key in ipairs(HUB_KEYS) do
				local seen = {}
				for _, recipe in ipairs(Data.recipes[key]) do
					seen[recipe.kind] = true
				end
				for _, kind in ipairs(Data.KINDS_BY_HUB[key]) do
					expect(seen[kind]):toBe(true)
				end
			end
		end)

		t:it("uses only the nine verified IDs, all present in the asset manifest", function()
			local allowedCount = 0
			for id in pairs(Data.ALLOWED_IDS) do
				allowedCount += 1
				expect(Data.ALLOWED_IDS[id]):toBe(true)
			end
			expect(allowedCount):toBe(#ALLOWED)
			for _, id in ipairs(ALLOWED) do
				expect(Data.ALLOWED_IDS[id]):toBe(true)
				expect(string.find(manifestSrc, tostring(id), 1, true) ~= nil):toBe(true)
			end
			expect(Data.ALLOWED_GENERATED[GENERATED_BASKET]):toBe(true)
			local generatedCount = 0
			for _, key in ipairs(HUB_KEYS) do
				for _, recipe in ipairs(Data.recipes[key]) do
					if recipe.source == "baked" then
						if recipe.baked ~= nil then
							expect(recipe.baked):toBe(GENERATED_BASKET)
							expect(Data.ALLOWED_GENERATED[recipe.baked]):toBe(true)
							expect(recipe.id):toBe(nil)
							generatedCount += if key == "pasar" and recipe.kind == "bakul" then 1 else 0
						else
							expect(type(recipe.id)):toBe("number")
							expect(Data.ALLOWED_IDS[recipe.id]):toBe(true)
						end
					else
						expect(recipe.id):toBe(nil)
						expect(recipe.baked):toBe(nil)
					end
				end
			end
			expect(generatedCount >= 2):toBe(true)
		end)

		t:it("uses the real BambooBasket generationId with no invented asset ID", function()
			expect(string.find(dataSrc, "14b48661-4c08-425f-ab3f-c641c1a885fd", 1, true) ~= nil):toBe(true)
			expect(string.find(dataSrc, "generated_bamboo_basket", 1, true) ~= nil):toBe(true)
			for _, recipe in ipairs(Data.recipes.pasar) do
				if recipe.baked == GENERATED_BASKET then
					expect(closeTo(recipe.target[1], 2)):toBe(true)
					expect(closeTo(recipe.target[2], 2)):toBe(true)
					expect(closeTo(recipe.target[3], 1.5)):toBe(true)
				end
			end
		end)

		t:it("uses only real PartType names and Enum.Material members with legal sizes", function()
			for shape in pairs(SHAPES) do
				expect(applierSrc:find(shape .. ' = "' .. shape .. '"', 1, true) ~= nil):toBe(true)
			end
			expect(applierSrc:find("Sphere", 1, true) == nil):toBe(true)
			expect(MATERIALS.Paper):toBe(nil)
			local checked = 0
			for _, key in ipairs(HUB_KEYS) do
				for _, recipe in ipairs(Data.recipes[key]) do
					if recipe.source == "procedural" then
						for _, descriptor in ipairs(recipe.parts) do
							checked += 1
							expect(SHAPES[descriptor.shape]):toBe(true)
							expect(MATERIALS[descriptor.material]):toBe(true)
							expect(LookDev.isBuiltinMaterial(descriptor.material)):toBe(true)
							local sx, sy, sz = descriptor.size[1], descriptor.size[2], descriptor.size[3]
							if descriptor.shape == "Ball" then
								expect(closeTo(sx, sy)):toBe(true)
								expect(closeTo(sy, sz)):toBe(true)
							elseif descriptor.shape == "Cylinder" then
								expect(closeTo(sx, sz)):toBe(true)
							end
						end
					end
				end
			end
			expect(checked >= 60):toBe(true)
		end)

		t:it("gives every baked recipe a real-world target bbox", function()
			local bakedCount = 0
			for _, key in ipairs(HUB_KEYS) do
				for _, recipe in ipairs(Data.recipes[key]) do
					if recipe.source == "baked" then
						bakedCount += 1
						expect(type(recipe.target)):toBe("table")
						expect(#recipe.target):toBe(3)
						for _, value in ipairs(recipe.target) do
							expect(type(value)):toBe("number")
							expect(value > 0 and value <= 60):toBe(true)
						end
						expect(recipe.parts):toBe(nil)
					else
						expect(recipe.target):toBe(nil)
						expect(type(recipe.parts)):toBe("table")
						expect(#recipe.parts > 0):toBe(true)
						for _, part in ipairs(recipe.parts) do
							expect(type(part.name)):toBe("string")
							expect(SHAPES[part.shape]):toBe(true)
							expect(#part.size):toBe(3)
							expect(#part.offset):toBe(3)
							expect(#part.color):toBe(3)
							expect(LookDev.isBuiltinMaterial(part.material)):toBe(true)
							for _, value in ipairs(part.size) do
								expect(value > 0):toBe(true)
							end
							for _, channel in ipairs(part.color) do
								expect(channel >= 0 and channel <= 255):toBe(true)
							end
						end
					end
				end
			end
			expect(bakedCount >= 12):toBe(true)
		end)

		t:it("keeps every recipe centre out of its own item-78 door gauge", function()
			for _, key in ipairs(HUB_KEYS) do
				local g = Data.GAUGES[key]
				local fromFacades = Facades.hubs[key].gauge
				expect(closeTo(g.w, fromFacades.w)):toBe(true)
				expect(closeTo(g.h, fromFacades.h)):toBe(true)
				expect(closeTo(g.d, fromFacades.d)):toBe(true)
				for _, recipe in ipairs(Data.recipes[key]) do
					local inside = math.abs(recipe.lx - g.lx) < g.w / 2 and math.abs(recipe.lz - g.lz) < g.d / 2
					expect(inside):toBe(false)
				end
			end
		end)

		t:it("places at least five recipe centres inside each hub camera's 35-degree cone", function()
			local coneCos = math.cos(math.rad(35))
			for _, key in ipairs(HUB_KEYS) do
				local camera = Cameras.get("hub_" .. key)
				expect(camera ~= nil):toBe(true)
				local hub = MapSpec.hub(key)
				local eye, look = camera.position, camera.lookAt
				local ldx, ldz = look[1] - eye[1], look[3] - eye[3]
				local lookMag = math.sqrt(ldx * ldx + ldz * ldz)
				expect(lookMag > 0):toBe(true)
				local inside = 0
				local previous = nil
				for _, recipe in ipairs(Data.recipes[key]) do
					local x, z = MapSpec.hubPoint(hub, recipe.lx, recipe.lz)
					local dx, dz = x - eye[1], z - eye[3]
					local mag = math.sqrt(dx * dx + dz * dz)
					expect(mag > 0):toBe(true)
					if (dx * ldx + dz * ldz) / (mag * lookMag) >= coneCos then
						inside += 1
					end
					if previous then
						local sx, sz = x - previous[1], z - previous[2]
						expect(math.sqrt(sx * sx + sz * sz) >= 2.5):toBe(true)
					end
					previous = { x, z }
				end
				expect(inside >= 5):toBe(true)
				-- Every slot is placed inside the cone by construction; the old skewed row left
				-- four Pasar and one Gelap/Ronda/Polisi centre outside it.
				expect(inside == #Data.recipes[key]):toBe(true)
			end
		end)

		t:it("keeps at least five props per hub unmasked from that hub's review camera", function()
			local function radius(recipe)
				if recipe.source == "baked" then
					return math.max(recipe.target[1], recipe.target[3]) / 2
				end
				local r = 0
				for _, piece in ipairs(recipe.parts) do
					r = math.max(
						r,
						math.abs(piece.offset[1]) + piece.size[1] / 2,
						math.abs(piece.offset[3]) + piece.size[3] / 2
					)
				end
				return r
			end
			for _, key in ipairs(HUB_KEYS) do
				local camera = Cameras.get("hub_" .. key)
				expect(camera ~= nil):toBe(true)
				local hub = MapSpec.hub(key)
				local eye = camera.position
				local props = {}
				for _, recipe in ipairs(Data.recipes[key]) do
					local x, z = MapSpec.hubPoint(hub, recipe.lx, recipe.lz)
					props[#props + 1] = { x = x, z = z, r = radius(recipe) }
				end
				local visible = 0
				for index, prop in ipairs(props) do
					local dx, dz = prop.x - eye[1], prop.z - eye[3]
					local distance = math.sqrt(dx * dx + dz * dz)
					local masked = false
					for otherIndex, other in ipairs(props) do
						if index ~= otherIndex then
							local ox, oz = other.x - eye[1], other.z - eye[3]
							local fraction = (ox * dx + oz * dz) / (distance * distance)
							if fraction > 0.02 and fraction < 0.98 then
								local px, pz = eye[1] + dx * fraction, eye[3] + dz * fraction
								if math.sqrt((px - other.x) ^ 2 + (pz - other.z) ^ 2) < other.r then
									masked = true
								end
							end
						end
					end
					if not masked then
						visible += 1
					end
				end
				expect(visible >= 5):toBe(true)
			end
		end)

		t:it("is pure data with no game APIs, Instances, colours, Enums or asset URLs", function()
			expect(string.find(dataSrc, "game.", 1, true) ~= nil):toBe(false)
			expect(string.find(dataSrc, "Instance.new", 1, true) ~= nil):toBe(false)
			expect(string.find(dataSrc, "Color3", 1, true) ~= nil):toBe(false)
			expect(string.find(dataSrc, "Enum.", 1, true) ~= nil):toBe(false)
			expect(string.find(dataSrc, "rbxassetid://%d") ~= nil):toBe(false)
		end)
	end)

	t:describe("hubprops_r8 server applier", function()
		t:it("uses the live hub frame and stages tagged prop Models in per-hub folders", function()
			expect(applierSrc:find("LookDev.register(FAMILY_ID", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("MapSpec.hubPoint(hub, recipe.lx, recipe.lz)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("math.rad(hub.yaw + (recipe.yaw or 0))", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("SetAttribute(Data.HUB_ATTRIBUTE, hubKey)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('prop.Name = hubKey .. "_" .. recipe.kind', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("SetAttribute(Data.PROP_ATTRIBUTE, true)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("SetAttribute(Data.KIND_ATTRIBUTE, recipe.kind)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("SetAttribute(Data.SOURCE_ATTRIBUTE, recipe.source)", 1, true) ~= nil):toBe(true)
		end)

		t:it("strips scripts, measures GetBoundingBox, scales to target and anchors baked props", function()
			expect(applierSrc:find("LookDevAssetLoader.get(recipe.id, FAMILY_ID)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Data.ALLOWED_IDS[recipe.id]", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("stripScripts(model)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Script = true, LocalScript = true, ModuleScript = true", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("instance:GetBoundingBox()", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("scaleModelToTarget(model, recipe.target, label)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("beforeSize.X * sx", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("part.Anchored = true", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("part.CanCollide = false", 1, true) ~= nil):toBe(true)
		end)

		t:it("clones step-(2) generated geometry from ServerStorage with no asset ID or LoadAsset", function()
			expect(applierSrc:find('local ServerStorage = service("ServerStorage")', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('FindFirstChild("LookDevAssets")', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Data.ALLOWED_GENERATED[recipe.baked]", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("local function generatedModel(", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("return source:Clone()", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("if generated then generatedModel(generated, label)", 1, true) ~= nil):toBe(true)
			local generatedAt = string.find(applierSrc, "local function generatedModel(", 1, true)
			local stageAt = generatedAt and string.find(applierSrc, "local function stageBaked(", generatedAt, true)
				or nil
			local generatedBody = generatedAt and stageAt and applierSrc:sub(generatedAt, stageAt) or ""
			expect(string.find(generatedBody, "LoadAsset", 1, true) == nil):toBe(true)
		end)

		t:it("paints Ground pads, fails loudly and destroys all staged instances on restore", function()
			expect(applierSrc:find("Enum.Material.Ground", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("terrain:FillBlock(", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("LookDevFailures.set(FAMILY_ID, failures)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("staged[#staged + 1] = instance", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("staged[index]:Destroy()", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("table.clear(staged)", 1, true) ~= nil):toBe(true)
			local restoreAt = string.find(applierSrc, "restore = function()", 1, true)
			local clearAt = restoreAt and string.find(applierSrc, "clearActive()", restoreAt, true) or nil
			expect(restoreAt ~= nil and clearAt ~= nil):toBe(true)
			expect(string.find(mainSrc, "pcall(require, script.Parent.World.LookDevHubPropsR8)", 1, true) ~= nil):toBe(
				true
			)
		end)

		t:it("snapshots exact Terrain voxels before each pad and restores them on disable", function()
			expect(applierSrc:find("local savedVoxels: { any } = {}", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("terrain:ReadVoxels(region, VOXEL)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("local function restoreSavedVoxels()", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("entry.terrain:WriteVoxels(", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("entry.waterMask", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("math.floor((cx - sx / 2) / VOXEL) * VOXEL", 1, true) ~= nil):toBe(true)
			local saveAt = string.find(applierSrc, "savePadVoxels(terrain, region, label)", 1, true)
			local fillAt = saveAt and string.find(applierSrc, "terrain:FillBlock(", saveAt, true) or nil
			expect(saveAt ~= nil and fillAt ~= nil):toBe(true)
			local restoreAt = string.find(applierSrc, "restore = function()", 1, true)
			local restoreVoxAt = restoreAt and string.find(applierSrc, "restoreSavedVoxels()", restoreAt, true) or nil
			expect(restoreVoxAt ~= nil):toBe(true)
			local applyAt = string.find(applierSrc, "apply = function(plan)", 1, true)
			local applyVoxAt = applyAt and string.find(applierSrc, "restoreSavedVoxels()", applyAt, true) or nil
			expect(applyVoxAt ~= nil):toBe(true)
		end)
	end)

	t:describe("hubprops_r8 Studio harness", function()
		t:it("registers HUBPROPS_VISIBLE and HUBPROPS_ON_GRASS with unweakened targets", function()
			expect(harnessSrc:find('"HUBPROPS_VISIBLE"', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('"HUBPROPS_ON_GRASS"', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("HUBPROPS_MIN_VISIBLE = 5", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('Cameras.get("hub_" .. key)', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("visibleFrom(prop, centre, camera[1], camera[2])", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("grassAt({ x = centre.X, z = centre.Z })", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("hubPropsMinVisible >= HUBPROPS_MIN_VISIBLE", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("hubPropsGrass == 0", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("hubPropsRun:IsServer() == true", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('attr(model, "HubProp") == true', 1, true) ~= nil):toBe(true)
		end)
	end)

	t:describe("hubprops_r8 registry, review, tests and gallery", function()
		t:it("ships candidate 57 with a plan and a server review path", function()
			expect(#LookDev.IDS):toBe(107)
			expect(LookDev.IDS[57]):toBe("hubprops_r8")
			expect(LookDev.candidates.hubprops_r8.status):toBe("candidate, awaiting designer yes")
			expect(LookDev.candidates.hubprops_r8.idsSource):toBe("Shared.ModelMapHubPropsR8")
			expect(LookDev.candidates.hubprops_r8.hubCount):toBe(6)
			local plan = LookDev.plan("hubprops_r8")
			expect(plan ~= nil):toBe(true)
			expect(plan.id):toBe("hubprops_r8")
			expect(plan.idsSource):toBe("Shared.ModelMapHubPropsR8")
			expect(plan.render):toBe(RENDER)
			expect(plan.hubCount):toBe(6)
			local entry = Review.paths.hubprops_r8
			expect(entry ~= nil):toBe(true)
			expect(entry.datamodel):toBe("server")
			expect(entry.path):toEqual({ "World", "LookDevHubPropsR8" })
			expect(string.find(runnerSrc, 'require("./specs/hubprops_r8_spec")', 1, true) ~= nil):toBe(true)
		end)

		t:it("has a gallery row with an existing render and a literal fps cost", function()
			local row = nil
			for line in string.gmatch(candidatesSrc, "[^\n]+") do
				if string.find(line, "`hubprops_r8`", 1, true) then
					row = line
				end
			end
			expect(row ~= nil):toBe(true)
			expect(string.find(row, 'LookDev.enable("hubprops_r8")', 1, true) ~= nil):toBe(true)
			expect(string.find(row, "`" .. RENDER .. "`", 1, true) ~= nil):toBe(true)
			expect(fs.isFile(RENDER) or fs.isDir(RENDER)):toBe(true)
			expect(string.find(string.lower(row), "fps", 1, true) ~= nil):toBe(true)
			expect(string.find(row, "pending", 1, true) ~= nil):toBe(true)
		end)

		t:it("documents the OFF-by-default candidate and no Studio verdict", function()
			local readme = fs.readFile(RENDER)
			expect(string.find(readme, "OFF by default", 1, true) ~= nil):toBe(true)
			expect(string.find(readme, "SERVER", 1, true) ~= nil):toBe(true)
			expect(string.find(readme, "HUBPROPS_VISIBLE", 1, true) ~= nil):toBe(true)
			expect(string.find(readme, "HUBPROPS_ON_GRASS", 1, true) ~= nil):toBe(true)
			local review = fs.readFile("docs/v2/evidence/h/2026-11-21-round9/REVIEW_ROUND9.md")
			expect(string.find(review, "hubprops_r8", 1, true) ~= nil):toBe(true)
			expect(string.find(review, "No Studio result", 1, true) ~= nil):toBe(true)
		end)
	end)
end
