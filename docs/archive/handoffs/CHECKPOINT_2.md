# Roadmap Checkpoint 2 Report (Phase B: B1–B6)

Tanggal: 2026-11-12  
Status: CHECKPOINT 2 SELESAI — MENUNGGU REVIEW SEBELUM PHASE C  
Total Test Suite: **479 tests passed, 0 failures** (`lune run tests/run`)

---

## 1. Dokumen yang Diselesaikan pada Checkpoint 2

| Milestone | Dokumen Deliverable | Rangkuman Hasil | Status |
|---|---|---|---|
| **B1** | `docs/v2/audits/SECURITY_AUDIT.md` | Audit 23 remote client->server, verifikasi rate limit token-bucket, sanitasi input, normalisasi `Market_Sell`, penambahan spec `tests/specs/security_spec.luau`. | PASS |
| **B2** | `docs/v2/audits/BALANCE.md` | Model simulasi progression pacing (Gurem ke Petani ~10 menit, Petani ke Juragan ~50 menit), Faucet/Sink rasio, analisis plafon pinjol (3x principal ceiling), penambahan spec `tests/specs/balance_spec.luau`. | PASS |
| **B3** | `docs/v2/audits/PERF_AUDIT.md` | Audit 14 loop server (semua non-blocking dengan interval 0.25s s/d 60s), utilisasi budget DataStore ~16% (sangat aman di bawah kuota 120 req/m), batching state 4Hz, 72 ubin part hemat memori. | PASS |
| **B4** | `docs/v2/audits/FTUE_AUDIT.md` | Walkthrough terpandu 5 menit pertama (Plant -> Harvest -> Sell -> Buy -> Discovery HP), resolusi friction point touch target 44px dan Phone App Grid, verifikasi loop retensi D1-D7. | PASS |
| **B5** | `docs/v2/audits/LOCALIZATION.md` | Audit kamus `Strings.luau` (>200 keys), 100% dwibahasa ID & EN, verifikasi auto-detect locale engine Roblox, zero emoji compliance, pengujian validasi string di `tests/specs/visuals_spec.luau`. | PASS |
| **B6** | `docs/v2/LAUNCH.md` | Rekomendasi kuesioner rating Roblox 9+ (parodi hukum & simulasi kredit kartun tanpa uang riil), spesifikasi aset toko (512x512 icon, 1920x1080 thumbnail), copywriting toko ID/EN, dan checklist pra-peluncuran. | PASS |

---

## 2. File Baru & Berubah pada Phase B

### File Baru
- `docs/v2/audits/SECURITY_AUDIT.md`
- `docs/v2/audits/BALANCE.md`
- `docs/v2/audits/PERF_AUDIT.md`
- `docs/v2/audits/FTUE_AUDIT.md`
- `docs/v2/audits/LOCALIZATION.md`
- `docs/v2/LAUNCH.md`
- `docs/archive/handoffs/CHECKPOINT_2.md`
- `tests/specs/security_spec.luau` (pengujian rate limit, input sanity, admin isolation)
- `tests/specs/balance_spec.luau` (pengujian pacing waktu, margin panen, plafon pinjol)

### File Diubah
- `src/server/Economy/EconomyService.luau` (normalisasi argumen remote `Market_Sell` 1-param / 2-param)
- `tests/specs/visuals_spec.luau` (penambahan assertion kelengkapan key dwibahasa ID/EN pada `Strings.raw`)
- `tests/run.luau` (registrasi `security_spec` dan `balance_spec`)

---

## 3. Hasil Verifikasi Test Suite
```text
Config: 36 tests PASS
Produce: 19 tests PASS
State: 15 tests PASS
Seasons: 28 tests PASS
ShopStock & ShopService: 24 tests PASS
Pasar supply and demand: 8 tests PASS
Tool & Storage: 19 tests PASS
WorkerService: 10 tests PASS
Onboarding: 8 tests PASS
DebtService: 11 tests PASS
QuestService: 3 tests PASS
LiveConfig: 17 tests PASS
Rarity & Traits: 19 tests PASS
AlmanakService: 10 tests PASS
RateLimit: 7 tests PASS
SusService & RankService: 28 tests PASS
EconomyService: 27 tests PASS
Receipts & Passes: 20 tests PASS
PlayerData.migrate: 23 tests PASS
Leaderboard: 28 tests PASS
Analytics: 14 tests PASS
Visuals & Art Tokens: 6 tests PASS
Security & Server Authority: 8 tests PASS
Economy & Progression Balance: 7 tests PASS

Total: 479 tests passed, 0 failed.
```

---

## 4. Keputusan Dibutuhkan / Langkah Berikutnya
1. **Penerbitan Produk Toko**:
   - Creator Dashboard perlu mengisi ID Developer Product dan GamePass di `Products.luau` dan `Passes.luau` sebelum rilis publik (saat ini bernilai placeholder `0`).
2. **Review Checkpoint 2**:
   - Menunggu persetujuan reviewer sebelum melanjutkan ke Phase C (v2.1: Social, Pasar Gelap, Polisi Desa deep pass) atau Phase W3–W5 pada Art Pass.
