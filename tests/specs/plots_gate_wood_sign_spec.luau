--!nocheck
-- WORK_QUEUE section P item 181: plots_r8 gate wood, one visible name sign per plot and rope/bamboo
-- detail. UNREGISTERED on purpose: the main session runs this spec standalone before/after the fix.
-- It fails on the pre-fix source (no SurfaceGui/TextLabel, no wood palette, no Studio check).
-- No Studio claim: CHECK_181.txt and any visual verdict belong to the main session.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect

	local Data = Env.new():require("shared/ModelMapPlotsR8")
	local applier = fs.readFile("src/server/World/LookDevPlotsR8.luau")
	local dataSrc = fs.readFile("src/shared/ModelMapPlotsR8.luau")
	local okCheck, checkSrc = pcall(fs.readFile, "tools/studio/check_p181.luau")
	local check = if okCheck then checkSrc else ""

	local gateParts = Data.gateParts(Data.GAP_WIDTH, Data.GATE_HEIGHT)
	local okDetail, detailSrc = pcall(Data.gateDetailParts, Data.GAP_WIDTH, Data.GATE_HEIGHT)
	local detail = if okDetail then detailSrc else {}
	local box = Data.gateBox()

	t:describe("plots_r8 gate wood, sign and detail (item 181)", function()
		t:it("keeps the gate count and clearance box unchanged", function()
			expect(Data.PLOT_COUNT):toBe(10)
			expect(#Data.plotIndices()):toBe(10)
			expect(#gateParts):toBe(4)
			expect(box):toEqual({ width = 6, height = 8, depth = 1 })
			local posts, lintels, signs = 0, 0, 0
			for _, part in ipairs(gateParts) do
				if part.kind == "gate_post" then
					posts += 1
				elseif part.kind == "gate_lintel" then
					lintels += 1
				elseif part.kind == "gate_sign" then
					signs += 1
				end
			end
			expect(posts):toBe(2)
			expect(lintels):toBe(1)
			expect(signs):toBe(1)
		end)

		t:it("declares one wood tone for the lintel and posts", function()
			local rgb = Data.GATE_WOOD_RGB
			expect(type(rgb)):toBe("table")
			expect(#rgb):toBe(3)
			for _, value in ipairs(rgb) do
				expect(type(value)):toBe("number")
				expect(value >= 0 and value <= 255):toBe(true)
			end
			expect(rgb[1] > rgb[2] and rgb[2] > rgb[3]):toBe(true)
			expect(rgb[1] - rgb[3]):toBeGreaterThan(40)
			expect(rgb[3]):toBeLessThan(80)
			expect(string.find(applier, "GATE_WOOD_COLOR", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "material = Enum.Material.WoodPlanks", 1, true) ~= nil):toBe(true)
			-- The pre-fix line made every non-sign gate part fall through to the flat cream default.
			expect(
				string.find(applier, 'gatePart.kind == "gate_sign" and { color = SIGN_COLOR } or nil', 1, true) == nil
			):toBe(true)
		end)

		t:it("attaches a real visible name sign to one gate board per plot", function()
			expect(string.find(applier, 'Instance.new("SurfaceGui")', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, 'Instance.new("TextLabel")', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "gui.Adornee = signPart", 1, true) ~= nil):toBe(true)
			expect(Data.GATE_SIGN_PREFIX):toBe("P")
			expect(string.find(applier, "label.Text = Data.GATE_SIGN_PREFIX .. tostring(index)", 1, true) ~= nil):toBe(
				true
			)
			expect(string.find(applier, "label.Visible = true", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "gate_marker", 1, true) ~= nil):toBe(true)
		end)

		t:it("places rope and bamboo detail outside the gate opening", function()
			expect(okDetail):toBe(true)
			expect(#detail):toBe(3)
			local ropes, bamboo = 0, 0
			for _, part in ipairs(detail) do
				if part.kind == "gate_rope" then
					ropes += 1
					expect(math.abs(part.lx) - part.thickness / 2 >= box.width / 2):toBe(true)
				elseif part.kind == "gate_bamboo" then
					bamboo += 1
					expect(part.ly - part.thickness / 2 >= box.height):toBe(true)
				end
			end
			expect(ropes):toBe(2)
			expect(bamboo):toBe(1)
			expect(string.find(applier, "Data.gateDetailParts(", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, '"gate_rope"', 1, true) ~= nil):toBe(true)
			expect(string.find(dataSrc, '"gate_bamboo"', 1, true) ~= nil):toBe(true)
		end)

		t:it("ships a self-contained Studio check that cannot vacuously pass", function()
			expect(okCheck):toBe(true)
			expect(string.find(check, 'enableAdditive("plots_r8", game)', 1, true) ~= nil):toBe(true)
			expect(string.find(check, "review.disableAll()", 1, true) ~= nil):toBe(true)
			expect(string.find(check, "VectorToWorldSpace(", 1, true) ~= nil):toBe(true)
			expect(string.find(check, "VectorToWorldVector", 1, true) == nil):toBe(true)
			expect(string.find(check, "GetPartBoundsInBox", 1, true) ~= nil):toBe(true)
			expect(string.find(check, "local COLOUR_TOLERANCE", 1, true) ~= nil):toBe(true)
			for _, name in ipairs({ "GATE_MATERIAL", "GATE_SIGN", "GATE_CLEAR" }) do
				expect(string.find(check, 'emit("' .. name .. '"', 1, true) ~= nil):toBe(true)
				expect(string.find(check, 'emit("' .. name .. '", false', 1, true) ~= nil):toBe(true)
			end
			expect(string.find(check, 'descendant:IsA("TextLabel")', 1, true) ~= nil):toBe(true)
			expect(string.find(check, 'parent:IsA("SurfaceGui")', 1, true) ~= nil):toBe(true)
			expect(string.find(check, 'descendant:IsA("Decal")', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "GetAttribute", 1, true) == nil):toBe(true)
			expect(string.find(applier, "part.CanCollide = false", 1, true) ~= nil):toBe(true)
		end)
	end)
end
