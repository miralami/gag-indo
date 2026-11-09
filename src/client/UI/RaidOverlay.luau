-- RaidOverlay: sinetron-style full-screen raid (GDD §5.3, §10) + the Pos Ronda countdown.
-- The server owns the state machine; this module only presents it and sends Raid_Choose.

local TweenService = game:GetService("TweenService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Strings = require(Shared.Strings)
local Remotes = require(Shared.Remotes)

local Theme = require(script.Parent.Theme)

local RaidOverlay = {}

function RaidOverlay.mount(lang: string)
	local t = function(key: string, ...: any): string
		return Strings.get(lang, key, ...)
	end

	local gui = Theme.screenGui("RaidOverlay", 70)

	local scrim = Theme.new("Frame", {
		Name = "Scrim",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(80, 0, 0),
		BackgroundTransparency = 0.45,
		Visible = false,
		Parent = gui,
	})

	-- BREAKING NEWS banner
	local banner = Theme.new("Frame", {
		Name = "Banner",
		Position = UDim2.fromScale(0, 0.06),
		Size = UDim2.new(1, 0, 0, 54),
		BackgroundColor3 = Color3.fromRGB(170, 30, 30),
		BorderSizePixel = 0,
		Parent = scrim,
	})
	Theme.label({
		Size = UDim2.fromScale(1, 0.55),
		Text = t("raid_breaking"),
		TextColor3 = Color3.new(1, 1, 1),
		Parent = banner,
	})
	Theme.label({
		Position = UDim2.fromScale(0, 0.55),
		Size = UDim2.fromScale(1, 0.45),
		Text = t("raid_title"),
		TextColor3 = Color3.fromRGB(255, 230, 180),
		Parent = banner,
	})
	local bannerStripe = Theme.new("Frame", {
		Position = UDim2.fromScale(0, 0.94),
		Size = UDim2.new(1, 0, 0, 4),
		BackgroundColor3 = Color3.fromRGB(255, 220, 60),
		BorderSizePixel = 0,
		Parent = banner,
	})
	bannerStripe.Name = "Stripe"

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

	local headline = Theme.label({
		Size = UDim2.new(1, 0, 0, 44),
		Text = t("raid_title"),
		TextColor3 = Color3.fromRGB(255, 190, 60),
		Parent = card,
	})
	local subtitle = Theme.label({
		Position = UDim2.new(0, 0, 0, 46),
		Size = UDim2.new(1, 0, 0, 40),
		Text = t("raid_subtitle"),
		TextColor3 = Theme.text,
		TextWrapped = true,
		Parent = card,
	})
	subtitle.TextSize = 15

	local waitLabel = Theme.label({
		Position = UDim2.new(0, 0, 0, 96),
		Size = UDim2.new(1, 0, 0, 60),
		Text = t("raid_wait"),
		TextColor3 = Theme.muted,
		TextWrapped = true,
		Parent = card,
	})
	waitLabel.TextSize = 14

	local countdown = Theme.label({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.new(0.2, 0, 0, 34),
		Text = "",
		TextColor3 = Theme.accent,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = card,
	})

	local fineButton = Theme.button({
		Name = "Fine",
		Position = UDim2.new(0, 0, 1, -122),
		Size = UDim2.new(0.48, 0, 0, 110),
		Text = "",
		BackgroundColor3 = Theme.green,
		Visible = false,
		Parent = card,
	})
	local amplopButton = Theme.button({
		Name = "Amplop",
		Position = UDim2.new(0.52, 0, 1, -122),
		Size = UDim2.new(0.48, 0, 0, 110),
		Text = "",
		BackgroundColor3 = Color3.fromRGB(150, 120, 40),
		Visible = false,
		Parent = card,
	})

	-- Pos Ronda countdown
	local jailBar = Theme.card({
		Name = "Jail",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 74),
		Size = UDim2.new(0.5, 0, 0, 56),
		BackgroundColor3 = Color3.fromRGB(120, 80, 20),
		Visible = false,
		Parent = gui,
	}, {
		Theme.new("UISizeConstraint", { MinSize = Vector2.new(240, 52), MaxSize = Vector2.new(420, 64) }),
	})
	local jailTitle = Theme.label({
		Size = UDim2.new(0.4, 0, 1, 0),
		Text = t("jail_title"),
		TextColor3 = Color3.fromRGB(255, 220, 130),
		Parent = jailBar,
	})
	jailTitle.TextSize = 14
	local jailTime = Theme.label({
		Position = UDim2.new(0.4, 0, 0, 0),
		Size = UDim2.new(0.58, 0, 1, 0),
		Text = "",
		Parent = jailBar,
	})
	jailTime.TextSize = 14

	local camera = workspace.CurrentCamera
	local baseFov = if camera then camera.FieldOfView else 70
	local zoomGeneration = 0

	local function sinetronZoom()
		if not camera then
			return
		end
		zoomGeneration += 1
		local generation = zoomGeneration
		task.spawn(function()
			for _ = 1, 3 do
				if generation ~= zoomGeneration or not camera then
					return
				end
				local zoomIn = TweenService:Create(camera, TweenInfo.new(0.22), { FieldOfView = 42 })
				zoomIn:Play()
				zoomIn.Completed:Wait()
				if generation ~= zoomGeneration then
					return
				end
				local zoomOut = TweenService:Create(camera, TweenInfo.new(0.22), { FieldOfView = baseFov })
				zoomOut:Play()
				zoomOut.Completed:Wait()
			end
		end)
	end

	local function stopZoom()
		zoomGeneration += 1
		if camera then
			camera.FieldOfView = baseFov
		end
	end

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

	local function hide()
		phase = "idle"
		scrim.Visible = false
		pulseToken += 1
		countdownToken += 1
		stopZoom()
	end

	Remotes.Raid_Start.OnClientEvent:Connect(function(payload: any)
		if type(payload) ~= "table" then
			return
		end
		local phaseName = payload.phase
		local isViral = payload.isViral == true
		scrim.Visible = true
		headline.Text = if isViral then t("raid_viral_title") else t("raid_title")
		subtitle.Text = if isViral then t("raid_viral_subtitle") else t("raid_subtitle")
		fineButton.Text = t("raid_fine", payload.fine or 0)

		if phaseName == "incoming" then
			phase = "incoming"
			waitLabel.Visible = true
			waitLabel.Text = t("raid_wait")
			countdown.Text = ""
			fineButton.Visible = false
			amplopButton.Visible = false
			sinetronZoom()
			pulse()
		elseif phaseName == "choosing" then
			phase = "choosing"
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
		jailBar.Visible = true
		jailTime.Text = t("jail_time", math.ceil(secondsLeft))
	end)
end

return RaidOverlay
