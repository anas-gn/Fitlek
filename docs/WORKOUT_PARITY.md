# SIRVYA Workout implementation map

Independent audit: see [WORKOUT_AUDIT.md](WORKOUT_AUDIT.md) and the
[counted feature matrix](WORKOUT_AUDIT_MATRIX.md). The audit verifies 141 / 152
requested-fork workout behaviors, with 11 partial. Historical credential
exposure and the legacy production HTTP default prevent a security sign-off.
The older grouped inventory below is implementation context; the counted matrix
is the current source of truth for verification and limitations.

Baseline: SIRVYA `main` / `origin/main` `23d3665` (latest fetched main).
Requested reference: arvids-unavailable/openGym `c42ba6b98e3776af5981f20c05ba392238799670`
(HEAD verified on 2026-10-03). Its README points to DuarteSantos8/openGym.
The existing integration also reviewed that upstream at `e88062e` (v1.3.9).
This is an independent implementation, not a React port or embedded application.

## Architecture audit

SIRVYA uses Flutter StatefulWidgets and services, shared_preferences for its JWT
and session, ApiService for Bearer HTTP, and AppTheme for global light/dark mode.
The real Client navigation is clientHome.dart's IndexedStack. Coach navigation is
MainLayoutCoach. Workout is additive in both; existing tab indices are preserved.
The backend is Express ES modules with mysql2 pools, JWT middleware, an existing
users table and coachclients relationship. Existing routes are split between anas
and pahae. Notifications use MySQL notifications plus Firebase Admin FCM; messaging
currently polls HTTP. Workout uses these systems, not openGym's JSON/cookies/push.
Existing localization consists of ENG/FR/ESP authentication screens; the additive LocaleService now shares these languages through Flutter delegates,
profile language selection and independently authored Workout translations.

Workout already separates coach prescriptions from real sets and snapshots each
session, preserving history across plan edits. Its role and relationship checks
run on the server. The expanded domain adds client-owned routines, exercise
preferences, workout preferences, progression and durable reminders in the same
MySQL database. Flutter recovery uses account-scoped local storage and the
existing idempotent set identity.

## Implementation sequence

1. Expand schema and authorization for personal routines, favorite/custom
   exercises, richer sets, progression, workout preferences and reminders.
2. Expand APIs and security/lifecycle tests before connecting new screens.
3. Import independently licensed exercise metadata, retaining stable source IDs.
4. Create native Workout surfaces, grouped cards, compact controls, week strip,
   floating rest controls and sheets inspired by the reference. Retain SIRVYA
   branding and global navigation. Scope the visual theme to Workout routes.
5. Add routine tools, active workout recovery/undo/add/swap, rich history/progress,
   and workout preferences/reminders. Test each complete flow and both roles.
6. Review visual and functional parity; document every remaining limitation.

## Feature inventory and parity review

DONE means locally exercised native/API behavior. Device integrations and live
browser identity providers have separate verification limits below.

