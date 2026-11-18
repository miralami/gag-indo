--!nocheck
-- WORK_QUEUE item 11: the client structured-state store (src/client/State.luau) had no spec of
-- its own -- state_spec.luau only exercises the shared builder. These lock the two failure paths
-- where a damaged server payload must not corrupt the local store or notify listeners, plus
-- safe listener cleanup (a disconnected tab must not keep receiving patches).

return function(t, Env)
	local expect = t.expect
	local env, State, remotes, snapshotRemote, patchRemote, fired

	-- Client-side remote fake: OnClientEvent carries the payload, FireServer is a no-op.
	local function clientRemotes()
		local created = {}
		return setmetatable({}, {
			__index = function(_, name)
				if not created[name] then
					local signal = env.newSignal()
					created[name] = {
						OnClientEvent = signal,
						FireServer = function() end,
						_fire = function(_, payload)
							signal:Fire(payload)
						end,
					}
				end
				return created[name]
			end,
		})
	end

	t:describe("Client state store failure paths (item 11)", function()
		t:beforeEach(function()
			env = Env.new()
			remotes = clientRemotes()
			env:mock("shared/Remotes", remotes)
			State = env:require("client/State")
			fired = {}
			State.onChanged(function(section)
				table.insert(fired, section)
			end)
			State.mount()
			snapshotRemote = remotes.State_Snapshot
			patchRemote = remotes.State_Patch
		end)

		t:it("ignores a nil or non-table snapshot", function()
			snapshotRemote:_fire(nil)
			snapshotRemote:_fire("bad")
			snapshotRemote:_fire(42)
			expect(State.ready):toBe(false)
			expect(State.version):toBe(0)
			expect(#fired):toBe(0)
		end)

		t:it("ignores a snapshot with a missing or non-table sections field", function()
			-- An empty `sections` table is a VALID (if empty) snapshot, so it is not fired here.
			snapshotRemote:_fire({ version = 7 })
			snapshotRemote:_fire({ version = 7, sections = "bad" })
			expect(State.ready):toBe(false)
			expect(State.version):toBe(0)
			expect(#fired):toBe(0)
		end)

		t:it("accepts a valid snapshot once and marks the store ready", function()
			snapshotRemote:_fire({ version = 3, sections = { produce = { padi = 2 } } })
			expect(State.ready):toBe(true)
			expect(State.version):toBe(3)
			expect(State.get("produce").padi):toBe(2)
			expect(fired[1]):toBe("all")
		end)

		t:it("ignores a malformed patch without changing data or firing listeners", function()
			snapshotRemote:_fire({ version = 1, sections = { produce = { padi = 2 } } })
			fired = {}
			patchRemote:_fire(nil)
			patchRemote:_fire("bad")
			patchRemote:_fire(42)
			expect(State.get("produce").padi):toBe(2)
			expect(#fired):toBe(0)
		end)

		t:it("applies a valid patch and names only the changed sections", function()
			patchRemote:_fire({ produce = { padi = 9 }, items = {} })
			expect(State.get("produce").padi):toBe(9)
			expect(State.get("items")):toEqual({})
			-- Section iteration order is unspecified in Lua; assert the set, not the order.
			local seen = {}
			for _, section in fired do
				seen[section] = true
			end
			expect(seen.produce):toBe(true)
			expect(seen.items):toBe(true)
			expect(#fired):toBe(2)
		end)

		t:it("a disconnected listener stops firing and Disconnect is idempotent", function()
			local count = 0
			local handle = State.onChanged(function()
				count += 1
			end)
			handle:Disconnect()
			expect(function()
				handle:Disconnect()
			end).never:toThrow()
			patchRemote:_fire({ items = {} })
			expect(count):toBe(0)
		end)
	end)
end
