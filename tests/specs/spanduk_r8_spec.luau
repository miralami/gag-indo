--!nocheck
-- WORK_QUEUE section M item 81: spanduk_r8 banners and signage.
-- Pure MapSpec-derived anchors, Strings keys, LookDev/review wiring, the two new read-only harness
-- checks and the applier's source guards. No Studio claim: CHECK evidence, tracker ticks and the
-- visual verdict belong to the main session / designer.

local fs = require("@lune/fs")

return function(t, Env, Fakes)
	local expect = t.expect

	local env = Env.new()
	local Data = env:require("shared/ModelMapSpandukR8")
	local MapSpec = env:require("server/World/MapSpec")
	local LookDev = env:require("shared/LookDev")
	local Review = env:require("shared/LookDevReview")
	local Strings = env:require("shared/Strings")

	local dataSrc = fs.readFile("src/shared/ModelMapSpandukR8.luau")
	local applierSrc = fs.readFile("src/server/World/LookDevSpandukR8.luau")
	local harnessSrc = fs.readFile("tools/studio/review_check_r8.luau")
	local gallerySrc = fs.readFile("docs/v2/visual/CANDIDATES.md")

	local warung = MapSpec.hub("warung")
	local pasar = MapSpec.hub("pasar")
	local warungSign = Data.hubSign(warung, "sign_warung", "hub_warung")
	local pasarSign = Data.hubSign(pasar, "spanduk_pasar", "hub_pasar")
	local southArm = nil
	for _, arm in ipairs(MapSpec.roadArms()) do
		if arm.name == "RoadSouth" then
			southArm = arm
		end
	end
	local roadRecipe = Data.roadSpanduk(southArm, "spanduk_selamat_datang", "canonical_overview")
	local buntingRecipe = Data.bunting(warung, "bunting_mampir", "hub_warung", 1)
	local counts = Data.counts({
		signs = { warungSign, pasarSign },
		spanduks = { roadRecipe },
		bunting = { buntingRecipe },
		flags = {},
		textPanels = {},
	})

	t:describe("spanduk_r8 pure data", function()
		t:it("locks the item-81 contract", function()
			expect(Data.id):toBe("spanduk_r8")
			expect(Data.familyId):toBe("spanduk_r8")
			expect(Data.folderName):toBe("LookDevSpandukR8_spanduk_r8")
			expect(Data.stageAttribute):toBe("SpandukR8")
			expect(Data.kindAttribute):toBe("SpandukKind")
			expect(Data.keyAttribute):toBe("SignKey")
			expect(Data.cameraAttribute):toBe("ApproachCamera")
			expect(Data.MIN_HEADROOM):toBe(9)
			expect(Data.BANNER_CLEARANCE >= Data.MIN_HEADROOM):toBe(true)
			expect(Data.BUNTING_FLAGS):toBe(7)
			expect(#Data.SIGN_KEYS):toBe(5)
			expect(Data.EXPECTED_SIGNS):toBe(4)
			expect(Data.EXPECTED_BUNTING_STRINGS):toBe(2)
		end)

		t:it("derives hub signs, the road spanduk and bunting from passed-in geometry", function()
			expect(warungSign.key):toBe("sign_warung")
			expect(warungSign.camera):toBe("hub_warung")
			expect(math.abs(warungSign.z - (warung.z + warung.depth / 2 + 4)) < 1e-6):toBe(true)
			expect(pasarSign.key):toBe("spanduk_pasar")
			expect(pasarSign.camera):toBe("hub_pasar")
			expect(roadRecipe.key):toBe("spanduk_selamat_datang")
			expect(roadRecipe.camera):toBe("canonical_overview")
			expect(roadRecipe.halfSpan):toBe(southArm.sx / 2 + 1.5)
			expect(roadRecipe.clearance >= 9):toBe(true)
			expect(roadRecipe.clearance - 4 / 2 >= 7.25):toBe(true)
			expect(buntingRecipe.camera):toBe("hub_warung")
			expect(buntingRecipe.count):toBe(Data.BUNTING_FLAGS)
			local first = Data.buntingPoint(buntingRecipe, 0)
			local last = Data.buntingPoint(buntingRecipe, 1)
			local middle = Data.buntingPoint(buntingRecipe, 0.5)
			expect(first.x):toBeNear(buntingRecipe.left.x, 1e-6)
			expect(last.x):toBeNear(buntingRecipe.right.x, 1e-6)
			expect(middle.drop > 0):toBe(true)
			expect(first.drop):toBeNear(0, 1e-6)
			expect(last.drop):toBeNear(0, 1e-6)
			expect(counts.sign):toBe(2)
			expect(counts.spanduk):toBe(1)
			expect(counts.bunting):toBe(1)
		end)

		t:it("carries no engine API or asset ID in the pure data module", function()
			expect(string.find(dataSrc, "rbxassetid://", 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, "Enum.", 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, "Instance.", 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, "Color3", 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, "CFrame", 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, "%d%d%d%d%d%d%d") == nil):toBe(true)
		end)
	end)

	t:describe("spanduk_r8 Strings, LookDev wiring and review harness", function()
		t:it("ships candidate 66 with Strings parity keys", function()
			expect(#LookDev.IDS):toBe(108)
			expect(LookDev.IDS[66]):toBe("spanduk_r8")
			local candidate = LookDev.candidates.spanduk_r8
			expect(candidate.id):toBe("spanduk_r8")
			expect(candidate.style):toBe("cartoonish-realism")
			expect(candidate.status):toBe("candidate, awaiting designer yes")
			expect(candidate.idsSource):toBe("Shared.ModelMapSpandukR8")
			expect(candidate.signCount):toBe(4)
			expect(candidate.buntingStrings):toBe(2)
			local plan = LookDev.plan("spanduk_r8")
			expect(plan ~= nil):toBe(true)
			expect(plan.id):toBe("spanduk_r8")
			expect(type(plan.render)):toBe("string")
			local entry = Review.paths.spanduk_r8
			expect(entry ~= nil):toBe(true)
			expect(entry.datamodel):toBe("server")
			expect(entry.path):toEqual({ "World", "LookDevSpandukR8" })
			for _, key in ipairs(Data.SIGN_KEYS) do
				local entryText = Strings.raw[key]
				expect(type(entryText)):toBe("table")
				expect(type(entryText.id)):toBe("string")
				expect(type(entryText.en)):toBe("string")
				expect(#entryText.id > 0 and #entryText.en > 0):toBe(true)
				expect(string.find(entryText.id, "^%s") == nil):toBe(true)
				expect(string.find(entryText.en, "%s$") == nil):toBe(true)
			end
		end)

		t:it("adds the two new checks next to the streetfurn family in ORDER", function()
			expect(
				harnessSrc:find(
					'"STREETFURN_CLEAR",\n\t"SIGN_TEXT_PARITY",\n\t"SIGN_FACING",\n\t"ANIMAL_COUNT",\n\t"ANIMAL_BOUNDS",\n\t"ANIMAL_COST",\n\t"PATH_CLEAR",',
					1,
					true
				) ~= nil
			):toBe(true)
			for _, name in ipairs({ "SIGN_TEXT_PARITY", "SIGN_FACING" }) do
				local _, emitted = string.gsub(harnessSrc, 'emit%(.-"' .. name .. '"', "")
				expect(emitted):toBe(1)
			end
			expect(harnessSrc:find('"LookDevSpandukR8_spanduk_r8"', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('"ApproachCamera"', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('"SignKey"', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("CFrame.LookVector", 1, true) == nil):toBe(true) -- read via cf.LookVector
			expect(harnessSrc:find("cf.LookVector", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("SD_MAX_ANGLE = 30", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("angle > SD_MAX_ANGLE", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("require(game.ReplicatedStorage.Shared.Strings)", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("require(game.ReplicatedStorage.Shared.ReviewCameras)", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('"spanduk_selamat_datang",\n\t"sign_warung",', 1, true) ~= nil):toBe(true)
		end)

		t:it("names a pending gallery row with an existing render path and review camera", function()
			local row = string.match(gallerySrc, "\n(| `spanduk_r8` |[^\r\n]+)")
			expect(row ~= nil):toBe(true)
			expect(string.find(row, 'LookDev.enable("spanduk_r8")', 1, true) ~= nil):toBe(true)
			local render = string.match(row, "`[^`]+` | [^|]+ | `[^`]+` | `([^`]+)`")
			expect(render ~= nil):toBe(true)
			expect(fs.isFile(render) or fs.isDir(render)):toBe(true)
			expect(string.find(row, "| pending", 1, true) ~= nil):toBe(true)
			expect(string.find(row, "`canonical_overview`", 1, true) ~= nil):toBe(true)
			expect(string.find(string.lower(row), "fps", 1, true) ~= nil):toBe(true)
		end)
	end)

	t:describe("spanduk_r8 applier", function()
		t:it("stages original anchored parts, Strings text from the UI font set and exact restore", function()
			expect(applierSrc:find("require((Shared :: any).ModelMapSpandukR8)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("require((Shared :: any).Strings)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("require((Shared :: any).Config.Visuals)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("require((Shared :: any).ReviewCameras)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("require(script.Parent.MapSpec)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Strings.get(SIGN_LANG, key)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("FONT[Visuals.fonts.display]", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Enum.Font.", 1, true) == nil):toBe(true) -- no hardcoded font name
			expect(applierSrc:find('Text%s*=%s*"', 1) == nil):toBe(true) -- no .Text word literal
			expect(applierSrc:find("CFrame.lookAt(", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Data.cameraAttribute", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('Instance.new("Part")', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('Instance.new("TextLabel")', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Anchored = true", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("CanCollide = false", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("LookDev.register(Data.familyId, applier)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("folder:Destroy()", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("rbxassetid://", 1, true) == nil):toBe(true)
		end)
	end)
end
