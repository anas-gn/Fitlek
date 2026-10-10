# Workout completion and release evidence — 2026-10-10

The local Workout flow works end to end with SIRVYA authentication, native Flutter screens, the actual API handlers and a real disposable MySQL database. This pass fixes functional transfer/recovery gaps and the host authorization/reset weaknesses that could compromise Workout data. Deployment, live providers, hardware delivery and full catalog demonstration rights remain separate requirements.

## Changes completed

- Secure password recovery: random OTPs, hashed persisted challenges, attempt/cooldown limits, single-use short-lived verification capability, transaction-safe password update and access/refresh-session revocation. Unsafe legacy reset routes return 410. The Flutter reset screen carries the capability and stops loading on success; narrow-screen footer overflow is fixed.
- Private ownership: self-service profiles derive the acting account, Client data is scoped, Coach links require consent, only staff can ban/lift bans, and profile/gallery/avatar writes reject impersonation. Workout and media authentication recheck current role, bans and token version. Database timeouts/pool failures return 503 so valid accounts and pending offline sets are retained.
- Workout backup: versioned export/preview/restore for routines, schedules, preferences, stable custom identities, completed history and measurements. Restore is one transaction, schedule/preferences are opt-in, active sessions reject restore, same-source history/custom identities are reused, and identical file replay is a no-op. Active sessions, device drafts and uploaded media are explicitly excluded.
- Training transfers: file streams replace eager loading; Apple Health XML is scanned in bounded chunks and retains body-mass records without interpreting DTDs/entities. Imports save up to 1,000 workouts/measurements atomically, compare converted measurements at the existing two-decimal kg storage precision, report duplicate measurements, and preserve the complete transaction if a late row is invalid. History exports have independent workout/measurement cursors and an explicit next-file action; actual formatted file size is bounded. Web JSON exports use browser-native downloads because the installed file-picker version does not implement web saving; native save dialogs retain their existing path.
- Recovery/timers: clearing a rest alert after finish is idempotent; a delayed positive rest update cannot resurrect a closed-session alert. Existing offline outbox, revision and account-isolation behavior is retained.
- Native presentation: compact Home/week/Today layout, selected-day circle, compact shaded weight chart, inline routine progression, tighter exercise rows and muscle chips. History details and copied summaries retain bodyweight reps, loaded timed values, cardio distance/speed and fractional effort.
- Runtime/release: configuration validation, explicit production CORS/HTTPS origin, bounded proxy/pool/traffic, migrations awaited before listen, database readiness endpoint, release signing required instead of debug fallback, iOS microphone/push/background declarations, checked-in npm lock and a repeatable release workflow.

## Verification

| Check | Result |
| --- | --- |
| Backend from a brand-new local schema | **114 passed, 0 failed, 0 skipped** on initial clean bootstrap; final expanded regressions on that initialized schema: **116 passed, 0 failed, 0 skipped**. |
| Full Flutter regression suite | **77 passed, 0 failed; 1 optional legacy capture skipped**. After the browser download correction, all **4 transfer UI checks** pass, including the new Coach export case. |
| Flutter static analysis | **No issues found** in whole-project analysis and subsequent touched-file/download checks. |
| Release web compile | **Passed** after the browser download fix (295.8 seconds), using the isolated localhost API override. |
| Android debug compile/package | **Passed**, Java 17, arm64, 705 tasks (10m 05s). No signed release or device run claimed. |
| Real built-app browser/API/MySQL journey | **13 checks passed**, 0 unexpected API errors, 0 JavaScript exceptions. [Machine-readable report](verification/workout-live-journey.json); no synthetic HTTP responses. |
| Physical Android/iOS and live external providers | **Not run**; no device attached and no macOS runner |

The clean-schema runner creates a uniquely named local `sirvya_ci_*` database from the checked-in SQL and migrations. It retains that disposable schema for inspection and does not reset the application database. Backend integration checks substitute provider verification/delivery explicitly; they do not prove real email, Google/Apple or FCM delivery. The CI workflow includes backend checks, Flutter checks/builds and the actual browser journey with uploaded evidence. Its YAML/shell syntax and underlying checks are verified locally; a remote GitHub Actions run has not been claimed.

Browser verification uses disposable local accounts and an isolated Chrome context. It runs the built Flutter app against actual mounted API handlers and MySQL, with real password login, Coach assignment, Client start/check-in/set logging/finish, history/statistics, SIRVYA return, Coach review and unrelated-Coach denial. Added coverage exercises offline queue/reconnect, an actual backup download/file chooser/restore, and an 11,200,136-byte Apple Health XML file with pounds-to-kg conversion and duplicate measurement handling. Screenshots are retained in [verification/journey](verification/journey/). Native screenshot pairs use separate deterministic fixtures for visual review.

