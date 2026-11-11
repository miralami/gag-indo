-- Guided first session (v2 PLAN §3.1). The steps are shown in order; each one only completes
-- when the matching action really happened on the server.
--
-- The tutorial never mentions cheating: the cheat menu is discovered, not assigned (§4.4).
-- Adding a step is a data edit plus a string and one `advance` call from the owning service.

local Onboarding = {}

Onboarding.steps = {
	{ id = "plant", labelKey = "tutorial_plant" },
	{ id = "harvest", labelKey = "tutorial_harvest" },
	{ id = "sell", labelKey = "tutorial_sell" },
	{ id = "buy", labelKey = "tutorial_buy" },
}

Onboarding.index = {}

for position, step in Onboarding.steps do
	Onboarding.index[step.id] = position
end

Onboarding.total = #Onboarding.steps

function Onboarding.exists(stepId: any): boolean
	return type(stepId) == "string" and Onboarding.index[stepId] ~= nil
end

return Onboarding
