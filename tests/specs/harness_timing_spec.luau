--!nocheck
-- WORK_QUEUE item 26 (test-suite health): characterizes the timing instrumentation added to the
-- tiny test framework. Timing is diagnostic output only, so these checks assert the contract
-- (keys populated, pass/fail unchanged, filter respected) without asserting wall-clock magnitudes
-- that would be flaky on a busy machine.

local Test = require("../lib/Test")

return function(t, Env, Fakes)
	local expect = t.expect

	local function tinyHarness()
		local h = Test.new()
		local suiteA, suiteB
		h:describe("Alpha", function()
			suiteA = h.suites[#h.suites]
			h:it("passes", function() end)
			h:it("also passes", function() end)
		end)
		h:describe("Beta", function()
			suiteB = h.suites[#h.suites]
			h:it("fails on purpose", function() error("boom") end)
		end)
		return h, suiteA, suiteB
	end

	t:describe("harness timing instrumentation (item 26)", function()
		t:it("run() still returns the same passed/failed/failure contract", function()
			local h = tinyHarness()
			local logs = {}
			local passed, failed, failures = h:run(nil, function(line)
				logs[#logs + 1] = line
			end)
			expect(passed):toBe(2)
			expect(failed):toBe(1)
			expect(#failures):toBe(1)
			expect(string.find(failures[1], "fails on purpose", 1, true) ~= nil):toBeTruthy()
			-- log strings are unchanged: suite headers plus PASS/FAIL lines, no timing text.
			local foundPass, foundFail = false, false
			for _, line in logs do
				if line == "  PASS  passes" then foundPass = true end
				if line == "  FAIL  fails on purpose" then foundFail = true end
				expect(string.find(line, "<== SLOW", 1, true) == nil):toBeTruthy()
			end
			expect(foundPass and foundFail):toBeTruthy()
		end)

		t:it("records a non-negative duration for every executed case and suite, plus a total", function()
			local h, suiteA, suiteB = tinyHarness()
			h:run(nil, function() end)
			expect(type(h.totalSeconds) == "number"):toBeTruthy()
			expect(h.totalSeconds >= 0):toBeTruthy()

			local casesSeen = 0
			for _, suite in h.suites do
				local suiteSeconds = h.suiteSeconds[suite]
				expect(type(suiteSeconds) == "number" and suiteSeconds >= 0):toBeTruthy()
				for _, case in suite.cases do
					local seconds = h.caseSeconds[case]
					expect(type(seconds) == "number" and seconds >= 0):toBeTruthy()
					casesSeen += 1
				end
			end
			expect(casesSeen):toBe(3)
			expect(suiteA ~= nil and suiteB ~= nil):toBeTruthy()
		end)

		t:it("a filtered run only times the cases it executed", function()
			local h, suiteA, suiteB = tinyHarness()
			local passed = h:run("alpha", function() end)
			expect(passed):toBe(2)
			-- Only Alpha's two cases were timed; Beta was filtered out entirely.
			local caseCount = 0
			for _, case in suiteA.cases do
				if h.caseSeconds[case] ~= nil then caseCount += 1 end
			end
			local excluded = 0
			for _, case in suiteB.cases do
				if h.caseSeconds[case] ~= nil then excluded += 1 end
			end
			expect(caseCount):toBe(2)
			expect(excluded):toBe(0)
			expect(h.suiteSeconds[suiteA] ~= nil):toBeTruthy()
			expect(h.suiteSeconds[suiteB] == nil):toBeTruthy()
		end)
	end)
end
