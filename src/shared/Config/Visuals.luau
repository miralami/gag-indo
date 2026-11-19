--!strict
-- Visuals: the single source for palette, type, spacing, outline/shadow and icon slots.
-- ART.md §3 (palette), §8 (type, spacing), §7 (icons). Pure data so Lune tests can read it.
-- Colours are hex strings; UI code converts them with Color3.fromHex.

local Visuals = {}

-- ART.md §3. Keep this list in sync with the art bible; add new colours there first.
Visuals.palette = {
	kertas = "f3e9d2",
	tinta = "2b2118",
	tinta_lembut = "5b4a38",
	senja = "f6c97a",
	padi = "9bb25a",
	daun = "6f8a3f",
	genteng = "a8452f",
	merah = "a83226",
	bambu = "b98a5a",
	kunyit = "c99a2e",
	indigo = "3b4f6b",
	malam = "1f4e6b",
	ungu = "7652a8",
}

-- ART.md §7: shared rarity presentation tokens, keyed by tier id.
Visuals.rarity = {
	biasa = { token = "tinta_lembut", frame = "plain", effect = "none" },
	bagus = { token = "daun", frame = "leaf", effect = "sheen" },
	super = { token = "malam", frame = "double", effect = "sweep" },
	langka = { token = "ungu", frame = "ornate", effect = "pulse_sparkle" },
	sultan = { token = "kunyit", frame = "gold", effect = "falling_sparkle_sting" },
}

Visuals.tierOrder = { "biasa", "bagus", "super", "langka", "sultan" }

Visuals.cropStages = {
	bibit = { stem = 0.6, crown = 0.7 },
	tumbuh = { stem = 1.6, crown = 1.5 },
	siap = { stem = 3.4, crown = 2.4 },
}

Visuals.textures = {
	bambu = 0, genteng = 0, seng = 0, paving = 0, sawah = 0, kertas = 0, tanah = 0,
}

Visuals.materials = {
	bambu = { texture = 0, color = "bambu", fallback = "Wood" },
	genteng = { texture = 0, color = "genteng", fallback = "Slate" },
	seng = { texture = 0, color = "malam", fallback = "Metal" },
	paving = { texture = 0, color = "tinta_lembut", fallback = "Concrete" },
	sawah = { texture = 0, color = "padi", fallback = "Grass" },
	kertas = { texture = 0, color = "kertas", fallback = "Fabric" },
	tanah = { texture = 0, color = "bambu", fallback = "Ground" },
}

Visuals.artManifest = {
	textures = { bambu = "texture_bambu", genteng = "texture_genteng", seng = "texture_seng", paving = "texture_paving", sawah = "texture_sawah", kertas = "texture_kertas", tanah = "texture_tanah" },
	icons = { cropPrefix = "crop_", tools = { "tool_cangkul", "tool_babat" }, tiers = { "tier_biasa", "tier_bagus", "tier_super", "tier_langka", "tier_sultan" }, currency = "currency_rupiah" },
}

Visuals.artSlots = {
	"crop_padi", "crop_singkong", "crop_jagung", "crop_bawang", "crop_cabai", "crop_tembakau",
	"crop_kopi", "crop_tebu", "crop_kakao", "crop_cengkeh", "crop_durian", "crop_sawit",
	"tool_cangkul", "tool_babat", "tier_biasa", "tier_bagus", "tier_super", "tier_langka",
	"tier_sultan", "currency_rupiah", "ui_lock", "ui_phone", "ui_warning",
}

Visuals.motion = { duration = 0.22, overshoot = 1.06 }
Visuals.particles = { langka = 3, sultan = 8 }
Visuals.effects = { screenShake = false, toastPop = true, duration = 0.22 }

-- A usable Roblox asset id or nil. Guards 0, negatives, fractions, NaN and infinity so
-- config can ship placeholder ids without ever writing a bad rbxassetid:// into a property.
function Visuals.assetId(id: any): number?
	if type(id) ~= "number" or id % 1 ~= 0 or id <= 0 then
		return nil
	end
	return id
end

function Visuals.assetUrl(id: any): string?
	local valid = Visuals.assetId(id)
	return if valid then "rbxassetid://" .. valid else nil
