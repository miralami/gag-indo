--!nocheck
-- WORK_QUEUE item 21: gamepad/keyboard navigation policy (LUNE-ONLY pure-logic specs).
--
-- src/client/UI/Navigation.luau is a pure stack/rescue policy with no Roblox globals, so it runs
-- under Lune. The Studio bridge (NavBridge.luau) supplies the visibility predicate and writes
-- GuiService.SelectedObject; the item's Studio pass covers that half. These specs lock the rules:
-- LIFO cancel, dismissability, default selection, and rescue out of hidden frames.

return function(t, Env)
	local expect = t.expect
	local Navigation

	-- Fake tokens are plain tables. `visible` is the predicate the bridge would compute from
	-- GuiObject.Visible ancestry; here it is a set membership check.
	local function vis(set)
		return function(token)
			return token ~= nil and set[token] == true
		end
	end

	t:describe("Navigation policy", function()
	t:beforeEach(function()
		local env = Env.new()
		Navigation = env:require("client/UI/Navigation")
	end)

	t:describe("Navigation stack", function()
		t:it("opens and closes screens in LIFO order", function()
			local nav = Navigation.new()
			local a, b = { name = "a" }, { name = "b" }
			nav:register("phone", { root = a, default = a, onClose = function() end })
			nav:register("shop", { root = b, default = b, onClose = function() end })
			expect(nav:count()):toBe(0) -- registration alone does not open a screen
			expect(nav:open("phone")):toBe(a)
			expect(nav:open("shop")):toBe(b)
			expect(nav:count()):toBe(2)
			expect(nav:ids()):toEqual({ "phone", "shop" })
			expect(nav:top().id):toBe("shop")
			expect(nav:close("shop")):toBe(a) -- restores the next screen's default
			expect(nav:top().id):toBe("phone")
			expect(nav:close("phone")):toBeNil()
			expect(nav:count()):toBe(0)
		end)

		t:it("re-registering an id moves it to the top and does not duplicate", function()
			local nav = Navigation.new()
			nav:register("a", { root = {}, default = {}, onClose = function() end })
			nav:register("b", { root = {}, default = {}, onClose = function() end })
			nav:open("a")
			nav:open("b")
			nav:register("a", { root = {}, default = {}, onClose = function() end })
			expect(nav:count()):toBe(2)
			expect(nav:ids()):toEqual({ "b", "a" })
		end)

		t:it("can be closed and reopened with its default restored", function()
			local nav = Navigation.new()
			local default = { name = "close" }
			nav:register("phone", { root = {}, default = default, onClose = function() end })
			expect(nav:open("phone")):toBe(default)
			nav:close("phone")
			expect(nav:count()):toBe(0)
			-- the screen stays registered, so reopening still yields its default selection
			expect(nav:open("phone")):toBe(default)
			expect(nav:count()):toBe(1)
		end)

		t:it("does not sink cancel when nothing is open", function()
			local nav = Navigation.new()
			nav:register("phone", { root = {}, default = {}, onClose = function() end })
			-- registered but never opened: Escape must pass through to the core menu
			expect(nav:cancel()):toBe(false)
		end)

		t:it("unregister removes a screen and cancels never returns it", function()
			local nav = Navigation.new()
			nav:register("a", { root = {}, default = {}, onClose = function() end })
			local removed = nav:unregister("a")
			expect(removed.id):toBe("a")
			expect(nav:count()):toBe(0)
			local handled = nav:cancel()
			expect(handled):toBe(false)
		end)
	end)

	t:describe("Navigation cancel (B / Escape)", function()
		t:it("closes only the topmost dismissable screen", function()
			local nav = Navigation.new()
			local closed = {}
			nav:register("phone", { root = {}, default = {}, onClose = function() table.insert(closed, "phone") end })
			nav:register("shop", { root = {}, default = {}, onClose = function() table.insert(closed, "shop") end })
			nav:open("phone")
			nav:open("shop")
			local ok1, fn1 = nav:cancel()
			expect(ok1):toBe(true)
			fn1()
			expect(closed):toEqual({ "shop" })
			local ok2, fn2 = nav:cancel()
			expect(ok2):toBe(true)
			fn2()
			expect(closed):toEqual({ "shop", "phone" })
			local ok3 = nav:cancel()
			expect(ok3):toBe(false)
		end)

		t:it("skips forced, non-dismissable overlays (raid)", function()
			local nav = Navigation.new()
			local closed = {}
			nav:register("phone", { root = {}, default = {}, onClose = function() table.insert(closed, "phone") end })
			nav:register("raid", { root = {}, default = {}, closable = false, onClose = nil })
			nav:open("phone")
			nav:open("raid")
			expect(nav:top().id):toBe("raid")
			-- Raid is non-closable, so cancel falls through to the phone underneath.
			local ok, fn = nav:cancel()
			expect(ok):toBe(true)
			fn()
			expect(closed):toEqual({ "phone" })
		end)

		t:it("returns false when the only open screen has no close callback", function()
			local nav = Navigation.new()
			nav:register("toast", { root = {}, default = {}, onClose = nil })
			nav:open("toast")
			local ok = nav:cancel()
			expect(ok):toBe(false)
		end)

		t:it("a dismissable screen with closable=false is still skipped", function()
			local nav = Navigation.new()
			local closed = false
			nav:register("forced", {
				root = {}, default = {}, closable = false,
				onClose = function() closed = true end,
			})
			nav:open("forced")
			local ok = nav:cancel()
			expect(ok):toBe(false)
			expect(closed):toBe(false)
		end)
	end)

	t:describe("Navigation default selection", function()
		t:it("open returns the screen's default token", function()
			local nav = Navigation.new()
			local default = { name = "close" }
			nav:register("shop", { root = {}, default = default, onClose = function() end })
			expect(nav:open("shop")):toBe(default)
		end)

		t:it("resolves a function default each time it is read (phase-driven screens)", function()
			local nav = Navigation.new()
			local phase = "intro"
			local skip, fine = { name = "skip" }, { name = "fine" }
			local calls = 0
			nav:register("raid", {
				root = {}, closable = false,
				default = function()
					calls += 1
					return if phase == "intro" then skip else fine
				end,
			})
			expect(nav:open("raid")):toBe(skip)
			phase = "choosing"
			expect(nav:open("raid")):toBe(fine)
			expect(calls):toBe(2)
		end)
	end)

	t:describe("Navigation rescue (selection never stuck in a hidden frame)", function()
		t:it("keeps a still-visible selection", function()
			local nav = Navigation.new()
			local sel, default = { name = "sel" }, { name = "default" }
			nav:register("phone", { root = {}, default = default, onClose = function() end })
			nav:open("phone")
			local target, reason = nav:rescue(sel, vis({ [sel] = true, [default] = true }))
			expect(target):toBe(sel)
			expect(reason):toBe("keep")
		end)

		t:it("moves a hidden selection to the topmost screen's visible default", function()
			local nav = Navigation.new()
			local hidden, phoneDefault, shopDefault = {}, {}, {}
			nav:register("phone", { root = {}, default = phoneDefault, onClose = function() end })
			nav:register("shop", { root = {}, default = shopDefault, onClose = function() end })
			nav:open("phone")
			nav:open("shop")
			-- selection was on a frame that just hid; shop default is visible.
			local target, reason = nav:rescue(hidden, vis({ [phoneDefault] = true, [shopDefault] = true }))
			expect(target):toBe(shopDefault)
			expect(reason):toBe("default")
		end)

		t:it("falls back to a lower screen when the top default is hidden", function()
			local nav = Navigation.new()
			local hidden, phoneDefault, shopDefault = {}, {}, {}
			nav:register("phone", { root = {}, default = phoneDefault, onClose = function() end })
			nav:register("shop", { root = {}, default = shopDefault, onClose = function() end })
			nav:open("phone")
			nav:open("shop")
			-- top (shop) default hidden (e.g. raid phase), phone default still visible.
			local target, reason = nav:rescue(hidden, vis({ [phoneDefault] = true }))
			expect(target):toBe(phoneDefault)
			expect(reason):toBe("default")
		end)

		t:it("clears selection when no default is visible", function()
			local nav = Navigation.new()
			local hidden, default = {}, {}
			nav:register("phone", { root = {}, default = default, onClose = function() end })
			nav:open("phone")
			local target, reason = nav:rescue(hidden, vis({}))
			expect(target):toBeNil()
			expect(reason):toBe("clear")
		end)

		t:it("clears selection when all screens are closed", function()
			local nav = Navigation.new()
			local default = {}
			nav:register("phone", { root = {}, default = default, onClose = function() end })
			nav:open("phone")
			nav:close("phone")
			local target, reason = nav:rescue(nil, vis({ [default] = true }))
			expect(target):toBeNil()
			expect(reason):toBe("clear")
		end)

		t:it("handles a nil selection with no screens open", function()
			local nav = Navigation.new()
			local target, reason = nav:rescue(nil, vis({}))
			expect(target):toBeNil()
			expect(reason):toBe("clear")
		end)
	end)
	end)
end
