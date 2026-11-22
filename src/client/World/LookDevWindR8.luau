-- LookDevWindR8: client applier for the OFF-BY-DEFAULT "wind_r8" candidate (WORK_QUEUE section M
-- item 85). Sets a gentle workspace.GlobalWind, sways staged jemuran cloths and sign boards with
-- capped looping tweens, and leans staged pisang/bambu Models from ONE Heartbeat sine loop. Every
-- target's original CFrame (pivot for Models) is saved before mutation and written back exactly on
-- restore, together with the captured GlobalWind baseline. No asset IDs, no other candidate touched.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local LookDev = require(Shared.LookDev)
local Wind = require(Shared.ModelMapWindR8)

local LookDevWindR8 = {}

local applied = false
local folder: Instance? = nil
local workspaceService: any = nil
local windBaseline: Vector3? = nil
local heartbeatConnection: any = nil
local tweens: { any } = {}
local targets: { any } = {}
local tiltEntries: { any } = {}
local savedCFrames: { [any]: CFrame } = {}
local elapsed = 0
local tiltStepped = false

local function loadMapSpec(plan: any?): any?
	if type(plan) == "table" and type(plan.mapSpec) == "table" then
		return plan.mapSpec
	end
	local ok, spec = pcall(function()
		local server = game:GetService("ServerScriptService"):FindFirstChild("Server")
		local world = server and server:FindFirstChild("World")
		local module = world and world:FindFirstChild("MapSpec")
		if not module then
			return nil
		end
		return require(module)
	end)
	if ok and type(spec) == "table" then
		return spec
	end
	return nil
end

local function vec(position: { number })
	return Vector3.new(position.x, position.y, position.z)
end

local function newPart(name: string, size: { number }, position: { number }, rgb: { number }, parent: Instance)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = Vector3.new(size.x, size.y, size.z)
	part.CFrame = CFrame.new(vec(position))
	part.Color = Color3.fromRGB(rgb.r, rgb.g, rgb.b)
	part.Anchored = true
	part.CanCollide = false
	part.CastShadow = false
	part.Parent = parent
	return part
end

local function readWind(): Vector3?
	if not workspaceService then
		return nil
	end
	local ok, value = pcall(function()
		return workspaceService.GlobalWind
	end)
	if ok and typeof(value) == "Vector3" then
		return value
	end
	return nil
end

local function restoreTarget(target: any, base: CFrame?)
	if not base then
		return false
	end
	local ok, err = pcall(function()
		if typeof(target) == "Instance" and target:IsA("Model") then
			target:PivotTo(base)
		elseif typeof(target) == "Instance" and target:IsA("BasePart") then
			target.CFrame = base
		end
	end)
	if not ok then
		warn("wind_r8: could not restore a target CFrame: " .. tostring(err))
	end
	return ok
end

local function restore()
	if not applied and windBaseline == nil and folder == nil then
		return
	end
	applied = false
	for _, tween in ipairs(tweens) do
		pcall(function()
			tween:Cancel()
		end)
	end
	tweens = {}
	if heartbeatConnection then
		pcall(function()
			heartbeatConnection:Disconnect()
		end)
	end
	heartbeatConnection = nil

	-- Restore exact saved CFrames while the staged instances are still alive; the harness keeps its
	-- own references, so it can compare them after the folder is destroyed.
	for _, target in ipairs(targets) do
		restoreTarget(target, savedCFrames[target])
	end
	if windBaseline and workspaceService then
		local ok, err = pcall(function()
			workspaceService.GlobalWind = windBaseline
		end)
		if not ok then
			warn("wind_r8: could not restore GlobalWind: " .. tostring(err))
		end
	end
	if folder then
		pcall(function()
			folder:Destroy()
		end)
	end
	folder = nil
	windBaseline = nil
	workspaceService = nil
	tiltEntries = {}
	targets = {}
	table.clear(savedCFrames)
	elapsed = 0
	tiltStepped = false
end

