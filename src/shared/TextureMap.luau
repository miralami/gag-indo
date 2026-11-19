--!strict
-- TextureMap: uploaded agent-made texture CANDIDATES for Visuals.textures (WORK_QUEUE round 2
-- item 5). All 7 are LookDev candidates AWAITING DESIGNER YES/NO — none approved, none shipped on
-- by default. The uploaded IDs live here, NOT in LookDev or its adapters, so LookDev's "no asset
-- IDs" spec guard still holds. See docs/v2/visual/CANDIDATES.md and ASSET_MANIFEST.md.
--
-- The shipping config keeps every Visuals.textures slot at 0 (built-in material + palette colour
-- fallback). Only src/client/World/LookDevTextures.luau swaps these in, and only while the
-- Studio-only "textures" candidate is enabled; disable() restores every slot to 0.

local TextureMap = {}

TextureMap.candidateIds = {
	bambu = 86020876968095,
	genteng = 121899778984239,
	seng = 116077927961929,
	paving = 70537329110423,
	sawah = 121312141770783,
	kertas = 102834761172815,
	tanah = 95694392312399,
}

-- Part-name keyword -> texture slot. Same category vocabulary as LookDevPlaza so the two
-- candidates compose predictably; unknown parts are left untouched.
TextureMap.categorySlots = {
	ground = "tanah",
	road = "paving",
	wood = "bambu",
	roof = "genteng",
	metal = "seng",
	field = "sawah",
	sign = "kertas",
}

-- Built-in material used under a texture while it is applied (Visuals.materials fallback).
-- Stored as a name string so this module stays pure data and Lune-testable.
TextureMap.fallbackMaterials = {
	bambu = "Wood",
	genteng = "Slate",
	seng = "Metal",
	paving = "Concrete",
	sawah = "Grass",
	kertas = "Fabric",
	tanah = "Ground",
}

local useCandidates = false

-- Applier entry point for the "textures" LookDev candidate. `on=false` restores every slot
-- to 0 so the built-in material + colour fallback returns.
function TextureMap.applyCandidates(visuals: any, on: boolean)
	useCandidates = on == true
	if type(visuals) ~= "table" or type(visuals.textures) ~= "table" then
		return
	end
	for slot, id in TextureMap.candidateIds do
		visuals.textures[slot] = if useCandidates then id else 0
	end
end

function TextureMap.usingCandidates(): boolean
	return useCandidates
end

return TextureMap
