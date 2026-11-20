--!nocheck
-- WORK_QUEUE item 50: props_r6. Data + applier source checks plus a fake InsertService mount that
-- runs the real applier under the Env harness: a known-size box is measured with GetBoundingBox,
-- scaled with ScaleTo(target/bodyY), then re-measured and compared with the R6 targets. No Studio,
-- screenshot or visual verdict here. Main session wires the registry and tests/run.luau.

local fs = require("@lune/fs")

local DATA_PATH = "src/shared/ModelMapPropsR6.luau"
local APPLIER_PATH = "src/server/World/LookDevModelsPropsR6.luau"

return function(t, Env)
	local expect = t.expect
	local env = Env.new()
	local R4 = env:require("shared/ModelMapPropsR4")
	local R5 = env:require("shared/ModelMapPropsR5")
	local R6 = env:require("shared/ModelMapPropsR6")
	local family = R6.families[R6.familyId]
	local data = fs.readFile(DATA_PATH)
	local applier = fs.readFile(APPLIER_PATH)

	local r4ids = R4.idsFor("props_r4")
	local r5slots = {}
	for _, slot in ipairs(R5.families.props_r5.slots) do
		r5slots[slot.slot] = slot
	end

	local function findSlot(name)
		for _, slot in ipairs(family.slots) do
			if slot.slot == name then
				return slot
			end
		end
		return nil
	end

	local function hasLongId(text)
		return string.match(text, "%d%d%d%d%d%d%d%d%d%d%d%d") ~= nil
	end

	local function closeTo(value, target)
		return type(value) == "number" and math.abs(value - target) < 1e-9
	end

	-- A 2x3x2 stud box (gerobak: 2x3x4 so its length scales to the 8-stud target). GetBoundingBox
	-- reports the base size before ScaleTo and the multiplied size afterwards, so the spec reads
	-- the actual post-ScaleTo dimensions instead of trusting the scale factor.
	local function newModel(appEnv, id)
		local base = if id == family.ids.gerobak then { X = 2, Y = 3, Z = 4 } else { X = 2, Y = 3, Z = 2 }
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
			ScaleFactor = 1,
			ScaleCalls = 0,
			GetBoundingBox = function(self)
				local factor = self.ScaleFactor or 1
				return { Y = 0 }, appEnv.Vector3.new(base.X * factor, base.Y * factor, base.Z * factor)
			end,
			ScaleTo = function(self, factor)
				self.ScaleFactor = factor
				self.ScaleCalls += 1
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
	local function makeApp()
		local appEnv = Env.new()
		local state = { loaded = {}, folders = {} }
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
				return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, cframeMeta)
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
		local api = appEnv:require("server/World/LookDevModelsPropsR6")
		return state, registered, workspace, api
	end

	t:describe("props_r6 data provenance", function()
		t:it("registers props_r6 and reuses every real R4 ID with no literals", function()
			expect(string.find(applier, 'LookDev.register("props_r6"', 1, true) ~= nil):toBe(true)
			expect(R6.familyId):toBe("props_r6")
			expect(family.id):toBe("props_r6")
			expect(#R6.familyIds()):toBe(1)
			expect(R6.familyIds()[1]):toBe("props_r6")
			expect(hasLongId(data)):toBe(false)
			expect(hasLongId(applier)):toBe(false)
			local count = 0
			for slot, id in pairs(family.ids) do
				count += 1
				expect(r4ids[slot]):toBe(id)
			end
			expect(count):toBe(7)
			expect(R6.count()):toBe(7)
			expect(R6.idsFor("props_r6")):toBe(family.ids)
			expect(R6.idsFor("not_a_family")):toBe(nil)
		end)

		t:it("stays pure data", function()
			expect(string.find(data, "GetService", 1, true)):toBe(nil)
			expect(string.find(data, "Instance.new", 1, true)):toBe(nil)
			expect(R6.groundY):toBe(R4.groundY)
			expect(R6.PLAYER_HEIGHT):toBe(5)
		end)
	end)

	t:describe("props_r6 real-size scales and targets", function()
		t:it("restores gerobak, sumur and cangkul to their target heights", function()
			local expected = { gerobak = 6, sumur = 4.5, alat_tani = 4.5 }
			local scales = { gerobak = 1, sumur = 0.9, alat_tani = 1.5 }
			for slotName, height in pairs(expected) do
				local entry = findSlot(slotName)
				expect(entry ~= nil):toBe(true)
				expect(entry.scale):toBe(scales[slotName])
				expect(closeTo(R6.effectiveHeight(entry), height)):toBe(true)
				expect(closeTo(R6.targets[slotName].height, height)):toBe(true)
			end
			-- The queue calls the hand tool "cangkul"; it reuses R4's alat_tani ID, no new key.
			expect(family.ids.cangkul):toBe(nil)
			expect(family.ids.alat_tani):toBe(r4ids.alat_tani)
			expect(findSlot("cangkul")):toBe(nil)
		end)

		t:it("keeps jemuran and the other R5 props at their R5 scales", function()
			expect(findSlot("jemuran").scale):toBe(1)
			expect(R6.effectiveHeight(findSlot("jemuran"))):toBe(7)
			expect(R6.targets.jemuran.height):toBe(7)
			for _, slotName in ipairs({ "lapak", "pagar_bambu" }) do
				expect(findSlot(slotName).scale):toBe(r5slots[slotName].scale)
			end
			expect(family.karung.scale):toBe(R5.families.props_r5.karung.scale)
			expect(closeTo(R6.effectiveHeight(findSlot("lapak")), 4.8)):toBe(true)
		end)

		t:it("records the gerobak 6-tall / 8-long planning target", function()
			expect(R6.targets.gerobak.height):toBe(6)
			expect(R6.targets.gerobak.length):toBe(8)
			expect(closeTo(R6.effectiveHeight(findSlot("gerobak")), R6.targets.gerobak.height)):toBe(true)
		end)

		t:it("moves the saved camera out from behind the pines", function()
			expect(R6.camera.position.x):toBe(154)
			expect(R6.camera.position.y):toBe(10)
			expect(R6.camera.position.z):toBe(140)
			expect(R6.camera.position.x ~= R4.camera.position.x):toBe(true)
			expect(R6.camera.target.x):toBe(R4.camera.target.x)
			expect(R6.camera.target.z):toBe(R4.camera.target.z)
			expect(string.find(data, "pine", 1, true) ~= nil):toBe(true)
		end)

		t:it("reuses the R5 gudang karung group verbatim", function()
			local r5karung = R5.families.props_r5.karung
			expect(family.karung.x):toBe(r5karung.x)
			expect(family.karung.z):toBe(r5karung.z)
			expect(family.karung.context):toBe(r5karung.context)
			expect(family.karung.note):toBe(r5karung.note)
			expect(#family.karung.stack):toBe(#r5karung.stack)
		end)
	end)

	t:describe("props_r6 applier guards and lifecycle", function()
		t:it("pcall-guards engine calls, carries no ID literal and registers props_r6", function()
			expect(string.find(applier, 'service("InsertService")', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "local id = familyMap.ids[entry.slot]", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, 'if type(id) ~= "number"', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "InsertService:LoadAsset(id)", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, 'Instance.new("Folder")', 1, true) ~= nil):toBe(true)
			local _, calls = string.gsub(applier, "pcall%(", "")
			expect(calls >= 15):toBe(true)
			expect(hasLongId(applier)):toBe(false)
			local _, registered = makeApp()
			expect(type(registered.props_r6)):toBe("table")
			expect(type(registered.props_r6.apply)):toBe("function")
			expect(type(registered.props_r6.restore)):toBe("function")
			expect(registered.props_r5):toBe(nil)
		end)

		t:it("scales with ScaleTo, anchors collision and detaches/restores the prior folder", function()
			expect(string.find(applier, "ModelMapPropsR6.effectiveHeight(entry)", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "model:ScaleTo(target / bodySizeY)", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "model:GetBoundingBox()", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "LookDevModelsPropsR6._measure = measure", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "karungEntries(familyMap.karung)", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "entry.yOffset or 0", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "CFrame.Angles(entry.rotX or 0, entry.ry, 0)", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "descendant.Anchored = true", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "descendant.CanCollide = false", 1, true) ~= nil):toBe(true)
			local marker = "restore = function()"
			local start = string.find(applier, marker, 1, true)
			expect(start ~= nil):toBe(true)
			local restoreBody = string.sub(applier, start + #marker)
			expect(string.find(applier, "local function clearActive()", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "folder:Destroy()", 1, true) ~= nil):toBe(true)
			expect(string.find(restoreBody, "clearActive()", 1, true) ~= nil):toBe(true)
			expect(string.find(restoreBody, "previous.Parent = Workspace", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "previous.Parent = nil", 1, true) ~= nil):toBe(true)
		end)
	end)

	t:describe("props_r6 bounding-box sizes from the real applier", function()
		t:it("measures the mounted box, scales it, then reads the target height back", function()
			local state, registered, workspace, api = makeApp()
			registered.props_r6.apply()
			expect(#state.loaded):toBe(10) -- six R5 slots plus four stacked sacks
			expect(#state.folders):toBe(1)
			expect(type(api._measure)):toBe("function")
			expect(type(api._measuredBox)):toBe("function")

			local bySlot = {}
			for _, model in ipairs(state.loaded) do
				expect(model.Name:match("^R6_") ~= nil):toBe(true)
				expect(model.ScaleCalls):toBe(1)
				expect(model.Parent):toBe(state.folders[1])
				local slotName = string.match(model.Name, "^R6_(.-)_%d+$")
				expect(slotName ~= nil):toBe(true)
				bySlot[slotName] = model
			end

			for _, slotName in ipairs({ "gerobak", "sumur", "alat_tani", "jemuran" }) do
				local model = bySlot[slotName]
				expect(model ~= nil):toBe(true)
				local entry = findSlot(slotName)
				local target = R6.effectiveHeight(entry)
				-- Loaded body Y is 3: prove ScaleTo was called with target / 3.
				expect(closeTo(model.ScaleFactor, target / 3)):toBe(true)
				local _, measuredY = api._measure(model)
				expect(closeTo(measuredY, target)):toBe(true)
				local size = api._measuredBox(model)
				expect(closeTo(size.Y, target)):toBe(true)
				expect(closeTo(size.Y, R6.targets[slotName].height)):toBe(true)
			end
			-- The gerobak box was mounted 4 studs long: after the 2x scale it reads the 8-stud target.
			expect(closeTo(api._measuredBox(bySlot.gerobak).Z, R6.targets.gerobak.length)):toBe(true)

			registered.props_r6.restore()
			expect(state.folders[1].Destroyed):toBe(true)
			for _, model in ipairs(state.loaded) do
				expect(model.Destroyed):toBe(true)
				expect(model.Parent):toBe(nil)
			end
			expect(workspace:FindFirstChild("LookDevModelsPropsR6_props_r6")):toBe(nil)
		end)
	end)
end
