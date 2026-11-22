--!nocheck
-- WORK_QUEUE item 48 (npcs_r6): role-specific textured R15 villagers. The data and
-- the real server applier are exercised under the Env harness with fake
-- InsertService / Players / Instance / CFrame, so no Studio, screenshot or visual
-- grade is involved. Main session wires this file into tests/run.luau after item 47.

local fs = require("@lune/fs")

local DATA_PATH = "src/shared/ModelMapNpcsR6.luau"
local R5_PATH = "src/shared/ModelMapNpcsR5.luau"
local APPLIER_PATH = "src/server/World/LookDevModelsNpcsR6.luau"
local MANIFEST_PATH = "docs/v2/visual/art/models_r6/npcs/upload_manifest.json"
local ROLE_IDS = { "polisi", "pak_rt", "petani", "pedagang", "petani_wanita" }

local function contains(text, needle)
	return string.find(text, needle, 1, true) ~= nil
end

local function longDigitRuns(text)
	local found = {}
	for value in string.gmatch(text, "%d+") do
		if #value >= 11 then
			found[value] = true
		end
	end
	return found
end

return function(t, Env)
	local expect = t.expect
	local env = Env.new()
	local Data = env:require("shared/ModelMapNpcsR6")
	local R5 = env:require("shared/ModelMapNpcsR5")
	local r5Family = R5.families.npcs_r5
	local manifest = fs.readFile(MANIFEST_PATH)
	local data = fs.readFile(DATA_PATH)
	local r5Source = fs.readFile(R5_PATH)
	local applier = fs.readFile(APPLIER_PATH)

	-- One fresh fake DataModel per case: the applier holds module-local folder state.
	local function makeApp(opts)
		opts = opts or {}
		local appEnv = Env.new()
		local state = {
			created = {},
			folders = {},
			rigs = {},
			heads = {},
			humanoids = {},
			descriptions = {},
			loaded = {},
			fallbackParts = {},
			addedAccessories = {},
			syncCalls = 0,
		}

		local cframeMeta = {}
		cframeMeta.__mul = function(a, b)
			return setmetatable({
				X = (a.X or 0) + (b.X or 0),
				Y = (a.Y or 0) + (b.Y or 0),
				Z = (a.Z or 0) + (b.Z or 0),
				angleY = b.angleY or a.angleY,
			}, cframeMeta)
		end
		local CFrame = {
			new = function(x, y, z)
				return setmetatable({ X = x, Y = y, Z = z }, cframeMeta)
			end,
			Angles = function(x, y, z)
				return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0, angleY = y or 0 }, cframeMeta)
			end,
		}
		appEnv.globals.CFrame = CFrame

		local function newNode(className, name)
			local node = {
				ClassName = className,
				Name = name or className,
				_parent = nil,
				_children = {},
				Destroyed = false,
			}
			function node:IsA(kind)
				if kind == "BasePart" then
					return self.ClassName == "Part" or self.ClassName == "BasePart"
				end
				return self.ClassName == kind
			end
			function node:GetChildren()
				return table.clone(self._children)
			end
			function node:GetDescendants()
				local out = {}
				local function walk(current)
					for _, child in pairs(current._children) do
						table.insert(out, child)
						walk(child)
					end
				end
				walk(self)
				return out
			end
			function node:FindFirstChild(childName)
				return self._children[childName]
			end
			function node:FindFirstChildOfClass(kind)
				for _, child in pairs(self._children) do
					if child.ClassName == kind then
						return child
					end
				end
				return nil
			end
			function node:GetBoundingBox()
				return { Y = 4 }, appEnv.Vector3.new(2, 4, 2), appEnv.Vector3.new(0, 0, 0)
			end
			function node:GetPivot()
				return { Y = 0 }
			end
			function node:PivotTo(target)
				self.PlacedAt = target
			end
			function node:SetPrimaryPartCFrame(target)
				self.PlacedAt = target
			end
			function node:Destroy()
				self.Destroyed = true
				self.Parent = nil
			end
			setmetatable(node, {
				__index = function(inst, key)
					if key == "Parent" then
						return rawget(inst, "_parent")
					end
					return nil
				end,
				__newindex = function(inst, key, value)
					if key == "Parent" then
						local old = rawget(inst, "_parent")
						if old ~= value then
							if old and old._children then
								old._children[rawget(inst, "Name")] = nil
							end
							if value and value._children then
								value._children[rawget(inst, "Name")] = inst
							end
							rawset(inst, "_parent", value)
						end
						return
					end
					rawset(inst, key, value)
				end,
			})
			return node
		end

		appEnv.globals.Instance = {
			new = function(className)
				local inst = newNode(className)
				table.insert(state.created, inst)
				if className == "Folder" then
					table.insert(state.folders, inst)
				end
				return inst
			end,
		}

		local workspace = newNode("Workspace", "Workspace")
		appEnv.services.Workspace = workspace

		local players = appEnv.services.Players
		players.CreateHumanoidModelFromDescriptionAsync = function(_, hd, rigType)
			table.insert(state.descriptions, { hd = hd, rigType = rigType })
			local rig = newNode("Model", "Rig")
			table.insert(state.rigs, rig)
			local humanoid = newNode("Humanoid", "Humanoid")
			humanoid.Parent = rig
			function humanoid:AddAccessory(accessory)
				table.insert(state.addedAccessories, accessory)
				accessory.Parent = rig
			end
			table.insert(state.humanoids, humanoid)
			local head = newNode("Part", "Head")
			head.Parent = rig
			head.CFrame = CFrame.new()
			table.insert(state.heads, head)
			local torso = newNode("Part", "Torso")
			torso.Parent = rig
			return rig
		end
		players.CreateHumanoidModelFromDescription = function()
			state.syncCalls += 1
			error("deprecated synchronous create must not be the primary path")
		end

		appEnv.services.InsertService = {
			LoadAsset = function(_, id)
				table.insert(state.loaded, id)
				if opts.failHats then
					error("bad hat id")
				end
				if id == Data.hats.polisi_cap.id then
					local model = newNode("Model", "PoliceHatModel")
					local accessory = newNode("Accessory", "PoliceCap")
					accessory.Parent = model
					return model
				end
				if id == Data.hats.caping.id then
					local model = newNode("Model", "CapingModel")
					local part = newNode("Part", "CapingPart")
					part.Size = appEnv.Vector3.new(2, 0.6, 2)
					part.CFrame = CFrame.new()
					part.Parent = model
					table.insert(state.fallbackParts, part)
					return model
				end
				error("unexpected hat id " .. tostring(id))
			end,
		}

		local registered = {}
		appEnv:mock("shared/LookDev", {
			register = function(id, applierTable)
				registered[id] = applierTable
			end,
		})
		appEnv:require("server/World/LookDevModelsNpcsR6")
		return state, registered, workspace, appEnv
	end

	t:describe("npcs_r6 pure data", function()
		t:it("uses exactly the ten verified Image IDs from the upload manifest, once each", function()
			expect(Data.costumeSource):toBe("models_r6/npcs/upload_manifest.json")
			expect(contains(data, "docs/v2/visual/art/models_r6/npcs/upload_manifest.json")):toBe(true)
			local ids = {}
			for _, roleId in ipairs(ROLE_IDS) do
				local role = Data.roles[roleId]
				for _, kind in ipairs({ "shirt", "pants" }) do
					local id = tostring(role[kind .. "Id"])
					expect(contains(manifest, '"code": "' .. kind .. "_" .. roleId .. '"')):toBe(true)
					expect(contains(manifest, '"asset_id": "' .. id .. '"')):toBe(true)
					table.insert(ids, id)
				end
			end
			expect(#ids):toBe(10)
			local seen = {}
			for _, id in ipairs(ids) do
				expect(seen[id]):toBe(nil)
				seen[id] = true
			end
			local manifestIds = 0
			for _ in string.gmatch(manifest, '"asset_id"%s*:') do
				manifestIds += 1
			end
			expect(manifestIds):toBe(10)
			expect(Data.roles.polisi.shirtId):toBe(113212316103784)
			expect(Data.roles.polisi.pantsId):toBe(98102154190902)
			expect(Data.roles.pak_rt.shirtId):toBe(117485364703264)
			expect(Data.roles.pak_rt.pantsId):toBe(127593796770640)
			expect(Data.roles.petani.shirtId):toBe(112086829394587)
			expect(Data.roles.petani.pantsId):toBe(130876277340560)
			expect(Data.roles.pedagang.shirtId):toBe(71100897124673)
			expect(Data.roles.pedagang.pantsId):toBe(139244403929211)
			expect(Data.roles.petani_wanita.shirtId):toBe(105653588811968)
			expect(Data.roles.petani_wanita.pantsId):toBe(76370296974052)
		end)

		t:it("has exactly the five expected roles and reuses R5 body colours", function()
			expect(Data.familyId):toBe("npcs_r6")
			local count = 0
			for roleId, role in pairs(Data.roles) do
				expect(contains(table.concat(ROLE_IDS, ","), roleId)):toBe(true)
				expect(role.id):toBe(roleId)
				local source = r5Family.roles[role.sourceRole]
				expect(source ~= nil):toBe(true)
				for _, field in ipairs({ "skin", "shirt", "pants" }) do
					expect(role[field]).toEqual(source[field])
				end
				count += 1
			end
			expect(count):toBe(5)
			expect(Data.roles.pak_rt.sourceRole):toBe("tukang_peci")
			expect(contains(r5Source, "tukang_peci")):toBe(true)
		end)

		t:it("reuses only real R5 hat IDs and records the missing peci as a designer build", function()
			expect(Data.roles.polisi.hat):toBe("polisi_cap")
			expect(Data.roles.petani.hat):toBe("caping")
			expect(Data.roles.petani_wanita.hat):toBe("caping")
			expect(Data.roles.pak_rt.hat):toBeNil()
			expect(Data.roles.pedagang.hat):toBeNil()
			expect(Data.hats.polisi_cap.id):toBe(R5.accessories.polisi_cap.id)
			expect(Data.hats.caping.id):toBe(R5.accessories.caping.id)
			expect(Data.hats.pecik):toBeNil()
			expect(type(Data.designerBuilds.note)):toBe("string")
			expect(contains(string.lower(Data.designerBuilds.note), "peci")):toBe(true)
			expect(contains(string.lower(Data.designerBuilds.note), "no caping substitute")):toBe(true)
			expect(Data.designerBuilds.roles):toEqual({ "pak_rt" })
		end)

		t:it("flips every slot to face the saved camera and keeps the R5 camera", function()
			expect(#Data.families.npcs_r6.slots):toBe(5)
			for index, slot in ipairs(Data.families.npcs_r6.slots) do
				expect(slot.ry):toBeGreaterThan(math.pi - 0.1)
				expect(slot.ry):toBeLessThan(math.pi + 0.1)
				expect(slot.ry).never:toBe(0)
				expect(slot.ry).never:toBe(r5Family.slots[index].ry)
				expect(slot.y):toBe(R5.groundY)
				expect(slot.z):toBe(8)
			end
			expect(Data.savedCamera.position).toEqual({ 0, 7, 28 })
			expect(Data.savedCamera.look).toEqual({ 0, 2.5, 8 })
			expect(Data.savedCamera.position).toEqual(r5Family.camera.position)
			expect(Data.savedCamera.look).toEqual(r5Family.camera.lookAt)
		end)

		t:it("stays pure data with no engine APIs in the map itself", function()
			for _, api in ipairs({ "GetService", "Instance.new", "Color3", "Vector3", "CFrame", "rbxassetid" }) do
				expect(contains(data, api)):toBe(false)
			end
		end)
	end)

	t:describe("npcs_r6 applier source guards", function()
		t:it("registers the candidate at module load and exports apply/restore", function()
			expect(contains(applier, 'LookDev.register("npcs_r6", { apply = apply, restore = restore })')):toBe(true)
			expect(contains(applier, "LookDevModelsNpcsR6.apply = apply")):toBe(true)
			expect(contains(applier, "LookDevModelsNpcsR6.restore = restore")):toBe(true)
			expect(contains(applier, "return LookDevModelsNpcsR6")):toBe(true)
		end)

		t:it("has no long asset-ID literal and pcall-guards every engine path", function()
			expect(longDigitRuns(applier)).toEqual({})
			expect(string.find(applier, "%d%d%d%d%d%d%d%d%d%d%d") == nil):toBe(true)
			local calls = 0
			for _ in string.gmatch(applier, "pcall%(") do
				calls += 1
			end
			expect(calls):toBeGreaterThan(20)
			for _, guarded in ipairs({
				"CreateHumanoidModelFromDescriptionAsync",
				"CreateHumanoidModelFromDescription",
				"LoadAsset(hat.id)",
				"humanoid:AddAccessory(accessory)",
				"shirt.ShirtTemplate",
				"pants.PantsTemplate",
				'rig:FindFirstChild("Head")',
				"model:PivotTo(target)",
			}) do
				expect(contains(applier, guarded)):toBe(true)
			end
			expect(contains(applier, "HatAccessory")):toBe(false)
			expect(contains(applier, "ShirtAssetIds")):toBe(false)
			expect(contains(applier, "PantsAssetIds")):toBe(false)
			expect(contains(applier, 'rbxassetid://" .. Data.')):toBe(false)
		end)
	end)

	t:describe("npcs_r6 real applier under a fake DataModel", function()
		t:it("creates textured Shirt/Pants siblings, attaches hats both ways and faces the camera", function()
			local state, registered, workspace = makeApp()
			expect(type(registered.npcs_r6)):toBe("table")
			expect(type(registered.npcs_r6.apply)):toBe("function")
			expect(type(registered.npcs_r6.restore)):toBe("function")
			expect(registered.npcs_r5):toBeNil()

			registered.npcs_r6.apply()
			expect(#state.rigs):toBe(5)
			expect(#state.descriptions):toBe(5)
			expect(state.syncCalls):toBe(0)
			expect(#state.folders):toBe(1)
			expect(state.folders[1].Parent):toBe(workspace)

			local shirts, pants = {}, {}
			for _, inst in ipairs(state.created) do
				if inst.ClassName == "Shirt" then
					table.insert(shirts, inst)
				elseif inst.ClassName == "Pants" then
					table.insert(pants, inst)
				end
			end
			expect(#shirts):toBe(5)
			expect(#pants):toBe(5)
			for index, slot in ipairs(Data.families.npcs_r6.slots) do
				local role = Data.roles[slot.slot]
				local humanoid = state.humanoids[index]
				local shirt, pantsForRole = shirts[index], pants[index]
				expect(shirt.Parent):toBe(humanoid.Parent)
				expect(pantsForRole.Parent):toBe(humanoid.Parent)
				expect(shirt.ShirtTemplate):toBe("rbxassetid://" .. role.shirtId)
				expect(pantsForRole.PantsTemplate):toBe("rbxassetid://" .. role.pantsId)
				expect(state.rigs[index].PlacedAt.angleY):toBeNear(slot.ry, 0.000001)
				expect(state.heads[index].Parent):toBe(state.rigs[index])
			end

			-- polisi carries a real Accessory; both caping hats hit the BasePart fallback.
			expect(#state.addedAccessories):toBe(1)
			expect(state.addedAccessories[1].Name):toBe("PoliceCap")
			expect(#state.fallbackParts):toBe(2)
			expect(state.fallbackParts[1].Parent):toBe(state.heads[1])
			expect(state.fallbackParts[2].Parent):toBe(state.heads[3])
			expect(#state.loaded):toBe(3)

			registered.npcs_r6.restore()
			expect(state.folders[1].Destroyed):toBe(true)
			expect(workspace:FindFirstChild(state.folders[1].Name)):toBeNil()
		end)

		t:it("detaches a pre-existing folder and restores that exact folder on disable", function()
			local state, registered, workspace, appEnv = makeApp()
			local previous = appEnv.globals.Instance.new("Folder")
			previous.Name = "LookDevModelsNpcsR6_npcs_r6"
			previous.Parent = workspace
			expect(workspace:FindFirstChild(previous.Name)):toBe(previous)

			registered.npcs_r6.apply()
			expect(previous.Parent):toBeNil()
			local active = state.folders[#state.folders]
			expect(active).never:toBe(previous)
			expect(workspace:FindFirstChild(previous.Name)):toBe(active)

			registered.npcs_r6.restore()
			expect(active.Destroyed):toBe(true)
			expect(previous.Destroyed):toBe(false)
			expect(previous.Parent):toBe(workspace)
			expect(workspace:FindFirstChild(previous.Name)):toBe(previous)
		end)

		t:it("keeps all five rigs staged when a hat load fails", function()
			local state, registered, _, appEnv = makeApp({ failHats = true })
			expect(function()
				registered.npcs_r6.apply()
			end).never:toThrow()
			expect(#state.rigs):toBe(5)
			expect(#state.fallbackParts):toBe(0)
			expect(#state.addedAccessories):toBe(0)
			expect(#state.loaded):toBe(3)
			expect(contains(table.concat(appEnv.warnings, "\n"), "hat LoadAsset failed")):toBe(true)
		end)
	end)
end
