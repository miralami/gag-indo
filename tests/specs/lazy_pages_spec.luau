--!nocheck
-- LazyPages: build-on-open registry used by the phone app pages (pure bookkeeping).

return function(t, Env)
	local expect = t.expect
	local env, LazyPages

	-- Fake page "instances" are tables; the log records the build/apply/destroy calls.
	local function makeRegistry(ids)
		local log = { built = {}, applied = {}, destroyed = {} }
		local defs = {}
		for _, id in ids do
			defs[id] = {
				build = function(pageId)
					table.insert(log.built, pageId)
					return { id = pageId }
				end,
				apply = function(instance, state)
					table.insert(log.applied, { id = instance.id, state = state })
				end,
				destroy = function(instance, pageId)
					table.insert(log.destroyed, pageId)
				end,
			}
		end
		return LazyPages.new(defs), log
	end

	t:describe("LazyPages", function()
		t:beforeEach(function()
			env = Env.new()
			LazyPages = env:require("client/UI/LazyPages")
		end)

		t:it("builds nothing until a page is opened", function()
			local pages, log = makeRegistry({ "a", "b" })
			expect(pages:builtCount()):toBe(0)
			expect(#log.built):toBe(0)
			expect(pages:isBuilt("a")):toBe(false)
			expect(pages:get("a")):toBe(nil)
		end)

		t:it("builds once on open, applies every open and keeps the instance", function()
			local pages, log = makeRegistry({ "a" })
			local first = pages:open("a")
			local second = pages:open("a")
			expect(first == second):toBe(true)
			expect(#log.built):toBe(1)
			expect(#log.applied):toBe(2)
			expect(pages:isBuilt("a")):toBe(true)
			expect(pages:builtCount()):toBe(1)
		end)

		t:it("ignores unknown pages without erroring", function()
			local pages = makeRegistry({ "a" })
			expect(pages:open("nope")):toBe(nil)
			expect(pages:refresh("nope")):toBe(false)
			expect(pages:setState("nope", { x = 1 })):toBe(false)
			expect(pages:close("nope")):toBe(false)
			expect(pages:has("nope")):toBe(false)
			expect(pages:has("a")):toBe(true)
		end)

		t:it("stores state set while closed and applies it on build", function()
			local pages, log = makeRegistry({ "a" })
			expect(pages:setState("a", { cash = 5 })):toBe(false)
			expect(#log.built):toBe(0)
			expect(#log.applied):toBe(0)
			pages:setState("a", { cash = 9, tier = 2 })
			pages:open("a")
			expect(log.applied[1].state.cash):toBe(9)
			expect(log.applied[1].state.tier):toBe(2)
		end)

		t:it("merges patches shallowly and applies at once when built", function()
			local pages, log = makeRegistry({ "a" })
			pages:open("a")
			local applied = pages:setState("a", { x = 1 })
			pages:setState("a", { y = 2 })
			expect(applied):toBe(true)
			local last = log.applied[#log.applied].state
			expect(last.x):toBe(1)
			expect(last.y):toBe(2)
		end)

		t:it("closing destroys the instance, keeps the state, and rebuilds fresh on reopen", function()
			local pages, log = makeRegistry({ "a" })
			local first = pages:open("a")
			pages:setState("a", { v = 3 })
			expect(pages:close("a")):toBe(true)
			expect(pages:close("a")):toBe(false)
			expect(log.destroyed[1]):toBe("a")
			expect(pages:isBuilt("a")):toBe(false)
			expect(pages:refresh("a")):toBe(false)
			pages:setState("a", { w = 4 })
			local second = pages:open("a")
			expect(first == second):toBe(false)
			expect(#log.built):toBe(2)
			local last = log.applied[#log.applied].state
			expect(last.v):toBe(3)
			expect(last.w):toBe(4)
		end)

		t:it("show keeps exactly one page built and home (nil) closes all", function()
			local pages, log = makeRegistry({ "a", "b", "c" })
			pages:show("a")
			pages:show("b")
			expect(pages:isBuilt("a")):toBe(false)
			expect(pages:isBuilt("b")):toBe(true)
			expect(pages:builtCount()):toBe(1)
			expect(log.destroyed[1]):toBe("a")
			pages:show("b")
			expect(#log.built):toBe(2)
			pages:show(nil)
			expect(pages:builtCount()):toBe(0)
			pages:show("c")
			pages:show("zzz")
			expect(pages:builtCount()):toBe(0)
		end)

		t:it("closeAll destroys every built page", function()
			local pages, log = makeRegistry({ "a", "b" })
			pages:open("a")
			pages:open("b")
			pages:closeAll()
			expect(pages:builtCount()):toBe(0)
			expect(#log.destroyed):toBe(2)
			pages:closeAll()
			expect(#log.destroyed):toBe(2)
		end)

		t:it("a build that returns nothing leaves the page unbuilt and unapplied", function()
			local applied = 0
			local pages = LazyPages.new({
				a = {
					build = function()
						return nil
					end,
					apply = function()
						applied += 1
					end,
				},
			})
			expect(pages:open("a")):toBe(nil)
			expect(pages:isBuilt("a")):toBe(false)
			expect(applied):toBe(0)
		end)

		t:it("works without apply or destroy hooks", function()
			local pages = LazyPages.new({ a = {
				build = function()
					return {}
				end,
			} })
			expect(pages:open("a") ~= nil):toBe(true)
			expect(pages:close("a")):toBe(true)
		end)
	end)
end
