--!nocheck
-- WORK_QUEUE section P items 228-237: the ten canonical-gap LookDev candidates.
-- Pure-data invariants only (counts, sizes, species, colours, slot/footprint fit, no pines,
-- no interactive parts, Strings keys, water/gate clearance) plus source guards on the applier.
-- No Studio claim: CHECK evidence, tracker ticks and the designer verdict belong to the main session.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect

	local env = Env.new()
	local Data = env:require("shared/ModelMapCanonicalR10")
	local MapSpec = env:require("server/World/MapSpec")
	local Game = env:require("shared/Config/Game")
	local Strings = env:require("shared/Strings")

	local dataSrc = fs.readFile("src/shared/ModelMapCanonicalR10.luau")
	local applierSrc = fs.readFile("src/server/World/LookDevCanonicalR10.luau")

	local EXPECTED = {
		"balai_r10",
		"hub_canopy_r10",
		"blocks_shrubs_r10",
		"pasar_roof_r10",
		"warung_cluster_r10",
		"polisi_roof_r10",
		"pakrt_roof_r10",
		"sawah_gubuk_r10",
		"plots_mailbox_r10",
		"river_palms_r10",
	}

	local ctx = { MapSpec = MapSpec, Game = Game, groundY = MapSpec.GROUND_Y }
	local anchors = {}
	for _, id in ipairs(EXPECTED) do
		anchors[id] = Data.anchorsFor(id, ctx)
	end

	local function gates()
		local out = {}
		for index = 1, Game.plotCount do
			local x, z = Game.plotCenter(index)
			local yaw = math.deg(math.atan2(x, z))
			local gx, gz = Data.rotatePoint(x, z, yaw, 0, -(34 / 2 + 3))
			out[#out + 1] = { x = gx, z = gz }
		end
		return out
	end

	local shrubCtx = {
		MapSpec = MapSpec,
		Game = Game,
		groundY = MapSpec.GROUND_Y,
		gateCentres = gates(),
	}
	local shrubs = Data.anchorsFor("blocks_shrubs_r10", shrubCtx)

	local function has(needle, haystack)
		for _, value in ipairs(haystack) do
			if value == needle then
				return true
			end
		end
		return false
	end

	local function setCount(list)
		local seen = {}
		for _, value in ipairs(list) do
			seen[value] = true
		end
		local n = 0
		for _ in pairs(seen) do
			n += 1
		end
		return n
	end

	local function kindsOf(parts, kind)
		local out = {}
		for _, recipe in ipairs(parts) do
			if recipe.kind == kind then
				out[#out + 1] = recipe
			end
		end
		return out
	end

	local function noFloaters(parts)
		for _, recipe in ipairs(parts) do
			local sx, sy, sz = recipe.size[1], recipe.size[2], recipe.size[3]
			local rx, rz = math.rad(recipe.rx or 0), math.rad(recipe.rz or 0)
			local halfY = math.abs(math.cos(rx) * math.cos(rz)) * sy / 2
				+ math.abs(math.sin(rz)) * sx / 2
				+ math.abs(math.sin(rx)) * sz / 2
			if recipe.dy - halfY < -0.001 then
				return false
			end
		end
		return true
	end

	local function noPines(value)
		return string.find(string.lower(tostring(value)), "pine", 1, true) == nil
	end

	t:describe("canonical_r10 pure data", function()
		t:it("locks the ten ids, folder names and stage contract", function()
			expect(Data.familyId):toBe("canonical_r10")
			expect(Data.stageAttribute):toBe("LookDevStage")
			expect(Data.kindAttribute):toBe("Kind")
			expect(Data.stringsKeyAttribute):toBe("StringsKey")
			expect(#Data.order):toBe(10)
			expect(Data.ids):toEqual(EXPECTED)
			for _, id in ipairs(EXPECTED) do
				expect(Data.known(id)):toBe(true)
				expect(Data.folderName(id)):toBe("LookDev_" .. id)
				expect(Data.counts(id, ctx).anchors > 0):toBe(true)
			end
			expect(Data.known("not_a_candidate")):toBe(false)
		end)

		t:it("keeps every recipe pure, deterministic and non-interactive", function()
			for _, id in ipairs(EXPECTED) do
				local parts = Data.partsFor(id)
				expect(Data.partsFor(id)):toEqual(parts)
				for _, recipe in ipairs(parts) do
					expect(type(recipe.kind) == "string" and #recipe.kind > 0):toBe(true)
					expect(has(recipe.shape, Data.SHAPES)):toBe(true)
					expect(recipe.interactive):toBe(false)
					expect(#recipe.size):toBe(3)
					for _, extent in ipairs(recipe.size) do
						expect(extent > 0):toBe(true)
					end
					expect(#recipe.rgb):toBe(3)
					for _, channel in ipairs(recipe.rgb) do
						expect(channel >= 0 and channel <= 255):toBe(true)
					end
					local kind = string.lower(recipe.kind)
					expect(string.find(kind, "prompt", 1, true) == nil):toBe(true)
					expect(string.find(kind, "click", 1, true) == nil):toBe(true)
					expect(string.find(kind, "detector", 1, true) == nil):toBe(true)
				end
			end
			expect(string.find(dataSrc, "rbxassetid://", 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, "Enum.", 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, "Instance.", 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, "%d%d%d%d%d%d%d") == nil):toBe(true)
		end)

		t:it("228 balai: twenty-plus parts fit the half-slot and carry a Strings sign", function()
			local slot = Data.balaiSlot(MapSpec.FUTURE_SLOTS[1])
			expect(slot.x):toBe(0)
			expect(slot.z):toBe(-137)
			expect(slot.width):toBe(42)
			expect(slot.depth):toBe(28)
			local parts = Data.partsFor("balai_r10")
			expect(#parts):toBeAtLeast(20)
			local bounds = Data.boundsFor("balai_r10")
			expect(bounds.minX >= -slot.width / 2 and bounds.maxX <= slot.width / 2):toBe(true)
			expect(bounds.minZ >= -slot.depth / 2 and bounds.maxZ <= slot.depth / 2):toBe(true)
			local signs = kindsOf(parts, "balai_sign")
			expect(#signs):toBe(1)
			expect(signs[1].signKey):toBe("sign_balai")
			expect(type(Strings.raw.sign_balai.id) == "string" and type(Strings.raw.sign_balai.en) == "string"):toBe(
				true
			)
			expect(noFloaters(parts)):toBe(true)
			expect(#anchors.balai_r10):toBe(1)
			expect(anchors.balai_r10[1].x):toBe(slot.x)
			expect(anchors.balai_r10[1].z):toBe(slot.z)
		end)

		t:it("229 hub canopy: 2-3 round trees per hub, 10-12 studs, no pines", function()
			local trees = anchors.hub_canopy_r10
			expect(#trees >= 12 and #trees <= 18):toBe(true)
			for _, hub in ipairs(MapSpec.HUBS) do
				local atHub = 0
				for _, tree in ipairs(trees) do
					if tree.hubKey == hub.key then
						atHub += 1
						local crown = kindsOf(Data.partsFor("hub_canopy_r10", tree), "canopy_crown")[1]
						expect(crown.shape):toBe("Ball")
						expect(crown.size[1] >= 10 and crown.size[1] <= 12):toBe(true)
						expect(crown.size[3]):toBe(crown.size[1])
						expect(has(tree.species, Data.CANOPY_SPECIES)):toBe(true)
						expect(noPines(tree.species) and noPines(crown.kind)):toBe(true)
						-- Outside the crossroads, and inside the connector ring or in its NW gap (the
						-- Gelap yard sits beyond the ring there, where no ring road is built).
						expect(math.abs(tree.x) > 20 or math.abs(tree.z) > 20):toBe(true)
						local angle = math.deg(math.atan2(tree.z, tree.x)) % 360
						local inGap = angle >= MapSpec.ROAD.gapStart and angle <= MapSpec.ROAD.gapEnd
						expect(inGap or math.sqrt(tree.x ^ 2 + tree.z ^ 2) < MapSpec.ROAD.ringCentre - 6):toBe(true)
					end
				end
				expect(atHub >= 2 and atHub <= 3):toBe(true)
			end
		end)

		t:it("230 shrubs: 60-plus rounded plants, at least three species", function()
			expect(#shrubs):toBeAtLeast(60)
			local species = {}
			for _, shrub in ipairs(shrubs) do
				species[#species + 1] = shrub.species
				expect(has(shrub.species, Data.SHRUB_SPECIES)):toBe(true)
				expect(noPines(shrub.species)):toBe(true)
				local parts = Data.partsFor("blocks_shrubs_r10", shrub)
				expect(#parts):toBe(1)
				expect(has(parts[1].shape, Data.ROUND_SHAPES)):toBe(true)
				expect(parts[1].size[1] <= 3 and parts[1].size[2] <= 3):toBe(true)
				local radius = math.sqrt(shrub.x ^ 2 + shrub.z ^ 2)
				expect(radius > MapSpec.ROAD.ringCentre + MapSpec.ROAD.ringWidth / 2):toBe(true)
				expect(radius + 2 < Game.plotRadius - 17):toBe(true)
				for _, gate in ipairs(gates()) do
					local dx, dz = shrub.x - gate.x, shrub.z - gate.z
					expect(dx * dx + dz * dz >= Data.GATE_CLEAR ^ 2):toBe(true)
				end
			end
			expect(setCount(species)):toBeAtLeast(3)
		end)

		t:it("231/233 red and blue roofs are pitched and stay inside their hub footprints", function()
			for _, entry in ipairs({
				{ id = "pasar_roof_r10", key = "pasar", channel = 1 },
				{ id = "polisi_roof_r10", key = "polisi", channel = 3 },
			}) do
				local anchor = anchors[entry.id][1]
				expect(anchor.hubKey):toBe(entry.key)
				local hub = MapSpec.hub(entry.key)
				local parts = Data.partsFor(entry.id, anchor)
				expect(#kindsOf(parts, "roof_panel")):toBeAtLeast(2)
				for _, panel in ipairs(kindsOf(parts, "roof_panel")) do
					expect(math.abs(panel.rx) > 0):toBe(true)
					expect(panel.rgb[entry.channel] > 90):toBe(true)
				end
				local red = Data.partsFor("pasar_roof_r10", anchors.pasar_roof_r10[1])[1]
				local blue = Data.partsFor("polisi_roof_r10", anchors.polisi_roof_r10[1])[1]
				expect(red.rgb[1] > red.rgb[2] + 80 and red.rgb[1] > red.rgb[3] + 80):toBe(true)
				expect(blue.rgb[3] > blue.rgb[1] + 80 and blue.rgb[3] > blue.rgb[2] + 40):toBe(true)
				local bounds = Data.boundsFor(entry.id, anchor)
				local hubBounds = MapSpec.hubBounds(hub)
				local pad = MapSpec.ROOF_OVERHANG + 0.5
				expect(hub.x + bounds.minX >= hubBounds.minX - pad):toBe(true)
				expect(hub.x + bounds.maxX <= hubBounds.maxX + pad):toBe(true)
				expect(hub.z + bounds.minZ >= hubBounds.minZ - pad):toBe(true)
				expect(hub.z + bounds.maxZ <= hubBounds.maxZ + pad):toBe(true)
			end
			-- Pos Ronda's tower is far outside the blue roof's footprint.
			local tower = MapSpec.RONDA_TOWER
			local polisi = anchors.polisi_roof_r10[1]
			expect(math.sqrt((polisi.x - tower.x) ^ 2 + (polisi.z - tower.z) ^ 2) > 60):toBe(true)
		end)

		t:it("232 warung: three tin stalls, two grounded tables, nothing interactive", function()
			local parts = Data.partsFor("warung_cluster_r10")
			local stalls = kindsOf(parts, "stall_tin_roof")
			expect(#stalls):toBeAtLeast(3)
			for _, stall in ipairs(stalls) do
				expect(stall.tin):toBe(true)
				expect(stall.material):toBe("Metal")
			end
			expect(setCount((function()
				local ids = {}
				for _, stall in ipairs(stalls) do
					ids[#ids + 1] = stall.stall
				end
				return ids
			end)())):toBeAtLeast(3)
			expect(#kindsOf(parts, "table_top")):toBeAtLeast(2)
			expect(noFloaters(parts)):toBe(true)
			local anchor = anchors.warung_cluster_r10[1]
			expect(anchor.hubKey):toBe("warung")
			local bounds = Data.boundsFor("warung_cluster_r10")
			local hubBounds = MapSpec.hubBounds(MapSpec.hub("warung"))
			expect(anchor.x + bounds.minX >= hubBounds.minX - 4):toBe(true)
			expect(anchor.x + bounds.maxX <= hubBounds.maxX + 4):toBe(true)
		end)

		t:it("234 pakrt: retint data alone, no ridge caps and no created geometry", function()
			expect(Data.CONTRACT.pakrt_roof_r10.touchesRidges):toBe(false)
			expect(#Data.partsFor("pakrt_roof_r10")):toBe(0)
			local rgb = Data.COLORS.yellow_orange
			expect(rgb[1] > 200 and rgb[2] > 110 and rgb[2] < 200 and rgb[3] < 90):toBe(true)
			expect(anchors.pakrt_roof_r10[1].hubKey):toBe("pakrt")
			expect(applierSrc:find('string.find(name, "Ridge", 1, true) == nil', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('string.find(name, "Cap", 1, true) == nil', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('prop = "Color"', 1, true) ~= nil):toBe(true)
		end)

		t:it("235 sawah: exactly one hut resting on terrace 2", function()
			local huts = anchors.sawah_gubuk_r10
			expect(#huts):toBe(1)
			local hut = huts[1]
			local terrace = MapSpec.TERRACES[Data.CONTRACT.sawah_gubuk_r10.terrace]
			expect(hut.terrace):toBe(2)
			expect(hut.y):toBe(terrace.top)
			expect(hut.z):toBe((terrace.z0 + terrace.z1) / 2)
			local floor = kindsOf(Data.partsFor("sawah_gubuk_r10"), "gubuk_floor")[1]
			expect(floor.dy - floor.size[2] / 2):toBe(0)
			expect(floor.size[1] >= 8 and floor.size[3] >= 6):toBe(true)
			expect(hut.x > MapSpec.TERRACE_GAP / 2 and hut.x < MapSpec.TERRACE_X[2]):toBe(true)
			expect(applierSrc:find('newInstance(stateFor(id), "Model", "Gubuk")', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('[Data.kindAttribute] = "gubuk"', 1, true) ~= nil):toBe(true)
		end)

		t:it("236 plots: a grounded mailbox and Strings sign per plot, off the gate lane", function()
			local boxes = anchors.plots_mailbox_r10
			expect(#boxes):toBeAtLeast(Game.plotCount)
			for _, plot in ipairs(boxes) do
				local parts = Data.partsFor("plots_mailbox_r10", plot)
				local mailbox = kindsOf(parts, "mailbox")
				local signs = kindsOf(parts, "mailbox_sign")
				expect(#mailbox >= 1):toBe(true)
				expect(#signs >= 1):toBe(true)
				local key = signs[1].signKey
				expect(type(Strings.raw[key].id) == "string" and type(Strings.raw[key].en) == "string"):toBe(true)
				expect(noFloaters(parts)):toBe(true)
				local gate = gates()[plot.index]
				local dx, dz = plot.x - gate.x, plot.z - gate.z
				expect(dx * dx + dz * dz >= Data.GATE_CLEAR ^ 2):toBe(true)
				expect(math.abs(plot.lx) > 6):toBe(true)
			end
		end)

		t:it("237 river: twenty-plus tall kelapa palms on the banks, out of the channel", function()
			local palms = anchors.river_palms_r10
			expect(#palms):toBeAtLeast(20)
			local species = {}
			for _, palm in ipairs(palms) do
				species[#species + 1] = palm.species
				expect(palm.species):toBe("kelapa")
				expect(noPines(palm.species)):toBe(true)
				local parts = Data.partsFor("river_palms_r10", palm)
				local top = 0
				for _, recipe in ipairs(parts) do
					top = math.max(top, recipe.dy + recipe.size[2] / 2)
					expect(noPines(recipe.kind) and noPines(recipe.shape)):toBe(true)
				end
				expect(top >= 14):toBe(true)
				expect(noFloaters(parts)):toBe(true)
				local centre = MapSpec.riverCentreZ(palm.x)
				expect(math.abs(palm.z - centre) > Data.RIVER_HALF + 4):toBe(true)
			end
			expect(setCount(species)):toBe(1)
		end)

		t:it("holds no pine species or interactive part in any of the ten candidates", function()
			for _, id in ipairs(EXPECTED) do
				for _, anchor in ipairs(anchors[id]) do
					expect(noPines(tostring(anchor.hubKey or ""))):toBe(true)
					expect(noPines(tostring(anchor.species or ""))):toBe(true)
				end
				for _, recipe in ipairs(Data.partsFor(id)) do
					expect(noPines(recipe.kind) and noPines(recipe.material)):toBe(true)
				end
			end
			expect(string.find(dataSrc, "pine", 1, true) == nil):toBe(true)
			expect(string.find(applierSrc, "ProximityPrompt", 1, true) == nil):toBe(true)
			expect(string.find(applierSrc, "ClickDetector", 1, true) == nil):toBe(true)
		end)
	end)

	t:describe("canonical_r10 applier wiring", function()
		t:it("registers all ten ids with the exact apply/restore table form", function()
			for _, id in ipairs(EXPECTED) do
				expect(
					applierSrc:find(
						"LookDev.register(id, { apply = applier.apply, restore = applier.restore })",
						1,
						true
					) ~= nil
				):toBe(true)
			end
			expect(applierSrc:find("require((Shared :: any).ModelMapCanonicalR10)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("require(script.Parent.MapSpec)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("require((Shared :: any).Strings)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Data.folderName(id)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("[Data.stageAttribute] = id", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("[Data.kindAttribute]", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Failures.set(id", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Failures.reset(id)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("pcall(", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("CanCollide = false", 1, true) ~= nil):toBe(true)
		end)

		t:it("destroys only created instances and restores overwritten properties", function()
			expect(applierSrc:find("instance:Destroy()", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("entry.instance[entry.prop] = entry.value", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("previous.Parent = nil", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("previous.Parent = Workspace", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("if state.applied then", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("rbxassetid://", 1, true) == nil):toBe(true)
			expect(applierSrc:find("assetId", 1, true) == nil):toBe(true)
			expect(applierSrc:find("%d%d%d%d%d%d%d") == nil):toBe(true)
		end)
	end)
end
