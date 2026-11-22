-- LookDevSmokeR8: client applier for the OFF-BY-DEFAULT "smoke_r8" candidate (WORK_QUEUE section
-- M item 84). Two chimney smoke columns, Warung-counter steam and one torch per MapSpec hub. Flame
-- emitters and their flickering PointLights are gated on isNight(Lighting.ClockTime); ClockTime 13
-- leaves them off. One Heartbeat drives the pure Smoke.flicker multiplier. No asset IDs, no real
-- brand, no Lighting writes; restore destroys every instance and disconnects both signals.
--
-- apply(plan) accepts injected mapSpec / lighting / heartbeat / workspace deps for deterministic
-- tests; with no injection it reads MapSpec from ServerScriptService.Server.World when available.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local LookDev = require(Shared.LookDev)
local Smoke = require(Shared.ModelMapSmokeR8)

local LookDevSmokeR8 = {}

local applied = false
local folder: Instance? = nil
local Lighting: any = nil
local heartbeatConnection: any = nil
local clockConnection: any = nil
local flameEmitters: { any } = {}
local torchLights: { any } = {}
local elapsed = 0

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

local function buildSource(spec: any, parent: Instance, kind: string): Instance?
	local ok, part = pcall(function()
		local p = Instance.new("Part")
		p.Name = kind .. "_" .. spec.id
		p.Size = Vector3.new(0.5, 0.5, 0.5)
		p.CFrame = CFrame.new(vec(spec.position))
		p.Anchored = true
		p.CanCollide = false
		p.CastShadow = false
		p.Transparency = 1
		p.Parent = parent
		return p
	end)
	if not ok or not part then
		warn("smoke_r8: could not build emitter source " .. tostring(spec.id) .. ": " .. tostring(part))
		return nil
	end
	return part
end

local function buildEmitter(spec: any, parent: Instance): any?
	local part = buildSource(spec, parent, "Source")
	if not part then
		return nil
	end
	local ok, emitter = pcall(function()
		local pe = Instance.new("ParticleEmitter")
		pe.Name = "Rate"
		pe.Rate = spec.rate
		pe.Lifetime = NumberRange.new(1.4, 2.2)
		pe.Speed = NumberRange.new(1.2, 2)
		pe.SpreadAngle = Vector2.new(10, 10)
		pe.Enabled = not spec.nightOnly
		pe.Parent = part
		return pe
	end)
	if not ok or not emitter then
		warn("smoke_r8: could not build ParticleEmitter " .. tostring(spec.id) .. ": " .. tostring(emitter))
		pcall(function()
			part:Destroy()
		end)
		return nil
	end
	return emitter
end

local function buildTorchPost(spec: any, parent: Instance, ground: number): Instance?
	local height = Smoke.LAMP_RANGE * 0.8
	local ok, post = pcall(function()
		local p = Instance.new("Part")
		p.Name = "TorchPost_" .. spec.id
		p.Size = Vector3.new(0.6, height, 0.6)
		p.CFrame = CFrame.new(spec.position.x, ground + height / 2, spec.position.z)
		p.Color = Color3.fromRGB(112, 78, 48)
		p.Anchored = true
		p.CanCollide = false
		p.CastShadow = false
		p.Parent = parent
		return p
	end)
	if not ok or not post then
		warn("smoke_r8: could not build torch post " .. tostring(spec.id) .. ": " .. tostring(post))
		return nil
	end
	return post
end

local function buildLight(spec: any, parent: Instance): any?
	local ok, light = pcall(function()
		local point = Instance.new("PointLight")
		point.Name = "Flicker"
		point.Range = spec.range
		point.Brightness = 0.9
		point.Color = Color3.fromRGB(255, 178, 84)
		point.Enabled = false
		point.Parent = parent
		return point
	end)
	if not ok or not light then
		warn("smoke_r8: could not build PointLight " .. tostring(spec.id) .. ": " .. tostring(light))
		return nil
	end
	return light
end

-- Single gate for both the flames and their lights. The literal expression is the day-off rule
-- the level-2 spec checks: at ClockTime 13 isNight is false and every torch is disabled.
local function gateTorches()
	if not applied or not Lighting then
		return
	end
	local on = Smoke.isNight(Lighting.ClockTime)
	for _, emitter in ipairs(flameEmitters) do
		emitter.Enabled = on
	end
	for _, entry in ipairs(torchLights) do
		entry.light.Enabled = on
	end
end

local function tick(dt: number)
	if not applied or not Lighting then
		return
	end
	elapsed += math.clamp(type(dt) == "number" and dt or 0, 0, 0.25)
	if not Smoke.isNight(Lighting.ClockTime) then
		return
	end
	for _, entry in ipairs(torchLights) do
		entry.light.Brightness = entry.base * Smoke.flicker(elapsed, entry.seed)
	end
