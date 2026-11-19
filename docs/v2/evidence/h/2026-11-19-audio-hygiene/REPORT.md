# Item 22 — Audio hygiene (2026-11-19)

Status: **SEEN-IN-STUDIO**. Branch `track/c-world-look`, fresh VERIFY-TEMP mock profile,
Rojo `localhost:34872`, Play Solo client VM. Place not saved, not published, no `profile:Save()`.
Studio returned to Edit at the end.

## What shipped

- `src/client/AudioPolicy.luau` (new, pure — no Roblox globals): config audit (every Sound has a
  registered group with volume 0..1, valid whole id, only music/ambience groups may loop), the
  playable-id set, a per-role loop-state machine (one current key per music/ambience role, outgoing
  + incoming recorded, monotonic generation as a transition identity), and the pooled one-shot
  invariant.
- `src/client/Audio.luau` (refactor): owns the actual `Sound`/`SoundGroup`/`Tween` objects. Mount
  creates one grouped, volumed Sound per configured id (17 with the shipped config) and never
  allocates again. One-shots reset `TimePosition = 0` then `Play()` on the same pooled Sound.
  Both looping roles go through the pure policy. Fade tweens are cosmetic; each outgoing Stop is
  authoritative on `task.delay(FADE_SECONDS)` guarded by a **per-Sound token** that `cancelFade`
  invalidates on replay or a newer fade.
- `tests/specs/audio_policy_spec.luau` (13 cases), `tests/specs/audio_wiring_spec.luau` (12 cases:
  static hookups + fake Sound/SoundGroup/TweenService behaviour). Suite **1908** passing
  (was 1883; +25). `selene src`: 0 errors / 0 warnings / 0 parse errors.

## Two real defects found and fixed during validation

1. **Role-generation guard leaked intermediate loops.** The first fade-out guard used
   `policy:isCurrent(role, gen)`. In the Studio census, a rapid `Cuaca` sequence left
   `ambience_badai`, `ambience_cerah`, `ambience_hujan` and `ambience_kabut` all `IsPlaying = true`
   (17 Sounds, all grouped, but 4 ambience loops). A later role change makes every earlier fade's
   generation stale, so their `Stop()` callbacks were skipped. Replaced with per-Sound fade identity:
   an intermediate outgoing loop is always stopped, while a Sound replayed in the meantime survives.
2. **TweenService does not step under this Studio MCP environment.** Probed with both a `Part`
   and a `Sound`: `TweenService:Create(...):Play()` neither animated the property nor fired
   `Completed` while `RunService.Heartbeat` ran normally. `task.delay` and `task.wait` do work.
   Therefore the audible fade tween was demoted to cosmetic and the authoritative Stop moved to an
   explicit `task.delay`, guarded by a per-Sound token. This makes loop cleanup independent of a
   callback that cannot be relied on here (and is harmless in a normal client where tweens work).

Mutation checks (restored afterwards, both green):
- removing the per-Sound token guard (`if stopTokens[sound] == token then` → `if true then`) makes
  `a rapid switch-back never lets a stale fade stop the new loop` fail;
- disabling the outgoing Stop makes both the switch-back and the distinct-switch leak spec fail.

## Studio census

Baseline after mount: 4 SoundGroups `JD_ambience:0.5`, `JD_music:0.45`, `JD_sting:0.85`,
`JD_ui:0.7`; 17 Sounds, `ungrouped = 0`, `badVol = 0`; loops playing `music_desa` and
`ambience_hujan`.

Rapid sequence via the real `ReplicatedStorage.Cuaca` attribute, 0.12 s gaps (sub-fade) then a
1.2 s settle:
`cerah, badai, kabut, hujan, cerah, badai, hujan`.

| step | looping Sounds observed mid-transition |
| --- | --- |
| cerah | music_desa, ambience_hujan, ambience_cerah |
| badai | + ambience_badai |
| kabut | + ambience_kabut |
| hujan / cerah / badai | crossfade overlap (expected before the 0.4 s fades finish) |
| hujan (after settle) | **music_desa, ambience_hujan only** |

After: `soundCount = 17` (unchanged), `grouped = 17`, `ungrouped = 0`, `badVol = 0`,
`musicLoops = 1`, `ambienceLoops = 1`. The crossfade overlap during sub-fade gaps is intentional;
the leak test is the settled count. No `MusicZone`-tagged `BasePart`s exist in this place (Track C
designer world is not built), so music-zone transitions could not be driven; the identical
fade/Stop path was exercised through the real `Cuaca` signal. The check that a rapid switch-back
does not kill a replayed loop is pinned by both the LUNE fake-service spec and the token mutation
check above.

Console: no game-code errors (only two Assistant-plugin version-change notices). `ui_click` is a
pooled non-looping Sound at volume 0.5 in `JD_ui`; one-shot pooling is proven by the fake-service
spec (25 plays, zero new Sounds).

Evidence machine-readable form: `results.json`.