end

function Visuals.applySurface(part: BasePart, slot: string, fallbackMaterial: Enum.Material)
	local textureUrl = Visuals.assetUrl(Visuals.textures[slot])
	local material = Visuals.materials[slot]
	if material then
		part.Color = Color3.fromHex(Visuals.palette[material.color])
	end
	part.Material = fallbackMaterial
	if not textureUrl then
		local existing = part:FindFirstChildOfClass("SurfaceAppearance")
		if existing then
			existing:Destroy()
		end
		return
	end
	local surface = part:FindFirstChildOfClass("SurfaceAppearance") or Instance.new("SurfaceAppearance")
	surface.ColorMap = textureUrl
	surface.Parent = part
end

-- ART.md §8: one type scale, one spacing scale.
Visuals.type = {
	display = 28,
	heading = 18,
	body = 13,
	small = 11,
}

Visuals.space = {
	xs = 4,
	sm = 8,
	md = 12,
	lg = 16,
	xl = 24,
	xxl = 32,
}

Visuals.radius = {
	card = 14,
	button = 10,
	chip = 8,
}

-- ART.md §4: 2 px ink contour, 4 px hard offset shadow, no blur.
Visuals.outline = 2
Visuals.shadow = 4
-- ART.md §8: touch targets at least 44 px.
Visuals.touch = 44

-- ART.md §8: candidates tested on a phone. Swap these two strings to re-skin all text.
Visuals.fonts = {
	display = "LuckiestGuy",
	body = "Nunito",
}

-- Icon slots. Every id stays 0 until the real image exists; `text` is the procedural
-- fallback drawn by UI/Icons.luau (ASCII only, no emoji). `token` names a palette colour.
Visuals.icons = {
	seed = { id = 0, text = "B", token = "daun" },
	lock = { id = 0, text = "L", token = "tinta_lembut" },
	cash = { id = 0, text = "Rp", token = "kunyit" },
	sus = { id = 0, text = "?", token = "merah" },
	reputation = { id = 0, text = "*", token = "malam" },
	phone = { id = 0, text = "HP", token = "malam" },
	cheat = { id = 0, text = "!", token = "genteng" },
	event = { id = 0, text = "!", token = "merah" },
	up = { id = 0, text = "^", token = "daun" },
	down = { id = 0, text = "v", token = "merah" },
	flat = { id = 0, text = "-", token = "tinta_lembut" },
	warning = { id = 0, text = "!", token = "kunyit" },
	rarity = { id = 0, text = "*", token = "kunyit" },
	done = { id = 0, text = "OK", token = "daun" },
	letter = { id = 0, text = "@", token = "bambu" },
	calendar = { id = 0, text = "7", token = "malam" },
	quest = { id = 0, text = "=", token = "daun" },
	debt = { id = 0, text = "Rp", token = "merah" },
	shame = { id = 0, text = "!", token = "merah" },
	warehouse = { id = 0, text = "GD", token = "bambu" },
	tools = { id = 0, text = "T", token = "indigo" },
	worker = { id = 0, text = "W", token = "bambu" },
	price = { id = 0, text = "Rp", token = "kunyit" },
	steal = { id = 0, text = "C", token = "genteng" },
	water = { id = 0, text = "S", token = "malam" },
	close = { id = 0, text = "X", token = "merah" },
	admin = { id = 0, text = "A", token = "indigo" },
	viral = { id = 0, text = "!", token = "merah" },
	user = { id = 0, text = "U", token = "indigo" },
	hat = { id = 0, text = "D", token = "kunyit" },
	garden = { id = 0, text = "K", token = "daun" },
	trophy = { id = 0, text = "1", token = "kunyit" },
	shop = { id = 0, text = "S", token = "daun" },
}

for _, name in Visuals.artSlots do
	if not Visuals.icons[name] then
		Visuals.icons[name] = { id = 0, text = "*", token = "kunyit" }
	end
end

function Visuals.icon(name: string)
	return Visuals.icons[name]
end

function Visuals.color(name: string): string?
	return Visuals.palette[name]
end

return Visuals
