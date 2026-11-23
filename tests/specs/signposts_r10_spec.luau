--!nocheck
-- WORK_QUEUE item 257: LUNE-ONLY pure-data contract for "signposts_r10".
-- Live staging and the hero-shot readability verdict belong to check_q257.luau + the designer;
-- LookDev IDS and review wiring belong to the main session. This spec asserts neither.

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
	local Data = env:require("shared/ModelMapSignpostsR10")
	local Strings = env:require("shared/Strings")
	local pureSrc = fs.readFile("src/shared/ModelMapSignpostsR10.luau")
	local applierSrc = fs.readFile("src/server/World/LookDevSignpostsR10.luau")

	t:describe("signposts_r10 pure data", function()
		t:it("stays pure: no engine calls, no asset IDs and no undeclared big ID", function()
			for _, token in ipairs({ "rbxassetid://", "game.", "Instance.new", "Enum." }) do
				expect(string.find(pureSrc, token, 1, true) == nil):toBe(true)
			end
			for run in string.gmatch(pureSrc, "%d%d%d%d%d%d%d+") do
				expect(#run <= 7):toBe(true)
			end
		end)

		t:it("declares the id, folder name and readability floor", function()
			expect(Data.id):toBe("signposts_r10")
			expect(Data.folderName):toBe("LookDevSignpostsR10_signposts_r10")
			expect(Data.ASSET_KEY):toBe("signpost")
			expect(Data.RING_RADIUS):toBe(144)
			expect(Data.GROUND_Y):toBe(0.5)
			expect(Data.READ_MIN_PX):toBe(14)
			expect(Data.FONT_SIZE_PX >= Data.READ_MIN_PX):toBe(true)
			expect(Data.PLATE_COUNT):toBe(6)
			expect(#Data.POST_SIZE):toBe(3)
			expect(Data.POST_SIZE[2] > 8 and Data.POST_SIZE[2] < 9):toBe(true)
			expect(#Data.PLATE_SIZE):toBe(3)
			expect(#Data.LAMP_SIZE):toBe(3)
		end)

		t:it("has exactly four junction signs, each with six distinct arrow plates", function()
			expect(#Data.SIGNS):toBe(4)
			local seenSigns = {}
			for index, sign in ipairs(Data.SIGNS) do
				expect(sign.index):toBe(index)
				expect(seenSigns[sign.index] == nil):toBe(true)
				seenSigns[sign.index] = true
				expect(#sign.name > 0):toBe(true)
				expect(type(sign.yaw)):toBe("number")
				expect(type(sign.position.x)):toBe("number")
				expect(type(sign.position.y)):toBe("number")
				expect(type(sign.position.z)):toBe("number")
				local radius = math.sqrt(sign.position.x ^ 2 + sign.position.z ^ 2)
				expect(math.abs(radius - Data.RING_RADIUS) < 0.001):toBe(true)
				expect(#sign.plates):toBe(6)
				local heights, keys, yawOffsets = {}, {}, {}
				for order, plate in ipairs(sign.plates) do
					expect(plate.order):toBe(order)
					expect(heights[plate.height] == nil):toBe(true)
					expect(keys[plate.textKey] == nil):toBe(true)
					expect(yawOffsets[plate.yawOffset] == nil):toBe(true)
					heights[plate.height], keys[plate.textKey], yawOffsets[plate.yawOffset] = true, true, true
					expect(plate.height > 0 and plate.height < Data.POST_SIZE[2]):toBe(true)
					expect(plate.fontSizePx >= Data.READ_MIN_PX):toBe(true)
					expect(type(plate.side)):toBe("number")
				end
			end
		end)

		t:it("declares six plate text keys with both variants in Strings", function()
			expect(#Data.STRING_KEYS):toBe(6)
			local declared, used = {}, {}
			for _, key in ipairs(Data.STRING_KEYS) do
				expect(declared[key] == nil):toBe(true)
				declared[key] = true
			end
			for _, sign in ipairs(Data.SIGNS) do
				for _, plate in ipairs(sign.plates) do
					expect(declared[plate.textKey]):toBe(true)
					used[plate.textKey] = true
				end
			end
			for _, key in ipairs(Data.STRING_KEYS) do
				expect(used[key]):toBe(true)
				local entry = Strings.raw[key]
				expect(type(entry)):toBe("table")
				expect(type(entry.id)):toBe("string")
				expect(#entry.id > 0):toBe(true)
				expect(type(entry.en)):toBe("string")
				expect(#entry.en > 0):toBe(true)
			end
			expect(Strings.raw.signpost_pasar.id):toBe("Pasar")
			expect(Strings.raw.signpost_sungai.en):toBe("River")
			expect(Strings.raw.signpost_balai_desa.id):toBe("Balai Desa")
			expect(Strings.raw.signpost_kampung.en):toBe("Village")
		end)

		t:it("keeps the baked asset ID and script stripping in the SERVER applier", function()
			expect(string.find(applierSrc, "71310674426033", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, "LookDevAssetLoader", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, ".baked(", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, "LuaSourceContainer", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, "SignpostPlate", 1, true) ~= nil):toBe(true)
		end)

		t:it("stays identical across fresh requires", function()
			local fresh = Env.new():require("shared/ModelMapSignpostsR10")
			expect(serialize(fresh.SIGNS)):toBe(serialize(Data.SIGNS))
			expect(serialize(fresh.STRING_KEYS)):toBe(serialize(Data.STRING_KEYS))
		end)
	end)
end
