--!nocheck
-- Mid-minigame Cancel (BUG-013): both the Cancel button and the Minigame_Cancel remote must
-- wire to close(), and close() must hide the scrim. The 2026-11-19 "cancel did not close the
-- overlay" observation was traced to hand-injected, unsynced sources, not a code defect;
-- this static guard locks the wiring so it cannot silently regress. Studio re-check:
-- docs/v2/evidence/h/2026-11-19-gate1-sweep/.

local fs = require("@lune/fs")

local MINIGAME = "src/client/UI/Minigame.luau"

return function(t, Env, Fakes)
	local expect = t.expect

	t:describe("Minigame Cancel wiring (BUG-013)", function()
		local src

		t:beforeEach(function()
			src = fs.readFile(MINIGAME)
		end)

		t:it("close() hides the scrim", function()
			expect(string.find(src, "scrim.Visible = false", 1, true) ~= nil):toBe(true)
		end)

		t:it("wires the Cancel button to close()", function()
			expect(string.find(src, "cancel.Activated:Connect(close)", 1, true) ~= nil):toBe(true)
		end)

		t:it("wires the Minigame_Cancel remote to close()", function()
			expect(string.find(src, "Remotes.Minigame_Cancel.OnClientEvent:Connect(close)", 1, true) ~= nil):toBe(true)
		end)
	end)
end
