--!nocheck
-- WORK_QUEUE item 8 (code health): characterization of the clean split that moved Phone's three
-- generic view helpers into PhoneWidgets.luau. The cases pin the exact instances/properties the
-- helpers produced before the move, so the extraction is provably behaviour-neutral.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect

	local function widgetEnv()
		local env = Env.new()
		local created = {}
		local icons = {}

		env.globals.UDim2 = {
			new = function(a, b, c, d)
				return { __udim2 = true, a = a, b = b, c = c, d = d }
			end,
			fromScale = function(x, y)
				return { __udim2 = true, scaleX = x, scaleY = y }
			end,
			fromOffset = function(x, y)
				return { __udim2 = true, offsetX = x, offsetY = y }
			end,
		}
		env.globals.UDim = {
			new = function(scale, offset)
				return { __udim = true, scale = scale, offset = offset }
			end,
		}

		local function record(node)
			table.insert(created, node)
			return node
		end
		-- Roblox attaches a child to props.Parent automatically; mirror that so sectionLabel's
		-- label shows up in row._children the way it does in Studio.
		local function attachParent(node, props)
			local parent = props and props.Parent
			if type(parent) == "table" and type(parent._children) == "table" then
				table.insert(parent._children, node)
			end
		end
		env:mock("client/UI/Icons", {
			make = function(name, props)
				table.insert(icons, { name = name, props = props })
				return props.Parent
			end,
		})
		env:mock("client/UI/Theme", {
			new = function(className, props, children)
				local node = record({ ClassName = className })
				for k, v in pairs(props or {}) do
					node[k] = v
				end
				node._children = {}
				for _, child in ipairs(children or {}) do
					table.insert(node._children, child)
				end
				return node
			end,
			label = function(props)
				local node = record({ ClassName = "TextLabel" })
				for k, v in pairs(props) do
					node[k] = v
				end
				attachParent(node, props)
				return node
			end,
			merah = "MERAH",
			displayFont = "DISPLAY",
		})

		return env, created, icons
	end

	t:describe("PhoneWidgets (extracted from Phone.luau)", function()
		t:it("clearChildren destroys only GuiObject children", function()
			local env = widgetEnv()
			local Widgets = env:require("client/UI/PhoneWidgets")
			local destroyed = {}
			local function child(name, isGui)
				return {
					Name = name,
					IsA = function(_, cls)
						return isGui and cls == "GuiObject"
					end,
					Destroy = function()
						table.insert(destroyed, name)
					end,
				}
			end
			local frame = {
				GetChildren = function()
					return { child("button", true), child("layout", false), child("label", true) }
				end,
			}
			Widgets.clearChildren(frame)
			expect(table.concat(destroyed, ",")):toBe("button,label")
		end)

		t:it("sectionLabel without an icon builds a Frame with an indented label", function()
			local env, created, icons = widgetEnv()
			local Widgets = env:require("client/UI/PhoneWidgets")
			local parent = { Name = "parent" }
			local row = Widgets.sectionLabel(parent, "Judul", 7, nil)
			expect(row.ClassName):toBe("Frame")
			expect(row.LayoutOrder):toBe(7)
			expect(row.BackgroundTransparency):toBe(1)
			expect(row.Parent):toBe(parent)
			expect(#row._children):toBe(1)
			local label = row._children[1]
			expect(label.Text):toBe("Judul")
			expect(label.TextColor3):toBe("MERAH")
			expect(label.TextXAlignment):toBe("TextXAlignment.Left")
			expect(label.TextSize):toBe(18)
			expect(label.Font):toBe("DISPLAY")
			expect(label.Position.b):toBe(0)
			expect(label.Size.b):toBe(0)
			expect(#icons):toBe(0)
			expect(#created):toBe(2)
		end)

		t:it("sectionLabel with an icon shifts the label 26 px and calls Icons.make", function()
			local env, _, icons = widgetEnv()
			local Widgets = env:require("client/UI/PhoneWidgets")
			local row = Widgets.sectionLabel({}, "Dompet", 3, "cash")
			expect(#icons):toBe(1)
			expect(icons[1].name):toBe("cash")
			expect(icons[1].props.Parent):toBe(row)
			local label = row._children[1]
			expect(label.Position.b):toBe(26)
			expect(label.Size.b):toBe(-26)
		end)

		t:it("scrollPage builds a ScrollingFrame with a list layout and phone padding", function()
			local env = widgetEnv()
			local Widgets = env:require("client/UI/PhoneWidgets")
			local parent = { Name = "screen" }
			local page = Widgets.scrollPage(parent, "Home")
			expect(page.ClassName):toBe("ScrollingFrame")
			expect(page.Name):toBe("Home")
			expect(page.Parent):toBe(parent)
			expect(page.ScrollBarThickness):toBe(4)
			expect(#page._children):toBe(2)
			expect(page._children[1].ClassName):toBe("UIListLayout")
			expect(page._children[2].ClassName):toBe("UIPadding")
			expect(page._children[2].PaddingBottom.offset):toBe(24)
		end)

		t:it("Phone binds the extracted helpers by name and no longer defines them inline", function()
			local phone = fs.readFile("src/client/UI/Phone.luau")
			local widgets = fs.readFile("src/client/UI/PhoneWidgets.luau")
			expect(string.find(phone, "PhoneWidgets", 1, true) ~= nil):toBe(true)
			expect(string.find(phone, "local function clearChildren", 1, true) ~= nil):toBe(false)
			expect(string.find(phone, "local function sectionLabel", 1, true) ~= nil):toBe(false)
			expect(string.find(phone, "local function scrollPage", 1, true) ~= nil):toBe(false)
			for _, name in { "clearChildren", "sectionLabel", "scrollPage" } do
				expect(string.find(widgets, "function PhoneWidgets." .. name, 1, true) ~= nil):toBe(true)
			end
		end)
	end)
end
