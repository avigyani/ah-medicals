# AH MEDICALS — Inventory App (Flutter, Phase 1)

Medical store inventory for **AH MEDICALS — Owner: Ashifa**.
Local-only, offline, no login, no server, no Firebase. All data stays on
the phone in SQLite.

## Phase 1 features

- **Dashboard** — total medicines, total stock value (stock × purchase
  price), low-stock count, near-expiry (90 days) count, expired count.
  Tap any card to see that list. Header shows shop name + Owner: Ashifa.
- **Medicines** — search by name / generic / company / batch / barcode;
  filter chips: All, Low Stock, Near Expiry, Expired; sort by name or
  expiry date. Each row shows name, company, batch, expiry (red = expired,
  amber = within 90 days), stock, MRP.
- **Add / Edit / Delete medicine** — name, generic, manufacturer,
  category (Tablet, Capsule, Syrup, Injection, Ointment, Drops, Other),
  batch no, expiry date (date picker), MRP, purchase price, selling price,
  stock qty, minimum stock level, GST% (0/5/12/18), HSN, barcode (type or
  scan with camera), rack/location, supplier, prescription required
  (Rx yes/no). Validation: name, batch, expiry, MRP, stock required;
  duplicate batch + name warns before saving.
- **Stock In / Out** — from a medicine: Stock In (purchase — qty,
  supplier, purchase price) and Stock Out (sale / damage / expired —
  qty + reason). Every movement is logged in Stock History. Stock never
  goes below zero. Expired medicines are blocked from Sale with a warning.
- **Alerts** — low stock when stock ≤ min level; near expiry within 90
  days (amber) and 30 days (orange-red); expired listed separately.
- **Suppliers** — add name + phone; pick a supplier when adding stock
  or a medicine.
- **Reports** — stock value summary, low-stock list, near-expiry list,
  expired list, and "Delete all SAMPLE medicines".
- **Seed data** — 12 realistic sample medicines (Dolo 650, Novamox 500,
  Azithral 500, Cetzine, Electral ORS, Pan 40, Glycomet 500, Uprise-D3,
  Ascoril LS, Augmentin 625, Volini Gel, Crocin Advance) + 2 sample
  suppliers, all marked SAMPLE and deletable, so the app works at once.
  Seed includes 1 expired, 1 expiring within 30 days, 1 within 90 days,
  and 2 low-stock items to show the alerts.
- **Barcode scan** — camera scan via `mobile_scanner` (CAMERA permission
  in the manifest). Manual barcode entry always works as fallback.

## Project structure

```
ah-medicals-inventory/
  pubspec.yaml            # sqflite, path, mobile_scanner
  lib/
    main.dart             # App + bottom navigation (5 tabs)
    models.dart           # Medicine / Supplier / StockMovement + pure logic
    db.dart               # SQLite helper (CRUD, movements, seed)
    seed.dart             # 12 sample medicines + 2 suppliers
    scanner.dart          # Barcode scan screen
    screens.dart          # Dashboard, Medicines, Form, Detail, Suppliers,
                          # History, Reports, About
  test/
    logic_test.dart       # Expiry maths, low stock, stock value, seed sanity
  .github/workflows/build-apk.yml   # GitHub Actions APK build
```

## Build the APK (GitHub Actions — the reliable path)

The local VM cannot run Gradle: the sandbox blocks Java TCP loopback,
so the Gradle daemon (Java → Java over 127.0.0.1) cannot communicate
("Could not receive a message from the daemon"). `flutter analyze` and
`flutter test` pass locally; the APK must be built on GitHub Actions,
exactly like Avi AI was.

1. On github.com, create a new repo, e.g. `ah-medicals-inventory`
   (you create it — Muse cannot create repos).
2. Upload the ZIP contents to the repo (or `git push` from your PC).
3. Go to the repo → **Actions** → **Build AH MEDICALS APK** → **Run
   workflow** (it also runs on every push to `main`).
4. When it finishes (green tick), open the run → **Artifacts** →
   download **ah-medicals-apk** → install `app-release.apk` on the phone.

Package: `com.ahmedicals.inventory`, version 1.0.0+1, minSdk 21+.

## Verified here (2026-11-26)

- `flutter pub get` — OK (sqflite 2.4.2, mobile_scanner 7.x resolved).
- `flutter analyze` — no errors (14 info-level lints only).
- `flutter test` — 6/6 passed (expiry day counts, status bands,
  low-stock threshold, stock value, date validation, seed counts).
- Local `flutter build apk --release` — **BLOCKED, not a code problem**:
  the sandbox intercepts Java TCP loopback connections
  ("muse: Other TCP connections is turned off for this assistant"),
  so the Gradle daemon cannot start. Verified with a plain Java socket
  test: Python/curl loopback works, Java loopback is intercepted.
  The APK must come from the GitHub Actions workflow above.

## Phone test (his step)

1. Install the APK, open it — Dashboard shows 12 SAMPLE medicines,
   stock value, 2 low stock, 2 near expiry, 1 expired.
2. Medicines → search "Dolo", filter "Expired" (Ascoril LS), sort by Expiry.
3. Open Uprise-D3 → Stock In 10 → stock becomes 15; Stock Out 3 (Sale)
   → History shows both.
4. Try Stock Out on Ascoril LS (expired) with reason Sale — it must refuse.
5. Add a real medicine with the camera scan button; check the barcode fills in.
6. Reports → check the lists, then "Delete all SAMPLE medicines".

## Phase 2 (not built)

Billing / sales, purchase orders, GST reports, cloud backup, multi-user.

## Build

GitHub Actions builds the release APK on every push to main. Download it from the run's artifact `ah-medicals-apk` (`app-release.apk`).
