--!strict
-- LookDevPlotsR8: SERVER-ONLY applier for the OFF-BY-DEFAULT "plots_r8" candidate
-- (WORK_QUEUE section M item 71). Plot fences and an inner-side gate arch for all ten plots.
--
-- PROCEDURAL PARTS, NO ASSET IDS. No baked models, no LookDevAssetLoader, no LoadAsset: every
-- fence/gate piece is a plain Part built from Shared.ModelMapPlotsR8. Everything is anchored,
-- non-collidable, untyped by scripts, tagged, and removed by restore() (which reattaches any prior
-- folder). Enable from the Studio Server command bar:
--   require(game.ReplicatedStorage.Shared.LookDevReview).enable("plots_r8", game)

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

local function taggedPart(index: number, kind: string, name: string): any?
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
		part.Material = Enum.Material.Wood
		part.Color = Color3.fromRGB(122, 106, 58) -- weathered bamboo, brown-green
		part:SetAttribute("LookDevPlotsR8", FAMILY_ID)
		part:SetAttribute("PlotIndex", index)
		part:SetAttribute("Kind", kind)
	end)
	return part
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
		local segments = Data.fenceLayout(width, depth, Data.GAP_WIDTH, Data.OVERLAP)
		for _, segment in ipairs(segments) do
			local size = if segment.axis == "x"
				then Vector3.new(segment.length, Data.FENCE_HEIGHT, segment.thickness)
				else Vector3.new(segment.thickness, Data.FENCE_HEIGHT, segment.length)
			local cframe = frame * CFrame.new(segment.lx, GROUND_Y + Data.FENCE_HEIGHT / 2, segment.lz)
			local part = taggedPart(index, "fence", `Fence_{index}_{segment.axis}_{segment.lx}_{segment.lz}`)
			if part then
				pcall(function()
					part.Size = size
					part.CFrame = cframe
					part.Parent = plotFolder
				end)
			else
				fail("could not create fence part for plot " .. index)
			end
		end

		-- Gate centre on the inner (-Z) edge; the same local z is used by the harness marker.
		local gateZ = -(depth / 2 + 3)
		for _, gatePart in ipairs(gateParts) do
			local size = if gatePart.axis == "y"
				then Vector3.new(gatePart.thickness, gatePart.length, gatePart.thickness)
				else Vector3.new(gatePart.length, gatePart.thickness, gatePart.thickness)
			local cframe = frame * CFrame.new(gatePart.lx, GROUND_Y + gatePart.ly, gateZ + gatePart.lz)
			local part = taggedPart(index, gatePart.kind, `Gate_{gatePart.kind}_{index}_{gatePart.lx}`)
			if part then
				pcall(function()
					part.Size = size
					part.CFrame = cframe
					part.Parent = plotFolder
				end)
			else
				fail("could not create gate part for plot " .. index)
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