local function tick(dt: number)
	if not applied then
		return
	end
	elapsed += math.clamp(type(dt) == "number" and dt or 0, 0, 0.25)
	for _, entry in ipairs(tiltEntries) do
		local base = savedCFrames[entry.target]
		if base then
			local degrees = Wind.tiltFor(entry.seed, elapsed)
			pcall(function()
				entry.target:PivotTo(base * CFrame.Angles(math.rad(degrees), 0, 0))
			end)
		end
	end
	tiltStepped = true
end

local function buildLaundryLine(specs: { any }, parent: Instance)
	local first, last = specs[1], specs[#specs]
	if not first or not last then
		return
	end
	local start = CFrame.new(vec(first.position)) + Vector3.new(0, 1.2, 0)
	local finish = CFrame.new(vec(last.position)) + Vector3.new(0, 1.2, 0)
	local length = (finish.Position - start.Position).Magnitude
	if length <= 0 then
		return
	end
	local ok, err = pcall(function()
		local line = Instance.new("Part")
		line.Name = "JemuranLine_" .. tostring(first.lineId)
		line.Size = Vector3.new(0.12, 0.12, length + 1)
		line.CFrame = CFrame.lookAt((start.Position + finish.Position) / 2, finish.Position, Vector3.new(0, 1, 0))
		line.Color = Color3.fromRGB(118, 88, 58)
		line.Anchored = true
		line.CanCollide = false
		line.CastShadow = false
		line.Parent = parent
	end)
	if not ok then
		warn("wind_r8: could not build a jemuran line: " .. tostring(err))
	end
end

local function buildSway(spec: any, parent: Instance, tweenService: any)
	local target
	if spec.kind == "laundry" then
		target = newPart("Jemuran_" .. spec.id, { x = 1.2, y = 1.8, z = 0.12 }, spec.position, {
			r = 232,
			g = 218,
			b = 190,
		}, parent)
	else
		for side = -1, 1, 2 do
			newPart("SignPost_" .. spec.id .. "_" .. side, { x = 0.25, y = 4, z = 0.25 }, {
				x = spec.position.x + side * 2.2,
				y = spec.position.y - 2,
				z = spec.position.z,
			}, { r = 112, g = 78, b = 48 }, parent)
		end
		target = newPart("SignBoard_" .. spec.id, { x = 5, y = 1.6, z = 0.3 }, spec.position, {
			r = 176,
			g = 116,
			b = 62,
		}, parent)
	end

	savedCFrames[target] = target.CFrame -- saved BEFORE the tween touches it
	targets[#targets + 1] = target
	local info = TweenInfo.new(spec.duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	local tween = tweenService:Create(target, info, {
		CFrame = target.CFrame * CFrame.Angles(0, 0, math.rad(spec.amplitudeDeg)),
	})
	tweens[#tweens + 1] = tween
	tween:Play()
end

local function buildTilt(spec: any, parent: Instance)
	local model = Instance.new("Model")
	model.Name = "Tilt_" .. spec.id
	local height = spec.species == "pisang" and 6 or 7
	local trunk = newPart("Trunk_" .. spec.id, { x = 0.55, y = height, z = 0.55 }, {
		x = spec.position.x,
		y = spec.position.y + height / 2,
		z = spec.position.z,
	}, spec.species == "pisang" and { r = 92, g = 132, b = 62 } or { r = 118, g = 146, b = 74 }, model)
	for index = 1, 4 do
		local angle = (index - 1) * math.pi / 2
		local leaf = newPart("Leaf_" .. spec.id .. "_" .. index, { x = 3.2, y = 0.12, z = 0.9 }, {
			x = spec.position.x + math.cos(angle) * 1.2,
			y = spec.position.y + height + 0.4 - index * 0.25,
			z = spec.position.z + math.sin(angle) * 1.2,
		}, spec.species == "pisang" and { r = 58, g = 146, b = 54 } or { r = 74, g = 158, b = 78 }, model)
		leaf.CFrame = leaf.CFrame * CFrame.Angles(0, -angle, 0)
	end
	model.PrimaryPart = trunk
	model.Parent = parent

	savedCFrames[model] = model:GetPivot() -- saved BEFORE the Heartbeat tilts it
	targets[#targets + 1] = model
	tiltEntries[#tiltEntries + 1] = { target = model, seed = spec.seed }
end

local function apply(plan: any?)
	if applied then
		return
	end
	local mapSpec = loadMapSpec(plan)
	if not mapSpec then
		warn("wind_r8: MapSpec unavailable (ServerScriptService.Server.World.MapSpec)")
		return
	end
	local okSway, swayPlans = pcall(Wind.tweenPlan, mapSpec)
	local okTilt, tiltPlans = pcall(Wind.tiltPlan, mapSpec)
	if not okSway or not okTilt or #swayPlans > Wind.MAX_TWEENS then
		warn("wind_r8: sway or tilt plan invalid: " .. tostring(okSway and okTilt and "too many tweens" or tiltPlans))
		return
	end

	local okWorkspace, foundWorkspace = pcall(function()
		return game:GetService("Workspace")
	end)
	if not okWorkspace or not foundWorkspace then
		warn("wind_r8: Workspace unavailable")
		return
	end
	workspaceService = foundWorkspace
	windBaseline = readWind()
	local breeze = Wind.windVector()
	local okSet, setErr = pcall(function()
		workspaceService.GlobalWind = Vector3.new(breeze.x, breeze.y, breeze.z)
	end)
	if not okSet then
		warn("wind_r8: could not set GlobalWind: " .. tostring(setErr))
		restore()
		return
	end

	local okFolder, created = pcall(function()
		local existing = workspaceService:FindFirstChild(Wind.folder)
		if existing then
			existing:Destroy()
		end
		local f = Instance.new("Folder")
		f.Name = Wind.folder
		f.Parent = workspaceService
		return f
	end)
	if not okFolder or not created then
		warn("wind_r8: could not create " .. Wind.folder .. ": " .. tostring(created))
		restore()
		return
	end
	folder = created
	applied = true
	tweens, targets, tiltEntries = {}, {}, {}
	table.clear(savedCFrames)
	elapsed, tiltStepped = 0, false

	local okBuild, buildErr = pcall(function()
		local tweenService = game:GetService("TweenService")
		local lines = {}
		for _, spec in ipairs(swayPlans) do
			if spec.kind == "laundry" then
				lines[spec.lineId] = lines[spec.lineId] or {}
				lines[spec.lineId][#lines[spec.lineId] + 1] = spec
			end
		end
		for _, members in pairs(lines) do
			buildLaundryLine(members, folder)
		end
		for _, spec in ipairs(swayPlans) do
			buildSway(spec, folder, tweenService)
		end
		for _, spec in ipairs(tiltPlans) do
			buildTilt(spec, folder)
		end

		local okHeartbeat, heartbeat = pcall(function()
			return game:GetService("RunService").Heartbeat
		end)
		if okHeartbeat and heartbeat and type(heartbeat.Connect) == "function" then
			local okConnect, connection = pcall(function()
				return heartbeat:Connect(tick)
			end)
			if okConnect then
				heartbeatConnection = connection
			else
				warn("wind_r8: Heartbeat connect failed: " .. tostring(connection))
			end
		end
	end)
	if not okBuild then
		warn("wind_r8: staging failed: " .. tostring(buildErr))
		restore()
	end
end

-- Diagnostics used by tools/studio/review_check_r8.luau (WIND_SET / SWAY_TWEENS / WIND_RESTORE).
function LookDevWindR8.stageTargets()
	return table.clone(targets)
end
function LookDevWindR8.baseCFrame(target: any): CFrame?
	return savedCFrames[target]
end
function LookDevWindR8.tweenCount(): number
	return #tweens
end
function LookDevWindR8.tiltActive(): boolean
	return tiltStepped
end
function LookDevWindR8.isApplied(): boolean
	return applied
end

LookDevWindR8.savedCFrames = savedCFrames
LookDevWindR8.apply = apply
LookDevWindR8.restore = restore

LookDev.register(Wind.id, { apply = apply, restore = restore })

return LookDevWindR8
