# Juragan Desa

A satirical Indonesian village farming game for Roblox. v2 plan: [docs/v2/PLAN.md](docs/v2/PLAN.md) · v2 technical foundation: [docs/v2/TECH.md](docs/v2/TECH.md) · designer decisions: [docs/v2/DECISIONS.md](docs/v2/DECISIONS.md) · v1 design: [docs/v1/GDD.md](docs/v1/GDD.md) · v1 dev guide: [docs/v1/TECH.md](docs/v1/TECH.md)

> **v2 status:** the foundation (M0) and farming depth (M1) are in place. Saves are schema v3 and
> migrate in place; the game now has 12 crops in three families, server-rolled rarity tiers
> (biasa → sultan), condition-driven traits, the Almanak discovery book with page rewards, a rarity
> reveal toast, a replicated state module, a tag-driven world, admin LiveConfig and an F2 admin
> panel. Next up is M2 (seasons, shop, tools, gudang). See [docs/v2/TECH.md](docs/v2/TECH.md) for the
> contract and [docs/v2/mockups/index.html](docs/v2/mockups/index.html) for the proposed UI (D1, not
> wired in).

## First-time setup (once)

1. Open a **new** terminal (so Rokit's PATH is picked up), then in this folder:
   ```bash
   rokit install
   ```
   ```bash
   rojo plugin install
   ```
2. Build the starting place file:
   ```bash
   rojo build -o JuraganDesa.rbxl
   ```
3. Open **JuraganDesa.rbxl** in Roblox Studio (not a Baseplate template; the template's spawn sits on the Pasar).
4. **For saving to work in Studio:**
   - File → Publish to Roblox (private is fine).
   - Home → Game Settings → Security → turn on **Enable Studio Access to API Services**.
   - Without these, Output says *"Roblox API services unavailable - data will not be saved"*, and progress resets every Play.
5. Game Settings → Places → **Max Players = 10** (one plot per player).

## Every session

```bash
rojo serve
```

In Studio: Plugins → Rojo → **Connect**, then press **Play**. Edits to `src/` sync live.

## Admin panel (v2)

The in-game admin panel opens with **F2** and only for allowlisted UserIds. Put your Roblox UserId in
`src/server/Live/Admins.luau` (`Admins.userIds`) — it is empty by default and enforced on the server.
The panel can override season/weather, force the cabai event on or off, grant items and inspect a
player. Changes go through `LiveConfig`, so they survive a server restart and reach every server.
See [docs/v2/TECH.md](docs/v2/TECH.md) §4–5.

Admin LiveConfig stores: `LiveConfig_v1_Studio` in Studio, `LiveConfig_v1` live. Player saves keep the
old store names (`PlayerData_v1_Studio` / `PlayerData_v1`) and migrate in place to schema v3.

## Testing

Automated tests: `lune run tests/run`. Formal manual test cases and the per-version sign-off sheet
are in [docs/testing](docs/testing/README.md). The short walkthrough below is a quick first-run
check only.

## Quick walkthrough (first run)

**Farming & economy**
1. You spawn at your plot with Rp 50 and 5 Padi seeds.
2. Walk to a brown tile → **E / tap**. The **Mencangkul** bar opens; tap when the needle is in
   the green zone three times. "Kualitas: 1.15" (or so) appears and the crop starts growing.
   **Auto** skips the minigame for quality 0.90.
3. Wait, then harvest (the **Babat** hold-release bar). Walk to the blue **PASAR** stall and
   sell. Cash goes up and the sack empties.
4. Buy seeds in **🌱 Bibit** (top right). Buy the next grey tile (its price is on the tile).
5. Earn Rp 1.000 lifetime → rank **Petani** unlocks Jagung/Cabai. Buy 12 tiles + Rp 10.000 →
   **Juragan** unlocks Durian, and your chat lines start with **[Juragan]** (Ordal pass adds
   **[Ordal]**).
6. Stop, Play again: cash, seeds, rank, tiles and planted crops are still there, and crops kept
   growing while you were away.
   - 4 minutes into the server a toast announces **🔥 Harga Cabai Meroket** and a red chip appears
     under the stats card: cabai sells ×3 for 5 minutes, then the chip disappears. Timings live in
     `Config/Game.luau` (`cabaiEvent*`).

**Cheats & the law**
7. Open **📱 HP → Curang**, oplos a growing tile (Rp 20). It ripens faster, glows green, and the
   tile label shows ⚠. The HUD 👀 Sus number climbs.
8. Sell that hot harvest at the **PASAR** — refused. Sell at **TENGKULAK GELAP** (behind the
   Pasar) for +30%; that also raises Sus.
9. Let Sus reach 60: a 📨 Surat Panggilan toast. At ~80 a raid can roll; the **BREAKING NEWS**
   overlay appears, police walk in, and you pick **Bayar Denda** or **Kasih Amplop** (75%).
   Pick the envelope and lose the roll → fine ×1.5. With no money → **Pos Ronda** countdown.
10. Walk to **Pak RT** and pay uang rokok: Sus drops and the price grows each time (10 min
    window, 3 min cooldown). **Jaminan Kilat** in the phone gets you out of the Pos Ronda.

**Lapor (2 players: Test → Server, 2 clients)**
11. A cheats near B; B gets "📱 Rekam bukti?" → **Rekam**. The token appears in B's phone with
    a countdown.
12. B walks to **POS POLISI** and taps **Lapor** (or the prompt). B gets cash + Nama Baik, A
    gets +25 Sus. Two different reporters within 5 min → **VIRAL**: A is raided immediately and
    the envelope button is greyed out.

**Phone, passes & decor**
13. **📱 HP → HP** tab shows items + bukti. **Dekorasi** tab: buy Caping (Rp 250) / Peci /
    Batik with cash; the part appears on your character and stays after respawn.
14. Neighbour online? The **Curang** tab lists 💧 Curi and 🚿 Siram for the two adjacent plots.
    Siram = +1 Nama Baik (10/day cap).
15. With real IDs in `Config/Products.luau`: a game pass grants its `Pass_*` attribute on join
    (Extra Plot = 16 tiles) and a developer product grants exactly one item, even after a
    quick rejoin. With IDs at `0` nothing prompts and nothing errors.

If anything prints **red** in Output, paste it to Claude.

## Checking code

```bash
rojo sourcemap default.project.json -o sourcemap.json
```
```bash
luau-lsp analyze --platform roblox --sourcemap sourcemap.json --defs ".luau/globalTypes.d.luau" --ignore "**/Packages/**" src
```
(`globalTypes.d.luau` comes from the luau-lsp GitHub repo, `scripts/globalTypes.d.luau`; it is
git-ignored, so download it again after a fresh clone. `Packages/ProfileStore.luau` is vendored
third-party code and is excluded.)
