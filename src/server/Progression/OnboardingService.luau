-- OnboardingService: owns `data.tutorial`, the guided first session (v2 PLAN §3.1).
--
-- The owner of an action calls `advance(player, stepId)` after the action really succeeded:
-- FarmService after a plant/harvest, EconomyService after a sale, ShopService after a purchase.
-- Only the current step counts, so a player who sells something before planting still gets the
-- plant objective first; doing it twice changes nothing.
--
-- The HUD reads `TutorialStep`; the section is replicated like every other one.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Onboarding = require(Shared.Config.Onboarding)

local PlayerData = require(script.Parent.Parent.Data.PlayerData)
local Notify = require(script.Parent.Parent.Net.Notify)
local State = require(script.Parent.Parent.Net.State)

local OnboardingService = {}

local function blank(): { step: number, done: { [string]: boolean } }
	return { step = 1, done = {} }
end

-- Repairs a missing or malformed table without losing completed steps.
function OnboardingService.ensure(data): any
	if not data then
		return nil
	end
	local tutorial = data.tutorial
	if type(tutorial) ~= "table" then
		tutorial = blank()
		data.tutorial = tutorial
	end
	if type(tutorial.done) ~= "table" then
		tutorial.done = {}
	end
	local step = tonumber(tutorial.step)
	if not step or step ~= math.floor(step) or step < 1 then
		step = 1
	end
	tutorial.step = math.min(step, Onboarding.total + 1)
	return tutorial
end

-- The step the player is on, or nil when the tutorial is finished.
function OnboardingService.current(data): any?
	local tutorial = OnboardingService.ensure(data)
	if not tutorial then
		return nil
	end
	return Onboarding.steps[tutorial.step]
end

function OnboardingService.finished(data): boolean
	local tutorial = OnboardingService.ensure(data)
	return tutorial ~= nil and tutorial.step > Onboarding.total
end

function OnboardingService.publish(player: Player, data)
	local step = OnboardingService.current(data)
	player:SetAttribute("TutorialStep", if step then step.id else "")
end

-- Marks the current step done when `stepId` is the one expected. Returns true when it advanced.
function OnboardingService.advance(player: Player, stepId: any): boolean
	if not Onboarding.exists(stepId) then
		return false
	end
	local data = PlayerData.get(player)
	if not data then
		return false
	end
	local tutorial = OnboardingService.ensure(data)
	local step = Onboarding.steps[tutorial.step]
	if not step or step.id ~= stepId then
		return false
	end

	tutorial.done[stepId] = true
	tutorial.step += 1
	OnboardingService.publish(player, data)
	State.touch(player, "tutorial")

	Notify.send(player, "n_tutorial_step", "@" .. step.labelKey)
	if tutorial.step > Onboarding.total then
		Notify.send(player, "n_tutorial_finished")
	end
	return true
end

function OnboardingService.start()
	PlayerData.onLoaded(function(player, data)
		OnboardingService.ensure(data)
		OnboardingService.publish(player, data)
		State.touch(player, "tutorial")
	end)
end

return OnboardingService
