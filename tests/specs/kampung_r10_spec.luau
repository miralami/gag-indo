--!nocheck
-- WORK_QUEUE item 200: LUNE-ONLY pure-data contract for "kampung_r10". Studio staging and the
-- KAMPUNG_HOUSES / LANE_CLEAR / PATH_REACH / PLOT_CLEAR / NOT_INTERACTIVE checks belong to
-- check_q200.luau; LookDev IDS and review wiring belong to the wiring lane. This spec asserts neither.

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
			expect(Data.HOUSE_COUNT):toBe(12)
			expect(Data.CLUSTER_COUNT):toBe(3)
			expect(Data.HOUSES_PER_CLUSTER):toBe(4)
		end)

		t:it("holds 12 houses across 3 clusters of 4", function()
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

		t:it("returns two fences and two Ball plants per house", function()
			local yards = Data.yardParts()
			expect(#yards):toBe(48)
			local perHouse, plants = {}, 0
			for _, part in ipairs(yards) do
				perHouse[part.house] = (perHouse[part.house] or 0) + 1
				if part.kind == "plant" then
					expect(part.shape):toBe("Ball")
					plants += 1
				else
					expect(part.kind):toBe("fence")
					expect(part.shape):toBe("Block")
				end
				expect(#part.size):toBe(3)
				for _, channel in ipairs({ part.color.r, part.color.g, part.color.b }) do
					expect(channel >= 0 and channel <= 255):toBe(true)
				end
			end
			expect(plants):toBe(24)
			for index = 1, 12 do
				expect(perHouse[index]):toBe(4)
			end
		end)

		t:it("stages non-interactive attributed parts only", function()
			for _, token in ipairs({ "ProximityPrompt", "ClickDetector", "rbxassetid://" }) do
				expect(string.find(applierSrc, token, 1, true) == nil):toBe(true)
			end
			for _, token in ipairs({
				"Anchored = true",
				"CanCollide = false",
				"CastShadow = false",
				"SetAttribute",
				"Wedge",
			}) do
				expect(string.find(applierSrc, token, 1, true) ~= nil):toBe(true)
			end
			expect(string.find(applierSrc, "LookDev.register", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, "ModelMapKampungR10", 1, true) ~= nil):toBe(true)
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
end
