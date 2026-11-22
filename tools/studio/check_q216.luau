--!nocheck
-- check_q216: WORK_QUEUE item 216, self-contained SERVER-VM Studio check. Paste this whole file into
-- execute_luau in a fresh Play session. It casts the standard CAMERA_CLEAR ray from the eye of every
-- registered review camera toward its lookAt for Cameras.clearDistance studs, excluding Characters,
-- and prints verbatim CHECK lines. No staging, no place save, no visual verdict.
--
--   CAMERA_CLEAR  0 opaque hits within clearDistance for every registered camera
--   DOCS_ONCE     every registry name appears exactly once (pure-data check on the live module)
--
-- CALIBRATION ANCHOR: the clear ray and its distance are single statements so a blocked camera can
-- be injected (e.g. spawn a Block at a known eye) between setup and the loop.

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

local function emitOnce(name, passed, measured, target, detail)
	if not results.byName[name] then
		emit(name, passed, measured, target, detail)
	end
end

local CHECK_NAMES = { "CAMERA_CLEAR", "DOCS_ONCE" }

local ok, err = pcall(function()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	local Cameras = require(shared:WaitForChild("ReviewCameras"))
	if type(Cameras) ~= "table" or type(Cameras.all) ~= "function" then
		error("ReviewCameras.all API missing")
	end

	-- CALIBRATION ANCHOR: ray params and distance are computed once, before the loop.
	local clearDistance = tonumber(Cameras.clearDistance) or 6
	local all = Cameras.all()
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local function refreshExcludes()
		local excluded = {}
		for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
			if player.Character then
				excluded[#excluded + 1] = player.Character
			end
		end
		params.FilterDescendantsInstances = excluded
	end
	refreshExcludes()

	local blocked, badCoords, checked = {}, {}, 0
	for _, camera in ipairs(all) do
		checked += 1
		local position, lookAt = camera.position, camera.lookAt
		if type(position) ~= "table" or type(lookAt) ~= "table" or #position < 3 or #lookAt < 3 then
			badCoords[#badCoords + 1] = camera.name
		else
			local eye = Vector3.new(position[1], position[2], position[3])
			local look = Vector3.new(lookAt[1], lookAt[2], lookAt[3])
			local dir = look - eye
			if dir.Magnitude <= 0 then
				badCoords[#badCoords + 1] = camera.name
			else
				local rayOk, hit = pcall(function()
					return workspace:Raycast(eye, dir.Unit * clearDistance, params)
				end)
				if not rayOk then
					blocked[#blocked + 1] = camera.name .. "@ray-error"
				elseif hit and hit.Instance then
					local okTrans, transparent = pcall(function()
						return hit.Instance.Transparency
					end)
					if okTrans and type(transparent) == "number" and transparent < 0.5 then
						blocked[#blocked + 1] = camera.name .. "@" .. hit.Instance.Name
					end
				end
			end
		end
	end
	emit("CAMERA_CLEAR", #blocked == 0 and #badCoords == 0, #blocked + #badCoords, 0, {
		checked = checked,
		blocked = blocked,
		badCoords = badCoords,
		clearDistance = clearDistance,
	})

	-- Pure-data mirror of the spec's "documented once" contract, read from the live module.
	local seen, duplicates, nameCount = {}, {}, 0
	for _, camera in ipairs(all) do
		if seen[camera.name] then
			duplicates[#duplicates + 1] = camera.name
		else
			seen[camera.name] = true
			nameCount += 1
		end
	end
	emit("DOCS_ONCE", #duplicates == 0 and nameCount == checked, #duplicates, 0, {
		names = nameCount,
		checked = checked,
		duplicates = duplicates,
	})
end)

if not ok then
	local reason = { reason = "audit error: " .. tostring(err) }
	for _, name in ipairs(CHECK_NAMES) do
		emitOnce(name, false, 1, 0, reason)
	end
end

return results
