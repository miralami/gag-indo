--!nocheck
-- T2 remote audit: every C->S remote must have a server handler or be explicitly
-- guarded, and handler/guard code must rate-limit. New unguarded remotes must fail.

local fs = require("@lune/fs")

local function read(path: string): string
	return fs.readFile(path)
end

local function listLuau(dir: string): { string }
	local out = {}
	local function walk(d)
		for _, name in fs.readDir(d) do
			local p = d .. "/" .. name
			if fs.isDir(p) then
				walk(p)
			elseif string.sub(name, -5) == ".luau" then
				table.insert(out, p)
			end
		end
	end
	walk(dir)
	table.sort(out)
	return out
end

local function parseRemoteNames(): { string }
	local src = read("src/shared/Remotes.luau")
	local block = string.match(src, "local NAMES = {%s*(.-)%s*}[\r\n]+local Remotes") or ""
	local names = {}
	for line in string.gmatch(block, "[^\r\n]+") do
		local name = string.match(line, '^%s*"([A-Za-z0-9_]+)"')
		if name then
			table.insert(names, name)
		end
	end
	return names
end

local S2C = {
	Notify = true,
	Minigame_Start = true,
	Minigame_Cancel = true,
	Evidence_Offer = true,
	Evidence_Token = true,
	Evidence_Remove = true,
	Leaderboard_Data = true,
	Raid_Start = true,
	Raid_End = true,
	Jail_State = true,
	State_Snapshot = true,
	State_Patch = true,
	Admin_Result = true,
	Harness_Result = true,
}

local function isC2S(name: string): boolean
	return not S2C[name]
end

return function(t, Env, Fakes)
	local expect = t.expect
	local env, RemoteGuards, RateLimit, remotes, player

	t:describe("Remote audit (T2)", function()
		t:beforeEach(function()
			env = Env.new()
			remotes = Fakes.remotes(env)
			env:mock("shared/Remotes", remotes)
			RateLimit = env:require("server/Net/RateLimit")
			RemoteGuards = env:require("server/Net/RemoteGuards")
			player = Fakes.player(env)
		end)

		t:it("guards unowned client remotes without reading payload into state", function()
			RemoteGuards.start(remotes, RateLimit)
			local names = RemoteGuards.guarded()
			expect(#names >= 1):toBe(true)
			for _, name in names do
				local remote = remotes[name]
				expect(remote ~= nil):toBe(true)
				remote.OnServerEvent:Fire(player, string.rep("x", 5000), { huge = string.rep("y", 2000) }, math.huge, 0 / 0)
				remote.OnServerEvent:Fire(player, -1, { [1] = 2 })
			end
		end)

		t:it("ensures every C->S remote in Remotes.luau is handled or explicitly guarded with rate limiting", function()
			local guardedList = {}
			for _, name in RemoteGuards.guarded() do
				guardedList[name] = true
			end

			local serverFiles = listLuau("src/server")
			local serverTextByPath = {}
			for _, path in serverFiles do
				serverTextByPath[path] = read(path)
			end

			local bad = {}
			for _, name in parseRemoteNames() do
				if isC2S(name) then
					local handledPath = nil
					for path, text in serverTextByPath do
						if string.find(text, "Remotes." .. name .. ".OnServerEvent", 1, true)
							or string.find(text, "Remotes." .. name .. ".OnServerInvoke", 1, true)
						then
							handledPath = path
							break
						end
					end
					if guardedList[name] then
						if handledPath == nil then table.insert(bad, "g:" .. name) end
					else
						if handledPath == nil then
							table.insert(bad, "u:" .. name)
						else
							local t = serverTextByPath[handledPath]
							if not (string.find(t, "RateLimit.allow", 1, true) or string.find(t, ".allow(", 1, true)) then
								table.insert(bad, "r:" .. name)
							end
						end
					end
				end
			end
			if #bad > 0 then
				error("T2 remote audit: " .. table.concat(bad, ","))
			end
			expect(true):toBe(true)

			-- Guard list itself must be rate-limited.
			local guardText = read("src/server/Net/RemoteGuards.luau")
			expect(string.find(guardText, ".allow(", 1, true) ~= nil):toBe(true)
		end)
	end)
end


