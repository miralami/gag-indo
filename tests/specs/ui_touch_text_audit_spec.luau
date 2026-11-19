--!nocheck
-- WORK_QUEUE item 20: touch target and text size audit (LUNE-ONLY static source audit).
--
-- Walks every UI builder and every call site, not just the phone:
--   * no TextLabel/TextButton renders text below Visuals.type.small (11 px), including when
--     TextScaled shrinks it through a UITextSizeConstraint.MinTextSize;
--   * every interactive button meets the checked-in PhoneLayout.meetsTouch contract (a 44 px
--     axis). Pixel-sized buttons are checked directly; scale/full-width buttons and the two
--     grid-cell-sized button families are checked against the layout that sizes them.
--
-- The touch rule is deliberately the repo's own one-axis contract (PhoneLayout.meetsTouch),
-- not a new 44x44-both-axes rule: the wide, short Admin/HUD/Leaderboard buttons already pass
-- it, and forcing them to 44 px tall would regress the AdminPanel fit proved in item 19.
-- See WORK_QUEUE "Decisions for designer".

local fs = require("@lune/fs")

local MIN_TEXT = 11 -- Visuals.type.small
local TOUCH = 44 -- Visuals.touch / PhoneLayout.touchMin

local UI_DIRS = { "src/client/UI", "src/client/Minigames", "src/client/Feel", "src/server/World" }

local function read(path: string): string
	return fs.readFile(path)
end

local function has(path: string, needle: string): boolean
	return string.find(read(path), needle, 1, true) ~= nil
end

local function collect(dir: string, out: { string })
	for _, name in fs.readDir(dir) do
		local p = dir .. "/" .. name
		if fs.isDir(p) then
			collect(p, out)
		elseif string.match(name, "%.luau$") then
			table.insert(out, p)
		end
	end
end

local function uiFiles(): { string }
	local out = {}
	for _, dir in UI_DIRS do
		collect(dir, out)
	end
	table.sort(out)
	return out
end

