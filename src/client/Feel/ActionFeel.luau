-- ActionFeel: Track A juice and game feel feedback.
-- Handles plant, harvest, sell, and rarity reveal visual and audio punch.
-- Pure functions for testability; runtime bindings for client interaction.

local ActionFeel = {}

-- -----------------------------------------------------------------------------
-- Pure functions
-- -----------------------------------------------------------------------------

-- Quadratic bezier trajectory with upward arc for cash fly.
-- Works with Vector3 or Vector2 / {X, Y} positions.
function ActionFeel.cashFlyTrajectory(
	startPos: any,
	endPos: any,
	progress: number,
	arcHeight: number?
): any
	local t = math.clamp(progress, 0, 1)
	local oneMinusT = 1 - t

	local is3D = (startPos :: any).Z ~= nil
	if is3D then
		local p0 = startPos :: Vector3
		local p2 = endPos :: Vector3
		local dist = math.sqrt((p2.X - p0.X) ^ 2 + (p2.Z - p0.Z) ^ 2)
		local h = arcHeight or math.max(3, dist * 0.35)
		local p1 = Vector3.new((p0.X + p2.X) * 0.5, (p0.Y + p2.Y) * 0.5 + h, (p0.Z + p2.Z) * 0.5)

		local c0 = oneMinusT * oneMinusT
		local c1 = 2 * oneMinusT * t
		local c2 = t * t
		local x = p0.X * c0 + p1.X * c1 + p2.X * c2
		local y = p0.Y * c0 + p1.Y * c1 + p2.Y * c2
		local z = p0.Z * c0 + p1.Z * c1 + p2.Z * c2
		return Vector3.new(x, y, z)
	else
		local p0 = startPos
		local p2 = endPos
		local dist = math.abs(p2.X - p0.X)
		local h = arcHeight or math.max(20, dist * 0.25)
		local midX = (p0.X + p2.X) * 0.5
		local midY = (p0.Y + p2.Y) * 0.5 + h

		local c0 = oneMinusT * oneMinusT
		local c1 = 2 * oneMinusT * t
		local c2 = t * t
		local x = p0.X * c0 + midX * c1 + p2.X * c2
		local y = p0.Y * c0 + midY * c1 + p2.Y * c2

		local ok, res = pcall(function()
			return (Vector2 :: any).new(x, y)
		end)
		if ok and res then
			return res
		end
		return { X = x, Y = y }
	end
end

-- Elastic / back-ease pop scale for planted tile / harvest bounce.
-- Starts at 0, overshoots > 1.0 (approx 1.2), settles at 1.0.
function ActionFeel.popScale(t: number): number
	if t <= 0 or t ~= t then
		return 0
	elseif t >= 1 then
		return 1
	end
	local s = 2.7
	local p = t - 1
	return 1 + (s + 1) * (p * p * p) + s * (p * p)
end

-- Camera shake offset vector bounded by intensity.
function ActionFeel.shakeOffset(intensity: number, time: number): Vector3
	if intensity <= 0 or intensity ~= intensity then
		return Vector3.new(0, 0, 0)
	end
	local t = time or 0
	local x = math.sin(t * 31.7) * math.cos(t * 19.3)
	local y = math.sin(t * 27.1 + 1.2) * math.cos(t * 23.5)
	local z = math.sin(t * 37.9 + 2.4) * math.cos(t * 17.1)
	local mag = math.sqrt(x * x + y * y + z * z)
	if mag > 1 then
		x = x / mag
		y = y / mag
		z = z / mag
	end
	return Vector3.new(x * intensity, y * intensity, z * intensity)
end

-- Checks if a tier is Sultan.
function ActionFeel.isSultan(tier: any): boolean
	return type(tier) == "string" and string.lower(tier) == "sultan"
end

-- -----------------------------------------------------------------------------
-- Client runtime state & helpers
-- -----------------------------------------------------------------------------

local started = false
local lastActionTile: BasePart? = nil
local shakeToken = 0

local function getAudio()
	local ok, mod = pcall(function()
		return require(script.Parent.Parent.Audio)
	end)
	return if ok then mod else nil
end

local function getRemotes()
	local ok, mod = pcall(function()
		local rs = game:GetService("ReplicatedStorage")
		local shared = rs:FindFirstChild("Shared")
		if shared and shared:FindFirstChild("Remotes") then
			return require(shared.Remotes)
		end
		return nil
	end)
	return if ok then mod else nil
end

function ActionFeel.setLastTile(tilePart: BasePart?)
	lastActionTile = tilePart
end

-- Finds the local player's tile BasePart by tileIndex (1..16).
function ActionFeel.getTilePart(tileIndex: number): BasePart?
	local ok, result = pcall(function()
		local Players = game:GetService("Players")
		local CollectionService = game:GetService("CollectionService")
		local localPlayer = Players.LocalPlayer
		if not localPlayer then
			return nil
		end
		for _, tile in CollectionService:GetTagged("Tile") do
			if tile:IsA("BasePart") and tile:GetAttribute("TileIndex") == tileIndex then
				local plot = tile.Parent
				if plot and plot:GetAttribute("OwnerUserId") == localPlayer.UserId then
					return tile
				end
			end
		end
		return nil
	end)
	return if ok then result else nil
