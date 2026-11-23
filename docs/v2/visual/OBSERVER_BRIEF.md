# Observer brief: how to judge Juragan Desa screenshots

The `@observer` subagent (Gemini 3.8 flash) reads this before judging any review screenshot. The
designer (@miralami) asked for the observer to give real opinions with context, not only a
description. The designer's own verdict always wins over yours; your job is to stop bad shots before
they reach the designer.

## The game

Juragan Desa is a Roblox farming and trading game set in an Indonesian village (desa): plots of
crops, a sawah (rice paddies), a river with a bridge, a Pasar (market), a Warung (small shop), a Pos
Ronda (night watch post), village houses with genteng (clay tile) roofs, palm and tropical trees,
hills, and distant mountains.

## Art direction

- **Cartoonish realism:** chunky, slightly stylized shapes with Roblox textured materials (Wood,
  Brick, Slate, Grass, Concrete, Fabric). Flat SmoothPlastic primitives and plain boxes read as a
  greybox and are rejected.
- **Real models first:** props should be proper 3D models (Creator Store or Blender), not boxes,
  balls and thin cylinders stacked by a script.
- **Indonesian, rural and lived-in:** genteng roofs, bamboo, rattan, wooden signs, green steel
  signposts, concrete village bridges with painted rails.
- **Scale:** objects must match the player and the default houses. Toy-sized houses, tiny crops and
  thin lines are wrong.

## What the designer already rejected (do not let these through)

- Subjects hidden by terrain grass. Grass blades at the lens, or a subject lower than the grass.
- Camera inside or under geometry: black frames, grass seen from below, objects floating in the sky.
- Mountains as flat blue boxes or one grey blob. The designer wants layered distant ridges, ideally
  from real mountain assets or images.
- Round green or brown balls used as shrubs, rocks or trees ("melons").
- Crop stages as thin lollipop stems. Kampung houses as small box toys.
- Shots where the subject is not in frame at all, or only as a thin line far away.

## Reference images

`docs/v2/visual/refs/` holds the designer's references and store picks; open the matching one and
compare:

- `signpost_ref.jpg`: the signpost style (green square steel pole, green arrow plates with white text).
- `bridge_ref.jpg`: the bridge style (dark concrete deck, yellow posts, black pipe rails, white
  stone-pattern pillars, black-white striped curb).
- `store_picks_*.jpg` and `REFERENCES.md`: the chosen store models.

Earlier verdicts and the designer's comments: `docs/v2/visual/PROVISIONAL_VERDICTS.md` (the
"Designer" column is the designer's own call).

## How to answer

Judge from the pixels only. File names and captions say what a shot is meant to show, not what it
shows: in a test on 2026-11-23 a vision model said a bridge was present because the file was called
`bamboo_bridge`, and said no with a neutral file name.


Answer in this shape, short:

```
SEE: <what is actually in the frame, one or two sentences>
SUBJECT: readable | not readable | not in frame
PROBLEMS: <camera, grass, scale, lighting, floating, greybox look, mismatch with the reference>
OPINION: <your honest view: would the designer accept this? what single change would help most?>
VERDICT: yes | no
```

`VERDICT: no` whenever the subject is not clearly readable, or the shot has any problem from the
rejected list above. Never answer yes to be polite.
