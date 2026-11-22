--!nocheck
-- WORK_QUEUE item 41 (spawn_r5): off-by-default spawn dressing pass. The data module is pure and
-- is checked at runtime under the Env harness; the applier needs Roblox APIs and is checked as
-- source text. No visual verdict, no Studio claim, no screenshot, no asset ID invented here.

local fs = require("@lune/fs")

local DATA_PATH = "src/shared/SpawnDressingMapR5.luau"
local ADAPTER_PATH = "src/server/World/LookDevSpawnDressingR5.luau"

local ROLES = { "petani", "pedagang", "petani_wanita", "tukang_peci", "polisi" }
local TIERS = { "Rendah", "Sedang", "Tinggi" }

local function contains(text, needle)
	return string.find(text, needle, 1, true) ~= nil
end

local function findFunction(text, signature)
	local start = string.find(text, signature, 1, true)
	if not start then
		return ""
	end
	local finish = string.find(text, "\nend\n", start, true)
	return if finish then string.sub(text, start, finish + 4) else ""
end

return function(t, Env)
	local expect = t.expect
	local env = Env.new()
	local D = env:require("shared/SpawnDressingMapR5")
	local Buildings = env:require("shared/ModelMapBuildingsR4")
	local Props = env:require("shared/ModelMapPropsR5")
	local Vegetation = env:require("shared/ModelMapVegetationR5")
	local Npcs = env:require("shared/ModelMapNpcsR5")
	local data = fs.readFile(DATA_PATH)
	local applier = fs.readFile(ADAPTER_PATH)

	local bySource = {}
	for _, entry in ipairs(D.entries) do
		bySource[entry.source] = (bySource[entry.source] or 0) + 1
	end
	local function has(source, key)
		for _, entry in ipairs(D.entries) do
			if entry.source == source and entry.key == key then
				return true
			end
		end
		return false
	end
	local function countKey(source, key)
		local total = 0
		for _, entry in ipairs(D.entries) do
			if entry.source == source and entry.key == key then
				total += 1
			end
		end
		return total
	end

	t:describe("spawn_r5 pure data", function()
		t:it("is off by default with a saved north-facing review camera", function()
			expect(D.id):toBe("spawn_r5")
			expect(D.groundY):toBe(0.5)
			expect(type(D.camera)):toBe("table")
			expect(D.camera.position[3]):toBeGreaterThan(D.camera.lookAt[3])
			expect(type(D.camera.derivedFrom)):toBe("string")
			expect(contains(D.camera.derivedFrom, "buildings row")):toBe(true)
			expect(contains(D.camera.derivedFrom, "NPC row")):toBe(true)
		end)

		t:it("uses exactly the documented tier budgets and triangle estimates", function()
			expect(D.budgets.Rendah.instances):toBe(50)
			expect(D.budgets.Rendah.triangles):toBe(50000)
			expect(D.budgets.Sedang.instances):toBe(100)
			expect(D.budgets.Sedang.triangles):toBe(100000)
			expect(D.budgets.Tinggi.instances):toBe(150)
			expect(D.budgets.Tinggi.triangles):toBe(150000)
			expect(D.TRI_PER_KIT):toBe(2000)
			expect(D.TRI_PER_LANDMARK):toBe(8000)
			expect(D.tiers):toEqual(TIERS)
		end)

		t:it("holds only flat, well-formed entries from the four approved sources", function()
			expect(#D.entries):toBeGreaterThan(0)
			for _, entry in ipairs(D.entries) do
				expect(type(entry.slot)):toBe("string")
				expect(entry.kind == "model" or entry.kind == "rig"):toBe(true)
				expect(
					entry.source == "buildings"
						or entry.source == "props"
						or entry.source == "vegetation"
						or entry.source == "npcs"
				):toBe(true)
				expect(type(entry.key)):toBe("string")
				for _, field in ipairs({ "x", "y", "z", "ry", "rotX", "targetHeight" }) do
					expect(type(entry[field])):toBe("number")
				end
				local validTier = false
				for _, tier in ipairs(TIERS) do
					if tier == entry.tier then
						validTier = true
					end
				end
				expect(validTier):toBe(true)
				expect(entry.cluster == "A" or entry.cluster == "B" or entry.cluster == "C"):toBe(true)
				if entry.kind == "model" then
					expect(entry.y):toBe(0.5)
				else
					expect(entry.rotX):toBe(0)
				end
			end
		end)

		t:it("composes every required building, prop, tree and character", function()
			expect(has("buildings", "gudang")):toBe(true)
			expect(has("buildings", "warung")):toBe(true)
			expect(has("buildings", "rumah")):toBe(false)
			expect(has("buildings", "kandang")):toBe(false)
			expect(has("props", "jemuran")):toBe(true)
			expect(countKey("props", "karung")):toBe(4)
			expect(has("props", "gerobak")):toBe(true)
			expect(has("props", "sumur")):toBe(true)
			expect(has("props", "lapak")):toBe(true)
			expect(has("props", "pagar_bambu")):toBe(true)
			expect(has("props", "alat_tani")):toBe(true)
			expect(countKey("vegetation", "pisang")):toBeAtLeast(3)
			expect(countKey("vegetation", "pisang")):toBeAtMost(4)
			expect(countKey("vegetation", "bambu")):toBeAtLeast(10)
			for _, role in ipairs(ROLES) do
				expect(has("npcs", role)):toBe(true)
			end
			expect(bySource.npcs):toBe(5)
		end)

		t:it("never places kelapa, pine or the mangga stand-in", function()
			for _, entry in ipairs(D.entries) do
				expect(entry.key ~= "kelapa"):toBe(true)
				expect(entry.key ~= "mangga"):toBe(true)
				expect(entry.key ~= "mangga_true"):toBe(true)
				expect(entry.key ~= "pine"):toBe(true)
				expect(contains(entry.slot, "kelapa")):toBe(false)
				expect(contains(entry.slot, "mangga")):toBe(false)
				expect(contains(entry.slot, "pine")):toBe(false)
			end
		end)

		t:it("copies source positions verbatim, including the contextual karung stack", function()
			for _, entry in ipairs(D.entries) do
				if entry.source == "buildings" then
					local found = false
					for _, slot in ipairs(Buildings.families.buildings_r4.slots) do
						if
							slot.slot == entry.key
							and slot.x == entry.x
							and slot.z == entry.z
							and slot.ry == entry.ry
							and slot.targetHeight == entry.targetHeight
						then
							found = true
						end
					end
					expect(found):toBe(true)
				elseif entry.source == "props" and entry.key == "karung" then
					local group = Props.families.props_r5.karung
					local found = false
					for _, sack in ipairs(group.stack) do
						if
							group.x + sack.dx == entry.x
							and group.z + sack.dz == entry.z
							and sack.dy == entry.yOffset
						then
							found = true
						end
					end
					expect(found):toBe(true)
					expect(entry.scale):toBe(group.scale)
				elseif entry.source == "props" then
					local found = false
					for _, slot in ipairs(Props.families.props_r5.slots) do
						if
							slot.slot == entry.key
							and slot.x == entry.x
							and slot.z == entry.z
							and slot.ry == entry.ry
							and slot.scale == entry.scale
						then
							found = true
						end
					end
					expect(found):toBe(true)
				elseif entry.source == "vegetation" then
					local found = false
					for _, slot in ipairs(Vegetation.slots()) do
						if
							slot.slot == entry.key
							and slot.x == entry.x
							and slot.z == entry.z
							and slot.ry == entry.ry
							and slot.targetHeight == entry.targetHeight
						then
							found = true
						end
					end
					expect(found):toBe(true)
					expect(entry.footprint.halfX):toBeGreaterThan(0)
				elseif entry.source == "npcs" then
					local found = false
					for _, slot in ipairs(Npcs.families.npcs_r5.slots) do
						if slot.slot == entry.key and slot.x == entry.x and slot.y == entry.y and slot.z == entry.z then
							found = true
						end
					end
					expect(found):toBe(true)
				end
			end
		end)

		t:it("keeps every tree out of the north-road corridor", function()
			local trees = 0
			for _, entry in ipairs(D.entries) do
				if entry.isTree then
					trees += 1
					expect(entry.source):toBe("vegetation")
					expect(D.inNorthCorridor(entry.x, entry.z)):toBe(false)
					expect(entry.footprint ~= nil):toBe(true)
				end
			end
			expect(trees):toBeGreaterThan(0)
			expect(D.inNorthCorridor(0, 28)):toBe(true)
			expect(D.inNorthCorridor(15, 28)):toBe(false)
			expect(D.inNorthCorridor(0, -136)):toBe(true)
			expect(D.inNorthCorridor(0, -137)):toBe(false)
		end)

		t:it("stays inside instance and triangle budgets at every tier", function()
			for _, tier in ipairs(TIERS) do
				local budget = D.budgets[tier]
				expect(D.countForTier(tier)):toBeGreaterThan(0)
				expect(D.countForTier(tier) <= budget.instances):toBe(true)
				expect(D.estimateTrianglesForTier(tier) <= budget.triangles):toBe(true)
			end
			local landmarks = 0
			for _, entry in ipairs(D.entries) do
				if entry.landmark then
					landmarks += 1
				end
			end
			expect(landmarks):toBe(2)
			expect(D.estimateTrianglesForTier("Rendah")):toBe(
				2 * D.TRI_PER_LANDMARK + (D.countForTier("Rendah") - 2) * D.TRI_PER_KIT
			)
		end)

		t:it("resolves only real IDs from the source modules and nil for rigs", function()
			for _, entry in ipairs(D.entries) do
				local id = D.idFor(entry)
				if entry.kind == "rig" then
					expect(id):toBeNil()
				else
					expect(type(id)):toBe("number")
					expect(id > 0 and id % 1 == 0):toBe(true)
					local expected
					if entry.source == "buildings" then
						expected = Buildings.families.buildings_r4.ids[entry.key]
					elseif entry.source == "props" then
						expected = Props.families.props_r5.ids[entry.key]
					else
						expected = Vegetation.ids[entry.key]
					end
					expect(id):toBe(expected)
				end
			end
			expect(D.idFor({ kind = "model", source = "unknown", key = "x" })):toBeNil()
		end)

		t:it("maps only the verified hats and keeps tier selection monotone", function()
			expect(D.tierRank("Rendah")):toBe(1)
			expect(D.tierRank("Sedang")):toBe(2)
			expect(D.tierRank("Tinggi")):toBe(3)
			expect(D.tierRank("unknown")):toBe(0)
			expect(D.accessoryFor(Npcs.families.npcs_r5.roles.petani)):toBe(Npcs.accessories.caping)
			expect(D.accessoryFor("polisi")):toBe(Npcs.accessories.polisi_cap)
			expect(D.accessoryFor("pedagang")):toBeNil()
			expect(D.accessoryFor("tukang_peci")):toBeNil()
			local previous = 0
			for _, tier in ipairs(TIERS) do
				local list = D.entriesForTier(tier)
				expect(#list):toBe(D.countForTier(tier))
				expect(#list >= previous):toBe(true)
				previous = #list
			end
			local low = {}
			for _, entry in ipairs(D.entriesForTier("Rendah")) do
				low[entry.slot] = true
			end
			for _, entry in ipairs(D.entriesForTier("Tinggi")) do
				if D.tierRank(entry.tier) <= 1 then
					expect(low[entry.slot]):toBe(true)
				end
			end
		end)

		t:it("remains pure data with no engine calls", function()
			expect(contains(data, "GetService")):toBe(false)
			expect(contains(data, "Instance.new")):toBe(false)
			expect(contains(data, "game.")):toBe(false)
			expect(contains(data, "PivotTo")):toBe(false)
		end)
	end)

	t:describe("LookDevSpawnDressingR5 applier source", function()
		t:it("registers spawn_r5 and exports apply, restore and setTier", function()
			expect(contains(applier, 'LookDev.register("spawn_r5", applier)')):toBe(true)
			expect(contains(applier, "LookDevSpawnDressingR5.apply = applier.apply")):toBe(true)
			expect(contains(applier, "LookDevSpawnDressingR5.restore = applier.restore")):toBe(true)
			expect(contains(applier, "function LookDevSpawnDressingR5.setTier(")):toBe(true)
			expect(contains(applier, "entriesForTier(activeTier)")):toBe(true)
			expect(contains(applier, 'local activeTier = "Sedang"')):toBe(true)
		end)

		t:it("builds upright R15 rigs from a HumanoidDescription with all six colours", function()
			expect(contains(applier, 'Instance.new("HumanoidDescription")')):toBe(true)
			expect(contains(applier, "CreateHumanoidModelFromDescription")):toBe(true)
			expect(contains(applier, "Enum.HumanoidRigType.R15")):toBe(true)
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
			local groundRig = findFunction(applier, "local function groundRig(")
			expect(#groundRig > 0):toBe(true)
			expect(contains(groundRig, "rotX")):toBe(false)
			expect(contains(groundRig, "CFrame.Angles(0, entry.ry, 0)")):toBe(true)
		end)

		t:it("loads models only from resolved IDs and hats from accessory data", function()
			expect(contains(applier, "SpawnDressingMapR5.idFor(entry)")):toBe(true)
			expect(contains(applier, "LoadAsset(id)")):toBe(true)
			expect(contains(applier, "SpawnDressingMapR5.accessoryFor(role)")):toBe(true)
			expect(contains(applier, "LoadAsset(accessory.id)")):toBe(true)
			local _, loadCalls = string.gsub(applier, "LoadAsset%(", "")
			expect(loadCalls):toBe(2)
			expect(contains(applier, "Model:ScaleTo")):toBe(false)
			expect(contains(applier, "model:ScaleTo(target / bodySizeY)")):toBe(true)
			expect(
				contains(
					applier,
					"model:PivotTo(CFrame.new(pivot.Position) * CFrame.Angles(entry.rotX or 0, entry.ry, 0))"
				)
			):toBe(true)
		end)

		t:it("destroys the active folder on restore and re-parents the saved folder exactly", function()
			expect(contains(applier, "folder:Destroy()")):toBe(true)
			expect(contains(applier, "restore = function()")):toBe(true)
			expect(contains(applier, "previous.Parent = nil")):toBe(true)
			expect(contains(applier, "previous.Parent = Workspace")):toBe(true)
			expect(contains(applier, "previous.CanCollide = false")):toBe(false)
			expect(contains(applier, "descendant.CanCollide = false")):toBe(true)
		end)

		t:it("contains no embedded ID or ID-shaped literal", function()
			expect(string.find(applier, "rbxassetid://%d") ~= nil):toBe(false)
			expect(contains(applier, "assetId")):toBe(false)
			expect(string.find(applier, "%d%d%d%d%d%d%d") ~= nil):toBe(false)
		end)
	end)
end
