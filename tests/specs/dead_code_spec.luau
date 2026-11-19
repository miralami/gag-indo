--!nocheck
-- WORK_QUEUE item 25 (dead code / dead strings): characterization of the cleanup.
--
-- Proves the removal is real and stays removed:
--  * every Strings key deleted in item 25 is absent from Strings.raw;
--  * no Strings key is now unreferenced in src/ (reverse dead-key scan, prefix-aware);
--  * the longer lookalike keys that share a prefix with a deleted key are still present;
--  * every function deleted in item 25 is no longer defined in its module;
--  * every $path mapping in default.project.json points to a path that exists.
--
-- The reverse scan deliberately counts a key as referenced when its exact literal appears in
-- src/ OR tests/, or when it starts with a dynamic-concatenation prefix found in src/. This is
-- the same rule used to find the original 22 dead keys; the empty prefix from `"@" .. label`
-- is excluded so it cannot mask every key.

local fs = require("@lune/fs")

local REMOVED_KEYS = {
	"admin_button", "admin_event", "admin_no_access",
	"family_kebun", "family_palawija", "family_perkebunan",
	"hud_cheat", "hud_event_cabai", "hud_harvest_bag",
	"hud_namabaik", "hud_rank", "hud_shop_button", "hud_sus",
	"lb_button",
	"phone_home", "phone_namabaik", "phone_rank",
	"phone_steal", "phone_sus", "phone_water",
	"raid_jail_btn", "shop_rank_badge",
}

-- Deleted keys whose exact name is a prefix of a LIVE key. These must survive.
local KEPT_LOOKALIKES = {
	"hud_event_cabai_on", "hud_event_cabai_left",
	"phone_steal_short", "phone_water_short",
	"crop_padi", "hud_seed_count", -- ordinary live keys, scanner sanity
}

-- module, function, defining file
local REMOVED_FUNCTIONS = {
	{ "Village", "getWorld", "src/server/World/Village.luau" },
	{ "State", "touchAll", "src/server/Net/State.luau" },
	{ "Crops", "isRegrow", "src/shared/Config/Crops.luau" },
	{ "MarketService", "pressure", "src/server/Economy/MarketService.luau" },
	{ "FarmService", "hasGrowing", "src/server/Farm/FarmService.luau" },
}

local function listLuau(dir, out)
	for _, entry in fs.readDir(dir) do
		local full = dir .. "/" .. entry
		if fs.isDir(full) then
			listLuau(full, out)
		elseif string.match(entry, "%.luau$") then
			table.insert(out, full)
		end
	end
	return out
end

local function sorted(list)
	table.sort(list)
	return list
end

return function(t, Env)
	local expect = t.expect
	local probe = Env.new()
	local Strings = probe:require("shared/Strings")
	local S = Strings.raw

	t:describe("item 25: dead Strings keys removed", function()
		for _, key in REMOVED_KEYS do
			t:it(`"{key}" is absent from Strings.raw`, function()
				expect(S[key]):toBeNil()
			end)
		end
		for _, key in KEPT_LOOKALIKES do
			t:it(`lookalike "{key}" is still defined`, function()
				expect(S[key] ~= nil):toBeTruthy()
			end)
		end
	end)

	t:describe("item 25: no unreferenced Strings key remains", function()
		-- Build the reference corpus from src/ (excluding Strings.luau itself) and tests/.
		local corpus = {}
		for _, path in listLuau("src", {}) do
			if not string.match(path, "shared/Strings%.luau$") then
				table.insert(corpus, fs.readFile(path))
			end
		end
		for _, path in listLuau("tests", {}) do
			table.insert(corpus, fs.readFile(path))
		end
		local ALL = table.concat(corpus, "\n")

		local function hasLiteral(key)
			return string.find(ALL, "\"" .. key .. "\"", 1, true) ~= nil
				or string.find(ALL, "'" .. key .. "'", 1, true) ~= nil
		end

		-- Dynamic prefixes from `"lit" ..` / `"@lit" ..` concatenations in src/.
		local prefixes = {}
		for _, path in listLuau("src", {}) do
			local src = fs.readFile(path)
			for lit in string.gmatch(src, "\"([%w_]+)\"%s*%.%.") do
				if lit ~= "" then prefixes[lit] = true end
			end
			for lit in string.gmatch(src, "\"@([%w_]+)\"%s*%.%.") do
				if lit ~= "" then prefixes[lit] = true end
			end
		end

		local dead = {}
		for key in S do
			local referenced = hasLiteral(key)
			if not referenced then
				for p in prefixes do
					if #key > #p and string.sub(key, 1, #p) == p then
						referenced = true
						break
					end
				end
			end
			if not referenced then table.insert(dead, key) end
		end

		t:it("every Strings key has a src/ or tests/ reference (or a dynamic prefix)", function()
			expect("unreferenced keys: " .. table.concat(sorted(dead), ", ")):toBe("unreferenced keys: ")
		end)
		t:it("the table still has a non-trivial number of keys (scanner sanity)", function()
			local n = 0
			for _ in S do n += 1 end
			expect(n):toBeAtLeast(100)
		end)
	end)

	t:describe("item 25: dead functions removed", function()
		for _, row in REMOVED_FUNCTIONS do
			local mod, fn, path = row[1], row[2], row[3]
			t:it(`${mod}.{fn} is no longer defined in {path}`, function()
				local src = fs.readFile(path)
				local punct = "." -- plain-mode find: no Lua pattern escapes
				local gone = string.find(src, "function " .. mod .. punct .. fn .. "(", 1, true) == nil
					and string.find(src, mod .. punct .. fn .. " = function", 1, true) == nil
				expect(gone):toBeTruthy()
			end)
		end
		t:it("scanner would catch a live definition (sanity)", function()
			local src = fs.readFile("src/server/Economy/MarketService.luau")
			expect(string.find(src, "function MarketService.multiplier(", 1, true) ~= nil):toBeTruthy()
		end)
	end)

	t:describe("item 25: Rojo mappings resolve", function()
		local project = fs.readFile("default.project.json")
		local mappings = {}
		for path in string.gmatch(project, "\"%$path\"%s*:%s*\"([^\"]+)\"") do
			table.insert(mappings, path)
		end
		t:it("declares at least one $path mapping (scanner sanity)", function()
			expect(#mappings):toBeAtLeast(1)
		end)
		for _, path in mappings do
			t:it(`$path "{path}" exists on disk`, function()
				expect(fs.isDir(path) or fs.isFile(path)):toBeTruthy()
			end)
		end
	end)
end
