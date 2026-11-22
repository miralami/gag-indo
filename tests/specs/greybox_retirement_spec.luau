--!nocheck
-- Greybox retirement specs. The real Village and Map modules run here. Greybox is a spy so the
-- "was the generator called" question is exact, and the tagged designer world is faked so the
-- binding path can be checked without a live Roblox world. These lock the contract proven in
-- docs/v2/evidence/h/2026-11-19-greybox-retirement/: Greybox is only a fallback for places that
-- have no designer map; with a designer world the same six hubs bind from tags alone.

return function(t, Env, Fakes)
	local expect = t.expect

	local TAGS = {
		World = "VillageWorld",
		Greybox = "GreyboxWorld",
		PlayerSpawn = "PlayerSpawn",
		Pasar = "PasarPrompt",
		Gelap = "GelapPrompt",
		PakRT = "PakRTPrompt",
		Polisi = "PolisiPrompt",
		Warung = "WarungPrompt",
		Ronda = "RondaAnchor",
		PlotAnchor = "PlotAnchor",
		Npc = "NpcSpawn",
		Tile = "Tile",
	}

	local function mkPart(pos)
		local node = { ClassName = "BasePart", Position = pos, Parent = {}, _attrs = {} }
		function node:IsA(cls)
			return cls == "BasePart"
		end
		function node:GetAttribute(k)
			return self._attrs[k]
		end
		function node:SetAttribute(k, v)
			self._attrs[k] = v
		end
		return node
	end

	local function mkPrompt(parent)
		local node = {
			ClassName = "ProximityPrompt",
			Parent = parent,
			_attrs = {},
			Triggered = Env.newSignal(),
		}
		function node:IsA(cls)
			return cls == "ProximityPrompt"
		end
		function node:GetAttribute(k)
			return self._attrs[k]
		end
		function node:SetAttribute(k, v)
			self._attrs[k] = v
		end
		return node
	end

	local function mkNpc(role, pos)
		local node = { ClassName = "Model", Parent = {}, _attrs = { Npc = role } }
		function node:IsA(cls)
			return cls == "Model"
		end
		function node:GetAttribute(k)
			return self._attrs[k]
		end
		function node:SetAttribute(k, v)
			self._attrs[k] = v
		end
		function node:GetPivot()
			return { Position = pos }
		end
		return node
	end

	-- Build a Village whose Map/Greybox/NpcFactory are controlled, then populate the tag buckets.
	local function setup()
		local env = Env.new()
		local state = { tagged = {}, designer = false, greyboxCalls = 0 }
		env:mock("server/World/Map", {
			TAGS = TAGS,
			all = function(tag)
				return state.tagged[tag] or {}
			end,
			has = function(tag)
				return #(state.tagged[tag] or {}) > 0
			end,
			first = function(tag)
				return (state.tagged[tag] or {})[1]
			end,
			isDesignerWorld = function()
				return state.designer
			end,
			add = function() end,
		})
		env:mock("server/World/Greybox", {
			build = function()
				state.greyboxCalls += 1
				return {}
			end,
		})
		env:mock("server/World/NpcFactory", {
			wrap = function(model)
				return { model = model }
			end,
		})
		return env, state, env:require("server/World/Village")
	end

	local PROMPT_HUBS = {
		{ tag = TAGS.Pasar, name = "pasar" },
		{ tag = TAGS.Gelap, name = "gelap" },
		{ tag = TAGS.PakRT, name = "pakrt" },
		{ tag = TAGS.Polisi, name = "polisi" },
		{ tag = TAGS.Warung, name = "warung" },
	}

	local function addDesignerWorld(state)
		local expectPos = {}
		for i, hub in PROMPT_HUBS do
			local pos = Env.Vector3.new(i * 10, 2, i * 20)
			local parent = mkPart(pos)
			local prompt = mkPrompt(parent)
			state.tagged[hub.tag] = { prompt }
			expectPos[hub.name] = pos
		end
		local rondaPos = Env.Vector3.new(99, 2, 99)
		state.tagged[TAGS.Ronda] = { mkPart(rondaPos) }
		expectPos.ronda = rondaPos
		state.tagged[TAGS.Npc] = {
			mkNpc("pakrt", Env.Vector3.new(1, 0, 1)),
			mkNpc("tengkulak", Env.Vector3.new(2, 0, 2)),
			mkNpc("polisi", Env.Vector3.new(3, 0, 3)),
		}
		return expectPos
	end

	t:describe("Greybox retirement - Map.isDesignerWorld", function()
		local function realMapWithTags(tagged)
			local env = Env.new()
			env.services.CollectionService = {
				GetTagged = function(_, tag)
					return tagged[tag] or {}
				end,
			}
			return env:require("server/World/Map")
		end

		t:it("is false when the place has neither a VillageWorld nor a PlotAnchor", function()
			local Map = realMapWithTags({})
			expect(Map.isDesignerWorld()):toBe(false)
		end)

		t:it("is true when the place has a VillageWorld tag", function()
			local Map = realMapWithTags({ VillageWorld = { {} } })
			expect(Map.isDesignerWorld()):toBe(true)
		end)

		t:it("is true when the place has a PlotAnchor tag", function()
			local Map = realMapWithTags({ PlotAnchor = { {} } })
			expect(Map.isDesignerWorld()):toBe(true)
		end)
	end)

	t:describe("Greybox retirement - Village.build fallback", function()
		t:it("calls Greybox.build only when no designer world is present", function()
			local _, state, Village = setup()
			state.designer = false
			Village.build()
			expect(state.greyboxCalls):toBe(1)
			state.designer = true
			Village.build()
			expect(state.greyboxCalls):toBe(1)
		end)

		t:it("does not touch Greybox for a designer world and binds all six hubs from tags", function()
			local _, state, Village = setup()
			state.designer = true
			local expectPos = addDesignerWorld(state)
			Village.build()
			expect(state.greyboxCalls):toBe(0)
			for name, want in expectPos do
				local got = Village.positions[name]
				expect(got ~= nil):toBe(true)
				expect((got - want).Magnitude < 0.0001):toBe(true)
			end
			local prompts = 0
			for _ in pairs(Village.prompts) do
				prompts += 1
			end
			expect(prompts):toBe(5)
			expect(Village.pakrt ~= nil):toBe(true)
			expect(Village.tengkulak ~= nil):toBe(true)
			expect(#Village.police):toBe(1)
		end)

		t:it("rebind does not double-connect a designer prompt (hot reload safe)", function()
			local _, state, Village = setup()
			state.designer = true
			addDesignerWorld(state)
			Village.build()
			local prompt = state.tagged[TAGS.Pasar][1]
			expect(#prompt.Triggered._handlers):toBe(1)
			Village.build()
			expect(#prompt.Triggered._handlers):toBe(1)
			expect(Village.prompts.pasar == prompt):toBe(true)
		end)
	end)
end
