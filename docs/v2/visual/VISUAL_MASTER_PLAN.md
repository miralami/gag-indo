# Juragan Desa — Visual Master Plan

> Written 2026-11-16. The direction for everything the player **sees**: light, atmosphere, surfaces,
> models, vegetation, water, characters, animation, VFX, camera and UI fidelity.
> `plan/MASTER_PLAN.md` still governs what may be built, in what order and how work is proven; this file
> sits under it and never overrides it. Where this file disagrees with `visual/ART.md` on *look*, this file
> wins (see §2, decision D14). `visual/ART.md` keeps the palette, the UI kit and the NPC caricature rules.

## Visual tracker — read first, update last

**Last updated:** 2026-11-16 — plan written, nothing in it built yet.

Same rules as the master tracker: tick in the same commit as the work, with a status word
(`SEEN-IN-STUDIO`, `LUNE-ONLY`, `UNVERIFIED`, `BLOCKED`) and an evidence path.

- [ ] **V0 Foundation** — fidelity tiers, perf switches, look-dev scene, reference board
- [ ] **V1 The frame** — one hero screenshot (spawn view) that passes the screenshot test
- [ ] **V2 The moments** — six hook moments (§4) at clip quality
- [ ] **V3 The living village** — ambient life, weather you can see, night
- [ ] **V4 Fidelity sweep** — every surface, icon and screen; nothing below the bar

## 0. Why this file exists

The master plan makes the game work. This plan makes a stranger **stop scrolling**. On Roblox the
first contact is a thumbnail, then a five-second clip, then the first ten seconds after spawn. If
those look like every other farming game, the satire never gets a chance.

So visuals here are not decoration, they are the **hook**. Every item below is judged by one
question: *does it make a moment worth recording?*

Two things this plan is not:

- Not permission to start gameplay features. Master Plan rule 2 ("feel before features") is what
  authorises this work before Gate 1; it does not authorise new systems.
- Not a photoreal chase. See §2.

## 1. Where the visuals really are (2026-11-16, read from the code)

| Layer | Today | Honest verdict |
|---|---|---|
| Light | Golden hour 16–17, three season presets, Atmosphere, Bloom, SunRays, ColorCorrection (`Seasons.luau`, `Sky.luau`). Future lighting set by hand in the place file. | The strongest layer. Time never moves, so there is one mood. |
| Sky | Classic Roblox sunset skybox, Clouds under Terrain. | Stock. Recognisable as default. |
| Surfaces | Built-in materials only. All seven hero texture slots in `Visuals.textures` are `0`. | Nothing on screen is ours. |
| Models | World is Parts from `Greybox`/`Decor`/`Details`/`Flora`. Ten CC0 low-poly props uploaded 2026-11-15, placed in a test row, not dressed into the village. 86 Creator Store pines as backdrop. | Two styles side by side: chunky low-poly props and realistic pines. |
| Crops | A `Wood` stem Part and a crown Part, scaled per stage (`FarmService`). | The thing the player looks at most is two blocks. |
| NPCs | Box rigs with a Highlight contour (`NpcFactory`). No animation anywhere in `src`. | Placeholder. |
| VFX | Plant, harvest and sell bursts built in code with default particle textures (`ActionFeel`); rarity PointLight, Highlight and sparkles on the crop (`FarmService`). | Logic is there; the particles are default squares and sparkles. |
| Weather | Rain, storm and fog change light and sound only. No rain, no puddles, no lightning. | You hear rain you cannot see. |
| Life | Foliage sway within 50 studs (`Wind.luau`). Nothing else moves. | A still photograph. |
| Camera | FOV follows walk speed (`CameraFeel`); a camera nudge on plant and a shake on Langka/Sultan (`ActionFeel`). | No shots, no framing, no depth of field. |
| UI | Kit, tokens and layout done (`Theme`, `Visuals`). Every icon id is `0` so icons are letters. Motion exists in `Theme` and `RaidOverlay` only. | Structure good, surface unfinished, almost no motion. |
| Performance | Designer phone: about 30 fps at max, 60 at lowest. 27 Highlights. No quality tiers of our own. | No headroom yet for anything in this plan. That is why V0 comes first. |