end

-- -----------------------------------------------------------------------------
-- Action feel handlers
-- -----------------------------------------------------------------------------

-- Spawns soil particle burst / tweens model scale with popScale, plays sound, slight camera nudge.
function ActionFeel.onPlant(tilePart: BasePart?)
	local audio = getAudio()
	if audio then
		audio.play("ui_click")
	end

	-- Slight camera nudge
	pcall(function()
		local camera = workspace.CurrentCamera
		if camera then
			task.spawn(function()
				local original = camera.CFrame
				camera.CFrame = original * CFrame.Angles(math.rad(-0.4), 0, 0)
				task.wait(0.04)
				if workspace.CurrentCamera == camera then
					camera.CFrame = original
				end
			end)
		end
	end)

	if not tilePart or not tilePart:IsA("BasePart") or not tilePart.Parent then
		return
	end

	-- Soil particle burst
	pcall(function()
		local attachment = Instance.new("Attachment")
		attachment.Name = "SoilBurst"
		attachment.CFrame = CFrame.new(0, tilePart.Size.Y * 0.5, 0)
		attachment.Parent = tilePart

		local emitter = Instance.new("ParticleEmitter")
		emitter.Color = ColorSequence.new(Color3.fromRGB(110, 75, 45))
		emitter.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.4),
			NumberSequenceKeypoint.new(1, 0),
		})
		emitter.Speed = NumberRange.new(4, 8)
		emitter.SpreadAngle = Vector2.new(45, 45)
		emitter.Lifetime = NumberRange.new(0.25, 0.5)
		emitter.Rate = 0
		emitter.Parent = attachment
		emitter:Emit(14)

		task.delay(0.6, function()
			attachment:Destroy()
		end)
	end)

	-- Tween model scale with popScale
	pcall(function()
		local crop = tilePart:FindFirstChild("Crop")
		if crop and crop:IsA("BasePart") then
			local baseSize = crop.Size
			local duration = 0.35
			local startTime = os.clock()
			task.spawn(function()
				while crop.Parent do
					local elapsed = os.clock() - startTime
					local progress = elapsed / duration
					if progress >= 1 then
						crop.Size = baseSize
						break
					end
					local scale = ActionFeel.popScale(progress)
					crop.Size = baseSize * scale
					task.wait(0.025)
				end
			end)
		end
	end)
end

-- Spawns harvest burst, screen shake if Sultan / Langka, triggers sting sound via Audio.play.
function ActionFeel.onHarvest(tilePart: BasePart?, tier: string?)
	local isSultanTier = ActionFeel.isSultan(tier)
	local isLangka = type(tier) == "string" and string.lower(tier) == "langka"
	local isSuper = type(tier) == "string" and string.lower(tier) == "super"

	-- Sound sting
	local audio = getAudio()
	if audio then
		if isSultanTier then
			audio.play("sting_sultan")
		elseif isLangka or isSuper then
			audio.play("sting_rare")
		else
			audio.play("ui_click")
		end
	end

	-- Screen shake if Sultan or Langka
	if isSultanTier or isLangka then
		local intensity = if isSultanTier then 0.35 else 0.18
		local duration = if isSultanTier then 0.45 else 0.25
		pcall(function()
			local camera = workspace.CurrentCamera
			if camera then
				shakeToken += 1
				local token = shakeToken
				local original = camera.CFrame
				local startTime = os.clock()
				task.spawn(function()
					while token == shakeToken and workspace.CurrentCamera == camera do
						local elapsed = os.clock() - startTime
						if elapsed >= duration then
							break
						end
						local decay = 1 - (elapsed / duration)
						local offset = ActionFeel.shakeOffset(intensity * decay, elapsed)
						camera.CFrame = original * CFrame.new(offset.X, offset.Y, 0)
						task.wait(0.025)
					end
					if token == shakeToken and workspace.CurrentCamera == camera then
						camera.CFrame = original
					end
				end)
			end
		end)
	end

	-- Harvest particle burst
	if tilePart and tilePart:IsA("BasePart") and tilePart.Parent then
		pcall(function()
			local burstColor = if isSultanTier
				then Color3.fromRGB(255, 215, 0)
				elseif isLangka then Color3.fromRGB(190, 110, 255)
				elseif isSuper then Color3.fromRGB(80, 160, 255)
				else Color3.fromRGB(120, 210, 80)

			local attachment = Instance.new("Attachment")
			attachment.Name = "HarvestBurst"
			attachment.CFrame = CFrame.new(0, tilePart.Size.Y * 0.5, 0)
			attachment.Parent = tilePart

			local emitter = Instance.new("ParticleEmitter")
			emitter.Color = ColorSequence.new(burstColor)
			emitter.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.45),
				NumberSequenceKeypoint.new(1, 0),
			})
			emitter.Speed = NumberRange.new(6, 12)
			emitter.SpreadAngle = Vector2.new(60, 60)
			emitter.Lifetime = NumberRange.new(0.35, 0.65)
			emitter.Rate = 0
			emitter.Parent = attachment
			emitter:Emit(if isSultanTier then 30 else 20)

			task.delay(0.8, function()
				attachment:Destroy()
			end)
		end)
	end
