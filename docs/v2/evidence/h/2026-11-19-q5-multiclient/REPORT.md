# H — Q5 ten-player / multi-client attempt — 2026-11-19

Track H, Gate 1 Q5: "Thirty-minute soak with the harness, and a ten-player session, with no leak,
no desync and no stuck state." The soak half is done (`h/2026-11-14-soak/`). This file records the
honest attempt at the **ten-player half** and why it is blocked in this environment.

## What was attempted

1. Enumerated the complete Roblox Studio MCP tool surface available to the main session (the only
   session that can drive Studio). The full tool list is:
   `auto_setup_avatar`, `character_navigation`, `create_skill`, `edit_skill`, `execute_luau`,
   `generate_animation`, `generate_avatar`, `generate_material`, `generate_mesh`,
   `generate_procedural_model`, `generate_scene`, `generate_texture`, `get_console_output`,
   `get_studio_state`, `http_get`, `insert_asset`, `inspect_instance`, `list_roblox_studios`,
   `list_skills`, `multi_edit`, `open_cloud_invoke`, `save_place`, `screen_capture`, `script_grep`,
   `script_read`, `script_search`, `search_asset`, `search_game_tree`, `segment_mesh`, `skill`,
   `start_stop_play`, `store_image`, `subagent`, `submit_feedback`, `upload_image`,
   `user_keyboard_input`, `user_mouse_input`, `wait_job_finished`.
2. Targeted search for "team test / multi client / local server / player / run" over that surface.
   No tool starts a Local Server, spawns additional clients, or runs a Studio team test.
   `start_stop_play` only launches/stops a single **Play Solo** session (verified: state returns
   "Current Studio Mode: Play", one player via `Players:GetPlayers()`).
3. Checked whether Luau could substitute: `execute_luau` runs in one DataModel (Client or Server)
   of the single Play Solo instance. Roblox exposes no scriptable API to start a Local Server or
   create simulated clients from inside a running place; Team Test / Local Server is a Studio UI
   feature, not a TestService method. So there is no in-game path to N clients either.

## Result

The ten-player half cannot be produced here. The tools to open a Studio Local Server, add test
clients, or run Team Test are not exposed by this MCP bridge, and no scriptable substitute exists.
This is a **tool-capability** block, not a game defect — nothing in the game failed.

Status: **BLOCKED** — needs a human at Roblox Studio's Test tab with a Local Server and several
Test clients (or a published place with real players, which is separately Q6/G7). The harness
`enable` gate is Studio-admin-only and already passes here, so once a human opens the extra
clients, `HARNESS.md` §2–§4 can be replayed in each. The 30-min soak client half is already
`SEEN-IN-STUDIO` (`h/2026-11-14-soak/soak.json`); only the multi-client dimension is missing.

Machine-readable detail in `results.json`.
