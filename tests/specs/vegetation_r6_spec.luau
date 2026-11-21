--!nocheck
-- WORK_QUEUE section J item 47: vegetation_r6. Pure-data locks plus a fake InsertService/Terrain
-- env that exercises the REAL server applier: allowed-slot loading, staged/tier filtering and exact
-- restore. No Studio, no screenshot, no visual verdict, no place save, no invented asset ID.

local fs = require("@lune/fs")

local DATA_PATH = "src/shared/ModelMapVegetationR6.luau"
local APPLIER_PATH = "src/server/World/LookDevModelsVegetationR6.luau"
local REPORT_PATH = "docs/v2/evidence/h/2026-11-20-r6-vegetation-ids/REPORT.md"
local README_PATH = "docs/v2/visual/art/models_r6/vegetation/README.md"
local CANDIDATES_PATH = "docs/v2/visual/CANDIDATES.md"

local NEW_IDS = {
	kembang_sepatu = 15344074131,
	lidah_mertua = 184362803,
	teh_tehan = 8864962424,
	alang_alang = 361802126,
	bunga = 9639782964,
}
local DESIGNER_BUILDS = { "pepaya", "talas", "singkong", "nangka", "rambutan", "jambu_air" }

local function r5Margins(Env)
	return Env.new():require("shared/ModelMapVegetationR5").exclusionMargins
end

