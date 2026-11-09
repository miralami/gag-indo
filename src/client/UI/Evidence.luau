-- Evidence client: "📱 Rekam?" offers and the bukti tokens shown in the phone.
-- The server decides everything; this module only stores what the server sent.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Strings = require(Shared.Strings)
local Remotes = require(Shared.Remotes)

local Theme = require(script.Parent.Theme)

local Evidence = {}

type Token = { tokenId: string, cheatId: string, expiresAt: number }

local tokens: { [string]: Token } = {}
local listeners: { () -> () } = {}

local function fireChanged()
	for _, listener in listeners do
		task.spawn(listener)
	end
end

function Evidence.onChanged(listener: () -> ())
	table.insert(listeners, listener)
end

function Evidence.getTokens(): { Token }
	local now = os.time()
	local list = {}
	for _, token in tokens do
		if token.expiresAt > now then
			table.insert(list, token)
		end
	end
	table.sort(list, function(a, b)
		return a.expiresAt < b.expiresAt
	end)
	return list
end

function Evidence.mount(lang: string, gui: ScreenGui)
	local t = function(key: string, ...: any): string
		return Strings.get(lang, key, ...)
	end

	local offerHolder = Theme.new("Frame", {
		Name = "EvidenceOffers",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -10, 1, -76),
		Size = UDim2.new(0.3, 0, 0.22, 0),
		BackgroundTransparency = 1,
		Parent = gui,
	}, {
		Theme.new("UISizeConstraint", { MinSize = Vector2.new(220, 60), MaxSize = Vector2.new(320, 180) }),
		Theme.new("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			Padding = UDim.new(0, 6),
		}),
	})
	local offerOrder = 0
	local offerFrames: { [string]: Frame } = {}

	local function removeOffer(eventId: string)
		local frame = offerFrames[eventId]
		if frame then
			frame:Destroy()
			offerFrames[eventId] = nil
		end
	end

	-- Keep at most three offers on screen; the newest one is the most relevant.
	local function trimOffers()
		local list = {}
		for id, frame in offerFrames do
			table.insert(list, { id = id, order = frame.LayoutOrder })
		end
		if #list < 3 then
			return
		end
		table.sort(list, function(a, b)
			return a.order < b.order
		end)
		for i = 1, #list - 2 do
			removeOffer(list[i].id)
		end
	end

	Remotes.Evidence_Offer.OnClientEvent:Connect(function(
		eventId: string,
		cheaterName: string,
		cheatId: string,
		expiresAt: number
	)
		if type(eventId) ~= "string" or offerFrames[eventId] then
			return
		end
		offerOrder += 1
		local card = Theme.card({
			Name = "Offer",
			LayoutOrder = offerOrder,
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Parent = offerHolder,
		}, {
			Theme.new("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 4),
			}),
		})
		local padding = Instance.new("UIPadding")
		padding.PaddingLeft = UDim.new(0, 8)
		padding.PaddingRight = UDim.new(0, 8)
		padding.PaddingTop = UDim.new(0, 6)
		padding.PaddingBottom = UDim.new(0, 6)
		padding.Parent = card

		local title = Theme.label({
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 0, 20),
			Text = "📱 " .. t("phone_record") .. "?",
			TextColor3 = Theme.accent,
			Parent = card,
		})
		title.TextSize = 18

		local subtitle = Theme.label({
			LayoutOrder = 2,
			Size = UDim2.new(1, 0, 0, 18),
			Text = cheaterName .. " · " .. t("cheat_" .. cheatId),
			TextColor3 = Theme.muted,
			Parent = card,
		})
		subtitle.TextSize = 14

		local record = Theme.button({
			LayoutOrder = 3,
			Size = UDim2.new(1, 0, 0, 40),
			Text = "📱 " .. t("phone_record"),
			BackgroundColor3 = Theme.blue,
			Parent = card,
		})
		record.Activated:Connect(function()
			Remotes.Evidence_Record:FireServer(eventId)
			removeOffer(eventId)
		end)

		offerFrames[eventId] = card
		trimOffers()
		task.delay(math.max(0, expiresAt - os.time()), function()
			removeOffer(eventId)
		end)
	end)

	Remotes.Evidence_Token.OnClientEvent:Connect(function(tokenId: string, cheatId: string, expiresAt: number)
		if type(tokenId) ~= "string" or type(cheatId) ~= "string" then
			return
		end
		tokens[tokenId] = {
			tokenId = tokenId,
			cheatId = cheatId,
			expiresAt = if type(expiresAt) == "number" then expiresAt else os.time() + 180,
		}
		Theme.toast(t("n_got_token"), Theme.green)
		fireChanged()
	end)

	Remotes.Evidence_Remove.OnClientEvent:Connect(function(tokenId: string)
		if tokens[tokenId] then
			tokens[tokenId] = nil
			fireChanged()
		end
	end)

	-- Tokens expire on the server; prune locally too so the phone never lies.
	task.spawn(function()
		while true do
			task.wait(2)
			local now = os.time()
			local changed = false
			for tokenId, token in tokens do
				if token.expiresAt <= now then
					tokens[tokenId] = nil
					changed = true
				end
			end
			if changed then
				fireChanged()
			end
		end
	end)
end

return Evidence
