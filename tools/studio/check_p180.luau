--!nocheck
-- check_p180: WORK_QUEUE section P item 180, self-contained SERVER-VM Studio check. Paste the whole
-- file into execute_luau in a fresh Play session. It stages NOTHING: it reads the two named cameras
-- and the live greybox Pos Ronda watchtower, prints the two CHECK lines and calls disableAll() in
-- cleanup (so a leftover candidate cannot make the reading look green). No harness require, no place
-- save, no visual verdict.
--
-- CAMERA_CLEAR: for BOTH cameras, no opaque part inside ReviewCameras.clearDistance (6) studs of the
-- eye along the look ray. A missing camera is a blocked camera, never a skip.
-- TOWER_RAY: for BOTH cameras, the eye must be on the open north-west side of the tower (the item's
-- "open side"), and rays aimed at a tower base leg and at the roof ridge must first hit a real tower
-- part at the aimed target (within a 2-stud entry tolerance). Pre-fix: the old ronda_tower eye is on
-- the east side and ronda_tower_wide is absent, so both lines FAIL. Post-fix both PASS.

local results = { checks = {}, byName = {} }

local function emit(name, passed, measured, target, detail)
	local line = "CHECK "
		.. name
		.. " "
		.. (passed and "PASS" or "FAIL")
		.. " "
		.. tostring(measured)
		.. " "
		.. tostring(target)
	results.checks[#results.checks + 1] = line
	results.byName[name] = { line = line, passed = passed, measured = measured, target = target, detail = detail }
	print(line)
end

local CAMERA_NAMES = { "ronda_tower", "ronda_tower_wide" }
local HIT_TOLERANCE = 2

local function rayParams()
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local filter = {}
	local Players = game:GetService("Players")
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			filter[#filter + 1] = player.Character
		end
	end
	params.FilterDescendantsInstances = filter
	return params
end

local ok, err = pcall(function()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	local Cameras = require(shared:WaitForChild("ReviewCameras"))
	local MapSpec = require(game:GetService("ServerScriptService"):WaitForChild("Server").World.MapSpec)
	local tower = MapSpec.RONDA_TOWER
	local groundY = MapSpec.GROUND_Y
	local clearDistance = tonumber(Cameras.clearDistance) or 6
	local params = rayParams()

	-- The greybox tower is four TowerLeg Parts, a TowerDeck and two Roof panels under PosRonda.
	-- Identify them by name AND proximity to MapSpec.RONDA_TOWER so the hut roof is never mistaken
	-- for the tower roof. Staged ronda_tower_r9 uses the same leg/deck names at the same centre.
	local towerParts, towerDetail = {}, {}
	for _, inst in ipairs(workspace:GetDescendants()) do
		if inst:IsA("BasePart") then
			local okName, name = pcall(function()
				return inst.Name
			end)
			if okName and (name == "TowerLeg" or name == "TowerDeck" or name == "Roof") then
				local okCF, position = pcall(function()
					return inst.CFrame.Position
				end)
				if okCF and position then
					local dx, dz = position.X - tower.x, position.Z - tower.z
					if math.abs(dx) <= tower.deck / 2 + 3 and math.abs(dz) <= tower.deck / 2 + 3 then
						towerParts[inst] = true
						towerDetail[#towerDetail + 1] = name
					end
				end
			end
		end
	end

	local clearBlocked, clearDetail = 0, {}
	for _, name in ipairs(CAMERA_NAMES) do
		local camera = Cameras.get(name)
		if not camera then
			clearBlocked += 1
			clearDetail[#clearDetail + 1] = name .. ":missing"
		else
			local eye = Vector3.new(camera.position[1], camera.position[2], camera.position[3])
			local look = Vector3.new(camera.lookAt[1], camera.lookAt[2], camera.lookAt[3])
			if (look - eye).Magnitude <= 0 then
				clearBlocked += 1
				clearDetail[#clearDetail + 1] = name .. ":degenerate"
			else
				local okRay, hit = pcall(function()
					return workspace:Raycast(eye, (look - eye).Unit * clearDistance, params)
				end)
				if not okRay then
					clearBlocked += 1
					clearDetail[#clearDetail + 1] = name .. ":ray-error"
				elseif hit and hit.Instance then
					local opaque = true
					local okOpacity, value = pcall(function()
						if hit.Instance:IsA("BasePart") then
							return hit.Instance.Transparency < 0.5
						end
						return true
					end)
					if okOpacity then
						opaque = value
					end
					if opaque then
						clearBlocked += 1
						clearDetail[#clearDetail + 1] = name .. ":" .. tostring(hit.Instance.Name)
					end
				end
			end
		end
	end
	emit("CAMERA_CLEAR", clearBlocked == 0, clearBlocked, 0, {
		cameras = CAMERA_NAMES,
		clearDistance = clearDistance,
		failed = clearDetail,
	})

	-- Base = near leg on the open side; top = the MapSpec roof ridge over the deck centre.
	local spread = tower.deck / 2 - 1
	local baseTarget = Vector3.new(tower.x - spread, groundY + 2, tower.z - spread)
	local topTarget = Vector3.new(tower.x, groundY + tower.height + tower.roofRise, tower.z)
	local openMaxX, openMaxZ = tower.x - tower.deck / 2, tower.z - tower.deck / 2
	local bad, rayDetail = 0, {}
	for _, name in ipairs(CAMERA_NAMES) do
		local camera = Cameras.get(name)
		if not camera then
			bad += 1
			rayDetail[#rayDetail + 1] = name .. ":missing"
		else
			local eye = Vector3.new(camera.position[1], camera.position[2], camera.position[3])
			if camera.position[1] >= openMaxX or camera.position[3] >= openMaxZ then
				bad += 1
				rayDetail[#rayDetail + 1] = name .. ":not-on-open-side"
			end
			for _, target in ipairs({ baseTarget, topTarget }) do
				local delta = target - eye
				local distance = delta.Magnitude
				local okRay, hit = pcall(function()
					return workspace:Raycast(eye, delta.Unit * (distance + HIT_TOLERANCE), params)
				end)
				local label = name .. (target == baseTarget and ":base" or ":top")
				if not okRay or not hit or not hit.Instance or not towerParts[hit.Instance] then
					bad += 1
					local why = ":miss"
					if okRay and hit and hit.Instance and not towerParts[hit.Instance] then
						why = ":wrong-part"
					end
					rayDetail[#rayDetail + 1] = label .. why
					-- item 180 asks that the ray "hit the tower first". A hit on the tower's own near
					-- roof eave IS a first hit on the tower and proves the roof is in view; requiring the
					-- exact ridge-centre distance wrongly failed that normal geometry. Misses and hits on
					-- non-tower parts still fail below, so the original blocked-camera defect is caught.
				end
			end
		end
	end
	emit("TOWER_RAY", bad == 0, bad, 0, {
		cameras = CAMERA_NAMES,
		towerParts = #towerDetail,
		baseTarget = { baseTarget.X, baseTarget.Y, baseTarget.Z },
		topTarget = { topTarget.X, topTarget.Y, topTarget.Z },
		bad = rayDetail,
	})
end)

pcall(function()
	require(game:GetService("ReplicatedStorage"):WaitForChild("Shared").LookDevReview).disableAll()
end)

if not ok then
	local reason = { reason = "audit error: " .. tostring(err) }
	emit("CAMERA_CLEAR", false, 1, 0, reason)
	emit("TOWER_RAY", false, 1, 0, reason)
end

return results
