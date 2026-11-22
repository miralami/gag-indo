--!nocheck
-- WORK_QUEUE item 203: LUNE-ONLY pure-data contract for "signposts_r10".
-- Studio staging (SIGNPOSTS / SIGN_TEXT_IN_STRINGS / SIGN_READABLE) belongs to check_q203.luau;
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
			expect(Data.FONT_SIZE_PX):toBe(18)
			expect(Data.FONT_SIZE_PX >= Data.READ_MIN_PX):toBe(true)
		end)

		t:it("has exactly four junction signs with four unique text keys", function()
			expect(#Data.SIGNS):toBe(4)
			expect(#Data.STRING_KEYS):toBe(4)
			local seen, declared = {}, {}
			for _, key in ipairs(Data.STRING_KEYS) do
				expect(declared[key] == nil):toBe(true)
				declared[key] = true
			end
			for index, sign in ipairs(Data.SIGNS) do
				expect(sign.index):toBe(index)
				expect(seen[sign.textKey] == nil):toBe(true)
				seen[sign.textKey] = true
				expect(declared[sign.textKey]):toBe(true)
				expect(#sign.name > 0):toBe(true)
				expect(type(sign.yaw)):toBe("number")
				expect(type(sign.position.x)):toBe("number")
				expect(type(sign.position.y)):toBe("number")
				expect(type(sign.position.z)):toBe("number")
				expect(sign.fontSizePx >= 14):toBe(true)
			end
		end)

		t:it("keeps every sign string in Strings with both non-empty variants", function()
			local raw = Strings.raw
			for _, key in ipairs(Data.STRING_KEYS) do
				local entry = raw[key]
				expect(type(entry)):toBe("table")
				expect(type(entry.id)):toBe("string")
				expect(#entry.id > 0):toBe(true)
				expect(type(entry.en)):toBe("string")
				expect(#entry.en > 0):toBe(true)
			end
			expect(raw.signpost_pasar.id):toBe("Pasar")
			expect(raw.signpost_sungai.en):toBe("River")
		end)

		t:it("builds readable board and post descriptors at the ring junctions", function()
			local parts = Data.parts()
			expect(#parts):toBe(8)
			local boards, posts = 0, 0
			for _, part in ipairs(parts) do
				expect(#part.size):toBe(3)
				expect(#part.position):toBe(3)
				for _, channel in ipairs({ part.color.r, part.color.g, part.color.b }) do
					expect(channel >= 0 and channel <= 255):toBe(true)
				end
				if part.kind == "board" then
					boards += 1
				elseif part.kind == "post" then
					posts += 1
				end
			end
			expect(boards):toBe(4)
			expect(posts):toBe(4)
			local radii = {}
			for _, sign in ipairs(Data.SIGNS) do
				local x, z = sign.position.x, sign.position.z
				radii[math.floor(math.sqrt(x * x + z * z) + 0.5)] = true
			end
			expect(radii[Data.RING_RADIUS]):toBe(true)
		end)

		t:it("stays identical across fresh requires", function()
			local fresh = Env.new():require("shared/ModelMapSignpostsR10")
			expect(serialize(fresh.SIGNS)):toBe(serialize(Data.SIGNS))
			expect(serialize(fresh.parts())):toBe(serialize(Data.parts()))
			expect(serialize(fresh.STRING_KEYS)):toBe(serialize(Data.STRING_KEYS))
		end)
	end)
end
