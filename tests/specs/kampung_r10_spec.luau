--!nocheck
-- WORK_QUEUE items 200, 253 and 261. LUNE-ONLY pure-data and source contract for "kampung_r10":
-- 12 houses, the baked house/shrub IDs in the SERVER applier, and the exact SERVER-VM check lines.
-- Studio staging, KAMPUNG_HOUSES / LANE_CLEAR / PLOT_CLEAR / NOT_INTERACTIVE belong to check_q200;
-- q253's NO_MELONS / SHRUB_MODELS / LOOKDEV_LEAK are checked in the still-live check_q253.luau;
-- MODEL_USED / NO_SCRIPTS / HOUSE_SCALE / PATH_REACH / PERF_BUDGET belong to check_q261.luau.

local fs = require("@lune/fs")

local function serialize(value)
	if type(value) ~= "table" then
		return tostring(value)
	end
	local keys = {}
	for key in pairs(value) do
		keys[#keys + 1] = tostring(key)
	end
	table.sort(keys)
	local fields = {}
	for _, key in ipairs(keys) do
		fields[#fields + 1] = key .. "=" .. serialize(value[key])
	end
	return "{" .. table.concat(fields, ",") .. "}"
end

return function(t, Env)
	local expect = t.expect
	local env = Env.new()
	local Data = env:require("shared/ModelMapKampungR10")
	local pureSrc = fs.readFile("src/shared/ModelMapKampungR10.luau")
	local applierSrc = fs.readFile("src/server/World/LookDevKampungR10.luau")
	local check253Src = fs.readFile("tools/studio/check_q253.luau")
	local check261Src = fs.readFile("tools/studio/check_q261.luau")

	t:describe("kampung_r10 pure data", function()
		t:it("stays pure: no engine calls, no asset IDs, exact identity", function()
			for _, token in ipairs({ "rbxassetid://", "game.", "Instance.new", "Enum." }) do
				expect(string.find(pureSrc, token, 1, true) == nil):toBe(true)
			end
			for run in string.gmatch(pureSrc, "%d%d%d%d%d%d%d+") do
				expect(#run <= 7):toBe(true)
			end
			expect(Data.id):toBe("kampung_r10")
			expect(Data.folderName):toBe("LookDevKampungR10_kampung_r10")
			expect(Data.tagAttribute):toBe("KampungHouse")
			expect(Data.stageAttribute):toBe("LookDevStage")
			expect(Data.modelAttribute):toBe("KampungModelAsset")
			expect(Data.scaleTolerance):toBe(0.2)
			expect(Data.HOUSE_COUNT):toBe(12)
			expect(Data.CLUSTER_COUNT):toBe(3)
			expect(Data.HOUSES_PER_CLUSTER):toBe(4)
			expect(#Data.BODY_SIZE):toBe(3)
			expect(serialize(Data.BODY_SIZE)):toBe(serialize({ 16, 9, 12 }))
		end)

		t:it("holds 12 houses across 3 loose two-row clusters of 4", function()
			local houses = Data.houses()
			expect(#houses):toBe(Data.HOUSE_COUNT)
			expect(#houses >= 10 and #houses <= 14):toBe(true)
			local counts, names = {}, {}
			for _, house in ipairs(houses) do
				counts[house.cluster] = (counts[house.cluster] or 0) + 1
				names[house.name] = true
				expect(type(house.yaw) == "number"):toBe(true)
				expect(#house.body.size):toBe(3)
				expect(#house.roof.size):toBe(3)
			end
			expect(#counts):toBe(3)
			for _, cluster in ipairs({ 1, 2, 3 }) do
				expect(counts[cluster]):toBe(4)
			end
			local unique = 0
			for _ in pairs(names) do
				unique += 1
			end
			expect(unique):toBe(12)
		end)

		t:it("places every house between ring and plots, clear of plot centres", function()
			for _, house in ipairs(Data.houses()) do
				local x, z = house.position.x, house.position.z
				local radius = math.sqrt(x * x + z * z)
				expect(radius >= 150 and radius <= 185):toBe(true)
				for index = 1, 10 do
					local angle = (index - 3) / 10 * math.pi * 2
					local px, pz = math.cos(angle) * 192, math.sin(angle) * 192
					expect(math.sqrt((x - px) ^ 2 + (z - pz) ^ 2) >= 20):toBe(true)
				end
				for _, color in ipairs({ house.body.color, house.roof.color }) do
					for _, channel in ipairs({ color.r, color.g, color.b }) do
						expect(channel >= 0 and channel <= 255):toBe(true)
					end
				end
			end
		end)

		t:it("returns two fences and two hedge-shrub anchors per house, never a Ball", function()
			local yards = Data.yardParts()
			expect(#yards):toBe(48)
			local perHouse, shrubs, clusters = {}, 0, {}
			for _, part in ipairs(yards) do
				perHouse[part.house] = (perHouse[part.house] or 0) + 1
				expect(part.shape == "Ball"):toBe(false)
				expect(#part.size):toBe(3)
				expect(part.color ~= nil):toBe(true)
				if part.kind == "shrub" then
					expect(part.shape):toBe("Hedge")
					expect(part.position.y):toBe(Data.GROUND_Y)
					clusters[part.cluster] = true
					shrubs += 1
				else
					expect(part.kind):toBe("fence")
					expect(part.shape):toBe("Block")
				end
				for _, channel in ipairs({ part.color.r, part.color.g, part.color.b }) do
					expect(channel >= 0 and channel <= 255):toBe(true)
				end
			end
			expect(shrubs):toBe(24)
			expect(#clusters):toBe(Data.CLUSTER_COUNT)
			for index = 1, 12 do
				expect(perHouse[index]):toBe(4)
			end
			expect(string.find(pureSrc, "PartType.Ball", 1, true) == nil):toBe(true)
		end)

		t:it("is deterministic across fresh requires with fresh tables", function()
			local fresh = Env.new():require("shared/ModelMapKampungR10")
			expect(serialize(fresh.houses())):toBe(serialize(Data.houses()))
			expect(serialize(fresh.yardParts())):toBe(serialize(Data.yardParts()))
			local first, second = Data.houses(), Data.houses()
			expect(first ~= second):toBe(true)
			expect(first[1] ~= second[1]):toBe(true)
			first[1].position.x = -9999
			expect(second[1].position.x ~= -9999):toBe(true)
			expect(Data.houses()[1].position.x ~= -9999):toBe(true)
		end)
	end)

	t:describe("kampung_r10 SERVER applier", function()
		t:it("stages non-interactive attributed descendants only", function()
			for _, token in ipairs({ "ProximityPrompt", "ClickDetector", "LoadAsset", "rbxassetid://" }) do
				expect(string.find(applierSrc, token, 1, true) == nil):toBe(true)
			end
			for _, token in ipairs({
				"Anchored = true",
				"CanCollide = false",
				"CastShadow = false",
				"SetAttribute",
				"Cylinder",
				"Transparency = descriptor.transparent and 1 or 0",
			}) do
				expect(string.find(applierSrc, token, 1, true) ~= nil):toBe(true)
			end
			expect(string.find(applierSrc, "LookDev.register", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, "ModelMapKampungR10", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, "for index = #savedOrder, 1, -1 do", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, "for index = #created, 1, -1 do", 1, true) ~= nil):toBe(true)
		end)

		t:it("uses baked pick 2 for houses and real baked shrub IDs for yards", function()
			expect(string.find(applierSrc, "HOUSE_ASSET_ID = 18239791051", 1, true) ~= nil):toBe(true)
			expect(
				string.find(applierSrc, "SHRUB_ASSET_IDS = { 116666781655827, 9953859659, 5661660655 }", 1, true) ~= nil
			):toBe(true)
			expect(string.find(applierSrc, "require(script.Parent.LookDevAssetLoader)", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, ".baked(HOUSE_ASSET_ID)", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, ".baked(assetId)", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, "BaseScript", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, "LuaSourceContainer", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, ":ScaleTo(factor)", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, "(Data :: any).BODY_SIZE", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, "Data :: any).scaleTolerance", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, "20% HOUSE_SCALE", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, "HEDGE_BLADES", 1, true) == nil):toBe(true)
			expect(string.find(applierSrc, "Shape = Enum.PartType.Ball", 1, true) == nil):toBe(true)
			expect(string.find(applierSrc, "child.Shape == Enum.PartType.Ball", 1, true) ~= nil):toBe(true)
		end)

		t:it("keeps q253 hedge anchors as invisible real-model yard markers", function()
			expect(string.find(applierSrc, "stageShrubAnchor", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, "stageShrubModel", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, '"shrub", "Cylinder"', 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, "HedgeShrub", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, "shrubCluster", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, 'sanitizeModel, model, descriptor, houseIndex, "house"', 1, true) ~= nil):toBe(
				true
			)
			expect(string.find(applierSrc, "(Data :: any).modelAttribute", 1, true) ~= nil):toBe(true)
		end)
	end)

	t:describe("kampung_r10 Studio checks", function()
		t:it("check_q253 keeps its unweakened NO_MELONS / SHRUB_MODELS / LOOKDEV_LEAK targets", function()
			expect(string.find(check253Src, '"NO_MELONS"', 1, true) ~= nil):toBe(true)
			expect(string.find(check253Src, '"SHRUB_MODELS"', 1, true) ~= nil):toBe(true)
			expect(string.find(check253Src, "SHRUB_MODELS = 3", 1, true) ~= nil):toBe(true)
			expect(string.find(check253Src, "Enum.PartType.Wedge", 1, true) ~= nil):toBe(true)
			expect(string.find(check253Src, "Enum.PartType.Cylinder", 1, true) ~= nil):toBe(true)
			expect(string.find(check253Src, "HedgeShrub", 1, true) ~= nil):toBe(true)
			expect(string.find(check253Src, "shrubCluster", 1, true) ~= nil):toBe(true)
			expect(string.find(check253Src, "<= 4", 1, true) ~= nil):toBe(true)
			expect(string.find(check253Src, "CAL_NO_MELONS_FAIL", 1, true) ~= nil):toBe(true)
			expect(string.find(check253Src, "CAL_LOOKDEV_LEAK_FAIL", 1, true) ~= nil):toBe(true)
			expect(string.find(check253Src, 'emit("LOOKDEV_LEAK", #after == 0, #after, 0', 1, true) ~= nil):toBe(true)
		end)

		t:it("check_q261 measures the staged SERVER DataModel with exact names and targets", function()
			for _, name in ipairs({
				"MODEL_USED",
				"NO_SCRIPTS",
				"HOUSE_SCALE",
				"NO_MELONS",
				"PATH_REACH",
				"PERF_BUDGET",
				"CAL_MODEL_USED_FAIL",
				"CAL_HOUSE_SCALE_FAIL",
			}) do
				expect(string.find(check261Src, '"' .. name .. '"', 1, true) ~= nil):toBe(true)
			end
			for _, token in ipairs({
				"local CHECK_NAMES = {",
				"MODEL_USED = 12,",
				"NO_SCRIPTS = 0,",
				"HOUSE_SCALE = 12,",
				"NO_MELONS = 0,",
				"PERF_BUDGET = PERF_TARGET,",
				"HOUSE_ASSET_ID = 18239791051",
				'IsA("Model")',
				'IsA("BaseScript")',
				"GetBoundingBox()",
				"Data.scaleTolerance",
				"workspace:Raycast",
				"recordSet",
				"restoreInjected()",
				"review.disableAll()",
				"SUMMARY_Q261",
			}) do
				expect(string.find(check261Src, token, 1, true) ~= nil):toBe(true)
			end
			expect(string.find(check261Src, "after.houses == expected", 1, true) ~= nil):toBe(true)
			expect(string.find(check261Src, "after.blocked == before.blocked", 1, true) ~= nil):toBe(true)
			expect(string.find(check261Src, "calUsed.houses < expected", 1, true) ~= nil):toBe(true)
			expect(string.find(check261Src, "calScale.scaled < expected", 1, true) ~= nil):toBe(true)
			expect(string.find(check261Src, "FindFirstChildOfClass", 1, true) == nil):toBe(true)
		end)
	end)
end