end

local function apply(plan: any?)
	if applied then
		return
	end
	local mapSpec = loadMapSpec(plan)
	if not mapSpec then
		warn("smoke_r8: MapSpec unavailable (ServerScriptService.Server.World.MapSpec)")
		return
	end
	local built = Smoke.recipes(mapSpec)
	if Smoke.emitterCount(built) > Smoke.MAX_EMITTERS or Smoke.lightCount(built) > Smoke.MAX_LIGHTS then
		warn("smoke_r8: recipe exceeds the item-84 emitter or light budget")
		return
	end

	local service = type(plan) == "table" and plan.lighting or nil
	if not service then
		local okLighting, found = pcall(function()
			return game:GetService("Lighting")
		end)
		service = okLighting and found or nil
	end
	if not service then
		warn("smoke_r8: Lighting unavailable; torches stay off")
		return
	end
	Lighting = service

	local workspaceService = type(plan) == "table" and plan.workspace or nil
	if not workspaceService then
		local okWorkspace, found = pcall(function()
			return game:GetService("Workspace")
		end)
		workspaceService = okWorkspace and found or nil
	end
	if not workspaceService then
		warn("smoke_r8: Workspace unavailable")
		Lighting = nil
		return
	end
	local okFolder, created = pcall(function()
		local existing = workspaceService:FindFirstChild(Smoke.folder)
		if existing then
			existing:Destroy()
		end
		local f = Instance.new("Folder")
		f.Name = Smoke.folder
		f.Parent = workspaceService
		return f
	end)
	if not okFolder or not created then
		warn("smoke_r8: could not create " .. Smoke.folder .. ": " .. tostring(created))
		Lighting = nil
		return
	end
	folder = created
	applied = true
	elapsed = 0
	flameEmitters, torchLights = {}, {}

	for _, spec in ipairs(built.emitters) do
		local emitter = buildEmitter(spec, folder)
		if emitter and spec.nightOnly then
			flameEmitters[#flameEmitters + 1] = emitter
		end
	end
	local byId = {}
	for _, lightSpec in ipairs(built.lights) do
		byId[lightSpec.id] = lightSpec
	end
	for _, spec in ipairs(built.emitters) do
		if spec.kind == "torch_flame" then
			local lightSpec = byId[string.gsub(spec.id, "_flame$", "_light")]
			if lightSpec then
				buildTorchPost(spec, folder, mapSpec.GROUND_Y)
				local light = buildLight(lightSpec, folder)
				if light then
					torchLights[#torchLights + 1] = { light = light, seed = lightSpec.seed, base = 0.9 }
				end
			end
		end
	end
	gateTorches()

	local heartbeat = type(plan) == "table" and plan.heartbeat or nil
	if not heartbeat then
		local okHeartbeat, serviceOrErr = pcall(function()
			return game:GetService("RunService").Heartbeat
		end)
		heartbeat = okHeartbeat and serviceOrErr or nil
	end
	if heartbeat and type(heartbeat.Connect) == "function" then
		local okConnect, connection = pcall(function()
			return heartbeat:Connect(tick)
		end)
		if okConnect then
			heartbeatConnection = connection
		else
			warn("smoke_r8: Heartbeat connect failed: " .. tostring(connection))
		end
	end
	if type(service.GetPropertyChangedSignal) == "function" then
		local okClock, connection = pcall(function()
			return service:GetPropertyChangedSignal("ClockTime"):Connect(gateTorches)
		end)
		if okClock then
			clockConnection = connection
		else
			warn("smoke_r8: ClockTime connect failed: " .. tostring(connection))
		end
	end
end

local function restore()
	if not applied then
		return
	end
	applied = false
	if heartbeatConnection then
		pcall(function()
			heartbeatConnection:Disconnect()
		end)
	end
	heartbeatConnection = nil
	if clockConnection then
		pcall(function()
			clockConnection:Disconnect()
		end)
	end
	clockConnection = nil
	if folder then
		pcall(function()
			folder:Destroy()
		end)
	end
	folder = nil
	Lighting = nil
	flameEmitters, torchLights = {}, {}
	elapsed = 0
end

LookDevSmokeR8.apply = apply
LookDevSmokeR8.restore = restore
LookDevSmokeR8.gateTorches = gateTorches
LookDevSmokeR8.tick = tick
LookDevSmokeR8.isApplied = function()
	return applied
end

LookDev.register(Smoke.id, { apply = apply, restore = restore })

return LookDevSmokeR8
