--!nocheck
-- Cross-references between config tables. config_spec checks each table on its own; this file checks
-- that the ids one table names in another (crops, tiers, traits, seasons, cosmetics, strings, grants)
-- really exist, and that the numbers that look like prices, times and counts are sane.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect

	-- Config modules that name each other's ids. Read by path so the walkers below see every table.
	local CONFIG_MODULES = {
		"Almanak", "Badges", "Cheats", "Cosmetics", "Crops", "FirstSession", "Game", "Law", "Market",
		"Onboarding", "Pinjol", "Products", "Quests", "Seasons", "Shop", "Tiers", "Tools", "Traits",
		"Worker", "WorldConstants",
	}

	-- Consumables a Products or Quests grant may name as an inventory item.
	local CONSUMABLES = { amplopPremium = true, jaminanKilat = true }

	local env, Crops, Seasons, Tiers, Traits, Cosmetics, Strings, Products, Quests, Tools, Game

	local function sortedKeys(map)
		local keys = {}
		for key in map do
			table.insert(keys, key)
		end
		table.sort(keys, function(a, b)
			return tostring(a) < tostring(b)
		end)
		return keys
	end

	local function setOf(list)
		local out = {}
		for _, value in list do
			out[value] = true
		end
		return out
	end

	local function isCrop(cropId)
		return type(cropId) == "string" and Crops.list[cropId] ~= nil
	end

	local function isFinite(value)
		return type(value) == "number" and value == value and math.abs(value) < math.huge
	end

	-- Joins a list of problem strings so a failure shows every bad entry, not just the first.
	local function report(problems)
		return table.concat(problems, "; ")
	end

	t:describe("Config cross references", function()
		t:beforeEach(function()
			env = Env.new()
			Crops = env:require("shared/Config/Crops")
			Seasons = env:require("shared/Config/Seasons")
			Tiers = env:require("shared/Config/Tiers")
			Traits = env:require("shared/Config/Traits")
			Cosmetics = env:require("shared/Config/Cosmetics")
			Products = env:require("shared/Config/Products")
			Quests = env:require("shared/Config/Quests")
			Tools = env:require("shared/Config/Tools")
			Game = env:require("shared/Config/Game")
			Strings = env:require("shared/Strings")
		end)

		t:describe("crop references", function()
			t:it("points every Shop crop and family at a real crop or family", function()
				local Shop = env:require("shared/Config/Shop")
				local problems = {}
				for _, musim in sortedKeys(Shop.chanceBySeason) do
					if not Seasons.isMusim(musim) then
						table.insert(problems, "chanceBySeason musim " .. musim)
					end
					for family in Shop.chanceBySeason[musim] do
						if Crops.families[family] == nil then
							table.insert(problems, "chanceBySeason." .. musim .. " family " .. family)
						end
					end
				end
				for cropId in Shop.rareChance do
					if not isCrop(cropId) then
						table.insert(problems, "rareChance crop " .. cropId)
					end
				end
				for family in Shop.familyAmount do
					if Crops.families[family] == nil then
						table.insert(problems, "familyAmount family " .. family)
					end
				end
				for cropId in Shop.always do
					if not isCrop(cropId) then
						table.insert(problems, "always crop " .. cropId)
					end
				end
				expect(report(problems)):toBe("")
			end)

			t:it("keeps Shop chances in [0, 1] and amounts ordered", function()
				local Shop = env:require("shared/Config/Shop")
				local problems = {}
				for musim, families in Shop.chanceBySeason do
					for family, chance in families do
						if not (isFinite(chance) and chance >= 0 and chance <= 1) then
							table.insert(problems, "chanceBySeason." .. musim .. "." .. family .. "=" .. tostring(chance))
						end
					end
				end
				for cropId, chance in Shop.rareChance do
					if not (isFinite(chance) and chance >= 0 and chance <= 1) then
						table.insert(problems, "rareChance." .. cropId .. "=" .. tostring(chance))
					end
				end
				if Shop.amountMin > Shop.amountMax then
					table.insert(problems, "amountMin above amountMax")
				end
				expect(report(problems)):toBe("")
			end)

			t:it("only lists Almanak family pages that are real crop families", function()
				local Almanak = env:require("shared/Config/Almanak")
				local problems = {}
				for pageId, page in Almanak.pages do
					if Crops.families[page.family] == nil then
						table.insert(problems, "page " .. pageId .. " family " .. tostring(page.family))
					end
					if Cosmetics.list[page.reward] == nil then
						table.insert(problems, "page " .. pageId .. " reward " .. tostring(page.reward))
					end
				end
				expect(report(problems)):toBe("")
			end)

			t:it("only names real crops in Quests (task targets and login seeds)", function()
				local problems = {}
				for _, task in Quests.taskPool do
					if task.crop ~= nil and not isCrop(task.crop) then
						table.insert(problems, "task " .. task.id .. " crop " .. task.crop)
					end
				end
				for index, reward in Quests.loginRewards do
					if reward.type == "seeds" and not isCrop(reward.crop) then
						table.insert(problems, "loginRewards[" .. index .. "] crop " .. tostring(reward.crop))
					end
				end
				expect(report(problems)):toBe("")
			end)

			t:it("gives the first-session guard a real crop and real tiers", function()
				local FirstSession = env:require("shared/Config/FirstSession")
				local problems = {}
				if not isCrop("padi") then
					table.insert(problems, "padi missing from Crops.list")
				end
				for harvest, tierId in FirstSession.guaranteedTiers do
					if not Tiers.exists(tierId) then
						table.insert(problems, "guaranteedTiers[" .. tostring(harvest) .. "] " .. tostring(tierId))
					end
				end
				expect(report(problems)):toBe("")
			end)

			t:it("only starts the player with seeds for real crops", function()
				for cropId in Game.startSeeds do
					expect(isCrop(cropId)):toBe(true)
				end
			end)
		end)

		t:describe("season references", function()
			t:it("keys every growth family override by a real family", function()
				local problems = {}
				for musim, season in Seasons.list do
					for family in season.growthByFamily or {} do
						if Crops.families[family] == nil then
							table.insert(problems, musim .. ".growthByFamily " .. family)
						end
					end
				end
				expect(report(problems)):toBe("")
			end)

			t:it("gives every season a sky preset and every sky preset a season", function()
				local problems = {}
				for musim in Seasons.list do
					if Seasons.sky[musim] == nil then
						table.insert(problems, "no sky for " .. musim)
					end
				end
				for musim in Seasons.sky do
					if Seasons.list[musim] == nil then
						table.insert(problems, "sky for unknown " .. musim)
					end
				end
				expect(report(problems)):toBe("")
			end)

			t:it("keeps the musim order in step with the season list", function()
				local WorldConstants = env:require("shared/Config/WorldConstants")
				local problems = {}
				for _, musim in WorldConstants.SEASON_PRESETS do
					if Seasons.list[musim] == nil then
						table.insert(problems, "SEASON_PRESETS " .. musim)
					end
				end
				expect(#WorldConstants.SEASON_PRESETS):toBe(#sortedKeys(Seasons.list))
				expect(report(problems)):toBe("")
			end)

			t:it("only uses known weather in weights and overlays", function()
				local known = setOf(Seasons.cuacaOrder)
				local problems = {}
				for musim, weights in Seasons.weatherWeights do
					if Seasons.list[musim] == nil then
						table.insert(problems, "weatherWeights musim " .. musim)
					end
					for cuaca in weights do
						if not known[cuaca] then
							table.insert(problems, "weatherWeights." .. musim .. " cuaca " .. cuaca)
						end
					end
				end
				for cuaca in Seasons.cuacaSky do
					if not known[cuaca] then
						table.insert(problems, "cuacaSky " .. cuaca)
					end
				end
				expect(report(problems)):toBe("")
			end)

			t:it("labels every season with a real string", function()
				local problems = {}
				for musim, season in Seasons.list do
					local entry = Strings.raw[season.labelKey]
					if type(entry) ~= "table" or type(entry.id) ~= "string" or type(entry.en) ~= "string" then
						table.insert(problems, musim .. " labelKey " .. tostring(season.labelKey))
					end
				end
				expect(report(problems)):toBe("")
			end)
		end)

		t:describe("tier and trait references", function()
			t:it("names only tiers that exist in the tier table", function()
				expect(Tiers.exists(Tiers.default)):toBe(true)
				expect(Tiers.exists(Tiers.rareFrom)):toBe(true)
				local problems = {}
				for _, tierId in Tiers.order do
					if not Tiers.exists(tierId) then
						table.insert(problems, "order " .. tostring(tierId))
					end
				end
				expect(report(problems)):toBe("")
			end)

			t:it("has a hot trait that exists", function()
				expect(Traits.exists(Traits.hotTrait)):toBe(true)
				expect(Traits.isHot(Traits.hotTrait)):toBe(true)
			end)

			t:it("uses only known trait conditions, each with a chance in (0, 1]", function()
				local conditions = { rain = true, elNino = true, unfertilised = true, certified = true }
				local problems = {}
				for traitId, trait in Traits.list do
					if trait.condition ~= nil then
						if not conditions[trait.condition] then
							table.insert(problems, traitId .. " condition " .. tostring(trait.condition))
						end
						if not (isFinite(trait.chance) and trait.chance > 0 and trait.chance <= 1) then
							table.insert(problems, traitId .. " chance " .. tostring(trait.chance))
						end
					end
				end
				expect(report(problems)):toBe("")
			end)

			t:it("points every trait and tier at a label string with id and en", function()
				local problems = {}
				local function check(owner, key)
					local entry = Strings.raw[key]
					if type(entry) ~= "table" or type(entry.id) ~= "string" or entry.id == "" or type(entry.en) ~= "string" or entry.en == "" then
						table.insert(problems, owner .. " -> " .. tostring(key))
					end
				end
				for traitId, trait in Traits.list do
					check("trait " .. traitId, trait.labelKey)
				end
				for tierId, tier in Tiers.list do
					check("tier " .. tierId, tier.labelKey)
				end
				expect(report(problems)):toBe("")
			end)
		end)

		t:describe("grants and products", function()
			t:it("grants only the types Receipts.luau handles", function()
				local source = fs.readFile("src/server/Monetization/Receipts.luau")
				local handled = {}
				for grant in string.gmatch(source, 'product%.grant == "(%w+)"') do
					handled[grant] = true
				end
				local known = { "inventory", "seeds", "restock", "cash" }
				local problems = {}
				for _, grant in known do
					if not handled[grant] then
						table.insert(problems, "Receipts does not handle " .. grant)
					end
				end
				for key, product in Products.products do
					if not handled[product.grant] then
						table.insert(problems, "product " .. key .. " grant " .. tostring(product.grant))
					end
				end
				expect(report(problems)):toBe("")
			end)

			t:it("grants only consumables or seeds for real crops as inventory and seeds", function()
				local problems = {}
				for key, product in Products.products do
					if product.grant == "inventory" and not CONSUMABLES[product.item] then
						table.insert(problems, key .. " item " .. tostring(product.item))
					end
					if product.grant == "seeds" then
						for cropId, amount in product.seeds do
							if not isCrop(cropId) then
								table.insert(problems, key .. " seeds crop " .. cropId)
							end
							if not (isFinite(amount) and amount > 0 and math.floor(amount) == amount) then
								table.insert(problems, key .. " seeds amount " .. tostring(amount))
							end
						end
					end
				end
				for index, reward in Quests.loginRewards do
					if reward.type == "item" and not CONSUMABLES[reward.item] then
						table.insert(problems, "loginRewards[" .. index .. "] item " .. tostring(reward.item))
					end
				end
				expect(report(problems)):toBe("")
			end)

			t:it("keeps every product id and pass id unique when set", function()
				local problems = {}
				local seen = {}
				for key, product in Products.products do
					if product.id ~= 0 then
						if seen[product.id] then
							table.insert(problems, key .. " shares id with " .. seen[product.id])
						end
						seen[product.id] = key
					end
				end
				seen = {}
				for key, pass in Products.passes do
					if pass.id ~= 0 then
						if seen[pass.id] then
							table.insert(problems, "pass " .. key .. " shares id with " .. seen[pass.id])
						end
						seen[pass.id] = key
					end
				end
				expect(report(problems)):toBe("")
			end)

			t:it("keeps every product and pass id a non-negative whole number", function()
				local problems = {}
				for key, product in Products.products do
					if not (isFinite(product.id) and product.id >= 0 and math.floor(product.id) == product.id) then
						table.insert(problems, "product " .. key .. " id " .. tostring(product.id))
					end
				end
				for key, pass in Products.passes do
					if not (isFinite(pass.id) and pass.id >= 0 and math.floor(pass.id) == pass.id) then
						table.insert(problems, "pass " .. key .. " id " .. tostring(pass.id))
					end
				end
				expect(report(problems)):toBe("")
			end)

			t:it("keeps Badge and cosmetic ids numeric (0 means unset)", function()
				local Badges = env:require("shared/Config/Badges")
				local problems = {}
				for key, badge in Badges.list do
					if not (isFinite(badge.id) and badge.id >= 0) then
						table.insert(problems, "badge " .. key .. " id " .. tostring(badge.id))
					end
				end
				expect(report(problems)):toBe("")
			end)

			t:it("keeps Cosmetics order and list in step with unique keys", function()
				local problems = {}
				local seen = {}
				for _, cosmeticId in Cosmetics.order do
					if seen[cosmeticId] then
						table.insert(problems, "order repeats " .. cosmeticId)
					end
					seen[cosmeticId] = true
					if Cosmetics.list[cosmeticId] == nil then
						table.insert(problems, "order names missing " .. cosmeticId)
					end
				end
				for cosmeticId in Cosmetics.list do
					if not seen[cosmeticId] then
						table.insert(problems, "list item not in order " .. cosmeticId)
					end
				end
				expect(report(problems)):toBe("")
			end)
		end)

		t:describe("tools", function()
			t:it("sets strictly increasing costs and valid next links on every line", function()
				local problems = {}
				for _, lineId in Tools.order do
					local line = Tools.list[lineId]
					if line == nil then
						table.insert(problems, "order names missing " .. lineId)
						continue
					end
					if Game.rankIndex[line.rank] == nil then
						table.insert(problems, lineId .. " rank " .. tostring(line.rank))
					end
					local previousCost = 0
					local seen = {}
					for index, tier in line.tiers do
						if seen[tier.id] then
							table.insert(problems, lineId .. " repeats tier " .. tostring(tier.id))
						end
						seen[tier.id] = true
						if not (isFinite(tier.cost) and tier.cost > previousCost) then
							table.insert(problems, lineId .. "." .. tostring(tier.id) .. " cost " .. tostring(tier.cost))
						end
						previousCost = if isFinite(tier.cost) then tier.cost else previousCost
						local following = line.tiers[index + 1]
						local nextTier = Tools.next(lineId, tier.id)
						if following == nil then
							if nextTier ~= nil then
								table.insert(problems, lineId .. " maxed tier " .. tostring(tier.id) .. " has a next")
							end
						elseif nextTier == nil or nextTier.id ~= following.id then
							table.insert(problems, lineId .. " next of " .. tostring(tier.id) .. " is wrong")
						end
					end
					if line.tiers[1] ~= nil and Tools.next(lineId, nil).id ~= line.tiers[1].id then
						table.insert(problems, lineId .. " first buy is not the first tier")
					end
					if Strings.raw[line.label] == nil then
						table.insert(problems, lineId .. " label " .. tostring(line.label))
					end
				end
				expect(report(problems)):toBe("")
			end)

			t:it("keeps Tools.order and Tools.list in step", function()
				local count = 0
				for _ in Tools.list do
					count += 1
				end
				expect(count):toBe(#Tools.order)
			end)
		end)

		t:describe("labels referenced by config", function()
			t:it("points every Quests, Cheats and Tools label at a string with id and en", function()
				local Cheats = env:require("shared/Config/Cheats")
				local problems = {}
				local function check(owner, key)
					local entry = Strings.raw[key]
					if type(entry) ~= "table" or type(entry.id) ~= "string" or entry.id == "" or type(entry.en) ~= "string" or entry.en == "" then
						table.insert(problems, owner .. " -> " .. tostring(key))
					end
				end
				for _, task in Quests.taskPool do
					check("task " .. task.id, task.labelKey)
				end
				for cheatId, cheat in Cheats.list do
					check("cheat " .. cheatId, cheat.label)
				end
				for lineId, line in Tools.list do
					check("tool " .. lineId, line.label)
				end
				expect(report(problems)):toBe("")
			end)
		end)

		t:describe("numbers that look like prices, times and counts", function()
			-- Keys whose numeric value is a price, time, count, chance or size. Matched on the key
			-- or any ancestor key, so `baseLimitByRank.gurem` and `seeds.padi` are covered too.
			local VALUE_KEY_PATTERNS = {
				"[Cc]ost", "[Pp]rice", "[Ss]econds$", "[Dd]elay", "[Dd]uration", "[Ii]nterval", "[Cc]ooldown",
				"[Aa]mount", "[Tt]arget", "[Cc]ash", "[Ww]age", "[Ff]ee", "[Hh]arvests", "[Cc]hance",
				"[Ll]imit", "[Cc]apacity", "[Mm]in", "[Mm]ax", "[Ss]eeds", "^sack$", "[Cc]ount$", "[Ss]ize",
				"[Dd]ays$", "^tilesOwned", "^lifetimeEarned", "[Mm]ultiplier", "[Ss]tack",
			}

			local function matches(key)
				if type(key) ~= "string" then
					return false
				end
				for _, pattern in VALUE_KEY_PATTERNS do
					if string.find(key, pattern) then
						return true
					end
				end
				return false
			end

			-- Collects numeric leaves under a matching key. Returns a list of { path, value }.
			local function collect(value, path, out, seen, matchedAbove)
				if type(value) ~= "table" then
					return
				end
				if seen[value] then
					return
				end
				seen[value] = true
				for key, child in value do
					local childPath = path .. "." .. tostring(key)
					local matched = matchedAbove or matches(key)
					if type(child) == "number" then
						if matched then
							table.insert(out, { path = childPath, value = child })
						end
					elseif type(child) == "table" then
						collect(child, childPath, out, seen, matched)
					end
				end
			end

			t:it("keeps every price, time and count finite and non-negative", function()
				local problems = {}
				local checked = 0
				for _, name in CONFIG_MODULES do
					local module = env:require("shared/Config/" .. name)
					local found = {}
					collect(module, name, found, {}, false)
					for _, entry in found do
						checked += 1
						-- Negative values here are intentional deltas, not prices: skip the Law Sus
						-- and sky overlay values, which the patterns above do not reach.
						if not isFinite(entry.value) or entry.value < 0 then
							table.insert(problems, entry.path .. "=" .. tostring(entry.value))
						end
					end
				end
				expect(checked > 0):toBe(true)
				expect(report(problems)):toBe("")
			end)

			t:it("keeps Quests daily picks inside the pool", function()
				local ids = {}
				for _, task in Quests.taskPool do
					ids[task.id] = true
				end
				local problems = {}
				for dayNum = 1, 60 do
					local picked = Quests.rollDailyTasks(dayNum)
					local count = 0
					for id, task in picked do
						count += 1
						if not ids[id] or task.id ~= id then
							table.insert(problems, "day " .. dayNum .. " picked " .. tostring(id))
						end
					end
					if count ~= Quests.DAILY_TASK_COUNT then
						table.insert(problems, "day " .. dayNum .. " picked " .. count)
					end
				end
				expect(report(problems)):toBe("")
			end)

			t:it("keeps login rewards to one entry per streak day, with a positive amount", function()
				expect(#Quests.loginRewards):toBe(Quests.LOGIN_STREAK_DAYS)
				local problems = {}
				for index, reward in Quests.loginRewards do
					if not (isFinite(reward.amount) and reward.amount > 0) then
						table.insert(problems, "day " .. index .. " amount " .. tostring(reward.amount))
					end
				end
				expect(report(problems)):toBe("")
			end)
		end)
	end)
end
