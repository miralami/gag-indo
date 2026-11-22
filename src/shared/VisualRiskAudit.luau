--!strict
-- VisualRiskAudit: pure-data visual-risk predicates for candidate part descriptors.
-- No engine calls, no staging, no side effects: the same descriptors always give the same list.

local VisualRiskAudit = {
	emptyIsFailure = true, -- an empty set is not evidence of a clean candidate
	probeOk = false,
}

export type Descriptor = {
	name: string,
	size: { number },
	position: { number }?,
	shape: string?,
	kind: string?,
}

local FLOAT_KIND_TOKENS = { "roof", "awning", "sign" }
local FLOAT_NAME_TOKENS = { "roof", "awning", "sign", "ridge_cap" }
local SIZE_TOKENS = { "fence", "roof", "bridge", "road", "awning", "sign", "rail", "ditch", "path" }
local GROW = 0.3

local function containsToken(value: any, tokens: { string }): boolean
	if type(value) ~= "string" then
		return false
	end
	local lower = string.lower(value)
	for _, token in ipairs(tokens) do
		if string.find(lower, token, 1, true) ~= nil then
			return true
		end
	end
	return false
end

local function validVec(value: any, positive: boolean): boolean
	if type(value) ~= "table" or #value < 3 then
		return false
	end
	for index = 1, 3 do
		local component = value[index]
		if type(component) ~= "number" then
			return false
		end
		if component ~= component or component == math.huge or component == -math.huge then
			return false
		end
		if positive and component <= 0 then
			return false
		end
	end
	return true
end

local function nameOf(part: Descriptor): string
	return if type(part.name) == "string" then part.name else "<unnamed>"
end

local function bounds(part: Descriptor): { number }
	local position = part.position :: { number }
	local size = part.size
	local halfX, halfY, halfZ = size[1] * 0.5, size[2] * 0.5, size[3] * 0.5
	return {
		position[1] - halfX - GROW,
		position[1] + halfX + GROW,
		position[2] - halfY - GROW,
		position[2] + halfY + GROW,
		position[3] - halfZ - GROW,
		position[3] + halfZ + GROW,
	}
end

local function overlaps(a: { number }, b: { number }): boolean
	for axis = 1, 3 do
		local lowA, highA = a[axis * 2 - 1], a[axis * 2]
		local lowB, highB = b[axis * 2 - 1], b[axis * 2]
		if lowA > highB or lowB > highA then
			return false
		end
	end
	return true
end

function VisualRiskAudit.floaters(parts: { Descriptor }): { string }
	local failures: { string } = {}
	-- One descriptor has no neighbour to compare, so there is no relational evidence of floating.
	if #parts < 2 then
		return failures
	end
	local valid: { [number]: boolean } = {}
	local boxes: { [number]: { number } } = {}
	for index, part in ipairs(parts) do
		valid[index] = validVec(part.size, true) and validVec(part.position, false)
		if valid[index] then
			boxes[index] = bounds(part)
		end
	end
	for index, part in ipairs(parts) do
		if not valid[index] then
			failures[#failures + 1] = nameOf(part)
		elseif not containsToken(part.kind, FLOAT_KIND_TOKENS) and not containsToken(part.name, FLOAT_NAME_TOKENS) then
			local connected = false
			for otherIndex, otherBox in pairs(boxes) do
				if otherIndex ~= index and overlaps(boxes[index], otherBox) then
					connected = true
					break
				end
			end
			if not connected then
				failures[#failures + 1] = nameOf(part)
			end
		end
	end
	return failures
end

function VisualRiskAudit.cubeShrubs(parts: { Descriptor }): { string }
	local failures: { string } = {}
	for _, part in ipairs(parts) do
		if not validVec(part.size, true) then
			failures[#failures + 1] = nameOf(part)
			continue
		end
		local shape = part.shape or "Block"
		if shape ~= "Block" then
			continue
		end
		local size = part.size
		local smallest = math.min(size[1], size[2], size[3])
		local largest = math.max(size[1], size[2], size[3])
		if smallest >= 1.5 and largest <= smallest * 1.2 then
			failures[#failures + 1] = nameOf(part)
		end
	end
	return failures
end

function VisualRiskAudit.sizeSanity(parts: { Descriptor }): { string }
	local failures: { string } = {}
	for _, part in ipairs(parts) do
		if not validVec(part.size, true) then
			failures[#failures + 1] = nameOf(part)
			continue
		end
		if containsToken(part.kind, SIZE_TOKENS) or containsToken(part.name, SIZE_TOKENS) then
			continue
		end
		local size = part.size
		if math.max(size[1], size[2], size[3]) > 12 and math.min(size[1], size[2], size[3]) < 0.8 then
			failures[#failures + 1] = nameOf(part)
		end
	end
	return failures
end

-- Self-probe: every predicate must classify hand-built samples correctly, so a PASS is not vacuous.
local function probe()
	local touching = {
		{ name = "A", size = { 2, 2, 2 }, position = { 0, 0, 0 } },
		{ name = "B", size = { 2, 2, 2 }, position = { 2, 0, 0 } },
	}
	local separated = {
		{ name = "A", size = { 2, 2, 2 }, position = { 0, 0, 0 } },
		{ name = "B", size = { 2, 2, 2 }, position = { 2, 0, 0 } },
		{ name = "Lonely", size = { 2, 2, 2 }, position = { 100, 0, 0 } },
	}
	local cube = { { name = "Cube", size = { 2, 2, 2 }, position = { 0, 0, 0 } } }
	local ball = { { name = "Ball", shape = "Ball", size = { 2, 2, 2 }, position = { 0, 0, 0 } } }
	local thin = { { name = "Thin", size = { 20, 0.4, 0.4 }, position = { 0, 0, 0 } } }
	local road = { { name = "Road", kind = "road", size = { 20, 0.4, 0.4 }, position = { 0, 0, 0 } } }
	-- floaters() needs a valid neighbour before it can classify anything; give the invalid
	-- descriptor a valid touching pair so it is the sole offender, not a vacuous singleton.
	local invalid = {
		{ name = "A", shape = "Ball", size = { 2, 2, 2 }, position = { 0, 0, 0 } },
		{ name = "B", shape = "Ball", size = { 2, 2, 2 }, position = { 2, 0, 0 } },
		{ name = "Invalid", size = { 2 }, position = { 40, 0, 0 } },
	}
	return #VisualRiskAudit.floaters(touching) == 0
		and #VisualRiskAudit.floaters(separated) == 1
		and #VisualRiskAudit.floaters(invalid) == 1
		and #VisualRiskAudit.cubeShrubs(cube) == 1
		and #VisualRiskAudit.cubeShrubs(ball) == 0
		and #VisualRiskAudit.cubeShrubs(invalid) == 1
		and #VisualRiskAudit.sizeSanity(thin) == 1
		and #VisualRiskAudit.sizeSanity(road) == 0
		and #VisualRiskAudit.sizeSanity(invalid) == 1
end

VisualRiskAudit.probeOk = probe()

return VisualRiskAudit
