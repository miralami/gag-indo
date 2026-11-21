--!strict
-- LookDevPlotsR8: SERVER-ONLY applier for the OFF-BY-DEFAULT "plots_r8" candidate
-- (WORK_QUEUE section M item 71, redone in section O item 143). Canonical plot dressing:
-- 3-stud two-rail bamboo fences with posts every 4 studs, a gate with lintel + name sign,
-- scarecrow, mailbox + sign, an outer irrigation ditch and a corner gubuk in three plots.
--
-- PROCEDURAL PARTS, NO ASSET IDS. No baked models, no LookDevAssetLoader, no LoadAsset: every
-- piece is a plain Part built from Shared.ModelMapPlotsR8. Everything is anchored, non-collidable,
-- untyped by scripts, tagged, and removed by restore() (which reattaches any prior folder).
-- Enable from the Studio Server command bar:
--   require(game.ReplicatedStorage.Shared.LookDevReview).enableAdditive("plots_r8", game)

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevPlotsR8] missing service " .. name)
		return nil
	end
	return value
end

local ReplicatedStorage = service("ReplicatedStorage")
local Workspace = service("Workspace")
if not ReplicatedStorage or not Workspace then
	return {}
end

local Shared: any? = nil
local okShared, sharedValue = pcall(function()
	return (ReplicatedStorage :: any):WaitForChild("Shared")
end)
if okShared and sharedValue then
	Shared = sharedValue
else
	warn("[LookDevPlotsR8] missing Shared folder")
	return {}
end

local okModules, LookDev, Data = pcall(function()
	return require((Shared :: any).LookDev), require((Shared :: any).ModelMapPlotsR8)
end)
if not okModules or not LookDev or not Data then
	warn("[LookDevPlotsR8] could not require LookDev / ModelMapPlotsR8")
	return {}
end

local GROUND_Y = 0.5
local okSpec, MapSpec = pcall(function()
	return require(script.Parent.MapSpec)
end)
if okSpec and type(MapSpec) == "table" and type(MapSpec.GROUND_Y) == "number" then
	GROUND_Y = MapSpec.GROUND_Y
end

local LookDevPlotsR8 = {}

local FAMILY_ID = Data.id
local activeFolder: any? = nil
local savedFolder: any? = nil
local failures = 0

local BAMBOO = Color3.fromRGB(122, 106, 58) -- weathered bamboo, brown-green
local POST_COLOR = Color3.fromRGB(96, 84, 46)
local SIGN_COLOR = Color3.fromRGB(214, 190, 130)
local CLOTH_COLOR = Color3.fromRGB(163, 72, 58)

-- Procedural parts, no asset IDs: a clean apply publishes 0. The counter only moves if staging
-- itself fails, and is published on every exit path for the Studio reads.
local function publishFailures()
	pcall(function()
		require(game.ReplicatedStorage.Shared.LookDevFailures).set(FAMILY_ID, failures)
	end)
end

local function fail(message: string)
	failures += 1
	warn("[LookDevPlotsR8] " .. message)
end

local function taggedPart(index: number, kind: string, name: string, opts: any?): any?
	local part: any? = nil
	local ok, created = pcall(function()
		return Instance.new("Part")
	end)
	if ok and created then
		part = created
	end
	if not part then
		return nil
	end
	pcall(function()
		part.Name = name
		part.Anchored = true
		part.CanCollide = false
		part.Material = if opts and opts.material then opts.material else Enum.Material.Wood
		part.Color = if opts and opts.color then opts.color else BAMBOO
		if opts and opts.transparency then
			part.Transparency = opts.transparency
		end
		part:SetAttribute("LookDevPlotsR8", FAMILY_ID)
		part:SetAttribute("PlotIndex", index)
		part:SetAttribute("Kind", kind)
	end)
	return part
end

local function sizeOf(entry: any): Vector3?
	if entry.size then
		return Vector3.new(entry.size[1], entry.size[2], entry.size[3])
	end
	local thickness = entry.thickness or Data.POST_THICKNESS
	if entry.axis == "x" then
		return Vector3.new(entry.length, thickness, thickness)
	elseif entry.axis == "z" then
		return Vector3.new(thickness, thickness, entry.length)
	end
	return Vector3.new(thickness, entry.length or Data.FENCE_HEIGHT, thickness)
end

