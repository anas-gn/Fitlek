# SIRVYA Workout

Native Flutter module in the existing application. Baseline main/origin/main is
23d3665 (`design`); existing local Premium work is retained. See
[WORKOUT_PARITY.md](WORKOUT_PARITY.md) for the audit, inventory and parity limits.

## Architecture and ownership

Client navigation adds Workout at index 4. Coach navigation adds it at index 5.
StatefulWidgets/services, ApiService Bearer tokens, SharedPreferences, existing
users/coachclients, Express/mysql2 and SIRVYA notifications are reused. Theme is
scoped to Workout. LocaleService adds shared EN/FR/ES selection using the existing
language families; Workout translations are independently authored.

Database setup runs idempotently through `config/workoutSchema.js` and the
2026_sirvya_workout/2026_workout_experience migrations in the existing database.
Core tables: exercises, workout_plans, workout_days, workout_exercises,
workout_sessions, workout_sets. Supporting tables hold preferences, schedule/date
overrides, alert leases, private media and stable import identities.

WorkoutExercise prescribes targets. WorkoutSet records actual performance.
Routine progression can be inherited or overridden per exercise. Custom exercise
removal hides library entries while preserving historical stable identities.
Sessions snapshot immutable prescriptions and retain separately edited execution.
Snapshot slot IDs deliberately survive removal/editing of plan rows. Exercise
catalog IDs and source IDs remain stable. Nullable Coach ownership preserves
Client history on account removal; Client deletion cascades owned workouts.

Clients access only their own data. Coaches access only linked clients, edit
their own plans, and review linked-client workouts including personal routines.
Database roles are checked alongside JWT roles. Draft/archived plans cannot start.
Active sessions are uniquely constrained and transactional. Recorded sets cannot
be erased by swapping/removing an exercise; the user must explicitly undo them.

## API

Protected prefix `/api/workout`, using existing SIRVYA Bearer authentication.
Media content is the exception: a separately signed, short-lived, user/resource
download capability rechecks current access and cannot authenticate other APIs.

| Routes | Behavior |
| --- | --- |
| GET /clients | Coach linked-client picker |
| GET/POST /exercises; GET/PUT/DELETE /exercises/:id | Paginated catalog, contextual filters/details and owner-only custom lifecycle |
| PUT /exercises/:id/preferences; GET /exercises/:id/history | Favorites/notes and owned/linked history |
| GET/PUT /preferences; GET /templates | Workout-only configuration and original starter routines |
| GET/POST /plans; GET/PUT/DELETE /plans/:id | Personal/Coach plan lifecycle, revision checks and archive |
| POST /plans/:id/duplicate; GET /plans/:id/export; POST /plans/import | Stable portable prescriptions, no accounts |
| GET/PUT /schedule | Weekday routines, multi-routine overrides and explicit rest days |
| POST /sessions; GET /sessions/active; GET /sessions/:id | Start/resume, combined/freestyle/past workouts, immutable prescriptions |
| PUT /sessions/:id/sets; DELETE /sessions/:id/sets/:exerciseID/:setNumber | Idempotent actual set save/edit/undo |
| PUT /sessions/:id/execution; PUT /sessions/:id/rest-alert | Safe session changes and background rest delivery |
| PUT /sessions/:id; PUT /sessions/:id/history; DELETE /sessions/:id | Finish/cancel, historical correction and owned history deletion |
| GET /history; GET /stats | Paginated sessions, activity, records, progression, volume, effort and adherence |
| POST /history/import-preview; POST /history/import; GET /history/export | CSV/JSON mapping, atomic import batches and private exports |
| GET/POST /sessions/:id/media; GET/POST /exercises/:id/media | Private validated workout/custom demonstrations |
| GET /media/:id/ticket; GET /media/:id/content; DELETE /media/:id | Scoped media capability and owner deletion |

Large transfer payloads are authenticated before their bounded JSON parser.
Other API size limits are retained. Set identity is session + snapshot slot + set
number. Repeated/concurrent submissions update the same row. Warmups use a
separate bounded number range and do not influence working-set progression/PRs.

## Training behavior

Supersets alternate by round and support unequal counts; reorder moves the group.
Timed/cardio sets use duration rather than fake reps. Bodyweight load is optional.
Unilateral sides and drop/rest-pause segments contribute actual external-load
volume. RPE/RIR are optional and mutually exclusive. Estimated 1RM uses eligible
loaded 1–12 rep sets with Epley; one repetition equals the actual load.

Linear/double/Greyskull/time/bodyweight suggestions use completed working sets
from the same stable routine slot. Changed prescription targets/policy reset the
baseline; note-only edits retain progression. Exclusions, misses/deloads and
previous performance are supported. Estimates never overwrite original targets.

Outbox and unsaved row/form/timer drafts are serialized per SIRVYA account.
Read caches are bounded to 32 entries of at most 64 KiB per SIRVYA account;
offline screens explicitly label saved data. Account/token changes during a
request reject its response. Offline sets remain explicitly pending until acknowledged. Finish and structural
changes require pending sets to sync. Expired/unauthorized responses never fall
back to cached protected data. Wall-clock timers restore after suspension.

Reminders are opt-in, time-zone aware, honor explicit rest-day overrides and
use durable UTC alert deadlines/leases plus existing notification persistence.
Native rest notifications use flutter_local_notifications; FCM is the fallback.
Android scheduling is inexact without additional exact-alarm permissions.

Stats use recorded data. Adherence is against the current assigned schedule,
because old schedule versions cannot establish past obligations. Structural
balance offers configurable anchor ratios, not imported named preset tables.
Weight check-ins/imports reuse the existing weighthistory table and API.

Private uploads are outside public /uploads, bounded in size/count and validated.
Images are decoded/resized/re-encoded without metadata; videos require a valid
MP4 container structure. Owner checks apply to write/delete, linked-client checks
to reads. Stale orphan UUID files receive a one-day grace before bounded cleanup.

## Run and verify

```powershell
cd C:\kafka\Fitlek\backend
npm start
# Separate terminal, repository root:
flutter build web --release --dart-define=API_BASE_URL=http://localhost:3000/api
node serve_web.js
```

Preview: http://localhost:8080. API: http://localhost:3000/api.

```powershell
cd backend
$env:WORKOUT_TEST_MYSQL='1'
$env:APP_TEST_MYSQL='1'
$env:AUTH_TEST_MYSQL='1'
npm test
cd ..
flutter test --concurrency=1
flutter analyze
# Optional native fixture captures:
$env:WORKOUT_CAPTURE_SCREENSHOTS='1'
flutter test test/workout_visual_test.dart
```

MySQL tests reject remote hosts, mock provider delivery/identity verification only
inside test servers and remove their own fixture accounts. They exercise login,
registration/account completion, profile reads/edits, Coach invitations,
reservations/calendar/conflicts, messaging/unread/notifications, workout access
attacks, snapshots, duplicate submissions, metrics, import rollback and media.
Live provider sign-in and physical-device behavior are not implied by these tests.

Android builds use this project's existing Gradle 8.14 wrapper. Use a compatible
JDK such as Java 17; a globally configured Java 25 cannot run that wrapper.
Debug builds can be checked with `flutter build apk --debug`. Production signing
continues to use the existing Android configuration.
