--!nocheck
-- Greybox spec: terrain rebuild must clear every volume it owns before refilling, so repeated
-- builds do not stack water and terrace voxels.

return function(t, Env)
	local expect = t.expect
	local env, Greybox

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
		end)

		t:it("owns village ground, roads, hubs, river and terrace rows", function()
			local blocks = Greybox.terrainBlocks()
			expect(#blocks):toBe(15)
			expect(blocks[1].material):toBe("Material.Grass")
			expect(blocks[1].size.X):toBe(400)
			expect(blocks[1].cframe.position.Y):toBe(-3.5)
			expect(blocks[1].size.Y):toBe(4)
			expect(blocks[1].size.Z):toBe(400)
			expect(blocks[11].material):toBe("Material.Water")
			expect(blocks[11].size.X):toBe(220)
			expect(blocks[11].size.Y):toBe(8)
			expect(blocks[11].size.Z):toBe(100)
			for row = 0, 3 do
				local block = blocks[row + 12]
				expect(block.material):toBe("Material.Ground")
				expect(block.size.X):toBe(120 - row * 22)
				expect(block.size.Z):toBe(18)
				expect(block.cframe.position.Z):toBe(-100 + row * 14)
				expect(block.cframe.position.Y):toBe(-3.5)
				expect(block.size.Y):toBe(4)
			end
		end)

		t:it("keeps generated terrain at or below the 0.5-stud gameplay ground", function()
			-- Measured in Studio: a FillBlock's visible top face is regionTop + TERRAIN_VOXEL / 2
			-- (half a voxel above the region), so assert that face, not the region and not a
			-- whole-voxel snap.
			local voxel = Greybox.TERRAIN_VOXEL
			local ground = Greybox.GROUND_Y
			expect(ground):toBe(0.5)
			expect(voxel):toBe(4)
			for _, block in Greybox.terrainBlocks() do
				if block.material ~= "Material.Water" then
					local regionTop = block.cframe.position.Y + block.size.Y / 2
					local face = regionTop + voxel / 2
					expect(face <= ground):toBe(true)
				end
			end
		end)

		t:it("clears the entire legacy village terrain envelope before refilling", function()
			local clear = Greybox.terrainClearBlocks()
			expect(#clear):toBe(1)
			expect(clear[1].cframe.position.Y):toBe(0)
			expect(clear[1].size.X):toBe(400)
			expect(clear[1].size.Y):toBe(16)
			expect(clear[1].size.Z):toBe(400)
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

		t:it("clears each owned volume with Air before filling it", function()
			local calls = {}
			local terrain = {
				FillBlock = function(_, cframe, size, material)
					table.insert(calls, { cframe = cframe, size = size, material = material })
				end,
			}
			Greybox.applyTerrain(terrain)

			local blocks = Greybox.terrainBlocks()
			expect(#calls):toBe(#blocks * 2 + 1)
			expect(calls[1].material):toBe("Material.Air")
			expect(calls[1].size.X):toBe(400)
			expect(calls[1].size.Y):toBe(16)
			expect(calls[1].size.Z):toBe(400)
			for index, block in blocks do
				local clear = calls[index + 1]
				local fill = calls[index + #blocks + 1]
				expect(clear.material):toBe("Material.Air")
				expect(fill.material):toBe(block.material)
				expect(clear.size.X):toBe(fill.size.X)
				expect(clear.size.Y):toBe(fill.size.Y)
				expect(clear.size.Z):toBe(fill.size.Z)
				expect(clear.cframe.position.X):toBe(fill.cframe.position.X)
				expect(clear.cframe.position.Y):toBe(fill.cframe.position.Y)
				expect(clear.cframe.position.Z):toBe(fill.cframe.position.Z)
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
		local env, instances, Greybox, world

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

		-- Headroom: the lowest point of each roof, awning, spanduk and trim must clear a player by 9.5 studs.
			local HEADROOM_PARTS = { Roof = true, RoofRidge = true, Awning = true, Spanduk = true, KunyitTrim = true, MalamTrim = true }
			local GROUND = 0.5
			local HEADROOM = 9.5

			-- Lowest point of a part. A box tilted about X drops by half-height*|cos| + half-depth*|sin|.
			local function lowestY(item)
				local tilt = if item.CFrame then item.CFrame.tiltX else 0
				local centreY = if item.CFrame then item.CFrame.Position.Y else item.Position.Y
				return centreY - (item.Size.Y / 2 * math.abs(math.cos(tilt)) + item.Size.Z / 2 * math.abs(math.sin(tilt)))
			end

			t:it("keeps every hub roof, awning, spanduk and trim at least 9.5 studs above the ground", function()
				for name in HUB_SIGNS do
					local checked = 0
					for _, item in hub(name):GetDescendants() do
						if HEADROOM_PARTS[item.Name] then
							checked += 1
							expect(lowestY(item) >= GROUND + HEADROOM):toBe(true)
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
			expect(spawnPart.Position.X):toBe(0)
			expect(spawnPart.Position.Z):toBe(16)
			expect(spawnPart.CFrame.LookVector.Z < 0):toBe(true)
		end)
	end)
end
