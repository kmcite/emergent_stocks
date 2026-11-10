# emergent_stocks

Flutter app for your **medicine bag**: what you carry daily, **expiry dates**, and **emergency** meds (EpiPen, nitro, etc.). Data is stored locally with **ObjectBox**; theme uses a **liquid glass** look (translucent panels, no blur). Optional PocketBase sync stays behind `lib/sync/`.

This document doubles as the **project conventions** reference for new work in this repo.

---

## Stack

| Layer | Choice |
| --- | --- |
| SDK | Dart `^3.13.0` (primary constructors, `this { }` initializer blocks) |
| UI | Flutter Material 3, global font **SUSE Mono** |
| Persistence | ObjectBox 5.x + `path_provider`; prefs via `shared_preferences` |
| Optional sync | Hybrid push/pull via `lib/sync/` (PocketBase REST); app code never imports it |
| Routing | Custom `AppRouter` (`lib/utils/router.dart`) + `MaterialApp.router` |
| Modals | Local `navigation` package (`../navigation`) — `context.pushDialog`, etc. |
| State | In-house **signals** + **providers** (not Riverpod/Bloc) |

---

## Directory layout

```
lib/
  main.dart              # WidgetsFlutterBinding, ProviderScope, Application
  models/                # @Entity() ObjectBox models
  services/              # DatabaseService (local source of truth)
  sync/                  # Optional backend sync only — do not import from ui/business
  business/              # Domain “managers” + top-level *Provider declarations
  ui/                    # Screens and dialogs (active UI layer)
  utils/
    core.dart            # Signal, Computed, Effect, SignalConsumer
    provider.dart        # ProviderScope, provider(), context(provider)
    collections.dart     # ListSignal, MapSignal, SetSignal
    router.dart          # AppRouter, page stack
    navigation.dart      # router provider + push/pop (pages vs dialogs)
  objectbox.g.dart       # Generated — do not edit by hand
```

**Screens:** `dashboard_screen`, `medicine_bag_screen`, `settings_screen`, `stock_details_screen`; dialogs for add, edit, dispense, delete.

---

## Architecture (current direction)

### Bootstrap

1. `main()` wraps the app in `ProviderScope` (optionally with `overrides` for `LazyProvider`s).
2. `Application` extends `SignalConsumer` and builds `MaterialApp.router` with `routerConfig: router(context)` and theme from `settingsProvider`.

### Dependency injection — `provider.dart`

- Declare dependencies as top-level finals: `final stocksProvider = provider((f) => StocksManager(databaseServiceProvider(f)));`
- Read in widgets: `context(stocksProvider)` or `stocksProvider(context)` (same API).
- One cached instance per provider per `ProviderScope`.
- Services like `DatabaseService` are created through providers, not global singletons.

Naming: **`<feature>Provider`** for the `Provider` token; **`<Feature>Manager`** or **`<Feature>Signals`** for the implementation class in `business/`.

### Reactive UI — `core.dart`

- **`Signal<T>`** — writable cell; read with `signal()` or `.value`; use `.set` / `.state =` in callbacks.
- **`Computed<T>`** — derived values.
- **`ListSignal` / `MapSignal` / `SetSignal`** — reactive collections (`lib/utils/collections.dart`).
- **`SignalConsumer`** — base class for widgets that should rebuild when signals read **during `build`** change.

**Rules:**

- Read signals only in `build()` (or code `build` calls directly). Do not read signals inside `ListView.itemBuilder`, dialog builders, or other lazy callbacks without passing values from `build`.
- Prefer signals for form state and lists the UI binds to (see `NewStockManager`, `StocksManager`, `SettingsSignals`).
- Use `untrack()` when a read must not create a dependency.

### Routing — two navigators

| Action | API | Import |
| --- | --- | --- |
| Full-screen pages | `context.push(StockDetailsScreen(...))`, `context.pop()` | `emergent_stocks/utils/navigation.dart` |
| Dialogs / sheets | `context.pushDialog(MyDialog())`, `context.pop()` | `package:navigation/navigation.dart` |

`navigation.dart` (app) delegates `pop` to the modal route when not on the root page route, otherwise to `AppRouter`.

- Routable pages extend **`SignalConsumer`** and are pushed onto the custom stack.
- Home is `DashboardScreen`; `MedicineBagScreen` is the combined inventory + audit list (`lib/ui/medicine_bag_screen.dart`).
- Route guards and `onExitAttempt` hooks are scaffolded in comments for future auth/exit flows.

### Data — `DatabaseService`

- ObjectBox store under app documents: `emergent_stocks`.
- CRUD: `put`, `get`, `getAll`, `remove`, `removeAll`.
- Live queries: `watch<T>()` streams (used to feed `ListSignal`s).
- Prefs: `save` / `read` / `watchKey` for small settings (e.g. theme).

After changing `@Entity()` models, regenerate:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Models

