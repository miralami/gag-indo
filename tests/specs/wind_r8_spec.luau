--!nocheck
-- WORK_QUEUE section M item 85: wind_r8 gentle wind and sway. Pure breeze/tween/tilt data,
-- LookDev + review wiring, the three mutating client harness checks and the client applier's
-- source guards. No Studio claim: CHECK evidence, tracker ticks and the visual verdict belong to
-- the main session / designer.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect

	local env = Env.new()
	local Data = env:require("shared/ModelMapWindR8")
	local MapSpec = env:require("server/World/MapSpec")
	local LookDev = env:require("shared/LookDev")
	local Review = env:require("shared/LookDevReview")

	local dataSrc = fs.readFile("src/shared/ModelMapWindR8.luau")
	local applierSrc = fs.readFile("src/client/World/LookDevWindR8.luau")
	local harnessSrc = fs.readFile("tools/studio/review_check_r8.luau")
	local gallerySrc = fs.readFile("docs/v2/visual/CANDIDATES.md")

	local breeze = Data.windVector()
	local sway = Data.tweenPlan(MapSpec)
	local tilt = Data.tiltPlan(MapSpec)

	t:describe("wind_r8 pure data", function()
		t:it("locks the gentle breeze under MAX_WIND", function()
			expect(Data.id):toBe("wind_r8")
			expect(Data.folder):toBe("LookDevWindR8_wind_r8")
			expect(Data.MAX_WIND):toBe(12)
			expect(Data.MAX_TWEENS):toBe(30)
			expect(Data.MAX_TILT_DEG):toBe(4)
			expect(breeze.x):toBe(2.5)
			expect(breeze.y):toBe(0)
			expect(breeze.z):toBe(1.5)
			expect(Data.magnitude(breeze) > 0):toBe(true)
			expect(Data.magnitude(breeze) <= Data.MAX_WIND):toBe(true)
			expect(Data.magnitude(nil)):toBe(0)
			expect(Data.magnitude({ x = 0, y = 0, z = 30 })):toBe(30)
			local copy = Data.windVector()
			copy.x = 99
			expect(breeze.x):toBe(2.5)
		end)

		t:it("builds a non-empty MapSpec-derived tween plan within 30", function()
			expect(#sway > 0):toBe(true)
			expect(#sway <= Data.MAX_TWEENS):toBe(true)
			expect(#sway):toBe(10)
			local laundry, signs = 0, 0
			for _, spec in ipairs(sway) do
				expect(spec.kind == "laundry" or spec.kind == "sign"):toBe(true)
				expect(type(spec.id) == "string"):toBe(true)
				expect(type(spec.position.x) == "number"):toBe(true)
				expect(type(spec.position.y) == "number"):toBe(true)
				expect(type(spec.position.z) == "number"):toBe(true)
				expect(spec.amplitudeDeg > 0):toBe(true)
				expect(spec.duration > 0):toBe(true)
				if spec.kind == "laundry" then
					laundry += 1
				else
					signs += 1
				end
			end
			expect(laundry):toBe(6)
			expect(signs):toBe(4)
		end)

		t:it("derives laundry and sign positions from MapSpec hubs", function()
			local warung = MapSpec.hub("warung")
			local pasar = MapSpec.hub("pasar")
			local first = sway[1]
			local wx, wz = MapSpec.hubPoint(warung, -1.6, warung.depth * 0.5 + 4)
			expect(first.position.x):toBe(wx)
			expect(first.position.z):toBe(wz)
			expect(first.position.y):toBe(MapSpec.GROUND_Y + warung.ridge * 0.45)
			local sign = sway[7]
			local px, pz = MapSpec.hubPoint(pasar, pasar.width * 0.28, pasar.depth * 0.5 + 3)
			expect(sign.position.x):toBe(px)
			expect(sign.position.z):toBe(pz)
			expect(sign.kind):toBe("sign")
		end)

		t:it("builds pisang/bambu tilt specs at MapSpec hubs", function()
			expect(#tilt):toBe(6)
			local species = {}
			for _, spec in ipairs(tilt) do
				species[spec.species] = true
				expect(spec.maxDeg > 0 and spec.maxDeg <= Data.MAX_TILT_DEG):toBe(true)
				expect(type(spec.seed) == "number"):toBe(true)
				expect(type(spec.position.x) == "number"):toBe(true)
				expect(type(spec.position.z) == "number"):toBe(true)
			end
			expect(species.pisang):toBe(true)
			expect(species.bambu):toBe(true)
			local warung = MapSpec.hub("warung")
			local px, pz = MapSpec.hubPoint(warung, -warung.width * 0.34, warung.depth * 0.5 + 8)
			expect(tilt[1].position.x):toBe(px)
			expect(tilt[1].position.z):toBe(pz)
			expect(tilt[1].position.y):toBe(MapSpec.GROUND_Y)
		end)

		t:it("tilts deterministically inside a few degrees", function()
			for seed = 0, 20 do
				for step = 0, 200 do
					local value = Data.tiltFor(seed, step * 0.31)
					expect(value >= -Data.MAX_TILT_DEG and value <= Data.MAX_TILT_DEG):toBe(true)
				end
			end
			expect(Data.tiltFor(3, 1.25)):toBe(Data.tiltFor(3, 1.25))
			expect(Data.tiltFor(1, 0) ~= Data.tiltFor(1, 3)):toBe(true)
			expect(Data.tiltFor(nil, nil) >= -Data.MAX_TILT_DEG):toBe(true)
		end)

		t:it("carries no engine API or asset ID in the pure module", function()
			expect(string.find(dataSrc, "game.", 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, "Enum.", 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, "Instance.", 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, "rbxassetid://", 1, true) == nil):toBe(true)
		end)
	end)

	t:describe("wind_r8 wiring, harness and applier", function()
		t:it("ships candidate 70 with a client review path", function()
			expect(#LookDev.IDS):toBe(116)
			expect(LookDev.IDS[70]):toBe("wind_r8")
			local candidate = LookDev.candidates.wind_r8
			expect(candidate.id):toBe("wind_r8")
			expect(candidate.status):toBe("candidate, awaiting designer yes")
			expect(candidate.style):toBe("cartoonish-realism")
			expect(candidate.idsSource):toBe("Shared.ModelMapWindR8")
			expect(candidate.maxWind):toBe(12)
			expect(candidate.maxTweens):toBe(30)
			local plan = LookDev.plan("wind_r8")
			expect(plan ~= nil):toBe(true)
			expect(plan.id):toBe("wind_r8")
			expect(plan.idsSource):toBe("Shared.ModelMapWindR8")
			expect(type(plan.render)):toBe("string")
			local entry = Review.paths.wind_r8
			expect(entry ~= nil):toBe(true)
			expect(entry.datamodel):toBe("client")
			expect(entry.path):toEqual({ "World", "LookDevWindR8" })
		end)

		t:it("adds three mutating client checks in their own do block", function()
			local setAt = harnessSrc:find('"WIND_SET",', 1, true)
			local tweensAt = harnessSrc:find('"SWAY_TWEENS",', 1, true)
			local restoreAt = harnessSrc:find('"WIND_RESTORE",', 1, true)
			expect(setAt ~= nil and tweensAt ~= nil and restoreAt ~= nil):toBe(true)
			expect(setAt < tweensAt and tweensAt < restoreAt):toBe(true)
			expect(harnessSrc:find("do %-%- 12a%-wind%. WORK_QUEUE section M item 85", 1) ~= nil):toBe(true)
			local blockAt = harnessSrc:find("do %-%- 12a%-wind%.", 1)
			expect(harnessSrc:find("if isClient then", blockAt, true) ~= nil):toBe(true)
			expect(harnessSrc:find('review.enable("wind_r8", game)', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("applier.tweenCount()", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("applier.baseCFrame(target)", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("1e-4", blockAt, true) ~= nil):toBe(true)
			for _, name in ipairs({ "WIND_SET", "SWAY_TWEENS", "WIND_RESTORE" }) do
				local _, emitted = string.gsub(harnessSrc, 'emit%(.-"' .. name .. '"', "")
				expect(emitted >= 2):toBe(true) -- ORDER + windFail + main emit
			end
		end)

		t:it("sets wind, tweens sway, loops tilt and restores CFrames in the applier", function()
			expect(applierSrc:find("require(Shared.ModelMapWindR8)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("workspaceService.GlobalWind = Vector3.new", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("tweenService:Create(target, info", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("heartbeat:Connect(tick)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Wind.tiltFor(entry.seed, elapsed)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("savedCFrames[target] = target.CFrame", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("savedCFrames[model] = model:GetPivot()", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("target.CFrame = base", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("target:PivotTo(base)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("workspaceService.GlobalWind = windBaseline", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("tween:Cancel()", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("heartbeatConnection:Disconnect()", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("folder:Destroy()", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("LookDev.register(Wind.id", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("rbxassetid://", 1, true) == nil):toBe(true)
		end)

		t:it("names a pending gallery row with an existing render path and fps note", function()
			local row = string.match(gallerySrc, "\n(| `wind_r8` |[^\r\n]+)")
			expect(row ~= nil):toBe(true)
			expect(string.find(row, 'LookDev.enable("wind_r8")', 1, true) ~= nil):toBe(true)
			local render = string.match(row, "`[^`]+` | [^|]+ | `[^`]+` | `([^`]+)`")
			expect(render ~= nil):toBe(true)
			expect(fs.isFile(render) or fs.isDir(render)):toBe(true)
			expect(string.find(row, "| pending", 1, true) ~= nil):toBe(true)
			expect(string.find(string.lower(row), "fps", 1, true) ~= nil):toBe(true)
		end)
	end)
end
