--!strict
-- LookDevNightR8: SERVER-ONLY applier for the OFF-BY-DEFAULT "night_r8" candidate
-- (WORK_QUEUE section M item 90). It stages 16 warm window panes and 12 shadowless PointLights
-- (6 street posts + 6 torches = Rendah budget) from pure Shared.ModelMapNightR8 data.
--
-- The live gate reads Lighting.ClockTime and its GetPropertyChangedSignal. For deterministic Studio
-- checks only, setClockForCheck(clock)/clearClockForCheck() drive the SAME gate without writing to
-- Lighting: 20 lights everything, 13 leaves 0 lit panes and 0 enabled lights. restore() is exact and
-- idempotent: destroy the staged folder, disconnect the listener, clear the override, restore any
-- prior folder and publish load failures through Shared.LookDevFailures. No asset IDs.
--
--   require(game.ReplicatedStorage.Shared.LookDevReview).enable("night_r8", game)

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if ok then
		return value
	end
	warn("[LookDevNightR8] missing service " .. name)
	return nil
end

local ReplicatedStorage = service("ReplicatedStorage")
local Workspace = service("Workspace")
if not ReplicatedStorage or not Workspace then
	return {}
end

local okShared, Shared = pcall(function()
	return (ReplicatedStorage :: any):WaitForChild("Shared")
end)
if not okShared or not Shared then
	warn("[LookDevNightR8] missing Shared folder")
	return {}
end

local okModules, LookDev, Data, Failures = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapNightR8),
		require((Shared :: any).LookDevFailures)
end)
if not okModules or not LookDev or not Data or not Failures then
	warn("[LookDevNightR8] could not require LookDev / ModelMapNightR8 / LookDevFailures")
	return {}
end

local LookDevNightR8 = {}

local FAMILY_ID: string = Data.id
local applied = false
local folder: any? = nil
local savedFolder: any? = nil
local Lighting: any? = nil
local clockConnection: any? = nil
local clockOverride: number? = nil
local windows: { any } = {}
local lights: { any } = {}
local tracked: { any } = {}
local failures = 0

local function fail(message: string)
	failures += 1
	warn("[LookDevNightR8] " .. message)
end

local function publishFailures()
	pcall(function()
		Failures.set(FAMILY_ID, failures)
	end)
end