## 2. The target: aim realistic, land believable

**Designer, 2026-11-16 (D14):** the look we chase is **realistic**. Not brutal photorealism, but
honestly *trying* to be real. Semi-realistic is where we expect to land; it is the floor, not the
aim. "Better" does not have to mean "more realistic": it means higher fidelity in every small
thing (effects, UI, motion, detail).

One line: **Realisme hangat — a real Indonesian village on its best afternoon.**

| We chase | We do not chase |
|---|---|
| Real light behaviour: soft sky fill, long shadows, haze with depth, wet ground that reflects | Scanned photogrammetry, 4K textures, film grain, lens dirt |
| Real materials: wood grain, rusted seng, cracked plaster, mud, woven bamboo, with roughness and normal maps | Flat single-colour surfaces; also noisy "realism" that hides gameplay |
| Real proportions for buildings and props; real plant shapes | Uncanny human faces. Players stay R15, NPCs stay caricature (D7, `visual/ART.md` §6) |
| Things that move the way they do in a village: smoke, laundry, chickens, water, dust | Simulation for its own sake |
| Detail density where the player stands; calm where they do not | Uniform detail everywhere (kills phones and focus) |

### What changes from `visual/ART.md`

| `visual/ART.md` says | Now | Why |
|---|---|---|
| "No photoreal" (§1) | Realistic is the aim; photoreal *assets* are fine if they pass budget and licence | D14 |
| Hand-painted `SurfaceAppearance`, painted backdrop (§5) | PBR materials with real roughness and normal maps | D14 |
| Ink contour on hero props, crops and interactables through `Highlight` (§2, §4) | **Recommend retiring the world contour.** Readability comes from light, colour and motion instead. Highlight stays only as a *focus* cue on the thing you are about to interact with. Open decision V-D1 | A drawn outline around a realistic object reads as a bug, and the 27 Highlights are the top perf suspect (`RESEARCH_VISUAL_TIPS.md` §3.1) |
| Clock fixed at 16:30–17:30 (§5) | Golden hour stays the **default and the spawn moment**; a slow dusk-to-night drift is added in V3. Open decision V-D2 | One mood cannot carry a session; night is where lights, fireflies and the raid look best |
| Palette (§3), UI kit (§8), NPC caricature (§6), phone first (§2.5) | **Unchanged** | Palette becomes the *grading and accent* reference; real materials keep their real colours inside it |

The UI stays stylised (kertas, tinta, stempel). A realistic world with an illustrated, tactile UI is
a deliberate contrast: the UI is the paperwork of the village.

### The three laws

1. **Believable beats detailed.** One correct shadow and a wet reflection do more than a thousand props.
2. **Fidelity is in the response.** Every touch gets light, motion and sound within 100 ms. A
   plain scene that reacts feels richer than a rich scene that is dead.
3. **If the phone cannot run it, it does not exist.** Every item ships with its low-tier form (§6)
   or it does not ship.

## 3. The screenshot test

The bar for any visible work, used in every review:

1. **Thumbnail test.** Shrink the capture to 256 px wide. Can you still tell it is a village at
   sunset and where the player should look?
2. **Stranger test.** Would someone who has not seen the game guess "Roblox default kit"? If yes, fail.
3. **Three-read test.** Foreground (what I can touch), midground (where I can go), background
   (mood) are separable by value and haze.
4. **Motion test.** In a five-second clip, at least three independent things move.
5. **Low-tier test.** The same shot at the lowest fidelity tier is still clearly the same game.

## 4. The hook: six moments that must be clip-worthy

These are the shots a thumbnail, trailer or TikTok is cut from. V2 builds them. Each one names the
layers it needs so work can be traced back to §5.