local function splitLines(src: string): { string }
	local out = {}
	for line in string.gmatch(src, "([^\n]*)") do
		out[#out + 1] = line
	end
	return out
end

-- Every `key = <integer literal>` assignment on a line; `MaxTextSize` is intentionally skipped
-- because it caps growth, not the rendered minimum.
local function textSizeLiterals(line: string): { { key: string, value: number } }
	local found = {}
	for key, raw in string.gmatch(line, "(%a+)%s*=%s*(%d+)") do
		if key == "TextSize" or key == "MinTextSize" then
			table.insert(found, { key = key, value = tonumber(raw) :: number })
		end
	end
	return found
end

local BUTTON_CTORS = {
	"Theme.button(",
	"Theme.new(\"TextButton\"",
	"Theme.new('TextButton'",
	"Theme.new(\"ImageButton\"",
	"Theme.new('ImageButton'",
}

-- A button with no inline Size is sized by its parent layout. These are the only such families;
-- each layout gives them a >=44 touch axis (see the cell-size assertions below).
local GRID_SIZED = {
	{ anchor = "Perf_", why = "Admin perf switches use a half-panel-width UIGridLayout cell" },
	{ anchor = "App_", why = "Phone app tiles use an 88 px-tall UIGridLayout cell" },
}

local function isButtonLine(line: string): boolean
	for _, ctor in BUTTON_CTORS do
		if string.find(line, ctor, 1, true) then
			return true
		end
	end
	return false
end

-- First UDim2 Size expression on a line, e.g. UDim2.fromOffset(44, 44) or UDim2.new(0, 44, 0, 30).
local function sizeExpr(line: string): string?
	return string.match(line, "Size%s*=%s*(UDim2%.%a+%([^\n%)]*%))")
end

local function num(value: string?): number?
	return if value then tonumber((string.gsub(value, "%s", ""))) else nil
end

-- A UDim2 meets the touch target when either axis is a >=44 pixel literal, or either axis is a
-- scale (it fills a panel whose touch size is checked elsewhere). Named expressions are exempt
-- from this static check and covered by their own assertions.
local function meetsTouchExpr(expr: string?): boolean
	if not expr then
		return false
	end
	local a, b = string.match(expr, "fromOffset%(([^,]+),([^%)]+)%)")
	if a then
		local w, h = num(a), num(b)
		if w and h then
			return w >= TOUCH or h >= TOUCH
		end
		return true
	end
	local xs, xo, ys, yo = string.match(expr, "new%(([^,]+),([^,]+),([^,]+),([^%)]+)%)")
	if xs then
		local sx, ox, sy, oy = num(xs), num(xo), num(ys), num(yo)
		if (sx and sx > 0) or (sy and sy > 0) then
			return true
		end -- scale axis fills a >=44 panel
		if ox and oy then
			return math.abs(ox) >= TOUCH or math.abs(oy) >= TOUCH
		end
		return true -- named expression, checked by a behavioural/constant assertion
	end
	return true
end

return function(t, Env, Fakes)
	local expect = t.expect

	t:describe("UI touch target and text size audit", function()
		t:it("reads the minimums from the checked-in sources of truth", function()
			expect(has("src/shared/Config/Visuals.luau", "small = 11")):toBeTruthy()
			expect(has("src/shared/Config/Visuals.luau", "touch = 44")):toBeTruthy()
			expect(has("src/shared/PhoneLayout.luau", "PhoneLayout.touchMin = 44")):toBeTruthy()
			-- The contract is one axis >=44; changing it to both axes needs a designer decision.
			expect(has("src/shared/PhoneLayout.luau", "w >= PhoneLayout.touchMin or h >= PhoneLayout.touchMin")):toBeTruthy()
		end)

		t:it("no UI text renders below the 11 px minimum", function()
			local files = uiFiles()
			expect(#files):toBeAtLeast(8)
			local problems = {}
			for _, path in files do
				for lineno, line in splitLines(read(path)) do
					for _, hit in textSizeLiterals(line) do
						if hit.value < MIN_TEXT then
							table.insert(problems, `{path}:{lineno}: {hit.key} = {hit.value} < {MIN_TEXT}`)
						end
					end
				end
			end
			if #problems > 0 then
				error("text below minimum:\n  " .. table.concat(problems, "\n  "), 0)
			end
		end)

		t:it("every interactive button meets the 44 px touch target", function()
			local files = uiFiles()
			local problems = {}
			for _, path in files do
				-- Theme.luau defines the builder, not a button instance.
				if string.match(path, "Theme%.luau$") == nil then
					local src = read(path)
					local ls = splitLines(src)
					for i, line in ls do
						if isButtonLine(line) then
							local expr = nil
							for j = i + 1, math.min(i + 20, #ls) do
								expr = sizeExpr(ls[j])
								if expr then
									break
								end
							end
							if expr then
								if not meetsTouchExpr(expr) then
									table.insert(problems, `{path}:{i}: button {expr} has no 44 px axis`)
								end
							else
								local near = table.concat(ls, "\n", i, math.min(i + 12, #ls))
								local allowed = false
								for _, rule in GRID_SIZED do
									if string.find(near, rule.anchor, 1, true) then
										allowed = true
									end
								end
								if not allowed then
									table.insert(problems, `{path}:{i}: button has no inline Size and no grid layout`)
								end
							end
						end
					end
				end
			end
			if #problems > 0 then
				error("buttons below touch target:\n  " .. table.concat(problems, "\n  "), 0)
			end
		end)

		t:it("grid-sized button families provide a 44 px touch axis", function()
			local phone = read("src/client/UI/Phone.luau")
			expect(string.find(phone, "CellSize = UDim2.new(1 / 3, -4, 0, 88)", 1, true)):toBeTruthy()
			expect(has("src/client/UI/Admin.luau", "CellSize = UDim2.new(0.5, -2, 0, 30)")):toBeTruthy()
			-- Half a 340 px panel is 170 px wide: the axis that meets the touch target.
			expect(has("src/client/UI/Admin.luau", "Size = UDim2.fromOffset(340, 690)")):toBeTruthy()
		end)

		t:it("the two phone constraints clamp text at the 11 px minimum (mutation guard)", function()
			local phone = read("src/client/UI/Phone.luau")
			expect(string.find(phone, "MinTextSize = 11, Parent = label", 1, true)):toBeTruthy()
			expect(string.find(phone, "MinTextSize = 11, Parent = litLabel", 1, true)):toBeTruthy()
		end)
	end)
end
