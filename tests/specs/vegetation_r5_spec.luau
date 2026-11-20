--!nocheck
-- WORK_QUEUE item 37: vegetation_r5 LookDev candidate. Data + applier are checked under the Env
-- harness with fake InsertService/Workspace/CollectionService, so apply/skip/restore are exercised
-- without Studio. No visual verdict and no screenshot claim. Main session wires the central registry
-- and tests/run.luau; this spec is intentionally not self-registering there.

local fs = require("@lune/fs")

local DATA_PATH = "src/shared/ModelMapVegetationR5.luau"
local APPLIER_PATH = "src/server/World/LookDevModelsVegetationR5.luau"
local MANIFEST_PATH = "docs/v2/visual/art/vegetation_r5/MANIFEST.md"

return function(t, Env)
	local expect = t.expect
	local env = Env.new()
	local Data = env:require("shared/ModelMapVegetationR5")
	local R4 = env:require("shared/ModelMapVegetationR4")
	local MapSpec = env:require("server/World/MapSpec")
	local data = fs.readFile(DATA_PATH)
	local applier = fs.readFile(APPLIER_PATH)
	local manifest = fs.readFile(MANIFEST_PATH)
	local r4Ids = R4.families.vegetation_r4.ids
	local slots = Data.slots()

	local function newModel(appEnv, id)
		local parts = { {
			Anchored = false,
			CanCollide = true,
			IsA = function()
				return true
			end,
		} }
		local model = {
			Name = "loaded",
			Parent = nil,
			Destroyed = false,
			LoadedId = id,
			Scale = 0,
			GetBoundingBox = function()
				return { Y = 0 }, appEnv.Vector3.new(0, 0, 0), appEnv.Vector3.new(1, 4, 1)
			end,
			ScaleTo = function(self, factor)
				self.Scale = factor
			end,
			GetDescendants = function()
				return parts
			end,
			GetPivot = function()
				return { Y = 0 }
			end,
		}
		model.PivotTo = function(self, target)
			self.PlacedAt = target
		end
		model.SetPrimaryPartCFrame = function(self, target)
			self.PlacedAt = target
		end
		setmetatable(model, {
			__newindex = function(node, key, value)
				rawset(node, key, value)
				if key == "Parent" and type(value) == "table" and value.Children then
					table.insert(value.Children, node)
				end
			end,
		})
		return model
	end

	-- Fresh Env per case: the applier's active folder is module-local state.
	local function makeApp(anchors)
		local appEnv = Env.new()
		local state = { loaded = {}, folders = {} }
		appEnv.services.CollectionService = {
			GetTagged = function(_, tag)
				if tag == "PlotAnchor" then
					return anchors or {}
				end
				return {}
			end,
		}
		appEnv.services.InsertService = {
			LoadAsset = function(_, assetId)
				local model = newModel(appEnv, assetId)
				table.insert(state.loaded, model)
				return model
			end,
		}
		local workspace = { _children = {} }
		function workspace:FindFirstChild(name)
			return self._children[name]
		end
		appEnv.services.Workspace = workspace

		local cframeMeta = {}
		cframeMeta.__mul = function(a, b)
			return setmetatable({
				X = (a.X or 0) + (b.X or 0),
				Y = (a.Y or 0) + (b.Y or 0),
				Z = (a.Z or 0) + (b.Z or 0),
			}, cframeMeta)
		end
		appEnv.globals.CFrame = {
			new = function(x, y, z)
				return setmetatable({ X = x, Y = y, Z = z }, cframeMeta)
			end,
			Angles = function(x, y, z)
				return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, cframeMeta)
			end,
		}
		appEnv.globals.Instance = {
			new = function(className)
				local folder = { ClassName = className, Name = "", Parent = nil, Children = {}, Destroyed = false }
				function folder:Destroy()
					self.Destroyed = true
					for _, child in ipairs(self.Children) do
						child.Destroyed = true
						child.Parent = nil
					end
					if type(self.Parent) == "table" and self.Parent._children then
						self.Parent._children[self.Name] = nil
					end
					self.Parent = nil
				end
				setmetatable(folder, {
					__newindex = function(node, key, value)
						rawset(node, key, value)
						if key == "Parent" and type(value) == "table" and value._children then
							value._children[node.Name] = node
						end
					end,
				})
				table.insert(state.folders, folder)
				return folder
			end,
		}

		local registered = {}
		appEnv:mock("shared/LookDev", {
			register = function(id, applierTable)
				registered[id] = applierTable
			end,
		})
		appEnv:require("server/World/LookDevModelsVegetationR5")
		return state, registered, workspace
	end

	t:describe("vegetation_r5 data selects reused R4 IDs only", function()
		t:it("reuses exactly the three R4 asset IDs and embeds no ID literals", function()
			local keys = {}
			for key, id in pairs(Data.ids) do
				keys[key] = true
				expect(r4Ids[key]):toBe(id)
				expect(type(id)):toBe("number")
				expect(#tostring(id) >= 12 and tostring(id):match("^%d+$") ~= nil):toBe(true)
			end
			expect(keys.pisang):toBe(true)
			expect(keys.bambu):toBe(true)
			expect(keys.mangga):toBe(true)
			expect(keys.kelapa):toBe(nil)
			expect(data:find("%d%d%d%d%d%d%d%d%d%d%d%d") == nil):toBe(true)
			expect(applier:find("%d%d%d%d%d%d%d%d%d%d%d%d") == nil):toBe(true)
			expect(applier:find("rbxassetid", 1, true) == nil):toBe(true)
			expect(Data.sourceFamily):toBe("vegetation_r4")
		end)

		t:it("keeps kelapa only in a disabled other-level group and places no pine", function()
			expect(Data.placedKeys().kelapa):toBe(nil)
			expect(Data.ids.kelapa):toBe(nil)
			expect(#Data.otherLevels):toBe(1)
			local other = Data.otherLevels[1]
			expect(other.enabled):toBe(false)
			expect(other.modelKey):toBe("kelapa")
			expect(other.modelId):toBe(r4Ids.kelapa)
			expect(type(other.note)):toBe("string")
			for _, slot in ipairs(slots) do
				expect(slot.slot ~= "kelapa"):toBe(true)
				expect(slot.slot ~= "pine"):toBe(true)
				expect(slot.slot ~= "pinus"):toBe(true)
				expect(type(slot.footprint)):toBe("table")
			end
		end)

		t:it("makes bamboo clumps dense and pisang planted in clusters", function()
			local clumps, clusters = {}, {}
			for _, slot in ipairs(slots) do
				if slot.slot == "bambu" then
					clumps[slot.cluster] = (clumps[slot.cluster] or 0) + 1
				elseif slot.slot == "pisang" then
					clusters[slot.cluster] = (clusters[slot.cluster] or 0) + 1
				end
			end
			local clumpCount = 0
			for _, count in pairs(clumps) do
				expect(count > 1):toBe(true)
				clumpCount += 1
			end
			local clusterCount = 0
			for _, count in pairs(clusters) do
				expect(count > 1):toBe(true)
				clusterCount += 1
			end
			expect(clumpCount):toBe(3)
			expect(clumps.A):toBe(5)
			expect(clusterCount):toBe(3)
			expect(clusters.A):toBe(3)
		end)

		t:it("keeps the mango stand-in and records the Designer-build note", function()
			expect(Data.ids.mangga):toBe(r4Ids.mangga)
			expect(#Data.designerBuilds):toBe(1)
			expect(Data.designerBuilds[1].note:find("Designer build needed", 1, true) ~= nil):toBe(true)
			expect(manifest:find("Designer build needed", 1, true) ~= nil):toBe(true)
			expect(manifest:find("R4 broadleaf stand-in", 1, true) ~= nil):toBe(true)
		end)
	end)

	t:describe("vegetation_r5 exclusion zones", function()
		t:it("rejects path, hub, plot and open-space points and accepts a clear point", function()
			local zones = Data.exclusionZones(MapSpec, { { x = -30, z = 56, halfX = 4, halfZ = 4 } })
			local fp = { halfX = 2, halfZ = 2 }
			expect(Data.pointAllowed(92, 0, fp, zones)):toBe(false) -- east road arm
			expect(Data.pointAllowed(-64, -64, fp, zones)):toBe(false) -- Pasar footprint
			expect(Data.pointAllowed(-30, 56, fp, zones)):toBe(false) -- tagged plot anchor
			expect(Data.pointAllowed(0, 0, fp, zones)):toBe(false) -- plaza kept clear
			expect(Data.pointAllowed(220, 220, fp, zones)):toBe(true)
			expect(Data.pointAllowed(220, 220, { halfX = 1000, halfZ = 1000 }, {
				{ x = 220, z = 220, halfX = 1, halfZ = 1 },
			})):toBe(false)
			expect(Data.pointAllowed(220, 220, fp, {})):toBe(true)
		end)

		t:it("places every static slot clear of paths, plots and hubs", function()
			local zones = Data.exclusionZones(MapSpec, {})
			expect(#zones > 0):toBe(true)
			for _, slot in ipairs(slots) do
				expect(Data.slotAllowed(slot, zones)):toBe(true)
			end
		end)

		t:it("keeps zone construction and margins in the data module", function()
			expect(data:find("exclusionMargins", 1, true) ~= nil):toBe(true)
			expect(applier:find("ModelMapVegetationR5.exclusionZones", 1, true) ~= nil):toBe(true)
			expect(applier:find("ModelMapVegetationR5.slotAllowed", 1, true) ~= nil):toBe(true)
			expect(applier:find("Map.all(Map.TAGS.PlotAnchor)", 1, true) ~= nil):toBe(true)
			expect(applier:find("-64", 1, true) == nil):toBe(true)
		end)
	end)

	t:describe("vegetation_r5 applier registration and lifecycle", function()
		t:it("registers the off-by-default candidate string with apply and restore", function()
			expect(
				applier:find('LookDev.register("vegetation_r5", { apply = apply, restore = restore })', 1, true) ~= nil
			):toBe(true)
			local _, registered = makeApp({})
			expect(type(registered.vegetation_r5)):toBe("table")
			expect(type(registered.vegetation_r5.apply)):toBe("function")
			expect(type(registered.vegetation_r5.restore)):toBe("function")
			expect(registered.vegetation_r4):toBe(nil)
		end)

		t:it("loads only placed models, then destroys the folder and every instance on restore", function()
			local state, registered, workspace = makeApp({})
			registered.vegetation_r5.apply()
			expect(#state.loaded):toBe(#slots)
			expect(#state.folders):toBe(1)
			local folder = state.folders[1]
			expect(folder.Name):toBe(Data.folderName)
			expect(workspace:FindFirstChild(Data.folderName)):toBe(folder)
			local bamboo = 0
			for _, model in ipairs(state.loaded) do
				expect(string.find(model.Name, "kelapa", 1, true) == nil):toBe(true)
				expect(string.find(string.lower(model.Name), "pine", 1, true) == nil):toBe(true)
				expect(model.Name:match("^R5_") ~= nil):toBe(true)
				expect(model.Scale > 0):toBe(true)
				expect(model.Parent):toBe(folder)
				if string.find(model.Name, "_bambu_", 1, true) then
					bamboo += 1
				end
			end
			expect(bamboo > 5):toBe(true)
			registered.vegetation_r5.restore()
			expect(folder.Destroyed):toBe(true)
			for _, model in ipairs(state.loaded) do
				expect(model.Destroyed):toBe(true)
				expect(model.Parent):toBe(nil)
			end
			expect(workspace:FindFirstChild(Data.folderName)):toBe(nil)
		end)

		t:it("skips every slot whose footprint overlaps a tagged plot anchor", function()
			local anchor = {
				IsA = function()
					return true
				end,
				Size = env.Vector3.new(1200, 1, 1200),
				Position = env.Vector3.new(0, 0, 0),
			}
			local state, registered = makeApp({ anchor })
			registered.vegetation_r5.apply()
			expect(#state.loaded):toBe(0)
			expect(#state.folders):toBe(1)
			registered.vegetation_r5.restore()
			expect(state.folders[1].Destroyed):toBe(true)
		end)
	end)
end
