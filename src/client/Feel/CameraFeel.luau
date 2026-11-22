-- CameraFeel: a small field-of-view kick while the character runs fast (RESEARCH_VISUAL_TIPS:
-- "FOV, camera and footsteps polish"). Driven only by the character's movement, so it works the
-- same on touch, gamepad and keyboard. Client only; the server never reads the camera.
--
-- Idle rests at 72 (default 70). Moving above the default WalkSpeed (16) eases toward 76 and
-- back to 72 when the character stops. One tween at a time; a new target cancels the old one.

local CameraFeel = {}

local BASE_FOV = 72
local MAX_EXTRA_FOV = 4 -- 72 + 4 = 76 at full speed
local DEFAULT_WALK_SPEED = 16
local FULL_SPEED_RANGE = 8 -- WalkSpeed 24 (16 + 8) counts as full run
local TWEEN_SECONDS = 0.4
local SAMPLE_SECONDS = 0.1 -- read movement ten times a second, not every frame

-- Pure: 0 (idle or walking speed) to 1 (full run), from the humanoid's WalkSpeed.
function CameraFeel.ratioFor(walkSpeed: number, moving: boolean): number
	if not moving or walkSpeed <= DEFAULT_WALK_SPEED then
		return 0
	end
	return math.clamp((walkSpeed - DEFAULT_WALK_SPEED) / FULL_SPEED_RANGE, 0, 1)
end

-- Pure: FOV for a speed ratio. Clamped to 72..76 and never decreasing as the ratio grows.
function CameraFeel.targetFov(speedRatio: number): number
	local ratio = speedRatio
	if ratio ~= ratio then -- NaN guard
		ratio = 0
	end
	return BASE_FOV + MAX_EXTRA_FOV * math.clamp(ratio, 0, 1)
end

local started = false
local TweenService = nil
local tweenInfo = nil
local connections = {}
local humanoid = nil
local goalFov = nil
local activeTween = nil
local elapsed = 0
local bindGeneration = 0
local pausedBy: { [any]: boolean } = {}
local pauseCount = 0

local function setTarget(fov: number)
	if fov == goalFov then
		return
	end
	goalFov = fov

	local camera = game:GetService("Workspace").CurrentCamera
	if not camera then
		return
	end

	if activeTween then
		activeTween:Cancel()
		activeTween = nil
	end
	activeTween = TweenService:Create(camera, tweenInfo, { FieldOfView = fov })
	activeTween:Play()
end

local function step(dt: number)
	if pauseCount > 0 then
		return
	end
	elapsed += dt
	if elapsed < SAMPLE_SECONDS then
		return
	end
	elapsed = 0

	if not humanoid then
		return
	end
	local moving = humanoid.MoveDirection.Magnitude > 0
	setTarget(CameraFeel.targetFov(CameraFeel.ratioFor(humanoid.WalkSpeed, moving)))
end

-- Drops the previous character's humanoid and resets the camera to rest, then waits for the new
-- Humanoid. The generation counter stops a late WaitForChild from binding a stale character.
local function unbind()
	bindGeneration += 1
	humanoid = nil
	goalFov = nil
	if activeTween then
		activeTween:Cancel()
		activeTween = nil
	end
end

local function bind(character: Instance)
	unbind()
	local generation = bindGeneration
	task.spawn(function()
		local found = character:WaitForChild("Humanoid", 10)
		if generation == bindGeneration and found and found:IsA("Humanoid") then
			humanoid = found
			goalFov = nil
		end
	end)
end

-- Override API: while any owner has paused CameraFeel its step loop writes neither FOV nor CFrame
-- (a cutscene owns the camera). Owners are keyed, so two systems pausing and resuming in any order
-- never release each other's hold; pausing twice with one owner counts once. A nil owner is ignored.
function CameraFeel.pause(owner: any)
	if owner == nil or pausedBy[owner] then
		return
	end
	pausedBy[owner] = true
	pauseCount += 1
	if activeTween then
		activeTween:Cancel()
		activeTween = nil
	end
	goalFov = nil
end

-- Releases one owner's hold. When the last hold is released the default FOV (rest 72) is eased back
-- in with the normal tween, from whatever FOV the cutscene left. Resuming without a hold is a no-op.
function CameraFeel.resume(owner: any)
	if owner == nil or not pausedBy[owner] then
		return
	end
	pausedBy[owner] = nil
	pauseCount -= 1
	if pauseCount > 0 then
		return
	end
	goalFov = nil
	elapsed = 0
	local ok = pcall(function()
		if not TweenService then
			TweenService = game:GetService("TweenService")
			tweenInfo = TweenInfo.new(TWEEN_SECONDS, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
		end
		setTarget(CameraFeel.targetFov(0))
	end)
	if not ok then
		goalFov = nil -- no camera or services (e.g. Lune): the next sample retargets
	end
end

function CameraFeel.isPaused(): boolean
	return pauseCount > 0
end

function CameraFeel.start()
	if started then
		return
	end
	started = true

	TweenService = game:GetService("TweenService")
	tweenInfo = TweenInfo.new(TWEEN_SECONDS, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

	local player = game:GetService("Players").LocalPlayer
	local RunService = game:GetService("RunService")

	table.insert(connections, player.CharacterAdded:Connect(bind))
	table.insert(connections, player.CharacterRemoving:Connect(unbind))
	table.insert(connections, RunService.Heartbeat:Connect(step))

	if player.Character then
		bind(player.Character)
	end
end

-- Disconnects every signal this controller owns. A test/hot-reload helper; a normal client keeps
-- them for its whole life. Safe to call even when start() was never called.
function CameraFeel.stop()
	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	table.clear(connections)
	unbind()
	started = false
end

function CameraFeel.isStarted(): boolean
	return started
end

return CameraFeel
