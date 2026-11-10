# Setup on a New Device

Requirements and steps to develop Juragan Desa in Roblox Studio on another computer.
The step-by-step daily workflow is in [README.md](../README.md); this file covers what to install first.

## 1. Requirements

| Requirement | Why | Notes |
|---|---|---|
| **Windows 10/11 or macOS** | Roblox Studio runs here | Studio is not available on Linux |
| **Roblox account** | Studio login, publishing | Create the place under a group or your account |
| **Roblox Studio** | Build the map, playtest | Download from create.roblox.com |
| **Git** | Clone and pull the repo | [git-scm.com](https://git-scm.com) |
| **Rokit** | Installs the pinned tools (Rojo, luau-lsp) from `rokit.toml` | [github.com/rojo-rbx/rokit](https://github.com/rojo-rbx/rokit) |
| **Rojo plugin for Studio** | Connects Studio to `rojo serve` | Installed with `rojo plugin install` (step 3) |
| **A terminal** | Running the commands below | Open a **new** terminal after installing Rokit so its PATH is picked up |

Pinned versions (from `rokit.toml`): `rojo` 7.7.1, `luau-lsp` 1.70.1.

## 2. Clone the repo

```bash
git clone https://github.com/miralami/gag-indo.git
cd gag-indo
```

If you already have the folder, `git pull` instead.

## 3. Install the toolchain

```bash
rokit install
```
```bash
rojo plugin install
```

## 4. Build the starting place

```bash
rojo build -o JuraganDesa.rbxl
```

Open `JuraganDesa.rbxl` in Roblox Studio. Do **not** start from a Baseplate template.

These files are git-ignored, so they are **not** in the repo. Recreate them on each new machine:

- `JuraganDesa.rbxl`: created by the build command above.
- `sourcemap.json`: created by `rojo sourcemap default.project.json -o sourcemap.json` (only needed for type checking).
- `.luau/globalTypes.d.luau`: needed by `luau-lsp analyze`. Download `scripts/globalTypes.d.luau` from the luau-lsp GitHub repo and save it to `.luau/`.

## 5. Studio settings (one time per place)

1. File → **Publish to Roblox** (private is fine).
2. Home → Game Settings → Security → turn on **Enable Studio Access to API Services**.
   Without this, saving does not work and progress resets every Play.
3. Game Settings → Places → **Max Players = 10**.

## 6. Every session

```bash
rojo serve
```

In Studio: Plugins → Rojo → **Connect**, then press **Play**. Edits in `src/` sync live.

## 7. Optional: type checking

```bash
rojo sourcemap default.project.json -o sourcemap.json
```
```bash
luau-lsp analyze --platform roblox --sourcemap sourcemap.json --defs ".luau/globalTypes.d.luau" --ignore "**/Packages/**" src
```

## Troubleshooting

- **`rokit` or `rojo` not found:** close and reopen the terminal, then run `rokit install` again.
- **Rojo plugin does not connect:** make sure `rojo serve` is running in this folder and the plugin version matches Rojo 7.7.1.
- **Output says "Roblox API services unavailable - data will not be saved":** see step 5.