-- Every staged entry is anchored, non-collidable and reverted by restore() with the whole folder.
local function place(plotFolder: any, index: number, kind: string, name: string, cframe: CFrame, entry: any, opts: any?)
	local size = sizeOf(entry)
	if not size then
		fail("could not size " .. name .. " for plot " .. index)
		return
	end
	local part = taggedPart(index, kind, name, opts)
	if not part then
		fail("could not create " .. name .. " for plot " .. index)
		return
	end
	local ok, why = pcall(function()
		part.Size = size
		part.CFrame = cframe
		part.Parent = plotFolder
	end)
	if not ok then
		fail("could not place " .. name .. " for plot " .. index .. ":" .. tostring(why))
	end
end

-- Read the actual built plot model (designer PlotAnchor overrides are common); fall back to
-- Config.Game.plotCenter with -Z facing the village centre. Returns the plot's yaw-frame at
-- ground level plus its real Base footprint, so local layout numbers always match the built plot.
local function plotFrame(index: number): (CFrame?, number, number)
	local model: any? = nil
	local okFind, found = pcall(function()
		local world = (Workspace :: any):FindFirstChild("World")
		if world then
			local inside = world:FindFirstChild("Plot_" .. index)
			if inside then
				return inside
			end
		end
		return (Workspace :: any):FindFirstChild("Plot_" .. index, true)
	end)
	if okFind then
		model = found
	end

	local cf: CFrame? = nil
	local width, depth = Data.PLOT_WIDTH, Data.PLOT_DEPTH
	if model then
		local okRead, baseCFrame, baseSize = pcall(function()
			local primary = model.PrimaryPart
			if not primary then
				return nil, nil
			end
			return primary.CFrame, primary.Size
		end)
		if okRead and baseCFrame then
			cf = baseCFrame
			if baseSize then
				width, depth = baseSize.X, baseSize.Z
			end
		end
	end

	if not cf then
		local okGame, Game = pcall(function()
			return require((Shared :: any).Config.Game)
		end)
		if okGame and Game then
			local okCentre, x, z = pcall(Game.plotCenter, index)
			if okCentre and type(x) == "number" and type(z) == "number" then
				cf = CFrame.lookAt(Vector3.new(x, 0, z), Vector3.zero)
			end
		end
	end
	if not cf then
		return nil, width, depth
	end
	-- The plot PrimaryPart has a +0.7 Y pivot; keep its yaw but measure height from GROUND_Y.
	local flat = CFrame.new(cf.Position.X, 0, cf.Position.Z) * (cf - cf.Position)
	return flat, width, depth
end