return function(t, Env)
	local expect = t.expect
	local env = Env.new()
	local Data = env:require("shared/ModelMapVegetationR6")
	local R4 = env:require("shared/ModelMapVegetationR4")
	local MapSpec = env:require("server/World/MapSpec")
	local data = fs.readFile(DATA_PATH)
	local applier = fs.readFile(APPLIER_PATH)
	local report = fs.readFile(REPORT_PATH)
	local readme = fs.readFile(README_PATH)
	local candidatesSrc = fs.readFile(CANDIDATES_PATH)
	local mainSrc = fs.readFile("src/server/Main.server.luau")
	local r4Ids = R4.families.vegetation_r4.ids
	local slots = Data.slots()
	local staged = Data.stagedSlots()

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

	-- Fresh Env per case: the applier's active folder/tier state is module-local.
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
		local applierModule = appEnv:require("server/World/LookDevModelsVegetationR6")
		return state, registered, workspace, applierModule
	end

	t:describe("ModelMapVegetationR6 pure data", function()
		t:it("locks the candidate identity and the exact shortlisted IDs", function()
			expect(Data.id):toBe("vegetation_r6")
			expect(Data.folderName):toBe("LookDevVegetationR6")
			for key, id in pairs(NEW_IDS) do
				expect(Data.ids[key]):toBe(id)
				expect(type(id)):toBe("number")
				expect(report:find(tostring(id), 1, true) ~= nil):toBe(true)
				expect(data:find("https://create.roblox.com/store/asset/" .. tostring(id), 1, true) ~= nil):toBe(true)
			end
			for _, key in ipairs({ "pisang", "bambu", "mangga", "shrubs" }) do
				expect(Data.ids[key]):toBe(r4Ids[key])
				expect(data:find(tostring(r4Ids[key]), 1, true)):toBe(nil) -- no R4 literal here
			end
			expect(Data.ids.kelapa):toBe(nil)
			expect(Data.ids.pine):toBe(nil)
			expect(Data.ids.pinus):toBe(nil)
		end)

		t:it("adds no kelapa or pine slots and keeps all designer-build gaps ID-free", function()
			for _, slot in ipairs(slots) do
				for _, banned in ipairs({ "kelapa", "pine", "pinus" }) do
					expect(slot.slot == banned):toBe(false)
				end
				expect(Data.ids[slot.slot] ~= nil):toBe(true)
				expect(type(slot.footprint)):toBe("table")
				expect(type(slot.targetHeight)):toBe("number")
				expect(type(slot.x)):toBe("number")
				expect(type(slot.z)):toBe("number")
				expect(type(slot.ry)):toBe("number")
				expect(type(slot.rotX)):toBe("number")
				expect(type(slot.cluster)):toBe("string")
			end
			expect(#Data.designerBuilds):toBe(#DESIGNER_BUILDS)
			for _, name in ipairs(DESIGNER_BUILDS) do
				local found = false
				for _, build in ipairs(Data.designerBuilds) do
					if build.slot == name then
						found = true
						expect(build.reference):toBe("docs/v2/visual/KAMPUNG_VEGETATION.md")
						expect(Data.ids[name]):toBe(nil)
					end
				end
				expect(found):toBe(true)
			end
		end)

		t:it("makes bamboo clumps dense and stages clusters in the saved camera band", function()
			local clumps = {}
			for _, slot in ipairs(slots) do
				if slot.slot == "bambu" then
					clumps[slot.cluster] = (clumps[slot.cluster] or 0) + 1
				end
			end
			local clumpCount = 0
			for _, count in pairs(clumps) do
				expect(count >= 5):toBe(true)
				clumpCount += 1
			end
			expect(clumpCount):toBe(4)
			expect(#staged):toBe(42)
			for _, slot in ipairs(staged) do
				expect(slot.z >= 88 and slot.z <= 114):toBe(true)
			end
			expect(Data.savedCamera.eye):toEqual({ 0, 20, 150 })
			expect(Data.savedCamera.look):toEqual({ 0, 8, 96 })
		end)

		t:it("mirrors the tier budgets and keeps every cumulative estimate inside them", function()
			expect(Data.budgets.Rendah):toEqual({ instances = 50, triangles = 50000 })
			expect(Data.budgets.Sedang):toEqual({ instances = 100, triangles = 100000 })
			expect(Data.budgets.Tinggi):toEqual({ instances = 150, triangles = 150000 })
			expect(Data.tiers):toEqual({ "Rendah", "Sedang", "Tinggi" })
			expect(Data.tierRank("Rendah")):toBe(1)
			expect(Data.tierRank("nope")):toBe(0)
			local counts, triangles = Data.budgetAudit()
			for _, tier in ipairs(Data.tiers) do
				expect(counts[tier] <= Data.budgets[tier].instances):toBe(true)
				expect(triangles[tier] <= Data.budgets[tier].triangles):toBe(true)
			end
			expect(counts.Rendah):toBe(#staged)
			expect(counts.Sedang):toBe(78)
			expect(counts.Tinggi):toBe(#slots)
			expect(data:find("PLANNING ESTIMATES", 1, true) ~= nil):toBe(true)
		end)

		t:it("delegates exclusions to R5 and keeps every slot clear of static zones", function()
			expect(Data.exclusionMargins):toEqual(r5Margins(Env))
			local zones = Data.exclusionZones(MapSpec, { { x = -30, z = 56, halfX = 4, halfZ = 4 } })
			local fp = { halfX = 2, halfZ = 2 }
			expect(Data.pointAllowed(92, 0, fp, zones)):toBe(false) -- east road arm
			expect(Data.pointAllowed(-64, -64, fp, zones)):toBe(false) -- Pasar hub
			expect(Data.pointAllowed(-30, 56, fp, zones)):toBe(false) -- tagged plot anchor
			expect(Data.pointAllowed(0, 0, fp, zones)):toBe(false) -- plaza
			expect(Data.pointAllowed(220, 220, fp, zones)):toBe(true)
			expect(Data.pointAllowed(220, 220, { halfX = 1000, halfZ = 1000 }, {
				{ x = 220, z = 220, halfX = 1, halfZ = 1 },
			})):toBe(false)
			expect(Data.pointAllowed(220, 220, fp, {})):toBe(true)
			local staticZones = Data.exclusionZones(MapSpec, {})
			expect(#staticZones > 0):toBe(true)
			for _, slot in ipairs(slots) do
				expect(Data.slotAllowed(slot, staticZones)):toBe(true)
			end
			expect(data:find("ModelMapVegetationR5.exclusionZones", 1, true) ~= nil):toBe(true)
			expect(data:find("ModelMapVegetationR5.slotAllowed", 1, true) ~= nil):toBe(true)
		end)
	end)

	t:describe("LookDevModelsVegetationR6 applier", function()
		t:it("registers the candidate with no ID literal and pcall-guarded engine calls", function()
			expect(
				applier:find('LookDev.register("vegetation_r6", { apply = apply, restore = restore })', 1, true) ~= nil
			):toBe(true)
			expect(applier:find("%d%d%d%d%d%d%d")):toBe(nil)
			expect(applier:find("rbxassetid", 1, true)):toBe(nil)
			expect(applier:find("assetId", 1, true)):toBe(nil)
			local _, calls = string.gsub(applier, "pcall%(", "")
			expect(calls >= 12):toBe(true)
			expect(applier:find("InsertService:LoadAsset", 1, true) ~= nil):toBe(true)
			expect(applier:find("ModelMapVegetationR6.exclusionZones", 1, true) ~= nil):toBe(true)
			expect(applier:find("ModelMapVegetationR6.slotAllowed", 1, true) ~= nil):toBe(true)
			expect(applier:find("Map.all(Map.TAGS.PlotAnchor)", 1, true) ~= nil):toBe(true)
			expect(applier:find("CFrame.Angles(slot.rotX or 0, slot.ry, 0)", 1, true) ~= nil):toBe(true)
			expect(applier:find("model:ScaleTo(slot.targetHeight / bodyY)", 1, true) ~= nil):toBe(true)
			local _, registered = makeApp({})
			expect(type(registered.vegetation_r6)):toBe("table")
			expect(type(registered.vegetation_r6.apply)):toBe("function")
			expect(type(registered.vegetation_r6.restore)):toBe("function")
			expect(registered.vegetation_r4):toBe(nil)
		end)

		t:it("loads only the staged Rendah slots by default, then restores exactly", function()
			local state, registered, workspace = makeApp({})
			registered.vegetation_r6.apply()
			expect(#state.loaded):toBe(#staged)
			expect(#state.folders):toBe(1)
			local folder = state.folders[1]
			expect(folder.Name):toBe(Data.folderName)
			expect(workspace:FindFirstChild(Data.folderName)):toBe(folder)
			for _, model in ipairs(state.loaded) do
				expect(model.Name:match("^R6_") ~= nil):toBe(true)
				expect(model.Scale > 0):toBe(true)
				expect(model.Parent):toBe(folder)
				expect(model.PlacedAt ~= nil):toBe(true)
			end
			registered.vegetation_r6.restore()
			expect(folder.Destroyed):toBe(true)
			for _, model in ipairs(state.loaded) do
				expect(model.Destroyed):toBe(true)
				expect(model.Parent):toBe(nil)
			end
			expect(workspace:FindFirstChild(Data.folderName)):toBe(nil)
			expect(pcall(registered.vegetation_r6.restore)):toBe(true)
		end)

		t:it("honours setTier and setIncludeUnstaged without loading above budget", function()
			local state, registered, workspace, module = makeApp({})
			local applier = registered.vegetation_r6
			expect(module.setTier("nope")):toBe("Rendah")
			expect(module.setTier("Sedang")):toBe("Sedang")
			applier.apply()
			expect(#state.loaded):toBe(#staged) -- staged-only filter still wins
			applier.restore()
			state.loaded = {}
			expect(workspace:FindFirstChild(Data.folderName)):toBe(nil)

			expect(module.setIncludeUnstaged(true)):toBe(true)
			applier.apply()
			expect(#state.loaded):toBe(78)
			applier.restore()
			state.loaded = {}
			expect(module.setTier("Tinggi")):toBe("Tinggi")
			applier.apply()
			expect(#state.loaded):toBe(#slots)
			expect(#state.loaded <= Data.budgets.Tinggi.instances):toBe(true)
			applier.restore()
			state.loaded = {}
			expect(module.setIncludeUnstaged(false)):toBe(false)
			applier.apply()
			expect(#state.loaded):toBe(#staged)
			applier.restore()
		end)

		t:it("skips every slot whose footprint overlaps a tagged plot anchor", function()
			local anchor = {
				IsA = function()
					return true
				end,
				Size = env.Vector3.new(1200, 1, 1200),
				Position = env.Vector3.new(0, 0, 0),
			}
			local state, registered, workspace = makeApp({ anchor })
			registered.vegetation_r6.apply()
			expect(#state.loaded):toBe(0)
			expect(#state.folders):toBe(1)
			registered.vegetation_r6.restore()
			expect(state.folders[1].Destroyed):toBe(true)
			expect(workspace:FindFirstChild(Data.folderName)):toBe(nil)
		end)

		t:it("reattaches a pre-existing folder on restore", function()
			local state, registered, workspace = makeApp({})
			local prior = { Name = Data.folderName, Parent = workspace, Destroyed = false }
			setmetatable(prior, {
				__newindex = function(node, key, value)
					rawset(node, key, value)
					if key == "Parent" and type(value) == "table" and value._children then
						value._children[node.Name] = node
					end
				end,
			})
			workspace._children[Data.folderName] = prior
			registered.vegetation_r6.apply()
			expect(prior.Parent):toBe(nil)
			expect(state.folders[1] ~= prior):toBe(true)
			registered.vegetation_r6.restore()
			expect(prior.Parent):toBe(workspace)
			expect(prior.Destroyed):toBe(false)
			expect(workspace:FindFirstChild(Data.folderName)):toBe(prior)
		end)
	end)

	t:describe("round-6 vegetation registry, review and handoff", function()
		t:it("reaches 57 candidates with the server review path and plan", function()
			local LookDev = Env.new():require("shared/LookDev")
			local Review = Env.new():require("shared/LookDevReview")
			expect(#LookDev.IDS):toBe(60)
			expect(LookDev.IDS[41]):toBe("vegetation_r6")
			expect(LookDev.isCandidate("vegetation_r6")):toBe(true)
			expect(LookDev.candidates.vegetation_r6.status):toBe("candidate, awaiting designer yes")
			local plan = LookDev.plan("vegetation_r6")
			expect(plan.id):toBe("vegetation_r6")
			expect(plan.idsSource):toBe("Shared.ModelMapVegetationR6")
			expect(plan.render):toBe(README_PATH)
			local entry = Review.pathsFor("vegetation_r6")
			expect(entry.datamodel):toBe("server")
			expect(entry.path):toEqual({ "World", "LookDevModelsVegetationR6" })
			expect(mainSrc:find("pcall(require, script.Parent.World.LookDevModelsVegetationR6)", 1, true) ~= nil):toBe(
				true
			)
			expect(applier:find("pcall(require, script.Parent.World.LookDevModelsVegetationR6)", 1, true)):toBe(nil)
		end)

		t:it("keeps the CANDIDATES verdict blank and documents the handoff", function()
			local row
			for line in string.gmatch(candidatesSrc, "[^\n]+") do
				if string.find(line, "| `vegetation_r6` |", 1, true) then
					row = line
				end
			end
			expect(type(row)):toBe("string")
			expect(string.sub(row, -4) == "|  |" or string.find(row, "| %*%*[yn][eo]") ~= nil):toBe(true) -- verdict blank or a designer verdict
			for _, id in pairs(NEW_IDS) do
				expect(readme:find(tostring(id), 1, true) ~= nil):toBe(true)
				expect(readme:find("https://create.roblox.com/store/asset/" .. tostring(id), 1, true) ~= nil):toBe(true)
			end
			expect(readme:find("docs/v2/visual/art/models_r4/vegetation/upload_manifest.json", 1, true) ~= nil):toBe(
				true
			)
			expect(readme:find("docs/v2/evidence/h/2026-11-20-r6-vegetation-ids/REPORT.md", 1, true) ~= nil):toBe(true)
			expect(readme:find("docs/v2/visual/KAMPUNG_VEGETATION.md", 1, true) ~= nil):toBe(true)
			expect(readme:find('LookDev.enable("vegetation_r6")', 1, true) ~= nil):toBe(true)
			expect(readme:find("Server", 1, true) ~= nil):toBe(true)
			expect(readme:find("{ 0, 20, 150 }", 1, true) ~= nil):toBe(true)
			expect(readme:find("{ 0, 8, 96 }", 1, true) ~= nil):toBe(true)
			expect(readme:find("MAIN SESSION", 1, true) ~= nil):toBe(true)
			expect(readme:find("No screenshot was captured or graded", 1, true) ~= nil):toBe(true)
			expect(readme:find("blank", 1, true) ~= nil):toBe(true)
			expect(readme:find("Designer-build gaps", 1, true) ~= nil):toBe(true)
			for _, name in ipairs(DESIGNER_BUILDS) do
				expect(readme:find(name, 1, true) ~= nil):toBe(true)
			end
			expect(readme:find("30,400", 1, true) ~= nil):toBe(true)
			expect(readme:find("58,200", 1, true) ~= nil):toBe(true)
			expect(readme:find("78,200", 1, true) ~= nil):toBe(true)
		end)
	end)
end