| Reference behavior | Classification | Status / SIRVYA adaptation |
| --- | --- | --- |
| Dashboard, week strip, today/upcoming/recent, adherence | REIMPLEMENT | DONE: native dashboard and current-schedule adherence; fixture rendering verified |
| Weekly schedule, multiple routines, date overrides, explicit rest days | REIMPLEMENT | DONE: stable day IDs and calendar overrides, API tests |
| Client routines, Coach programs, create/edit/archive/duplicate/starters | REIMPLEMENT | DONE: personal routines and linked-client plans; archive preserves history |
| Reorder exercises and paired supersets | NEEDS ADAPTATION | DONE: native move controls preserve entire contiguous groups; drag gestures adapted to buttons |
| Routine JSON import/export, print/PDF | REIMPLEMENT | DONE: transactional stable-ID mapping, native generated PDF and print/export action; physical printer untested |
| Catalog/search/filter/secondary muscles/bodyweight/favorites | REIMPLEMENT | DONE: 1324 MIT metadata entries plus 24 original seeds, pagination/debounce/indexes; filters reflect matching equipment/muscles |
| Custom exercise create/edit/remove, pinned notes, equipment profiles | REIMPLEMENT | DONE: owner-only native forms, description/secondary muscles, library removal retains stable routines/history; measurement changes reject exercises in use |
| Library exercise → routine action; older exercise history | REIMPLEMENT | DONE: native day selection/configuration and paginated history with actual performance charts, widget tests |
| Muscle explorer, details and exercise history | NEEDS ADAPTATION | DONE: original vector illustration, library filters, linked-client selection and real history |
| Dataset images, animations and videos | EXCLUDE - LICENSE ISSUE | EXCLUDED - LICENSE: metadata MIT license expressly excludes media; no such assets copied |
| Licensed demonstration replacement | NEEDS ADAPTATION | DONE: 38 unmodified, attributed CC BY-SA illustrations in 19 native demonstrations, mapped to 24 stable identities; offline frames/playback and reduced-motion controls. Coverage is limited to reviewed matching exercises. |
| Multilingual exercise instructions | NEEDS ADAPTATION | DONE: licensed EN/FR/ES instructions; SIRVYA language selection |
| Single/combined routine, freestyle, past-workout logging | REIMPLEMENT | DONE: snapshot containers in the same database, date-aware history/progression |
| Cards/compact/guided views, steppers, keyboard controls | NEEDS ADAPTATION | DONE: Flutter rows/sheets, keyboard Enter/arrows, Space rest pause; mobile layouts |
| Load/reps/duration/effort/previous performance | REIMPLEMENT | DONE: distinct prescriptions and actual sets, server validation and widget tests |
| Superset round-robin, uneven counts, timed/bodyweight | REIMPLEMENT | DONE: appropriate measurement and grouping; warmups separated from working sets |
| Active add/remove/swap/reorder exercises and add/edit/undo sets | REIMPLEMENT | DONE: revision/ownership checks protect recorded results and original targets |
| Warmups/drops/rest-pause/unilateral sides/set notes | REIMPLEMENT | DONE: actual side loads and extra segments, configurable intervals, metric tests |
| Offline queue, typed drafts, resume/conflict handling | NEEDS ADAPTATION | DONE: serialized account-scoped storage, idempotent sets, explicit pending/error UI; server revisions replace openGym JSON merge |
| Rest pause/resume/extend/skip, group-aware auto rest | REIMPLEMENT | DONE: wall-clock deadlines and native controls; server alert tests |
| Work countdown/elapsed/overtime and persistence | REIMPLEMENT | DONE: wall-clock timer restores across screen disposal; countdown continues into overtime |
| Sound/vibration/flash/keep-awake | NEEDS ADAPTATION | PARTIAL: native hooks/preferences implemented; physical-device behavior unverified |
| Daily reminders/background rest/Android countdown actions | NEEDS ADAPTATION | PARTIAL: durable MySQL scheduling and existing SIRVYA FCM/local notifications wired; deadline/retry/dedup tested, device delivery unverified |
| Routine defaults, exercise overrides; linear/double/Greyskull/time/bodyweight progression and deload | REIMPLEMENT | DONE: successful working sets only; repeated exercises have independent stable slots, changed prescriptions reset, exclusions supported |
| Plate/bar inventory, warm-up ramp, estimated 1RM tools | REIMPLEMENT | DONE: independent bounded calculator and per-set shortcut, unit-aware input, math tests |
| Completion summary/volume/PRs | REIMPLEMENT | DONE: recorded data only; warmups excluded from PRs; loaded/timed/bodyweight metrics stay distinct |
| History details, date/duration correction/edit/delete/exclusion | REIMPLEMENT | DONE: native editor and transactional API; prescribed/performed comparison retained |
| Strong/Hevy/FitNotes CSV and bodyweight import/export | NEEDS ADAPTATION | DONE: preview/mapping, atomic batches, deduplication, existing weighthistory reused; parser and ownership tests |
| Progress charts/records/heatmap/frequency/time/streaks/periods | REIMPLEMENT | DONE: dated real performance and native charts; seven-row calendar heatmap covers the selected period including a full year |
| Muscle balance/recent training load/relative strength | NEEDS ADAPTATION | DONE: actual working/hard sets, last training date and recent load; no invented recovery score |
| Structural balance protocols and overrides | NEEDS ADAPTATION | PARTIAL: named custom protocols, selection/delete, stable anchors and target overrides work. Linked Coaches edit actual Client ratios with ownership checks and preservation of other preferences. Published Poliquin/Thibaudeau/ATG preset tables await independent source/license review. |
| Effort distributions, cardio distance and speed | REIMPLEMENT | DONE: actual optional RPE/RIR and distance/time metrics |
| Bodyweight goal/check-in/history | REPLACE WITH EXISTING SIRVYA FEATURE | DONE: existing weighthistory plus workout-specific goal/check-in preference; no second profile |
| AI provider setup, chat and automated Coach plans | REPLACE WITH EXISTING SIRVYA FEATURE | REPLACED BY SIRVYA human Coach plan/review flow; no separate AI provider setup or identity |
| Coach assignment, actual results, exercise history, adherence/progress | NEEDS ADAPTATION | DONE: existing coachclients authorization; unrelated clients rejected |
| Workout photos/videos and private custom demonstrations | REIMPLEMENT | DONE: validated private uploads, restricted expiring download tickets and existing native video player; media authorization tests |
| Gym QR/access wallet | EXCLUDE - NOT WORKOUT RELATED | EXCLUDED - NOT WORKOUT: membership/access responsibilities remain outside Workout |
| Login/passkeys/accounts/admin authentication | EXCLUDE - LOGIN/AUTH | REPLACED BY SIRVYA Bearer authentication and users |
| Profile/account/general application settings | EXCLUDE - ACCOUNT MANAGEMENT / GENERAL SETTINGS | REPLACED BY SIRVYA; workout-specific preferences retained |
| React router/Capacitor/service worker/cookie sessions/JSON database | REPLACE WITH EXISTING SIRVYA FEATURE | REPLACED BY Flutter/Express/MySQL/native notifications; no embedded frontend |