end

-- Triggers cash-fly visual (e.g. floating "+Rp <amount>" text flying toward top-left HUD stats chip),
-- plays sound Audio.play("ui_sell").
function ActionFeel.onSell(earnedAmount: number, originPosition: any?)
	local audio = getAudio()
	if audio then
		audio.play("ui_sell")
	end

	pcall(function()
		local Players = game:GetService("Players")
		local localPlayer = Players.LocalPlayer
		if not localPlayer then
			return
		end
		local playerGui = localPlayer:FindFirstChild("PlayerGui")
		if not playerGui then
			return
		end

		local camera = workspace.CurrentCamera
		local vp = if camera then camera.ViewportSize else Vector2.new(800, 600)

		-- Resolve start screen position
		local startPos = Vector2.new(vp.X * 0.5, vp.Y * 0.55)
		if originPosition then
			if (originPosition :: any).Z ~= nil and camera then
				local screenPt, onScreen = camera:WorldToViewportPoint(originPosition :: Vector3)
				if onScreen then
					startPos = Vector2.new(screenPt.X, screenPt.Y)
				end
			elseif (originPosition :: any).X ~= nil and (originPosition :: any).Y ~= nil then
				startPos = Vector2.new(originPosition.X, originPosition.Y)
			end
		end

		-- Resolve target screen position (HUD CashChip)
		local endPos = Vector2.new(80, 50)
		local cashChip: Frame? = nil
		local hud = playerGui:FindFirstChild("Hud")
		if hud then
			local stats = hud:FindFirstChild("Stats")
			if stats then
				cashChip = stats:FindFirstChild("CashChip") :: Frame?
				if cashChip and cashChip.AbsolutePosition then
					endPos = cashChip.AbsolutePosition + cashChip.AbsoluteSize * 0.5
				end
			end
		end

		-- Container gui
		local feelGui = playerGui:FindFirstChild("ActionFeelGui") :: ScreenGui?
		if not feelGui then
			feelGui = Instance.new("ScreenGui")
			feelGui.Name = "ActionFeelGui"
			feelGui.ResetOnSpawn = false
			feelGui.DisplayOrder = 90
			feelGui.Parent = playerGui
		end

		local label = Instance.new("TextLabel")
		label.Name = "CashFly"
		label.AnchorPoint = Vector2.new(0.5, 0.5)
		label.Position = UDim2.fromOffset(startPos.X, startPos.Y)
		label.Size = UDim2.fromOffset(140, 32)
		label.BackgroundTransparency = 1
		label.Text = "+Rp " .. tostring(math.floor(earnedAmount or 0))
		label.TextColor3 = Color3.fromRGB(255, 215, 0)
		label.TextSize = 18
		label.Font = Enum.Font.GothamBold
		label.Parent = feelGui

		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(30, 20, 10)
		stroke.Thickness = 2
		stroke.Parent = label

		-- Fly animation along bezier arc toward cash chip
		local duration = 0.65
		local startTime = os.clock()
		task.spawn(function()
			while label.Parent do
				local elapsed = os.clock() - startTime
				local progress = elapsed / duration
				if progress >= 1 then
					label:Destroy()
					-- Punch scale cash chip if present
					if cashChip then
						pcall(function()
							local TweenService = game:GetService("TweenService")
							local up = TweenService:Create(
								cashChip,
								TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
								{ Size = UDim2.new(0, 0, 0, 34) }
							)
							local down = TweenService:Create(
								cashChip,
								TweenInfo.new(0.12),
								{ Size = UDim2.new(0, 0, 0, 30) }
							)
							up:Play()
							up.Completed:Connect(function()
								down:Play()
							end)
						end)
					end
					break
				end

				-- Upward arc in screen space (-Y)
				local pos = ActionFeel.cashFlyTrajectory(startPos, endPos, progress, -60)
				label.Position = UDim2.fromOffset(pos.X, pos.Y)
				task.wait(0.02)
			end
		end)
	end)
end

-- Binds to relevant attribute changes / remotes / events.
function ActionFeel.start()
	if started then
		return
	end
	started = true

	local remotes = getRemotes()
	if remotes and remotes.Notify then
		remotes.Notify.OnClientEvent:Connect(function(key: string, params: { any }?)
			if key == "n_rarity_reveal" and params and type(params[3]) == "string" then
				ActionFeel.onHarvest(lastActionTile, params[3])
			elseif key == "n_planted" then
				ActionFeel.onPlant(lastActionTile)
			end
		end)
	end
end

return ActionFeel
