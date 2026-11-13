# Juragan Desa — Art Bible

Status: **draft, direction chosen (A + B)**. Moodboard: `docs/v2/art/moodboard.html`.
Decision record: D11 in `DECISIONS.md`.

## 1. Direction in one line

**Cat tangan berkontur.** Warm painted volume (moodboard A) held together by a clean ink contour and
hard-shadow stickers (moodboard B). It looks hand-made and premium, and it still reads as a Roblox
game: chunky proportions, R15 avatars, readable on a phone.

| Takes from A (cat tangan) | Takes from B (kartun tebal) |
|---|---|
| Painted gradients and brush texture on fills | Ink contour on things the player must read |
| Late-afternoon light, tinted shadows | Flat, saturated accent colours |
| Warm, lived-in village | Hard offset shadow, sticker feel (UI) |
| Rarity as glow and richness | Rarity as frame and badge |

**The bar:** a screenshot should look like a good illustrated game, not like default Roblox parts.
The Indonesian market compares against polished mobile games, so the quality of the first
screenshot, thumbnail and first minute is the product.

**Still Roblox:** R15 rigs and avatar compatibility stay, proportions stay chunky and friendly, no
photoreal, no assets that need a high-end device. Everything must be buildable with Parts,
MeshParts, `SurfaceAppearance`, Terrain, Future lighting and `ScreenGui`.

## 2. Pillars

1. **Warm, never pale.** Light is always golden-hour warm. Shadows are indigo-brown, never black or grey.
2. **Contour what matters.** Hero props, NPCs, crops, interactables and every UI element get the ink
   line. Backdrop (terrain, far trees, hills) is painted and has no line. This is how the player's
   eye finds things.
3. **One palette, everywhere.** World, UI, icons and VFX draw from the same swatches. No stray colours.
4. **Indonesian specifics, not generic farm.** Genteng, bambu, seng, spanduk, warung, ojek, sawah
   terasering, kabel listrik semrawut. Details carry identity.
5. **Phone first.** If it is not readable on a 6-inch screen at arm's length, it is wrong.

## 3. Palette

Shared by world, UI and icons. Names are the Indonesian things they come from.

| Token | Hex | Used for |
|---|---|---|
| `kertas` | `#f3e9d2` | UI paper, light surfaces |
| `tinta` | `#2b2118` | Contours, text, hard shadows |
| `tinta-lembut` | `#5b4a38` | Secondary text |
| `senja` | `#f6c97a` | Sun, sky, warm highlights |
| `padi` | `#9bb25a` | Sawah, light foliage |
| `daun` | `#6f8a3f` | Foliage, grass, success |
| `genteng` | `#a8452f` | Roofs, brick |
| `merah` | `#a83226` | Signage, stamps, danger |
| `bambu` | `#b98a5a` | Wood, bamboo, walls |
| `kunyit` | `#c99a2e` | Gold, rarity top tier, rank |
| `indigo` | `#3b4f6b` | Shadows, night, cool accent |
| `malam` | `#1f4e6b` | Water, rain, links |
| `ungu` | `#7652a8` | Langka rarity frame and glow |

Rules: shadow colour is `indigo` at 35 to 55 percent, never black. Any new colour must be added here
first. A scene uses at most 3 dominant hues plus `tinta`.

## 4. Line and shape

- **UI:** 2 px `tinta` outline plus a hard offset shadow (4 px right/down, no blur). Already approved in the mockups.
- **World, contour objects:** thin outline, about 1.5 to 2 px on screen, through `Highlight` outline or an
  inverted-hull mesh, `tinta` coloured. Scale it down with distance so it never gets noisy.
- **World, backdrop:** no outline. Painted gradient and texture only.
- **Silhouette first:** every prop must be recognisable as a flat black shape. Exaggerate roofs,
  hats, tools. Big shapes, few details, chunky corners.
- **Corners:** soft radius on UI cards, slightly rounded on props. No razor-sharp hard-surface edges.

## 5. World (3D)

- **Textures:** hand-painted `SurfaceAppearance` (colour map, optional roughness). Roblox default
  materials only as a fallback under a painted texture. No smooth-plastic look anywhere.
- **Lighting (base):** `Future` technology, warm low sun (about 16:30 to 17:30 clock time), `Atmosphere`
  with warm haze, `ColorCorrection` for a slight warm tint and saturation, subtle `Bloom` and `SunRays`.
  Season presets in `Config/Seasons.luau` already tween Lighting; they get re-tuned to this palette:
  - **Hujan:** cooler, `indigo`/`malam` shadows, soft fog, saturated greens.
  - **Kemarau:** amber haze, long shadows, dry `bambu` and `padi`.
  - **Pancaroba:** pale gold, mixed cloud, in-between.
- **Terrain:** real Terrain for sawah (stepped terraces with water reflections), river and hill.
  Hand-painted colours, not default grass.
