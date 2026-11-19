# Gate 1 — designer's one-page checklist

These are the six Gate 1 rows still open. Everything else is already closed. Each row below is
self-contained: do the clicks, look at what it says, save the evidence in the named folder. This is
the short version of `GATE1.md`; that file has the full criterion wording and status history.

**Before any row.** In the repo run `rojo serve` and leave it open. In Studio open
`JuraganDesa.rbxl`, then Plugins → Rojo → **Connect** and wait for "Synced". Check Game Settings →
Security → **Enable Studio Access to API Services** if the row needs saving. For phone-size rows,
Test tab → Device → **iPhone 14** *before* pressing F5, then press F5 (Play Solo) and wait for
`[JuraganDesa] server started` with no red errors. Copy Output to `output.log` in the evidence
folder. Use the four status words exactly: `SEEN-IN-STUDIO`, `LUNE-ONLY`, `UNVERIFIED`, `BLOCKED`.

---

## 1. G4b — read every label at phone size

1. Set Device → iPhone 14, press F5.
2. Move to the **plot**, then the **Pasar**, then the **warung** (WASD; use the harness `teleport`
   command from `HARNESS.md` §4 if walking is slow).
3. At each place look at every world sign and every HUD label. Nothing may overlap another label,
   clip off the screen, or hide under the HUD.
4. Take a screenshot at each of the three places. If a label is bad, write it in `BUGS.md`, fix it,
   and repeat the screenshot.

**Look for:** overlapping text, cut-off words, labels behind the HUD.
**Evidence:** `docs/v2/evidence/h/2026-11-19-g4b-phone/` — three PNGs + `REPORT.md` saying what you
checked. Then mark G4b `SEEN-IN-STUDIO` in `GATE1.md`.

## 2. G6 — frame rate and instance count on the phone emulator

1. Set Device → iPhone 14, press F5, and **click the Studio window so it has focus** (an unfocused
   Studio throttles to ~15 fps and gives a useless reading).
2. Stand at the plot for 10 s, then at the Pasar for 10 s. Open MicroProfiler (Developer Console →
   MicroProfiler) and read the fps shown, or read `Stats` from the Studio command bar:

   ```lua
   local s = game:GetService("Stats")
   print("frame time", s.FrameTime) -- roughly 1 / this is fps; confirm against MicroProfiler
   print("descendants", game:GetDescendants())
   print("playergui", game.Players.LocalPlayer.PlayerGui:GetDescendants())
   ```

3. Record both fps readings and both counts. Target is 60 fps on a mid-range Android; a focused
   emulator reading is what we can measure here. The old 15.0 reading was unfocused — do not reuse
   it.

**Evidence:** `docs/v2/evidence/h/2026-11-19-perf-phone/REPORT.md` with fps at plot/Pasar, the two
counts, and `output.log`. Then mark G6 `SEEN-IN-STUDIO`.

## 3. G7 — five real people, ten minutes each

1. Get **five different people**, each on their **own phone**, with no help or coaching from you.
2. Each plays for ten minutes. Say nothing except "go".
3. Write down every moment they pause, ask "what do I tap?", or get stuck. Also note anything they
   say is confusing.
4. Fix each confusion point or log it as a bug in `BUGS.md`. Repeat the session if you changed
   something that could affect it.

**Look for:** confusion, stuck states, anything needing an explanation.
**Evidence:** notes in `BUGS.md` plus a session log under `docs/v2/evidence/h/2026-11-19-g7-five-players/`.
Then mark G7 `SEEN-IN-STUDIO`.

## 4. Q5 — ten players at once (the only missing half)

The 30-minute single-client soak is already clean. Only the **many-clients** half is open.

1. Test tab → **Start** with **Local Server** on. Add test clients until you have **ten players**
   (start with two to check the setup, then go to ten).
2. In each client's command bar, enable the harness and confirm it prints `Harness on.` (see
   `HARNESS.md` §2–§3).
3. In every client, run the §2–§4 loop from `HARNESS.md`. Do this for at least a few cycles; if you
   can, let it run to the 1800 s soak deadline.
4. After each action, compare the clients: same cash, seeds, tiles and rank for the same action.
   A difference is **desync** — save it. Note any client that stops replying (**stuck**).
5. Save the server memory series during the run and the full multi-client Output.

**Look for:** clients disagreeing, a client that stops responding, memory climbing steadily.
**Evidence:** `docs/v2/evidence/h/2026-11-19-q5-multiclient-closed/` — `REPORT.md`, `results.json`
(one row per player), `output.log`. Then mark Q5 `SEEN-IN-STUDIO`.

## 5. Q6 — save and reload in a published place

1. Confirm place ownership decision **D-G2** (designer owns the private test place).
2. Studio → File → **Publish to Roblox** → create a **private** place. Keep "Enable Studio Access
   to API Services" on.
3. Play as a real player. Note the exact numbers: cash, seeds, tiles owned, what is planted. Use
   the harness `status` command if you want a printed table.
4. Leave the game (Esc → Leave). Wait a few seconds. **Rejoin** the same private place.
5. Compare the numbers. Nothing may reset: same cash, seeds, tiles, plantings.

**Look for:** anything that resets or doubles after rejoin.
**Evidence:** `docs/v2/evidence/h/2026-11-19-published-persistence/REPORT.md` with the before and
after numbers, plus `output.log`. Then mark Q6 `SEEN-IN-STUDIO`.

## 6. Q7 — touch only, real mid-range Android

1. Install the Roblox app on a real mid-range Android phone. Join the same private place.
2. Play **touch only** — no keyboard, no mouse. Ten minutes.
3. Every action must work by tapping: plant, harvest, sell, buy, open/close the phone, minigame,
   raid. Note the frame rate you see.
4. Save screenshots of the main screens at the phone's own resolution.

**Look for:** any action you cannot do by touch, and a frame rate far below 60.
**Evidence:** `docs/v2/evidence/h/2026-11-19-device-touch/` — shots + a fps note. Then mark Q7
`SEEN-IN-STUDIO`.

---

**G1 closes last**, by itself, once every `Q#` row passes. **G4** (no placeholders) is a separate
art block on tracks C/G/E — it is not part of this checklist.
