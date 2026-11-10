-- Village: finds the tagged village and attaches behaviour (v2 PLAN §3.1).
--
-- It no longer builds layout. If the place file has a designer map (VillageWorld tag) or
-- plot anchors, that map wins. Otherwise World/Greybox.luau generates the v1 greybox and
-- tags it the same way, so both paths behave identically.
--
-- Prompt tags (localized by the client in Tiles.luau):
--   PasarPrompt, GelapPrompt, PakRTPrompt, PolisiPrompt, WarungPrompt.
-- NPC models: NpcSpawn with attribute Npc = "pakrt" | "tengkulak" | "polisi".

local Map = require(script.Parent.Map)
local Greybox = require(script.Parent.Greybox)
local NpcFactory = require(script.Parent.NpcFactory)

local Village = {}

Village.DEFAULT_POSITIONS = {
	pasar = Vector3.new(0, 2, 3),
	gelap = Vector3.new(0, 2, -14),
	pakrt = Vector3.new(30, 3, 16),
	polisi = Vector3.new(-30, 2, 22),
	ronda = Vector3.new(-30, 2, -26),
	warung = Vector3.new(30, 2, -20),
}

Village.positions = table.clone(Village.DEFAULT_POSITIONS)
Village.prompts = {} :: { [string]: ProximityPrompt }
Village.pakrt = nil :: any
Village.tengkulak = nil :: any
Village.police = {} :: { any }
-- Handlers registered by services in start(); declared here so the type checker sees them.
Village._pasarHandler = nil :: any
Village._bribeHandler = nil :: any
Village._reportHandler = nil :: any
Village._warungHandler = nil :: any

local npcCache: { [Model]: any } = {}

-- Prompt tag -> the name used for distance checks, the handler field, and the sale channel.
local PROMPT_BINDINGS = {
	{ tag = Map.TAGS.Pasar, name = "pasar", field = "_pasarHandler", channel = "pasar" },
	{ tag = Map.TAGS.Gelap, name = "gelap", field = "_pasarHandler", channel = "gelap" },
	{ tag = Map.TAGS.PakRT, name = "pakrt", field = "_bribeHandler" },
	{ tag = Map.TAGS.Polisi, name = "polisi", field = "_reportHandler" },
	{ tag = Map.TAGS.Warung, name = "warung", field = "_warungHandler" },
}

local function instancePosition(instance: Instance?): Vector3?
	if not instance then
		return nil
	end
	if instance:IsA("BasePart") then
		return instance.Position
	end
	if instance:IsA("Model") then
		local ok, pivot = pcall(function()
			return instance:GetPivot()
		end)
		if ok and pivot then
			return pivot.Position
		end
	end
	local part = instance:FindFirstChildWhichIsA("BasePart", true)
	return if part then part.Position else nil
end

local function bindPrompts()
	for _, binding in PROMPT_BINDINGS do
		for _, prompt in Map.all(binding.tag) do
			if prompt:IsA("ProximityPrompt") and not prompt:GetAttribute("Bound") then
				prompt:SetAttribute("Bound", true)
				Village.prompts[binding.name] = prompt
				local position = instancePosition(prompt.Parent)
				if position then
					Village.positions[binding.name] = position
				end
				prompt.Triggered:Connect(function(player)
					local handler = Village[binding.field]
					if handler then
						handler(player, binding.channel)
					end
				end)
			elseif prompt:IsA("ProximityPrompt") then
				Village.prompts[binding.name] = prompt
			end
		end
	end

	for _, anchor in Map.all(Map.TAGS.Ronda) do
		local position = instancePosition(anchor)
		if position then
			Village.positions.ronda = position
			break
		end
	end
end

local function bindNpcs()
	Village.pakrt = nil
	Village.tengkulak = nil
	Village.police = {}

	for _, model in Map.all(Map.TAGS.Npc) do
		if model:IsA("Model") then
			local npc = npcCache[model]
			if not npc then
				npc = NpcFactory.wrap(model)
				npcCache[model] = npc
			end
			local role = model:GetAttribute("Npc")
			if role == "pakrt" then
				Village.pakrt = npc
			elseif role == "tengkulak" then
				Village.tengkulak = npc
			elseif role == "polisi" then
				table.insert(Village.police, npc)
			end
		end
	end

	-- Clean the cache when a designer replaces the map.
	for model in npcCache do
		if not model.Parent then
			npcCache[model] = nil
		end
	end
end

-- Re-read tags and attach behaviour. Safe to call again after a Studio hot reload.
function Village.bind()
	Village.positions = table.clone(Village.DEFAULT_POSITIONS)
	Village.prompts = {}
	bindPrompts()
	bindNpcs()
	return Village
end

function Village.build()
	if not Map.isDesignerWorld() then
		Greybox.build()
	end
	Village.bind()
	return Village
end

function Village.onPasar(handler: (Player, string) -> ())
	Village._pasarHandler = handler
end

function Village.onBribe(handler: (Player) -> ())
	Village._bribeHandler = handler
end

function Village.onReport(handler: (Player) -> ())
	Village._reportHandler = handler
end

function Village.onWarung(handler: (Player) -> ())
	Village._warungHandler = handler
end

function Village.getPosition(name: string): Vector3
	return Village.positions[name] or Vector3.new(0, 0, 0)
end

function Village.getWorld(): Instance?
	local tagged = Map.first(Map.TAGS.World)
	if tagged then
		return tagged
	end
	return workspace:FindFirstChild("World")
end

return Village
