# Architecture

Flutter mobile app with Signals state management, Riverpod DI, and a feature-based structure.

## Tech Stack

| Layer | Package | Version |
|---|---|---|
| UI | Flutter | >= 3.41.0 |
| Language | Dart | >= 3.11.0 |
| Reactive state | signals_flutter | ^7.1.0 |
| Dependency injection | flutter_riverpod / riverpod | ^3.3.1 / ^3.2.1 |
| Immutable models | freezed / freezed_annotation | ^3.2.5 / ^3.1.0 |
| JSON serialization | json_serializable / json_annotation | ^6.8.0 / ^4.9.0 |
| Asset code gen | flutter_gen | ^5.7.0 |
| Localization | flutter_localizations + intl | ^0.20.0 |
| Backend content | supabase_flutter | 2.18.3 (pinned) |
| Local file location | path_provider | 2.1.6 (pinned) |

---

## Folder Structure

```
lib/
  main.dart               # MaterialApp: theme, locale, routes
  base/
    dependency/           # App-level services (router, i18n) exposed via AppService
      router/utils/       # Route names, inputs, pages, screens
    store/                # StoreBase, createAutoDisposeStore, AutoDisposeManager, StoreProvider
  config/                 # Environment config (AppConfig)
  constants/              # AppSpacing, AppEdgeInsets, ...
  data/                   # Supabase content, scoped atomic JSON files, global DI
  models/                 # ContentSnapshot, categories/prompts, GameSetup/players
  features/               # One folder per feature
    landing/              # Start screen (initial route)
    how_to_play/          # Rules screen
    setup/                # Setup store, setup/category screens and content notices
    unknown/              # Fallback for unknown routes
  l10n/
    arb/                  # app_en.arb (template), app_vi.arb
    gen_l10n/             # Generated output (do not edit)
  store/app_store.dart    # Global AppStore (locale)
  theme/                  # AppColors tokens + AppTheme (light/dark)
```

---

## Layer Responsibilities

### `base/`
Core infrastructure that features depend on but do not own.

- `base/store/store_base.dart` — `StoreBase` and `createAutoDisposeStore`
- `base/store/auto_dispose_manager.dart` — `AutoDisposeManager` and `.manageBy()` for signals/effects/subscriptions
- `base/store/store_provider.dart` — registry of store providers (`StoreProvider.app` is global)
- `base/dependency/app_service.dart` — `AppService` / `AppProvider`: Riverpod providers for router and i18n

### `features/`
Each feature folder contains its screen(s) and, when it has state, a store. Static screens (landing, how-to-play) have no store.

### `theme/`
`AppColors` holds design tokens from `docs/support.bumble.com-DESIGN.md` (repo root). `AppTheme.light` maps them to `ThemeData` (color scheme, text theme, buttons, cards, app bar). `AppTheme.dark` currently mirrors light until a dark design exists. Screens use `Theme.of(context)` and `AppColors`; do not hardcode hex values.

### `l10n/`
Template is `app_en.arb`; every key must also exist in `app_vi.arb`. Default locale is `vi`, held by `AppStore.locale` and passed to `MaterialApp.locale`. Read strings with `AppLocalizations.of(context)`. Never edit generated files.

---

## Dependency Injection

Riverpod is the DI container. State lives in signals on stores, not in Riverpod providers.

- `AppProvider` — raw providers for router and i18n
- `AppService` — derived providers that compose `AppProvider` dependencies
- `StoreProvider` — store providers; feature stores use `createAutoDisposeStore`
- `data/game_providers.dart` — app-lifetime content repository and setup store,
  watched at startup; share pending loads and committed settings across routes

---

## Code Generation

| Tool | What it generates | Command |
|---|---|---|
| `freezed` | Immutable model classes | `dart run build_runner build` |
| `json_serializable` | `fromJson` / `toJson` methods | `dart run build_runner build` |
| `flutter_gen` | Type-safe asset references | `dart run flutter_gen run` |
| `flutter_localizations` | Localization classes | `flutter gen-l10n` (also on `flutter run` / `flutter build`) |
