--!nocheck
-- WORK_QUEUE round 4 item 28: regression coverage for round-3 review bugs 2-7 (bug 1, the
-- LookDev.enable dot syntax, was already fixed). Static + fake-DataModel proof only: no Studio
-- screenshot, no visual verdict, no place save, no asset ID invented here.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect

	local REAL_SKY_KEYS = {
		SkyboxBk = 102550480946849,
		SkyboxDn = 129220381103008,
		SkyboxFt = 133281364333444,
		SkyboxLf = 138405045926458,
		SkyboxRt = 102997698570968,
		SkyboxUp = 119387111356535,
	}
	local OLD_SKY_KEYS = {
		"SkyboxImageBack",
		"SkyboxImageBottom",
		"SkyboxImageFront",
		"SkyboxImageLeft",
		"SkyboxImageRight",
		"SkyboxImageTop",
	}

	t:describe("round-3 bug 2 — sky_r3 uses real Sky keys and a Color3 Decay", function()
		t:it("keys all six unchanged face IDs by the real Roblox Sky properties", function()
			local SkyMapR3 = Env.new():require("shared/SkyMapR3")
			local seen, count = {}, 0
			for key, id in SkyMapR3.ids do
				count += 1
				expect(REAL_SKY_KEYS[key] ~= nil):toBe(true)
				expect(id):toBe(REAL_SKY_KEYS[key])
				expect(seen[key]):toBe(nil)
				seen[key] = true
			end
			expect(count):toBe(6)
			for _, old in ipairs(OLD_SKY_KEYS) do
				expect(SkyMapR3.ids[old]):toBe(nil)
			end
			expect(SkyMapR3.faceCount()):toBe(6)
		end)

		t:it("keeps the recipe numbers but makes Decay a plain RGB array", function()
			local SkyMapR3 = Env.new():require("shared/SkyMapR3")
			local a = SkyMapR3.atmosphere
			expect(a.Density):toBe(0.22)
			expect(a.Offset):toBe(0.55)
			expect(a.Glare):toBe(1.2)
			expect(a.Haze):toBe(2.4)
			expect(a.Color):toEqual({ 214, 223, 230 })
			expect(type(a.Decay)):toBe("table")
			expect(a.Decay):toEqual({ 120, 150, 160 })
			for _, channel in a.Decay do
				expect(type(channel)):toBe("number")
			end
			local count = 0
			for _ in a do
				count += 1
			end
			expect(count):toBe(6)
		end)

		t:it("the applier writes the real keys and resolves Decay to a Color3 at apply time", function()
			local instances = {}

			local function newInstance(className)
				local fields = { ClassName = className, Name = className, Parent = nil }
				function fields:Destroy()
					self.Parent = nil
				end
				local object = setmetatable({}, {
					__index = fields,
					__newindex = function(_, key, value)
						fields[key] = value
					end,
				})
				table.insert(instances, object)
				return object
			end

			local function find(parent, className, name)
				for _, object in ipairs(instances) do
					if
						object.Parent == parent
						and object.ClassName == className
						and (name == nil or object.Name == name)
					then
						return object
					end
				end
				return nil
			end

			local env = Env.new()
			local lighting = { ClassName = "Lighting" }
			local workspace = { ClassName = "Workspace" }
			lighting.FindFirstChildOfClass = function(_, className)
				return find(lighting, className)
			end
			workspace.FindFirstChildOfClass = function(_, className)
				return find(workspace, className)
			end
			env.services.Lighting = lighting
			env.services.Workspace = workspace
			env.globals.Instance = { new = newInstance }
			env.globals.Color3 = {
				fromRGB = function(r, g, b)
					return { R = r / 255, G = g / 255, B = b / 255 }
				end,
				fromHex = function(hex)
					return { hex = hex }
				end,
			}

			local SkyMapR3 = env:require("shared/SkyMapR3")
			local adapter = env:require("client/World/LookDevSkyR3")
			adapter.apply(nil)
			local sky = find(lighting, "Sky", "SkyR3")
			expect(sky ~= nil):toBe(true)
			for key, id in REAL_SKY_KEYS do
				expect(sky[key]):toBe("rbxassetid://" .. tostring(id))
			end
			local atmosphere = find(lighting, "Atmosphere")
			expect(atmosphere ~= nil):toBe(true)
			expect(atmosphere.Decay):toEqual({ R = 120 / 255, G = 150 / 255, B = 160 / 255 })
			expect(pcall(adapter.restore)):toBe(true)
		end)
	end)

	t:describe("round-3 bug 6 — staging is on real MapSpec ground away from spawn", function()
		t:it("shares one origin inside PLAZA and keeps all staged coordinates off spawn/roads", function()
			local env = Env.new()
			local MapSpec = env:require("server/World/MapSpec")
			local Corner = env:require("shared/LookDevCorner")
			local Models = env:require("shared/ModelMapR3")
			local Sky = env:require("shared/SkyMapR3")

			local origin = Corner.ORIGIN
			expect(origin[1]):toBe(Models.STAGING_ORIGIN.x)
			expect(origin[3]):toBe(Models.STAGING_ORIGIN.z)
			expect(origin[1]):toBe(Sky.STAGING_ORIGIN.x)
			expect(origin[3]):toBe(Sky.STAGING_ORIGIN.z)

			local plaza = MapSpec.PLAZA
			local minX, maxX = plaza.x - plaza.width / 2, plaza.x + plaza.width / 2
			local minZ, maxZ = plaza.z - plaza.depth / 2, plaza.z + plaza.depth / 2
			expect(minX):toBe(-48)
			expect(maxX):toBe(48)
			expect(minZ):toBe(-42)
			expect(maxZ):toBe(42)
			expect(origin[1] > minX and origin[1] < maxX):toBe(true)
			expect(origin[3] > minZ and origin[3] < maxZ):toBe(true)
			expect(#Corner.partsInBounds()):toBe(#Corner.parts)

			local points = {}
			local function add(tag, x, z)
				table.insert(points, { tag = tag, x = x, z = z })
			end
			for _, part in ipairs(Corner.parts) do
				add(part.name, part.position[1], part.position[3])
			end
			for _, cam in ipairs(Corner.cameras) do
				add("camera/" .. cam.id, cam.position[1], cam.position[3])
			end
			for _, familyId in ipairs(Models.familyIds()) do
				for _, slot in ipairs(Models.families[familyId].slots) do
					add(familyId .. "/" .. slot.slot, slot.x, slot.z)
				end
			end
			for _, wedge in ipairs(Sky.ridge) do
				add(wedge.name, wedge.position[1], wedge.position[3])
			end
			-- The sky camera lives in the owned doc; prove that saved value was moved too.
			local readme = fs.readFile("docs/v2/visual/art/sky_r3/README.md")
			local line = string.match(readme, "[^\n]*`sky_horizon`[^\n]*")
			expect(line ~= nil):toBe(true)
			local nums = {}
			for n in string.gmatch(line, "%-?%d+%.?%d*") do
				table.insert(nums, tonumber(n))
			end
			expect(#nums):toBe(6)
			add("camera/sky_horizon", nums[1], nums[3])

			expect(#points >= 40):toBe(true)
			local spawn = MapSpec.SPAWN
			for _, point in ipairs(points) do
				expect(point.x >= minX and point.x <= maxX):toBe(true)
				expect(point.z >= minZ and point.z <= maxZ):toBe(true)
				local dx, dz = point.x - spawn.x, point.z - spawn.z
				expect(math.sqrt(dx * dx + dz * dz) >= spawn.size + 8):toBe(true)
			end

			-- Road arms are outside the plaza; prove no staged GEOMETRY sits on one.
			local geometry = {}
			for _, part in ipairs(Corner.parts) do
				table.insert(geometry, { part.position[1], part.position[3] })
			end
			for _, familyId in ipairs(Models.familyIds()) do
				for _, slot in ipairs(Models.families[familyId].slots) do
					table.insert(geometry, { slot.x, slot.z })
				end
			end
			for _, wedge in ipairs(Sky.ridge) do
				table.insert(geometry, { wedge.position[1], wedge.position[3] })
			end
			for _, road in ipairs(MapSpec.roadArms()) do
				local rx0, rx1 = road.x - road.sx / 2, road.x + road.sx / 2
				local rz0, rz1 = road.z - road.sz / 2, road.z + road.sz / 2
				for _, point in ipairs(geometry) do
					local onRoad = point[1] >= rx0 and point[1] <= rx1 and point[2] >= rz0 and point[2] <= rz1
					expect(onRoad):toBe(false)
				end
			end
		end)
	end)

	t:describe("round-3 bugs 3/4/5 — model staging data and server transforms", function()
		t:it("gives every slot a targetHeight and the two CC0 imports a rotX", function()
			local Models = Env.new():require("shared/ModelMapR3")
			local total = 0
			for _, familyId in ipairs(Models.familyIds()) do
				for _, slot in ipairs(Models.families[familyId].slots) do
					total += 1
					expect(type(slot.targetHeight)):toBe("number")
					expect(slot.targetHeight > 0 and slot.targetHeight < 100):toBe(true)
				end
			end
			expect(total):toBe(20)

			local byName = {}
			for _, slot in ipairs(Models.families.npcs_r3.slots) do
				byName[slot.slot] = slot
			end
			for _, id in ipairs({ "farmer_cc0", "polisi_cc0" }) do
				expect(math.abs(byName[id].rotX - math.pi / 2) < 0.0001):toBe(true)
			end
			for _, id in ipairs({ "villager_a", "villager_b", "villager_c", "villager_d" }) do
				expect(byName[id].rotX):toBe(nil)
			end
			for _, familyId in ipairs({ "buildings_r3", "vegetation_r3", "props_r3" }) do
				for _, slot in ipairs(Models.families[familyId].slots) do
					expect(slot.rotX):toBe(nil)
				end
			end
		end)

		t:it("keeps all 20 real upload IDs exactly", function()
			local raw = fs.readFile("docs/v2/visual/art/models_r3/upload_manifest.json")
			local rows = {}
			for slot, id in string.gmatch(raw, '"slot":%s*"([^"]+)".-"asset_id":%s*"([^"]+)"') do
				rows[slot] = tonumber(id)
			end
			local Models = Env.new():require("shared/ModelMapR3")
			local matched = 0
			for _, familyId in ipairs(Models.familyIds()) do
				for slot, id in pairs(Models.families[familyId].ids) do
					matched += 1
					expect(rows[familyId .. "/" .. slot]):toBe(id)
				end
			end
			expect(matched):toBe(20)
		end)

		t:it("anchors every BasePart, disables collision, scales and rotates with pcall", function()
			local adapter = fs.readFile("src/server/World/LookDevModelsR3.luau")
			expect(string.find(adapter, 'descendant:IsA("BasePart")', 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "descendant.Anchored = true", 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "descendant.CanCollide = false", 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "model:GetBoundingBox()", 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "model:ScaleTo(", 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "slot.targetHeight / size.Y", 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "CFrame.Angles(slot.rotX or 0, slot.ry, 0)", 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "InsertService:LoadAsset", 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "pcall(", 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "%d%d%d%d%d%d%d") == nil):toBe(true)
		end)
	end)

	t:describe("round-3 bug 7 — LookDevReview one-call helper", function()
		local function rootFor(env)
			return {
				ServerScriptService = env.services.ServerScriptService,
				PlayerScripts = env.roots.client.Parent,
			}
		end

		t:it("covers exactly the 57 existing candidates and their datamodel", function()
			local env = Env.new()
			local LookDev = env:require("shared/LookDev")
			local Review = env:require("shared/LookDevReview")
			local count = 0
			for _ in Review.paths do
				count += 1
			end
			expect(count):toBe(#LookDev.IDS)
			expect(count):toBe(62)
			for _, id in ipairs(LookDev.IDS) do
				local entry = Review.pathsFor(id)
				expect(entry ~= nil):toBe(true)
				expect(entry.datamodel == "client" or entry.datamodel == "server"):toBe(true)
				expect(type(entry.path[1])):toBe("string")
				expect(type(entry.path[2])):toBe("string")
			end
			local round4Datamodel = {
				textures_r4 = "client",
				sky_r4_a = "client",
				sky_r4_b = "client",
				sky_r4_c = "client",
				buildings_r4 = "server",
				vegetation_r4 = "server",
				props_r4 = "server",
				npcs_r4 = "server",
			}
			local round6Datamodel = {
				sky_r6_a = "client",
				sky_r6_b = "client",
				sky_r6_c = "client",
				sky_r6_d = "client",
				sky_r6_e = "client",
				sky_r6_f = "client",
			}
			for id, datamodel in pairs(round6Datamodel) do
				expect(Review.pathsFor(id).datamodel):toBe(datamodel)
				expect(Review.pathsFor(id).path):toEqual({ "World", "LookDevSkyR6" })
			end
			expect(Review.pathsFor("spawn_ground_r6").datamodel):toBe("server")
			expect(Review.pathsFor("spawn_ground_r6").path):toEqual({ "World", "LookDevSpawnGroundR6" })
			for id, datamodel in pairs(round4Datamodel) do
				expect(Review.pathsFor(id).datamodel):toBe(datamodel)
			end
			expect(Review.pathsFor("not_a_candidate")):toBe(nil)
			expect(Review.resolveContainer("server", rootFor(env))):toBe(env.services.ServerScriptService.Server)
			expect(Review.resolveContainer("client", rootFor(env))):toBe(env.roots.client)
			expect(Review.resolveContainer("client", {
				StarterPlayer = { StarterPlayerScripts = env.roots.client.Parent },
			})):toBe(env.roots.client)
		end)

		t:it("resolves containers when missing DataModel members throw on index", function()
			local env = Env.new()
			local Review = env:require("shared/LookDevReview")

			-- Real DataModels throw "X is not a valid member" instead of returning nil.
			local function throwingRoot(fields)
				return setmetatable(fields, {
					__index = function(_, key)
						error(key .. " is not a valid member", 2)
					end,
				})
			end

			local viaStarter = throwingRoot({
				StarterPlayer = { StarterPlayerScripts = env.roots.client.Parent },
			})
			expect(Review.resolveContainer("client", viaStarter)):toBe(env.roots.client)

			local viaPlayers = throwingRoot({
				Players = { LocalPlayer = { PlayerScripts = env.roots.client.Parent } },
			})
			expect(Review.resolveContainer("client", viaPlayers)):toBe(env.roots.client)

			local viaServerScripts = throwingRoot({
				ServerScriptService = env.services.ServerScriptService,
			})
			expect(Review.resolveContainer("server", viaServerScripts)):toBe(env.services.ServerScriptService.Server)
		end)

		t:it("requires the CLIENT applier before LookDev.enable", function()
			local env = Env.new()
			local events = {}
			env:mock("shared/LookDev", {
				register = function(id)
					table.insert(events, "register:" .. id)
				end,
				enable = function(id, opts)
					table.insert(events, "enable:" .. id)
					expect(opts.studio):toBe(true)
					return true, nil
				end,
				disable = function()
					table.insert(events, "disable")
					return true
				end,
			})
			local Review = env:require("shared/LookDevReview")
			local ok, why = Review.enable("icons", rootFor(env), { studio = true })
			expect(ok):toBe(true)
			expect(why):toBe(nil)
			expect(events):toEqual({ "register:icons", "enable:icons" })
			expect(Review.disable()):toBe(true)
			expect(events[3]):toBe("disable")
		end)

		t:it("requires the SERVER applier before LookDev.enable", function()
			local env = Env.new()
			env.services.InsertService = { LoadAsset = function() end }
			env.services.Workspace = {}
			local events = {}
			env:mock("shared/LookDev", {
				register = function(id)
					table.insert(events, "register:" .. id)
				end,
				enable = function(id)
					table.insert(events, "enable:" .. id)
					return true, nil
				end,
				disable = function()
					return true
				end,
			})
			local Review = env:require("shared/LookDevReview")
			local ok, why = Review.enable("buildings_r3", rootFor(env), { studio = true })
			expect(ok):toBe(true)
			expect(why):toBe(nil)
			expect(events):toEqual({
				"register:buildings_r3",
				"register:vegetation_r3",
				"register:props_r3",
				"register:npcs_r3",
				"enable:buildings_r3",
			})
		end)

		t:it("is pure at load, uses dot syntax and rejects bad ids/containers/requires", function()
			local src = fs.readFile("src/shared/LookDevReview.luau")
			expect(string.find(src, "game:GetService", 1, true) == nil):toBe(true)
			expect(string.find(src, "WaitForChild", 1, true) == nil):toBe(true)
			expect(string.find(src, "LookDev.enable(id, opts)", 1, true) ~= nil):toBe(true)
			expect(string.find(src, "LookDev:enable", 1, true) == nil):toBe(true)

			local env = Env.new()
			local Review = env:require("shared/LookDevReview")
			local ok, why = Review.enable("not_a_candidate", rootFor(env), { studio = true })
			expect(ok):toBe(false)
			expect(why):toBe("unknown review candidate")
			ok, why = Review.prepare("sky_r3", {})
			expect(ok):toBe(false)
			expect(why):toBe("missing client container")
			ok, why = Review.prepare("sky_r3", {
				PlayerScripts = { Client = { World = { LookDevSkyR3 = {} } } },
			})
			expect(ok):toBe(false)
			expect(string.find(why, "applier require failed", 1, true) ~= nil):toBe(true)
		end)
	end)
end
