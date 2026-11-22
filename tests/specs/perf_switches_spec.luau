--!nocheck
-- PerfSwitches (V0.2): local, reversible rendering toggles driven through fake roots.

return function(t, Env)
	local expect = t.expect

	t:describe("PerfSwitches", function()
		local env, Module, lighting, ws, terrain, sw

		local function inst(class, props)
			local self = { ClassName = class }
			function self:IsA(name)
				return name == class
			end
			for key, value in props or {} do
				self[key] = value
			end
			return self
		end

		local function root(extra)
			local r = { _kids = {}, DescendantAdded = Env.newSignal() }
			function r:GetDescendants()
				return table.clone(self._kids)
			end
			function r:add(child)
				table.insert(self._kids, child)
				self.DescendantAdded:Fire(child)
				return child
			end
			for key, value in extra or {} do
				r[key] = value
			end
			return r
		end

		t:beforeEach(function()
			env = Env.new()
			Module = env:require("client/Feel/PerfSwitches")
			lighting = root({ GlobalShadows = true })
			ws = root()
			terrain = { Decoration = true }
			sw = Module.new({ lighting = lighting, workspace = ws, terrain = terrain })
		end)

		t:it("turns scalar switches off and restores the exact originals", function()
			terrain.Decoration = true
			lighting.GlobalShadows = true
			sw.set("shadows", false)
			sw.set("decoration", false)
			expect(lighting.GlobalShadows):toBe(false)
			expect(terrain.Decoration):toBe(false)
			sw.set("shadows", true)
			sw.set("decoration", true)
			expect(lighting.GlobalShadows):toBe(true)
			expect(terrain.Decoration):toBe(true)
		end)

		t:it("restores a scalar that started off as off", function()
			lighting.GlobalShadows = false
			sw.set("shadows", false)
			sw.set("shadows", true)
			expect(lighting.GlobalShadows):toBe(false)
		end)

		t:it("restores per-instance values, keeping ones that were already off", function()
			local a = ws:add(inst("Highlight", { Enabled = true }))
			local b = ws:add(inst("Highlight", { Enabled = false }))
			local p = ws:add(inst("ParticleEmitter", { Enabled = true }))
			local bloom = lighting:add(inst("BloomEffect", { Enabled = true }))
			local part = ws:add(inst("Part", { Enabled = true }))
			sw.set("highlights", false)
			sw.set("particles", false)
			sw.set("bloom", false)
			expect(a.Enabled):toBe(false)
			expect(p.Enabled):toBe(false)
			expect(bloom.Enabled):toBe(false)
			expect(part.Enabled):toBe(true)
			sw.set("highlights", true)
			expect(a.Enabled):toBe(true)
			expect(b.Enabled):toBe(false)
			expect(p.Enabled):toBe(false) -- other switches stay off
			sw.set("particles", true)
			sw.set("bloom", true)
			expect(p.Enabled):toBe(true)
			expect(bloom.Enabled):toBe(true)
		end)

		t:it("switches off instances added while off, and leaves them alone once on", function()
			sw.set("highlights", false)
			local late = ws:add(inst("Highlight", { Enabled = true }))
			expect(late.Enabled):toBe(false)
			sw.set("highlights", true)
			expect(late.Enabled):toBe(true)
			local after = ws:add(inst("Highlight", { Enabled = true }))
			expect(after.Enabled):toBe(true)
		end)

		t:it("is idempotent and does not overwrite remembered originals", function()
			local a = ws:add(inst("Highlight", { Enabled = true }))
			sw.set("highlights", false)
			sw.set("highlights", false)
			sw.set("shadows", false)
			sw.set("shadows", false)
			expect(lighting.GlobalShadows):toBe(false)
			sw.set("highlights", true)
			sw.set("highlights", true)
			sw.set("shadows", true)
			sw.set("shadows", true)
			expect(a.Enabled):toBe(true)
			expect(lighting.GlobalShadows):toBe(true)
		end)

		t:it("ignores unknown names and non-boolean values", function()
			sw.set("nope", false)
			sw.toggle("nope")
			sw.set("shadows", "off")
			sw.set(nil, false)
			expect(sw.get("nope")):toBe(true)
			expect(sw.get("shadows")):toBe(true)
			expect(lighting.GlobalShadows):toBe(true)
		end)

		t:it("toggle flips and get reports; restoreAll puts everything back and unwatches", function()
			local a = ws:add(inst("Highlight", { Enabled = true }))
			sw.toggle("highlights")
			sw.toggle("decoration")
			expect(sw.get("highlights")):toBe(false)
			expect(terrain.Decoration):toBe(false)
			sw.restoreAll()
			expect(a.Enabled):toBe(true)
			expect(terrain.Decoration):toBe(true)
			expect(sw.get("highlights")):toBe(true)
			expect(#ws.DescendantAdded._handlers):toBe(0)
			expect(#lighting.DescendantAdded._handlers):toBe(0)
		end)

		t:it("tolerates missing roots", function()
			local bare = Module.new({})
			bare.set("shadows", false)
			bare.set("highlights", false)
			bare.set("decoration", false)
			bare.restoreAll()
			expect(bare.get("shadows")):toBe(true)
		end)
	end)
end
