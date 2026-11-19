--!strict
-- FpsSampler: pure rolling frame-time -> fps helper for the Studio-only perf sampling (V0.2).
-- No Roblox APIs so tests/specs/fps_sampler_spec.luau can drive it with plain numbers. The live
-- wiring (RenderStepped -> push(dt), publish attribute) is a thin caller in FpsSampler.start().
--
-- Bad frame times (non-number, NaN, <= 0, or an absurd > 2 s pause) are ignored so a tab-out does
-- not poison the average. fps() is nil until at least `minSamples` clean frames have arrived.

local FpsSampler = {}

local MAX_FRAME_TIME = 2

function FpsSampler.new(windowSize: number?, minSamples: number?)
	local size = windowSize or 60
	local minN = minSamples or 20
	local self = {}
	local samples = {}
	local sum = 0

	function self.push(dt: any)
		if type(dt) ~= "number" or dt ~= dt or dt <= 0 or dt > MAX_FRAME_TIME then
			return
		end
		samples[#samples + 1] = dt
		sum += dt
		if #samples > size then
			sum -= (table.remove(samples, 1) :: number)
		end
	end

	function self.averageFrameTime(): number?
		if #samples < minN then
			return nil
		end
		return sum / #samples
	end

	function self.fps(): number?
		local avg = self.averageFrameTime()
		if not avg or avg <= 0 then
			return nil
		end
		return 1 / avg
	end

	function self.count(): number
		return #samples
	end

	function self.reset()
		samples = {}
		sum = 0
	end

	return self
end

-- Studio-only live wiring. Publishes the smoothed fps to the local Player attribute "ClientFps".
-- In a published place this is a no-op: nothing is connected and nothing is written.
function FpsSampler.start(opts: any?)
	opts = opts or {}
	local RunService = opts.runService or game:GetService("RunService")
	local isStudio = opts.isStudio
	if isStudio == nil then
		local ok, value = pcall(function()
			return RunService:IsStudio()
		end)
		isStudio = ok and value == true
	end
	if not isStudio then
		return function() end
	end

	local Players = opts.players or game:GetService("Players")
	local player = opts.player or Players.LocalPlayer
	local sampler = FpsSampler.new(opts.windowSize, opts.minSamples)
	local lastPublish = 0
	local conn = RunService.RenderStepped:Connect(function(dt)
		sampler.push(dt)
		local now = os.clock()
		if now - lastPublish >= 0.5 then
			lastPublish = now
			local fps = sampler.fps()
			if fps and player and player.SetAttribute then
				pcall(function()
					player:SetAttribute("ClientFps", math.floor(fps * 10 + 0.5) / 10)
				end)
			end
		end
	end)
	return function()
		conn:Disconnect()
		sampler.reset()
	end
end

return FpsSampler
