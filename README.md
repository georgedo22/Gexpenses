# GExpenses

A lightweight, offline-first expense tracker built with **Flutter** + **Riverpod** + **SQLite (sqflite)**.

## Features

- **Balance tracking** — set an initial balance, and every expense/income updates it atomically inside a single SQLite transaction.
- **Quick expense entry** — title, amount, category, date **and time**, with an optional note.
- **Full history** — searchable, category-filtered, paged list of every expense.
- **Income management** — add, edit and delete income entries; each one adjusts the balance and shows up in the monthly cash-flow summary.
- **Reports** — daily, weekly, monthly, yearly, and custom date-range views with interactive charts (fl_chart) and comparison against the previous period. The monthly report also shows income and net cash flow.
- **Monthly budgets** — set a limit per category and watch live progress with over-budget / near-limit warnings.
- **Backup & restore** — export to CSV or JSON through the platform share sheet, import again from a file, and erase all data from Settings.
- **Currency selection** — choose your display currency during onboarding or from Settings; the choice persists across restarts.
- **Arabic & English with RTL** — full Arabic localization with automatic right-to-left layout, localized dates, and Arabic-Indic digit input support.
- **Dark mode** — follows the system theme.
- **Accessible** — semantic labels for charts and amounts, contrast-safe category colors, and reduced-motion support.
- **Runs on Android, iOS, Web, Windows, macOS, and Linux** (web uses SQLite WASM via `sqflite_common_ffi_web`).

## Architecture

```
lib/
├── core/            # Constants, theme, brand mark, shared utilities
├── data/            # SQLite database, models, repositories
├── domain/          # Business services (Expense, Report, Budget, Backup)
├── l10n/            # App strings (English + Arabic)
└── presentation/    # Riverpod providers, screens, widgets
```

Data integrity:

- All mutations that touch both an expense/income and the balance run inside `DatabaseHelper.runInTransaction`, so they can never get out of sync.
- Money is stored as **integer cents** (`amount_cents`, `current_cents`, …), so repeated additions cannot accumulate floating-point drift. Balance deltas are applied as integer cents in SQL (`adjustBalanceCentsInTx`); conversion to/from `double` happens in the model/repository boundary only.
- Schema version 2 ships a real `onUpgrade` migration that converts an existing v1 database in place and adds the `budgets` table.

## Branding

The launcher icon is generated from the vector brand mark in `lib/core/branding/brand_mark.dart`:

```bash
flutter test tool/generate_brand_assets.dart   # renders assets/branding/logo_mark.png
flutter pub run flutter_launcher_icons         # writes Android/iOS/web/desktop icons
```

## Getting started

```bash
flutter pub get
flutter run
```

Run the tests:

```bash
flutter test
```

## App size (APK / AAB)

A release build ships at **~15–25 MB per ABI**. If your APK is much larger,
you are almost certainly distributing a **debug** build (`app-debug.apk`,
often 150–200 MB) or a fat APK that bundles every CPU architecture.

```bash
# For Google Play (recommended): one .aab — Play serves per-device slices.
flutter build appbundle --release

# Per-ABI APKs for direct distribution (~15–25 MB each).
flutter build apk --release --split-per-abi

# Same, with debug symbols stripped (keep the symbols folder to
# de-obfuscate crash reports later).
flutter build apk --release --split-per-abi --obfuscate \
  --split-debug-info=build/symbols

# See exactly what contributes to the size.
flutter build apk --release --analyze-size
```

Notes:

- Never distribute `app-debug.apk` — it contains the JIT VM and debug info.
- Release builds run R8 minification and resource shrinking (see
  `android/app/build.gradle.kts` + `proguard-rules.pro`).
- Assets in this project total <200 KB; size is dominated by the Flutter
  engine + AOT snapshot per ABI, so splitting ABIs is the single biggest win.

### Download size vs. installed size

Android always reports a larger "app size" than the APK you download:

| Component | Notes |
| --- | --- |
| APK download | ~19 MB per ABI (armv7) — what users see on Play |
| Native libraries (`libflutter.so`, `libapp.so`) | ~13–15 MB uncompressed |
| ART-compiled code (`.odex`/`.vdex`/`.oat`) | Generated at install for *every* Android app |
| App data (`databases/`, `shared preferences`) | A few hundred KB for this app |

`jniLibs.useLegacyPackaging = false` keeps the libraries mapped straight out
of the APK, so they are not extracted and duplicated on device. To inspect the
real breakdown:

```bash
adb shell pm path com.gexpenses.app          # where it lives
adb shell du -sh /data/app/*gexpenses*/lib   # native libs
adb shell du -sh /data/app/*gexpenses*/oat   # compiled code
adb shell du -sh /data/data/com.gexpenses.app
```

Settings → Apps → GExpenses → Storage splits the same numbers into
*App size / User data / Cache*; clear cache after testing large exports.


The suite covers the amount input parser, the expense model, and the full data layer (transactions, balance consistency, income CRUD, budgets, CSV/JSON backup round trips, reset and the v1→v2 migration) using `sqflite_common_ffi`.

## Release checklist

- [ ] Generate your own release keystore and configure it in `android/app/build.gradle.kts` (currently signed with debug keys).
- [ ] Add a privacy policy URL before publishing to the stores.
- [ ] Bump `version` in `pubspec.yaml` for each release.
- [ ] Run `flutter test` and `flutter build web --release` (CI does both on every push).

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)
