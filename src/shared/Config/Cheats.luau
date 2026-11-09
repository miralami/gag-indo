-- Cheat table (GDD §4). Every shortcut must be clearly profitable.
-- `evidenceValue` is what a witness can report (the reward is a share of it).

export type Cheat = {
	label: string,
	sus: number,
	cost: number,
	evidenceValue: number,
	growBonus: number?, -- oplosan
	priceMultiplier: number?, -- gelap
	shiftSeconds: number?, -- curi_air
	cooldown: number?, -- curi_air, per victim
}

local Cheats = {}

Cheats.list = {
	-- Pupuk oplosan: ripens the crop faster, but the produce stays "hot".
	oplosan = {
		label = "cheat_oplosan",
		sus = 15,
		cost = 20,
		growBonus = 0.40, -- remove 40% of the remaining time
		evidenceValue = 20,
	},
	-- Jual ke tengkulak gelap: +30% price, sells hot produce too.
	gelap = {
		label = "cheat_gelap",
		sus = 20,
		cost = 0,
		priceMultiplier = 1.3,
		evidenceValue = 0, -- filled in with the extra profit at sale time
	},
	-- Curi air: the attacker's crops speed up, the victim's slow down.
	curi_air = {
		label = "cheat_curi_air",
		sus = 10,
		cost = 0,
		shiftSeconds = 30,
		cooldown = 300, -- per victim, 5 minutes
		evidenceValue = 20,
	},
} :: { [string]: Cheat }

Cheats.order = { "oplosan", "curi_air" }

return Cheats
