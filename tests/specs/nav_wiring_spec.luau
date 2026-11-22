--!nocheck
-- WORK_QUEUE item 21 (gamepad/keyboard navigation): static wiring checks. The pure policy is
-- covered by navigation_spec.luau; this file locks the Studio-side hookups that specs cannot run
-- under Lune (ContextActionService binding, GuiService.SelectedObject writes, and one registration
-- per dismissable screen). The Studio pass in docs/v2/evidence/ covers runtime behaviour.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect

	local function read(path)
		return fs.readFile(path)
	end

	local function has(text, needle, label)
		expect(string.find(text, needle, 1, true) ~= nil, label):toBe(true)
	end

	local function lacks(text, needle, label)
		expect(string.find(text, needle, 1, true) == nil, label):toBe(true)
	end

	t:describe("Navigation wiring", function()
		t:it("NavBridge binds B and Escape at High priority and gates on Begin", function()
			local src = read("src/client/UI/NavBridge.luau")
			has(src, "BindActionAtPriority", "uses BindActionAtPriority")
			has(src, "Enum.KeyCode.Escape", "binds Escape")
			has(src, "Enum.KeyCode.ButtonB", "binds gamepad B")
			has(src, "Enum.ContextActionPriority.High.Value", "binds at High priority")
			has(src, "Enum.UserInputState.Begin", "gates on Begin")
			has(src, "Enum.ContextActionResult.Sink", "sinks a handled close")
			has(src, "Enum.ContextActionResult.Pass", "passes Escape when nothing closes")
			has(src, "false,", "does not create a touch button")
		end)

		t:it("NavBridge writes and watches GuiService.SelectedObject", function()
			local src = read("src/client/UI/NavBridge.luau")
			has(src, "GuiService.SelectedObject = token", "assigns SelectedObject")
			has(src, 'GetPropertyChangedSignal("SelectedObject")', "watches selection changes")
		end)

		t:it("every dismissable screen registers a default and a close callback", function()
			local screens = {
				{ path = "src/client/UI/Phone.luau", id = "phone" },
				{ path = "src/client/UI/Hud.luau", id = "shop" },
				{ path = "src/client/UI/Leaderboard.luau", id = "leaderboard" },
				{ path = "src/client/UI/Admin.luau", id = "admin" },
				{ path = "src/client/UI/Minigame.luau", id = "minigame" },
			}
			for _, screen in screens do
				local src = read(screen.path)
				has(src, 'NavBridge.register("' .. screen.id .. '"', screen.id .. " registers")
				has(src, "local NavBridge = require(script.Parent.NavBridge)", screen.id .. " requires the bridge")
			end
		end)

		t:it("admin unregisters when destroyed", function()
			local src = read("src/client/UI/Admin.luau")
			has(src, 'NavBridge.unregister("admin")', "admin unregisters in destroy()")
		end)

		t:it("the raid overlay is registered non-dismissable with a phase-driven default", function()
			local src = read("src/client/UI/RaidOverlay.luau")
			has(src, 'NavBridge.register("raid"', "raid registers")
			-- Non-closable: B/Escape must never dismiss the forced timed choice.
			local raidBlock = string.match(src, 'NavBridge.register%("raid".-%)')
			expect(raidBlock ~= nil, "raid registration block found"):toBe(true)
			has(raidBlock, "closable = false", "raid is non-dismissable")
			has(raidBlock, "function()", "raid default is dynamic")
			has(src, "if fineButton.Visible then", "default follows Fine button")
			has(src, "if skipButton.Visible then", "default follows Skip button")
			has(src, "NavBridge.rescue()", "raid re-rescues on phase changes")
		end)

		t:it("the client bootstrap starts the bridge after screens mount", function()
			local src = read("src/client/Main.client.luau")
			has(src, "local NavBridge = require(script.Parent.UI.NavBridge)", "bootstrap requires bridge")
			has(src, "NavBridge.start()", "bootstrap starts bridge")
			local mount = string.find(src, "Tiles.mount(lang)", 1, true)
			local start = string.find(src, "NavBridge.start()", 1, true)
			expect(start ~= nil and mount ~= nil and start > mount, "start runs after mounts"):toBe(true)
		end)

		t:it("the pure policy stays free of Roblox globals", function()
			local src = read("src/client/UI/Navigation.luau")
			lacks(src, "game:GetService", "no service access")
			lacks(src, 'GetService("GuiService")', "no GuiService dependency")
			lacks(src, "Instance.new", "no instance creation")
		end)
	end)
end
