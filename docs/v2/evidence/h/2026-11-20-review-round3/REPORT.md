# Round-3 candidate review: Studio shots (2026-11-20)

Studio Play session on synced code (Rojo connected; `LookDev.IDS` = 17). Shots were taken from a
scriptable client camera. Nothing was saved or published, and play mode was stopped afterwards.
`REVIEW_SHEET.jpg` combines the shots; the designer gives the verdicts.

## Shots

| File | Candidate | Note |
|---|---|---|
| `corner_warung.jpg` | `corner` | The saved camera `{480,12,500}` shows primitives floating over the void: (500,500) has no terrain. |
| `buildings_r3.jpg`, `vegetation_r3.jpg`, `props_r3.jpg`, `npcs_r3.jpg` | model families | Loaded by hand at their `ModelMapR3` slots, anchored, on a temporary ground plate, with the player for scale. |
| `spawn_baseline.jpg` / `textures_r3_wide.jpg` | `textures_r3` | Wide shot: almost no visible change. |
| `textures_r3_close_before.jpg` / `_after.jpg` | `textures_r3` | Close shot: only the stall trim, a wedge and the grass decoration change. |
| `sky_r3_wide.jpg` | `sky_r3` | Haze and colour only; the skybox did not apply (bug 2). |
| `day_cycle_1600.jpg`, `day_cycle_1800.jpg` | `day_cycle` | Golden hour (16:00) and maghrib. The night capture timed out. |

## Bugs found (UNVERIFIED fixes; LUNE tests passed with these bugs present)

1. **Docs give the wrong toggle syntax.** `LookDev.enable` is a plain function, so
   `LookDev:enable("id")`, the form in every doc, returns `false, "unknown candidate"`. The correct
   form is `LookDev.enable("id")`.
2. **The `sky_r3` skybox never applies.** It sets `Sky.SkyboxImageFront` etc., which are not real
   properties; the real ones are `SkyboxFt/Bk/Lf/Rt/Up/Dn`. It also assigns a number to
   `Atmosphere.Decay`, which takes a Color3.
3. **Model families vanish.** `LookDevModelsR3` never anchors the loaded parts. At (500,500) there
   is no ground, so the models fall and are destroyed, and the folder stays empty.
4. **Model scale is wrong.** Every r3 model is smaller than the player: the rumah is
   6.4×4.9×5.2 studs, the NPCs are about 2.4 studs tall, and the kelapa is 3.6 studs. Every model
   is also untextured grey.
5. **CC0 rig orientation.** `farmer_cc0` and `polisi_cc0` lie flat, a Z-up/Y-up import error.
6. **`corner` placement.** It is built at (500,500), off the map with no terrain, so it can't be
   judged against the real village.
7. **Review tooling.** A command-bar or `execute_luau` `require` gets a fresh LookDev with no
   appliers registered. The review loaded the applier modules into that context by hand.