local function apply()
	failures = 0
	if activeFolder then
		publishFailures()
		return
	end

	local previous: any? = nil
	pcall(function()
		previous = (Workspace :: any):FindFirstChild(Data.folderName)
	end)
	if previous then
		pcall(function()
			previous.Parent = nil
		end)
		savedFolder = previous
	end

	local folder: any? = nil
	local okNew, created = pcall(function()
		return Instance.new("Folder")
	end)
	if okNew and created then
		folder = created
		pcall(function()
			folder.Name = Data.folderName
			folder.Parent = Workspace
		end)
	end
	if not folder then
		fail("could not create staging folder")
		publishFailures()
		return
	end
	activeFolder = folder

	local gateParts = Data.gateParts(Data.GAP_WIDTH, Data.GATE_HEIGHT)
	local rails = Data.fenceRails()
	local gubukSet = {}
	for _, index in ipairs(Data.gubukPlots()) do
		gubukSet[index] = true
	end

	for _, index in ipairs(Data.plotIndices()) do
		local plotFolder: any? = nil
		local okFolder, made = pcall(function()
			return Instance.new("Folder")
		end)
		if okFolder and made then
			plotFolder = made
			pcall(function()
				plotFolder.Name = "Plot_" .. index .. "_plots_r8"
				plotFolder.Parent = folder
			end)
		end
		if not plotFolder then
			fail("could not create folder for plot " .. index)
			continue
		end

		local frame, width, depth = plotFrame(index)
		if not frame then
			fail("could not resolve CFrame for plot " .. index)
			continue
		end
		-- Layout follows the real Base footprint (designer PlotAnchor overrides may change it).
		local layout = Data.fenceLayout(width, depth, Data.GAP_WIDTH, Data.OVERLAP)
		local posts = Data.fencePosts(width, depth, Data.GAP_WIDTH)
		local localDitch = Data.ditchLayout(width, depth)

		-- Two rails per segment; Kind=="fence" counts these pieces only (posts are fence_post).
		for _, segment in ipairs(layout) do
			for _, rail in ipairs(rails) do
				local entry = {
					lx = segment.lx,
					lz = segment.lz,
					ly = rail.ly,
					axis = segment.axis,
					length = segment.length,
					thickness = rail.thickness,
				}
				place(
					plotFolder,
					index,
					"fence",
					`Fence_{index}_{segment.axis}_{segment.lx}_{segment.lz}_{rail.ly}`,
					frame * CFrame.new(entry.lx, GROUND_Y + entry.ly, entry.lz),
					entry
				)
			end
		end

		-- Posts every POST_SPACING studs along all four edges, each FENCE_HEIGHT tall.
		for _, post in ipairs(posts) do
			place(
				plotFolder,
				index,
				"fence_post",
				`FencePost_{index}_{post.lx}_{post.lz}`,
				frame * CFrame.new(post.lx, GROUND_Y + Data.FENCE_HEIGHT / 2, post.lz),
				{ axis = "y", length = Data.FENCE_HEIGHT, thickness = Data.POST_THICKNESS },
				{ color = POST_COLOR }
			)
		end

		-- Gate centre on the inner (-Z) edge; the same local z is used by the harness marker.
		local gateZ = -(depth / 2 + 3)
		for _, gatePart in ipairs(gateParts) do
			local opts = gatePart.kind == "gate_sign" and { color = SIGN_COLOR } or nil
			place(
				plotFolder,
				index,
				gatePart.kind,
				`Gate_{gatePart.kind}_{index}_{gatePart.lx}`,
				frame * CFrame.new(gatePart.lx, GROUND_Y + gatePart.ly, gateZ + gatePart.lz),
				gatePart,
				opts
			)
		end

		-- Scarecrow and mailbox + small sign just inside the plot.
		for _, recipe in ipairs(Data.scarecrowParts()) do
			local opts = recipe.kind == "scarecrow" and { color = CLOTH_COLOR } or nil
			place(
				plotFolder,
				index,
				recipe.kind,
				`Scarecrow_{index}_{recipe.ly}`,
				frame * CFrame.new(recipe.lx, GROUND_Y + recipe.ly, recipe.lz),
				recipe,
				opts
			)
		end
		for _, recipe in ipairs(Data.mailboxParts(width, depth)) do
			local opts = recipe.kind == "mailbox_sign" and { color = SIGN_COLOR } or nil
			place(
				plotFolder,
				index,
				recipe.kind,
				`Mailbox_{recipe.kind}_{index}_{recipe.ly}`,
				frame * CFrame.new(recipe.lx, GROUND_Y + recipe.ly, recipe.lz),
				recipe,
				opts
			)
		end

		-- Thin transparent water sheet and its two banks on the OUTER edge.
		for _, bank in ipairs(localDitch.banks) do
			place(
				plotFolder,
				index,
				"ditch_bank",
				`DitchBank_{index}_{bank.lz}`,
				frame * CFrame.new(bank.lx, GROUND_Y + bank.ly, bank.lz),
				{ size = { bank.width, bank.thickness, bank.depth } },
				{ color = Color3.fromRGB(108, 92, 60) }
			)
		end
		local water = localDitch.water
		place(
			plotFolder,
			index,
			"ditch_water",
			`DitchWater_{index}`,
			frame * CFrame.new(water.lx, GROUND_Y + water.ly, water.lz),
			{ size = { water.width, water.thickness, water.depth } },
			{
				color = Color3.fromRGB(86, 140, 152),
				material = Enum.Material.Water,
				transparency = 0.75,
			}
		)

		-- One small gubuk in a corner of plots 2, 5 and 8.
		if gubukSet[index] then
			for _, recipe in ipairs(Data.gubukParts(width, depth)) do
				place(
					plotFolder,
					index,
					"gubuk",
					`Gubuk_{index}_{recipe.ly}_{recipe.lx}`,
					frame * CFrame.new(recipe.lx, GROUND_Y + recipe.ly, recipe.lz),
					recipe,
					{ color = Color3.fromRGB(148, 120, 68) }
				)
			end
		end

		local marker = taggedPart(index, "gate_marker", "GateMarker_" .. index)
		if marker then
			pcall(function()
				marker.Size = Vector3.new(1, 1, 1)
				marker.CFrame = frame * CFrame.new(0, GROUND_Y, gateZ)
				marker.Transparency = 1
				marker.Parent = plotFolder
			end)
		else
			fail("could not create gate marker for plot " .. index)
		end
	end
	publishFailures()
end

local function restore()
	if activeFolder then
		pcall(function()
			activeFolder:Destroy()
		end)
		activeFolder = nil
	end
	if savedFolder then
		pcall(function()
			savedFolder.Parent = Workspace
		end)
		savedFolder = nil
	end
end

LookDevPlotsR8.apply = apply
LookDevPlotsR8.restore = restore

LookDev.register(FAMILY_ID, { apply = apply, restore = restore })

return LookDevPlotsR8
