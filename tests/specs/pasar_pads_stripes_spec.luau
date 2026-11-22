--!nocheck
-- WORK_QUEUE section P item 179: Pasar lapak pads and awning stripes.
-- Pad materials are checked as ACTUALLY STAGED (ModelMapPasarGroundR8.PAD_MATERIALS drives the R8
-- applier); the legacy Slate tokens in MATERIALS are intentionally left for the item-109 contract.
-- No Studio claim: CHECK evidence, tracker ticks and the visual verdict belong to the main session.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect

	local env = Env.new()
	local Awning = env:require("shared/ModelMapPasarAwningsR8")
	local Ground = env:require("shared/ModelMapPasarGroundR8")
	local awningApplierSrc = fs.readFile("src/server/World/LookDevPasarAwningsR8.luau")
	local groundApplierSrc = fs.readFile("src/server/World/LookDevPasarGroundR8.luau")

	local function hsvValue(rgb)
		return math.max(rgb[1], rgb[2], rgb[3]) / 255
	end

	t:describe("p179 pad materials", function()
		t:it("uses only Ground, Cobblestone or Pavement on every staged pad", function()
			local allowed = Ground.ALLOWED_PAD_MATERIALS
			expect(type(allowed)):toBe("table")
			expect(allowed.Ground):toBe(true)
			expect(allowed.Cobblestone):toBe(true)
			expect(allowed.Pavement):toBe(true)
			expect(allowed.SmoothPlastic):toBe(nil)
			expect(allowed.Slate):toBe(nil)

			expect(type(Ground.PAD_MATERIALS)):toBe("table")
			for _, kind in ipairs(Ground.KINDS) do
				local staged = Ground.PAD_MATERIALS[kind]
				expect(type(staged)):toBe("string")
				expect(allowed[staged]):toBe(true)
			end
			expect(allowed[Awning.MATERIALS.base]):toBe(true)
			expect(groundApplierSrc:find("Data.PAD_MATERIALS", 1, true) ~= nil):toBe(true)
			expect(awningApplierSrc:find("Data.PAD_COLOUR", 1, true) ~= nil):toBe(true)
		end)
	end)

	t:describe("p179 awning stripes and stalls", function()
		t:it("keeps every red/white/blue stripe at HSV value >= 0.6", function()
			for _, name in ipairs(Awning.STRIPE_ORDER) do
				local rgb = Awning.COLOURS[name]
				expect(type(rgb)):toBe("table")
				expect(#rgb):toBe(3)
				expect(hsvValue(rgb)):toBeAtLeast(0.6)
			end
			local stripes = Awning.stripeParts()
			expect(#stripes):toBeGreaterThan(0)
			for _, stripe in ipairs(stripes) do
				expect(hsvValue(Awning.COLOURS[stripe.colour])):toBeAtLeast(0.6)
			end
		end)

		t:it("still stages at least ten lapak stalls", function()
			expect(#Awning.stalls()):toBeAtLeast(10)
			expect(Awning.count()):toBeAtLeast(10)
		end)
	end)
end
