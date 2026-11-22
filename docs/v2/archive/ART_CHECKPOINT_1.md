# Art Checkpoint 1 Report

## Status
- **W1 (Theme + Icons)**: Selesai.
- **W2 (Screens)**: Selesai.
- **Total Tests**: 463 passed (`lune run tests/run`).

---

## File yang disentuh

### Baru
- `src/shared/Config/Visuals.luau` (single source of truth: 12 token palette, type scale, space scale, radius, outline, shadow, touch, fonts, icon slots).
- `src/client/UI/Icons.luau` (icon wrapper: id 0 + procedural on-palette chip fallback ASCII).
- `tests/specs/visuals_spec.luau` (test suite: palette hex, type scale, touch, font names, icon fallback ASCII, no emoji in strings).

### Diubah
- `src/client/UI/Theme.luau` (token palette `paper`/`ink`/`padi`/`senja`/dll, `Theme.contrastText`, sticker outline 2px + shadow 4px, `Theme.toast`, kompatibilitas field legacy).
- `src/shared/Strings.luau` (pembersihan seluruh emoji player-facing, penambahan key `phone_home`, expose `Strings.raw`).
- `src/client/UI/Hud.luau` (migrasi palette, LuckiestGuy untuk display cash, eliminasi `Color3.fromRGB`, touch target 44px).
- `src/client/UI/Phone.luau` (navigasi App Grid Home + tombol Back `<` 44px, chip icons pada section label, eliminasi `Color3.fromRGB`, eliminasi emoji).
- `src/client/UI/RaidOverlay.luau` (migrasi palette `merah`/`kunyit`/`senja`, display font, eliminasi `Color3.fromRGB`, tombol 44px).
- `src/client/UI/Minigame.luau` (migrasi palette `paper`/`ink`/`merah`, display font, tombol close 44px `X`).
- `src/client/Minigames/Babat.luau` (bar `ink`, zone `padi`, fill `senja`, eliminasi `Color3.fromRGB`).
- `src/client/Minigames/Mencangkul.luau` (bar `ink`, zone `padi`, needle `kunyit`, eliminasi `Color3.fromRGB`).
- `src/client/UI/Tiles.luau` (status labels menggunakan token `padi`/`senja`/`paper`, eliminasi `Color3.fromRGB`).
- `src/client/UI/Admin.luau` (header display font, button 44px, eliminasi `Color3.fromRGB` & emoji `👤`/`⚙`).
- `src/client/UI/Evidence.luau` (display font `merah`, tombol 44px, eliminasi emoji `📱`).
- `src/client/UI/Leaderboard.luau` (header display font `merah`, eliminasi aksen kuning rendah kontras).
- `tests/run.luau` (registrasi `visuals_spec`).

---

## Ringkasan Perubahan Visual

1. **Palette Terpadu (visual/ART.md §3)**:
   - 12 token: `kertas` (`#f3e9d2`), `tinta` (`#2b2118`), `tinta_lembut` (`#5b4a38`), `senja` (`#f6c97a`), `padi` (`#9bb25a`), `daun` (`#6f8a3f`), `genteng` (`#a8452f`), `merah` (`#a83226`), `bambu` (`#b98a5a`), `kunyit` (`#c99a2e`), `indigo` (`#3b4f6b`), `malam` (`#1f4e6b`).
   - Seluruh pemanggilan `Color3.fromRGB` di layer client UI telah dieliminasi 100%. Sisa `Color3` di layer client hanya:
     - `Theme.luau`: konversi hex palette via `Color3.fromHex`.
     - `Icons.luau`: fallback color resolving via `Color3.fromHex`.
     - `Hud.luau`: `crop.color:Lerp(Color3.new(0, 0, 0), 0.55)` (warna benih dinamis dari Crop config).

2. **Tipografi & Spacing (visual/ART.md §8)**:
   - Display font: `LuckiestGuy` (28px title / 18px heading).
   - Body font: `Nunito` (13px body / 11px small).
   - Touch targets minimum 44px pada seluruh button interaktif (seed bar, close button, shop rows, phone apps, admin button, evidence record).

3. **Sticker Outline & Hard Shadow (visual/ART.md §4)**:
   - `Theme.button` dan `Theme.card` menerapkan outline 2px tinta (`UIStroke`) + offset shadow 4px tanpa blur (kecuali di dalam container layout berulang `UIListLayout`/`UIGridLayout`).

4. **Phone Home Grid**:
   - Phone dirombak dari tab horizontal yang sempit menjadi App Grid beranda (6 app icon kartu: HP, Kebun, BayarLater, Tugas, Curang, Dekorasi) dilengkapi tombol Back `<` 44px dan judul halaman kontekstual.

5. **Icon Slots & Emoji Removal**:
   - Seluruh emoji di teks UI dan `Strings.luau` telah dihapus total.
   - Digantikan oleh sistem slot `Icons.luau` dengan id `0` dan badge fallback ASCII kontras.

---

## Belum Diverifikasi di Studio
- Tampilan riil font `LuckiestGuy` dan `Nunito` pada mobile device (Lune menguji token enum, rendering aktual terjadi di Roblox client).
- Tampilan sibling drop-shadow `Theme.sticker` pada resolusi sempit (~320px screen width).
- Visual feel transisi App Grid Phone di layar sentuh fisik.

---

## Keputusan Dibutuhkan
1. **Aksen Ungu Rarity Langka**: `visual/ART.md` §12 mencatat warna ungu untuk Langka belum masuk dalam 12 token palette dasar. Perlu penetapan kode hex ungu di `visual/ART.md` sebelum W3 (Rarity pass).
2. **Icon Asset IDs**: Saat ini seluruh 24 slot icon menggunakan ID `0` (fallback chip ASCII). Asset ID final dari designer diperlukan saat asset upload siap.

---

## Commit yang Disarankan
- `feat(art): W1 visual tokens, theme kit, and icons system`
- `refactor(art): W2 screens pass with palette tokens, mobile 44px targets, and app grid phone`
- `test(art): add visuals and palette verification specs`
