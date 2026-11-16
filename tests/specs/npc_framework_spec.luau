--!nocheck
-- NPC framework spec: caricature archetypes (design cards) and raid/debt cutscene hooks.

return function(t, Env)
	local expect = t.expect
	local env, Archetypes, Hooks

	t:describe("Npc framework", function()
		t:beforeEach(function()
			env = Env.new()
			Archetypes = env:require("shared/Config/NpcArchetypes")
			Hooks = env:require("server/Npc/CutsceneHooks")
			Hooks._reset()
		end)

		t:it("defines the three caricature NPC archetypes from the design card", function()
			expect(#Archetypes.order):toBe(3)
			for _, id in { "pakrt", "tengkulak", "polisi" } do
				local card = Archetypes.get(id)
				expect(card ~= nil):toBe(true)
				expect(card.id):toBe(id)
				expect(type(card.displayName) == "string" and #card.displayName > 0):toBe(true)
				expect(type(card.silhouette) == "string" and #card.silhouette > 0):toBe(true)
				expect(type(card.exaggeratedFeature) == "string" and #card.exaggeratedFeature > 0):toBe(true)
				expect(type(card.accessory) == "string" and #card.accessory > 0):toBe(true)
				expect(type(card.voice) == "string" and #card.voice > 0):toBe(true)
				expect(#card.outfit):toBe(3)
				expect(Archetypes.isFictionalCaricature(id)):toBe(true)
			end
			expect(Archetypes.isFictionalCaricature("unknown")):toBe(false)
		end)

		t:it("emits raid phase hooks for cutscene logic", function()
			local events = {}
			local off = Hooks.onRaid(function(event)
				table.insert(events, event)
			end)
			local player = { Name = "Tester" }
			Hooks.emitRaid({ kind = "raid", player = player, phase = "incoming", isViral = false })
			Hooks.emitRaid({ kind = "raid", player = player, phase = "choosing", isViral = false })
			Hooks.emitRaid({ kind = "raid", player = player, phase = "jail", isViral = false, outcome = "jail" })
			expect(#events):toBe(3)
			expect(events[1].phase):toBe("incoming")
			expect(events[2].phase):toBe("choosing")
			expect(events[3].outcome):toBe("jail")
			off()
			Hooks.emitRaid({ kind = "raid", player = player, phase = "cooldown" })
			expect(#events):toBe(3)
		end)

		t:it("emits debt collector state hooks for cutscene logic", function()
			local events = {}
			Hooks.onDebtCollector(function(event)
				table.insert(events, event)
			end)
			local player = { Name = "Debtor" }
			Hooks.emitDebtCollector({ kind = "debt_collector", player = player, state = "summoned", waiting = true })
			Hooks.emitDebtCollector({ kind = "debt_collector", player = player, state = "dismissed", waiting = false })
			expect(#events):toBe(2)
			expect(events[1].state):toBe("summoned")
			expect(events[1].waiting):toBe(true)
			expect(events[2].state):toBe("dismissed")
			expect(events[2].waiting):toBe(false)
		end)

		t:it("a throwing listener does not break the emitter or later listeners", function()
			Hooks._reset()
			local got = 0
			Hooks.onRaid(function()
				error("boom")
			end)
			Hooks.onRaid(function()
				got += 1
			end)
			Hooks.emitRaid({ kind = "raid", player = { Name = "T" }, phase = "incoming" })
			expect(got):toBe(1)
			Hooks._reset()
		end)
	end)
end
