--!nocheck
-- WORK_QUEUE item 239: SubjectCoverage helper. Pure Lune spec with fake engine objects: a fake
-- Camera projects world X/Y linearly, a fake workspace.Raycast reconstructs the screen point and
-- asks the case's visibility function for the first hit. No game API and no place save.

return function(t, Env)
	local expect = t.expect
	local Coverage = Env.new():require("shared/SubjectCoverage")

	local function v3(x, y, z)
		return { X = x, Y = y, Z = z }
	end

	local function fakePart(name, x, y, width, height)
		local part = {
			Name = name,
			Size = v3(width, height, 1),
			CFrame = {
				Position = v3(x, y, 10),
				XVector = v3(1, 0, 0),
				YVector = v3(0, 1, 0),
				ZVector = v3(0, 0, 1),
			},
			Transparency = 0,
			_stage = "FIXTURE",
		}
		function part:IsA(className)
			return className == "BasePart"
		end
		function part:GetAttribute(key)
			if key == "LookDevStage" then
				return self._stage
			end
			return nil
		end
		return part
	end

	local function makeDeps(opts)
		opts = opts or {}
		local parts = opts.parts or {}
		local visibility = opts.visibility or function()
			return nil
		end
		local camera = {
			ViewportSize = nil,
			CFrame = nil,
		}
		function camera:WorldToViewportPoint(point)
			return { X = 200 + point.X * 10, Y = 150 - point.Y * 10, Z = point.Z }
		end
		function camera:ViewportPointToRay(x, y)
			return { Origin = v3(0, 0, 0), Direction = v3((x - 200) / 10, (150 - y) / 10, 1) }
		end
		local workspace = {
			GetDescendants = function()
				return opts.descendants or parts
			end,
			Raycast = function(_, _, direction, params)
				local excluded = params and params.FilterDescendantsInstances or {}
				local x = 200 + (direction.X / direction.Z) * 10
				local y = 150 - (direction.Y / direction.Z) * 10
				local hit = visibility(x, y, excluded)
				if not hit then
					return nil
				end
				for _, inst in ipairs(excluded) do
					if inst == hit then
						return nil
					end
				end
				return { Instance = hit }
			end,
		}
		return {
			game = {
				GetService = function(_, name)
					if name == "Workspace" then
						return workspace
					end
					return nil
				end,
			},
			workspace = workspace,
			Instance = {
				new = function()
					return camera
				end,
			},
			Vector2 = {
				new = function(x, y)
					return { X = x, Y = y }
				end,
			},
			Vector3 = { new = v3 },
			CFrame = {
				lookAt = function(eye)
					return {
						Position = v3(eye.X, eye.Y, eye.Z),
						XVector = v3(1, 0, 0),
						YVector = v3(0, 1, 0),
						ZVector = v3(0, 0, 1),
					}
				end,
			},
			RaycastParams = {
				new = function()
					return { FilterDescendantsInstances = {} }
				end,
			},
			Enum = { RaycastFilterType = { Exclude = "Exclude" } },
			reviewCameras = {
				get = function(name)
					if opts.cameras and opts.cameras[name] == nil then
						return nil
					end
					return { position = { 0, 0, 0 }, lookAt = { 0, 0, 10 } }
				end,
			},
		},
			camera
	end

	local VIEWPORT = { 400, 300 }

	t:describe("SubjectCoverage projection, occlusion and dedup (item 239)", function()
		t:it("projects AABB corners, clips to viewport and ignores non-tagged instances", function()
			local inside = fakePart("inside", 10, 0, 4, 2)
			local outside = fakePart("outside", 19, 0, 10, 2)
			local folder = { Name = "folder", _stage = "FIXTURE" }
			function folder:IsA()
				return false
			end
			function folder:GetAttribute()
				return "FIXTURE"
			end
			local deps = makeDeps({
				parts = { inside, outside },
				descendants = { folder, inside, outside },
				visibility = function()
					return inside
				end,
			})
			local result = Coverage.measure("FIXTURE", "test_cam", VIEWPORT, deps)
			expect(result.ok):toBeTruthy()
			expect(result.partCount):toBe(2)
			expect(#result.rects):toBe(2)
			expect(result.fraction):toBe(1)
			expect(result.sampleCount > 0):toBeTruthy()
			local clipped
			for _, rect in ipairs(result.rects) do
				if rect.x0 > 300 then
					clipped = rect
				end
			end
			expect(clipped ~= nil):toBeTruthy()
			expect(clipped.x1):toBe(400)
			expect(clipped.y0 >= 0 and clipped.y1 <= 300):toBeTruthy()
		end)

		t:it("rejects an opaque non-candidate first hit", function()
			local part = fakePart("visible", 10, 0, 4, 2)
			local blocker = fakePart("blocker", 0, 0, 1, 1)
			blocker._stage = "OTHER"
			local deps = makeDeps({
				parts = { part },
				visibility = function(x)
					if x < 300 then
						return blocker
					end
					return part
				end,
			})
			local result = Coverage.measure("FIXTURE", "test_cam", VIEWPORT, deps)
			expect(result.ok):toBeTruthy()
			expect(result.fraction > 0 and result.fraction < 1):toBeTruthy()
			expect(result.hitCount < result.sampleCount):toBeTruthy()
		end)

		t:it("skips transparent non-candidate hits and retries the ray", function()
			local part = fakePart("visible", 10, 0, 4, 2)
			local glass = fakePart("glass", 0, 0, 1, 1)
			glass._stage = "OTHER"
			glass.Transparency = 1
			local deps = makeDeps({
				parts = { part },
				visibility = function(_, _, excluded)
					for _, inst in ipairs(excluded) do
						if inst == glass then
							return part
						end
					end
					return glass
				end,
			})
			local result = Coverage.measure("FIXTURE", "test_cam", VIEWPORT, deps)
			expect(result.fraction):toBe(1)
			expect(result.hitCount):toBe(result.sampleCount)
		end)

		t:it("deduplicates overlapping candidate rects on the shared grid", function()
			local first = fakePart("first", 10, 0, 4, 2)
			local second = fakePart("second", 10, 0, 4, 2)
			local single = makeDeps({
				parts = { first },
				visibility = function()
					return first
				end,
			})
			local overlap = makeDeps({
				parts = { first, second },
				visibility = function(x)
					if x < 300 then
						return first
					end
					return second
				end,
			})
			local base = Coverage.measure("FIXTURE", "test_cam", VIEWPORT, single)
			local result = Coverage.measure("FIXTURE", "test_cam", VIEWPORT, overlap)
			expect(result.fraction):toBe(1)
			expect(result.hitCount):toBe(result.sampleCount)
			expect(result.sampleCount):toBe(base.sampleCount)
			expect(#result.rects):toBe(2)
		end)

		t:it("returns a fraction-zero failure when no parts carry the candidate tag", function()
			local deps = makeDeps({ parts = { fakePart("other", 10, 0, 4, 2) } })
			local result = Coverage.measure("MISSING", "test_cam", VIEWPORT, deps)
			expect(result.ok):toBeFalsy()
			expect(result.fraction):toBe(0)
			expect(result.sampleCount):toBe(0)
			expect(string.find(result.reason or "", "no candidate parts", 1, true) ~= nil):toBeTruthy()
		end)

		t:it("fails closed on an unknown camera and carries the default viewport", function()
			local part = fakePart("visible", 10, 0, 4, 2)
			local deps = makeDeps({ parts = { part }, cameras = {} })
			local missing = Coverage.measure("FIXTURE", "unknown_cam", VIEWPORT, deps)
			expect(missing.ok):toBeFalsy()
			expect(missing.fraction):toBe(0)
			local defaulted = Coverage.measure("FIXTURE", "test_cam", nil, deps)
			expect(defaulted.viewport.width):toBe(1375)
			expect(defaulted.viewport.height):toBe(753)
		end)

		t:it("self-probe passes on synthetic rects", function()
			expect(Coverage.probe()):toBeTruthy()
		end)
	end)
end