| # | Moment | The shot | Needs |
|---|---|---|---|
| M1 | **Spawn at senja** | Camera rises from behind rice stalks to the player, village and terraces in haze behind, sun low on the left, smoke from the warung. Two seconds, then control. | L1 L2 L4 L5 L8 |
| M2 | **The harvest** | Stalks bend, cut, spring; grain and dust catch the sun; the produce pops up, spins once and lands in the sack with weight. | L4 L7 L10 |
| M3 | **The reveal** | Time dips for a beat. Light on the tile shifts to the tier colour, a god-ray column, the item rises. Sultan: gold motes fall across the whole plot, visible from the neighbouring plots. | L1 L7 L8 L9 |
| M4 | **The sale** | Scale tips, thermal *struk* prints out line by line, cash arcs to the HUD and the counter rolls like a pump meter. | L7 L9 L10 |
| M5 | **The raid** | Dusk. Red-blue light sweeps across wet road and bamboo walls before you see the car. Dust, a slammed door, sinetron zoom on a face, a stamped letter fills the screen. | L1 L5 L6 L7 L8 L9 |
| M6 | **Rain arrives** | Wind first (foliage, laundry), light drops, first drops on dust, then sheets of rain, splashes, sawah surface dimpled, roofs dripping, puddles holding the sky. | L1 L2 L4 L5 L7 |

Later, same standard: the debt collector at the gate (night, one motorbike headlight), rank-up
ceremony, cabai event.

## 5. The ten layers

Each layer: where it is, where it goes, the work items. IDs are stable; cite them in commits.
"Lane" names the master-plan track that owns the files.

### L1. Light and atmosphere (lane C)

Target: light does the art direction. The village should look good with every texture switched off.

- **V-L1.1** Re-grade the three season presets against reference photos (V0), on a phone screen,
  not a monitor. Shadows stay tinted (indigo-brown), never neutral grey.
- **V-L1.2** Exposure discipline: one `ExposureCompensation` and bloom threshold per preset, so
  white walls never clip and the sun disc still blooms.
- **V-L1.3** Local light: warm lamps in warung, pos ronda, houses; they switch on as dusk falls.
  Low tier keeps emissive surfaces and drops the light sources.
- **V-L1.4** Time drift (V-D2): golden hour for the first session, then a slow slide to blue hour
  and night with moon fill, and back. Server owns the clock; presets gain a time axis.
- **V-L1.5** Replace the stock skybox with a sky that matches each season (clear amber, broken
  monsoon cloud, heavy overcast). Asset route per `plan/TOOLS.md`; never an invented id.
- **V-L1.6** Depth cues: aerial haze tuned so far hills go two steps bluer and lighter; optional
  light shafts (Beams, additive) under trees and through the pasar roof, near camera only.
- **V-L1.7** Depth of field only in authored shots (M1, M3, M5, photo mode), never during play.

### L2. Surfaces and materials (lane G makes, lane C applies)

Target: no surface is a built-in material at default. Eight to ten materials carry the village.

- **V-L2.1** Hero material set as PBR (colour, normal, roughness): anyaman bambu, kayu tua, genteng
  tanah liat, seng berkarat, plester retak, paving/semen, tanah kering, lumpur sawah, aspal desa,
  kain spanduk. This is wider than the 6 to 8 hero textures in Master Plan §5 track G; the extra
  two or three are road and mud, which the terrain needs. Sources: Poly Haven CC0 first (licence already cleared in
  `RESEARCH_VISUAL_TIPS.md` §5), resized to the texture budget in §6.
- **V-L2.2** Deliver them as `MaterialVariant`s, applied through MaterialService overrides where
  that works so existing Parts need no re-authoring (to confirm, §11; otherwise the world builders
  set the variant per Part); `SurfaceAppearance` only on unique meshes.
- **V-L2.3** Terrain materials get the same treatment (grass, ground, mud, rock, sand) so the
  ground and the buildings belong to one photograph.
- **V-L2.4** Wear and story: decal layer for water stains under roofs, moss at wall feet, tyre
  tracks, posters and stickers, oil spots at the motor parking. This is where "Indonesian
  specifics" (`visual/ART.md` pillar 4) lives.
- **V-L2.5** Wetness: in rain presets, roads and roofs get darker and glossier (swap to a wet
  variant), and reflective puddle surfaces appear in low spots (technique to confirm, §11).

### L3. Models and silhouette (lanes G and C)

Target: one style. Today there are two (low-poly props, realistic pines); pick realistic
proportions with moderate detail and bring everything to it.

- **V-L3.1** Style call on the ten uploaded Poly Pizza props: keep those that hold up next to PBR
  materials after re-texturing, replace the rest. Decide per prop in the look-dev scene, with
  screenshots. Open decision V-D3.
