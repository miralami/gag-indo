--!nocheck
-- WORK_QUEUE item 18: NPC pathing robustness.
--
-- NpcFactory:walkTo used a fixed-step interpolation with no stall guard, no time bound and no
-- guaranteed arrival. The shared NpcWalk now detects a stuck mover, bounds travel time and pivots
-- straight to the goal as a fallback, so police and the debt collector reach every plot. These
-- cases drive the REAL NpcWalk with injectable host behaviour (LUNE-ONLY): normal arrival, stuck,
-- timeout, cancellation, unparenting, several distinct plot positions, and graceful degradation on
-- a host with no pivot API (the fake parts in debt_collector_failure_spec). A source check locks
-- that both public callers route through the shared walker.

local fs = require("@lune/fs")

return function(t, Env, Fakes)
	local expect = t.expect
	local env, Walk

	-- Minimal CFrame stand-in: new(pos) keeps .Position so the host reads back where it was told to
	-- go; composition (*) returns the left operand; lookAt only needs to accept the two vectors.
	local function cframeShim()
		local cf = {}
		cf.new = function(pos)
			local p = pos or { X = 0, Y = 0, Z = 0 }
			return setmetatable({ Position = { X = p.X, Y = p.Y, Z = p.Z } }, {
				__mul = function(a)
					return a
				end,
			})
		end
		cf.lookAt = function(at)
			return cf.new(at)
		end
		cf.Angles = function()
			return cf.new()
		end
		return cf
	end

	-- A stand-in mover with GetPivot/PivotTo. `opts.stuck` makes PivotTo a no-op; `opts.crawl`
	-- advances a fixed small step toward the commanded point (progress without arrival);
	-- otherwise it snaps exactly where commanded.
	local function makeMover(startPos, opts)
		opts = opts or {}
		local m = { Parent = {}, pivots = {} }
		local pos = { X = startPos.X, Y = startPos.Y, Z = startPos.Z }
		m.GetPivot = function()
			return { Position = { X = pos.X, Y = pos.Y, Z = pos.Z } }
		end
		m.PivotTo = function(self, cf)
			local p = cf.Position
			table.insert(self.pivots, { X = p.X, Y = p.Y, Z = p.Z })
			if opts.stuck then
				return
			end
			if opts.crawl then
				local ddx, ddz = p.X - pos.X, p.Z - pos.Z
				local mag = math.sqrt(ddx * ddx + ddz * ddz)
				if mag > 0 then
					pos = {
						X = pos.X + (ddx / mag) * opts.crawl,
						Y = p.Y,
						Z = pos.Z + (ddz / mag) * opts.crawl,
					}
				end
				return
			end
			pos = { X = p.X, Y = p.Y, Z = p.Z }
		end
		m.pos = function()
			return pos
		end
		return m
	end

	local function vec(x, y, z)
		return Env.Vector3.new(x, y, z)
	end

	t:describe("NpcWalk robustness (item 18)", function()
		t:beforeEach(function()
			env = Env.new()
			env.globals.CFrame = cframeShim()
			Walk = env:require("server/World/NpcWalk")
		end)

		t:it("arrives exactly at the goal on a normal walk", function()
			local m = makeMover(vec(0, 0, 0))
			expect(Walk.walkTo(m, vec(20, 0, 0), 14)):toBe(true)
			expect(#m.pivots > 1):toBe(true)
			local last = m.pivots[#m.pivots]
			expect(last.X):toBe(20)
			expect(last.Z):toBe(0)
		end)

		t:it("falls back to the goal when the mover is stuck", function()
			local m = makeMover(vec(0, 0, 0), { stuck = true })
			expect(Walk.walkTo(m, vec(30, 0, 0), 14)):toBe(true)
			-- Stall guard fires well before the timeout budget, and the last commanded pivot is the goal.
			expect(#m.pivots < 20):toBe(true)
			expect(m.pivots[#m.pivots].X):toBe(30)
		end)

		t:it("falls back to the goal on timeout when progress never arrives", function()
			local m = makeMover(vec(0, 0, 0), { crawl = 0.1 })
			expect(Walk.walkTo(m, vec(50, 0, 0), 14)):toBe(true)
			-- crawl (0.1/step) exceeds the stall epsilon, so this is the timeout path, not stuck:
			-- it runs past the expected step count and still ends by pivoting onto the goal.
			expect(#m.pivots > 80):toBe(true)
			expect(m.pivots[#m.pivots].X):toBe(50)
		end)

		t:it("stops without teleporting when cancelled", function()
			local m = makeMover(vec(0, 0, 0))
			local calls = 0
			local ok = Walk.walkTo(m, vec(40, 0, 0), 14, function()
				calls += 1
				return calls >= 3
			end)
			expect(ok):toBe(false)
			expect(#m.pivots):toBe(2)
			expect(m.pivots[#m.pivots].X < 40):toBe(true)
		end)

		t:it("stops without teleporting when the mover is unparented mid-walk", function()
			local m = makeMover(vec(0, 0, 0))
			local origPivot = m.PivotTo
			local count = 0
			m.PivotTo = function(self, cf)
				count += 1
				if count == 2 then
					self.Parent = nil
				end
				origPivot(self, cf)
			end
			expect(Walk.walkTo(m, vec(40, 0, 0), 14)):toBe(false)
			expect(m.pivots[#m.pivots].X < 40):toBe(true)
		end)

		t:it("reaches several distinct plot positions", function()
			for _, x in { -60, -10, 25, 90 } do
				local m = makeMover(vec(0, 0, 0))
				local z = x / 2
				expect(Walk.walkTo(m, vec(x, 0, z), 14)):toBe(true)
				local last = m.pivots[#m.pivots]
				expect(last.X):toBe(x)
				expect(last.Z):toBe(z)
			end
		end)

		t:it("degrades to a no-op on a host with no pivot API", function()
			expect(Walk.walkTo({}, vec(1, 0, 0), 14)):toBe(false)
		end)

		t:it("reads position fields regardless of the type name (native vector analogue)", function()
			-- A Studio Vector3 is a native `vector`: type() is neither "table" nor "userdata".
			-- Override type() in a fresh module env to report "vector" for position-shaped tables:
			-- the old type-name guard would bail here, the pcall-based field read does not.
			local e = Env.new()
			local realType = type
			e.globals.type = function(v)
				if realType(v) == "table" and realType(v.X) == "number" then
					return "vector"
				end
				return realType(v)
			end
			e.globals.CFrame = cframeShim()
			local walk = e:require("server/World/NpcWalk")
			local m = makeMover(vec(0, 0, 0))
			expect(walk.walkTo(m, vec(15, 0, 0), 14)):toBe(true)
			expect(m.pivots[#m.pivots].X):toBe(15)
		end)
	end)

	t:describe("NPC walkers route through the shared walker (item 18)", function()
		t:it("NpcFactory:walkTo and DebtCollector.summon both call NpcWalk.walkTo", function()
			local factory = fs.readFile("src/server/World/NpcFactory.luau")
			local collector = fs.readFile("src/server/Economy/DebtCollector.luau")
			expect(string.find(factory, "NpcWalk.walkTo", 1, true) ~= nil):toBe(true)
			expect(string.find(collector, "NpcWalk.walkTo", 1, true) ~= nil):toBe(true)
		end)
	end)
end
