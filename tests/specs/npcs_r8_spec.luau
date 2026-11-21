--!nocheck
-- WORK_QUEUE section M item 86: npcs_r8, five more villager roles. Locks the 15
-- main-session-verified catalog IDs, the second-row slots, the kids' scale and
-- the source-level wiring. The applier/harness need Roblox APIs, so Lune checks
-- their source text only.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect
	local env = Env.new()
	local Map = env:require("shared/ModelMapNpcsR8")
	local R6 = env:require("shared/ModelMapNpcsR6")
	local LookDev = env:require("shared/LookDev")
	local Review = env:require("shared/LookDevReview")
	local applier = fs.readFile("src/server/World/LookDevModelsNpcsR8.luau")
	local harness = fs.readFile("tools/studio/review_check_r8.luau")

	t:describe("npcs_r8 catalog roles", function()
		t:it("locks the 15 verified catalog IDs exactly", function()
			local c = Map.catalog
			expect(c.tengkulak.shirt):toBe(11755115818)
			expect(c.tengkulak.pants):toBe(121010548089939)
			expect(c.tengkulak.hats[1]):toBe(76392482317942)
			expect(c.debt_collector.shirt):toBe(5601091452)
			expect(c.debt_collector.pants):toBe(104437888647181)
			expect(c.debt_collector.hats[1]):toBe(122870229188390)
			expect(c.ibu_warung.layeredShirt):toBe(135555867890569)
			expect(c.ibu_warung.pants):toBe(94473038627675)
			expect(c.ibu_warung.hats[1]):toBe(99279983172002)
			expect(c.anak_anak.shirt):toBe(17550183186)
			expect(c.anak_anak.pants):toBe(14798718772)
			expect(c.anak_anak.hats[1]):toBe(90295258026402)
			expect(c.bapak_ojek.shirt):toBe(129826976931984)
			expect(c.bapak_ojek.pants):toBe(79151443926768)
			expect(c.bapak_ojek.hats[1]):toBe(16100797199)
		end)

		t:it("has five roles with distinct shirt/layeredShirt + pants pairs", function()
			local expected = { "tengkulak", "debt_collector", "ibu_warung", "anak_anak", "bapak_ojek" }
			expect(#Map.roleIds):toBe(5)
			for index, id in ipairs(expected) do
				expect(Map.roleIds[index]):toBe(id)
				expect(Map.roles[id].id):toBe(id)
				expect(Map.roles[id].catalog):toBe(Map.catalog[id])
				expect(#(Map.catalog[id].hats or {})):toBeGreaterThan(0)
			end
			local count = 0
			for _ in pairs(Map.roles) do
				count += 1
			end
			expect(count):toBe(5)
			expect(Map.uniqueOutfits(Map.catalog)):toBe(true)
			local duplicate = {
				a = { shirt = 1, pants = 2 },
				b = { shirt = 1, pants = 2 },
			}
			expect(Map.uniqueOutfits(duplicate)):toBe(false)
		end)

		t:it("maps body colours from R6 roles without inventing data", function()
			local sources = Map.roleSources
			expect(sources.tengkulak):toBe("pedagang")
			expect(sources.debt_collector):toBe("polisi")
			expect(sources.ibu_warung):toBe("petani_wanita")
			expect(sources.anak_anak):toBe("petani_wanita")
			expect(sources.bapak_ojek):toBe("petani")
			for _, id in ipairs(Map.roleIds) do
				local source = R6.roles[sources[id]]
				expect(Map.roles[id].skin):toBe(source.skin)
				expect(Map.roles[id].shirt):toBe(source.shirt)
				expect(Map.roles[id].pants):toBe(source.pants)
			end
		end)

		t:it("gives only anak-anak the kids' body and head scale", function()
			expect(Map.roles.anak_anak.bodyHeightScale):toBe(0.8)
			expect(Map.roles.anak_anak.headScale):toBe(1.2)
			for _, id in ipairs({ "tengkulak", "debt_collector", "ibu_warung", "bapak_ojek" }) do
				expect(Map.roles[id].bodyHeightScale):toBe(nil)
				expect(Map.roles[id].headScale):toBe(nil)
			end
		end)

		t:it("stages a second camera-facing row at z=14 with 6-stud spacing", function()
			expect(Map.ROW_OFFSET_Z):toBe(6)
			expect(Map.SPACING):toBe(6)
			expect(#Map.slots):toBe(5)
			for index, slot in ipairs(Map.slots) do
				local source = R6.slots[index]
				expect(slot.slot):toBe(Map.roleIds[index])
				expect(slot.x):toBe((index - 3) * 6)
				expect(slot.y):toBe(source.y)
				expect(slot.z):toBe(source.z + 6)
				expect(slot.z):toBe(14)
				expect(slot.ry):toBe(source.ry)
				expect(slot.ry):toBeGreaterThan(2.5)
				expect(slot.ry):toBeLessThan(3.8)
				expect(slot.targetHeight):toBe(source.targetHeight)
			end
			expect(Map.slots[2].x - Map.slots[1].x):toBe(6)
			expect(Map.savedCamera):toBe(R6.savedCamera)
			expect(Map.families.npcs_r8.roles):toBe(Map.roles)
			expect(Map.families.npcs_r8.slots):toBe(Map.slots)
		end)
	end)

	t:describe("npcs_r8 applier source", function()
		t:it("dresses R15 rigs through HumanoidDescription", function()
			expect(applier:find('Instance.new("HumanoidDescription")', 1, true) ~= nil):toBe(true)
			expect(applier:find("hd.Shirt = catalog.shirt", 1, true) ~= nil):toBe(true)
			expect(applier:find("hd.Pants = catalog.pants", 1, true) ~= nil):toBe(true)
			expect(applier:find("hd:SetAccessories(accessories, true)", 1, true) ~= nil):toBe(true)
			expect(applier:find("IsLayered = true", 1, true) ~= nil):toBe(true)
			expect(applier:find("CreateHumanoidModelFromDescriptionAsync", 1, true) ~= nil):toBe(true)
		end)

		t:it("sets kids' scale with a warn-only pcall guard", function()
			expect(applier:find("hd.BodyHeightScale = role.bodyHeightScale", 1, true) ~= nil):toBe(true)
			expect(applier:find("hd.HeadScale = role.headScale", 1, true) ~= nil):toBe(true)
			expect(applier:find("BodyHeightScale unsupported", 1, true) ~= nil):toBe(true)
			expect(applier:find("HeadScale unsupported", 1, true) ~= nil):toBe(true)
			-- The description member is absent in some Studio builds; the rig's scale
			-- Instances are the authoritative write and must stay locked.
			expect(applier:find("scaleRig(rig, role, roleName, warned)", 1, true) ~= nil):toBe(true)
			expect(applier:find("node.Value = value", 1, true) ~= nil):toBe(true)
		end)

		t:it("stamps outfit attributes for the live harness and publishes failures", function()
			expect(applier:find('rig:SetAttribute("LookDevR8", FAMILY_ID)', 1, true) ~= nil):toBe(true)
			expect(applier:find('rig:SetAttribute("Role", roleName)', 1, true) ~= nil):toBe(true)
			expect(applier:find('rig:SetAttribute("ShirtId"', 1, true) ~= nil):toBe(true)
			expect(applier:find('rig:SetAttribute("PantsId"', 1, true) ~= nil):toBe(true)
			expect(applier:find('rig:SetAttribute("HatIds"', 1, true) ~= nil):toBe(true)
			expect(applier:find("LookDevFailures.set(FAMILY_ID, failures)", 1, true) ~= nil):toBe(true)
			expect(applier:find(".reset(FAMILY_ID)", 1, true) ~= nil):toBe(true)
			expect(applier:find('LookDev.register("npcs_r8"', 1, true) ~= nil):toBe(true)
		end)
	end)

	t:describe("npcs_r8 harness and LookDev wiring", function()
		t:it("adds both checks to the LOAD_FAILURES-guarded harness", function()
			expect(harness:find('"NPC8_ROLES"', 1, true) ~= nil):toBe(true)
			expect(harness:find('"NPC8_OUTFITS"', 1, true) ~= nil):toBe(true)
			expect(harness:find('ipairs({ "vegetation_r7", "npcs_r7", "props_r7", "npcs_r8" })', 1, true) ~= nil):toBe(
				true
			)
			expect(harness:find("LookDevModelsNpcsR8_npcs_r8", 1, true) ~= nil):toBe(true)
			expect(harness:find("Own do...end scope", 1, true) ~= nil):toBe(true)
			expect(harness:find("GetAttribute", 1, true) ~= nil):toBe(true)
		end)

		t:it("registers candidate 71 with its server review path", function()
			expect(#LookDev.IDS):toBe(71)
			expect(LookDev.IDS[71]):toBe("npcs_r8")
			expect(LookDev.isCandidate("npcs_r8")):toBe(true)
			local plan = LookDev.plan("npcs_r8")
			expect(plan.id):toBe("npcs_r8")
			expect(plan.idsSource):toBe("Shared.ModelMapNpcsR8")
			local entry = Review.pathsFor("npcs_r8")
			expect(entry.datamodel):toBe("server")
			expect(entry.path):toEqual({ "World", "LookDevModelsNpcsR8" })
		end)
	end)
end
