--!nocheck
-- T4 (DebtCollector): failure-path specs. Summon and dismiss must stay idempotent and must
-- never emit cutscene events for a collector that does not exist.

return function(t, Env, Fakes)
	local expect = t.expect

	local function makeCollectorEnv(opts)
		opts = opts or {}
		local env = Env.new()
		local plots = {}
		local created = {}
		local player = Fakes.player(env)
		if opts.hasPlot ~= false then
			plots[player] = {
				spawnCFrame = setmetatable({}, { __mul = function(a) return a end }),
			}
		end

		env.services.Workspace = {}
		env.globals.CFrame = { new = function() return {} end }
		env.globals.Vector2 = { new = function(x, y) return { X = x, Y = y } end }
		env:mock("server/Farm/PlotService", {
			getPlotOf = function(p)
				return plots[p]
			end,
		})
		env:mock("server/World/Props", {
			part = function()
				local part = { destroyed = 0, attrs = {} }
				function part:SetAttribute(k, v)
					self.attrs[k] = v
				end
				function part:Destroy()
					self.destroyed += 1
				end
				table.insert(created, part)
				return part
			end,
			billboard = function()
				return { Text = "" }
			end,
		})

		local Hooks = env:require("server/Npc/CutsceneHooks")
		local DebtCollector = env:require("server/Economy/DebtCollector")
		local events = {}
		Hooks.onDebtCollector(function(event)
			table.insert(events, event)
		end)

		return {
			env = env,
			player = player,
			DebtCollector = DebtCollector,
			events = events,
			created = created,
		}
	end

	t:describe("DebtCollector failure paths (T4)", function()
		t:it("summon without a plot creates nothing and emits nothing", function()
			local fx = makeCollectorEnv({ hasPlot = false })
			fx.DebtCollector.summon(fx.player)
			expect(fx.DebtCollector.isWaiting(fx.player)):toBe(false)
			expect(#fx.created):toBe(0)
			expect(#fx.events):toBe(0)
		end)

		t:it("summon twice keeps one collector and emits one summon event", function()
			local fx = makeCollectorEnv()
			fx.DebtCollector.summon(fx.player)
			fx.DebtCollector.summon(fx.player)
			expect(#fx.created):toBe(1)
			expect(#fx.events):toBe(1)
			expect(fx.DebtCollector.isWaiting(fx.player)):toBe(true)
		end)

		t:it("dismiss without a collector is a no-op", function()
			local fx = makeCollectorEnv()
			fx.DebtCollector.dismiss(fx.player)
			expect(#fx.events):toBe(0)
			expect(fx.DebtCollector.isWaiting(fx.player)):toBe(false)
		end)

		t:it("dismiss twice destroys once and emits once", function()
			local fx = makeCollectorEnv()
			fx.DebtCollector.summon(fx.player)
			fx.DebtCollector.dismiss(fx.player)
			fx.DebtCollector.dismiss(fx.player)
			expect(fx.created[1].destroyed):toBe(1)
			expect(#fx.events):toBe(2)
			expect(fx.events[2].state):toBe("dismissed")
			expect(fx.DebtCollector.isWaiting(fx.player)):toBe(false)
		end)

		t:it("summon after dismiss makes a fresh collector", function()
			local fx = makeCollectorEnv()
			fx.DebtCollector.summon(fx.player)
			fx.DebtCollector.dismiss(fx.player)
			fx.DebtCollector.summon(fx.player)
			expect(#fx.created):toBe(2)
			expect(fx.DebtCollector.isWaiting(fx.player)):toBe(true)
		end)
	end)
end
