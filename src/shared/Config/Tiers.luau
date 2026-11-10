-- Rarity tiers (v2 PLAN §3.2). Rolled by the server on harvest; the multiplier applies
-- on top of the crop's base sell price. M0 ships the table only: every stack is "biasa"
-- until RarityService lands in M1.
--
-- Keep colours here so the client can tint a stack without a second config file.

export type Tier = {
	chance: number, -- roll weight when the rarity roll is wired (sums to 1.0)
	valueMultiplier: number,
	color: Color3,
	labelKey: string,
}

local Tiers = {}

Tiers.default = "biasa"
Tiers.order = { "biasa", "bagus", "super", "langka", "sultan" }

Tiers.list = {
	biasa = {
		chance = 0.70,
		valueMultiplier = 1,
		color = Color3.fromRGB(210, 210, 210),
		labelKey = "tier_biasa",
	},
	bagus = {
		chance = 0.20,
		valueMultiplier = 1.5,
		color = Color3.fromRGB(110, 210, 110),
		labelKey = "tier_bagus",
	},
	super = {
		chance = 0.075,
		valueMultiplier = 3,
		color = Color3.fromRGB(80, 160, 255),
		labelKey = "tier_super",
	},
	langka = {
		chance = 0.02,
		valueMultiplier = 8,
		color = Color3.fromRGB(190, 110, 255),
		labelKey = "tier_langka",
	},
	sultan = {
		chance = 0.005,
		valueMultiplier = 25,
		color = Color3.fromRGB(255, 190, 40),
		labelKey = "tier_sultan",
	},
} :: { [string]: Tier }

function Tiers.exists(tierId: any): boolean
	return type(tierId) == "string" and Tiers.list[tierId] ~= nil
end

function Tiers.multiplier(tierId: string?): number
	local tier = if tierId then Tiers.list[tierId] else nil
	return if tier then tier.valueMultiplier else 1
end

return Tiers
