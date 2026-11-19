--!nocheck
-- WORK_QUEUE round-2 item 18: CLIENT ERROR BOUNDARY.
-- Execute the REAL src/client/Main.client.luau under the Env harness with one or more UI/feel
-- modules forced to throw from mount()/start(). The bootstrap must not abort: every other
-- module still mounts, and each failed module is warned exactly once.

return function(t, Env, Fakes)
	local expect = t.expect

	local UI = {
		"client/UI/Hud", "client/UI/Tiles", "client/UI/Evidence", "client/UI/Phone",
		"client/UI/Minigame", "client/UI/RaidOverlay", "client/UI/Admin",
		"client/UI/Leaderboard",
	}
	local WORLD = { "client/World/Sky", "client/World/Wind" }
	local FEEL = {
		"client/Feel/CameraFeel", "client/Feel/ActionFeel",
		"client/Feel/FidelityRuntime", "client/Feel/FpsSampler",
	}
	local Others = { "client/Audio", "client/State", "client/Chat/Tags" }
	local LOOKDEV = {
		"client/World/LookDevPlaza", "client/UI/LookDevIcons", "client/World/LookDevTextures",
		"client/World/LookDevNpcs", "client/World/LookDevCrops", "client/World/LookDevHubProps",
		"client/World/LookDevSounds",
	}

	-- The exact mount/start calls the bootstrap must make.
	local EXPECTED = {}
	for _, path in ipairs(UI) do table.insert(EXPECTED, path .. ".mount") end
	for _, path in ipairs(WORLD) do
		table.insert(EXPECTED, path .. (path == "client/World/Sky" and ".mount" or ".start"))
	end
	for _, path in ipairs(FEEL) do table.insert(EXPECTED, path .. ".start") end
	for _, path in ipairs(Others) do
		local method = if path == "client/State" or path == "client/Chat/Tags" then ".mount" else ".start"
		table.insert(EXPECTED, path .. method)
	end
	table.insert(EXPECTED, "client/UI/NavBridge.start")

	local function boot(failures)
		failures = failures or {}
		local env = Env.new()
		env.services.LocalizationService = { RobloxLocaleId = "en-us" }
		local calls = {}

		env:mock("shared/Strings", { langFor = function() return "en" end })

		local function stub(path, methods)
			local mod = {}
			for _, method in ipairs(methods) do
				mod[method] = function()
					table.insert(calls, path .. "." .. method)
					if failures[path .. "." .. method] then
						error("forced failure: " .. path .. "." .. method)
					end
					-- Hud.mount returns the parent Gui consumed by Evidence.mount.
					if path == "client/UI/Hud" and method == "mount" then
						return {}
					end
				end
			end
			env:mock(path, mod)
		end

		for _, path in ipairs(UI) do stub(path, { "mount" }) end
		for _, path in ipairs(WORLD) do
			stub(path, { path == "client/World/Sky" and "mount" or "start" })
		end
		for _, path in ipairs(FEEL) do stub(path, { "start" }) end
		for _, path in ipairs(Others) do
			local method = if path == "client/State" or path == "client/Chat/Tags" then "mount" else "start"
			stub(path, { method })
		end
		stub("client/UI/NavBridge", { "start" })
		for _, path in ipairs(LOOKDEV) do env:mock(path, {}) end

		env:addScript("client/Main.client")
		local ok, err = pcall(function()
			env:require("client/Main.client")
		end)
		return { env = env, calls = calls, ok = ok, err = err }
	end

	local function countCall(calls, name)
		local n = 0
		for _, c in ipairs(calls) do if c == name then n += 1 end end
		return n
	end

	local function countWarning(env, needle)
		local n = 0
		for _, w in ipairs(env.warnings) do
			if string.find(w, needle, 1, true) then n += 1 end
		end
		return n
	end

	local function assertAllOthersRan(r)
		for _, name in ipairs(EXPECTED) do
			if countCall(r.calls, name) ~= 1 then
				error("missing call " .. name .. "; got: " .. table.concat(r.calls, ", ") ..
					"; warnings: " .. table.concat(r.env.warnings, " | "))
			end
		end
	end

	t:describe("Client error boundary (round-2 item 18)", function()
		t:it("a failing UI module never aborts the rest of the bootstrap", function()
			local r = boot({ ["client/UI/Hud.mount"] = true })
			expect(r.ok):toBe(true)
			if not r.ok then error("Main.client threw: " .. tostring(r.err)) end
			assertAllOthersRan(r)
			expect(countWarning(r.env, "Hud.mount")):toBe(1)
		end)

		t:it("a failing feel module is isolated and warned exactly once", function()
			local r = boot({ ["client/Feel/CameraFeel.start"] = true })
			expect(r.ok):toBe(true)
			if not r.ok then error("Main.client threw: " .. tostring(r.err)) end
			assertAllOthersRan(r)
			expect(countWarning(r.env, "CameraFeel.start")):toBe(1)
		end)

		t:it("several failures are each warned once and never stop the mount loop", function()
			local r = boot({
				["client/UI/Phone.mount"] = true,
				["client/Feel/ActionFeel.start"] = true,
				["client/UI/NavBridge.start"] = true,
			})
			expect(r.ok):toBe(true)
			if not r.ok then error("Main.client threw: " .. tostring(r.err)) end
			assertAllOthersRan(r)
			expect(countWarning(r.env, "Phone.mount")):toBe(1)
			expect(countWarning(r.env, "ActionFeel.start")):toBe(1)
			expect(countWarning(r.env, "NavBridge.start")):toBe(1)
			expect(#r.env.warnings):toBe(3)
		end)

		t:it("a clean bootstrap warns nothing", function()
			local r = boot()
			expect(r.ok):toBe(true)
			if not r.ok then error("Main.client threw: " .. tostring(r.err)) end
			assertAllOthersRan(r)
			expect(#r.env.warnings):toBe(0)
		end)
	end)
end
