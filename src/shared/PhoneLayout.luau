-- PhoneLayout: pure layout rules for the in-game phone UI (Track D).
-- Used by client UI and by Lune specs to keep phone-size targets consistent.

local PhoneLayout = {}

PhoneLayout.touchMin = 44
PhoneLayout.homeBarHeight = 44
PhoneLayout.appGridCellMinHeight = 88
PhoneLayout.rowMinHeight = 44
PhoneLayout.sectionLabelHeight = 26
PhoneLayout.buttonHeight = 44
PhoneLayout.smallButtonHeight = 44
PhoneLayout.textPadding = 8

-- Interactive elements that must meet the touch target on at least one axis/area.
-- Heights/widths are minimums in pixels.
PhoneLayout.controls = {
	headerBack = { minWidth = 44, minHeight = 44 },
	headerLang = { minWidth = 44, minHeight = 44 },
	headerClose = { minWidth = 44, minHeight = 44 },
	homeBar = { minHeight = 44 },
	phoneToggle = { minWidth = 44, minHeight = 64 },
	appTile = { minHeight = 88 },
	listButton = { minHeight = 44 },
}

function PhoneLayout.meetsTouch(size: { minWidth: number?, minHeight: number? }?): boolean
	if not size then
		return false
	end
	local w = size.minWidth or 0
	local h = size.minHeight or 0
	return w >= PhoneLayout.touchMin or h >= PhoneLayout.touchMin
end

function PhoneLayout.allControlsMeetTouch(): boolean
	for _, control in PhoneLayout.controls do
		if not PhoneLayout.meetsTouch(control) then
			return false
		end
	end
	return true
end

return PhoneLayout
