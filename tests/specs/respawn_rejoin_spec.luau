--!nocheck
-- WORK_QUEUE item 13: respawn and rejoin. A character reset fires CharacterAdded again; every
-- handler that connects to it must connect exactly once per session, never once per respawn, and
-- the per-character work must run once each time. The HUD owns ScreenGuis with ResetOnSpawn=false so
-- a reset never destroys/rebuilds them. LUNE-ONLY; the 10-reset Studio loop is in the evidence report.

return function(t, Env, Fakes)
	local expect = t.expect

	-- FarmService --------------------------------------------------------------------------------
	-- onLoaded (once per session) registers one CharacterAdded handler that teleports the player to
	-- their plot after each respawn. Ten respawns must keep one connection and fire ten teleports.
	local function makeFarm()
		local env = Env.new()
		local remotes = Fakes.remotes(env)
		local playerData = Fakes.playerData()
		local teleports = {}

		local cf = setmetatable({}, { __mul = function() return cf end })
		local function newPart(name)
			local node = {
				Name = name, _children = {}, _attributes = {}, CFrame = cf,
				Size = env.Vector3.new(6, 0.5, 6), Position = env.Vector3.new(0, 0, 0),
			}
			function node:SetAttribute(k, v) self._attributes[k] = v end
			function node:GetAttribute(k) return self._attributes[k] end
			function node:FindFirstChild(n) return self._children[n] end
			function node:Destroy() end
			return node
		end
		local tile1, tile2 = newPart("Tile_1"), newPart("Tile_2")
		tile1._children.Prompt = { Enabled = false }
		tile2._children.Prompt = { Enabled = false }
		local plot = {
			index = 1, tiles = { [1] = tile1, [2] = tile2 },
			spawnCFrame = { Position = env.Vector3.new(0, 0, 0) },
		}
		env.globals.Instance = { new = function(className) return newPart(className) end }
		env.globals.CFrame = { new = function() return cf end }
		env.globals.Color3.fromHex = function() return {} end
		local vectorMeta = getmetatable(env.Vector3.new(0, 0, 0))
		vectorMeta.__mul = function(a, b) return env.Vector3.new(a.X * b, a.Y * b, a.Z * b) end

		env:mock("shared/Remotes", remotes)
		env:mock("server/Data/PlayerData", playerData)
		env:mock("server/Net/Notify", Fakes.notify())
		env:mock("server/Net/RateLimit", Fakes.rateLimit(true))
		env:mock("server/Net/State", { touch = function() end })
		env:mock("server/Live/LiveConfig", {
			getRuntime = function() return { musim = "kemarau", anomali = "none", cuaca = "cerah" } end,
		})
		env:mock("server/Analytics/Analytics", { track = function() end, log = function() end })
		env:mock("server/Economy/EconomyService", {
			hasRank = function() return true end,
			sync = function() end,
			addHarvest = function() end,
			near = function() return true end,
			refreshRank = function() end,
			addCash = function() end,
			trySpend = function(_, amount) return amount ~= nil end,
		})
		env:mock("server/Progression/AlmanakService", { record = function() return nil end })
		env:mock("server/Progression/BadgeService", { award = function() end })
		env:mock("server/Progression/OnboardingService", { advance = function() end })
		env:mock("server/Progression/QuestService", { progress = function() end })
		env:mock("server/Farm/PlotService", {
			claim = function() return plot end,
			teleportToPlot = function(p) table.insert(teleports, p) end,
			onTilePrompt = function() end,
			getPlotOf = function() return plot end,
			getPlot = function() return plot end,
		})

		local FarmService = env:require("server/Farm/FarmService")
		-- start() owns an infinite task.spawn growth loop; suppress it just for start().
		local realSpawn = env.globals.task.spawn
		env.globals.task.spawn = function() end
		FarmService.start()
		local player = Fakes.player(env)
		plot.owner = player
		local data = playerData.set(player, Fakes.newData(env))
		player.CharacterAdded = Env.newSignal()
		player.Character = nil -- no initial task.spawn teleport
		playerData.fireLoaded(player, data)
		env.globals.task.spawn = realSpawn

		return { env = env, player = player, data = data, teleports = teleports }
	end

	t:describe("respawn: FarmService CharacterAdded (item 13)", function()
		t:it("connects CharacterAdded once per session; ten respawns do not grow it", function()
			local fx = makeFarm()
			expect(#fx.player.CharacterAdded._handlers):toBe(1)
			for i = 1, 10 do
				fx.player.CharacterAdded:Fire({ Name = "Character" .. i })
			end
			expect(#fx.player.CharacterAdded._handlers):toBe(1)
		end)

		t:it("each respawn teleports to the plot exactly once", function()
			local fx = makeFarm()
			for i = 1, 10 do
				fx.player.CharacterAdded:Fire({ Name = "Character" .. i })
			end
			expect(#fx.teleports):toBe(10)
			for _, p in fx.teleports do
				expect(p):toBe(fx.player)
			end
		end)
	end)

	-- Cosmetics ---------------------------------------------------------------------------------
	-- onLoaded (once per session) registers one CharacterAdded handler that re-applies the equipped
	-- cosmetic to each new character. Ten respawns keep one connection and build one hat per reset.
	local function makeCosmetics()
		local env = Env.new()
		local playerData = Fakes.playerData()
		local made = { Part = 0, WeldConstraint = 0 }

		local cf = setmetatable({}, { __mul = function() return cf end })
		env.globals.CFrame = { new = function() return cf end, Angles = function() return cf end }
		env.globals.Instance = { new = function(className)
			made[className] = (made[className] or 0) + 1
			local inst = { Name = className, Destroyed = false }
			function inst:Destroy() self.Destroyed = true end
			return inst
		end }

		env:mock("shared/Remotes", Fakes.remotes(env))
		env:mock("server/Data/PlayerData", playerData)
		env:mock("server/Net/Notify", Fakes.notify())
		env:mock("server/Net/RateLimit", Fakes.rateLimit(true))
		env:mock("server/Economy/EconomyService", {})

		local Cosmetics = env:require("server/Monetization/Cosmetics")
		Cosmetics.start()
		local player = Fakes.player(env)
		local data = playerData.set(player, Fakes.newData(env))
		data.equipped = { cosmetic = "peci" } -- a plain hat, no caping cylinder special case
		player.CharacterAdded = Env.newSignal()
		player.Character = nil
		playerData.fireLoaded(player, data)

		return { env = env, player = player, data = data, made = made }
	end

	local function fakeCharacter(env)
		local head = { Name = "Head", CFrame = env.globals.CFrame.new(), Size = env.Vector3.new(2, 1, 2) }
		local children = { Head = head }
		local character = {
			Parent = env.services.Players,
			FindFirstChild = function(_, name) return children[name] end,
		}
		return character
	end

	t:describe("respawn: Cosmetics CharacterAdded (item 13)", function()
		t:it("connects CharacterAdded once; re-applies the hat once per respawn", function()
			local fx = makeCosmetics()
			expect(#fx.player.CharacterAdded._handlers):toBe(1)
			for i = 1, 10 do
				local character = fakeCharacter(fx.env)
				fx.player.Character = character
				fx.player.CharacterAdded:Fire(character)
			end
			expect(#fx.player.CharacterAdded._handlers):toBe(1)
			expect(fx.made.Part):toBe(10) -- one CosmeticHat built per reset, no accumulation
			expect(fx.made.WeldConstraint):toBe(10)
		end)
	end)

	-- CameraFeel ---------------------------------------------------------------------------------
	-- start() is idempotent; its three character-scoped signals connect once. Ten reset cycles that
	-- fire CharacterAdded and CharacterRemoving must not grow any connection; stop() clears all.
	t:describe("respawn: CameraFeel character-scoped signals (item 13)", function()
		t:it("ten reset cycles keep one connection per owned signal", function()
			local env = Env.new()
			env.globals.TweenInfo = { new = function() return {} end }
			env.services.TweenService = {
				Create = function() return { Play = function() end, Cancel = function() end } end,
			}
			local heartbeat = Env.newSignal()
			local characterAdded = Env.newSignal()
			local characterRemoving = Env.newSignal()
			env.services.RunService.Heartbeat = heartbeat
			env.services.Players.LocalPlayer = {
				Character = nil,
				CharacterAdded = characterAdded,
				CharacterRemoving = characterRemoving,
			}
			local CameraFeel = env:require("client/Feel/CameraFeel")
			CameraFeel.start()
			expect(#heartbeat._handlers):toBe(1)
			expect(#characterAdded._handlers):toBe(1)
			expect(#characterRemoving._handlers):toBe(1)

			for i = 1, 10 do
				local humanoid = {
					WalkSpeed = 16,
					MoveDirection = { Magnitude = 0 },
					IsA = function() return true end,
				}
				local character = {
					WaitForChild = function(_, name)
						if name == "Humanoid" then return humanoid end
					end,
				}
				characterRemoving:Fire(character) -- old character dies
				characterAdded:Fire(character) -- new character spawns
			end

			expect(#heartbeat._handlers):toBe(1)
			expect(#characterAdded._handlers):toBe(1)
			expect(#characterRemoving._handlers):toBe(1)
			CameraFeel.stop()
			expect(#heartbeat._handlers):toBe(0)
			expect(#characterAdded._handlers):toBe(0)
			expect(#characterRemoving._handlers):toBe(0)
		end)
	end)

	-- UI after reset -----------------------------------------------------------------------------
	-- Every HUD ScreenGui is created with ResetOnSpawn=false, so a character reset never destroys
	-- it; there is no UI teardown/rebuild to get wrong on respawn. LazyPages (separately spec'd)
	-- covers the deliberate page close→reopen rebuild for the phone's lazy app pages.
	t:describe("respawn: UI survives a character reset (item 13)", function()
		t:it("Theme.screenGui is ResetOnSpawn=false so the HUD is not destroyed on respawn", function()
			local env = Env.new()
			env.globals.Color3.fromHex = function() return { R = 0, G = 0, B = 0 } end
			env.services.TweenService = { Create = function() return { Play = function() end } end }
			local playerGui = {}
			env.services.Players.LocalPlayer = {
				WaitForChild = function(_, name)
					if name == "PlayerGui" then return playerGui end
				end,
			}
			env.globals.Instance = { new = function(className) return { ClassName = className } end }
			local Theme = env:require("client/UI/Theme")
			local gui = Theme.screenGui("HudGui", 1)
			expect(gui.ResetOnSpawn):toBe(false)
			expect(gui.Name):toBe("HudGui")
		end)
	end)
end