- **Hub identity:** each hub has one colour accent and one landmark silhouette, so the player always
  knows where they are: Pasar (`merah` spanduk), Balai Desa (`kunyit`), Pos Polisi (`malam`),
  Warung (`genteng` + seng), sawah (`padi`).
- **Set dressing:** layered clutter near hubs (kabel, motor, jemuran, karung, galon), calm open space
  between them. Density is the story.
- **Budget:** instancing and shared textures. Target 60 fps on mid-range Android. Textures are
  atlased and small. Contour effects only on objects within about 60 studs.

## 6. Characters and NPCs

- Players keep their **R15 avatar**. We do not restyle the player.
- **NPCs are caricature:** oversized head, one exaggerated feature, one signature accessory, and a
  three-colour outfit from the palette. Each must be identifiable from its silhouette alone.
- **Contour on NPCs always on**, so they pop out of the painted backdrop.
- **Parody rule (D7):** persona and stereotype stay accurate, names and faces are changed. Every
  recurring NPC gets a one-line design card (silhouette, accessory, palette, voice) before it is built.
- Expressions: a few strong face states (neutral, angry, smug, panic) rather than many subtle ones.

## 7. Crops and rarity

- **Icons:** painted fill, ink contour, drawn on a transparent square, one angle (three-quarter).
  Same light direction (top-left, warm) on every icon. Replaces emoji.
- **World models:** each crop has growth stages (bibit, tumbuh, siap) with a readable silhouette per stage.
- **Rarity** is shown the same way on icon, world model and UI chip:

| Tier | Frame / badge | Effect | Colour |
|---|---|---|---|
| Biasa | Plain | None | `tinta-lembut` |
| Bagus | Thin leaf corner | Slight sheen | `daun` |
| Super | Double border | Soft highlight sweep | `malam` |
| Langka | Ornate border | Pulsing glow, small sparkles | purple accent |
| Sultan | Gold `kunyit` frame | Gold glow, falling sparkles, sting sound | `kunyit` |

  The "wow" harvest is the tier reveal: frame snaps in, glow, sting. Biasa gets no fanfare, which is what makes the others feel earned.

## 8. UI

The approved mockup direction stays: **kertas, tinta, stempel**. Changes from this bible:

- Paper surfaces get a subtle painted texture, not flat fill.
- Image icons replace every emoji (`🌱`, `🔒` and others in `Hud.luau`).
- Per-surface treatment from PLAN §3.1: spanduk (shop), kop surat (raid), struk (receipts), chat-app (phone), wall calendar (quests).
- D1 redirects apply: HUD more playful, Toko Bibit slightly more Roblox-playful, HP home as app grid, HP chat nudged playful, Surat polish only.
- One type scale (28 / 18 / 13 / 11), one spacing scale (4 / 8 / 12 / 16 / 24 / 32).
- **Type, to test in Studio:** a heavy display face for spanduk headings (`LuckiestGuy` or `Bungee`),
  a readable face for body and letters (`Merriweather` or `Nunito`). Final choice after seeing them on a phone.
- Minimum functional text 11 px equivalent on a phone. Touch targets at least 44 px.

## 9. VFX and motion

- Particles use palette colours only. Sparkles are small hand-drawn shapes, not default Roblox sparkle.
- UI motion: quick ease-out, a small overshoot (stamp slam, badge pop). Nothing slower than 0.3 s.
- Screen shake only for the raid and a Sultan reveal.

## 10. Production plan

1. **Lighting pass** (code, fast): re-tune season presets to the palette, add Atmosphere, ColorCorrection, Bloom. Biggest change to the "pale" look for the least work.
2. **UI kit** (code): new `Theme` from this palette, outline + hard-shadow components, icon slots.
3. **Icon set** (art): crops, tools, tiers, currency. Generated, then cleaned by the designer to match section 7.
4. **Hero textures** (art): 6 to 8 painted textures (bambu, genteng, seng, paving, sawah, kertas, tanah). These carry most of the look.
5. **Studio map and NPCs** (art + designer): build with tags that `Map.luau` already supports; each NPC from a design card.
6. **VFX and audio** pass.

## 11. Quality checklist (apply to every asset)

- [ ] Uses only palette colours.
- [ ] Readable as a silhouette, and on a phone.
- [ ] Contour present if it is interactive or hero; absent if it is backdrop.
- [ ] Shadows tinted, never black.
- [ ] No emoji, no default Roblox plastic look, no default font.
- [ ] Works in all three season lighting presets.

## 12. Open questions

- Who produces the painted textures and icons: designer by hand, generated and cleaned, or a hired artist? This sets the real schedule for M3.
- Final display and body fonts (test on device).
- Purple accent hex for Langka: `#7652a8` (`ungu`), now added to the palette.
