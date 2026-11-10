-- Admin panel (v2 PLAN §7.1). Internal tool, not a player-facing screen: it uses the v1
-- Theme for now and will move onto the v2 kit with the rest of the UI in M3.
--
-- The server marks allowlisted players with the IsAdmin attribute; everyone else never
-- sees the panel and the server rejects their commands anyway.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Strings = require(Shared.Strings)
local Remotes = require(Shared.Remotes)

local Theme = require(script.Parent.Theme)

local player = Players.LocalPlayer

local Admin = {}

local lang = "en"
local gui: ScreenGui? = nil
local panel: Frame? = nil
local statusLabel: TextLabel? = nil
local logLabel: TextLabel? = nil
local order = 0

local function t(key: string, ...: any): string
	return Strings.get(lang, key, ...)
end

local function nextOrder(): number
	order += 1
	return order
end

local function send(action: string, value: any?)
	Remotes.Admin_Command:FireServer({ action = action, value = value })
end

local function setLog(text: string)
	if logLabel then
		logLabel.Text = text
	end
end

local function row(parent: Frame, title: string, buttons: { any }): Frame
	local frame = Theme.new("Frame", {
		Name = "Row",
		LayoutOrder = nextOrder(),
		Size = UDim2.new(1, 0, 0, 56),
		BackgroundTransparency = 1,
		Parent = parent,
	})
	Theme.label({
		Size = UDim2.new(1, 0, 0, 18),
		Text = title,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextScaled = true,
		Parent = frame,
	})
	local holder = Theme.new("Frame", {
		Name = "Buttons",
		Position = UDim2.new(0, 0, 0, 20),
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1,
		Parent = frame,
	}, {
		Theme.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	for index, spec in buttons do
		local button = Theme.button({
			Name = spec.name or ("Button" .. index),
			LayoutOrder = index,
			Size = UDim2.new(0, spec.width or 72, 1, 0),
			Text = spec.text,
			Parent = holder,
		})
		button.Activated:Connect(spec.onClick)
	end
	return frame
end

local function updateStatus(config, runtime)
	if not statusLabel or type(config) ~= "table" or type(runtime) ~= "table" then
		return
	end
	local events = if type(config.events) == "table" then config.events else {}
	statusLabel.Text = string.format(
		"%s: %s (%s) · %s: %s · %s · %s: %s",
		t("admin_season"),
		tostring(runtime.musim),
		tostring(runtime.seasonSource),
		t("admin_anomaly"),
		tostring(runtime.anomali),
		tostring(runtime.cuaca),
		t("admin_cabai"),
		tostring(events.cabai or "auto")
	)
end

local function build()
	if gui and gui.Parent then
		return
	end
	order = 0
	gui = Theme.screenGui("AdminPanel", 80)
	local frame = Theme.card({
		Name = "Panel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(340, 470),
		Visible = false,
		Parent = gui,
	}, {
		Theme.new("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
		}),
		Theme.new("UIPadding", {
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
			PaddingTop = UDim.new(0, 10),
			PaddingBottom = UDim.new(0, 10),
		}),
	})
	panel = frame

	Theme.label({
		LayoutOrder = nextOrder(),
		Size = UDim2.new(1, 0, 0, 26),
		Text = t("admin_title"),
		Parent = frame,
	})

	local status = Theme.label({
		LayoutOrder = nextOrder(),
		Size = UDim2.new(1, 0, 0, 34),
		Text = t("admin_ready"),
		TextColor3 = Theme.muted,
		TextWrapped = true,
		Parent = frame,
	})
	status.TextSize = 13
	statusLabel = status

	row(frame, t("admin_season"), {
		{ text = "Hujan", width = 66, onClick = function() send("setSeason", "hujan") end },
		{ text = "Kemarau", width = 74, onClick = function() send("setSeason", "kemarau") end },
		{ text = "Pancaroba", width = 86, onClick = function() send("setSeason", "pancaroba") end },
		{ text = t("admin_auto"), width = 56, onClick = function() send("setSeason", "auto") end },
	})

	row(frame, t("admin_anomaly"), {
		{ text = "None", width = 60, onClick = function() send("setAnomaly", "none") end },
		{ text = "El Nino", width = 72, onClick = function() send("setAnomaly", "elNino") end },
		{ text = "La Nina", width = 72, onClick = function() send("setAnomaly", "laNina") end },
	})

	row(frame, t("admin_cabai"), {
		{ text = "On", width = 52, onClick = function() send("setEvent", { event = "cabai", mode = "on" }) end },
		{ text = "Off", width = 52, onClick = function() send("setEvent", { event = "cabai", mode = "off" }) end },
		{ text = t("admin_auto"), width = 56, onClick = function() send("setEvent", { event = "cabai", mode = "auto" }) end },
		{ text = "Refresh", width = 68, onClick = function() send("refresh") end },
	})

	row(frame, t("admin_grant"), {
		{
			text = "Amplop +1",
			width = 88,
			onClick = function()
				send("grantItem", { userId = player.UserId, itemId = "amplopPremium", amount = 1 })
			end,
		},
		{
			text = "Jaminan +1",
			width = 88,
			onClick = function()
				send("grantItem", { userId = player.UserId, itemId = "jaminanKilat", amount = 1 })
			end,
		},
		{
			text = "Padi +10",
			width = 76,
			onClick = function()
				send("grantItem", { userId = player.UserId, itemId = "seed_padi", amount = 10 })
			end,
		},
	})

	local inspectButtons = {}
	for _, target in Players:GetPlayers() do
		table.insert(inspectButtons, {
			text = "👤 " .. target.Name,
			width = 96,
			onClick = function()
				send("inspect", target.UserId)
			end,
		})
		if #inspectButtons >= 6 then
			break
		end
	end
	if #inspectButtons == 0 then
		inspectButtons = { { text = t("admin_offline"), width = 160, onClick = function() end } }
	end
	row(frame, t("admin_inspect"), inspectButtons)

	local log = Theme.label({
		LayoutOrder = nextOrder(),
		Size = UDim2.new(1, 0, 0, 58),
		Text = t("admin_idle"),
		TextColor3 = Theme.accent,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = frame,
	})
	log.TextSize = 13
	logLabel = log

	local close = Theme.button({
		LayoutOrder = nextOrder(),
		Size = UDim2.new(1, 0, 0, 32),
		Text = t("admin_close"),
		Parent = frame,
	})
	close.Activated:Connect(function()
		if panel then
			panel.Visible = false
		end
	end)
end

local function destroy()
	if gui then
		gui:Destroy()
	end
	gui = nil
	panel = nil
	statusLabel = nil
	logLabel = nil
end

local function toggle()
	if not player:GetAttribute("IsAdmin") then
		return
	end
	build()
	if panel then
		panel.Visible = not panel.Visible
		if panel.Visible then
			send("getConfig")
		end
	end
end

function Admin.mount(langCode: string)
	lang = langCode

	Remotes.Admin_Result.OnClientEvent:Connect(function(result)
		if type(result) ~= "table" then
			return
		end
		if result.ok and type(result.data) == "table" then
			local data = result.data
			if data.config and data.runtime then
				updateStatus(data.config, data.runtime)
			elseif data.name then
				setLog(string.format(
					"%s — Rp %s · %s · Sus %s · NB %s · %s %s",
					tostring(data.name),
					Strings.formatNumber(data.cash or 0, lang),
					tostring(data.rank),
					tostring(data.sus),
					tostring(data.namaBaik),
					t("phone_inventory"),
					tostring(data.produce)
				))
			elseif result.message then
				setLog(tostring(result.message))
			end
		elseif result.message then
			setLog(string.format(t("admin_failed"), tostring(result.message)))
		end
	end)

	player:GetAttributeChangedSignal("IsAdmin"):Connect(function()
		if player:GetAttribute("IsAdmin") then
			build()
		else
			destroy()
		end
	end)

	if player:GetAttribute("IsAdmin") then
		build()
	end

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.F2 then
			toggle()
		end
	end)
end

return Admin