- ObjectBox entities in `lib/models/` with `@Entity()`, `@Id()`, sensible defaults.
- Example: `EmergentStock` — `name`, `genericName`, `strength`, `count`, `expiryDateMs`, `forEmergency`, `notes`, plus sync fields `remoteId`, `updatedAtMs`.
- UI theme: `lib/ui/theme/liquid_glass.dart` — gradients, semi-transparent surfaces, hairline borders (**no** `BackdropFilter`).

### Optional cloud sync (PocketBase)

**Rule:** UI and `business/` talk only to `DatabaseService`. Sync is a sidecar started from `main.dart` via `syncCoordinatorProvider`.

| Piece | Role |
| --- | --- |
| `DatabaseService` | Source of truth; enqueues `SyncOutboxEntry` on every local stock put/delete |
| `SyncCoordinator` | Periodic pull + debounced push when the outbox changes |
| `SyncEngine` | Push outbox, then pull remote deltas (hybrid) |
| `PocketBaseStockGateway` | Only PocketBase-specific code (REST under `lib/sync/remote/`) |

**Conflict handling:** Last-write-wins on `updatedAtMs`. Pull skips rows that are newer locally or still have a pending outbox upsert.

**Enable sync** (SharedPreferences via `DatabaseService.save`, no PocketBase types in app code):

| Key | Value |
| --- | --- |
| `sync_enabled` | `true` |
| `sync_base_url` | e.g. `http://127.0.0.1:8090` |
| `sync_superuser_email` / `sync_superuser_password` | PocketBase superuser (set in **Settings**; used only by `lib/sync/`) |
| `sync_auth_token` | Cached token after sign-in (cleared when sync settings change) |
**PocketBase collection** — fixed name `emergent_stocks` (`SyncConfig.defaultCollectionName`; create in Admin UI):

| Field | Type |
| --- | --- |
| `name` | Text |
| `count` | Number |
| `generic_name` | Text |
| `strength` | Text |
| `expiry_date_ms` | Number |
| `for_emergency` | Bool |
| `notes` | Text |
| `local_id` | Number |
| `updated_ms` | Number |

Open API list/create/update/delete rules must allow the token you configure (or use an admin token for prototypes).

---

## UI conventions

- **Screens**: `*_screen.dart`, `Scaffold` + `AppBar`, extend `SignalConsumer`.
- **Dialogs**: `*_dialog.dart`, `Dialog` or `AlertDialog`, rounded corners (~16), max width ~400 for forms; open with `pushDialog`.
- **Theming**: use `Theme.of(context)` / `colorScheme`; avoid hard-coded colors except intentional status chips (e.g. stock level).
- **Layout**: `Column`/`Row` with **`spacing`** where appropriate; padding often `12`–`24`.
- **Forms**: required fields marked with `*`; validation errors as nullable getters (`countError`) shown only after non-empty input where applicable; primary action disabled until `isValid` / `isNewStockValid`.
- **Private widgets**: prefix with `_` in the same file for sections and tiles.
- **Imports**: `package:emergent_stocks/...` for cross-library references.

---

## Business layer conventions

- Managers receive dependencies via **constructor** (often `final` primary constructor params).
- Side effects on construction: `this { db.watch<EmergentStock>().listen(stocks.set); }` pattern in `StocksManager`.
- Persist changes only through `DatabaseService` / `StocksManager.putStock` / `updateStock` / `removeStock` — keep widgets thin.
- Callback hooks like `onStockSaved`, `onFormCleared` for navigation after save (typically `context.pop`).

---

## Code style & tooling

- **Lints**: `package:flutter_lints/flutter.yaml` via `analysis_options.yaml`.
- **Formatter**: `trailing_commas: preserve`.
- Several analyzer rules are relaxed project-wide (`avoid_print`, `constant_identifier_names`, etc.).
- **Comments**: explain non-obvious reactive, routing, or lifecycle behavior (see existing files); avoid noise.

---

## Local path dependency

`pubspec.yaml` references the sibling package:

```yaml
navigation:
  path: ../navigation
```

Clone or keep `navigation` beside this repo when resolving dependencies.

---

## Run & build

```bash
flutter pub get
flutter run
flutter analyze
```

Targets include **Windows** (evidence in build output); standard Flutter platform folders are present.

### App icon & splash

Source art lives in `assets/branding/` (`app_icon.svg`, rasterized `app_icon.png` and `splash_icon.png`). Colors: background `#141A33`, accent `#64D2FF`.

After changing branding assets, regenerate platform assets:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

`flutter_native_splash` covers **Android** (including Android 12) and **web** (`web/index.html` + `web/splash/`). **Windows** uses the generated `app_icon.ico` and a startup window fill matching the splash background (`win32_window.cpp`).

---

## Working agreement (for follow-up tasks)

1. Match existing layering: `models` → `services` → `business` (+ provider) → `ui` (`SignalConsumer`).
2. Use custom router for pages, `navigation` package for dialogs.
3. Regenerate ObjectBox after model changes.
4. Do not revive `lib/features/` or LocatorScope unless explicitly migrating the whole app.
5. Keep diffs focused; mirror naming and patterns in the nearest similar file (`new_stock_dialog.dart` / `NewStockManager` are good references for new forms).
