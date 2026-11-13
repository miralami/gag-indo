--!nocheck
-- Visuals spec: tests shared/Config/Visuals (palette hex, type scale, space, icons, ASCII fallbacks).

local EXPECTED_PALETTE = {
	"kertas",
	"tinta",
	"tinta_lembut",
	"senja",
	"padi",
	"daun",
	"genteng",
	"merah",
	"bambu",
	"kunyit",
	"indigo",
	"malam",
	"ungu",
}

return function(t, Env)
	local expect = t.expect
	local env, Visuals, Strings

	t:describe("Visuals & Art Tokens", function()
		t:beforeEach(function()
			env = Env.new()
			Visuals = env:require("shared/Config/Visuals")
			Strings = env:require("shared/Strings")
		end)

		t:it("contains all ART.md palette tokens as valid 6-char hex strings", function()
			for _, name in EXPECTED_PALETTE do
				local hex = Visuals.palette[name]
				expect(hex ~= nil):toBe(true)
				expect(type(hex)):toBe("string")
				expect(#hex):toBe(6)
				expect(hex:match("^[0-9a-fA-F]+$") ~= nil):toBe(true)
			end
		end)

		t:it("matches ART.md type and spacing scale specifications", function()
			expect(Visuals.type.display):toBe(28)
			expect(Visuals.type.heading):toBe(18)
			expect(Visuals.type.body):toBe(13)
			expect(Visuals.type.small):toBe(11)

			expect(Visuals.space.xs):toBe(4)
			expect(Visuals.space.sm):toBe(8)
			expect(Visuals.space.md):toBe(12)
			expect(Visuals.space.lg):toBe(16)
			expect(Visuals.space.xl):toBe(24)
			expect(Visuals.space.xxl):toBe(32)

			expect(Visuals.outline):toBe(2)
			expect(Visuals.shadow):toBe(4)
			expect(Visuals.touch):toBe(44)
		end)

		t:it("defines a valid rarity visual for every tier", function()
			local tiers = env:require("shared/Config/Tiers")
			for _, id in tiers.order do
				local rarity = Visuals.rarity[id]
				expect(rarity ~= nil):toBe(true)
				expect(Visuals.palette[rarity.token] ~= nil):toBe(true)
				expect(type(rarity.frame)):toBe("string")
				expect(type(rarity.effect)):toBe("string")
			end
		end)

		t:it("specifies mobile-tested display and body fonts", function()
			expect(Visuals.fonts.display):toBe("LuckiestGuy")
			expect(Visuals.fonts.body):toBe("Nunito")
		end)

		t:it("registers icon slots with id 0, valid palette tokens, and ASCII fallbacks", function()
			local count = 0
			for name, icon in Visuals.icons do
				count += 1
				expect(icon.id):toBe(0)
				expect(type(icon.text)):toBe("string")
				expect(#icon.text > 0):toBe(true)
				expect(icon.text:match("^[%w%p%s]+$") ~= nil):toBe(true)
				expect(Visuals.palette[icon.token] ~= nil):toBe(true)
			end
			expect(count >= 20):toBe(true)
		end)

		t:it("ensures every string key has both non-empty id and en fields", function()
			local count = 0
			for key, entry in Strings.raw do
				count += 1
				expect(type(entry.id)):toBe("string")
				expect(#entry.id > 0):toBe(true)
				expect(type(entry.en)):toBe("string")
				expect(#entry.en > 0):toBe(true)
			end
			expect(count >= 80):toBe(true)
		end)

		t:it("ensures Strings table contains no 4-byte UTF-8 emoji", function()
			for key, entry in Strings.raw do
				for lang, text in entry do
					for i = 1, #text do
						local b = string.byte(text, i)
						expect(b >= 0xF0 and b <= 0xF4):toBe(false)
					end
				end
			end
		end)
	end)
end