- **V-L3.2** Building kit: walls, posts, roof pitches, eaves, doors, shutters, steps, at real
  proportion, so the six hubs stop being boxes. Roofs get overhang and visible structure; this
  is the single biggest silhouette gain.
- **V-L3.3** Hero landmarks, one per hub, modelled individually: warung with seng awning, pasar
  hall, balai desa with pendopo roof, pos polisi, pos ronda with kentongan, gudang.
- **V-L3.4** Village clutter set (about 30 pieces, instanced): galon, jemuran, kandang ayam,
  sepeda, ember, tumpukan karung, tiang listrik with tangled cable, gapura, plang, warung goods.
- **V-L3.5** Budgets: about 2,000 triangles per kit piece, up to 8,000 per landmark
  (`RESEARCH_VISUAL_TIPS.md` §3.11), shared material set, shared mesh ids for batching.

### L4. Vegetation, terrain and water (lane C)

Target: the fields are the game. Padi must look like padi.

- **V-L4.1** **Crops as real plants.** Replace stem-and-crown Parts with authored meshes per crop
  and stage (bibit, tumbuh, siap), starting with the first-session crops (padi first). Clumped
  cards for padi; they sway and they bend when walked through.
- **V-L4.2** Stage transitions are animated (grow, not swap) and the ready stage is readable from
  30 studs by colour alone: green to gold.
- **V-L4.3** Tree set that matches Indonesia: kelapa, pisang, bambu rumpun, mangga, sengon. The
  pine backdrop is replaced or pushed far enough to read as a ridge line. Open decision V-D4.
- **V-L4.4** Ground layering near paths and hubs: grass, weeds at fence feet, fallen leaves, stones.
- **V-L4.5** Sawah water: shallow, reflective, sky-coloured between the stalks, with a mud rim.
  River with a visible flow direction, foam at stones, darker depth in the middle.
- **V-L4.6** Wind as one system: `Workspace.GlobalWind` drives terrain grass, particles and cloud
  drift; `Wind.luau` drives foliage and now also laundry and banners. Weather sets the strength.

### L5. Ambient life (lane C, client)

Target: stand still for ten seconds and count five things moving.

- **V-L5.1** Always on: kitchen smoke, dust in sun shafts, insects over the sawah, leaves falling,
  banners and laundry in the wind, water ripples.
- **V-L5.2** Animals: chickens that scatter when you run at them, ducks in a line on the pematang,
  a cat on the warung bench, birds that lift off the wires at the raid siren.
- **V-L5.3** Dusk and night: fireflies over the fields, moths at lamps, lit windows, frogs (audio).
- **V-L5.4** Village life props that tick: a ceiling fan, a swinging lamp, a TV flicker in a
  window, a passing motor on the far road.
- **V-L5.5** All of it is client-side, pooled, range-culled, and scaled by fidelity tier (§6).

### L6. Characters and animation (lane F)

Target: NPCs are people with a posture, not boxes with a line of text.

- **V-L6.1** NPC models from the design cards (`art/npcs.md`): caricature stays, materials become
  believable (cloth, batik, a worn peci). Contour dropped with V-D1.
- **V-L6.2** Animation set per archetype: idle with a habit (Pak RT adjusts his peci, the
  Tengkulak counts money), talk, point, laugh, panic. Uploads go through the designer's account;
  ids recorded in the manifest.
- **V-L6.3** Player tool animations for the two minigame verbs (mencangkul, babat) plus plant,
  carry and sell, with tool models in hand. These are in every clip of the game.
- **V-L6.4** Faces: three or four strong expressions, swapped, not blended.
- **V-L6.5** Heads and eyes track the player within a few studs. Cheap and it reads as alive.

### L7. Gameplay VFX (lane A)

Target: every verb has an anticipation, an impact and a settle, with authored textures.

- **V-L7.1** Particle texture atlas of our own (dust puff, soil clod, grain, leaf, water drop,
  splash ring, smoke, spark, gold mote, paper scrap) with flipbooks where motion matters. Replaces
  every default texture in `ActionFeel` and `FarmService`.
