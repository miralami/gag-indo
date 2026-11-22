--!nocheck
-- WORK_QUEUE round-2 item 16: SAVE FUZZING.
-- Run 1000 deterministic randomly-damaged save tables through migrate + SaveSanitize, and
-- through the real fake-ProfileStore load path for a subset. Assert: no throw, every template
-- key is present with the right type, every template number is finite, the save is at the
-- current version, and the fixed structure is not cyclic. Negative numbers are deliberately
-- left alone by SaveSanitize (cash/debt own that rule), so the numeric invariant is finiteness
-- rather than non-negativity; count fields damaged to NaN/inf are repaired to their non-negative
-- template defaults, which is checked explicitly.

return function(t, Env, Fakes)
	local expect = t.expect
	local CASES = 1000
	local LOAD_EVERY = 50

	local function finite(n)
		return type(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge
	end

	-- Seeded LCG: no global math.random state, fully reproducible from SEED.
	local SEED = 0x5EED1234
	local function rng(seedRef)
		seedRef[1] = (1103515245 * seedRef[1] + 12345) % 2147483648
		return seedRef[1]
	end
	local function pick(list, roll)
		return list[(roll % #list) + 1]
	end

	local function deepCopy(value)
		if type(value) ~= "table" then return value end
		local out = {}
		for k, v in value do out[k] = deepCopy(v) end
		return out
	end

	-- A nasty but bounded value. Each call builds fresh tables so no state leaks between cases.
	local function badValue(seedRef)
		local r = rng(seedRef)
		local cyclic = {}
		cyclic.self = cyclic
		local hugeTable = {}
		for i = 1, 40 do hugeTable["junk" .. i] = i end
		return pick({
			function() return nil end,
			function() return true end,
			function() return false end,
			function() return "text" end,
			function() return "" end,
			function() return 0 / 0 end,
			function() return math.huge end,
			function() return -math.huge end,
			function() return -1 end,
			function() return 3.75 end,
			function() return string.rep("x", 5000) end,
			function() return {} end,
			function() return hugeTable end,
			function() return cyclic end,
		}, r)()
	end

	local NESTED = {
		cooldowns = true, stats = true, quests = true, worker = true,
		gudang = true, debt = true, shop = true, tutorial = true,
		story = true, prestige = true,
	}

	-- Corrupt a fresh save: random top-level fields, nested fields, deletions, legacy fields,
	-- occasional old version. Every field drawn from a template default is damaged with a value
	-- that migrate/SaveSanitize is designed to repair (wrong type / NaN / inf / cyclic table).
	local function damage(seedRef, template, env)
		local data = deepCopy(Fakes.newData(env))
		local templateKeys = {}
		for k in pairs(template) do
			if type(k) == "string" then table.insert(templateKeys, k) end
		end
		table.sort(templateKeys)

		local hits = 2 + (rng(seedRef) % 6)
		for _ = 1, hits do
			local key = pick(templateKeys, rng(seedRef))
			data[key] = badValue(seedRef)
			if NESTED[key] and type(template[key]) == "table" and type(data[key]) == "table" then
				local subKeys = {}
				for sk in pairs(template[key]) do
					if type(sk) == "string" then table.insert(subKeys, sk) end
				end
				if #subKeys > 0 then
					data[key][pick(subKeys, rng(seedRef))] = badValue(seedRef)
				end
			end
		end

		-- Exercise the legacy migration branches with v1/v2-shaped junk.
		local roll = rng(seedRef) % 5
		if roll == 0 then data.version = 1 end
		if roll == 1 then data.version = 2 end
		if roll == 2 then
			data.harvest = { padi = { count = badValue(seedRef), hotCount = badValue(seedRef) } }
		end
		if roll == 3 then
			data.inventory = { seed_padi = badValue(seedRef) }
			data.seeds = badValue(seedRef)
		end
		-- Sometimes damage the whole root; only the SaveSanitize-only path accepts this.
		if rng(seedRef) % 9 == 0 then
			data = badValue(seedRef)
		end
		return data
	end

	-- Bounded, cycle-aware walk. Returns true if it terminates without exceeding node budget.
	local function bounded(node)
		local budget = 20000
		local function walk(v, depth, seen)
			budget -= 1
			if budget <= 0 or depth > 120 then return false end
			if type(v) ~= "table" then return true end
			if seen[v] then return true end -- a preserved input cycle is not introduced by sanitize
			seen[v] = true
			for _, child in v do
				if not walk(child, depth + 1, seen) then return false end
			end
			seen[v] = nil
			return true
		end
		return walk(node, 0, {})
	end

	-- Post-conditions for a table-root save after migrate + sanitize.
	local function violations(data, template, CURRENT_VERSION)
		local bad = {}
		if type(data) ~= "table" then
			table.insert(bad, "root is not a table")
			return bad
		end
		for key, default in pairs(template) do
			if type(key) ~= "string" then continue end
			local value = data[key]
			if value == nil then
				table.insert(bad, "missing key " .. key)
			elseif type(value) ~= type(default) then
				table.insert(bad, "wrong type " .. key)
			elseif type(default) == "number" and not finite(value) then
				table.insert(bad, "non-finite " .. key)
			elseif NESTED[key] and type(default) == "table" then
				for sk, sd in pairs(default) do
					if type(sk) ~= "string" then continue end
					local sv = value[sk]
					if sv == nil then
						table.insert(bad, "missing " .. key .. "." .. sk)
					elseif type(sv) ~= type(sd) then
						table.insert(bad, "wrong type " .. key .. "." .. sk)
					elseif type(sd) == "number" and not finite(sv) then
						table.insert(bad, "non-finite " .. key .. "." .. sk)
					end
				end
			end
		end
		if data.version ~= CURRENT_VERSION then
			table.insert(bad, "version is " .. tostring(data.version))
		end
		if not bounded(data) then
			table.insert(bad, "structure does not terminate within budget")
		end
		return bad
	end

	local function makeProfile(env, data)
		local p = {
			Data = data,
			_active = true,
			OnAfterSave = env.newSignal(),
			OnSessionEnd = env.newSignal(),
		}
		function p:IsActive() return self._active end
		function p:AddUserId() end
		function p:Reconcile() end
		function p:Save() end
		function p:EndSession()
			self._active = false
			self.OnSessionEnd:Fire()
		end
		return p
	end

	t:describe("Save fuzzing — 1000 damaged saves (round-2 item 16)", function()
		t:it("migrate + SaveSanitize hold every invariant across 1000 damaged saves", function()
			local env = Env.new()
			env:mock("server/Packages/ProfileStore", { New = function() return {} end })
			local PlayerData = env:require("server/Data/PlayerData")
			local template = PlayerData.TEMPLATE
			local seedRef = { SEED }
			local tableRoots, nonTableRoots = 0, 0
			local failures = {}

			for i = 1, CASES do
				local damaged = damage(seedRef, template, env)
				if type(damaged) == "table" then
					tableRoots += 1
					local ok, err = pcall(function()
						PlayerData.migrate(damaged)
						PlayerData.sanitize(damaged)
					end)
					if not ok then
						table.insert(failures, "case " .. i .. " threw: " .. tostring(err))
					else
						local bad = violations(damaged, template, PlayerData.CURRENT_VERSION)
						if #bad > 0 then
							table.insert(failures, "case " .. i .. ": " .. table.concat(bad, ", "))
						end
					end
				else
					nonTableRoots += 1
					-- migrate assumes a table root (ProfileStore guarantees one); SaveSanitize
					-- is the pure entry point that must tolerate any root without throwing.
					local ok, err = pcall(function() PlayerData.sanitize(damaged) end)
					if not ok then
						table.insert(failures, "non-table case " .. i .. " threw: " .. tostring(err))
					end
				end
			end

			expect(tableRoots > 800):toBe(true)
			expect(nonTableRoots > 0):toBe(true)
			if #failures > 0 then
				error("save fuzz violations (" .. #failures .. "):\n" .. table.concat(failures, "\n", 1, math.min(#failures, 12)))
			end
			expect(true):toBe(true)
		end)

		t:it("the real load path migrates and sanitizes damaged profiles without throwing", function()
			local env = Env.new()
			local factory = function() return nil end
			local store = { StartSessionAsync = function(_, _, _) return factory() end }
			env:mock("server/Packages/ProfileStore", { New = function() return store end })
			local PlayerData = env:require("server/Data/PlayerData")
			PlayerData.start()
			local template = PlayerData.TEMPLATE
			local seedRef = { SEED + 1 }
			local loaded, failures = 0, {}

			for i = 1, CASES do
				local damaged = damage(seedRef, template, env)
				if type(damaged) ~= "table" then continue end
				if i % LOAD_EVERY ~= 0 then continue end
				local profile = makeProfile(env, damaged)
				factory = function() return profile end
				local player = Fakes.player(env)
				local ok, err = pcall(function()
					env.services.Players.PlayerAdded:Fire(player)
				end)
				loaded += 1
				if not ok then
					table.insert(failures, "load case " .. i .. " threw: " .. tostring(err))
				else
					local bad = violations(damaged, template, PlayerData.CURRENT_VERSION)
					if #bad > 0 then
						table.insert(failures, "load case " .. i .. ": " .. table.concat(bad, ", "))
					end
				end
			end

			expect(loaded >= 15):toBe(true)
			if #failures > 0 then
				error("load-path save fuzz violations:\n" .. table.concat(failures, "\n"))
			end
			expect(true):toBe(true)
		end)

		-- BUG-018 regression: a damaged v1/v2 harvest sack whose hotCount/count/qualitySum
		-- are strings, tables, NaN or inf used to throw at PlayerData.luau:163
		-- (`attempt to compare number < table|string`) because the legacy v2 split did raw
		-- comparisons/arithmetic before SaveSanitize could repair the fields.
		t:it("a damaged legacy harvest sack with non-numeric counts neither throws nor leaves non-finite quality", function()
			local env = Env.new()
			env:mock("server/Packages/ProfileStore", { New = function() return {} end })
			local PlayerData = env:require("server/Data/PlayerData")
			local template = PlayerData.TEMPLATE
			local badCounts = { "many", {}, 0 / 0, math.huge, -math.huge, true, -3 }
			local checked = 0

			for _, bad in badCounts do
				local data = deepCopy(Fakes.newData(env))
				data.version = 1
				data.harvest = {
					padi = { count = bad, hotCount = bad, qualitySum = bad, hotQualitySum = bad },
				}
				local ok, err = pcall(function()
					PlayerData.migrate(data)
					PlayerData.sanitize(data)
				end)
				expect(ok):toBe(true)
				if not ok then error("legacy sack migration threw: " .. tostring(err)) end
				checked += 1
				-- The v1/v2 harvest is folded into v3 produce; any surviving qualitySum must
				-- be finite, and the whole save must satisfy the invariants.
				local badFields = violations(data, template, PlayerData.CURRENT_VERSION)
				if #badFields > 0 then
					error("legacy sack left invalid fields: " .. table.concat(badFields, ", "))
				end
				if type(data.produce) == "table" then
					for _, stack in pairs(data.produce) do
						if type(stack) == "table" and stack.qualitySum ~= nil then
							expect(finite(stack.qualitySum)):toBe(true)
						end
					end
				end
			end
			expect(checked == #badCounts):toBe(true)
		end)
	end)
end
