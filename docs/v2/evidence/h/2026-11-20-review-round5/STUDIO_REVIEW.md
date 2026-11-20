# Round-5 candidates: real Studio shots (2026-11-20, main session)

Shots in `shots/` come from a Play session on synced code. The cameras were saved scriptable client
cameras, and each candidate was enabled with `LookDevReview.enable`. Nothing was saved or published,
and Play was stopped afterwards.

The first attempt rendered an empty 3D view (HUD only), in Edit mode as well. Bringing the Studio
window to the front fixed it, so the blank captures opencode reported were a viewport/window issue,
not game code. `REVIEW_ROUND5_STUDIO.html` is the review sheet. Verdicts belong to the designer.

## Findings

1. **`sky_r5`**: the biggest improvement: a blue sky, light cumulus, Cover 0.4, and no slabs. It still
   reads slightly dull.
2. **`spawn_ground_r5`**: the white kerbs are gone from the front path, but the back road is still
   asphalt-dark. Tall grass now covers the flower beds.
3. **`spawn_r5`**: the five villagers stand in a straight row, like a queue. It still doesn't feel
   lived-in.
4. **`npcs_r5`**: the R15 villagers are solid and upright, but plain: single-colour shirts and **0
   accessories** on all five, so the three hat IDs never land. The saved camera sees their backs
   (they face -Z and the camera sits at +Z).
5. **`vegetation_r5`**: the kelapa is out, the pisang is in and the bamboo is denser. Pines still show
   in the background, and the plants sit far from the camera.
6. **`textures_r4`** after the darkening fix: the ground is now bright red laterite and the grass is
   straw-yellow dry grass. It reads as desert, not a green village.
7. **`props_r5`**: the tools got *smaller* than in round 4 (gerobak 3.0 studs, was 6.0; sumur 2.5,
   was 5.0). The saved camera is still pine-screened. Jemuran and the karung semen stack read well.