local function track(instance: any?)
	if instance then
		tracked[#tracked + 1] = instance
	end
end

local function clearActive()
	for index = #tracked, 1, -1 do
		pcall(function()
			tracked[index]:Destroy()
		end)
	end
	table.clear(tracked)
	table.clear(windows)
	table.clear(lights)
	local current = folder
	if current then
		pcall(function()
			current:Destroy()
		end)
	end
	folder = nil
end

local function currentClock(): number
	if clockOverride ~= nil then
		return clockOverride
	end
	if Lighting then
		local ok, value = pcall(function()
			return Lighting.ClockTime
		end)
		if ok and type(value) == "number" and value == value then
			return value
		end
	end
	return 12 -- unreadable clock is day: never light by accident
end

-- One gate for panes and lights. It is called on apply, on every Lighting.ClockTime change and on
-- both clock-override calls, so the override cannot drift from the live path.
local function applyGate()
	if not applied then
		return
	end
	local on = Data.isNight(currentClock())
	for _, entry in ipairs(windows) do
		local part = entry.part
		pcall(function()
			part.Material = Enum.Material[if on then Data.WINDOW_MATERIAL else Data.DAY_WINDOW_MATERIAL]
			part.Color = Color3.fromRGB(
				(if on then Data.WINDOW_RGB else Data.DAY_WINDOW_RGB)[1],
				(if on then Data.WINDOW_RGB else Data.DAY_WINDOW_RGB)[2],
				(if on then Data.WINDOW_RGB else Data.DAY_WINDOW_RGB)[3]
			)
			part.Transparency = if on then Data.WINDOW_TRANSPARENCY else Data.DAY_WINDOW_TRANSPARENCY
			part:SetAttribute("Lit", on)
		end)
	end
	for _, entry in ipairs(lights) do
		local point = entry.light
		pcall(function()
			point.Enabled = on
			point.Brightness = if on then Data.GLOW_INTENSITY else 0
		end)
	end
end

local function stageWindow(index: number, spec: any, parent: any): boolean
	local okNew, part = pcall(function()
		return Instance.new("Part")
	end)
	if not okNew or not part then
		fail("could not create window pane " .. tostring(index))
		return false
	end
	track(part)
	local okSet = pcall(function()
		part.Name = "LookDevNightR8_Window_" .. index
		part.Size = Vector3.new(spec.size[1], spec.size[2], spec.size[3])
		part.CFrame = CFrame.new(spec.x, spec.y, spec.z) * CFrame.Angles(0, math.rad(spec.orientation or 0), 0)
		part.Anchored = true
		part.CanCollide = false
		part.CastShadow = false
		part:SetAttribute("NightR8", "window")
		part:SetAttribute("HubKey", spec.hubKey)
		part:SetAttribute("WindowSource", spec.source)
		part:SetAttribute("Lit", false)
		part.Parent = parent
	end)
	if not okSet then
		fail("could not configure window pane " .. tostring(index))
		return false
	end
	windows[#windows + 1] = { part = part }
	return true
end

local function stageLamp(spec: any, parent: any): boolean
	local okNew, carrier = pcall(function()
		return Instance.new("Part")
	end)
	if not okNew or not carrier then
		fail("could not create lamp carrier " .. tostring(spec.id))
		return false
	end
	track(carrier)
	local okCarrier = pcall(function()
		carrier.Name = tostring(spec.name)
		carrier.Size = Vector3.new(0.5, 0.5, 0.5)
		carrier.CFrame = CFrame.new(spec.x, spec.y, spec.z)
		carrier.Anchored = true
		carrier.CanCollide = false
		carrier.CastShadow = false
		carrier.Transparency = 1
		carrier:SetAttribute("NightR8", spec.kind)
		carrier:SetAttribute("HubKey", spec.hubKey)
		carrier:SetAttribute("LampId", spec.id)
		carrier.Parent = parent
	end)
	if not okCarrier then
		fail("could not configure lamp carrier " .. tostring(spec.id))
		return false
	end
	local okPoint, point = pcall(function()
		return Instance.new("PointLight")
	end)
	if not okPoint or not point then
		fail("could not create PointLight " .. tostring(spec.id))
		return false
	end
	track(point)
	local okLight = pcall(function()
		point.Name = "Glow"
		point.Range = Data.LAMP_RANGE
		point.Brightness = 0
		point.Color = Color3.fromRGB(255, 203, 122)
		point.Shadows = false -- Rendah lamp budget: no shadow-casting lights
		point.Enabled = false
		point.Parent = carrier
	end)
	if not okLight then
		fail("could not configure PointLight " .. tostring(spec.id))
		return false
	end
	lights[#lights + 1] = { light = point, kind = spec.kind }
	return true
end

local function apply()
	failures = 0
	if applied then
		return
	end
	clearActive()

	local okService, lightingService = pcall(function()
		return game:GetService("Lighting")
	end)
	if not okService or not lightingService then
		fail("Lighting unavailable")
		publishFailures()
		return
	end
	Lighting = lightingService

	local okFind, previous = pcall(function()
		return (Workspace :: any):FindFirstChild(Data.folder)
	end)
	if okFind and previous then
		pcall(function()
			previous.Parent = nil
		end)
		savedFolder = previous
	end

	local okFolder, newFolder = pcall(function()
		return Instance.new("Folder")
	end)
	if not okFolder or not newFolder then
		fail("could not create staging folder")
		publishFailures()
		return
	end
	track(newFolder)
	folder = newFolder
	pcall(function()
		newFolder.Name = Data.folder
		newFolder.Parent = Workspace
		newFolder:SetAttribute("NightR8", Data.id)
	end)

	if #Data.WINDOW_SPECS > Data.MAX_WINDOWS or #Data.LAMP_SPECS ~= Data.GLOW_LIGHT_COUNT then
		fail("pure spec counts exceed the documented budget")
	end
	if #Data.LAMP_SPECS > Data.MAX_LIGHTS then
		fail("lamp count exceeds MAX_LIGHTS")
	end
	for index, spec in ipairs(Data.WINDOW_SPECS) do
		stageWindow(index, spec, newFolder)
	end
	for _, spec in ipairs(Data.LAMP_SPECS) do
		stageLamp(spec, newFolder)
	end

	applied = true
	applyGate()

	local okListen, connection = pcall(function()
		return Lighting:GetPropertyChangedSignal("ClockTime"):Connect(applyGate)
	end)
	if okListen and connection then
		clockConnection = connection
	else
		fail("could not listen to Lighting.ClockTime")
	end
	publishFailures()
end

local function restore()
	if not applied and folder == nil and clockConnection == nil and clockOverride == nil and savedFolder == nil then
		return
	end
	if clockConnection then
		pcall(function()
			clockConnection:Disconnect()
		end)
		clockConnection = nil
	end
	clockOverride = nil
	applied = false
	clearActive()
	local previous = savedFolder
	if previous then
		pcall(function()
			previous.Parent = Workspace
		end)
		savedFolder = nil
	end
	Lighting = nil
	publishFailures()
end

function LookDevNightR8.setClockForCheck(clock: any): boolean
	if type(clock) ~= "number" or clock ~= clock or clock == math.huge or clock == -math.huge then
		return false
	end
	clockOverride = clock
	applyGate()
	return true
end

function LookDevNightR8.clearClockForCheck(): boolean
	clockOverride = nil
	applyGate()
	return true
end

function LookDevNightR8.diagnostics(): any
	local clock = currentClock()
	local night = Data.isNight(clock)
	local litWindows, enabledLights = 0, 0
	for _, entry in ipairs(windows) do
		local ok, lit = pcall(function()
			return entry.part:GetAttribute("Lit")
		end)
		if ok and lit == true then
			litWindows += 1
		end
	end
	for _, entry in ipairs(lights) do
		local ok, enabled = pcall(function()
			return entry.light.Enabled
		end)
		if ok and enabled == true then
			enabledLights += 1
		end
	end
	return {
		clock = clock,
		isNight = night,
		litWindows = litWindows,
		lightCount = #lights,
		windowParts = #windows,
		litParts = litWindows + enabledLights,
		enabledLights = enabledLights,
		override = clockOverride,
		folderPresent = folder ~= nil,
		failures = failures,
		litAt20 = Data.litWindowCount(20),
		litAt13 = Data.litWindowCount(13),
	}
end

LookDevNightR8.apply = apply
LookDevNightR8.restore = restore

LookDev.register("night_r8", { apply = apply, restore = restore })

return LookDevNightR8
