-- Mencangkul: three taps on a swinging needle (GDD §3.3). Purely client-side timing;
-- the server clamps the score and computes quality = 0.8 + 0.5 * score.

local RunService = game:GetService("RunService")

local Theme = require(script.Parent.Parent.UI.Theme)

local Mencangkul = {}

local GREEN_WIDTH = 0.22
local PERIOD = 1.15 -- seconds for a full left-right-left sweep

-- parent: a framed play area. Returns a cleanup function.
function Mencangkul.play(parent: Frame, t: (string, ...any) -> string, onFinish: (number) -> ()): () -> ()
	local bar = Theme.new("Frame", {
		Name = "Bar",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.fromScale(0.9, 0.26),
		BackgroundColor3 = Color3.fromRGB(25, 25, 30),
		BorderSizePixel = 0,
		Parent = parent,
	}, { Theme.corner(nil, 8) })

	local zoneStart = 0.08 + math.random() * 0.6
	Theme.new("Frame", {
		Name = "Zone",
		Position = UDim2.fromScale(zoneStart, 0),
		Size = UDim2.fromScale(GREEN_WIDTH, 1),
		BackgroundColor3 = Theme.green,
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		Parent = bar,
	})

	local needle = Theme.new("Frame", {
		Name = "Needle",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.new(0, 4, 1.1, 0),
		BackgroundColor3 = Theme.accent,
		BorderSizePixel = 0,
		Parent = bar,
	})

	local hitsLabel = Theme.label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.78),
		Size = UDim2.fromScale(0.7, 0.16),
		Text = t("mg_taps", 0, 3),
		Parent = parent,
	})

	local tapArea = Theme.new("TextButton", {
		Name = "TapArea",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Parent = parent,
	})

	local hits = 0
	local taps = 0
	local position = 0
	local direction = 1
	local active = true
	local connection

	local function finish()
		if not active then
			return
		end
		active = false
		if connection then
			connection:Disconnect()
		end
		parent:Destroy()
		onFinish(hits / 3)
	end

	connection = RunService.RenderStepped:Connect(function(dt)
		if not active then
			return
		end
		position += (dt / (PERIOD / 2)) * direction
		if position >= 1 then
			position = 1
			direction = -1
		elseif position <= 0 then
			position = 0
			direction = 1
		end
		needle.Position = UDim2.fromScale(position, 0)
	end)

	tapArea.Activated:Connect(function()
		if not active then
			return
		end
		taps += 1
		if position >= zoneStart and position <= zoneStart + GREEN_WIDTH then
			hits += 1
		end
		hitsLabel.Text = t("mg_taps", hits, 3)
		if taps >= 3 then
			task.wait(0.25) -- let the last hit land visually
			finish()
		end
	end)

	-- Safety net: a player who walks away must not leave the overlay up forever.
	task.delay(20, finish)

	return function()
		if active then
			active = false
			if connection then
				connection:Disconnect()
			end
			if parent then
				parent:Destroy()
			end
		end
	end
end

return Mencangkul
