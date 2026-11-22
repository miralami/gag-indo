-- LookDevAnimalsR8: client applier for the OFF-BY-DEFAULT "animals_r8" candidate (WORK_QUEUE
-- section M item 82). Eleven simple-Part animals (4 ayam, 4 bebek, 2 kambing, 1 kucing) wander on
-- MapSpec-derived home bands. ONE Heartbeat connection drives the pure shared step function; no
-- asset IDs, no physics and no game-state mutation. Everything is destroyed on restore.
--
-- The pure step/sim lives in Shared.ModelMapAnimalsR8; the harness calls it directly in the Server
-- VM for ANIMAL_COUNT / ANIMAL_BOUNDS / ANIMAL_COST, so Studio needs no 60-second real-time wait.
-- `apply({ mapSpec = ..., heartbeat = ... })` accepts injected deps for deterministic Lune specs;
-- with no injection it reads MapSpec from ServerScriptService.Server.World when available and falls
-- back to RunService.Heartbeat. Failures publish a warn and leave `applied` false.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local LookDev = require(Shared.LookDev)
local Animals = require(Shared.ModelMapAnimalsR8)

local LookDevAnimalsR8 = {}

local applied = false
local folder: Instance? = nil
local connection: any = nil
local mapSpec: any = nil
local bounds: any = nil
local states: { any } = {}
local models: { any } = {}

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

local function vec(t: { number })
	return Vector3.new(t[1], t[2], t[3])
end

local function buildAnimal(state: any, parent: Instance): any?
	local okModel, model = pcall(function()
		local m = Instance.new("Model")
		m.Name = state.id
		m.Parent = parent
		return m
	end)
	if not okModel or not model then
		return nil
	end

	-- An invisible anchored root keeps the visible parts unanchored and physics-free: every visible
	-- part is welded to it, and the whole model is moved once per Heartbeat by SetPrimaryPartCFrame.
	local okAnchor, anchor = pcall(function()
		local a = Instance.new("Part")
		a.Name = "Anchor"
		a.Size = Vector3.new(0.1, 0.1, 0.1)
		a.Transparency = 1
		a.CanCollide = false
		a.Anchored = true
		a.Parent = model
		return a
	end)
	if not okAnchor or not anchor then
		pcall(function()
			model:Destroy()
		end)
		return nil
	end
	pcall(function()
		model.PrimaryPart = anchor
	end)

	for _, recipe in ipairs(Animals.PARTS[state.kind] or {}) do
		local partOk, built = pcall(function()
			local part = Instance.new("Part")
			part.Name = recipe[1]
			part.Size = vec(recipe[2])
			part.CFrame = CFrame.new(vec(recipe[3]))
			part.Color = Color3.fromRGB(recipe[4][1], recipe[4][2], recipe[4][3])
			part.Anchored = false
			part.CanCollide = false
			part.CastShadow = false
			part.Parent = model
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = part
			weld.Part1 = anchor
			weld.Parent = part
			return part
		end)
		if not partOk or not built then
			warn("animals_r8: could not build " .. state.id .. "." .. tostring(recipe[1]) .. ": " .. tostring(built))
		end
	end
	return model
end

local function tick(dt: number)
	if not applied then
		return
	end
	Animals.stepAll(states, dt, bounds)
	for index, model in ipairs(models) do
		local state = states[index]
		local ok, err = pcall(function()
			model:SetPrimaryPartCFrame(
				CFrame.new(state.position.x, state.position.y, state.position.z) * CFrame.Angles(0, state.yaw, 0)
			)
		end)
		if not ok then
			warn("animals_r8: could not place " .. state.id .. ": " .. tostring(err))
		end
	end
end

local function apply(plan: any?)
	if applied then
		return
	end
	mapSpec = loadMapSpec(plan)
	if not mapSpec then
		warn("animals_r8: MapSpec unavailable (ServerScriptService.Server.World.MapSpec)")
		return
	end
	local builtBounds = Animals.bounds(mapSpec)
	if not builtBounds then
		warn("animals_r8: MapSpec is missing GROUND_Y / TERRAIN_HALF")
		return
	end
	local okSpawn, spawned = pcall(Animals.spawn, mapSpec)
	if not okSpawn or type(spawned) ~= "table" or #spawned == 0 or #spawned > Animals.MAX_ANIMALS then
		warn("animals_r8: spawn failed: " .. tostring(spawned))
		return
	end
	local okFolder, created = pcall(function()
		local existing = game:GetService("Workspace"):FindFirstChild(Animals.folder)
		if existing then
			existing:Destroy()
		end
		local f = Instance.new("Folder")
		f.Name = Animals.folder
		f.Parent = game:GetService("Workspace")
		return f
	end)
	if not okFolder or not created then
		warn("animals_r8: could not create " .. Animals.folder .. ": " .. tostring(created))
		return
	end

	folder = created
	bounds = builtBounds
	states, models = spawned, {}
	for _, state in ipairs(states) do
		local model = buildAnimal(state, folder)
		if model then
			models[#models + 1] = model
		end
	end

	local heartbeat = nil
	if type(plan) == "table" then
		heartbeat = plan.heartbeat
	end
	if not heartbeat then
		local okHeartbeat, service = pcall(function()
			return game:GetService("RunService").Heartbeat
		end)
		if okHeartbeat then
			heartbeat = service
		end
	end
	if heartbeat and type(heartbeat.Connect) == "function" then
		local okConnect, result = pcall(function()
			return heartbeat:Connect(tick)
		end)
		if okConnect then
			connection = result
		else
			warn("animals_r8: Heartbeat connect failed: " .. tostring(result))
		end
	else
		warn("animals_r8: no Heartbeat available; models stay at their spawn positions")
	end
	applied = true
end

local function restore()
	if not applied then
		return
	end
	applied = false
	if connection then
		pcall(function()
			connection:Disconnect()
		end)
	end
	connection = nil
	if folder then
		pcall(function()
			folder:Destroy()
		end)
	end
	folder = nil
	states, models = {}, {}
	bounds, mapSpec = nil, nil
end

-- Deterministic 60-second helper. Reuses the pure simulation; `clock` is injectable like
-- FidelityRuntime.start({ clock = ... }) in the client feel layer.
function LookDevAnimalsR8.simulate(inputStates: any?, seconds: number?, dt: number?, inputBounds: any?, clock: any?)
	local source = inputStates or states
	local limit = inputBounds or bounds
	local now = clock or os.clock
	local started = now()
	local finalStates, steps = Animals.simulate(source, seconds or Animals.SIM_SECONDS, dt or Animals.DT, limit)
	return finalStates, now() - started, steps
end

LookDevAnimalsR8.tick = tick
LookDevAnimalsR8.apply = apply
LookDevAnimalsR8.restore = restore
LookDevAnimalsR8.isApplied = function()
	return applied
end

LookDev.register(Animals.id, { apply = apply, restore = restore })

return LookDevAnimalsR8
