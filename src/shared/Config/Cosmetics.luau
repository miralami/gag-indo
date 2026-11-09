-- Cosmetic shop (GDD §9.3). v1 uses cash so the shop is testable without Robux;
-- swap `price` for a Robux purchase flow later without touching the UI.
-- `kind` decides how the client renders it on the character.

export type Cosmetic = {
	price: number,
	kind: string, -- "hat" | "shirt"
	color: Color3,
}

local Cosmetics = {}

Cosmetics.order = { "caping", "peci", "batik" }

Cosmetics.list = {
	caping = { price = 250, kind = "hat", color = Color3.fromRGB(222, 196, 120) },
	peci = { price = 750, kind = "hat", color = Color3.fromRGB(25, 25, 30) },
	batik = { price = 1200, kind = "shirt", color = Color3.fromRGB(90, 60, 140) },
} :: { [string]: Cosmetic }

return Cosmetics
