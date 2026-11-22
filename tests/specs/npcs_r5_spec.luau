--!nocheck
-- WORK_QUEUE item 40 (npcs_r5): solid Roblox R15 villagers. The applier needs Roblox
-- APIs, so it is checked as source text; the shared data module is pure and is checked
-- at runtime under the Env harness. No Studio claim, no visual verdict, no screenshot.

local fs = require("@lune/fs")

local DATA_PATH = "src/shared/ModelMapNpcsR5.luau"
local ADAPTER_PATH = "src/server/World/LookDevModelsNpcsR5.luau"
local MANIFEST_PATH = "docs/v2/visual/art/models_r5/npcs/MANIFEST.md"

local REAL_IDS = {
	["71002247087415"] = true,
	["14769019514"] = true,
	["126970096704856"] = true,
}

local ROLE_IDS = { "petani", "pedagang", "petani_wanita", "tukang_peci", "polisi" }

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
	local R5 = env:require("shared/ModelMapNpcsR5")
	local family = R5.families.npcs_r5
	local data = fs.readFile(DATA_PATH)
	local applier = fs.readFile(ADAPTER_PATH)
	local manifest = fs.readFile(MANIFEST_PATH)

	t:describe("npcs_r5 pure data", function()
		t:it("exposes exactly the five required roles through R4-style helpers", function()
			expect(R5.familyId):toBe("npcs_r5")
			expect(family.id):toBe("npcs_r5")
			expect(R5.count()):toBe(5)
			expect(#R5.familyIds()):toBe(1)
			expect(R5.familyIds()[1]):toBe("npcs_r5")
			expect(R5.rolesFor("npcs_r5")):toBe(family.roles)
			expect(R5.rolesFor("not_a_family")):toBe(nil)
			expect(R5.slotsFor("npcs_r5")):toBe(family.slots)
			expect(#R5.slotsFor("not_a_family")):toBe(0)

			local count = 0
			for _, id in ipairs(ROLE_IDS) do
				local role = family.roles[id]
				expect(role ~= nil):toBe(true)
				expect(role.id):toBe(id)
				count += 1
			end
			for id in pairs(family.roles) do
				expect(contains(table.concat(ROLE_IDS, ","), id)):toBe(true)
			end
			expect(count):toBe(5)
		end)

		t:it("holds valid integer RGB triples for skin, shirt and pants", function()
			local function checkTriple(triple, roleId, field)
				expect(type(triple)):toBe("table")
				expect(#triple == 0 or #triple == 3):toBe(true)
				for _, channel in ipairs({ "r", "g", "b" }) do
					local value = triple[channel]
					expect(type(value)):toBe("number")
					expect(value >= 0 and value <= 255):toBe(true)
					expect(value % 1 == 0):toBe(true)
				end
				expect(roleId .. field .. triple.r .. "," .. triple.g .. "," .. triple.b):toBeTruthy()
			end
			for id, role in pairs(family.roles) do
				checkTriple(role.skin, id, "skin")
				checkTriple(role.shirt, id, "shirt")
				checkTriple(role.pants, id, "pants")
			end
			expect(family.roles.polisi.shirt.b):toBeGreaterThan(family.roles.polisi.shirt.r)
			expect(family.roles.polisi.pants.b):toBeGreaterThan(family.roles.polisi.pants.r)
		end)

		t:it("uses only the three verified real accessory IDs with creator and URL", function()
			local seen = {}
			for key, accessory in pairs(R5.accessories) do
				seen[key] = true
				expect(type(accessory.id)):toBe("number")
				expect(REAL_IDS[tostring(accessory.id)]):toBe(true)
				expect(type(accessory.name)):toBe("string")
				expect(type(accessory.creator)):toBe("string")
				expect(#accessory.creator > 0):toBe(true)
				expect(contains(accessory.licence, "FREE")):toBe(true)
				expect(accessory.kind):toBe("Model")
				expect(contains(accessory.url, tostring(accessory.id))):toBe(true)
				expect(contains(accessory.url, "https://create.roblox.com/store/asset/")):toBe(true)
				expect(type(accessory.targetSize)):toBe("number")
				expect(accessory.targetSize >= 0.5 and accessory.targetSize <= 2.5):toBe(true)
				expect(type(accessory.offsetY)):toBe("number")
			end
			for _, key in ipairs({ "caping", "caping_backup", "polisi_cap" }) do
				expect(seen[key]):toBe(true)
			end
			local ids = {}
			for _, accessory in pairs(R5.accessories) do
				ids[tostring(accessory.id)] = true
			end
			local idCount = 0
			for _ in pairs(ids) do
				idCount += 1
			end
			expect(idCount):toBe(3)
			expect(R5.accessories.caping.id):toBe(71002247087415)
			expect(R5.accessories.caping_backup.id):toBe(14769019514)
			expect(R5.accessories.polisi_cap.id):toBe(126970096704856)
			expect(R5.accessories.caping.creator):toBe("Zephban5961")
			expect(R5.accessories.caping_backup.creator):toBe("RZKU")
			expect(R5.accessories.polisi_cap.creator):toBe("Mukamato101")
			expect(R5.accessories.caping.url):toBe("https://create.roblox.com/store/asset/71002247087415")
			expect(R5.accessories.caping_backup.url):toBe("https://create.roblox.com/store/asset/14769019514")
			expect(R5.accessories.polisi_cap.url):toBe("https://create.roblox.com/store/asset/126970096704856")
		end)

		t:it("maps real hats only to the three roles that have them", function()
			expect(family.roles.petani.hat):toBe("caping")
			expect(family.roles.petani_wanita.hat):toBe("caping")
			expect(family.roles.polisi.hat):toBe("polisi_cap")
			expect(family.roles.pedagang.hat):toBe(nil)
			expect(family.roles.tukang_peci.hat):toBe(nil)
			local assigned = {}
			for _, role in pairs(family.roles) do
				if role.hat then
					expect(R5.accessories[role.hat] ~= nil):toBe(true)
					assigned[role.hat] = true
				end
			end
			expect(assigned.caping_backup):toBe(nil) -- spare, never staged
		end)

		t:it("stages all five on the plaza row facing the saved camera", function()
			expect(#family.slots):toBe(5)
			local expectedX = { -16, -8, 0, 8, 16 }
			for index, slot in ipairs(family.slots) do
				expect(slot.slot):toBe(ROLE_IDS[index])
				expect(slot.x):toBe(expectedX[index])
				expect(slot.y):toBe(0.5)
				expect(slot.z):toBe(8)
				expect(slot.ry):toBe(0)
				expect(slot.targetHeight):toBe(R5.PLAYER_HEIGHT)
				expect(slot.rotX):toBe(nil)
			end
			expect(family.camera.position):toEqual({ 0, 7, 28 })
			expect(family.camera.lookAt):toEqual({ 0, 2.5, 8 })
			expect(family.camera.position[3] > family.slots[1].z):toBe(true)
			expect(family.camera.lookAt[3]):toBe(family.slots[1].z)
			expect(family.camera.lookAt[2] > family.slots[1].y):toBe(true)
			expect(family.camera.lookAt[2] < family.slots[1].y + R5.PLAYER_HEIGHT):toBe(true)
		end)

		t:it("records the Designer builds and no substitute ID", function()
			expect(type(R5.designerBuild)):toBe("table")
			expect(type(R5.designerBuild.note)):toBe("string")
			for _, word in ipairs({ "peci", "batik", "sarong" }) do
				expect(contains(string.lower(R5.designerBuild.note), word)):toBe(true)
				expect(contains(string.lower(manifest), word)):toBe(true)
			end
			expect(contains(R5.designerBuild.note, "Designer build")):toBe(true)
			expect(contains(manifest, "Designer build")):toBe(true)
			expect(contains(data, "peci/kopiah")):toBe(true)
		end)

		t:it("stays pure data with exactly the three ID literals", function()
			local sourceIds = longDigitRuns(data)
			local expected = 0
			for id in pairs(REAL_IDS) do
				expect(sourceIds[id]):toBe(true)
				expected += 1
			end
			local actual = 0
			for _ in pairs(sourceIds) do
				actual += 1
			end
			expect(actual):toBe(expected)
			expect(contains(data, "rbxassetid")):toBe(false)
			expect(contains(data, "GetService")):toBe(false)
			expect(contains(data, "Instance.new")):toBe(false)
			expect(contains(data, "Color3")):toBe(false)
			expect(contains(data, "Vector3")):toBe(false)
			expect(contains(data, "CFrame")):toBe(false)
			expect(contains(data, "game:")):toBe(false)
			expect(contains(data, "rotX")):toBe(false)
			expect(contains(data, "LoadAnimation")):toBe(false)
			for _, creator in ipairs({ "Zephban5961", "RZKU", "Mukamato101" }) do
				expect(contains(manifest, creator)):toBe(true)
			end
			for id in pairs(REAL_IDS) do
				expect(contains(manifest, id)):toBe(true)
			end
		end)
	end)

	t:describe("LookDevModelsNpcsR5 server applier", function()
		t:it("registers the npcs_r5 candidate and exports apply/restore", function()
			expect(contains(applier, 'LookDev.register("npcs_r5"')):toBe(true)
			expect(contains(applier, "LookDevModelsNpcsR5.apply = applier.apply")):toBe(true)
			expect(contains(applier, "LookDevModelsNpcsR5.restore = applier.restore")):toBe(true)
			expect(contains(applier, "return LookDevModelsNpcsR5")):toBe(true)
			expect(contains(manifest, 'LookDev.enable("npcs_r5")')):toBe(true)
		end)

		t:it("builds R15 rigs from HumanoidDescription, never from imported bodies", function()
			expect(contains(applier, 'Instance.new("HumanoidDescription")')):toBe(true)
			expect(contains(applier, "CreateHumanoidModelFromDescription")):toBe(true)
			expect(contains(applier, "Enum.HumanoidRigType.R15")):toBe(true)
			expect(contains(applier, 'type((Players :: any).CreateHumanoidModelFromDescription) ~= "function"')):toBe(
				true
			)
			expect(contains(applier, "warnRole(")):toBe(true)
			expect(contains(applier, "warned[roleName]")):toBe(true)
		end)

		t:it("sets all six Color3 body fields", function()
			for _, field in ipairs({
				"HeadColor",
				"TorsoColor",
				"LeftArmColor",
				"RightArmColor",
				"LeftLegColor",
				"RightLegColor",
			}) do
				expect(contains(applier, "hd." .. field .. " = Color3.fromRGB(")):toBe(true)
			end
			expect(contains(applier, "HatAccessory")):toBe(false)
			expect(contains(applier, "ShirtAssetIds")):toBe(false)
			expect(contains(applier, "PantsAssetIds")):toBe(false)
		end)

		t:it("grounds with the bounding-box bottom and only Y rotation", function()
			expect(contains(applier, "GetBoundingBox()")):toBe(true)
			expect(contains(applier, "boxCFrame.Y - boxSize.Y * 0.5 - pivot.Y")):toBe(true)
			expect(
				contains(applier, "CFrame.new(slot.x, slot.y - bottomOffset, slot.z) * CFrame.Angles(0, slot.ry, 0)")
			):toBe(true)
			expect(contains(applier, "model:PivotTo(target)")):toBe(true)
			expect(contains(applier, "rotX")):toBe(false)
			expect(contains(applier, "math.pi")):toBe(false)
			local angleCalls = 0
			for _ in string.gmatch(applier, "CFrame%.Angles%(") do
				angleCalls += 1
			end
			expect(angleCalls):toBe(1)
			expect(contains(applier, "LoadAnimation")):toBe(false)
			expect(contains(applier, "Humanoid:Play")):toBe(false)
			expect(contains(applier, "Animator")):toBe(false)
			expect(contains(applier, "descendant.Anchored = true")):toBe(true)
			expect(contains(applier, "descendant.CanCollide = false")):toBe(true)
		end)

		t:it("loads the three real hat Models through one data-driven call", function()
			local loadCalls = 0
			for _ in string.gmatch(applier, "LoadAsset%(") do
				loadCalls += 1
			end
			expect(loadCalls):toBe(1)
			expect(contains(applier, ":LoadAsset(accessory.id)")):toBe(true)
			expect(contains(applier, "ModelMapNpcsR5.accessories[role.hat]")):toBe(true)
			expect(contains(applier, 'descendant:IsA("BasePart")')):toBe(true)
			expect(contains(applier, "accessory.targetSize / largest")):toBe(true)
			expect(contains(applier, "head.CFrame * CFrame.new(0, accessory.offsetY, 0)")):toBe(true)
			expect(contains(applier, "part.Parent = model")):toBe(true)
			expect(contains(applier, "rbxassetid")):toBe(false)
			expect(contains(applier, 'Instance.new("Decal"')):toBe(false)
			for id in pairs(REAL_IDS) do
				expect(contains(applier, id)):toBe(false)
			end
			local sourceIds = longDigitRuns(applier)
			local count = 0
			for _ in pairs(sourceIds) do
				count += 1
			end
			expect(count):toBe(0)
		end)

		t:it("detaches a prior folder and destroys everything it created on restore", function()
			expect(contains(applier, 'Instance.new("Folder")')):toBe(true)
			expect(contains(applier, "local function clearActive()")):toBe(true)
			expect(contains(applier, "folder:Destroy()")):toBe(true)
			expect(contains(applier, "previous.Parent = nil")):toBe(true)
			local marker = "restore = function()"
			local start = string.find(applier, marker, 1, true)
			expect(start ~= nil):toBe(true)
			local restoreBody = string.sub(applier, start + #marker)
			expect(contains(restoreBody, "clearActive()")):toBe(true)
			expect(contains(restoreBody, "previous.Parent = Workspace")):toBe(true)
		end)
	end)
end
