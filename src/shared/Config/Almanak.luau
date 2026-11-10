-- Almanak pages (v2 PLAN §3.2). One page per crop family; a page completes when every
-- crop in the family has been discovered at least once (any tier, any trait).
--
-- Completing a page grants the cosmetic in `reward` for free. Cosmetics are cash-bought in
-- v1, so the reward is deliberately one of the existing items instead of a new asset.

export type Page = {
	family: string,
	reward: string,
	labelKey: string,
}

local Almanak = {}

Almanak.order = { "palawija", "kebun", "perkebunan" }

Almanak.pages = {
	palawija = { family = "palawija", reward = "caping", labelKey = "almanak_page_palawija" },
	kebun = { family = "kebun", reward = "batik", labelKey = "almanak_page_kebun" },
	perkebunan = { family = "perkebunan", reward = "peci", labelKey = "almanak_page_perkebunan" },
} :: { [string]: Page }

function Almanak.exists(pageId: any): boolean
	return type(pageId) == "string" and Almanak.pages[pageId] ~= nil
end

return Almanak
