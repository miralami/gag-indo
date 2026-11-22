--!strict
-- LookDevSignpostsR10: SERVER-ONLY applier for the OFF-BY-DEFAULT "signposts_r10" candidate
-- (WORK_QUEUE item 203). Stages four anchored, non-collidable wooden signposts at the ring-road
-- junctions; each board carries a SurfaceGui TextLabel whose Text is the id text from Shared.Strings
-- at apply time. Geometry, palette and text keys come from Shared.ModelMapSignpostsR10; no asset IDs
-- or visual verdict live here. Only instances created here are destroyed, in LIFO order; apply/restore
-- are idempotent and pcall-guarded throughout.
-- Enable from the Server command bar:
--   require(game.ReplicatedStorage.Shared.LookDevReview).enableAdditive("signposts_r10", game)

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevSignpostsR10] missing service " .. name)
		return nil
	end
	return value
end

local ReplicatedStorage = service("ReplicatedStorage")
local Workspace = service("Workspace")
if not ReplicatedStorage or not Workspace then
	return {}
end

local Shared: any? = nil
local okShared, sharedFolder = pcall(function()
	return (ReplicatedStorage :: any):WaitForChild("Shared")
end)
if okShared and sharedFolder then
	Shared = sharedFolder
else
	warn("[LookDevSignpostsR10] missing Shared folder")
	return {}
end

local okModules, LookDev, Data, LookDevFailures, Strings = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapSignpostsR10),
		require((Shared :: any).LookDevFailures),
		require((Shared :: any).Strings)
end)
if not okModules or not LookDev or not Data or not LookDevFailures or not Strings then
	warn("[LookDevSignpostsR10] could not require LookDev / ModelMapSignpostsR10 / LookDevFailures / Strings")
	return {}
end

local LookDevSignpostsR10 = {}

local FAMILY_ID = Data.id
local STAGE_ATTR = "LookDevStage"

local failures = 0
local active = false
local created: { any } = {}

local function fail(message: string)
	failures += 1
	warn("[LookDevSignpostsR10] " .. message)
end

local function publishFailures()
	pcall(function()
		LookDevFailures.set(FAMILY_ID, failures)
	end)
end

local function track(instance: any)
	created[#created + 1] = instance
end

local function stageFolder(): any?
	local okFind, existing = pcall(function()
		return (Workspace :: any):FindFirstChild((Data :: any).folderName)
	end)
	if not okFind then
		fail("could not look up staging folder: " .. tostring(existing))
		return nil
	end
	if existing then
		return existing
	end
	local okNew, instance = pcall(function()
		return (Instance :: any).new("Folder")
	end)
	if not okNew or not instance then
		fail("could not create staging folder: " .. tostring(instance))
		return nil
	end
	local okParent, why = pcall(function()
		instance.Name = (Data :: any).folderName
		instance.Parent = Workspace
	end)
	if not okParent then
		pcall(function()
			instance:Destroy()
		end)
		fail("could not parent staging folder: " .. tostring(why))
		return nil
	end
	track(instance)
	return instance
end

local function stagePart(descriptor: any, parent: any, signDescriptor: any?): any?
	local okPart, part = pcall(function()
		local instance = (Instance :: any).new("Part")
		instance.Size = Vector3.new(descriptor.size[1], descriptor.size[2], descriptor.size[3])
		instance.CFrame = CFrame.new(descriptor.position[1], descriptor.position[2], descriptor.position[3])
			* CFrame.Angles(0, math.rad(descriptor.yaw), 0)
		instance.Color = Color3.fromRGB(descriptor.color.r, descriptor.color.g, descriptor.color.b)
		instance.Anchored = true
		instance.CanCollide = false
		instance.CastShadow = false
		instance.Name = descriptor.name
		-- Only the board is tagged: one tagged instance per sign keeps the Studio audit's
		-- text and readability counts at exactly four.
		if descriptor.kind == "board" and signDescriptor then
			instance:SetAttribute("Signpost", true)
			instance:SetAttribute("sign", signDescriptor.index)
			instance:SetAttribute("textKey", signDescriptor.textKey)
			instance:SetAttribute("fontSizePx", signDescriptor.fontSizePx)
			instance:SetAttribute(STAGE_ATTR, FAMILY_ID)
		end
		return instance
	end)
	if not okPart or not part then
		fail("could not build " .. tostring(descriptor and descriptor.name) .. ": " .. tostring(part))
		return nil
	end
	track(part)
	local okParent, why = pcall(function()
		part.Parent = parent
	end)
	if not okParent then
		fail("could not parent " .. tostring(descriptor.name) .. ": " .. tostring(why))
	end
	return part
end

local function addSignText(board: any, signDescriptor: any)
	local ok = pcall(function()
		local gui = (Instance :: any).new("SurfaceGui")
		gui.Name = "SignFace"
		gui.Face = Enum.NormalId.Front
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 8 -- 18 px reads at ~2.25 studs tall, clear from 12 studs away
		gui.LightInfluence = 0
		local label = (Instance :: any).new("TextLabel")
		label.Name = "SignText"
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.TextScaled = false
		label.TextSize = signDescriptor.fontSizePx
		label.TextColor3 = Color3.fromRGB(48, 34, 24)
		label.Text = Strings.get("id", signDescriptor.textKey)
		label.Parent = gui
		gui.Parent = board
		track(label)
		track(gui)
	end)
	if not ok then
		fail("could not write sign text for " .. tostring(signDescriptor.textKey))
	end
end

local function apply(_plan: any)
	if active then
		return
	end
	failures = 0

	local root = stageFolder()
	if root then
		local okParts, parts = pcall(function()
			return (Data :: any).parts()
		end)
		if not okParts or type(parts) ~= "table" then
			fail("could not read sign descriptors: " .. tostring(parts))
		else
			local byIndex = {}
			local okSigns, signs = pcall(function()
				return (Data :: any).SIGNS
			end)
			if not okSigns or type(signs) ~= "table" then
				fail("could not read sign descriptors: " .. tostring(signs))
			else
				for _, descriptor in ipairs(signs) do
					byIndex[descriptor.index] = descriptor
				end
			end
			for _, descriptor in ipairs(parts) do
				local signDescriptor = byIndex[descriptor.signIndex]
				local board = stagePart(descriptor, root, signDescriptor)
				if descriptor.kind == "board" and board then
					if signDescriptor then
						addSignText(board, signDescriptor)
					else
						fail("missing sign descriptor for part " .. tostring(descriptor.name))
					end
				end
			end
		end
	end

	active = true
	publishFailures()
end

local function restore()
	if not active and #created == 0 then
		return
	end
	for index = #created, 1, -1 do
		local instance = created[index]
		pcall(function()
			instance:Destroy()
		end)
		created[index] = nil
	end
	active = false
	publishFailures()
end

LookDevSignpostsR10.apply = apply
LookDevSignpostsR10.restore = restore

LookDev.register(FAMILY_ID, { apply = apply, restore = restore })

return LookDevSignpostsR10
