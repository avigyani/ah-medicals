# DawaKhata — Medical Store Inventory (Flutter, Phase 1)

Medical store inventory for **any** medical shop — generic app, no shop
name or owner hardcoded. Local-only, offline, no login, no server, no
Firebase. All data stays on the phone in SQLite.

## Phase 1 features

- **Dashboard** — total medicines, total stock value (stock × purchase
  price), low-stock count, near-expiry (90 days) count, expired count.
  Tap any card to see that list.
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
  expired list, and "Delete all SAMPLE medicines" (for old installs that
  still carry sample data).
- **Barcode scan** — camera scan via `mobile_scanner` (CAMERA permission
  in the manifest). Manual barcode entry always works as fallback.

The app starts empty — add your own medicines. No sample data is seeded.

## Project structure

```
dawakhata/
  pubspec.yaml            # sqflite, path, mobile_scanner
  lib/
    main.dart             # App + bottom navigation (5 tabs)
    models.dart           # Medicine / Supplier / StockMovement + pure logic
    db.dart               # SQLite helper (CRUD, movements)
    scanner.dart          # Barcode scan screen
    screens.dart          # Dashboard, Medicines, Form, Detail, Suppliers,
                          # History, Reports, About
  test/
    logic_test.dart       # Expiry maths, low stock, stock value
  .github/workflows/build-apk.yml   # GitHub Actions APK + AAB build
```

## Build (GitHub Actions — the reliable path)

The local VM cannot run Gradle: the sandbox blocks Java TCP loopback,
so the Gradle daemon (Java → Java over 127.0.0.1) cannot communicate.
`flutter analyze` and `flutter test` pass locally; the APK/AAB must be
built on GitHub Actions.

Repo: `avigyani/ah-medicals` (branch `main`). On every push, the
**Build DawaKhata APK + AAB** workflow runs: `flutter pub get` →
`analyze` → `test` → `flutter build apk --release` → artifact
**dawakhata-apk** (`app-release.apk`).

The Play Store bundle (**dawakhata-aab**, `app-release.aab`) builds only
when the repo secret `UPLOAD_KEYSTORE_PASSPHRASE` exists — it decrypts
the upload keystore (`android/upload-keystore.enc.b64`, AES-256) and
signs the bundle with it. Without the secret the AAB step is skipped
and the APK still builds (debug-signed, for direct install testing).

Package: `com.dawakhata.app`, version 1.0.0+1, minSdk 21+.

## Phone test (his step)

1. Install the APK, open it — Dashboard starts empty (0 medicines).
2. Add a medicine (Add medicine → Save medicine), check it appears.
3. Stock In 10 → stock rises; Stock Out 3 (Sale) → History shows both.
4. Try Stock Out on an expired medicine with reason Sale — it must refuse.
5. Add a medicine with the camera scan button; check the barcode fills in.
6. Reports → check the lists.

## Phase 2 (not built)

Billing / sales, purchase orders, GST reports, cloud backup, multi-user.
