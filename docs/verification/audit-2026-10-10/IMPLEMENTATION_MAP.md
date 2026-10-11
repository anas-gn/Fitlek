# Current implementation map

Initial repository: Master at f81eb0d9c776c6a9410e629be9ca73859eca7686, clean git status and empty diff. The first 20 commits and original paths are preserved in [snapshot.json](snapshot.json). Current changes are additive audit fixes; none of the initial work was discarded.

## Flutter

Native Workout models, localized screens, nested navigation, shared API service, recovery outbox and timers.

- `lib/localization/workout_localizations.dart`
- `lib/localization/workout_strings.dart`
- `lib/models/workout.dart`
- `lib/screens/ENG/workout/active_workout.dart`
- `lib/screens/ENG/workout/exercise_library.dart`
- `lib/screens/ENG/workout/workout_anatomy.dart`
- `lib/screens/ENG/workout/workout_balance.dart`
- `lib/screens/ENG/workout/workout_bodyweight.dart`
- `lib/screens/ENG/workout/workout_builder.dart`
- `lib/screens/ENG/workout/workout_calendar.dart`
- `lib/screens/ENG/workout/workout_charts.dart`
- `lib/screens/ENG/workout/workout_check_in.dart`
- `lib/screens/ENG/workout/workout_demonstration.dart`
- `lib/screens/ENG/workout/workout_home.dart`
- `lib/screens/ENG/workout/workout_media.dart`
- `lib/screens/ENG/workout/workout_muscles.dart`
- `lib/screens/ENG/workout/workout_pdf.dart`
- `lib/screens/ENG/workout/workout_planning.dart`
- `lib/screens/ENG/workout/workout_preferences.dart`
- `lib/screens/ENG/workout/workout_progress.dart`
- `lib/screens/ENG/workout/workout_set_row.dart`
- `lib/screens/ENG/workout/workout_timer_bar.dart`
- `lib/screens/ENG/workout/workout_tools.dart`
- `lib/screens/ENG/workout/workout_transfer.dart`
- `lib/screens/ENG/workout/workout_ui.dart`
- `lib/services/workout_download_stub.dart`
- `lib/services/workout_download_web.dart`
- `lib/services/workout_file.dart`
- `lib/services/workout_file_io.dart`
- `lib/services/workout_file_stub.dart`
- `lib/services/workout_import_reader.dart`
- `lib/services/workout_recovery.dart`
- `lib/services/workout_service.dart`
- `lib/services/workout_timer.dart`

## Backend

Authenticated Express router, domain validation, queries, training/progression/effort/muscle logic, reminders and data transfer services.

- `backend/config/workoutSchema.js`
- `backend/routes/anas/workout.js`
- `backend/services/workoutBackup.js`
- `backend/services/workoutDomain.js`
- `backend/services/workoutEffort.js`
- `backend/services/workoutExperience.js`
- `backend/services/workoutHistoryTransfer.js`
- `backend/services/workoutImport.js`
- `backend/services/workoutMedia.js`
- `backend/services/workoutMediaCleanup.js`
- `backend/services/workoutMuscles.js`
- `backend/services/workoutProgram.js`
- `backend/services/workoutQueries.js`
- `backend/services/workoutReminders.js`
- `backend/services/workoutStats.js`

## Database

Additive relational tables in existing MySQL; runtime idempotent compatibility upgrades.

- `backend/migrations/2026_sirvya_workout.sql`
- `backend/migrations/2026_workout_audit_indexes.sql`
- `backend/migrations/2026_workout_experience.sql`
- `backend/migrations/2026_workout_fractional_effort.sql`
- `backend/migrations/2026_workout_week_plan.sql`

## Tests

Flutter behavior/layout and backend unit/real-MySQL integration checks.

- `backend/tests/workout.backup.integration.test.js`
- `backend/tests/workout.demonstrations.test.js`
- `backend/tests/workout.domain.test.js`
- `backend/tests/workout.experience.test.js`
- `backend/tests/workout.import.test.js`
- `backend/tests/workout.integration.test.js`
- `backend/tests/workout.product-parity.test.js`
- `backend/tests/workout.queries.test.js`
- `backend/tests/workout.stats.test.js`
- `test/workout_anatomy_test.dart`
- `test/workout_audit_test.dart`
- `test/workout_continuation_test.dart`
- `test/workout_custom_flow_test.dart`
- `test/workout_experience_test.dart`
- `test/workout_history_detail_test.dart`
- `test/workout_host_navigation_test.dart`
- `test/workout_import_reader_test.dart`
- `test/workout_library_test.dart`
- `test/workout_logging_test.dart`
- `test/workout_product_parity_test.dart`
- `test/workout_recovery_parity_test.dart`
- `test/workout_test.dart`
- `test/workout_tools_test.dart`
- `test/workout_transfer_flow_test.dart`
- `test/workout_visual_parity_test.dart`
- `test/workout_visual_test.dart`

## Host integration

Existing user/JWT, Coach/Client link, navigation and notification integration.

- `backend/index.js`
- `backend/middleware/auth.js`
- `lib/mainLayoutCoach.dart`
- `lib/screens/ENG/clientHome.dart`
- `lib/services/apiService.dart`
- `lib/services/notification_service.dart`
- `lib/sessionRouter.dart`

New audit files: `lib/services/workout_dates.dart`, timezone/wake-lock Flutter tests, `backend/services/chatMedia.js`, Push Day/private-media integration tests. Schema now adds private upload ownership and catalog filter indexes. Full changed-file list is in section O of the main report.

Reference source map: Home → Home/sheets/history; planning → Plan/RoutineEdit/sheets/store; execution → Workout/progression/history/RestTimer/useUI; analysis → Stats/History/effort/muscles/onerm/Heatmap/BodyMap/LineChart; portability → Settings/import-csv/plan-share; infrastructure → App/api/useStore/mobile/push/backend server. Source backend authentication/account/SQL architecture was inspected for scope and intentionally not transplanted. The fetched source SHA stayed c42ba6b; source Vitest ran 192 checks, and its actual React UI was rendered for paired 396/1100 captures.
