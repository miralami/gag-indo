-- CutsceneHooks: lightweight state/event hooks for NPC-driven cutscenes (logic only).
-- Raid and debt-collector flows can emit phase/state events here so future cutscene
-- directors subscribe without assets or Studio-only tooling.

local CutsceneHooks = {}

export type RaidEvent = {
	kind: "raid",
	player: Player,
	phase: string,
	isViral: boolean?,
	outcome: string?,
}

export type DebtEvent = {
	kind: "debt_collector",
	player: Player,
	state: "summoned" | "dismissed",
	waiting: boolean,
}

local raidListeners: { (RaidEvent) -> () } = {}
local debtListeners: { (DebtEvent) -> () } = {}

function CutsceneHooks.onRaid(listener: (RaidEvent) -> ())
	table.insert(raidListeners, listener)
	return function()
		local index = table.find(raidListeners, listener)
		if index then
			table.remove(raidListeners, index)
		end
	end
end

function CutsceneHooks.onDebtCollector(listener: (DebtEvent) -> ())
	table.insert(debtListeners, listener)
	return function()
		local index = table.find(debtListeners, listener)
		if index then
			table.remove(debtListeners, index)
		end
	end
end

function CutsceneHooks.emitRaid(event: RaidEvent)
	for _, listener in raidListeners do
		local ok, err = pcall(listener, event)
		if not ok then
			warn("CutsceneHooks listener failed: " .. tostring(err))
		end
	end
end

function CutsceneHooks.emitDebtCollector(event: DebtEvent)
	for _, listener in debtListeners do
		local ok, err = pcall(listener, event)
		if not ok then
			warn("CutsceneHooks listener failed: " .. tostring(err))
		end
	end
end

function CutsceneHooks._reset()
	table.clear(raidListeners)
	table.clear(debtListeners)
end

return CutsceneHooks
