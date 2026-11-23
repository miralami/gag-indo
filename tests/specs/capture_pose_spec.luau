--!nocheck
-- WORK_QUEUE item 264: pure-math contract for CAPTURE_POSE. No Studio claim: the client-DM pose
-- calibration lives in tools/studio/check_q264.luau and is run by the main session.

return function(t, Env)
	local expect = t.expect
	local CapturePose = Env.new():require("shared/CapturePose")
	local Cameras = Env.new():require("shared/ReviewCameras")

	local function finite(value)
		return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
	end

	-- Direction at `degrees` from the camera's -Z ray, rotating about +Y.
	local function turnedLook(degrees)
		local radians = math.rad(degrees)
		return { math.sin(radians), 0, -math.cos(radians) }
	end

	t:describe("item 264 CapturePose", function()
		t:it("exports the 0.5 stud and 2 degree tolerances", function()
			expect(CapturePose.POSITION_TOL):toBe(0.5)
			expect(CapturePose.ANGLE_TOL_DEG):toBe(2)
		end)

		t:it("returns a unit look vector from position to lookAt", function()
			local camera = { position = { 2, 3, 5 }, lookAt = { 2, 3, -5 } }
			local look = CapturePose.lookVector(camera)
			expect(#look):toBe(3)
			expect(look[1]):toBeNear(0)
			expect(look[2]):toBeNear(0)
			expect(look[3]):toBeNear(-1)
		end)

		t:it("passes at the exact review pose", function()
			local camera = { position = { 0, 0, 0 }, lookAt = { 0, 0, -10 } }
			local result = CapturePose.measure(camera, camera.position, CapturePose.lookVector(camera))
			expect(result.positionError):toBeNear(0)
			expect(result.angleDeg):toBeNear(0)
			expect(result.ok):toBe(true)
		end)

		t:it("passes with a 0.4 stud position error", function()
			local camera = { position = { 0, 0, 0 }, lookAt = { 0, 0, -10 } }
			local result = CapturePose.measure(camera, { 0.4, 0, 0 }, CapturePose.lookVector(camera))
			expect(result.positionError):toBeNear(0.4)
			expect(result.angleDeg):toBeNear(0)
			expect(result.ok):toBe(true)
		end)

		t:it("fails with a 0.6 stud position error", function()
			local camera = { position = { 0, 0, 0 }, lookAt = { 0, 0, -10 } }
			local result = CapturePose.measure(camera, { 0.6, 0, 0 }, CapturePose.lookVector(camera))
			expect(result.positionError):toBeNear(0.6)
			expect(result.ok):toBe(false)
		end)

		t:it("passes with a 1.5 degree look error", function()
			local camera = { position = { 0, 0, 0 }, lookAt = { 0, 0, -10 } }
			local result = CapturePose.measure(camera, camera.position, turnedLook(1.5))
			expect(result.positionError):toBeNear(0)
			expect(result.angleDeg):toBeNear(1.5, 1e-6)
			expect(result.ok):toBe(true)
		end)

		t:it("fails with a 3 degree look error", function()
			local camera = { position = { 0, 0, 0 }, lookAt = { 0, 0, -10 } }
			local result = CapturePose.measure(camera, camera.position, turnedLook(3))
			expect(result.angleDeg):toBeNear(3, 1e-6)
			expect(result.ok):toBe(false)
		end)

		t:it("fails when a within-tolerance position error is combined with a 3 degree look error", function()
			local camera = { position = { 0, 0, 0 }, lookAt = { 0, 0, -10 } }
			local result = CapturePose.measure(camera, { 0.4, 0, 0 }, turnedLook(3))
			expect(result.positionError):toBeNear(0.4)
			expect(result.angleDeg):toBeNear(3, 1e-6)
			expect(result.ok):toBe(false)
		end)

		t:it("returns FAIL with finite numbers for a zero look vector", function()
			local camera = { position = { 0, 0, 0 }, lookAt = { 0, 0, -10 } }
			local result = CapturePose.measure(camera, camera.position, { 0, 0, 0 })
			expect(finite(result.positionError)):toBe(true)
			expect(finite(result.angleDeg)):toBe(true)
			expect(result.ok):toBe(false)
		end)

		t:it("returns FAIL with finite numbers for a degenerate camera ray", function()
			local camera = { position = { 1, 2, 3 }, lookAt = { 1, 2, 3 } }
			local look = CapturePose.lookVector(camera)
			local result = CapturePose.measure(camera, camera.position, look)
			expect(finite(result.positionError)):toBe(true)
			expect(finite(result.angleDeg)):toBe(true)
			expect(result.ok):toBe(false)
		end)

		t:it("returns FAIL with finite numbers for non-finite pose components", function()
			local camera = { position = { 0, 0, 0 }, lookAt = { 0, 0, -10 } }
			local result = CapturePose.measure(camera, camera.position, { math.huge, math.huge, math.huge })
			expect(finite(result.positionError)):toBe(true)
			expect(finite(result.angleDeg)):toBe(true)
			expect(result.ok):toBe(false)
		end)

		t:it("measures the real lamp_night review camera from its own pose", function()
			local camera = Cameras.get("lamp_night")
			expect(camera ~= nil):toBe(true)
			local look = CapturePose.lookVector(camera)
			expect(#look):toBe(3)
			expect(math.sqrt(look[1] ^ 2 + look[2] ^ 2 + look[3] ^ 2)):toBeNear(1)
			local result = CapturePose.measure(camera, camera.position, look)
			expect(result.positionError):toBeNear(0)
			expect(result.angleDeg):toBeNear(0)
			expect(result.ok):toBe(true)
		end)

		t:it("measures the real path_curve review camera from its own pose", function()
			local camera = Cameras.get("path_curve")
			expect(camera ~= nil):toBe(true)
			local result = CapturePose.measure(camera, camera.position, CapturePose.lookVector(camera))
			expect(result.positionError):toBeNear(0)
			expect(result.angleDeg):toBeNear(0)
			expect(result.ok):toBe(true)
		end)

		t:it("formats PASS and FAIL lines with the shot name and both measurements", function()
			local camera = { position = { 0, 0, 0 }, lookAt = { 0, 0, -10 } }
			local pass = CapturePose.measure(camera, camera.position, CapturePose.lookVector(camera))
			expect(CapturePose.line("ROAD_FENCE_01", pass)):toBe(
				"CHECK CAPTURE_POSE_ROAD_FENCE_01 PASS 0.0000stud/0.00deg <=0.5stud/<=2deg"
			)
			local fail = CapturePose.measure(camera, { 0.6, 0, 0 }, turnedLook(3))
			expect(CapturePose.line("LAMPS_13", fail)):toBe(
				"CHECK CAPTURE_POSE_LAMPS_13 FAIL 0.6000stud/3.00deg <=0.5stud/<=2deg"
			)
		end)
	end)
end
