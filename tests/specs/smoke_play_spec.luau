--!nocheck
-- WORK_QUEUE section N item 107: guards for tools/studio/smoke_play.luau (clean-Play smoke test).
-- Source-string guards only: no Studio claim. The real SMOKE_CLEAN PASS for the default look and
-- full_r9 belongs to the main session / CHECK_107.txt evidence.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect
	Env.new()
	local src = fs.readFile("tools/studio/smoke_play.luau")

	t:describe("item 107 clean-Play smoke harness", function()
		t:it("exposes SMOKE_CLEAN in ORDER with an emit and byName return", function()
			expect(src:find('"SMOKE_CLEAN"', 1, true) ~= nil):toBe(true)
			expect(src:find('emit%("SMOKE_CLEAN"', 1) ~= nil):toBe(true)
			expect(src:find("byName", 1, true) ~= nil):toBe(true)
			expect(src:find("return { order = ORDER", 1, true) ~= nil):toBe(true)
		end)

		t:it("reads console lines fed by the main session, not a fake built-in log", function()
			expect(src:find("_G.SMOKE_CONSOLE_LINES", 1, true) ~= nil):toBe(true)
			expect(src:find("get_console_output", 1, true) ~= nil):toBe(true)
			expect(src:find("60 s", 1, true) ~= nil):toBe(true)
		end)

		t:it("keeps a short allowlist; every entry carries a one-line reason", function()
			expect(src:find("local ALLOWLIST = {", 1, true) ~= nil):toBe(true)
			local _, texts = string.gsub(src, 'text = "', "")
			local _, reasons = string.gsub(src, 'reason = "', "")
			expect(texts >= 3 and texts <= 8):toBe(true)
			expect(reasons >= texts):toBe(true)
		end)

		t:it("allowlists only documented noise, never the smoke_r8 emitter bug", function()
			for _, text in ipairs({
				"[JuraganDesa] server started",
				"[ProfileStore]: Roblox API services available - data will be saved",
				"Assistant plugin version changed from",
				"ContentId: rbxassetid://203785492 failed due to: Asset type does not match requested type",
				"ShippingLookR7: no PlotAnchor parts within 10 s; only flower beds painted",
			}) do
				expect(src:find(text, 1, true) ~= nil):toBe(true)
			end
			-- The real errors fixed under this item must never be hidden by an allowlist entry.
			expect(src:find("smoke_r8: could not build ParticleEmitter", 1, true) == nil):toBe(true)
			expect(src:find("NumberSequence expected", 1, true) == nil):toBe(true)
		end)

		t:it("fails on any non-allowlisted line (no info bucket that ignores output)", function()
			expect(src:find("violations%[#violations %+ 1%] = line", 1) ~= nil):toBe(true)
			expect(src:find("local ok = %(#violations == 0%)", 1) ~= nil):toBe(true)
			expect(src:find('emit%("SMOKE_CLEAN", ok, #violations, 0', 1) ~= nil):toBe(true)
		end)
	end)
end