Reviewed openGym Home, Plan, RoutineEdit, Library, Muscles, Workout, History,
Stats, CheckIn, Settings, CoachSetup/Intake/Chat and Admin, plus stores/domain
helpers, imports, progression, timers, media and CSS. The reference revision is
c42ba6b (requested fork) and e88062e (upstream supplement). Behavior is independently recreated; no source or translated
strings were ported.

## Visual review evidence

Native fixture renders at 396 × 844:
[Dashboard](verification/native-dashboard.png),
[Active workout](verification/native-active.png),
[Exercise library](verification/native-library.png),
[Coach builder](verification/native-coach-builder.png),
[Progress](verification/native-progress.png).
Additional native captures: [Demonstration](verification/native-demonstration.png)
and [Client balance protocol](verification/native-balance-protocol.png).

Workout has scoped dark/light neutral surfaces, green actions, compact set grids,
rounded cards, modal editors, a calendar strip and persistent timer controls.
SIRVYA branding and global Client/Coach navigation remain in place. These images
are Flutter test renders, not live browser screenshots; no pixel-perfect parity
claim is made.

Real local web browser evidence:
[Completion](verification/browser-completion.png),
[History](verification/browser-history.png),
[Coach dashboard](verification/browser-coach-dashboard.png),
[Coach review](verification/browser-coach-review.png).
The browser flow authenticates a disposable SIRVYA Client, selects the Workout
tab, starts a Coach-assigned day, logs a set, completes it, and opens actual history.
The Coach then opens that linked Client's completed session and compares its
prescribed targets with saved performance. Browser setup uses the real SIRVYA
login endpoint and restores its session; manual login form entry was not exercised.

## Verification limits

Local backend regression: 68 tests passed, no skips, with disposable users in the
existing MySQL database. The full Flutter suite passes 46 tests with screenshot
capture enabled and no skips. Native navigation, recovery, forms, timers, rich
sets, bounded caches, year heatmaps, licensed demonstrations and scoped Client
balance protocol creation/edit/selection/deletion are covered.
The release web build passes; all 38 bundled demonstration frame hashes match
the audited originals. Full repository-wide Flutter analysis is now clean.

Android debug APK build passes with Java 17 and the Flutter ARM64 target after
disk space became available. Earlier attempts failed during native-library
extraction/merging due to insufficient disk space; generated files from those
failed app builds were removed. The APK retains package `com.sirvya.app`, label
SIRVYA, version 1.0.2 (10), and includes all 38 audited illustration frames plus
their full license. Artifact: `build/app/outputs/flutter-apk/app-debug.apk`
(186,008,603 bytes). SHA-256:
`ec5fdb05ea956a9fbf152d80ef6a0f7db21e3754e32e3d24ad3d30bd70fa9f29`.
This local verification build uses `API_BASE_URL=http://localhost:3000/api`;
an attached Android device needs `adb reverse tcp:3000 tcp:3000` to reach the
local backend. No physical device was attached. The original global Java 25
setting was restored; it remains incompatible with the existing Gradle wrapper.

Real Google OAuth browser sign-in, physical Android/iOS alerts/actions/vibration,
video codecs, wake lock and printer integration remain unverified. An isolated
headless Chrome profile exercises the local release web build with disposable
SIRVYA accounts. Live Google identity verification remains mocked only in tests.
The existing intro video reports an unsupported codec in headless Chrome;
the application continues through sign-in and normal navigation.

## Licensing and cleanup

See [THIRD_PARTY_WORKOUT.md](THIRD_PARTY_WORKOUT.md). Dataset media is excluded.
Secrets, generated build files, local logs, node_modules and reference checkout
are ignored. Disposable browser verification accounts were removed. Existing
user backups remain on disk, with accidentally tracked Git backups, SQL data dump
and backend archive removed from the index. Migration/count utilities now use
the existing environment-based database configuration. Existing Premium work
is retained. The integration is committed locally as requested; no push/deploy.
The ignored reference checkout remains: automatic approval review rejected its
temporary cleanup with only a generic "blocked by policy" message.
