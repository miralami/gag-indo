--!strict
-- Saved adzan toggle for the day-cycle sound beds (WORK_QUEUE round 3 item 25). Pure: helpers
-- read/write one boolean in a ProfileStore profile.Data table, keyed by DayCycle's own key.
-- A missing or damaged persisted value is treated as ON, so shipping behaviour never silences
-- adzan by accident. No Roblox services, no remotes, no asset IDs.

local DayCycle = require(script.Parent.Parent.World.DayCycle)

local AdzanSetting = {}

AdzanSetting.KEY = DayCycle.ADZAN_SETTING_KEY
AdzanSetting.DEFAULT_ON = true
AdzanSetting.VOLUME = 0.12 -- LOW: the softest bed in the mix

local function booleanOf(value: any): boolean?
	if type(value) == "boolean" then
		return value
	elseif value == 1 then
		return true
	elseif value == 0 then
		return false
	elseif type(value) == "string" then
		local text = string.lower(value)
		if text == "on" or text == "true" or text == "1" then
			return true
		elseif text == "off" or text == "false" or text == "0" then
			return false
		end
	end
	return nil
end

-- Missing, non-table, NaN and unknown strings all degrade to the shipped default (ON).
function AdzanSetting.read(profileData: any): boolean
	if type(profileData) ~= "table" then
		return AdzanSetting.DEFAULT_ON
	end
	local value = booleanOf(profileData[AdzanSetting.KEY])
	return if value == nil then AdzanSetting.DEFAULT_ON else value
end

-- Writes only a valid boolean-ish value; leaves damaged data untouched and reports failure.
function AdzanSetting.write(profileData: any, enabled: any): boolean
	if type(profileData) ~= "table" then
		return false
	end
	local value = booleanOf(enabled)
	if value == nil then
		return false
	end
	profileData[AdzanSetting.KEY] = value
	return true
end

return AdzanSetting