- **V-L7.2** Plant: tool bites, soil clods arc and land, a dark wet patch on the tile fades over
  time.
- **V-L7.3** Harvest (M2): stalk bend and spring, grain burst that takes light, produce pop-up
  with squash and stretch, arc into the sack.
- **V-L7.4** Rarity ladder (M3), one step richer per tier so Biasa stays plain and Sultan is an
  event: sheen, sweep, light column and motes, full-plot gold fall with a time dip.
- **V-L7.5** Sell (M4): coin and note particles with weight, struk print, HUD counter roll.
- **V-L7.6** Weather VFX (M6): rain sheets attached to the camera, splash rings on ground and
  water, roof drip lines, mist on the terraces, lightning as a one-frame light change plus a
  delayed thunder.
- **V-L7.7** World reactions: footstep dust or splash by surface, grass and crops parting, water
  wake in the sawah.
- **V-L7.8** Raid and debt (M5): rotating red-blue light, headlight cone with dust in it, door
  slam dust, a paper letter that flutters down.

### L8. Camera (lanes A and F)

- **V-L8.1** Authored shots for M1, M3 and M5, each under three seconds and skippable by moving.
- **V-L8.2** Impact language: small, fast, decaying kicks keyed to the event, never a generic
  shake. Reduced-motion setting turns all of it off.
- **V-L8.3** Framing help near hubs: a slight pull-back and tilt when entering a hub so the
  landmark is in frame.
- **V-L8.4** Photo mode (hide HUD, free camera, depth of field, time-of-day slider). It makes
  players produce our marketing. After Gate 1.

### L9. UI fidelity (lane D)

The kit is right; the finish is missing. Fidelity here means material, motion and response.

- **V-L9.1** Real icons in every slot (unblocks G4). No letter fallbacks visible in the first ten
  minutes.
- **V-L9.2** Paper as a material: grain texture, slightly uneven edges, a fold shadow; struk on
  thermal paper with a torn edge; raid letter with letterhead and a stamp that lands off-centre.
- **V-L9.3** Motion grammar, defined once in `Theme` and used everywhere: open (scale from the
  button that opened it), close, press (2 px sink into the hard shadow), reward (pop with
  overshoot), number change (roll), error (short shake). Nothing over 0.3 s (`visual/ART.md` §9).
- **V-L9.4** Phone as an object: bezel, screen glow on the avatar's face at night, notification
  buzz with a tilt, app-open zoom from the icon.
- **V-L9.5** Diegetic touches: prices on chalkboards in the pasar, the leaderboard on the balai
  desa notice board, loan offers as stickers on a pole.
- **V-L9.6** Font decision on a phone (master tracker D, §9.3) and one pass for optical alignment.

### L10. Sound-to-picture sync (lane E)

Audio has its own track; this layer only says what picture work must not ship silent. Every item
in L5 and L7 has a sound within the same frame budget, footsteps change by surface, rain on seng
sounds different from rain on leaves, and the mix ducks for M3 and M5.

## 6. Fidelity tiers and the budget

Nothing in §5 ships without this. The designer's phone already sits at 30 fps at max settings.

### Tiers

One client module, `FidelityTier`, picks a tier and everything visual asks it instead of deciding
alone. Inputs: the player's saved quality setting, a rolling frame-time average, and a manual
override in settings.

| | Rendah | Sedang | Tinggi |
|---|---|---|---|
| Target device | below mid-range Android | mid-range Android (the real target) | desktop, flagship |
| Frame rate | 30 floor | 60, the Gate 1 target at the device's default quality | 60 |
| Ambient life (L5) | smoke and wind only | most, half counts | all |
| Particles | 40% rate, short life | 70% | 100% |
| Local lights | none (emissive only) | key lights, no shadows | all, shadows on heroes |
| Small-part shadows | off | off beyond 60 studs | on |
| Rain | camera sheet only | plus splashes | plus drips, mist, puddles |
| Foliage sway range | 25 studs | 50 | 80 |
| Authored camera DoF | off | off | on |

The tier moves **down** quickly when frames are missed and **up** slowly, and never during a hook
moment.

### Budgets (project numbers until measured; replace with measurements in V0)