The standard JavaScript release web build passes. Its optional Wasm dry run reports an existing socket_io_common interop incompatibility; no Wasm release is claimed.

Raw local logs are in ignored `workout_tmp/`: `clean-final-backend.log`, `flutter-final-passed.log`, `android-final-complete.log` plus backend-final-passed.log and final analysis/web/journey logs. The Android attempt first encountered the workstation's Java 25 preference, then disk exhaustion; the successful retry uses Java 17 directly and generated cache cleanup. No application source, user data or production media was deleted.

## What is still required

| Requirement | Concrete next step |
| --- | --- |
| Production credentials | The owner must revoke/rotate the private keys and environment secrets previously found in repository history. Removing the historical archive from the current tree does not revoke it. Coordinate any history cleanup with collaborators. |
| Production HTTPS and environment | Supply an owned certificate-backed API hostname, proxy configuration, allowed web origins, secret-manager credentials and a deployment target. Build with `API_BASE_URL=https://<owned-host>/api`; the default legacy HTTP IP is not release-ready. Validate `/api/ready`, login and authorized media on staging. |
| Android distribution | Supply the release keystore/key properties and Firebase/OAuth application configuration. The build now refuses missing release signing. Run hardware sign-in, file/PDF/media, permissions and background/process-kill checks. |
| iOS distribution | Use macOS/Xcode, the Apple team/provisioning profile, APNs key and registered sign-in configuration. Verify microphone, push/background alerts and permission-denial behavior on hardware. Static declarations are not a device pass. |
| Notification/provider evidence | Verify actual OTP email and Google/Apple sign-in, FCM/APNs, timed rest/reminder delivery, sound/vibration and wake lock with owned test accounts/devices. |
| Full catalog demonstrations | Obtain distribution rights for the excluded GymVisual media or build a complete reviewed replacement collection. Current replacement media covers 24 exercise identities; metadata coverage is broader. No unlicensed GIF import is included. |
| Exact reference presentation | Existing paired captures document native adaptations. Home/editor/chart/detail spacing is improved; this pass does not claim pixel equality or re-rate every historical partial parity row. Device-dependent rows remain unverified. |
| Separate host chat work | Realtime socket wiring/authenticated rooms and authorized chat attachments remain unfinished host features in the October 6 release audit. They are outside the Workout module and must be closed before claiming the entire SIRVYA application is finished. |

This snapshot includes the implementation, regression checks, release workflow and local verification evidence. The application has not been deployed, release-signed or submitted to stores.

## Local web and Google sign-in follow-up

The full release web build is running locally at `http://localhost:8082`, with the actual backend at `http://localhost:3201/api` and the existing local application database. API readiness and browser CORS checks pass.

The first real Google attempt exposed a local process network restriction: Firebase certificate retrieval failed with EACCES, and the API incorrectly returned an invalid-token message. Restarting the local API with network access resolves certificate retrieval. Authentication now distinguishes invalid/expired credentials (401) from provider/network/configuration failures (503, Retry-After), without issuing a session on either failure. All 9 focused authentication checks pass against the isolated local schema. A live signing-certificate and deliberately invalid-signature check confirms that the running API reaches Google and still rejects forged credentials. Actual Google account sign-in requires the user's browser retry and is not yet recorded as passed.

## Reproduce available checks

From `backend/`:

```sh
npm ci
node scripts/verifyCleanCheckout.mjs
```

From the repository root:

```sh
flutter analyze --no-pub
flutter test --no-pub --concurrency=1
flutter build web --release --no-pub --dart-define=API_BASE_URL=http://localhost:3201/api
```

The checked-in browser driver `backend/scripts/verifyWorkoutJourney.mjs` requires a disposable local `sirvya_ci_<timestamp>` schema, built web output using API port 3201, and a dedicated Chrome debugging instance on port 64425. Run with the explicit `--import ./tests/providerFixtures.js` preload from `backend/`; it does not contact real providers, mocks no API response, and cleans up its temporary users and browser context.

For release configuration references, see Flutter's [Android signing guidance](https://docs.flutter.dev/deployment/android#sign-the-app) and Apple's [remote-notification registration guidance](https://developer.apple.com/documentation/usernotifications/registering-your-app-with-apns).
