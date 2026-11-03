# GExpenses

A lightweight, offline-first expense tracker built with **Flutter** + **Riverpod** + **SQLite (sqflite)**.

## Features

- **Balance tracking** — set an initial balance, and every expense/income updates it atomically inside a single SQLite transaction.
- **Quick expense entry** — title, amount, category, date **and time**, with an optional note.
- **Reports** — daily, weekly, monthly, yearly, and custom date-range views with charts (fl_chart) and comparison against the previous period.
- **Income** — record income entries that credit your balance.
- **Currency selection** — choose your display currency from Settings; the choice persists across restarts.
- **Dark mode** — follows the system theme.
- **Runs on Android, iOS, Web, Windows, macOS, and Linux** (web uses SQLite WASM via `sqflite_common_ffi_web`).

## Architecture

```
lib/
├── core/            # Constants, theme, shared utilities
├── data/            # SQLite database, models, repositories
├── domain/          # Business services (ExpenseService, ReportService)
├── l10n/            # App strings
└── presentation/    # Riverpod providers, screens, widgets
```

Data integrity: all mutations that touch both an expense/income and the balance run inside `DatabaseHelper.runInTransaction`, so they can never get out of sync.

## Getting started

```bash
flutter pub get
flutter run
```

Run the tests:

```bash
flutter test
```

## Release checklist

- [ ] Generate your own release keystore and configure it in `android/app/build.gradle.kts` (currently signed with debug keys).
- [ ] Replace the default Flutter launcher icon with your own (e.g. via `flutter_launcher_icons`).
- [ ] Add a privacy policy URL before publishing to the stores.
- [ ] Bump `version` in `pubspec.yaml` for each release.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

