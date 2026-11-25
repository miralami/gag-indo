--!nocheck
-- Map layout v1.1 data (MapSpec.V1_*): the hub footprints, front points and NPC spawns that the
-- designer world (Workspace.JuraganMap) uses, kept apart from the greybox HUBS table so the fresh-place
-- fallback does not move. Also the facing-aware raid camera geometry that the v1 NPC spots need.

return function(t, Env)
	local expect = t.expect
	local env, MapSpec, RaidCutscene

	-- Axis-aligned world footprint of a v1 hub; yaw 90/270 swaps width and depth.
	local function inside(hub, x, z, margin)
		local halfX, halfZ = hub.width / 2, hub.depth / 2
		if hub.yaw == 90 or hub.yaw == 270 then
			halfX, halfZ = halfZ, halfX
		end
		margin = margin or 0
		return math.abs(x - hub.x) <= halfX + margin and math.abs(z - hub.z) <= halfZ + margin
	end

	t:describe("MapSpec v1 hubs", function()
		t:beforeEach(function()
			env = Env.new()
			MapSpec = env:require("server/World/MapSpec")
			RaidCutscene = env:require("shared/Config/RaidCutscene")
		end)

		t:it("has one v1 hub for every greybox hub key", function()
			for _, key in MapSpec.HUB_ORDER do
				local hub = MapSpec.v1Hub(key)
				expect(hub ~= nil):toBe(true)
				expect(hub.key):toBe(key)
			end
			expect(#MapSpec.V1_HUBS):toBe(#MapSpec.HUB_ORDER)
			expect(MapSpec.v1Hub("nope")):toBeNil()
		end)

		t:it("carries the v1.1 centres from MAP_LAYOUT_V1", function()
			local want = {
				pasar = { -82, 102 },
				gelap = { -61, 148 },
				warung = { 104, 84 },
				ronda = { -165, -45 },
				polisi = { -80, -112 },
				pakrt = { 80, -112 },
			}
			for key, xz in want do
				expect(MapSpec.v1Hub(key).x):toBe(xz[1])
				expect(MapSpec.v1Hub(key).z):toBe(xz[2])
			end
		end)

		t:it("leaves the greybox hub table alone", function()
			expect(MapSpec.hub("pasar").x):toBe(-71)
			expect(MapSpec.hub("pasar").z):toBe(-86)
			expect(MapSpec.hub("pakrt").z):toBe(68)
			expect(MapSpec.NPC_SPOTS[1].x):toBe(68)
		end)

		t:it("puts the front point past the door side of each hub", function()
			local x, z = MapSpec.v1Front("pakrt")
			expect(x):toBeNear(80, 1e-9)
			expect(z):toBeNear(-83, 1e-9) -- -112 + 24 + 5, door south
			x, z = MapSpec.v1Front("pasar")
			expect(x):toBeNear(-82, 1e-9)
			expect(z):toBeNear(102 - (29.5 + 5), 1e-9) -- door north
			x, z = MapSpec.v1Front("ronda")
			expect(x):toBeNear(-165 + 21 + 5, 1e-9) -- door east
			expect(z):toBeNear(-45, 1e-9)
			x = MapSpec.v1Front("pakrt", 4.5)
			expect(x):toBeNear(84.5, 1e-9)
		end)

		t:it("reports a unit facing for each door", function()
			local fx, fz = MapSpec.v1Facing("pakrt")
			expect(fx):toBeNear(0, 1e-9)
			expect(fz):toBeNear(1, 1e-9)
			fx, fz = MapSpec.v1Facing("ronda")
			expect(fx):toBeNear(1, 1e-9)
			expect(fz):toBeNear(0, 1e-9)
			fx, fz = MapSpec.v1Facing("pasar")
			expect(fx):toBeNear(0, 1e-9)
			expect(fz):toBeNear(-1, 1e-9)
		end)

		t:it("front points of the five street hubs stand outside every v1 footprint", function()
			-- The Gelap is excluded on purpose: its door faces north into the back alley that joins it
			-- to the Pasar, so its front point is inside the Pasar's footprint by design.
			for _, key in MapSpec.HUB_ORDER do
				if key ~= "gelap" then
					local x, z = MapSpec.v1Front(key)
					for _, hub in MapSpec.V1_HUBS do
						expect(inside(hub, x, z)):toBe(false)
					end
				end
			end
		end)
	end)

	t:describe("MapSpec v1 NPC spots", function()
		t:beforeEach(function()
			env = Env.new()
			MapSpec = env:require("server/World/MapSpec")
		end)

		t:it("lists pakrt, tengkulak and polisi once each", function()
			local seen = {}
			for _, spot in MapSpec.V1_NPC_SPOTS do
				seen[spot.npc] = (seen[spot.npc] or 0) + 1
			end
			expect(seen.pakrt):toBe(1)
			expect(seen.tengkulak):toBe(1)
			expect(seen.polisi):toBe(1)
			expect(MapSpec.v1NpcSpot("pakrt").x):toBeNear(84.5, 1e-9)
			expect(MapSpec.v1NpcSpot("polisi").z):toBeNear(-94.5, 1e-9)
			expect(MapSpec.v1NpcSpot("warga")):toBeNil()
		end)

		t:it("stands Pak RT and the police beside their lane, outside every hub", function()
			for _, role in { "pakrt", "polisi" } do
				local spot = MapSpec.v1NpcSpot(role)
				expect(math.abs(spot.x - MapSpec.v1Hub(role).x)):toBeNear(MapSpec.V1_NPC_ALONG, 1e-9)
				for _, hub in MapSpec.V1_HUBS do
					expect(inside(hub, spot.x, spot.z)):toBe(false)
				end
			end
		end)

		t:it("keeps the tengkulak inside the Gelap compound", function()
			local spot = MapSpec.v1NpcSpot("tengkulak")
			expect(spot.x):toBe(-60)
			expect(spot.z):toBe(150)
			expect(inside(MapSpec.v1Hub("gelap"), spot.x, spot.z)):toBe(true)
		end)
	end)

	t:describe("RaidCutscene.cameraFor facing", function()
		t:beforeEach(function()
			env = Env.new()
			RaidCutscene = env:require("shared/Config/RaidCutscene")
		end)

		t:it("defaults to the -z side for an anchor without facing", function()
			local f = RaidCutscene.cameraFor({ kind = "zoom", focus = "road" }, 0, 0)
			expect(f.eye.x):toBeNear(RaidCutscene.focusAnchors.road.x, 1e-9)
			expect(f.eye.z):toBeNear(RaidCutscene.focusAnchors.road.z - 14, 1e-9)
		end)

		t:it("stands on the +z side for a south-facing anchor and yaws around it", function()
			local k = RaidCutscene.focusAnchors.kades
			local f = RaidCutscene.cameraFor({ kind = "zoom", focus = "kades" }, 0, 0)
			expect(f.eye.x):toBeNear(k.x, 1e-9)
			expect(f.eye.z):toBeNear(k.z + 14, 1e-9)
			local turned = RaidCutscene.cameraFor({ kind = "zoom", focus = "kades" }, 0, 90)
			-- Y-rotation by 90 degrees turns +z into +x.
			expect(turned.eye.x):toBeNear(k.x + 14, 1e-9)
			expect(turned.eye.z):toBeNear(k.z, 1e-9)
		end)

		t:it("keeps the stand-off distance for any facing and yaw", function()
			RaidCutscene.focusAnchors.east = { x = 10, y = 5, z = 20, facing = { x = 1, z = 0 } }
			for _, yaw in { 0, 33, -18, 180 } do
				local f = RaidCutscene.cameraFor({ kind = "zoom", focus = "east" }, 0, yaw)
				local dx, dz = f.eye.x - 10, f.eye.z - 20
				expect(math.sqrt(dx * dx + dz * dz)):toBeNear(14, 1e-9)
			end
			local f = RaidCutscene.cameraFor({ kind = "zoom", focus = "east" }, 0, 0)
			expect(f.eye.x):toBeNear(24, 1e-9)
			RaidCutscene.focusAnchors.east = nil
		end)
	end)
end
