--!nocheck
-- Greybox spec: terrain rebuild must clear every volume it owns before refilling, so repeated
-- builds do not stack water and terrace voxels.

return function(t, Env)
	local expect = t.expect
	local env, Greybox, MapSpec

	t:describe("Greybox terrain rebuild", function()
		t:beforeEach(function()
			env = Env.new()
			env:mock("server/World/Map", {
				TAGS = { Greybox = "GreyboxWorld" },
				all = function()
					return {}
				end,
				isDesignerWorld = function()
					return false
				end,
				add = function() end,
			})
			env:mock("server/World/Props", {
				palette = function()
					return { R = 0, G = 0, B = 0 }
				end,
				part = function()
					return {}
				end,
			})
			env:mock("server/World/NpcFactory", { build = function() end })
			env:mock("server/World/Ground", { Y = 0.5 })
			env.globals.CFrame = {
				new = function(x, y, z)
					return { position = Env.Vector3.new(x, y, z) }
				end,
				lookAt = function(at, look)
					return { position = at, look = look }
				end,
			}
			Greybox = env:require("server/World/Greybox")
			MapSpec = env:require("server/World/MapSpec")
		end)

		-- Visible face of a Greybox terrain block: regionTop + TERRAIN_VOXEL / 2.
		local function faceOf(block)
			return block.cframe.position.Y + block.size.Y / 2 + MapSpec.TERRAIN_VOXEL / 2
		end

		t:it("owns village ground, roads, hubs, river and terrace rows", function()
			local blocks = Greybox.terrainBlocks()
			local spec = MapSpec.terrainBlocks()
			expect(#blocks):toBe(#spec)
			expect(#blocks > 0):toBe(true)
			-- One-to-one with MapSpec, in order, nothing wider than MAX_FILL_SPAN.
			for index, block in blocks do
				local volume = spec[index]
				expect(block.material):toBe("Material." .. volume.material)
				expect(block.size.X):toBe(volume.size[1])
				expect(block.size.Y):toBe(volume.size[2])
				expect(block.size.Z):toBe(volume.size[3])
				expect(block.cframe.position.X):toBe(volume.centre[1])
				expect(block.cframe.position.Y):toBe(volume.centre[2])
				expect(block.cframe.position.Z):toBe(volume.centre[3])
				expect(block.size.X <= MapSpec.MAX_FILL_SPAN):toBe(true)
				expect(block.size.Z <= MapSpec.MAX_FILL_SPAN):toBe(true)
			end
			-- The base slab is Grass, comes first and covers the whole playable square.
			expect(blocks[1].material):toBe("Material.Grass")
			local side = MapSpec.TERRAIN_HALF * 2
			local grassArea = 0
			for _, block in blocks do
				if block.material == "Material.Grass" then
					grassArea += block.size.X * block.size.Z
				end
			end
			expect(grassArea):toBe(side * side)
			-- Terrace rows: the highest visible face among a terrace's Ground strips is its MapSpec top.
			-- Lower faces (stacked 4-stud layers) are expected and not asserted away.
			for _, terrace in MapSpec.TERRACES do
				local top = -math.huge
				for _, block in blocks do
					local z = block.cframe.position.Z
					if block.material == "Material.Ground" and z > terrace.z0 and z < terrace.z1 then
						top = math.max(top, faceOf(block))
					end
				end
				expect(top):toBe(terrace.top)
			end
			-- River: carve, bed, bank and water lists exist and the water surface is at -0.5.
			local river = Greybox.riverVolumes()
			for _, kind in { "carves", "beds", "banks", "water" } do
				expect(#river[kind] > 0):toBe(true)
			end
			for _, water in river.water do
				expect(water.material):toBe("Material.Water")
				expect(faceOf(water)):toBe(-0.5)
			end
		end)

		t:it("keeps generated terrain at or below the 0.5-stud gameplay ground, terrace band excepted", function()
			-- Measured in Studio: a FillBlock's visible top face is regionTop + TERRAIN_VOXEL / 2
			-- (half a voxel above the region), so assert that face, not the region and not a
			-- whole-voxel snap. The sawah terraces are the one deliberate rise: they are skipped here and
			-- pinned to their MapSpec tops above. The river is its own list, checked at the end.
			local voxel = Greybox.TERRAIN_VOXEL
			local ground = Greybox.GROUND_Y
			expect(ground):toBe(0.5)
			expect(voxel):toBe(4)
			local bandMin, bandMax = math.huge, -math.huge
			for _, terrace in MapSpec.TERRACES do
				bandMin = math.min(bandMin, terrace.z0)
				bandMax = math.max(bandMax, terrace.z1)
			end
			local checked = 0
			for _, block in Greybox.terrainBlocks() do
				local z = block.cframe.position.Z
				if block.material ~= "Material.Water" and not (z > bandMin and z < bandMax) then
					checked += 1
					expect(faceOf(block) <= ground):toBe(true)
				end
			end
			expect(checked > 0):toBe(true)
			local river = Greybox.riverVolumes()
			for _, kind in { "beds", "banks" } do
				for _, block in river[kind] do
					expect(faceOf(block) <= ground):toBe(true)
				end
			end
		end)

		t:it("clears the entire terrain envelope before refilling", function()
			local clear = Greybox.terrainClearBlocks()
			expect(#clear):toBe(#MapSpec.terrainClear())
			local half = MapSpec.TERRAIN_HALF
			local area = 0
			local lowest, highest = math.huge, -math.huge
			for _, piece in clear do
				expect(piece.size.X <= MapSpec.MAX_FILL_SPAN):toBe(true)
				expect(piece.size.Z <= MapSpec.MAX_FILL_SPAN):toBe(true)
				expect(math.abs(piece.cframe.position.X) + piece.size.X / 2 <= half + 1e-6):toBe(true)
				expect(math.abs(piece.cframe.position.Z) + piece.size.Z / 2 <= half + 1e-6):toBe(true)
				area += piece.size.X * piece.size.Z
				lowest = math.min(lowest, piece.cframe.position.Y - piece.size.Y / 2)
				highest = math.max(highest, piece.cframe.position.Y + piece.size.Y / 2)
			end
			-- The strips tile the whole playable square.
			expect(area):toBe(half * 2 * (half * 2))
			-- Vertically: under the base slab and river bed, over the highest terrace's final top.
			local topTerrace = MapSpec.TERRACES[#MapSpec.TERRACES].top
			expect(lowest <= MapSpec.TERRAIN_BASE_Y - MapSpec.TERRAIN_VOXEL / 2):toBe(true)
			expect(lowest <= -8):toBe(true)
			expect(highest + MapSpec.TERRAIN_VOXEL / 2 >= topTerrace):toBe(true)
		end)

		t:it("scatters at least 14 trees", function()
			expect(#Greybox.treeSpots() >= 14):toBe(true)
		end)

		t:it("gives every tree at least 3 canopy balls", function()
			local spots = Greybox.treeSpots()
			for index = 1, #spots do
				expect(#Greybox.canopyLayout(index) >= 3):toBe(true)
			end
		end)

		t:it("clears the envelope with Air before filling anything, then carves the river before its beds", function()
			local calls = {}
			local terrain = {
				FillBlock = function(_, cframe, size, material)
					table.insert(calls, { cframe = cframe, size = size, material = material })
				end,
			}
			Greybox.applyTerrain(terrain)

			local clears = Greybox.terrainClearBlocks()
			local blocks = Greybox.terrainBlocks()
			local river = Greybox.riverVolumes()
			expect(#calls):toBe(#clears + #blocks + #river.carves + #river.beds + #river.banks + #river.water)
			-- Phase 1: the Air envelope, strip for strip.
			for index, clear in clears do
				local call = calls[index]
				expect(call.material):toBe("Material.Air")
				expect(call.size.X):toBe(clear.size.X)
				expect(call.size.Y):toBe(clear.size.Y)
				expect(call.size.Z):toBe(clear.size.Z)
				expect(call.cframe.position.X):toBe(clear.cframe.position.X)
				expect(call.cframe.position.Y):toBe(clear.cframe.position.Y)
				expect(call.cframe.position.Z):toBe(clear.cframe.position.Z)
			end
			-- Phase 2: every base block, in order, none of them Air.
			for index, block in blocks do
				local call = calls[#clears + index]
				expect(call.material):toBe(block.material)
				expect(call.material ~= "Material.Air"):toBe(true)
				expect(call.size.X):toBe(block.size.X)
				expect(call.size.Z):toBe(block.size.Z)
				expect(call.cframe.position.Y):toBe(block.cframe.position.Y)
			end
			-- Phase 3: river carves (Air) first, then beds, banks and water.
			local cursor = #clears + #blocks
			for index = 1, #river.carves do
				expect(calls[cursor + index].material):toBe("Material.Air")
			end
			cursor += #river.carves
			for index = 1, #river.beds do
				expect(calls[cursor + index].material):toBe("Material.Mud")
			end
			cursor += #river.beds + #river.banks
			for index = 1, #river.water do
				expect(calls[cursor + index].material):toBe("Material.Water")
			end
		end)
	end)

	-- Billboards are the world labels a phone player reads. The real Props module is loaded here
	-- with just enough Roblox globals to build BillboardGui/TextLabel stand-ins.
	t:describe("Props billboard readability", function()
		local env, Props, instances

		t:beforeEach(function()
			env = Env.new()
			instances = {}
			env.globals.Color3 = {
				fromHex = function()
					return { R = 0, G = 0, B = 0 }
				end,
				fromRGB = function(r, g, b)
					return { R = r, G = g, B = b }
				end,
				new = function(r, g, b)
					return { R = r, G = g, B = b }
				end,
			}
			env.globals.UDim2 = {
				fromOffset = function(x, y)
					return { Width = x, Height = y }
				end,
				fromScale = function(x, y)
					return { Width = x, Height = y }
				end,
			}
			env.globals.Instance = {
				new = function(className)
					local object = { ClassName = className }
					table.insert(instances, object)
					return object
				end,
			}
			Props = env:require("server/World/Props")
		end)

		t:it("caps the pixel size of a label", function()
			local label = Props.billboard({}, 4, { X = 400, Y = 200 })
			local gui = label.Parent
			expect(gui.Size.Width):toBe(240)
			expect(gui.Size.Height):toBe(60)
		end)

		t:it("fades labels by default within 140 studs and is not AlwaysOnTop", function()
			local label = Props.billboard({}, 4, { X = 140, Y = 40 })
			local gui = label.Parent
			expect(gui.MaxDistance > 0):toBe(true)
			expect(gui.MaxDistance <= 140):toBe(true)
			expect(gui.AlwaysOnTop):toBe(false)
		end)

		t:it("uses a fixed text size between 12 and 28, not TextScaled", function()
			local label = Props.billboard({}, 4, { X = 140, Y = 40 })
			expect(label.TextScaled):toBe(false)
			expect(label.TextSize >= 12):toBe(true)
			expect(label.TextSize <= 28):toBe(true)
		end)
	end)

	-- Hub buildings: the real Greybox.build runs against fake Instances with the real Props, so
	-- every hub it builds is checked for a pitched roof and a readable sign label.
	t:describe("Greybox hub buildings", function()
		local HUB_SIGNS = {
			Pasar = "PASAR",
			TengkulakGelap = "TENGKULAK GELAP",
			RumahPakRT = "RUMAH PAK RT",
			PosPolisi = "POS POLISI",
			PosRonda = "POS RONDA",
			Warung = "WARUNG",
		}
		local env, instances, Greybox, world, MapSpec

		-- Stand-in for Color3:Lerp: remembers the palette colour it came from, the goal and the amount.
		local function lerpColour(self, goal, alpha)
			return { base = self.base or self.hex, toward = goal.hex, amount = alpha, Lerp = lerpColour }
		end

		local function hub(name)
			for _, child in world:GetChildren() do
				if child.Name == name and child.ClassName == "Model" then
					return child
				end
			end
			return nil
		end

		t:beforeEach(function()
			env = Env.new()
			instances = {}

			local function children(parent)
				local list = {}
				for _, object in instances do
					if object.Parent == parent and not object.Destroyed then
						table.insert(list, object)
					end
				end
				return list
			end

			local function descendants(parent)
				local list = {}
				for _, child in children(parent) do
					table.insert(list, child)
					for _, item in descendants(child) do
						table.insert(list, item)
					end
				end
				return list
			end

			local function newInstance(className)
				local object = { ClassName = className, Name = className }
				object.SetAttribute = function(self, key, value)
					self.attributes = self.attributes or {}
					self.attributes[key] = value
				end
				object.IsA = function(self, name)
					return self.ClassName == name or (name == "BasePart" and self.ClassName == "Part")
				end
				object.GetChildren = function(self)
					return children(self)
				end
				object.GetDescendants = function(self)
					return descendants(self)
				end
				object.FindFirstChild = function(self, name)
					for _, child in children(self) do
						if child.Name == name then
							return child
						end
					end
					return nil
				end
				object.FindFirstChildOfClass = function(self, className)
					for _, child in children(self) do
						if child.ClassName == className then
							return child
						end
					end
					return nil
				end
				object.Destroy = function(self)
					self.Destroyed = true
					self.Parent = nil
				end
				table.insert(instances, object)
				return object
			end

			-- CFrame stand-in: a position and a tilt about X (radians). Enough for the headroom check.
			local cframeMeta = {}
			cframeMeta.__mul = function(a, b)
				return setmetatable({ Position = a.Position, tiltX = a.tiltX + b.tiltX }, cframeMeta)
			end
			env.globals.CFrame = {
				new = function(x, y, z)
					local position = if y == nil then x else { X = x, Y = y, Z = z }
					return setmetatable({ Position = position, tiltX = 0 }, cframeMeta)
				end,
				Angles = function(x)
					return setmetatable({ Position = { X = 0, Y = 0, Z = 0 }, tiltX = x }, cframeMeta)
				end,
				lookAt = function(at, look)
					local lookVec = if look and at then { X = look.X - at.X, Y = look.Y - at.Y, Z = look.Z - at.Z } else { X = 0, Y = 0, Z = -1 }
					return setmetatable({ Position = at, LookVector = lookVec, tiltX = 0 }, cframeMeta)
				end,
			}
			env.globals.Color3 = {
				fromHex = function(hex)
					return { hex = hex, Lerp = lerpColour }
				end,
				fromRGB = function(r, g, b)
					return { R = r, G = g, B = b }
				end,
				new = function(r, g, b)
					return { R = r, G = g, B = b }
				end,
			}
			env.globals.Vector2 = {
				new = function(x, y)
					return { X = x, Y = y }
				end,
			}
			env.globals.UDim2 = {
				fromOffset = function(x, y)
					return { Width = x, Height = y }
				end,
				fromScale = function(x, y)
					return { Width = x, Height = y }
				end,
			}
			env.services.CollectionService = {
				AddTag = function() end,
				GetTagged = function()
					return {}
				end,
			}
			env.globals.Instance = {
				new = newInstance,
			}
			local terrain = {
				FillBlock = function() end,
				FillBall = function() end,
				SetMaterialColor = function() end,
			}
			env.globals.workspace = {
				Terrain = terrain,
				FindFirstChild = function()
					return nil
				end,
			}
			env:mock("server/World/Map", {
				TAGS = {
					Greybox = "GreyboxWorld",
					Pasar = "Pasar",
					Gelap = "Gelap",
					PakRT = "PakRT",
					Polisi = "Polisi",
					Ronda = "Ronda",
					Warung = "Warung",
					PlayerSpawn = "PlayerSpawn",
				},
				all = function()
					return {}
				end,
				isDesignerWorld = function()
					return false
				end,
				add = function() end,
			})
			env:mock("server/World/NpcFactory", { build = function() end })
			env:mock("server/World/Ground", { Y = 0.5 })
			Greybox = env:require("server/World/Greybox")
			MapSpec = env:require("server/World/MapSpec")
			world = Greybox.build()
		end)

		t:it("gives every hub a pitched roof built from at least two Roof slabs", function()
			for name in HUB_SIGNS do
				local model = hub(name)
				expect(model ~= nil):toBe(true)
				local roofs = 0
				for _, item in model:GetDescendants() do
					if item.Name == "Roof" then
						roofs = roofs + 1
					end
				end
				expect(roofs >= 2):toBe(true)
			end
		end)

		-- Headroom: the lowest point of each roof, awning, spanduk and trim must clear a player by MapSpec.HEADROOM.
			local HEADROOM_PARTS = { Roof = true, RoofRidge = true, Awning = true, Spanduk = true, KunyitTrim = true, MalamTrim = true }

			-- Lowest point of a part. A box tilted about X drops by half-height*|cos| + half-depth*|sin|.
			local function lowestY(item)
				local tilt = if item.CFrame then item.CFrame.tiltX else 0
				local centreY = if item.CFrame then item.CFrame.Position.Y else item.Position.Y
				return centreY - (item.Size.Y / 2 * math.abs(math.cos(tilt)) + item.Size.Z / 2 * math.abs(math.sin(tilt)))
			end

			t:it("keeps every hub roof, awning, spanduk and trim at least MapSpec.HEADROOM above the ground", function()
				local GROUND, HEADROOM = MapSpec.GROUND_Y, MapSpec.HEADROOM
				for name in HUB_SIGNS do
					local checked = 0
					for _, item in hub(name):GetDescendants() do
						if HEADROOM_PARTS[item.Name] then
							checked += 1
							expect(lowestY(item) >= GROUND + HEADROOM - 1e-6):toBe(true)
						end
					end
					expect(checked > 0):toBe(true)
				end
			end)

			t:it("keeps the Pos Ronda watchtower clear of the hut roof footprint", function()
				-- The hut roof covers x -37..-23 and z -32..-20; no watchtower leg or deck may stand under it.
				for _, item in hub("PosRonda"):GetDescendants() do
					if item.Name == "TowerLeg" or item.Name == "TowerDeck" then
						local insideHut = math.abs(item.Position.X + 30) <= 7 and math.abs(item.Position.Z + 26) <= 6
						expect(insideHut):toBe(false)
					end
				end
			end)

			t:it("paints the hub's name on both faces of its sign board, with no floating billboard", function()
			local faces = { SignFront = "NormalId.Front", SignBack = "NormalId.Back" }
			for name, text in HUB_SIGNS do
				local board = hub(name):FindFirstChild("Sign")
				expect(board ~= nil):toBe(true)
				expect(board:FindFirstChildOfClass("BillboardGui") == nil):toBe(true)
				for faceName, face in faces do
					local gui = board:FindFirstChild(faceName)
					expect(gui ~= nil):toBe(true)
					expect(gui.ClassName):toBe("SurfaceGui")
					expect(gui.Face):toBe(face)
					expect(gui:FindFirstChild("Label").Text):toBe(text)
				end
			end
		end)

		t:it("frames spawn toward the village road, Pasar and Pak RT landmark", function()
			local spawnPart
			for _, child in world:GetChildren() do
				if child.Name == "Spawn" then
					spawnPart = child
					break
				end
			end
			expect(spawnPart ~= nil):toBe(true)
			expect(spawnPart.CFrame ~= nil):toBe(true)
			expect(spawnPart.Position.X):toBe(MapSpec.SPAWN.x)
			expect(spawnPart.Position.Z):toBe(MapSpec.SPAWN.z)
			expect(spawnPart.CFrame.LookVector.Z * MapSpec.SPAWN.lookZ > 0):toBe(true)
			expect(spawnPart.CFrame.LookVector.Z < 0):toBe(true) -- north, up the road toward the Balai
		end)
	end)
end
