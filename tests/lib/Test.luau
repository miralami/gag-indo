--!nocheck
-- Tiny test framework (describe / it / beforeEach / expect). No dependencies.
-- A spec file returns `function(t, Env, Fakes) ... end`; see tests/specs/*_spec.luau.

local Test = {}
Test.__index = Test

type Case = { name: string, fn: () -> () }
type Suite = { name: string, cases: { Case }, before: { () -> () } }

-- ---------------------------------------------------------------------------
-- Value helpers
-- ---------------------------------------------------------------------------

local function show(value: any, depth: number?): string
	local level = depth or 0
	local kind = type(value)
	if kind == "string" then
		return string.format("%q", value)
	elseif kind == "table" then
		-- Fakes (players, instances) point back at each other; don't walk forever.
		if level >= 3 then
			return "{...}"
		end
		local parts = {}
		local keys = {}
		for key in value do
			table.insert(keys, key)
		end
		table.sort(keys, function(a, b)
			return tostring(a) < tostring(b)
		end)
		for _, key in keys do
			table.insert(parts, tostring(key) .. " = " .. show(value[key], level + 1))
		end
		return "{ " .. table.concat(parts, ", ") .. " }"
	end
	return tostring(value)
end

local function deepEqual(a: any, b: any): boolean
	if a == b then
		return true
	end
	if type(a) ~= "table" or type(b) ~= "table" then
		return false
	end
	for key, value in a do
		if not deepEqual(value, b[key]) then
			return false
		end
	end
	for key in b do
		if a[key] == nil then
			return false
		end
	end
	return true
end

-- ---------------------------------------------------------------------------
-- expect()
-- ---------------------------------------------------------------------------

local Expectation = {}
Expectation.__index = Expectation

local function check(self, passed: boolean, message: string)
	if self._negate then
		passed = not passed
		message = "NOT: " .. message
	end
	if not passed then
		error(message, 3)
	end
end

function Expectation:toBe(expected)
	check(self, self._value == expected, `expected {show(expected)}, got {show(self._value)}`)
end

function Expectation:toEqual(expected)
	check(self, deepEqual(self._value, expected), `expected {show(expected)}, got {show(self._value)}`)
end

function Expectation:toBeNear(expected: number, epsilon: number?)
	local value = self._value
	local eps = epsilon or 1e-6
	check(
		self,
		type(value) == "number" and math.abs(value - expected) <= eps,
		`expected {show(expected)} (+/- {eps}), got {show(value)}`
	)
end

function Expectation:toBeGreaterThan(expected: number)
	check(self, type(self._value) == "number" and self._value > expected, `expected > {expected}, got {show(self._value)}`)
end

function Expectation:toBeLessThan(expected: number)
	check(self, type(self._value) == "number" and self._value < expected, `expected < {expected}, got {show(self._value)}`)
end

function Expectation:toBeAtLeast(expected: number)
	check(self, type(self._value) == "number" and self._value >= expected, `expected >= {expected}, got {show(self._value)}`)
end

function Expectation:toBeAtMost(expected: number)
	check(self, type(self._value) == "number" and self._value <= expected, `expected <= {expected}, got {show(self._value)}`)
end

function Expectation:toBeNil()
	check(self, self._value == nil, `expected nil, got {show(self._value)}`)
end

function Expectation:toBeTruthy()
	check(self, self._value ~= nil and self._value ~= false, `expected a truthy value, got {show(self._value)}`)
end

function Expectation:toBeFalsy()
	check(self, self._value == nil or self._value == false, `expected a falsy value, got {show(self._value)}`)
end

-- Array contains `item` (by ==).
function Expectation:toContain(item)
	check(self, type(self._value) == "table" and table.find(self._value, item) ~= nil, `expected {show(self._value)} to contain {show(item)}`)
end

-- Calling the function must throw. Optional `fragment` must appear in the message.
function Expectation:toThrow(fragment: string?)
	local ok, err = pcall(self._value)
	local matched = not ok and (fragment == nil or string.find(tostring(err), fragment, 1, true) ~= nil)
	check(self, matched, `expected the function to throw{if fragment then ` containing {show(fragment)}` else ""}, got {if ok then "no error" else show(tostring(err))}`)
end

local function expect(value: any)
	local expectation = setmetatable({ _value = value, _negate = false }, Expectation)
	-- expect(x).never:toBe(y)
	expectation.never = setmetatable({ _value = value, _negate = true }, Expectation)
	return expectation
end

-- ---------------------------------------------------------------------------
-- Suites
-- ---------------------------------------------------------------------------

function Test.new()
	local self = setmetatable({}, Test)
	self.suites = {} :: { Suite }
	self._stack = {} :: { Suite }
	self.expect = expect
	return self
end

function Test:describe(name: string, body: () -> ())
	local parentBefore = {}
	local prefix = ""
	local parent = self._stack[#self._stack]
	if parent then
		prefix = parent.name .. " > "
		parentBefore = table.clone(parent.before)
	end
	local suite: Suite = { name = prefix .. name, cases = {}, before = parentBefore }
	table.insert(self.suites, suite)
	table.insert(self._stack, suite)
	body()
	table.remove(self._stack)
end

function Test:beforeEach(fn: () -> ())
	local suite = self._stack[#self._stack]
	assert(suite, "beforeEach must be called inside describe()")
	table.insert(suite.before, fn)
end

function Test:it(name: string, fn: () -> ())
	local suite = self._stack[#self._stack]
	assert(suite, "it() must be called inside describe()")
	table.insert(suite.cases, { name = name, fn = fn })
end

-- Runs everything. Returns passed, failed and the list of failure descriptions.
function Test:run(filter: string?, log: (string) -> ())
	local passed, failed = 0, 0
	local failures = {}

	for _, suite in self.suites do
		local printedHeader = false
		for _, case in suite.cases do
			local fullName = suite.name .. " > " .. case.name
			if filter == nil or string.find(string.lower(fullName), string.lower(filter), 1, true) then
				if not printedHeader then
					log(suite.name)
					printedHeader = true
				end
				local ok, err = pcall(function()
					for _, hook in suite.before do
						hook()
					end
					case.fn()
				end)
				if ok then
					passed += 1
					log("  PASS  " .. case.name)
				else
					failed += 1
					log("  FAIL  " .. case.name)
					log("        " .. tostring(err))
					table.insert(failures, fullName .. "\n        " .. tostring(err))
				end
			end
		end
	end

	return passed, failed, failures
end

return Test
