--!strict
-- DELIBERATELY BAD — calibration fixture for item 217; never promoted.
-- Pure descriptor data for proving review_check_visual.luau FAILs on known visual risks.

local Fixture = {}

Fixture.id = "visual_fixture_bad"
Fixture.folderName = "LookDevVisualFixtureBad_visual_fixture_bad"

function Fixture.parts()
	return {
		-- One clearly-good cluster: two touching parts at the origin.
		{ name = "GoodBase", shape = "Ball", size = { 2, 2, 2 }, position = { 0, 0, 0 } },
		{ name = "GoodNeighbour", shape = "Ball", size = { 2, 2, 2 }, position = { 2, 0, 0 } },
		-- (a) isolated floater.
		{ name = "FloatingRock", size = { 3, 3, 3 }, position = { 0, 40, 0 } },
		-- (b) cube shrub.
		{ name = "CubeShrub", shape = "Block", size = { 2, 2, 2 }, position = { 50, 0, 50 } },
		-- (c) overlong thin bar with no exempt kind or name.
		{ name = "LongThinBar", size = { 20, 0.4, 0.4 }, position = { 100, 0, 100 } },
	}
end

return Fixture
