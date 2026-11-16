--!nocheck
-- Phone layout spec: phone-size touch targets and basic layout rules (Track D).

return function(t, Env)
	local expect = t.expect
	local env, PhoneLayout

	t:describe("PhoneLayout", function()
		t:beforeEach(function()
			env = Env.new()
			PhoneLayout = env:require("shared/PhoneLayout")
		end)

		t:it("defines a 44px minimum touch target", function()
			expect(PhoneLayout.touchMin):toBe(44)
			expect(PhoneLayout.buttonHeight >= 44):toBe(true)
			expect(PhoneLayout.homeBarHeight >= 44):toBe(true)
		end)

		t:it("declares phone controls that meet the minimum touch target", function()
			expect(PhoneLayout.allControlsMeetTouch()):toBe(true)
			for name, control in PhoneLayout.controls do
				expect(PhoneLayout.meetsTouch(control)):toBe(true)
			end
		end)

		t:it("keeps app grid cells and list rows large enough for phone taps", function()
			expect(PhoneLayout.appGridCellMinHeight >= 44):toBe(true)
			expect(PhoneLayout.rowMinHeight >= 44):toBe(true)
			expect(PhoneLayout.controls.appTile.minHeight >= 44):toBe(true)
		end)
	end)
end
