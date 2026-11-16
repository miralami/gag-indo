-- RaidOverlay: sinetron-style full-screen raid (GDD 5.3, 10) + the Pos Ronda countdown.
-- The server owns the state machine; this module only presents it and sends Raid_Choose.
-- Refactored for W2: palette tokens from Theme, display font, Icons, no hardcoded RGB.

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Strings = require(Shared.Strings)
local Remotes = require(Shared.Remotes)
local RaidCutscene = require(Shared.Config.RaidCutscene)

local Audio = require(script.Parent.Parent.Audio)
local Icons = require(script.Parent.Icons)
local Theme = require(script.Parent.Theme)
local MomentGuard = require(script.Parent.Parent.Feel.MomentGuard)
local CameraFeel = require(script.Parent.Parent.Feel.CameraFeel)
local CutsceneSequencer = require(script.Parent.Parent.Feel.CutsceneSequencer)
local CutsceneState = require(script.Parent.Parent.Feel.CutsceneState)

local RaidOverlay = {}

function RaidOverlay.mount(lang: string)
	local t = function(key: string, ...: any): string
		return Strings.get(lang, key, ...)
	end

	local gui = Theme.screenGui("RaidOverlay", 70)

	local scrim = Theme.new("Frame", {
		Name = "Scrim",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.merah,
		BackgroundTransparency = 0.45,
		Visible = false,
		Parent = gui,
	})

	-- BREAKING NEWS banner
	local banner = Theme.new("Frame", {
		Name = "Banner",
		Position = UDim2.fromScale(0, 0.06),
		Size = UDim2.new(1, 0, 0, 54),
		BackgroundColor3 = Theme.merah,
		BorderSizePixel = 0,
		Parent = scrim,
	})
	local breakingLabel = Theme.label({
		Size = UDim2.fromScale(1, 0.55),
		Text = t("raid_breaking"),
		Font = Theme.displayFont,
		TextColor3 = Theme.paper,
		Parent = banner,
	})
	breakingLabel.TextSize = 16
	local bannerTitle = Theme.label({
		Position = UDim2.fromScale(0, 0.55),
		Size = UDim2.fromScale(1, 0.45),
		Text = t("raid_title"),
		TextColor3 = Theme.senja,
		Parent = banner,
	})
	bannerTitle.TextSize = 13
	local bannerStripe = Theme.new("Frame", {
		Name = "Stripe",
		Position = UDim2.fromScale(0, 0.94),
		Size = UDim2.new(1, 0, 0, 4),
		BackgroundColor3 = Theme.kunyit,
		BorderSizePixel = 0,
		Parent = banner,
	})

	-- Center card
	local card = Theme.card({
		Name = "Card",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.55),
		Size = UDim2.fromScale(0.84, 0.5),
		Parent = scrim,
	}, {
		Theme.new("UISizeConstraint", { MinSize = Vector2.new(300, 240), MaxSize = Vector2.new(520, 420) }),
	})
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 14)
	padding.PaddingRight = UDim.new(0, 14)
	padding.PaddingTop = UDim.new(0, 12)
	padding.PaddingBottom = UDim.new(0, 12)
	padding.Parent = card

	Icons.make("raid", {
		Position = UDim2.new(0, 0, 0, 8),
		Size = UDim2.fromOffset(28, 28),
		Color = Theme.merah,
		Parent = card,
	})

	local headline = Theme.label({
		Position = UDim2.new(0, 36, 0, 0),
		Size = UDim2.new(1, -36, 0, 44),
		Text = t("raid_title"),
		Font = Theme.displayFont,
		TextColor3 = Theme.merah,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})
	local subtitle = Theme.label({
		Position = UDim2.new(0, 0, 0, 46),
		Size = UDim2.new(1, 0, 0, 40),
		Text = t("raid_subtitle"),
		TextColor3 = Theme.ink,
		TextWrapped = true,
		Parent = card,
	})
	subtitle.TextSize = 15

	local waitLabel = Theme.label({
		Position = UDim2.new(0, 0, 0, 96),
		Size = UDim2.new(1, 0, 0, 60),
		Text = t("raid_wait"),
		TextColor3 = Theme.inkSoft,
		TextWrapped = true,
		Parent = card,
	})
	waitLabel.TextSize = 14

	local countdown = Theme.label({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.new(0.2, 0, 0, 34),
		Text = "",
		Font = Theme.displayFont,
		TextColor3 = Theme.merah,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = card,
	})

	local fineButton = Theme.button({
		Name = "Fine",
		Position = UDim2.new(0, 0, 1, -122),
		Size = UDim2.new(0.48, 0, 0, 110),
		Text = "",
		BackgroundColor3 = Theme.padi,
		Visible = false,
		Parent = card,
	})
	local amplopButton = Theme.button({
		Name = "Amplop",
		Position = UDim2.new(0.52, 0, 1, -122),
		Size = UDim2.new(0.48, 0, 0, 110),
		Text = "",
		BackgroundColor3 = Theme.bambu,
		Visible = false,
		Parent = card,
	})

	local skipButton = Theme.button({
		Name = "Skip",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -16),
		Size = UDim2.new(0, 140, 0, 44),
		Text = t("raid_skip"),
		BackgroundColor3 = Theme.inkSoft,
		Visible = false,
		Parent = scrim,
	})

	-- Pos Ronda countdown
	local jailBar = Theme.card({
		Name = "Jail",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 74),
		Size = UDim2.new(0.5, 0, 0, 56),
		BackgroundColor3 = Theme.bambu,
		Visible = false,
		Parent = gui,
	}, {
		Theme.new("UISizeConstraint", { MinSize = Vector2.new(240, 52), MaxSize = Vector2.new(420, 64) }),
	})
	local jailTitle = Theme.label({
		Size = UDim2.new(0.4, 0, 1, 0),
		Text = t("jail_title"),
		Font = Theme.displayFont,
		TextColor3 = Theme.ink,
		Parent = jailBar,
	})
	jailTitle.TextSize = 14
	local jailTime = Theme.label({
		Position = UDim2.new(0.4, 0, 0, 0),
		Size = UDim2.new(0.58, 0, 1, 0),
		Text = "",
		TextColor3 = Theme.ink,
		Parent = jailBar,
	})
	jailTime.TextSize = 14

	-- Letter slam: the card scales down from oversize onto the screen.
	local cardScale = Theme.new("UIScale", { Scale = 1, Parent = card })

	-- "BREAKING NEWS" lower third, shown from the first zoom shot until the letter lands. The text
	-- is 15 px and the bar sits above the skip button, inside the device safe area.
	local lowerThird = Theme.new("Frame", {
		Name = "LowerThird",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -72),
		Size = UDim2.new(0.92, 0, 0, 56),
		BackgroundColor3 = Theme.merah,
		BorderSizePixel = 0,
		Visible = false,
		Parent = scrim,
	}, {
		Theme.new("UISizeConstraint", { MinSize = Vector2.new(260, 56), MaxSize = Vector2.new(640, 72) }),
		Theme.new("UIStroke", { Color = Theme.kunyit, Thickness = 2 }),
	})
	local lowerThirdLabel = Theme.label({
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -20, 1, 0),
		Text = t("raid_lower_third"),
		TextColor3 = Theme.paper,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = lowerThird,
	})
	lowerThirdLabel.TextSize = 15
	pcall(function()
		(gui :: any).ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
	end)

	local pulseToken = 0
	local function pulse()
		pulseToken += 1
		local token = pulseToken
		task.spawn(function()
			while token == pulseToken and scrim.Visible do
				local tween = TweenService:Create(scrim, TweenInfo.new(0.5), {
					BackgroundTransparency = 0.25,
				})
				tween:Play()
				tween.Completed:Wait()
				if token ~= pulseToken or not scrim.Visible then
					return
				end
				local back = TweenService:Create(scrim, TweenInfo.new(0.5), {
					BackgroundTransparency = 0.55,
				})
				back:Play()
				back.Completed:Wait()
			end
		end)
	end

	local countdownToken = 0
	local function runCountdown(seconds: number)
		countdownToken += 1
		local token = countdownToken
		task.spawn(function()
			local remaining = seconds
			while token == countdownToken and remaining > 0 do
				countdown.Text = tostring(remaining)
				task.wait(1)
				remaining -= 1
			end
			countdown.Text = ""
		end)
	end

	local phase = "idle"

	-- Cutscene wiring. The decisions (which UI follows which shot, camera restore bookkeeping, the
	-- seen counter) are pure and live in Feel/CutsceneState; this block only touches Instances.
	local CUTSCENE_OWNER = "RaidCutscene"
	local player = Players.LocalPlayer
	local sequence: any = nil
	local renderConnection: RBXScriptConnection? = nil
	local deathConnections: { RBXScriptConnection } = {}
	local cameraRestore = CutsceneState.newCameraRestore()
	local uiState = CutsceneState.endedUi()
	local fovTween: Tween? = nil
	local pendingChoosing: any = nil
	local applyChoosing: (any) -> () = function() end

	local function currentCamera(): Camera?
		local ok, found = pcall(function()
			return workspace.CurrentCamera
		end)
		if ok then
			return found
		end
		return nil
	end

	local function stopFovTween()
		local tween = fovTween
		fovTween = nil
		if tween then
			pcall(function()
				tween:Cancel()
			end)
		end
	end

	local function tweenFov(fov: any, seconds: number)
		local camera = currentCamera()
		if not camera or type(fov) ~= "number" or fov ~= fov then
			return
		end
		stopFovTween()
		pcall(function()
			local tween = TweenService:Create(
				camera,
				TweenInfo.new(seconds, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
				{ FieldOfView = math.clamp(fov, 20, 100) }
			)
			fovTween = tween
			tween:Play()
		end)
	end

	-- Takes the camera for the shots: remembers the previous CameraType/FOV once, switches to
	-- Scriptable and tells CameraFeel to stop writing FOV.
	local function takeCamera()
		CameraFeel.pause(CUTSCENE_OWNER)
		local camera = currentCamera()
		if not camera then
			return
		end
		pcall(function()
			cameraRestore.capture(camera.CameraType, camera.FieldOfView)
			camera.CameraType = Enum.CameraType.Scriptable
		end)
	end

	-- Safe to call any number of times (finish, skip, cancel, hide, death).
	local function releaseCamera()
		stopFovTween()
		local saved = cameraRestore.release()
		local camera = currentCamera()
		if saved and camera then
			pcall(function()
				camera.CameraType = saved.cameraType
			end)
		end
		CameraFeel.resume(CUTSCENE_OWNER) -- eases FOV back to the default
	end

	local function rootPosition(): Vector3?
		local ok, position = pcall(function()
			local character = player and player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root and root:IsA("BasePart") then
				return root.Position
			end
			return nil
		end)
		if ok then
			return position
		end
		return nil
	end

	-- Per-frame camera placement. Focus targets (kades, police chief, road) have no world anchors
	-- yet, so every shot frames the local player from a different angle and distance.
	local function placeCamera(shot: any, progress: number)
		local camera = currentCamera()
		local base = rootPosition()
		if not camera or not base or type(shot) ~= "table" then
			return
		end
		pcall(function()
			local eye, target
			if shot.kind == "establish" then
				local dolly = if type(shot.dolly) == "number" then shot.dolly else 0
				eye = base + Vector3.new(0, 16, 34 + dolly * progress)
				target = base
			elseif shot.kind == "zoom" then
				local yaw = CFrame.Angles(0, math.rad(CutsceneState.focusOffset(shot.focus)), 0)
				eye = base + Vector3.new(0, 5, 0) + yaw * Vector3.new(0, 0, 18)
				target = base + Vector3.new(0, 2.5, 0)
			elseif shot.kind == "walkin" then
				eye = base + Vector3.new(0, 4, 40 - 22 * progress)
				target = base + Vector3.new(0, 3, 0)
			else
				return -- letter: hold the last frame
			end
			camera.CFrame = CFrame.lookAt(eye, target)
		end)
	end

	local function slamLetter(slam: boolean)
		cardScale.Scale = if slam then 1.35 else 1
		if slam then
			pcall(function()
				TweenService
					:Create(
						cardScale,
						TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
						{ Scale = 1 }
					)
					:Play()
			end)
		end
	end

	-- Mirrors the pure UI flags onto Instances. Before the letter lands the scrim stays clear so the
	-- shots are visible; the banner and card belong to the letter.
	local function applyUi(ui: any)
		lowerThird.Visible = ui.lowerThird
		card.Visible = ui.letter
		banner.Visible = ui.letter
	end

	local function disconnectAll()
		if renderConnection then
			renderConnection:Disconnect()
			renderConnection = nil
		end
		for _, connection in deathConnections do
			connection:Disconnect()
		end
		table.clear(deathConnections)
	end

	-- Ends the cutscene's hold on the screen. playedOut is true for a natural end or a skip, false
	-- for a cancel (hide, death, restart), which must not count as a viewing.
	local function endCutscene(playedOut: boolean)
		local running = sequence
		sequence = nil
		disconnectAll()
		if running and not playedOut then
			running.cancel()
		end
		releaseCamera()
		skipButton.Visible = false
		if playedOut then
			local seen = nil
			pcall(function()
				seen = player:GetAttribute(RaidCutscene.seenAttribute)
			end)
			pcall(function()
				player:SetAttribute(RaidCutscene.seenAttribute, CutsceneState.nextSeen(seen))
			end)
		end
		local letterShown = uiState.letter
		uiState = CutsceneState.endedUi()
		applyUi(uiState)
		if not letterShown then
			-- skipped or cancelled before the letter: show the card without the slam
			scrim.BackgroundTransparency = 0.45
			slamLetter(false)
			if scrim.Visible then
				pulse()
			end
		end
	end

	local function flushPendingChoosing()
		local payload = pendingChoosing
		pendingChoosing = nil
		if payload ~= nil and phase == "incoming" then
			applyChoosing(payload)
		end
	end

	-- Cancels a running cutscene without counting a viewing and drops any deferred choosing state.
	local function cancelCutscene()
		pendingChoosing = nil
		if sequence then
			endCutscene(false)
		end
	end

	local function startCutscene()
		if sequence then
			endCutscene(false)
		end
		local seen = nil
		pcall(function()
			seen = player:GetAttribute(RaidCutscene.seenAttribute)
		end)
		local seq = CutsceneSequencer.new(RaidCutscene.shots, {
			skippable = CutsceneSequencer.skippableAfter(seen),
		})
		sequence = seq
		uiState = { lowerThird = false, letter = false }
		scrim.BackgroundTransparency = 1
		applyUi(uiState)
		skipButton.Visible = seq.isSkippable()
		takeCamera()

		seq.onShot(function(shot: any)
			uiState = CutsceneState.uiFor(shot.kind, uiState)
			applyUi(uiState)
			if shot.kind == "letter" then
				scrim.BackgroundTransparency = 0.45
				slamLetter(shot.slam == true)
				pulse()
			else
				tweenFov(shot.fov, if shot.kind == "zoom" then 0.25 else 0.5)
			end
		end)
		seq.onFinished(function()
			if sequence == seq then
				endCutscene(true)
				flushPendingChoosing()
			end
		end)

		renderConnection = RunService.RenderStepped:Connect(function(dt: number)
			if sequence ~= seq then
				return
			end
			seq.step(dt)
			local shot, progress = seq.current()
			if shot then
				placeCamera(shot, progress)
			end
		end)

		-- Character death or removal cancels the cutscene; the choices still arrive afterwards.
		local function abort()
			if sequence == seq then
				endCutscene(false)
				flushPendingChoosing()
			end
		end
		pcall(function()
			table.insert(deathConnections, player.CharacterRemoving:Connect(abort))
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				table.insert(deathConnections, humanoid.Died:Connect(abort))
			end
		end)

		seq.play()
	end

	-- The raid overlay is a hook moment: the fidelity tier is frozen while it is up.
	local raidMoment = MomentGuard.new()
	gui.Destroying:Connect(function()
		cancelCutscene()
		raidMoment.finish()
	end)

	local function hide()
		raidMoment.finish()
		phase = "idle"
		scrim.Visible = false
		skipButton.Visible = false
		pulseToken += 1
		countdownToken += 1
		cancelCutscene() -- seq.cancel(): no seen increment; restores camera type and FOV
	end

	skipButton.Activated:Connect(function()
		if phase == "incoming" and sequence and sequence.isSkippable() then
			sequence.skip()
		end
	end)

	applyChoosing = function(payload: any)
		local isViral = payload.isViral == true
		phase = "choosing"
		skipButton.Visible = false
		waitLabel.Visible = true
		waitLabel.Text = t("raid_choose")
		amplopButton.Visible = true
		if isViral then
			amplopButton.Text = t("raid_amplop_blocked")
			amplopButton.Active = false
			amplopButton.BackgroundTransparency = 0.5
		else
			amplopButton.Text = t("raid_amplop", payload.amplop or 0)
			amplopButton.Active = true
			amplopButton.BackgroundTransparency = 0
		end
		fineButton.Visible = true
		fineButton.Active = true
		runCountdown(payload.timeout or 20)
	end

	Remotes.Raid_Start.OnClientEvent:Connect(function(payload: any)
		if type(payload) ~= "table" then
			return
		end
		local phaseName = payload.phase
		local isViral = payload.isViral == true
		scrim.Visible = true
		raidMoment.begin()
		headline.Text = if isViral then t("raid_viral_title") else t("raid_title")
		subtitle.Text = if isViral then t("raid_viral_subtitle") else t("raid_subtitle")
		fineButton.Text = t("raid_fine", payload.fine or 0)

		if phaseName == "incoming" then
			phase = "incoming"
			pendingChoosing = nil
			waitLabel.Visible = true
			waitLabel.Text = t("raid_wait")
			countdown.Text = ""
			fineButton.Visible = false
			amplopButton.Visible = false
			Audio.play("sting_raid")
			startCutscene()
		elseif phaseName == "choosing" then
			if sequence then
				-- choices become interactive when the cutscene finishes
				pendingChoosing = payload
				return
			end
			applyChoosing(payload)
		end
	end)

	local function choose(choice: string)
		if phase ~= "choosing" then
			return
		end
		phase = "resolving"
		fineButton.Active = false
		amplopButton.Active = false
		waitLabel.Visible = true
		waitLabel.Text = t("raid_wait")
		countdown.Text = ""
		Remotes.Raid_Choose:FireServer(choice)
	end

	fineButton.Activated:Connect(function()
		choose("denda")
	end)
	amplopButton.Activated:Connect(function()
		choose("amplop")
	end)

	Remotes.Raid_End.OnClientEvent:Connect(function(outcome: string)
		phase = "resolving"
		cancelCutscene()
		fineButton.Visible = false
		amplopButton.Visible = false
		waitLabel.Visible = true
		countdown.Text = ""
		local key = "raid_outcome_" .. tostring(outcome)
		waitLabel.Text = t(key)
		pulseToken += 1
		task.delay(4, function()
			if phase ~= "resolving" or not scrim.Visible then
				return
			end
			hide()
		end)
	end)

	Remotes.Jail_State.OnClientEvent:Connect(function(secondsLeft: number)
		if type(secondsLeft) ~= "number" or secondsLeft <= 0 then
			jailBar.Visible = false
			return
		end
		if not jailBar.Visible then
			Audio.play("sting_jail")
		end
		jailBar.Visible = true
		jailTime.Text = t("jail_time", math.ceil(secondsLeft))
	end)
end

return RaidOverlay
