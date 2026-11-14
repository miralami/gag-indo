--!nocheck
-- NpcFactory spec (BUG-010): wrapping the same model twice (Greybox build wraps, then Village
-- bind wraps again with no info) must reuse the NameTag and Speech billboards. Each NPC shows
-- one name text, and the first wrap's label text is kept.

return function(t, Env)
	local expect = t.expect
	local env, NpcFactory, instances, tagged

	local function childrenNamed(parent, name)
		local list = {}
		for _, object in instances do
			if object.Parent == parent and object.Name == name then
				table.insert(list, object)
			end
		end
		return list
	end

	local function findChild(parent, name)
		return childrenNamed(parent, name)[1]
	end

	local function newInstance(className)
		local object = { ClassName = className, Name = className }
		object.FindFirstChild = function(self, childName)
			return findChild(self, childName)
		end
		table.insert(instances, object)
		return object
	end

	-- A stand-in for a character Model with a HumanoidRootPart, the way Greybox/Village see one.
	local function newCharacter(name)
		local model = newInstance("Model")
		model.Name = name
		model.FindFirstChild = function(self, childName)
			return findChild(self, childName)
		end
		model.FindFirstChildWhichIsA = function(self, className)
			for _, object in instances do
				if object.Parent == self and object.ClassName == className then
					return object
				end
			end
			return nil
		end
		model.SetAttribute = function(self, key, value)
			self[key] = value
		end
		model.GetPivot = function()
			return { position = Env.Vector3.new(0, 0, 0) }
		end
		local root = newInstance("Part")
		root.Name = "HumanoidRootPart"
		root.Parent = model
		return model
	end

	t:describe("NpcFactory.wrap idempotence (BUG-010)", function()
		t:beforeEach(function()
			env = Env.new()
			instances = {}
			tagged = {}

			env.globals.Color3 = {
				fromHex = function()
					return { R = 0, G = 0, B = 0 }
				end,
				fromRGB = function(r, g, b)
					return { R = r, G = g, B = b }
				end,
				new = function(r, g, b)
					return { R = r, G = g, B = b }
				end,
			}
			env.globals.Vector2 = {
				new = function(x, y)
					return { X = x, Y = y }
				end,
			}
			env.globals.UDim2 = {
				fromOffset = function(x, y)
					return { Width = x, Height = y }
				end,
				fromScale = function(x, y)
					return { Width = x, Height = y }
				end,
			}
			env.globals.Instance = {
				new = function(className)
					return newInstance(className)
				end,
			}
			env:mock("server/World/Map", {
				TAGS = { Npc = "NpcTag" },
				add = function(instance, tag)
					table.insert(tagged, { instance = instance, tag = tag })
				end,
			})
			-- Real Props module: it builds the BillboardGui and TextLabel stand-ins.
			NpcFactory = env:require("server/World/NpcFactory")
		end)

		local function anchorOf(model)
			return model.PrimaryPart
		end

		t:it("wraps once with exactly one NameTag and one Speech billboard", function()
			local model = newCharacter("Pak RT")
			NpcFactory.wrap(model, { name = "Pak RT", subtitle = "Ketua RT 01" })
			local anchor = anchorOf(model)
			expect(#childrenNamed(anchor, "NameTag")):toBe(1)
			expect(#childrenNamed(anchor, "Speech")):toBe(1)
		end)

		t:it("wrapping twice still leaves exactly one NameTag and one Speech child", function()
			local model = newCharacter("Pak RT")
			NpcFactory.wrap(model, { name = "Pak RT", subtitle = "Ketua RT 01" })
			NpcFactory.wrap(model)
			local anchor = anchorOf(model)
			expect(#childrenNamed(anchor, "NameTag")):toBe(1)
			expect(#childrenNamed(anchor, "Speech")):toBe(1)
		end)

		t:it("keeps the first wrap's name text when the second wrap has no info", function()
			local model = newCharacter("Pak RT")
			NpcFactory.wrap(model, { name = "Pak RT", subtitle = "Ketua RT 01" })
			NpcFactory.wrap(model)
			local label = findChild(findChild(anchorOf(model), "NameTag"), "Label")
			expect(label.Text):toBe("Pak RT · Ketua RT 01")
		end)

		t:it("returns the same label objects from the second wrap", function()
			local model = newCharacter("Pak RT")
			local first = NpcFactory.wrap(model, { name = "Pak RT", subtitle = "Ketua RT 01" })
			local second = NpcFactory.wrap(model)
			expect(second.nameLabel == first.nameLabel):toBe(true)
			expect(second.speechLabel == first.speechLabel):toBe(true)
		end)
	end)
end
