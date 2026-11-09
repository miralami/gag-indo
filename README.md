# Juragan Desa

A satirical Indonesian village farming game for Roblox. Design: [docs/GDD.md](docs/GDD.md) · Dev guide: [docs/TECH.md](docs/TECH.md)

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

## Week 1 test (should all work)

1. You spawn at your plot with Rp 50 and 5 Padi seeds.
2. Walk to a brown tile → **E / tap** → "Tanam Padi". A 1:00 countdown appears.
3. Wait, then harvest. Walk to the blue **PASAR** stall in the middle → sell.
4. Buy seeds in **Toko Bibit** (top right), buy the grey tile next to your field.
5. Stop, Play again: cash, seeds and planted crops are still there, and crops kept growing while you were gone.

If anything prints **red** in Output, paste it to Claude.

## Checking code

```bash
rojo sourcemap default.project.json -o sourcemap.json
```
```bash
luau-lsp analyze --platform roblox --sourcemap sourcemap.json --defs "@roblox=globalTypes.d.luau" --ignore "**/Packages/**" src
```
(`globalTypes.d.luau` comes from the luau-lsp GitHub repo, `scripts/globalTypes.d.luau`.)
