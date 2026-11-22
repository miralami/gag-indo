-- DebtCollector: the visible "kolektor" that waits at an overdue player's plot.
--
-- DebtService owns WHEN a collector is needed; this module owns the world object. It is bound
-- once in Main.server so DebtService never has to require PlotService (keeps the graph acyclic
-- and lets tests inject a fake collector instead of building parts).
--
-- The model is deliberately a greybox marker: the Week 5 art pass replaces it with a real model
-- while keeping the name and the "DebtCollectorFor" attribute.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Strings = require(Shared.Strings)

local PlotService = require(script.Parent.Parent.Farm.PlotService)
local Props = require(script.Parent.Parent.World.Props)
local NpcWalk = require(script.Parent.Parent.World.NpcWalk)
local CutsceneHooks = require(script.Parent.Parent.Npc.CutsceneHooks)

local DebtCollector = {}

local parts: { [Player]: BasePart } = {}

local function language(player: Player): string
	local locale = (player :: any).LocaleId
	if type(locale) == "string" and string.sub(locale, 1, 2) == "en" then
		return "en"
	end
	return "id"
end

-- Idempotent: asking twice for the same player keeps the one collector.
function DebtCollector.summon(player: Player)
	if parts[player] then
		return
	end
	local plot = PlotService.getPlotOf(player)
	if not plot then
		return
	end

	local part = Props.part({
		Name = "DebtCollector",
		Size = Vector3.new(2, 5, 2),
		CFrame = plot.spawnCFrame * CFrame.new(5, 2.5, 0),
		Color = Color3.fromRGB(46, 42, 52),
		Material = Enum.Material.SmoothPlastic,
		CanCollide = false,
	})
	part:SetAttribute("DebtCollectorFor", player.UserId)
	local label = Props.billboard(part, 3.4, Vector2.new(150, 36), {
		name = "CollectorLabel",
		alwaysOnTop = true,
		maxDistance = 120,
	})
	label.Text = Strings.get(language(player), "debt_collector_tag")
	part.Parent = game:GetService("Workspace")
	parts[player] = part
	-- Walk the collector from its spawn offset to the plot so it visibly arrives (item 18). The
	-- shared walker adds stuck/timeout detection with a teleport fallback, so the collector reaches
	-- the plot for every plot position. Fake parts without a pivot API degrade to a no-op.
	local target = plot.spawnCFrame and plot.spawnCFrame.Position
	if target then
		task.spawn(function()
			NpcWalk.walkTo(part, target, 8)
		end)
	end
	CutsceneHooks.emitDebtCollector({ kind = "debt_collector", player = player, state = "summoned", waiting = true })
end

function DebtCollector.dismiss(player: Player)
	local part = parts[player]
	if not part then
		return
	end
	parts[player] = nil
	part:Destroy()
	CutsceneHooks.emitDebtCollector({ kind = "debt_collector", player = player, state = "dismissed", waiting = false })
end

function DebtCollector.isWaiting(player: Player): boolean
	return parts[player] ~= nil
end

return DebtCollector