- Draw calls under about 500 and triangles under about 500k in the spawn view at Sedang
  (community figure, `RESEARCH_VISUAL_TIPS.md` §3.11).
- Textures 512 by default, 1024 only for terrain-scale and landmark surfaces.
- Highlights: at most one live at a time (the focus cue), down from 27.
- Particles: every emitter pooled; a hard cap on live emitters per tier.
- PlayerGui: 947 instances at idle today (`evidence/h/2026-11-14-perf/`); build screens on open,
  not at mount.

## 7. Phases and gates

Order matters more than speed. Each phase ends with evidence in the owning track's folder under
`docs/v2/evidence/<track>/` (Master Plan §7). L3.5 budgets apply in every phase.

### V0 — Foundation (before anything pretty)

| # | Task | Done when |
|---|---|---|
| V0.1 | `FidelityTier` module with pure tier-selection logic and a spec | `LUNE-ONLY` spec; tiers switch live in Studio |
| V0.2 | Admin-only switches for Highlights, shadows, bloom, decoration, particles (`RESEARCH_VISUAL_TIPS.md` §3.1) | Designer phone gives an fps number per switch; the cost table replaces the guesses in §6 |
| V0.3 | Reference board: 12–20 photos (village at senja, sawah, pasar, warung at night, rain on seng) from the designer or CC0 sources, stored with sources under `docs/v2/visual/art/reference/` | Board exists; every later review cites a photo |
| V0.4 | Look-dev scene: one 60×60 stud corner (warung, a road bend, a sawah edge) where materials, models and light are tried before touching the village; includes the prop style call V-L3.1 | Scene built in Studio, before/after captured |
| V0.5 | Designer answers V-D1 to V-D5 (§10) | Rows in `plan/DECISIONS.md` |

**Gate V0:** we know what each effect costs on the phone, and we have a corner of the village
that the designer says is the look.

### V1 — The frame

Take the look-dev result to the **spawn view only**: L1.1–L1.2, L1.6, L2.1–L2.3, L3.2 for the
buildings in frame, L4.1–L4.2 for padi, L4.5, L5.1, L9.1, and M1 with its shot from L8.1.

**Gate V1:** the spawn screenshot passes all five screenshot tests at Sedang on the designer's
phone at 60 fps at its default quality (the Gate 1 number). This contributes to Gate 1 item G4
for the opening view; G4 as a whole also needs icons everywhere and real NPCs.

### V2 — The moments

M2, M3, M4 first (they repeat every minute), then M5. Needs L7.1 before any of them, then
L7.2–L7.5, L6.3, L8.1–L8.2, L1.7, L9.2–L9.3. M5 also pulls forward what the raid needs: L7.8,
L1.3 for the lights in shot, and L6.1–L6.2 for the raid cast only.

**Gate V2:** a 30-second clip cut only from real gameplay shows plant, harvest, reveal, sale and
raid, and the designer would post it. Each moment holds its frame-rate floor on the phone.

### V3 — The living village

M6 (rain) lives here because it needs the whole weather stack. L5 in full, L1.3–L1.5 (lights,
time drift, skies), L2.5, L4.3–L4.6, the rest of L6, L7.6–L7.7.

**Gate V3:** motion test passes from any hub; rain, dusk and night each have a screenshot that
passes §3; ten-minute soak at Sedang with no tier thrash.

### V4 — Fidelity sweep

Walk every hub and every screen with the §3 tests and the `visual/ART.md` §11 checklist (updated for
D14). L2.4, L3.3–L3.4, L9.4–L9.6, L8.3–L8.4. Anything below the bar is fixed or removed.

**Gate V4:** no capture from anywhere in the village fails the stranger test.

### How this fits Gate 1

Bugs still outrank everything. V0 and V1 run **before** Gate 1 because they contribute to G4 and G6.
V2 overlaps the first-session beats already built by track B, so it may run before Gate 1 as
"feel". V3 and V4 are mostly after Gate 1, except items needed so that nothing in the first ten
minutes is a placeholder.

## 8. Lanes, pipeline and proof

