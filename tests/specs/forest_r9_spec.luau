--!nocheck
-- WORK_QUEUE items 138/102: default tropical BackgroundForest. Pure Lune locks on the data and
-- the Greybox consumer. No Studio, no screenshot, no visual verdict, no new asset ID.

local fs = require("@lune/fs")

local DATA_PATH = "src/shared/ModelMapForestR9.luau"
local GREYBOX_PATH = "src/server/World/Greybox.luau"

local function hasPine(value: string): boolean
	return string.find(string.lower(value), "pine", 1, true) ~= nil
end

local SPECIES_SET = { kelapa = true, mangga = true, pisang = true, bambu = true }

return function(t, Env)
	local expect = t.expect
	local Data = Env.new():require("shared/ModelMapForestR9")
	local R4 = Env.new():require("shared/ModelMapVegetationR4")
	local MapSpec = Env.new():require("server/World/MapSpec")
	local data = fs.readFile(DATA_PATH)
	local greybox = fs.readFile(GREYBOX_PATH)
	local placements = Data.placements()
	local r4Ids = R4.families.vegetation_r4.ids

	t:describe("ModelMapForestR9 pure data", function()
		t:it("locks the shared name/attribute contract and the four verified R4 IDs", function()
			expect(Data.MIN_INSTANCES):toBe(450)
			expect(Data.MIN_SPECIES):toBe(4)
			expect(Data.FOLDER_NAME):toBe("BackgroundForest")
			expect(Data.NAME_PREFIX):toBe("Tropical_")
			expect(#Data.SPECIES):toBe(4)
			for _, species in ipairs(Data.SPECIES) do
				expect(SPECIES_SET[species]):toBe(true)
				expect(hasPine(species)):toBe(false)
			end
			for species, id in pairs(Data.IDS) do
				expect(SPECIES_SET[species]):toBe(true)
				expect(id):toBe(r4Ids[species])
				expect(hasPine(species)):toBe(false)
			end
			expect(Data.IDS.shrubs):toBe(nil)
			expect(Data.IDS.pine):toBe(nil)
			expect(hasPine(Data.FOLDER_NAME)):toBe(false)
			expect(hasPine(Data.NAME_PREFIX)):toBe(false)
			expect(data:find("ModelMapVegetationR4.families.vegetation_r4.ids", 1, true) ~= nil):toBe(true)
			expect(data:find("Instance", 1, true)):toBe(nil)
			expect(data:find("Enum", 1, true)):toBe(nil)
		end)

		t:it("returns a deterministic >=450 wall across both bands with four species", function()
			expect(#placements >= Data.MIN_INSTANCES):toBe(true)
			expect(#placements >= 460 and #placements <= 750):toBe(true)
			local counts = {}
			for _, p in ipairs(placements) do
				counts[p.species] = (counts[p.species] or 0) + 1
			end
			local distinct = 0
			for species, count in pairs(counts) do
				expect(count > 0):toBe(true)
				expect(SPECIES_SET[species]):toBe(true)
				distinct += 1
			end
			expect(distinct):toBe(Data.MIN_SPECIES)
			local again = Data.placements()
			expect(#again):toBe(#placements)
			for i, p in ipairs(placements) do
				expect(p.x):toBe(again[i].x)
				expect(p.z):toBe(again[i].z)
				expect(p.species):toBe(again[i].species)
			end
		end)

		t:it("keeps every placement finite, in-band, yaw/scale bounded and name-safe", function()
			local ring, hills = 0, 0
			for _, p in ipairs(placements) do
				expect(p.x == p.x and p.x ~= math.huge and p.x ~= -math.huge):toBe(true)
				expect(p.z == p.z and p.z ~= math.huge and p.z ~= -math.huge):toBe(true)
				expect(p.yaw >= 0 and p.yaw < math.pi * 2):toBe(true)
				expect(p.scale >= 0.85 and p.scale <= 1.15):toBe(true)
				expect(type(p.angle)):toBe("number")
				expect(p.angle % 1 == 0 and p.angle >= 0 and p.angle < 360):toBe(true)
				expect(type(p.layer)):toBe("number")
				expect(p.layer >= 1 and p.layer <= 9 and p.layer % 1 == 0):toBe(true)
				expect(type(p.riverSide)):toBe("boolean")
				expect(p.riverSide):toBe(p.z > 200)
				local radius = math.sqrt(p.x * p.x + p.z * p.z)
				if p.layer <= 7 then
					ring += 1
					expect(radius >= 260 and radius <= 380):toBe(true)
				else
					hills += 1
					expect(radius >= 400 and radius <= 460):toBe(true)
				end
				expect(hasPine(Data.NAME_PREFIX .. p.species .. "_" .. p.angle .. "_" .. p.layer)):toBe(false)
			end
			expect(ring > 0):toBe(true)
			expect(hills > 0):toBe(true)
		end)

		t:it("honours the north/south skip rectangles and the sunset corridor", function()
			for _, p in ipairs(placements) do
				expect(not (p.z < -260 and math.abs(p.x) < 370)):toBe(true)
				expect(not (p.z > 250 and p.z < 364)):toBe(true)
				local deg = (math.deg(math.atan2(p.z, p.x)) + 360) % 360
				expect(deg < 130.01 or deg > 229.99):toBe(true)
			end
		end)

		t:it("biases kelapa toward the river/south side", function()
			local riverKelapa, inlandKelapa, river, inland = 0, 0, 0, 0
			for _, p in ipairs(placements) do
				if p.riverSide then
					river += 1
					if p.species == "kelapa" then
						riverKelapa += 1
					end
				else
					inland += 1
					if p.species == "kelapa" then
						inlandKelapa += 1
					end
				end
			end
			expect(river > 0 and inland > 0):toBe(true)
			expect(riverKelapa / river > inlandKelapa / inland):toBe(true)
		end)
	end)

	t:describe("ModelMapForestR9 shade anchors", function()
		local anchors = Data.shadeAnchors(MapSpec.HUBS)

		t:it("places 3-4 broadleaf/bamboo shade trees per hub, behind the door lane", function()
			local perHub = {}
			for _, a in ipairs(anchors) do
				expect(a.shade):toBe(true)
				expect(type(a.hubKey)):toBe("string")
				expect(SPECIES_SET[a.species]):toBe(true)
				expect(hasPine(a.species)):toBe(false)
				expect(a.layer % 1 == 0 and a.layer % 2 == 1):toBe(true)
				expect(a.angle % 1 == 0 and a.angle >= 0 and a.angle < 360):toBe(true)
				perHub[a.hubKey] = (perHub[a.hubKey] or 0) + 1
				local hub = nil
				for _, h in ipairs(MapSpec.HUBS) do
					if h.key == a.hubKey then
						hub = h
						break
					end
				end
				expect(hub ~= nil):toBe(true)
				if hub then
					local dx, dz = a.x - hub.x, a.z - hub.z
					expect(dx * dx + dz * dz <= 25 * 25):toBe(true)
					-- Inverse of MapSpec.rotatePoint: local +Z is the door lane, local -Z the back.
					local c, s = math.cos(math.rad(hub.yaw)), math.sin(math.rad(hub.yaw))
					expect(dx * s + dz * c < 0):toBe(true)
				end
			end
			for _, hub in ipairs(MapSpec.HUBS) do
				local count = perHub[hub.key] or 0
				expect(count >= 3 and count <= 4):toBe(true)
			end
			expect(#anchors >= #MapSpec.HUBS * 3):toBe(true)
		end)

		t:it("is deterministic and rejects pine names", function()
			local again = Data.shadeAnchors(MapSpec.HUBS)
			expect(#again):toBe(#anchors)
			for i, a in ipairs(anchors) do
				expect(a.x):toBe(again[i].x)
				expect(a.z):toBe(again[i].z)
				expect(a.species):toBe(again[i].species)
				expect(a.hubKey):toBe(again[i].hubKey)
				expect(hasPine("Shade_" .. a.species .. "_" .. a.hubKey .. "_" .. i)):toBe(false)
			end
			expect(data:find("shadeAnchors", 1, true) ~= nil):toBe(true)
			expect(greybox:find("shadeAnchors", 1, true) ~= nil):toBe(true)
			expect(greybox:find('SetAttribute("ShadeTree", true)', 1, true) ~= nil):toBe(true)
		end)
	end)

	t:describe("Greybox default-look consumer", function()
		t:it("requires R9, uses NAME_PREFIX and sets both forest attributes", function()
			expect(greybox:find("ModelMapForestR9", 1, true) ~= nil):toBe(true)
			expect(greybox:find("ModelMapForestR9.placements()", 1, true) ~= nil):toBe(true)
			expect(greybox:find("ModelMapForestR9.NAME_PREFIX", 1, true) ~= nil):toBe(true)
			expect(greybox:find('SetAttribute("ForestTree", true)', 1, true) ~= nil):toBe(true)
			expect(greybox:find('SetAttribute("ForestSpecies", p.species)', 1, true) ~= nil):toBe(true)
			expect(greybox:find("forest.Name = ModelMapForestR9.FOLDER_NAME", 1, true) ~= nil):toBe(true)
			expect(greybox:find('"Realistic Pine Tree"', 1, true)):toBe(nil)
			expect(greybox:find('"Pine_"', 1, true)):toBe(nil)
			expect(greybox:find('"[Pp][Ii][Nn][Ee]"', 1, true) ~= nil):toBe(true)
		end)
	end)
end
