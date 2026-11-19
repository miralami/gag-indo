--!nocheck
-- WORK_QUEUE item 9: look-dev candidates for designer review. These candidates are recorded as
-- "candidate, awaiting designer yes" and are OFF by default. This spec locks the gate, the two
-- candidate plans, the built-in-material/asset-ID guard, and the thin-adapter wiring. It never
-- marks a candidate approved: that is the designer's decision.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect

	local function fresh()
		return Env.new():require("shared/LookDev")
	end

	t:describe("LookDev candidates (candidate, awaiting designer yes)", function()
		t:it("ships three candidates, all unapproved and cartoonish-realism", function()
			local LookDev = fresh()
			expect(#LookDev.IDS):toBe(3)
			expect(LookDev.IDS[1]):toBe("plaza_lighting")
			expect(LookDev.IDS[2]):toBe("police_walkin")
			expect(LookDev.IDS[3]):toBe("icons")
			for _, id in LookDev.IDS do
				local c = LookDev.candidates[id]
				expect(c.id):toBe(id)
				expect(c.status):toBe("candidate, awaiting designer yes")
				expect(c.style):toBe("cartoonish-realism")
				expect(type(c.title)):toBe("string")
			end
		end)

		t:it("contains no asset IDs in the registry or any adapter", function()
			for _, path in {
				"src/shared/LookDev.luau",
				"src/client/World/LookDevPlaza.luau",
				"src/server/World/LookDevWalkin.luau",
				"src/client/UI/LookDevIcons.luau",
			} do
				local src = fs.readFile(path)
				expect(string.find(src, "rbxasset", 1, true) ~= nil):toBe(false)
				expect(string.find(src, "assetId", 1, true) ~= nil):toBe(false)
				-- A 7+ digit literal is the shape of a Roblox asset/product ID.
				expect(string.find(src, "%d%d%d%d%d%d%d") ~= nil):toBe(false)
			end
		end)

		t:it("every plaza material is a built-in Enum.Material name", function()
			local LookDev = fresh()
			for category, name in LookDev.candidates.plaza_lighting.materials do
				expect(LookDev.isBuiltinMaterial(name)):toBe(true)
			end
			expect(LookDev.isBuiltinMaterial("Sandstone")):toBe(true)
			expect(LookDev.isBuiltinMaterial("NotAMaterial")):toBe(false)
			expect(LookDev.isBuiltinMaterial(nil)):toBe(false)
		end)
	end)

	t:describe("LookDev opt-in gate", function()
		t:it("is off by default and refuses non-Studio callers", function()
			local LookDev = fresh()
			expect(LookDev.current()):toBe(nil)
			expect(LookDev.canEnable(nil)):toBe(false)
			expect(LookDev.canEnable({})):toBe(false)
			expect(LookDev.canEnable({ studio = 1 })):toBe(false)
			expect(LookDev.canEnable({ studio = "true" })):toBe(false)
			expect(LookDev.canEnable({ studio = false })):toBe(false)
			expect(LookDev.canEnable({ studio = true })):toBe(true)
		end)

		t:it("enable refuses an unknown candidate even in Studio", function()
			local LookDev = fresh()
			local ok, why = LookDev.enable("nope", { studio = true })
			expect(ok):toBe(false)
			expect(why):toBe("unknown candidate")
			expect(LookDev.current()):toBe(nil)
		end)

		t:it("enable/disable round-trips and only one candidate is active", function()
			local LookDev = fresh()
			expect(LookDev.enable("plaza_lighting", { studio = true })):toBe(true)
			expect(LookDev.current()):toBe("plaza_lighting")
			expect(LookDev.enable("plaza_lighting", { studio = true })):toBe(true)
			expect(LookDev.disable()):toBe(true)
			expect(LookDev.current()):toBe(nil)
			expect(LookDev.disable()):toBe(false) -- idempotent
			expect(LookDev.enable("police_walkin", { studio = true })):toBe(true)
			expect(LookDev.current()):toBe("police_walkin")
			LookDev.disable()
		end)

		t:it("registered appliers run with the plan and restore on disable", function()
			local LookDev = fresh()
			local applied, restored = nil, 0
			LookDev.register("plaza_lighting", {
				apply = function(plan) applied = plan end,
				restore = function() restored += 1 end,
			})
			expect(LookDev.hasApplier("plaza_lighting")):toBe(true)
			expect(LookDev.enable("plaza_lighting", { studio = true })):toBe(true)
			expect(applied.id):toBe("plaza_lighting")
			expect(LookDev.disable()):toBe(true)
			expect(restored):toBe(1)
		end)

		t:it("a throwing applier is contained and enable reports the failure", function()
			local LookDev = fresh()
			LookDev.register("plaza_lighting", {
				apply = function() error("boom") end,
				restore = function() end,
			})
			local ok, why = LookDev.enable("plaza_lighting", { studio = true })
			expect(ok):toBe(false)
			expect(string.find(why or "", "boom", 1, true) ~= nil):toBe(true)
			expect(LookDev.disable()):toBe(true) -- still enabled, restore is pcall-safe
		end)

		t:it("only well-formed appliers register", function()
			local LookDev = fresh()
			LookDev.register("plaza_lighting", { apply = function() end })
			expect(LookDev.hasApplier("plaza_lighting")):toBe(false)
			LookDev.register("unknown", { apply = function() end, restore = function() end })
			expect(LookDev.hasApplier("unknown")):toBe(false)
		end)
	end)

	t:describe("LookDev plans", function()
		t:it("plaza plan carries the hub, material map and lighting grade", function()
			local LookDev = fresh()
			local plan = LookDev.plan("plaza_lighting")
			expect(plan.id):toBe("plaza_lighting")
			expect(plan.hub):toBe("pasar")
			expect(plan.materials.ground):toBe("Sandstone")
			expect(plan.lighting.clockTime):toBe(11.4)
			expect(#plan.lighting.fogColor):toBe(3)
			expect(LookDev.plan("unknown")):toBe(nil)
		end)

		t:it("walk-in plan is timed to the real walkin shot and aims at the road anchor", function()
			local LookDev = fresh()
			local RaidCutscene = Env.new():require("shared/Config/RaidCutscene")
			local shotDuration = 1.8
			for _, shot in RaidCutscene.shots do
				if shot.id == "walkin" then
					shotDuration = shot.duration
				end
			end
			local plan = LookDev.plan("police_walkin")
			expect(plan.id):toBe("police_walkin")
			expect(plan.npc):toBe("polisi")
			expect(plan.shotId):toBe("walkin")
			expect(plan.duration):toBe(shotDuration)
			local anchor = RaidCutscene.anchorFor("road")
			expect(plan.anchor.x):toBe(anchor.x)
			expect(plan.anchor.z):toBe(anchor.z)
			expect(plan.speed > 0):toBe(true)
			-- distance / duration, so the walk lands exactly when the shot ends.
			local ox, oz = -34, -16
			expect(math.abs(plan.speed - math.sqrt(ox * ox + oz * oz) / shotDuration)):toBeLessThan(0.0001)
		end)

		t:it("icons plan points at the IconMap data source and never embeds IDs", function()
			local LookDev = fresh()
			local plan = LookDev.plan("icons")
			expect(plan.id):toBe("icons")
			expect(plan.idsSource):toBe("Shared.IconMap.candidateIds")
			expect(type(plan.render)):toBe("string")
		end)
	end)

	t:describe("LookDev adapter wiring", function()
		t:it("all three thin adapters register with the shared toggle", function()
			local plaza = fs.readFile("src/client/World/LookDevPlaza.luau")
			local walkin = fs.readFile("src/server/World/LookDevWalkin.luau")
			local icons = fs.readFile("src/client/UI/LookDevIcons.luau")
			expect(string.find(plaza, "LookDev.register(\"plaza_lighting\"", 1, true) ~= nil):toBe(true)
			expect(string.find(walkin, "LookDev.register(\"police_walkin\"", 1, true) ~= nil):toBe(true)
			expect(string.find(icons, "LookDev.register(\"icons\"", 1, true) ~= nil):toBe(true)
		end)

		t:it("icons applier toggles IconMap candidate ids and restores fallbacks", function()
			local icons = fs.readFile("src/client/UI/LookDevIcons.luau")
			expect(string.find(icons, "IconMap.applyCandidates(Visuals, true)", 1, true) ~= nil):toBe(true)
			expect(string.find(icons, "IconMap.applyCandidates(Visuals, false)", 1, true) ~= nil):toBe(true)
		end)

		t:it("plaza applier uses built-in Enum.Material only", function()
			local plaza = fs.readFile("src/client/World/LookDevPlaza.luau")
			expect(string.find(plaza, "Enum.Material[materialName]", 1, true) ~= nil):toBe(true)
			expect(string.find(plaza, "isBuiltinMaterial", 1, true) ~= nil):toBe(true)
			-- Originals are saved so disable() restores the exact live look.
			expect(string.find(plaza, "local function restore()", 1, true) ~= nil):toBe(true)
		end)

		t:it("walk-in applier reuses the existing police model and pathing", function()
			local walkin = fs.readFile("src/server/World/LookDevWalkin.luau")
			expect(string.find(walkin, "Village.police", 1, true) ~= nil):toBe(true)
			expect(string.find(walkin, ":walkTo(", 1, true) ~= nil):toBe(true)
			expect(string.find(walkin, ":teleport(", 1, true) ~= nil):toBe(true)
			expect(string.find(walkin, "local function restore()", 1, true) ~= nil):toBe(true)
		end)

		t:it("Main bootstraps register the appliers behind a failure-isolating pcall", function()
			local client = fs.readFile("src/client/Main.client.luau")
			local server = fs.readFile("src/server/Main.server.luau")
			expect(string.find(client, "pcall(require, script.Parent.World.LookDevPlaza)", 1, true) ~= nil):toBe(true)
			expect(string.find(client, "pcall(require, script.Parent.UI.LookDevIcons)", 1, true) ~= nil):toBe(true)
			expect(string.find(server, "pcall(require, script.Parent.World.LookDevWalkin)", 1, true) ~= nil):toBe(true)
		end)
	end)
end
