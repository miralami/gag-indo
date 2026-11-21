--!nocheck
-- WORK_QUEUE section O item 143: canonical plots_r8 dressing. Pure-data contract, review-camera
-- derivation, server LookDev wiring and harness source assertions. No Studio claim: CHECK_143.txt
-- and the visual verdict belong to the main session. The applier uses procedural Parts only,
-- so there are no asset IDs to validate.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect

	local env = Env.new()
	local Data = env:require("shared/ModelMapPlotsR8")
	local Game = env:require("shared/Config/Game")
	local MapSpec = env:require("server/World/MapSpec")
	local LookDev = env:require("shared/LookDev")
	local Review = env:require("shared/LookDevReview")
	local Cameras = Env.new():require("shared/ReviewCameras")

	local segments = Data.fenceLayout(Data.PLOT_WIDTH, Data.PLOT_DEPTH, Data.GAP_WIDTH, Data.OVERLAP)
	local rails = Data.fenceRails()
	local posts = Data.fencePosts(Data.PLOT_WIDTH, Data.PLOT_DEPTH, Data.GAP_WIDTH)
	local gateParts = Data.gateParts(Data.GAP_WIDTH, Data.GATE_HEIGHT)
	local box = Data.gateBox()
	local scarecrow = Data.scarecrowParts()
	local mailbox = Data.mailboxParts(Data.PLOT_WIDTH, Data.PLOT_DEPTH)
	local ditch = Data.ditchLayout(Data.PLOT_WIDTH, Data.PLOT_DEPTH)
	local gubukPlots = Data.gubukPlots()
	local gubuk = Data.gubukParts(Data.PLOT_WIDTH, Data.PLOT_DEPTH)

	local function near(a, b)
		return math.abs(a - b) < 1e-6
	end

	local function lines(list)
		local groups = {}
		for _, segment in ipairs(list) do
			local fixed = if segment.axis == "x" then segment.lz else segment.lx
			local key = segment.axis .. ":" .. tostring(fixed)
			groups[key] = groups[key] or {}
			table.insert(groups[key], segment)
		end
		return groups
	end

	local function postGroups(list)
		local groups = {}
		for _, post in ipairs(list) do
			local isSide = near(math.abs(post.lx), Data.PLOT_WIDTH / 2)
			local along = if isSide then post.lz else post.lx
			local key = if isSide then "z:" .. post.lx else "x:" .. post.lz
			groups[key] = groups[key] or {}
			groups[key][#groups[key] + 1] = along
		end
		for _, values in pairs(groups) do
			table.sort(values)
		end
		return groups
	end

	t:describe("plots_r8 fence and gate data", function()
		t:it("covers all ten plots with a stable staging name and canonical constants", function()
			expect(Data.id):toBe("plots_r8")
			expect(Data.folderName):toBe("LookDevPlotsR8_plots_r8")
			expect(Data.PLOT_COUNT):toBe(Game.plotCount)
			expect(Data.PLOT_COUNT):toBe(10)
			expect(Data.plotIndices()):toEqual({ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 })
			expect(Data.PLOT_WIDTH):toBe(Game.tileColumns * 7.5 + 4)
			expect(Data.PLOT_DEPTH):toBe(math.ceil(Game.tilesBuilt / Game.tileColumns) * 7.5 + 4)
			expect(Data.GAP_WIDTH):toBe(6)
			expect(Data.GATE_HEIGHT):toBe(8)
			expect(Data.MIN_SEGMENTS):toBe(8)
			expect(Data.OVERLAP):toBe(0.2)
			expect(Data.FENCE_HEIGHT):toBe(3)
			expect(Data.POST_SPACING):toBe(4)
			expect(Data.DITCH_WIDTH):toBe(2)
		end)

		t:it("builds at least eight fence rails per plot with exactly 0.2 overlap between neighbours", function()
			expect(#segments >= Data.MIN_SEGMENTS):toBe(true)
			expect(#segments):toBe(8)
			expect(#rails):toBe(2)
			expect(#segments * #rails):toBe(16)
			expect(#segments * #rails >= Data.MIN_SEGMENTS):toBe(true)
			local groups = lines(segments)
			local innerZ = -Data.PLOT_DEPTH / 2
			local groupsSeen = 0
			for key, group in pairs(groups) do
				groupsSeen += 1
				expect(#group):toBe(2)
				table.sort(group, function(a, b)
					return (if a.axis == "x" then a.lx else a.lz) < (if b.axis == "x" then b.lx else b.lz)
				end)
				local a, b = group[1], group[2]
				local aEnd = (if a.axis == "x" then a.lx else a.lz) + a.length / 2
				local bStart = (if b.axis == "x" then b.lx else b.lz) - b.length / 2
				if key == "x:" .. tostring(innerZ) then
					-- Inner edge: the only non-overlapping neighbours, separated by the gate gap.
					expect(near(bStart - aEnd, Data.GAP_WIDTH)):toBe(true)
					expect(near((aEnd + bStart) / 2, 0)):toBe(true)
				else
					expect(near(aEnd - bStart, Data.OVERLAP)):toBe(true)
				end
				expect(near(a.lx, b.lx) and near(a.lz, b.lz)):toBe(false) -- no stacked coplanar parts
				expect(a.thickness ~= b.thickness):toBe(true)
			end
			expect(groupsSeen):toBe(4)
		end)

		t:it("puts two bamboo rails inside the 3-stud fence height", function()
			local seen = {}
			for _, rail in ipairs(rails) do
				expect(rail.thickness > 0):toBe(true)
				expect(rail.ly - rail.thickness / 2 >= 0):toBe(true)
				expect(rail.ly + rail.thickness / 2 <= Data.FENCE_HEIGHT):toBe(true)
				expect(seen[rail.ly] ~= true):toBe(true)
				seen[rail.ly] = true
			end
			local first, second = rails[1], rails[2]
			expect(first.ly < second.ly):toBe(true)
			expect(near(first.thickness, second.thickness)):toBe(true)
		end)

		t:it("spaces fence posts every 4 studs and skips the gate opening", function()
			expect(#posts):toBe(35)
			local groups = postGroups(posts)
			local seenGroups = 0
			for key, values in pairs(groups) do
				seenGroups += 1
				local gaps = 0
				for i = 2, #values do
					local diff = values[i] - values[i - 1]
					expect(diff == Data.POST_SPACING or diff == 2 * Data.POST_SPACING):toBe(true)
					if diff == 2 * Data.POST_SPACING then
						gaps += 1 -- the inner edge's single gate gap
					end
				end
				expect(gaps <= 1):toBe(true)
				if string.sub(key, 1, 1) == "z" then
					expect(gaps):toBe(0)
				end
			end
			expect(seenGroups):toBe(4)
			for _, post in ipairs(posts) do
				expect(post.axis):toBe("y")
				expect(post.thickness):toBe(Data.POST_THICKNESS)
				if near(post.lz, -Data.PLOT_DEPTH / 2) then
					expect(math.abs(post.lx) >= Data.GAP_WIDTH / 2):toBe(true)
				end
			end
		end)

		t:it("centres the six-wide gap on the inner (-Z) edge only", function()
			local inner = {}
			for _, segment in ipairs(segments) do
				if near(segment.lz, -Data.PLOT_DEPTH / 2) and segment.axis == "x" then
					inner[#inner + 1] = segment
				end
			end
			expect(#inner):toBe(2)
			table.sort(inner, function(a, b)
				return a.lx < b.lx
			end)
			local leftEnd = inner[1].lx + inner[1].length / 2
			local rightStart = inner[2].lx - inner[2].length / 2
			expect(near(leftEnd, -Data.GAP_WIDTH / 2)):toBe(true)
			expect(near(rightStart, Data.GAP_WIDTH / 2)):toBe(true)
			expect(near((leftEnd + rightStart) / 2, 0)):toBe(true)
			for _, segment in ipairs(segments) do
				if segment.axis == "z" then
					expect(near(segment.lx, -Data.PLOT_WIDTH / 2) or near(segment.lx, Data.PLOT_WIDTH / 2)):toBe(true)
				end
			end
		end)

		t:it("keeps gate posts outside the 6x8x1 box, with a lintel and name sign above it", function()
			expect(box):toEqual({ width = 6, height = 8, depth = 1 })
			expect(#gateParts):toBe(4)
			local postsSeen, lintel, sign = 0, nil, nil
			for _, part in ipairs(gateParts) do
				if part.kind == "gate_post" then
					postsSeen += 1
					expect(math.abs(part.lx) - part.thickness / 2 >= box.width / 2):toBe(true)
					expect(part.lz):toBe(0)
				elseif part.kind == "gate_lintel" then
					lintel = part
				elseif part.kind == "gate_sign" then
					sign = part
				end
			end
			expect(postsSeen):toBe(2)
			expect(lintel ~= nil):toBe(true)
			expect(lintel.ly - lintel.thickness / 2 >= box.height):toBe(true)
			expect(lintel.ly - lintel.thickness / 2 > box.height + 0.05):toBe(true)
			expect(lintel.lx):toBe(0)
			expect(sign ~= nil):toBe(true)
			expect(sign.ly - sign.thickness / 2 > lintel.ly + lintel.thickness / 2):toBe(true)
			expect(sign.lx):toBe(0)
			expect(sign.length > box.width):toBe(true)
		end)

		t:it("defines a scarecrow, a mailbox with a small sign and an outer irrigation ditch", function()
			expect(#scarecrow):toBeGreaterThan(3)
			for _, part in ipairs(scarecrow) do
				expect(part.kind):toBe("scarecrow")
				expect(part.length > 0 and part.thickness > 0):toBe(true)
			end
			expect(#mailbox):toBe(3)
			local boxes, signs = 0, 0
			for _, part in ipairs(mailbox) do
				if part.kind == "mailbox" then
					boxes += 1
				elseif part.kind == "mailbox_sign" then
					signs += 1
				end
			end
			expect(boxes):toBe(2)
			expect(signs):toBe(1)
			expect(ditch.water.depth):toBe(Data.DITCH_WIDTH)
			expect(ditch.water.thickness <= 0.2):toBe(true)
			expect(#ditch.banks):toBe(2)
			expect(ditch.water.lz > Data.PLOT_DEPTH / 2):toBe(true)
			local lowBank, highBank = ditch.banks[1], ditch.banks[2]
			expect(lowBank.lz + lowBank.depth / 2 <= ditch.water.lz - ditch.water.depth / 2):toBe(true)
			expect(highBank.lz - highBank.depth / 2 >= ditch.water.lz + ditch.water.depth / 2):toBe(true)
		end)

		t:it("places a small gubuk in exactly three deterministic plots", function()
			expect(gubukPlots):toEqual({ 2, 5, 8 })
			local seen = {}
			for _, index in ipairs(gubukPlots) do
				expect(index >= 1 and index <= Data.PLOT_COUNT):toBe(true)
				expect(seen[index] ~= true):toBe(true)
				seen[index] = true
			end
			expect(#gubuk):toBeGreaterThan(5)
			for _, part in ipairs(gubuk) do
				expect(part.kind):toBe("gubuk")
				expect(#part.size):toBe(3)
				for _, dimension in ipairs(part.size) do
					expect(dimension > 0):toBe(true)
				end
			end
		end)

		t:it("is deterministic and free of Roblox APIs and asset-ID literals", function()
			local other = Env.new():require("shared/ModelMapPlotsR8")
			expect(other.fenceLayout(Data.PLOT_WIDTH, Data.PLOT_DEPTH, Data.GAP_WIDTH, Data.OVERLAP)):toEqual(segments)
			expect(other.fenceRails()):toEqual(rails)
			expect(other.fencePosts(Data.PLOT_WIDTH, Data.PLOT_DEPTH, Data.GAP_WIDTH)):toEqual(posts)
			expect(other.gateParts(Data.GAP_WIDTH, Data.GATE_HEIGHT)):toEqual(gateParts)
			expect(other.gateBox()):toEqual(box)
			expect(other.scarecrowParts()):toEqual(scarecrow)
			expect(other.mailboxParts(Data.PLOT_WIDTH, Data.PLOT_DEPTH)):toEqual(mailbox)
			expect(other.ditchLayout(Data.PLOT_WIDTH, Data.PLOT_DEPTH)):toEqual(ditch)
			expect(other.gubukPlots()):toEqual(gubukPlots)
			expect(other.gubukParts(Data.PLOT_WIDTH, Data.PLOT_DEPTH)):toEqual(gubuk)
			expect(other.plotIndices()):toEqual(Data.plotIndices())

			local src = fs.readFile("src/shared/ModelMapPlotsR8.luau")
			expect(string.find(src, "rbxassetid://%d") ~= nil):toBe(false)
			expect(string.find(src, "%d%d%d%d%d%d%d") ~= nil):toBe(false)
			expect(string.find(src, "game.", 1, true) ~= nil):toBe(false)
			expect(string.find(src, "Instance.new", 1, true) ~= nil):toBe(false)
			expect(string.find(src, "Enum.", 1, true) ~= nil):toBe(false)
		end)
	end)

	t:describe("plots_r8 review cameras", function()
		t:it("adds plot_aerial_01..10 from the plot centre and connector-road radial", function()
			for i = 1, Game.plotCount do
				local name = "plot_aerial_" .. string.format("%02d", i)
				local camera = Cameras.get(name)
				expect(camera ~= nil):toBe(true)
				expect(camera.datamodel):toBe("Server")
				local px, pz = Game.plotCenter(i)
				local radius = math.sqrt(px * px + pz * pz)
				local ux, uz = px / radius, pz / radius
				expect(near(camera.position[1], px - ux * 40)):toBe(true)
				expect(near(camera.position[2], MapSpec.GROUND_Y + 30)):toBe(true)
				expect(near(camera.position[3], pz - uz * 40)):toBe(true)
				expect(near(camera.lookAt[1], px)):toBe(true)
				expect(near(camera.lookAt[2], MapSpec.GROUND_Y)):toBe(true)
				expect(near(camera.lookAt[3], pz)):toBe(true)
			end
			local names = Cameras.names()
			local seen = {}
			for _, name in ipairs(names) do
				seen[name] = (seen[name] or 0) + 1
			end
			for i = 1, Game.plotCount do
				expect(seen["plot_aerial_" .. string.format("%02d", i)]):toBe(1)
			end
		end)
	end)

	t:describe("plots_r8 server LookDev wiring", function()
		t:it("registers candidate 48 with a plan and a server review path", function()
			expect(#LookDev.IDS):toBe(61)
			expect(LookDev.IDS[48]):toBe("plots_r8")
			expect(LookDev.candidates.plots_r8.status):toBe("candidate, awaiting designer yes")
			expect(LookDev.candidates.plots_r8.idsSource):toBe("Shared.ModelMapPlotsR8")
			local plan = LookDev.plan("plots_r8")
			expect(plan ~= nil):toBe(true)
			expect(plan.id):toBe("plots_r8")
			expect(Review.paths.plots_r8.datamodel):toBe("server")
			expect(Review.paths.plots_r8.path):toEqual({ "World", "LookDevPlotsR8" })
		end)

		t:it("stages all canonical kinds as tagged non-collidable parts and restores its folder", function()
			local applier = fs.readFile("src/server/World/LookDevPlotsR8.luau")
			expect(string.find(applier, "PROCEDURAL PARTS, NO ASSET IDS", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "LookDev.register(FAMILY_ID", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "LookDevFailures).set(FAMILY_ID, failures)", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, 'SetAttribute("LookDevPlotsR8", FAMILY_ID)', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, 'SetAttribute("PlotIndex", index)', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, 'SetAttribute("Kind", kind)', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, 'GateMarker_" .. index', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "marker.Transparency = 1", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "part.CanCollide = false", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "GetAttribute", 1, true) == nil):toBe(true)
			for _, kind in ipairs({
				"fence",
				"fence_post",
				"scarecrow",
				"mailbox_sign",
				"ditch_water",
				"ditch_bank",
				"gubuk",
				"gate_marker",
			}) do
				expect(string.find(applier, '"' .. kind .. '"', 1, true) ~= nil):toBe(true)
			end
			for _, kind in ipairs({ "gate_post", "gate_lintel", "gate_sign" }) do
				local found = false
				for _, part in ipairs(gateParts) do
					if part.kind == kind then
						found = true
					end
				end
				expect(found):toBe(true)
			end
			expect(string.find(applier, "Mailbox_{recipe.kind}", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "Enum.Material.Water", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "transparency = 0.75", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "Data.gubukPlots()", 1, true) ~= nil):toBe(true)
			local main = fs.readFile("src/server/Main.server.luau")
			expect(string.find(main, "pcall(require, script.Parent.World.LookDevPlotsR8)", 1, true) ~= nil):toBe(true)
		end)
	end)

	t:describe("plots_r8 harness source", function()
		t:it("raises PLOT_FENCE to 8 and adds a non-vacuous PLOT_FENCE_VISIBLE check at >=70", function()
			local src = fs.readFile("tools/studio/review_check_r8.luau")
			expect(string.find(src, "local FENCE_MIN = 8", 1, true) ~= nil):toBe(true)
			local orderAt = string.find(src, '"PLOT_FENCE",', 1, true)
			expect(orderAt ~= nil):toBe(true)
			local visibleAt = string.find(src, '"PLOT_FENCE_VISIBLE",', 1, true)
			expect(visibleAt ~= nil):toBe(true)
			expect(visibleAt > orderAt):toBe(true)
			expect(string.find(src, "local PLOT_FENCE_VISIBLE_MIN = 70", 1, true) ~= nil):toBe(true)
			expect(string.find(src, '"plot_aerial_" .. string.format("%02d", i)', 1, true) ~= nil):toBe(true)
			expect(string.find(src, "first opaque hit must be that rail", 1, true) ~= nil):toBe(true)
			expect(string.find(src, 'emit("PLOT_FENCE_VISIBLE",', 1, true) ~= nil):toBe(true)
			expect(string.find(src, "GATE_CLEAR", 1, true) ~= nil):toBe(true)
			expect(string.find(src, "CAMERA_CLEAR", 1, true) ~= nil):toBe(true)
		end)
	end)
end
