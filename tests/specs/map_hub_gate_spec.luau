-- MapHubGate (map layout v1): which Greybox hubs and road strips are hidden once the place
-- carries hub 3D models in Workspace.JuraganMap.Hubs. The pure plan() is checked here; apply()
-- is a thin Roblox wrapper and is seen in Studio (docs/v2/evidence/map_layout_v1/).
return function(t, Env)
	local expect = t.expect

	local WORLD = {
		"GroundNorth",
		"Spawn",
		"Pasar",
		"TengkulakGelap",
		"Warung",
		"PosPolisi",
		"RumahPakRT",
		"PosRonda",
		"Pak RT",
		"Plot_1",
		"RingRoad",
		"RingRoad",
		"RoadEast",
		"RoadEdge",
		"Decor",
		"Details",
		"Flora",
		"Tree_1",
	}

	local function has(list, name)
		for _, v in list do
			if v == name then
				return true
			end
		end
		return false
	end

	t:describe("MapHubGate.plan", function()
		t:it("hides nothing when the place has no hub models", function()
			local Gate = Env.new():require("server/World/MapHubGate")
			expect(#Gate.plan({}, WORLD)):toBe(0)
			expect(#Gate.plan({ kebun = true, plaza = true }, WORLD)):toBe(0)
		end)

		t:it("hides only the hubs that have a model, plus roads and hub dressing", function()
			local Gate = Env.new():require("server/World/MapHubGate")
			local hidden = Gate.plan({ pasar = true, gelap = true }, WORLD)
			expect(has(hidden, "Pasar")):toBe(true)
			expect(has(hidden, "TengkulakGelap")):toBe(true)
			expect(has(hidden, "Warung")):toBe(false)
			expect(has(hidden, "RingRoad")):toBe(true)
			expect(has(hidden, "RoadEdge")):toBe(true)
			expect(has(hidden, "Decor")):toBe(true)
		end)

		t:it("never hides plots, NPCs, the spawn, ground or trees", function()
			local Gate = Env.new():require("server/World/MapHubGate")
			local all = {}
			for key in Gate.GREYBOX_HUBS do
				all[key] = true
			end
			local hidden = Gate.plan(all, WORLD)
			for _, name in { "GroundNorth", "Spawn", "Pak RT", "Plot_1", "Flora", "Tree_1" } do
				expect(has(hidden, name)):toBe(false)
			end
			expect(has(hidden, "PosRonda")):toBe(true)
		end)
	end)
end
