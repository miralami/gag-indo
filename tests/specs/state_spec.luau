--!nocheck
-- shared/State is the wire format between the server and the client store.
-- A missing or leaking section here shows up as a stale HUD, so test both.

return function(t, Env)
	local expect = t.expect
	local env, State, Produce

	local function baseData()
		return {
			produce = {},
			items = { seed_padi = 3, amplopPremium = 1 },
			tools = { cangkul = true },
			gudang = { capacity = 40, stacks = {} },
			debt = { active = false, owed = 0 },
			quests = { daily = {}, loginStreak = 2 },
			almanak = { padi = { harvested = 4 } },
			story = { chapter = 1, flags = { metPakRt = true } },
		}
	end

	t:describe("State", function()
		t:beforeEach(function()
			env = Env.new()
			State = env:require("shared/State")
			Produce = env:require("shared/Produce")
		end)

		t:describe("sections", function()
			t:it("knows every section it advertises", function()
				for _, name in State.SECTIONS do
					expect(State.isSection(name)):toBe(true)
				end
			end)

			t:it("rejects unknown section names", function()
				expect(State.isSection("cash")):toBe(false)
				expect(State.isSection("produce ")):toBe(false)
				expect(State.isSection(nil)):toBe(false)
			end)

			t:it("returns nil for an unknown section", function()
				expect(State.section(baseData(), "nope")):toBeNil()
			end)

			t:it("builds a produce snapshot", function()
				local data = baseData()
				Produce.add(data.produce, "padi", 1)
				local section = State.section(data, "produce")
				expect(section[Produce.key("padi", "biasa", {})].count):toBe(1)
				-- Must be a copy: the client gets data, not a handle on the save.
				section[Produce.key("padi", "biasa", {})].count = 7
				expect(Produce.count(data.produce)):toBe(1)
			end)

			t:it("builds an items snapshot from the generic bag", function()
				local section = State.section(baseData(), "items")
				expect(section.seed_padi):toBe(3)
				expect(section.amplopPremium):toBe(1)
			end)

			t:it("defaults missing sections to an empty table instead of nil", function()
				local section = State.section({}, "debt")
				expect(type(section)):toBe("table")
				expect(next(section)):toBeNil()
			end)

			t:it("copies nested section data", function()
				local data = baseData()
				local section = State.section(data, "story")
				section.flags.metPakRt = false
				expect(data.story.flags.metPakRt):toBe(true)
			end)

			t:it("never sends a table reference back to the save", function()
				local data = baseData()
				local section = State.section(data, "quests")
				section.loginStreak = 0
				expect(data.quests.loginStreak):toBe(2)
			end)
		end)

		t:describe("snapshot", function()
			t:it("includes every advertised section and a version", function()
				local snapshot = State.snapshot(baseData())
				expect(snapshot.version):toBe(State.VERSION)
				for _, name in State.SECTIONS do
					expect(snapshot.sections[name] ~= nil):toBe(true)
				end
			end)
		end)

		t:describe("patch", function()
			t:it("only includes the named sections", function()
				local patch = State.patch(baseData(), { produce = true, items = true })
				expect(patch.produce ~= nil):toBe(true)
				expect(patch.items ~= nil):toBe(true)
				expect(patch.story):toBeNil()
			end)

			t:it("ignores unknown names", function()
				local patch = State.patch(baseData(), { cash = true })
				expect(next(patch)):toBeNil()
			end)

			t:it("returns an empty table when nothing changed", function()
				local patch = State.patch(baseData(), {})
				expect(next(patch)):toBeNil()
			end)
		end)
	end)
end
