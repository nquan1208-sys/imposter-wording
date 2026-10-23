# EscapeCall Mobile

Flutter mobile app with Signals state management, Riverpod DI, a Bumble-inspired theme (`lib/theme`) and VI/EN localization (default VI).

## Docs

- [Architecture](docs/architecture.md)
- [State Management](docs/state-management.md)
- [Routing](docs/routing.md)
- [How to Add a New Feature](docs/how-to-new-feature.md)

## Environments

Run these commands from `app/` on a new machine:

```sh
cp env/.env.local.example env/.env.local
cp env/.env.dev.example env/.env.dev
cp env/.env.prod.example env/.env.prod
flutter pub get
```

Create all three files, even if some credentials are not available yet: Flutter
registers all three as assets. Real env files are ignored by Git; examples are
committed. Each file contains `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY`.

| Environment | File | Backend |
| --- | --- | --- |
| Local | `env/.env.local` | Local Supabase, same public client values as `admin/.env.local` |
| Dev | `env/.env.dev` | Shared `imposter-word` Supabase project; fill in its publishable key |
| Prod | `env/.env.prod` | Fill in the production project URL and publishable key |

Copy the Admin `VITE_SUPABASE_URL` and `VITE_SUPABASE_PUBLISHABLE_KEY` values
without the `VITE_` prefix. Use only `sb_publishable_...` keys; never put secret,
service-role keys or passwords in these files. All three files are bundled into
every build and can be extracted, including the files not selected at startup.

### Run and debug

Open the repository root in VS Code/Cursor with the Flutter extension installed.
In **Run and Debug**, select **Flutter Local**, **Flutter Dev** or **Flutter Prod**,
select your device, then press F5. All three launch in debug mode with breakpoints
and hot reload, using the same app ID; they cannot be installed side by side.

Equivalent terminal commands:

```sh
flutter run --dart-define=APP_ENV=local
flutter run --dart-define=APP_ENV=dev
flutter run --dart-define=APP_ENV=prod
```

`APP_ENV` selects the file loaded by `flutter_dotenv` before `runApp`. It defaults
to `local`. Unknown environments, missing/empty files, invalid URLs and missing
or invalid publishable keys stop startup with a configuration error. There is no
fallback to another environment. Dev and Prod cannot start until configured.
After changing env values or environments, stop and run again.

Start the local Supabase stack from the repository root with `supabase start`.
Use `http://127.0.0.1:54321` for iOS Simulator. For Android Emulator, edit
`SUPABASE_URL` in `env/.env.local` to `http://10.0.2.2:54321`. For a physical
device, use the LAN IP of the computer running Supabase and ensure it is reachable.

Application code can read the validated config through `AppConfig.current`
from `package:untitled/config/app_config.dart`. This setup does not initialize a
Supabase client or make API requests.

### Release builds

Fill in production config first:

```sh
flutter build appbundle --release --dart-define=APP_ENV=prod
flutter build ipa --release --dart-define=APP_ENV=prod
```

IPA builds require macOS/Xcode and signing configuration. Config validation runs
at application startup, including release; building alone does not validate keys.

### Checks

```sh
flutter analyze
flutter test
```
