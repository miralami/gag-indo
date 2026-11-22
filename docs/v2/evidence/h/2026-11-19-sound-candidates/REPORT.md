# Round 2 item 9 — sound candidates behind LookDev

Date 2026-11-19. Branch `track/c-world-look`. Status `SEEN-IN-STUDIO`.

## Target

For each action in the audio event list, search the Creator Store (Studio MCP `search_asset`) for
free sounds whose licence allows use; record each existing ID, licence and source in
`ASSET_MANIFEST.md`; wire them behind `LookDev` through SoundGroups, following the round-1 audio
policy. All selected assets are CANDIDATES awaiting a designer yes/no: none approved, none shipped
on by default.

## Search and selection

The audio event list is `Config/Audio.sounds` (groups `music` / `ambience` / `ui` / `sting`). Round 1
had already recorded 17 free Creator Store audio IDs with licence and source in
`ASSET_MANIFEST.md`; the only empty registry slots were the two hub music beds `music_sawah` and
`music_hutan` (both `id = 0`). `search_asset` with `scope=creator_store`, `assetType=Audio`,
`priceFilter=free` was run several times for calm rural/forest music; two free beds were chosen and
each was **verified loading in a Play VM** (`IsLoaded = true`, `TimeLength` read) before its ID was
recorded. No ID was invented.

- `music_sawah` — `9042889348`, "Close Your Eyes - 60 - No Melody", APMOfficial, free, 58.59 s.
- `music_hutan` — `9048807207`, "Cavernous Wonders 60 A", APMOfficial, free, 60.97 s.

Licence note: Creator Store audio for use in Roblox experiences (terms are Roblox's, not re-read
here; Master Plan §6 phase 4 open point). Both are recorded in `docs/v2/visual/art/ASSET_MANIFEST.md`.

## What was made

- `src/shared/SoundMap.luau` — pure data + helpers. `candidateIds` holds the two IDs, `candidateOrder`
  is the stable review order, `assetUrl(key)` builds the Roblox asset URL (so the URL literal and
  the IDs stay OUT of the adapter), and `playable()` feeds the round-1 `AudioPolicy`. It never
  touches Roblox APIs at load, so Lune specs can read it. This is the same split used by
  `IconMap` / `TextureMap` for images.
- `src/client/World/LookDevSounds.luau` — the ID-free client applier. On enable it find-or-creates
  the round-1 `JD_<group>` SoundGroups, creates one `Sound` per candidate with `Looped` / `Volume`
  from `Config/Audio.sounds`, assigns it to its `SoundGroup`, and drives loop state through
  `AudioPolicy.new(SoundMap.playable())` + `:transition(group, key)` so at most one loop per role is
  active. On disable it stops and destroys every created Sound and the `LookDevSoundCandidates`
  folder. No numeric ID or asset-URL literal lives here, so the LookDev no-ID guard passes.
- `LookDev.luau` gains an eighth pure-data `sounds` candidate (`idsSource` pointer, `soundCount = 2`,
  no numeric IDs), booted behind `pcall` in `Main.client.luau`.

## Studio proof (Play Solo, fresh Client VM, Rojo `localhost:34872`)

- `LookDev.IDS` = `plaza_lighting,police_walkin,icons,textures,npcs,crops,hubprops,sounds`;
  `hasApplier("sounds")` = true.
- `enable("sounds")` returned `true` with no warning; `current()` = `sounds`;
  `SoundMap.usingCandidates()` went `false → true → false`.
- Round-1 SoundGroups present: `JD_ambience,JD_music,JD_sting,JD_ui`.
- Two candidate Sounds appeared under `LookDevSoundCandidates`, both in `JD_music`, `loop=true`,
  `vol=0.3`, **both `loaded=true`** after a 6 s wait:
  - `music_sawah` → `rbxassetid://9042889348`, `len=58.59`, `playing=false`.
  - `music_hutan` → `rbxassetid://9048807207`, `len=60.97`, `playing=true`.
- `activeLoops` = `music_hutan`: exactly one looping music bed is active, the other is loaded but
  pooled — the round-1 AudioPolicy hygiene contract.
- `disable()` returned `true`; both Sounds and the folder were destroyed (`2 → 0`).

## Gallery

`docs/v2/visual/CANDIDATES.md` has a `sounds` row (toggle, render/proof, cost, blank designer yes/no)
and wiring proof. There is no image render for audio; the review artifact is the in-Studio
enable/disable proof recorded here. No agent graded the sound aesthetically — audition and yes/no
belong to the designer.

## Validation

`lune run tests/run.luau`: **All 1964 tests passed** (up from 1956; a new
`tests/specs/soundmap_spec.luau` plus eight-candidate / sound-applier updates to
`tests/specs/lookdev_candidates_spec.luau`). `selene src`: 0 errors / 0 warnings / 0 parse errors.
Both IDs are in `docs/v2/visual/art/ASSET_MANIFEST.md`. Place was not saved and not published.
