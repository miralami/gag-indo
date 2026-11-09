-- Babat: hold to fill the gauge, release in the sweet spot (GDD §3.3).
-- Releasing early is a weak cut; hitting the top fumbles the cut.

local Theme = require(script.Parent.Parent.UI.Theme)

local Babat = {}

local SWEET_START = 0.58
local SWEET_WIDTH = 0.18
local FILL_SECONDS = 1.6

-- parent: a framed play area. Returns a cleanup function.
function Babat.play(parent: Frame, t: (string, ...any) -> string, onFinish: (number) -> ()): () -> ()
	local bar = Theme.new("Frame", {
		Name = "Bar",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.fromScale(0.9, 0.26),
		BackgroundColor3 = Color3.fromRGB(25, 25, 30),
		BorderSizePixel = 0,
		Parent = parent,
	}, { Theme.corner(nil, 8) })

	Theme.new("Frame", {
		Name = "Zone",
		Position = UDim2.fromScale(SWEET_START, 0),
		Size = UDim2.fromScale(SWEET_WIDTH, 1),
		BackgroundColor3 = Theme.green,
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		Parent = bar,
	})

	local fill = Theme.new("Frame", {
		Name = "Fill",
		Position = UDim2.fromScale(0, 0),
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = Color3.fromRGB(90, 170, 230),
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		Parent = bar,
	})

	local valueLabel = Theme.label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.78),
		Size = UDim2.fromScale(0.7, 0.16),
		Text = t("mg_babat_hint"),
		Parent = parent,
	})

	local holdArea = Theme.new("TextButton", {
		Name = "HoldArea",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Parent = parent,
	})

	local value = 0
	local holding = false
	local active = true
	local finished = false

	local function scoreFor(v: number): number
		local center = SWEET_START + SWEET_WIDTH / 2
		local half = SWEET_WIDTH / 2
		local distance = math.abs(v - center)
		if distance <= half then
			return 1 - (distance / half) * 0.3
		end
		return math.max(0, 0.7 - (distance - half) * 1.4)
	end

	local function cleanup()
		active = false
		if parent then
			parent:Destroy()
		end
	end

	local function release()
		if finished then
			return
		end
		finished = true
		holding = false
		task.wait(0.2)
		local score = scoreFor(math.clamp(value, 0, 1))
		cleanup()
		onFinish(score)
	end

	local function loop()
		local last = os.clock()
		while active and holding do
			local now = os.clock()
			local dt = now - last
			last = now
			value = math.min(1, value + dt / FILL_SECONDS)
			fill.Size = UDim2.fromScale(value, 1)
			valueLabel.Text = string.format("%d%%", math.floor(value * 100))
			if value >= 1 then
				-- Held too long: fumble.
				release()
				return
			end
			task.wait()
		end
	end

	holdArea.InputBegan:Connect(function(input)
		if finished then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			if holding then
				return -- second finger: ignore, one fill loop only
			end
			holding = true
			valueLabel.Text = string.format("%d%%", math.floor(value * 100))
			task.spawn(loop)
		end
	end)

	holdArea.InputEnded:Connect(function(input)
		if finished then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			holding = false
			release()
		end
	end)

	task.delay(20, function()
		if not finished then
			finished = true
			holding = false
			local score = scoreFor(math.clamp(value, 0, 1))
			cleanup()
			onFinish(score)
		end
	end)

	return function()
		if active then
			active = false
			holding = false
			cleanup()
		end
	end
end

return Babat
