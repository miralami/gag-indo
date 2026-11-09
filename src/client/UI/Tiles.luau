-- Tiles: local-only presentation of plots.
--  * Hides prompts on other players' plots (the server still checks ownership).
--  * Localizes prompt text and shows countdown labels above tiles.
-- Uses CollectionService tags so it keeps working when tiles stream in/out.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Strings = require(Shared.Strings)

local player = Players.LocalPlayer
local PROMPT_DISTANCE = 10 -- matches PlotService.makePrompt

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
		prompt.ObjectText = Strings.get(lang, "prompt_tile")
		if state == "empty" then
			local seed = player:GetAttribute("SelectedSeed") or "padi"
			prompt.ActionText = Strings.get(lang, "prompt_plant", "@crop_" .. seed)
		elseif state == "ready" then
			prompt.ActionText = Strings.get(lang, "prompt_harvest")
		elseif state == "growing" then
			prompt.ActionText = Strings.get(lang, "prompt_growing")
		elseif state == "buy" then
			prompt.ActionText = Strings.get(lang, "prompt_buy_tile", tile:GetAttribute("Price") or 0)
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
			for _, c in connections do
				c:Disconnect()
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

	-- Pasar prompt text
	local function localizePasar(instance: Instance)
		if instance:IsA("ProximityPrompt") then
			instance.ObjectText = Strings.get(lang, "prompt_pasar")
			instance.ActionText = Strings.get(lang, "prompt_sell")
		end
	end
	for _, prompt in CollectionService:GetTagged("PasarPrompt") do
		localizePasar(prompt)
	end
	CollectionService:GetInstanceAddedSignal("PasarPrompt"):Connect(localizePasar)

	-- Countdown labels
	task.spawn(function()
		while true do
			local now = workspace:GetServerTimeNow()
			for tile in tracked do
				local status = tile:FindFirstChild("Status")
				local textLabel = if status then status:FindFirstChild("Label") :: TextLabel? else nil
				if textLabel then
					local state = tile:GetAttribute("State")
					local crop = tile:GetAttribute("Crop")
					if state == "growing" and type(crop) == "string" then
						local readyAt = tile:GetAttribute("ReadyAt")
						local remaining = if type(readyAt) == "number" then readyAt - now else 0
						textLabel.Text = Strings.get(lang, "crop_" .. crop) .. " " .. formatTime(remaining)
					elseif state == "ready" then
						textLabel.Text = Strings.get(lang, "tile_ready")
					elseif state == "buy" and isMine(tile) then
						textLabel.Text = "Rp " .. Strings.formatNumber(tile:GetAttribute("Price") or 0, lang)
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
