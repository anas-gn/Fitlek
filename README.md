# SIRVYA

SIRVYA is the existing Flutter application and Express/MySQL API. Workout is a native module for Clients and Coaches, sharing SIRVYA accounts, Coach/Client relationships, notifications and database. Workout access is currently free.

See the [current completion report](docs/WORKOUT_COMPLETION_2026-10-10.md), [Workout guide](docs/SIRVYA_WORKOUT.md), [parity matrix](docs/WORKOUT_RECOVERY_CURRENT.md) and [third-party licenses](docs/THIRD_PARTY_WORKOUT.md). Historical audits describe the state on their recorded dates.

## Repository

| Path | Purpose |
| --- | --- |
| `lib/` | Flutter application and native Workout screens/services |
| `android/`, `ios/`, `web/` | Platform runners for the same Flutter application |
| `backend/` | Express API, MySQL migrations, services and integration checks |
| `test/` | Flutter behavior, recovery, responsive and navigation checks |
| `docs/verification/` | Reviewed captures and real local API/browser journey evidence |

The checked-in `web/` directory is a Flutter runner. Client and Coach journeys are the implemented application scope; older Advisor/Manager APIs do not establish a complete separate portal.

## Local setup

Use Node 22, MySQL and the Flutter SDK. The verification workflow pins the tested Flutter version in `.github/workflows/release-checks.yml`. Android builds use Java 17.

1. In `backend/`, run `npm ci`, copy `.env.example` to an ignored `.env`, and configure MySQL, a random JWT secret, Firebase service-account credentials and email delivery. Configure Google/Apple clients separately when testing those providers.
2. Create the application database and load `backend/sirvya_schema.sql` for a new installation. Back up existing data before upgrading. `npm start` applies the idempotent authentication, app compatibility and Workout schema ensures before accepting traffic. Existing legacy Premium APIs require their migrations if used; current `/api/workout` access requires no Stripe subscription.
3. From the repository root run `flutter pub get`. Create `assets/config.env` if absent; an empty file is sufficient for local compile configuration. Never put service-account/private signing material in Flutter assets.
4. Run the backend with `npm run dev` from `backend/`. Run the application from the repository root:

```sh
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000/api
```

For an Android emulator, use `http://10.0.2.2:3000/api`. Production builds must specify the owned certificate-backed HTTPS API URL:

```sh
flutter build web --release --dart-define=API_BASE_URL=https://your-api-host/api
```

The current default API URL is a legacy HTTP development endpoint; it is not a production release configuration. Production backend startup requires explicit `CORS_ORIGINS`, `PUBLIC_API_ORIGIN` with HTTPS, and a strong `JWT_SECRET`. Set `TRUST_PROXY_HOPS` to the actual trusted proxy depth. Firebase, email delivery, release signing and hostname configuration require the owner's credentials.

## Workout behavior

Clients create personal routines, use Coach assignments, schedule workouts, log actual sets, resume/offline-sync active sessions, finish and review history/statistics. Coaches assign routines and review only linked Clients. Exercise prescriptions and actual results remain distinct; stable snapshots preserve history after routine edits.

History imports preview Strong/Hevy/FitNotes CSV, SIRVYA JSON and streamed Apple Health bodyweight XML before writing. Imports are transactional and repeat imports skip duplicates. JSON history exports offer successive files of up to 100 workouts and 100 measurements.

Full Workout backup export/preview/restore includes routines, effective schedules, preferences, exercise identities/preferences, completed history and measurements. Schedule/preference replacement is opt-in; Coach routines restore as personal copies. Limits are 100 plans, 1,000 completed workouts, 1,000 measurements and an 8 MiB backup. Active sessions, device drafts and uploaded media are excluded and disclosed in the interface.

Password reset uses `/auth/send-forgot-otp`, `/auth/verify-forgot-otp` and `/auth/reset-password-otp`. The verified step returns a short-lived, single-use reset capability; email alone cannot update a password. Reset invalidates old access and refresh sessions. The unsafe legacy reset endpoints return HTTP 410.

## Verification

The release workflow initializes a fresh disposable MySQL database, runs backend integration checks, analyzes/tests Flutter and compiles web and Android debug builds. Local clean-schema verification is reproducible from `backend/`:

```sh
node scripts/verifyCleanCheckout.mjs
```

It accepts only local MySQL, creates a uniquely named disposable database and retains it for inspection; it does not reset the application database. Provider verification/delivery is explicitly substituted in test servers. Hardware and live providers remain separate checks.

```sh
flutter analyze --no-pub
flutter test --no-pub --concurrency=1
```

See the completion report for exact pass counts, browser evidence and remaining release requirements. Licensed replacement demonstrations cover part of the exercise catalog; original GymVisual media is excluded without distribution rights. Existing host realtime chat and its attachment protection remain separate unfinished work, as recorded in the release audit.

## License

Private project. Third-party code, anatomy and exercise/media assets retain the licenses documented in `docs/THIRD_PARTY_WORKOUT.md`.
