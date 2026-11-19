--!nocheck
-- WORK_QUEUE item 13: StreamingEnabled readiness. Streaming is NOT flipped by this repo — the
-- setting and its fps trade-off are a designer decision (see WORK_QUEUE "Decisions for designer").
-- What this spec locks is the code-side precondition: no client path waits forever on a world part
-- that streaming may not have replicated yet, and every shipping world-part consumer discovers
-- through CollectionService tags (which follow instances as they stream) rather than a one-time
-- child snapshot. These are source audits, run from the repository root like enums_spec.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect

	-- Names guaranteed to be present on the owning client regardless of streaming. Everything else
	-- reached through WaitForChild needs an explicit timeout so a streamed-out instance cannot hang
	-- a script forever.
	local ALWAYS_REPLICATED = {
		Shared = true,
		Remotes = true,
		PlayerGui = true,
	}

	local function collectLuauFiles(path, out)
		for _, entry in fs.readDir(path) do
			local full = path .. "/" .. entry
			if fs.isDir(full) then
				collectLuauFiles(full, out)
			elseif string.match(entry, "%.luau$") then
				out[#out + 1] = full
			end
		end
		return out
	end

	-- Every WaitForChild call in `source`, with enough context to tell whether it is safe.
	local function findWaitForChildCalls(source, file)
		local found = {}
		for line in string.gmatch(source, "[^\r\n]+") do
			local init = 1
			while true do
				local s, e, args = string.find(line, "WaitForChild%s*%(([^%)]*)%)", init)
				if not s then
					break
				end
				local prefix = string.sub(line, 1, s - 1)
				found[#found + 1] = {
					file = file,
					args = args,
					name = string.match(args, '["\']([^"\']+)["\']'),
					hasTimeout = string.find(args, ",") ~= nil,
					onWorkspace = string.match(prefix, "[Ww]orkspace%s*[:%.]%s*$") ~= nil,
				}
				init = e + 1
			end
		end
		return found
	end

	local function problemFor(call)
		if call.hasTimeout then
			return nil
		end
		if call.onWorkspace then
			return "unbounded WaitForChild on Workspace (a streamable world part)"
		end
		if ALWAYS_REPLICATED[call.name] then
			return nil
		end
		return "unbounded WaitForChild on '" .. tostring(call.name) .. "'"
	end

	-- Shipping modules that consume world parts. Each must discover them via CollectionService tags;
	-- LookDev review tools are handled separately (dev-only, off by default).
	local TAG_CONSUMERS = {
		"src/client/Audio.luau", -- MusicZone
		"src/client/World/Wind.luau", -- WindShake
		"src/client/Feel/ActionFeel.luau", -- Tile
		"src/client/UI/Phone.luau", -- Tile
		"src/client/UI/Tiles.luau", -- Tile / prompts
		"src/client/UI/Leaderboard.luau", -- LeaderboardBoard
		"src/client/World/LookDevNpcs.luau", -- NpcSpawn + GetInstanceAddedSignal
	}

	t:describe("StreamingEnabled readiness (setting not flipped; code stays safe if it is)", function()
		t:it("no client WaitForChild on a streamable path is missing its timeout", function()
			local files = collectLuauFiles("src/client", {})
			expect(#files):toBeAtLeast(20)

			local calls, problems = 0, {}
			for _, file in files do
				for _, call in ipairs(findWaitForChildCalls(fs.readFile(file), file)) do
					calls += 1
					local problem = problemFor(call)
					if problem then
						problems[#problems + 1] = `{file}: {problem} — WaitForChild({call.args})`
					end
				end
			end

			-- Guard against a vacuous pass if the matcher or the file walk regresses.
			expect(calls):toBeAtLeast(20)
			if #problems > 0 then
				error("unbounded client WaitForChild calls found:\n  " .. table.concat(problems, "\n  "), 0)
			end
		end)

		t:it("the WaitForChild classifier flags unbounded world waits and accepts bounded ones (self-check)", function()
			local bad = findWaitForChildCalls('x = workspace:WaitForChild("World")', "literal")
			expect(#bad):toBe(1)
			expect(problemFor(bad[1])):toBeTruthy()

			local bounded = findWaitForChildCalls('x = workspace:WaitForChild("World", 10)', "literal")
			expect(#bounded):toBe(1)
			expect(problemFor(bounded[1])):toBe(nil)

			local shared = findWaitForChildCalls('local Shared = RS:WaitForChild("Shared")', "literal")
			expect(#shared):toBe(1)
			expect(problemFor(shared[1])):toBe(nil)

			local other = findWaitForChildCalls('x = folder:WaitForChild("Inventory")', "literal")
			expect(#other):toBe(1)
			expect(problemFor(other[1])):toBeTruthy()
		end)

		t:it("every world-part consumer discovers instances through CollectionService tags", function()
			local problems = {}
			for _, file in TAG_CONSUMERS do
				local source = fs.readFile(file)
				if string.find(source, "CollectionService:GetTagged%(", 1) == nil then
					problems[#problems + 1] = file .. " does not use CollectionService:GetTagged"
				end
			end
			expect(#TAG_CONSUMERS):toBeAtLeast(5)
			if #problems > 0 then
				error("non-streaming world discovery found:\n  " .. table.concat(problems, "\n  "), 0)
			end
		end)

		t:it("shipping workspace child snapshots are only a supplement to tag discovery", function()
			-- A bare workspace:FindFirstChild(...) snapshot can miss a streamed-out instance. It is
			-- acceptable only when the same module also has a tag-based (streaming-safe) path. The
			-- dev-only LookDev* review tools are excluded: they are off by default and never ship.
			local files = collectLuauFiles("src/client", {})
			local snapshots, problems = 0, {}
			for _, file in files do
				if string.find(file, "LookDev") == nil then
					local source = fs.readFile(file)
					if string.find(source, "[Ww]orkspace[:%.]FindFirstChild%s*%(", 1) then
						snapshots += 1
						if string.find(source, "CollectionService:GetTagged%(", 1) == nil then
							problems[#problems + 1] = file .. " uses a workspace child snapshot without a tag path"
						end
					end
				end
			end

			expect(snapshots):toBeAtLeast(1) -- Phone.neighborPlayers() is the known, guarded case
			if #problems > 0 then
				error("streaming-unsafe workspace snapshots found:\n  " .. table.concat(problems, "\n  "), 0)
			end
		end)
	end)
end
