-- Traits ("Sifat") that stack on a produce stack (v2 PLAN §3.2).
-- M0 defined the vocabulary and migrated the old `hot` flag to the "oplosan" trait; M1
-- rolls the condition-driven traits on harvest (see server/Farm/TraitService.luau).
--
-- `hot` means "the Pasar refuses it and the Tengkulak Gelap buys it"; the raid confiscates
-- stacks with this trait, exactly like the v1 `hot` sack did.
--
-- `condition` is what has to be true before the trait can roll:
--   rain          harvested during hujan/badai
--   elNino        harvested while the El Nino anomaly is live
--   unfertilised  the plot never had fertiliser this cycle
--   certified     the player applied a Balai Desa stamp
-- `chance` is the roll once the condition is met (1 = always).

export type Trait = {
	hot: boolean?,
	labelKey: string,
	condition: string?,
	chance: number?,
}

local Traits = {}

Traits.order = { "oplosan", "basah", "kering", "organik", "bersertifikat" }

Traits.list = {
	oplosan = { hot = true, labelKey = "trait_oplosan" },
	basah = { condition = "rain", chance = 0.35, labelKey = "trait_basah" },
	kering = { condition = "elNino", chance = 0.35, labelKey = "trait_kering" },
	organik = { condition = "unfertilised", chance = 0.30, labelKey = "trait_organik" },
	bersertifikat = { condition = "certified", chance = 1, labelKey = "trait_bersertifikat" },
} :: { [string]: Trait }

Traits.hotTrait = "oplosan"

function Traits.exists(traitId: any): boolean
	return type(traitId) == "string" and Traits.list[traitId] ~= nil
end

function Traits.isHot(traitId: any): boolean
	local trait = if type(traitId) == "string" then Traits.list[traitId] else nil
	return trait ~= nil and trait.hot == true
end

return Traits
