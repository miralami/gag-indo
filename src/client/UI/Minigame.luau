-- Minigame overlay: one card, one big tap area (GDD §10). Picks Mencangkul for planting
-- and Babat for harvesting, and can be skipped with Auto (flat quality 0.9).

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Strings = require(Shared.Strings)
local Remotes = require(Shared.Remotes)

local Theme = require(script.Parent.Theme)
local Mencangkul = require(script.Parent.Parent.Minigames.Mencangkul)
local Babat = require(script.Parent.Parent.Minigames.Babat)

local Minigame = {}

type Attempt = {
	action: string,
	tile: number,
	cropId: string?,
	cleanup: (() -> ())?,
}

function Minigame.mount(lang: string)
	local t = function(key: string, ...: any): string
		return Strings.get(lang, key, ...)
	end

	local gui = Theme.screenGui("Minigame", 60)

	local scrim = Theme.new("Frame", {
		Name = "Scrim",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.35,
		Visible = false,
		Parent = gui,
	})

	local card = Theme.card({
		Name = "Card",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.82, 0.46),
		Parent = scrim,
	}, {
		Theme.new("UISizeConstraint", { MinSize = Vector2.new(300, 240), MaxSize = Vector2.new(460, 330) }),
	})
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.Parent = card

	local title = Theme.label({
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, 30),
		Text = "",
		TextColor3 = Theme.accent,
		Parent = card,
	})

	local hint = Theme.label({
		Position = UDim2.new(0, 0, 0, 30),
		Size = UDim2.new(1, 0, 0, 22),
		Text = "",
		TextColor3 = Theme.muted,
		Parent = card,
	})
	hint.TextSize = 14

	local playArea: Frame? = nil

	local auto = Theme.button({
		Name = "Auto",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1),
		Size = UDim2.new(0.6, 0, 0, 42),
		Text = t("mg_auto"),
		BackgroundColor3 = Theme.panelLight,
		Parent = card,
	})

	local cancel = Theme.button({
		Name = "Cancel",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.new(0.14, 0, 0, 30),
		Text = "✕",
		BackgroundColor3 = Theme.red,
		Parent = card,
	})

	local current: Attempt? = nil

	local function close()
		if current and current.cleanup then
			current.cleanup()
		end
		current = nil
		if playArea then
			playArea:Destroy()
			playArea = nil
		end
		scrim.Visible = false
	end

	local function start(action: string, tile: number, cropId: string?)
		close()

		scrim.Visible = true
		local isPlant = action == "plant"
		local cropLabel = if cropId then t("crop_" .. cropId) else ""
		title.Text = if isPlant
			then t("mg_mencangkul_title") .. " · " .. t("mg_plant", cropLabel)
			else t("mg_babat_title") .. " · " .. t("mg_harvest", cropLabel)
		hint.Text = if isPlant then t("mg_mencangkul_hint") else t("mg_babat_hint")

		local area = Theme.new("Frame", {
			Name = "PlayArea",
			Position = UDim2.new(0, 0, 0, 54),
			Size = UDim2.new(1, 0, 1, -110),
			BackgroundColor3 = Theme.panelLight,
			BackgroundTransparency = 0.55,
			BorderSizePixel = 0,
			Parent = card,
		}, { Theme.corner(nil, 10) })
		playArea = area

		local attempt: Attempt = { action = action, tile = tile, cropId = cropId, cleanup = nil }
		current = attempt

		local function onFinish(score: number)
			if current ~= attempt then
				return
			end
			current = nil
			if playArea then
				playArea:Destroy()
				playArea = nil
			end
			scrim.Visible = false
			Remotes.Farm_Complete:FireServer(score)
			local quality = 0.8 + 0.5 * math.clamp(score, 0, 1)
			Theme.toast(t("mg_score", string.format("%.2f", quality)), Theme.green)
		end

		attempt.cleanup = if isPlant
			then Mencangkul.play(area, t, onFinish)
			else Babat.play(area, t, onFinish)
	end

	auto.Activated:Connect(function()
		local attempt = current
		if not attempt then
			return
		end
		close()
		Remotes.Farm_Auto:FireServer(attempt.tile, attempt.action, attempt.cropId)
	end)

	cancel.Activated:Connect(close)

	Remotes.Minigame_Start.OnClientEvent:Connect(function(action: string, tile: number, cropId: string?)
		if type(action) ~= "string" or type(tile) ~= "number" then
			return
		end
		start(action, tile, if type(cropId) == "string" then cropId else nil)
	end)
	Remotes.Minigame_Cancel.OnClientEvent:Connect(close)
end

return Minigame
