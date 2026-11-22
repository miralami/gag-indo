-- LookDevFlyersR8: client applier for the OFF-BY-DEFAULT "flyers_r8" candidate (WORK_QUEUE section
-- M item 83). Burung circling high, kupu-kupu near the plaza flower beds / sawah verge and capung
-- darting by the river near the bridge. ONE Heartbeat connection drives the pure shared step
-- function; no asset IDs, no physics and no game-state mutation. Everything is destroyed on
-- restore.
--
-- The pure step/sim lives in Shared.ModelMapFlyersR8; the harness calls it directly in the Server
-- VM for FLYER_COUNT / FLYER_COST, so Studio needs no 60-second real-time wait.
-- `apply({ mapSpec = ..., heartbeat = ..., tier = ... })` accepts injected deps for deterministic
-- Lune specs; with no injection it reads MapSpec from ServerScriptService.Server.World when
-- available and falls back to RunService.Heartbeat. Failures publish a warn and leave `applied`
-- false.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local LookDev = require(Shared.LookDev)
local Flyers = require(Shared.ModelMapFlyersR8)

local LookDevFlyersR8 = {}

local applied = false
local folder: Instance? = nil
local connection: any = nil
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

local function buildFlyer(state: any, parent: Instance): any?
	local okModel, model = pcall(function()
		local m = Instance.new("Model")
		m.Name = state.id
		m.Parent = parent
		return m
	end)
	if not okModel or not model then
		return nil
	end
	local entry = { model = model, body = nil, wingL = nil, wingR = nil }
	local recipes = Flyers.PARTS[state.kind] or {}
	for _, recipe in ipairs(recipes) do
		local partOk, built = pcall(function()
			local part = Instance.new("Part")
			part.Name = recipe[1]
			part.Size = vec(recipe[2])
			part.Color = Color3.fromRGB(recipe[4][1], recipe[4][2], recipe[4][3])
			part.Anchored = true
			part.CanCollide = false
			part.CastShadow = false
			part.Parent = model
			return part
		end)
		if not partOk or not built then
			warn("flyers_r8: could not build " .. state.id .. "." .. tostring(recipe[1]) .. ": " .. tostring(built))
		elseif recipe[1] == "Body" then
			entry.body = built
		elseif recipe[1] == "WingL" then
			entry.wingL = built
		elseif recipe[1] == "WingR" then
			entry.wingR = built
		end
	end
	if not entry.body or not entry.wingL or not entry.wingR then
		pcall(function()
			model:Destroy()
		end)
		return nil
	end
	return entry
end

local function tick(dt: number)
	if not applied then
		return
	end
	Flyers.stepAll(states, dt, bounds)
	for index, entry in ipairs(models) do
		local state = states[index]
		local ok, err = pcall(function()
			local root = CFrame.new(state.position.x, state.position.y, state.position.z)
				* CFrame.Angles(0, state.yaw, 0)
			entry.body.CFrame = root
			local recipes = Flyers.PARTS[state.kind]
			entry.wingL.CFrame = root * CFrame.new(vec(recipes[2][3])) * CFrame.Angles(0, 0, state.wing)
			entry.wingR.CFrame = root * CFrame.new(vec(recipes[3][3])) * CFrame.Angles(0, 0, -state.wing)
		end)
		if not ok then
			warn("flyers_r8: could not place " .. state.id .. ": " .. tostring(err))
		end
	end
end

local function apply(plan: any?)
	if applied then
		return
	end
	local mapSpec = loadMapSpec(plan)
	if not mapSpec then
		warn("flyers_r8: MapSpec unavailable (ServerScriptService.Server.World.MapSpec)")
		return
	end
	local builtBounds = Flyers.bounds(mapSpec)
	if not builtBounds then
		warn("flyers_r8: MapSpec is missing GROUND_Y / TERRAIN_HALF")
		return
	end
	local tier = type(plan) == "table" and plan.tier or "Tinggi"
	local cap = Flyers.caps(tier)
	local capTotal = cap.burung + cap.kupu + cap.capung
	local okSpawn, spawned = pcall(Flyers.spawn, mapSpec, tier)
	if not okSpawn or type(spawned) ~= "table" or #spawned == 0 or #spawned > capTotal then
		warn("flyers_r8: spawn failed: " .. tostring(spawned))
		return
	end
	local okFolder, created = pcall(function()
		local existing = game:GetService("Workspace"):FindFirstChild(Flyers.folder)
		if existing then
			existing:Destroy()
		end
		local f = Instance.new("Folder")
		f.Name = Flyers.folder
		f.Parent = game:GetService("Workspace")
		return f
	end)
	if not okFolder or not created then
		warn("flyers_r8: could not create " .. Flyers.folder .. ": " .. tostring(created))
		return
	end

	folder = created
	bounds = builtBounds
	states, models = spawned, {}
	for _, state in ipairs(states) do
		local entry = buildFlyer(state, folder)
		if entry then
			models[#models + 1] = entry
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
			warn("flyers_r8: Heartbeat connect failed: " .. tostring(result))
		end
	else
		warn("flyers_r8: no Heartbeat available; models stay at their spawn positions")
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
	bounds = nil
end

-- Deterministic 60-second helper. Reuses the pure simulation; `clock` is injectable like
-- FidelityRuntime.start({ clock = ... }) in the client feel layer.
function LookDevFlyersR8.simulate(inputStates: any?, seconds: number?, dt: number?, inputBounds: any?, clock: any?)
	local source = inputStates or states
	local limit = inputBounds or bounds
	local now = clock or os.clock
	local started = now()
	local finalStates, steps = Flyers.simulate(source, seconds or Flyers.SIM_SECONDS, dt or Flyers.DT, limit)
	return finalStates, steps, now() - started
end

LookDevFlyersR8.tick = tick
LookDevFlyersR8.apply = apply
LookDevFlyersR8.restore = restore
LookDevFlyersR8.isApplied = function()
	return applied
end

LookDev.register(Flyers.id, { apply = apply, restore = restore })

return LookDevFlyersR8