- **Ownership follows `plan/MASTER_PLAN.md` §5.** L1–L5 track C, L6 track F, L7–L8 track A, L9 track D,
  L10 track E, assets track G. `FidelityTier` lives in `src/client/Feel/` (track A); its settings
  toggle is track D; crop visuals in `FarmService` follow track A's "visible crop growth stages"
  deliverable. `Theme.luau` stays track D only; `JuraganDesa.rbxl` stays track C only.
- **Studio is main-session only** (`AGENTS.md`). Subagents prepare meshes in Blender, write Luau
  and specs; anything that needs a play session, a capture or a place-file setting (lighting
  technology, terrain decoration, MaterialService content) is done by the main session.
- **Assets:** Toolbox/Creator Store and CC0 first, then Blender, then generated and cleaned.
  Every asset gets a manifest row before merge; ids are never invented; uploads land in the
  designer's inventory through the Open Cloud key.
- **Proof for visual work** adds to Master Plan §7: a before/after pair from the same camera
  position, at Rendah and Tinggi, at phone size, plus the fps reading. A visual claim with no
  capture is never `SEEN-IN-STUDIO`; the other status words keep their Master Plan §7 meaning. Agents that cannot read viewport captures say so and leave the visual
  judgement `BLOCKED` on the designer rather than describing what they did not see.
- **Testable logic stays testable:** tier selection, pooling limits, preset interpolation, motion
  curves and timing tables are pure functions with Lune specs, as `ActionFeel` and `Wind` already do.

## 9. Not doing

- Restyling player avatars, or realistic NPC faces.
- Volumetric clouds or fog systems, ray-traced anything, screen-space effects we would have to fake
  with stacked transparent parts.
- A weather simulation. Weather is a presentation of server state that already exists.
- Any effect that sells an advantage or hides information the player needs.
- Detail outside the playable village beyond what the horizon needs.
- Anything that cannot name its Rendah form.

## 10. Open decisions for the designer

| # | Decision | Recommendation |
|---|---|---|
| V-D1 | Retire the world ink contour (`visual/ART.md` §2, §4)? Keep `Highlight` only as a focus cue. | Yes. It fights realism and is the first perf suspect. UI keeps its outline. |
| V-D2 | Let the clock move (golden hour → dusk → night → morning)? | Yes, slowly, with golden hour guaranteed for the first session and for spawn. |
| V-D3 | The ten low-poly props: re-texture and keep, or replace? | Judge per prop in the look-dev scene; expect to keep the simple ones (crate, barrel, karung, fence) and replace the stall, hut and motor. |
| V-D4 | Pine backdrop: replace with tropical trees, or push back as a far ridge? | Replace within sight of the village; pines are the least Indonesian thing on screen. |
| V-D5 | Who supplies the reference photos (V0.3)? | Designer picks 12–20; they define "realistic" better than any paragraph here. |
| V-D6 | Animation production route (L6): Studio animation editor, Blender, or Creator Store packs restyled? | Creator Store first for generic motion, authored for the two tool verbs and NPC habits. |

## 11. Engine facts to confirm before relying on them

Marked here instead of being trusted from memory. Each is checked against
`create.roblox.com/docs` when its work item starts, and the answer is written back into this section.

- Whether MaterialService overrides re-skin existing Parts by base material without setting
  `MaterialVariant` on each, whether the same applies to Terrain, and the supported map sizes.
- How to make a reflective puddle: a decal is unlikely to carry reflectance, so expect a thin
  Part or `SurfaceAppearance`.
- At which quality levels `DepthOfFieldEffect`, local light shadows and `Atmosphere` haze are
  dropped by the engine on mobile.
- Current `Highlight` limits and cost on mobile (the 1 ms figure in `RESEARCH_VISUAL_TIPS.md` is
  from the docs as read 2026-11-14).
- What `Workspace.GlobalWind` drives today (terrain grass, particles with wind drag, clouds).
- Whether a `LocalScript` can read the effective graphics quality when the player uses Automatic,
  or only the saved setting. `FidelityTier` assumes the worst case and measures frame time.
- Flipbook particle layout options and texture size limits.
- Cost of Future lighting against ShadowMap on mid-range phones: only a phone measurement answers
  this (already listed as unconfirmed in `RESEARCH_VISUAL_TIPS.md` §3.10).
