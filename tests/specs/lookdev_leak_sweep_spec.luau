--!nocheck
-- WORK_QUEUE item 219: LUNE-ONLY contract for tools/studio/check_q219.luau. The self-contained
-- SERVER-VM harness stages and unstages every Shared.LookDev.IDS entry, snapshots Workspace and
-- Lighting descendant signatures, proves the leak detector with an injected leftover part, and
-- restores the prior active candidate. No Studio call, no place save, no visual verdict here.

local fs = require("@lune/fs")

local CHECK = "tools/studio/check_q219.luau"
local AGGREGATE_NAMES = {
	"LOOKDEV_LEAK",
	"LOOKDEV_IDS_SWEPT",
	"LOOKDEV_CLIENT_SKIP",
	"CAL_LOOKDEV_LEAK_FAIL",
}

return function(t, Env)
	local expect = t.expect
	local env = Env.new()
	local LookDev = env:require("shared/LookDev")
	local Review = env:require("shared/LookDevReview")
	local checkSrc = fs.readFile(CHECK)

	local ids, clients, servers = {}, 0, 0
	for _, id in ipairs(LookDev.IDS) do
		ids[id] = (ids[id] or 0) + 1
		local entry = Review.pathsFor(id)
		if entry and entry.datamodel == "client" then
			clients += 1
		elseif entry and entry.datamodel == "server" then
			servers += 1
		end
	end

	t:describe("item 219 LookDev leak sweep", function()
		t:it("declares every LookDev id once with a client or server review path", function()
			expect(#LookDev.IDS > 0):toBe(true)
			expect(clients + servers):toBe(#LookDev.IDS)
			expect(servers > 0):toBe(true)
			expect(clients > 0):toBe(true)
			for id, count in pairs(ids) do
				expect(count):toBe(1)
				expect(type(id) == "string" and #id > 0):toBe(true)
				expect(Review.pathsFor(id) ~= nil):toBe(true)
			end
			expect(type(Review.enableAdditive) == "function"):toBe(true)
			expect(type(Review.disableAll) == "function"):toBe(true)
		end)

		t:it("emits aggregate, per-id, anti-vacuity, skip and calibration CHECK lines", function()
			for _, name in ipairs(AGGREGATE_NAMES) do
				expect(checkSrc:find('"' .. name .. '"', 1, true) ~= nil):toBe(true)
			end
			expect(checkSrc:find('"LOOKDEV_LEAK_" .. upper', 1, true) ~= nil):toBe(true)
			expect(checkSrc:find("string.upper(id)", 1, true) ~= nil):toBe(true)
			expect(checkSrc:find('emit("LOOKDEV_LEAK", leakPass', 1, true) ~= nil):toBe(true)
			expect(checkSrc:find('emit("LOOKDEV_IDS_SWEPT", sweptPass', 1, true) ~= nil):toBe(true)
			expect(checkSrc:find('emit("LOOKDEV_CLIENT_SKIP", skipPass', 1, true) ~= nil):toBe(true)
			expect(checkSrc:find('emit("CAL_LOOKDEV_LEAK_FAIL",', 1, true) ~= nil):toBe(true)
			expect(checkSrc:find("emitOnce(name, false", 1, true) ~= nil):toBe(true)
		end)

		t:it("snapshots both containers and diffs descendant signatures across disableAll", function()
			expect(checkSrc:find('signature("Workspace")', 1, true) ~= nil):toBe(true)
			expect(checkSrc:find('signature("Lighting")', 1, true) ~= nil):toBe(true)
			expect(checkSrc:find("GetDescendants()", 1, true) ~= nil):toBe(true)
			expect(checkSrc:find("instance:GetFullName()", 1, true) ~= nil):toBe(true)
			expect(checkSrc:find("diffSignatures(before, after)", 1, true) ~= nil):toBe(true)
			expect(checkSrc:find("review.enableAdditive", 1, true) ~= nil):toBe(true)
			expect(checkSrc:find("review.enable, id, game", 1, true) ~= nil):toBe(true)
			expect(checkSrc:find("pcall(review.disableAll)", 1, true) ~= nil):toBe(true)
			expect(checkSrc:find("local before = snapshot() -- baseline must be read before staging", 1, true) ~= nil):toBe(
				true
			)
		end)

		t:it("fails a vacuous sweep and reports client skips separately", function()
			expect(checkSrc:find("expectedSwept <= 0", 1, true) ~= nil):toBe(true)
			expect(checkSrc:find("expectedSwept = #ids - skipped", 1, true) ~= nil):toBe(true)
			expect(checkSrc:find("local skipTarget = clientExpected - clientStaged", 1, true) ~= nil):toBe(true)
			expect(checkSrc:find("clientStaged += 1", 1, true) ~= nil):toBe(true)
			expect(checkSrc:find('entry.datamodel == "client"', 1, true) ~= nil):toBe(true)
		end)

		t:it("keeps the non-vacuous FAIL anchor, cleanup and prior-candidate restore", function()
			expect(checkSrc:find("injectLeftover()", 1, true) ~= nil):toBe(true)
			expect(checkSrc:find('"Q219_LEAK_CALIBRATION"', 1, true) ~= nil):toBe(true)
			expect(checkSrc:find('"Q219LeakCalibration"', 1, true) ~= nil):toBe(true)
			expect(checkSrc:find("calDelta >= 1", 1, true) ~= nil):toBe(true)
			expect(checkSrc:find("destroyInjected()", 1, true) ~= nil):toBe(true)
			expect(checkSrc:find("LookDev.current()", 1, true) ~= nil):toBe(true)
			expect(checkSrc:find("LookDev.enable(priorId)", 1, true) ~= nil):toBe(true)
			expect(checkSrc:find("restoreAttempted", 1, true) ~= nil):toBe(true)
		end)
	end)
end
