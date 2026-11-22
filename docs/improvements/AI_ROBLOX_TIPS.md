# 28 tips for AI-made Roblox games (dated snapshot, 2026-11-19)

Source: YouTube "Every Trick To GOOD Ai Roblox Games" (https://www.youtube.com/watch?v=yv-ZLjaULkg).
Creator opinion, not primary docs. Sponsor content (Forge GUI asset generator) is ignored; we do not
use it. Fit column: **HAVE** = already our practice, **APPLY** = adopt now, **CHECK** = verify the
repo before acting, **LATER** = post-Gate 1 / launch, **SKIP**. Nothing here overrides `MASTER_PLAN.md`.

| # | Tip | Fit | What it means for us |
|---|---|---|---|
| 1 | Be specific in prompts | HAVE | Dispatches name scope, files, validator (AGENTS.md). |
| 2 | Talk instead of type (more context) | APPLY | User-side; long voice briefs are welcome. |
| 3 | Make the agent ask questions first | APPLY | Ask 3 to 5 questions on any ambiguous feature/art task before building. |
| 4 | Say where things go and how big | APPLY | Give placement + scale in studs/character heights for every build lane. |
| 5 | Picture beats adjective | APPLY | Attach reference screenshots (see `RESEARCH_VISUAL_TIPS.md` §1, designer references). |
| 6 | One feature at a time | HAVE | Gate 1 before features; one lane per file. |
| 7 | Never say "it's broken": paste the error/recording | APPLY | Bug reports go in `docs/testing/BUGS.md` with Studio output text. |
| 8 | Agent must playtest itself; repeat "fidelity passes" | HAVE | `SEEN-IN-STUDIO` needs evidence; add 2 to 3 look-again passes on visual work. |
| 9 | Notes/memory file | HAVE | `AGENTS.md`, MASTER_PLAN tracker, memory dir. |
| 10 | Repeated work becomes a skill | APPLY | Candidates: Studio evidence capture, asset upload + manifest entry. |
| 11 | Connect tools (Studio MCP) | HAVE | Studio MCP is main-session only. |
| 12 | Multiple agents, one master, no shared files | HAVE | Orchestration rules in AGENTS.md. |
| 13 | Match effort to task | APPLY | High for planning, low for one-line fixes; pick lane model accordingly. |
| 14 | Pre-set permissions before leaving it overnight | APPLY | Allowlist common Studio/lune/git calls so unattended runs do not stall. |
| 15 | Save a copy before big changes | HAVE | Branches + commits; Studio version history before risky place edits. |
| 16 | Lock art style first | HAVE | D11 cartoonish realism (`visual/ART.md`). |
| 17 | UI as a kit | CHECK | Confirm GUI uses one shared kit/theme, not per-screen styling. |
| 18 | Sound is half the feel | HAVE (partial) | Audio config exists; IDs must be verified, never invented. |
| 19 | Every action gets feedback: sound + shake + popup number | APPLY | Audit core actions for all three; `client/Feel/` is the home. |
| 20 | Test on phone (about 80% of players) | HAVE | Designer's Xiaomi 12 Lite measured; keep phone view in Gate checks. |
| 21 | Know the core loop; explain it in under 2 sentences | CHECK | Confirm the loop sentence exists in the plan. |
| 22 | Give players something to do in the first 10 seconds | CHECK | Audit first-session flow against this. |
| 23 | All numbers in one settings script | CHECK | Confirm tunables live in `Config/`, not scattered literals. |
| 24 | Progress saving is top priority | HAVE | Save tests + BUG-004 force-raid no-save verified. |
| 25 | Show odds for random paid items | CHECK | Roblox policy; verify any random reward shows odds and is policy-safe. |
| 26 | Watch a real player; every explanation is a fix | LATER | Playtest with a new player after Gate 1. |
| 27 | Package like a YouTube video (icon, thumbnails, several versions) | LATER | Launch task; do not invent asset IDs. |
| 28 | Ads: small spend over a long time, not a burst | LATER | Launch task. |

## Immediate adoptions (cheap, no new code)

1. Ask-questions-first on ambiguous tasks (3).
2. Placement and scale in every build brief (4); reference images for look tasks (5).
3. Bug reports carry pasted Studio output (7).
4. Visual work gets repeated look-again passes before `SEEN-IN-STUDIO` (8).
5. Feedback triple (sound, shake, number) audit of core actions (19).
6. CHECK items (17, 21, 22, 23, 25) become a short audit lane after Gate 1.
