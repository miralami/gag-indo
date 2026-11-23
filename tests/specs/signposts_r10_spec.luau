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
			expect(Data.RING_RADIUS):toBe(144)
			expect(Data.GROUND_Y):toBe(0.5)
			expect(Data.READ_MIN_PX):toBe(14)
			expect(Data.FONT_SIZE_PX >= Data.READ_MIN_PX):toBe(true)
			expect(Data.PLATE_COUNT >= 5 and Data.PLATE_COUNT <= 6):toBe(true)
			expect(#Data.POST_SIZE):toBe(3)
			expect(#Data.PLATE_SIZE):toBe(3)
			expect(#Data.LAMP_SIZE):toBe(3)
		end)

		t:it("has a green square pole about 12 studs tall", function()
			expect(Data.POST_SIZE[1]):toBe(Data.POST_SIZE[3])
			expect(Data.POST_SIZE[1] >= 0.6 and Data.POST_SIZE[1] <= 0.8):toBe(true)
			expect(Data.POST_SIZE[2] >= 11.5 and Data.POST_SIZE[2] <= 13):toBe(true)
			local c = Data.POST_COLOR
			expect(c.g > c.r and c.g > c.b):toBe(true)
			expect(Data.PLATE_COLOR.g > Data.PLATE_COLOR.r):toBe(true)
			expect(Data.BORDER_COLOR.r):toBe(255)
			expect(Data.TEXT_COLOR.g):toBe(255)
			expect(Data.PLATE_STEP > Data.PLATE_SIZE[2]):toBe(true)
		end)

		t:it("has exactly four junction signs, each with five distinct non-overlapping plates", function()
			expect(#Data.SIGNS):toBe(4)
			local seenSigns = {}
			for index, sign in ipairs(Data.SIGNS) do
				expect(sign.index):toBe(index)
				expect(seenSigns[sign.index] == nil):toBe(true)
				seenSigns[sign.index] = true
				expect(#sign.name > 0):toBe(true)
				expect(type(sign.yaw)):toBe("number")
				local radius = math.sqrt(sign.position.x ^ 2 + sign.position.z ^ 2)
				expect(math.abs(radius - Data.RING_RADIUS) < 0.001):toBe(true)
				expect(#sign.plates >= 5 and #sign.plates <= 6):toBe(true)
				expect(#sign.plates):toBe(Data.PLATE_COUNT)
				local keys, yawOffsets, last = {}, {}, nil
				for order, plate in ipairs(sign.plates) do
					expect(plate.order):toBe(order)
					expect(keys[plate.textKey] == nil):toBe(true)
					expect(yawOffsets[plate.yawOffset] == nil):toBe(true)
					keys[plate.textKey], yawOffsets[plate.yawOffset] = true, true
					if last then
						expect(plate.height - last >= Data.PLATE_SIZE[2]):toBe(true)
					end
					last = plate.height
					expect(plate.height - Data.PLATE_SIZE[2] / 2 > 0):toBe(true)
					expect(plate.height + Data.PLATE_SIZE[2] / 2 < Data.POST_SIZE[2]):toBe(true)
					expect(plate.fontSizePx >= Data.READ_MIN_PX):toBe(true)
					expect(plate.side == 1 or plate.side == -1):toBe(true)
				end
			end
		end)

		t:it("declares plate text keys with both variants in Strings", function()
			expect(#Data.STRING_KEYS):toBe(Data.PLATE_COUNT)
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

		t:it("builds from parts: DiamondPlate pole, no Wood, no store model, SurfaceGui per plate", function()
			expect(string.find(applierSrc, "Material.DiamondPlate", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, "Material.Wood", 1, true) == nil):toBe(true)
			expect(string.find(applierSrc, "Material.SmoothPlastic", 1, true) == nil):toBe(true)
			expect(string.find(applierSrc, "LookDevAssetLoader", 1, true) == nil):toBe(true)
			expect(string.find(applierSrc, ".baked(", 1, true) == nil):toBe(true)
			expect(string.find(applierSrc, "SurfaceGui", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, "SignpostPlate", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, "PointLight", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, "isNight", 1, true) ~= nil):toBe(true)
		end)

		t:it("stays identical across fresh requires", function()
			local fresh = Env.new():require("shared/ModelMapSignpostsR10")
			expect(serialize(fresh.SIGNS)):toBe(serialize(Data.SIGNS))
			expect(serialize(fresh.STRING_KEYS)):toBe(serialize(Data.STRING_KEYS))
		end)
	end)
end
