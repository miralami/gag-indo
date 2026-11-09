-- Tiles: local-only presentation of plots.
--  * Hides prompts on other players' plots (the server still checks ownership).
--  * Localizes prompt text for tiles, Pasar, Tengkulak Gelap, Pak RT, Pos Polisi, Warung.
--  * Shows countdown / hot labels above tiles.
-- Uses CollectionService tags so it keeps working when tiles stream in/out.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Strings = require(Shared.Strings)

local player = Players.LocalPlayer
local PROMPT_DISTANCE = 10 -- matches PlotService/Props prompt defaults

local Tiles = {}

local function isMine(tile: BasePart): boolean
	local plot = tile.Parent
	return plot ~= nil and plot:GetAttribute("OwnerUserId") == player.UserId
end

local function formatTime(seconds: number): string
	seconds = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

function Tiles.mount(lang: string)
	local function t(key: string, ...: any): string
		return Strings.get(lang, key, ...)
	end

	-- [tile] = connections to clean up when it streams out
	local tracked: { [BasePart]: { RBXScriptConnection } } = {}

	local function applyPrompt(tile: BasePart)
		local prompt = tile:FindFirstChild("Prompt") :: ProximityPrompt?
		if not prompt then
			return
		end
		-- Hide other players' prompts locally by shrinking their range to 0.
		-- (We don't touch Enabled: the server owns it, and a local override would stick.)
		if not isMine(tile) then
			prompt.MaxActivationDistance = 0
			return
		end
		prompt.MaxActivationDistance = PROMPT_DISTANCE
		local state = tile:GetAttribute("State")
		prompt.ObjectText = t("prompt_tile")
		if state == "empty" then
			local seed = player:GetAttribute("SelectedSeed") or "padi"
			prompt.ActionText = t("prompt_plant", "@crop_" .. seed)
		elseif state == "ready" then
			prompt.ActionText = t("prompt_harvest")
		elseif state == "growing" then
			prompt.ActionText = t("prompt_growing")
		elseif state == "buy" then
			prompt.ActionText = t("prompt_buy_tile", tile:GetAttribute("Price") or 0)
		end
	end

	local function track(instance: Instance)
		if not instance:IsA("BasePart") or tracked[instance] then
			return
		end
		local tile = instance :: BasePart
		local connections = {}
		table.insert(connections, tile.AttributeChanged:Connect(function()
			applyPrompt(tile)
		end))
		table.insert(connections, tile.ChildAdded:Connect(function(child)
			if child.Name == "Prompt" then
				applyPrompt(tile)
			end
		end))
		local plot = tile.Parent
		if plot then
			table.insert(connections, plot:GetAttributeChangedSignal("OwnerUserId"):Connect(function()
				applyPrompt(tile)
			end))
		end
		tracked[tile] = connections
		applyPrompt(tile)
	end

	local function untrack(instance: Instance)
		local connections = tracked[instance :: BasePart]
		if connections then
			for _, connection in connections do
				connection:Disconnect()
			end
			tracked[instance :: BasePart] = nil
		end
	end

	for _, tile in CollectionService:GetTagged("Tile") do
		track(tile)
	end
	CollectionService:GetInstanceAddedSignal("Tile"):Connect(track)
	CollectionService:GetInstanceRemovedSignal("Tile"):Connect(untrack)

	-- Selected seed changes the "Tanam X" text
	player:GetAttributeChangedSignal("SelectedSeed"):Connect(function()
		for tile in tracked do
			applyPrompt(tile)
		end
	end)

	---------------------------------------------------------------- NPC/stall prompts
	local staticPrompts: { [string]: { objectKey: string, actionKey: string } } = {
		PasarPrompt = { objectKey = "prompt_pasar", actionKey = "prompt_sell" },
		GelapPrompt = { objectKey = "prompt_gelap", actionKey = "prompt_sell_gelap" },
		PakRTPrompt = { objectKey = "prompt_pakrt", actionKey = "prompt_bribe" },
		PolisiPrompt = { objectKey = "prompt_polisi", actionKey = "prompt_lapor" },
		WarungPrompt = { objectKey = "prompt_warung", actionKey = "prompt_warung_chat" },
	}

	local function localizePrompt(prompt: Instance)
		if not prompt:IsA("ProximityPrompt") then
			return
		end
		for tag, keys in staticPrompts do
			if CollectionService:HasTag(prompt, tag) then
				prompt.ObjectText = t(keys.objectKey)
				if tag == "PakRTPrompt" then
					prompt.ActionText = t(keys.actionKey, player:GetAttribute("BribePrice") or 100)
				else
					prompt.ActionText = t(keys.actionKey)
				end
				return
			end
		end
	end

	for tag in staticPrompts do
		for _, prompt in CollectionService:GetTagged(tag) do
			localizePrompt(prompt)
		end
		CollectionService:GetInstanceAddedSignal(tag):Connect(localizePrompt)
	end
	player:GetAttributeChangedSignal("BribePrice"):Connect(function()
		for _, prompt in CollectionService:GetTagged("PakRTPrompt") do
			localizePrompt(prompt)
		end
	end)

	-- Countdown / ready labels
	task.spawn(function()
		while true do
			local now = workspace:GetServerTimeNow()
			for tile in tracked do
				local status = tile:FindFirstChild("Status")
				local textLabel = if status then status:FindFirstChild("Label") :: TextLabel? else nil
				if textLabel then
					local state = tile:GetAttribute("State")
					local crop = tile:GetAttribute("Crop")
					local hot = tile:GetAttribute("Hot") == true
					if state == "growing" and type(crop) == "string" then
						local readyAt = tile:GetAttribute("ReadyAt")
						local remaining = if type(readyAt) == "number" then readyAt - now else 0
						local text = t("crop_" .. crop) .. " " .. formatTime(remaining)
						textLabel.Text = if hot then t("tile_hot", text) else text
						textLabel.TextColor3 = if hot then Color3.fromRGB(190, 255, 140) else Color3.new(1, 1, 1)
					elseif state == "ready" then
						textLabel.Text = if hot then t("tile_hot", t("tile_ready")) else t("tile_ready")
						textLabel.TextColor3 = if hot then Color3.fromRGB(190, 255, 140) else Color3.fromRGB(170, 255, 150)
					elseif state == "buy" and isMine(tile) then
						textLabel.Text = "Rp " .. Strings.formatNumber(tile:GetAttribute("Price") or 0, lang)
						textLabel.TextColor3 = Color3.new(1, 1, 1)
					else
						textLabel.Text = ""
					end
				end
			end
			task.wait(0.5)
		end
	end)
end

return Tiles
