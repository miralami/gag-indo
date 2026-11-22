--!nocheck
-- WORK_QUEUE item 238: review-capture HUD helper. hideHud saves the exact prior Enabled of every
-- ScreenGui under the player's PlayerGui, disables them all, and restoreHud writes the saved values
-- back. Pure Lune spec: fake DataModel/PlayerGui/ScreenGui tables, no game API.

return function(t, Env)
	local expect = t.expect
	local Review = Env.new():require("shared/LookDevReview")

	local function newGui(name, enabled, className)
		return { Name = name, ClassName = className or "ScreenGui", Enabled = enabled }
	end

	local function newPlayerGui(guis)
		local playerGui = { Name = "PlayerGui", ClassName = "PlayerGui" }
		function playerGui:GetDescendants()
			return guis
		end
		return playerGui
	end

	local function newRoot(playerGui, opts)
		opts = opts or {}
		local players = {}
		if not opts.serverOnly then
			players.LocalPlayer = { Name = "Local", PlayerGui = playerGui }
		end
		players._list = if playerGui then { { Name = "Client", PlayerGui = playerGui } } else {}
		function players:GetPlayers()
			return self._list
		end
		return { Players = players }
	end

	local function countEnabled(guis)
		local total = 0
		for _, gui in ipairs(guis) do
			if gui.ClassName == "ScreenGui" and gui.Enabled == true then
				total += 1
			end
		end
		return total
	end

	t:describe("LookDevReview HUD hide/restore (item 238)", function()
		t:beforeEach(function()
			Review.restoreHud() -- no-op when clean; prevents snapshot leakage between cases
		end)

		t:it("HUD_HIDDEN disables every ScreenGui and HUD_RESTORE returns the exact prior values", function()
			local guis = { newGui("Hud", true), newGui("Phone", false), newGui("Board", true) }
			local root = newRoot(newPlayerGui(guis))
			local saved = {}
			for _, gui in ipairs(guis) do
				saved[gui] = gui.Enabled
			end

			expect(Review.hideHud(root)):toBe(3)
			expect(countEnabled(guis)):toBe(0)
			expect(Review.restoreHud()):toBe(true)
			for _, gui in ipairs(guis) do
				expect(gui.Enabled):toBe(saved[gui])
			end
			expect(countEnabled(guis)):toBe(2)
			expect(Review.restoreHud()):toBe(false)
		end)

		t:it("ignores non-ScreenGui descendants", function()
			local hud = newGui("Hud", true)
			local frame = newGui("Frame", true, "Frame")
			local guis = { hud, frame }
			local root = newRoot(newPlayerGui(guis))

			expect(Review.hideHud(root)):toBe(1)
			expect(hud.Enabled):toBe(false)
			expect(frame.Enabled):toBe(true)
			expect(Review.restoreHud()):toBe(true)
			expect(hud.Enabled):toBe(true)
			expect(frame.Enabled):toBe(true)
		end)

		t:it("a second hide keeps the first snapshot and records later ScreenGuis", function()
			local first = newGui("Hud", true)
			local second = newGui("Phone", false)
			local guis = { first, second }
			local root = newRoot(newPlayerGui(guis))

			expect(Review.hideHud(root)):toBe(2)
			local late = newGui("Late", true)
			table.insert(guis, late)
			expect(Review.hideHud(root)):toBe(3)
			expect(countEnabled(guis)):toBe(0)

			expect(Review.restoreHud()):toBe(true)
			expect(first.Enabled):toBe(true)
			expect(second.Enabled):toBe(false)
			expect(late.Enabled):toBe(true)
		end)

		t:it("handles a missing PlayerGui without losing an existing snapshot", function()
			local missingRoot = newRoot(nil, { serverOnly = true })
			expect(Review.hideHud(missingRoot)):toBe(0)
			expect(Review.restoreHud()):toBe(false)

			local hud = newGui("Hud", true)
			local root = newRoot(newPlayerGui({ hud }))
			expect(Review.hideHud(root)):toBe(1)
			expect(Review.hideHud(missingRoot)):toBe(0) -- failed hide must not clear the snapshot
			expect(hud.Enabled):toBe(false)
			expect(Review.restoreHud()):toBe(true)
			expect(hud.Enabled):toBe(true)
		end)

		t:it("SERVER VM fallback resolves PlayerGui through GetPlayers", function()
			local guis = { newGui("Hud", true), newGui("Board", false) }
			local root = newRoot(newPlayerGui(guis), { serverOnly = true })

			expect(Review.hideHud(root)):toBe(2)
			expect(countEnabled(guis)):toBe(0)
			expect(Review.restoreHud()):toBe(true)
			expect(guis[1].Enabled):toBe(true)
			expect(guis[2].Enabled):toBe(false)
		end)

		t:it("resolves a fake game root through GetService", function()
			local hud = newGui("Hud", true)
			local playerGui = newPlayerGui({ hud })
			local players = { LocalPlayer = { PlayerGui = playerGui } }
			local root = {
				GetService = function(_, name)
					return if name == "Players" then players else nil
				end,
			}

			expect(Review.hideHud(root)):toBe(1)
			expect(hud.Enabled):toBe(false)
			expect(Review.restoreHud()):toBe(true)
			expect(hud.Enabled):toBe(true)
		end)

		t:it("walks GetChildren when GetDescendants is unavailable", function()
			local hud = newGui("Nested", true)
			local folder = {
				Name = "Folder",
				ClassName = "Folder",
				GetChildren = function()
					return { hud }
				end,
			}
			local playerGui = {
				Name = "PlayerGui",
				ClassName = "PlayerGui",
				GetChildren = function()
					return { folder }
				end,
			}
			local root = newRoot(playerGui)

			expect(Review.hideHud(root)):toBe(1)
			expect(hud.Enabled):toBe(false)
			expect(Review.restoreHud()):toBe(true)
			expect(hud.Enabled):toBe(true)
		end)
	end)
end
