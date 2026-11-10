-- Traits ("Sifat") that stack on a produce stack (v2 PLAN §3.2).
-- M0 defines the vocabulary and migrates the old `hot` flag to the "oplosan" trait, so
-- saves already carry traits before the rarity/trait roll exists in M1.
--
-- `hot` means "the Pasar refuses it and the Tengkulak Gelap buys it"; the raid confiscates
-- stacks with this trait, exactly like the v1 `hot` sack did.

export type Trait = {
	hot: boolean?,
	labelKey: string,
}

local Traits = {}

Traits.order = { "oplosan", "basah", "kering", "organik", "bersertifikat" }

Traits.list = {
	oplosan = { hot = true, labelKey = "trait_oplosan" },
	basah = { labelKey = "trait_basah" },
	kering = { labelKey = "trait_kering" },
	organik = { labelKey = "trait_organik" },
	bersertifikat = { labelKey = "trait_bersertifikat" },
} :: { [string]: Trait }

Traits.hotTrait = "oplosan"

function Traits.exists(traitId: any): boolean
	return type(traitId) == "string" and Traits.list[traitId] ~= nil
end

return Traits
