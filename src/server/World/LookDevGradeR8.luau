--!strict
-- LookDevGradeR8: SERVER-ONLY appliers for the OFF-BY-DEFAULT "grade_r8_a/b/c" candidates
-- (WORK_QUEUE section M item 91). Three tropical colour grades from pure Shared.ModelMapGradeR8
-- data. Each applier touches only Atmosphere, ColorCorrectionEffect, BloomEffect and SunRaysEffect;
-- it never creates, reads or writes any depth-of-field effect.
--
-- Effects are reused with Lighting:FindFirstChildOfClass and created under Lighting when missing.
-- Every overwritten property is saved on apply and restored byte-for-byte on restore; only
-- instances created here are destroyed. apply/restore are idempotent, every engine call is
-- pcall-guarded, and failures are published through Shared.LookDevFailures. No asset IDs.
--
--   require(game.ReplicatedStorage.Shared.LookDevReview).enable("grade_r8_a", game)

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if ok then
		return value
	end
	warn("[LookDevGradeR8] missing service " .. name)
	return nil
end

local ReplicatedStorage = service("ReplicatedStorage")
local Lighting = service("Lighting")
if not ReplicatedStorage or not Lighting then
	return {}
end

local okShared, Shared = pcall(function()
	return (ReplicatedStorage :: any):WaitForChild("Shared")
end)
if not okShared or not Shared then
	warn("[LookDevGradeR8] missing Shared folder")
	return {}
end

local okModules, LookDev, Data, Failures = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapGradeR8),
		require((Shared :: any).LookDevFailures)
end)
if not okModules or not LookDev or not Data or not Failures then
	warn("[LookDevGradeR8] could not require LookDev / ModelMapGradeR8 / LookDevFailures")
	return {}
end

local LookDevGradeR8 = {}
LookDevGradeR8.appliers = {} :: { [string]: { apply: (any) -> (), restore: () -> () } }

type SavedProp = { effect: any, prop: string, key: string, value: any }

local function make(key: string): { apply: (any) -> (), restore: () -> () }
	local id: string = Data.idPrefix .. key
	local applied = false
	local failures = 0
	local savedOrder: { SavedProp } = {}
	local created: { any } = {}

	local function fail(message: string)
		failures += 1
		warn("[LookDevGradeR8] " .. id .. ": " .. message)
	end

	local function publishFailures()
		pcall(function()
			Failures.set(id, failures)
		end)
	end

	local function clearState()
		for index = #savedOrder, 1, -1 do
			savedOrder[index] = nil
		end
		for index = #created, 1, -1 do
			local instance = created[index]
			pcall(function()
				instance:Destroy()
			end)
			created[index] = nil
		end
	end

	-- Reuse an existing Lighting child; create one only when absent, and remember it for restore.
	local function findEffect(className: string): any?
		local okFind, effect = pcall(function()
			return (Lighting :: any):FindFirstChildOfClass(className)
		end)
		if not okFind then
			fail("could not look up " .. className .. ": " .. tostring(effect))
			return nil
		end
		if effect then
			return effect
		end
		local okNew, instance = pcall(function()
			return (Instance :: any).new(className)
		end)
		if not okNew or not instance then
			fail("could not create " .. className .. ": " .. tostring(instance))
			return nil
		end
		local okParent, parentErr = pcall(function()
			instance.Name = "LookDevGradeR8_" .. className
			instance.Parent = Lighting
		end)
		if not okParent then
			pcall(function()
				instance:Destroy()
			end)
			fail("could not parent " .. className .. ": " .. tostring(parentErr))
			return nil
		end
		created[#created + 1] = instance
		return instance
	end

	local function saveProp(effect: any, className: string, prop: string): boolean
		local keyName = className .. "." .. prop
		for _, entry in ipairs(savedOrder) do
			if entry.key == keyName then
				return true
			end
		end
		local okRead, value = pcall(function()
			return effect[prop]
		end)
		if not okRead then
			fail("could not read " .. keyName .. ": " .. tostring(value))
			return false
		end
		savedOrder[#savedOrder + 1] = { effect = effect, prop = prop, key = keyName, value = value }
		return true
	end

	local function targetValue(className: string, prop: string, value: any): (any?, string?)
		if className == "Atmosphere" and (prop == "Color" or prop == "Decay") then
			local ok, color = pcall(function()
				return Color3.fromRGB(value.r, value.g, value.b)
			end)
			if not ok or not color then
				return nil, tostring(color)
			end
			return color, nil
		end
		if className == "ColorCorrectionEffect" and prop == "TintColor" then
			local ok, color = pcall(function()
				return Color3.new(value.r, value.g, value.b)
			end)
			if not ok or not color then
				return nil, tostring(color)
			end
			return color, nil
		end
		return value, nil
	end

	local function apply(_plan: any)
		if applied then
			return
		end
		clearState()
		failures = 0
		local values = Data.valuesFor(key)
		if not values then
			fail("unknown grade key " .. tostring(key))
			publishFailures()
			return
		end
		for _, className in ipairs(Data.TOUCHED_EFFECTS) do
			local effect = findEffect(className)
			if effect then
				for _, prop in ipairs(Data.properties[className]) do
					if saveProp(effect, className, prop) then
						local target, why = targetValue(className, prop, values[className][prop])
						if target == nil then
							fail("bad " .. className .. "." .. prop .. ": " .. tostring(why))
						else
							local okSet, err = pcall(function()
								effect[prop] = target
							end)
							if not okSet then
								fail("could not set " .. className .. "." .. prop .. ": " .. tostring(err))
							end
						end
					end
				end
			end
		end
		applied = true
		publishFailures()
	end

	local function restore()
		if not applied and #savedOrder == 0 and #created == 0 then
			return
		end
		applied = false
		for index = #savedOrder, 1, -1 do
			local entry = savedOrder[index]
			local ok, err = pcall(function()
				entry.effect[entry.prop] = entry.value
			end)
			if not ok then
				fail("could not restore " .. entry.key .. ": " .. tostring(err))
			end
			savedOrder[index] = nil
		end
		for index = #created, 1, -1 do
			local instance = created[index]
			pcall(function()
				instance:Destroy()
			end)
			created[index] = nil
		end
		publishFailures()
	end

	return { apply = apply, restore = restore }
end

for _, key in ipairs(Data.order) do
	local applier = make(key)
	LookDevGradeR8.appliers[key] = applier
	LookDev.register(Data.idPrefix .. key, applier)
end

return LookDevGradeR8
