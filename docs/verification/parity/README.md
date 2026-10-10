# Workout parity captures and verification

Reference: [requested openGym source at c42ba6b](https://github.com/arvids-unavailable/openGym/tree/c42ba6b98e3776af5981f20c05ba392238799670). The current behavior/visual/test matrix is [WORKOUT_RECOVERY_CURRENT.md](../../WORKOUT_RECOVERY_CURRENT.md); [WORKOUT_PRODUCT_PARITY.md](../../WORKOUT_PRODUCT_PARITY.md) retains the historical audit and implementation record.

Latest functional, security, native build and real API/browser results are recorded in the [October 10 completion report](../../WORKOUT_COMPLETION_2026-10-10.md). Refreshed native Home/editor/chart captures include compact rows, circular selection and muscle chips. These deterministic pairs complement the real local MySQL journey; they do not verify hardware delivery or pixel equality.

Historical validation (2026-10-05): backend **81 passed / 3 skipped / 0 failed** (84 total, local MySQL), all thirteen Workout Flutter suites **63 passed / 1 optional capture skipped / 0 failed**, final host-navigation/app smoke **2 passed**, additional responsive/capture checks **14 passed**. Final Workout/host/model/service/localization analysis is clean. The release web rebuild after the final navigation change passed in **163.8 seconds**. Earlier results below are historical.

The [full built-app browser capture](sirvya-full-web-smoke.png) verifies SIRVYA opens Workout with one navigation bar; isolated browser fixtures also check Plan/Stats/Exercises and return to SIRVYA. All API traffic in this context is synthetic, with no production data writes. See `workout_tmp/recovery-web-smoke.json`; this verifies release browser integration, not real-user authentication, OS notification delivery or pixel equality. Local review is at http://localhost:8080 with API port 3000; scheduled outbound Workout reminders are disabled. The headless browser reports an existing unsupported intro-video format warning outside the Workout module.

The fixtures use the same recurring routine, actual completed sets, confirmed weights, active prescription, dated bodyweight and goal. They are synthetic QA fixtures, never production user data. Reference captures execute the actual React application in an isolated browser context; native captures render the actual Flutter screens with bundled fonts. These are review artifacts, not a claim of pixel equality.

| Screen | openGym 396px | SIRVYA 396px | openGym 1100px | SIRVYA 1100px |
| --- | --- | --- | --- | --- |
| Home | [reference](opengym-home-396.png) | [native](sirvya-home-396.png) | [reference](opengym-home-1100.png) | [native](sirvya-home-1100.png) |
| Plan | [reference](opengym-plan-396.png) | [native](sirvya-plan-396.png) | [reference](opengym-plan-1100.png) | [native](sirvya-plan-1100.png) |
| Stats | [reference](opengym-stats-396.png) | [native](sirvya-stats-396.png) | [reference](opengym-stats-1100.png) | [native](sirvya-stats-1100.png) |
| Active | [reference](opengym-active-396.png) | [native](sirvya-active-396.png) | [reference](opengym-active-1100.png) | [native](sirvya-active-1100.png) |
| Routine editor | [reference](opengym-editor-396.png) | [native](sirvya-editor-396.png) | [reference](opengym-editor-1100.png) | [native](sirvya-editor-1100.png) |
| Exercise configuration | [reference](opengym-configuration-396.png) | [native](sirvya-configuration-396.png) | [reference](opengym-configuration-1100.png) | [native](sirvya-configuration-1100.png) |
| Completion summary | [reference](opengym-summary-396.png) | [native](sirvya-summary-396.png) | [reference](opengym-summary-1100.png) | [native](sirvya-summary-1100.png) |
| Library | [reference](opengym-library-396.png) | [native](sirvya-library-396.png) | [reference](opengym-library-1100.png) | [native](sirvya-library-1100.png) |
| History | [reference](opengym-history-396.png) | [native](sirvya-history-396.png) | [reference](opengym-history-1100.png) | [native](sirvya-history-1100.png) |
| Custom exercise | [reference](opengym-custom-396.png) | [native](sirvya-custom-396.png) | [reference](opengym-custom-1100.png) | [native](sirvya-custom-1100.png) |
| Pre-workout check-in | [reference](opengym-checkin-396.png) | [native](sirvya-checkin-396.png) | [reference](opengym-checkin-1100.png) | [native](sirvya-checkin-1100.png) |
| Date override | [reference](opengym-day-override-396.png) | [native](sirvya-day-override-396.png) | [reference](opengym-day-override-1100.png) | [native](sirvya-day-override-1100.png) |
| Weekday assignment | [reference](opengym-day-assignment-396.png) | [native](sirvya-day-assignment-396.png) | [reference](opengym-day-assignment-1100.png) | [native](sirvya-day-assignment-1100.png) |
| Training calendar | [reference](opengym-calendar-396.png) | [native](sirvya-calendar-396.png) | [reference](opengym-calendar-1100.png) | [native](sirvya-calendar-1100.png) |
| Exercise picker | [reference](opengym-picker-396.png) | [native](sirvya-picker-396.png) | [reference](opengym-picker-1100.png) | [native](sirvya-picker-1100.png) |

The completion pair uses one completed bench set, 600 kg volume and 30 minutes. Paired page/sheet captures use the fixture's 2026-10-04 clock, so Home/Today/week labels and active elapsed time are comparable across later dates. The full built-app smoke uses the actual local date and is a separate integration artifact. The `sirvya-recovery-*` editor/picker/configuration images use a pounds/unilateral/Chosen fixture and are not matched dataset comparisons.

All fifteen pages/sheets, including the picker, now have native/reference pairs. The source/native interaction tests remain separate from visual review; the matrix keeps unresolved gaps explicit.

All images are 844px high. Content below the viewport is not visually verified by these captures. The [dataset license media exception](https://github.com/hasaneyldrm/exercises-dataset/blob/main/LICENSE) excludes original Gym Visual images/videos from MIT; reference GIFs are not downloaded without rights. Native media uses reviewed Everkinetic replacements for 24 exercise identities. Muscle maps use the same separately MIT-licensed MuscleMap contours and five-color legend, rendered and hit-tested natively. Asset loading is awaited before capture. Source-style headers, segments, chips, metric tiles and summary are aligned; October 10 improves Home/chart/editor/detail spacing; remaining native control and chart differences are documented adaptations. Passing capture tests do not imply pixel equality.

To regenerate from the workspace root (with backend dependencies and Flutter already installed):

```powershell
node backend/scripts/generateWorkoutParityFixture.mjs
$env:WORKOUT_CAPTURE = '1'
& C:/flutter/flutter/bin/cache/dart-sdk/bin/dart.exe C:/flutter/flutter/bin/cache/flutter_tools.snapshot test --no-pub test/workout_visual_parity_test.dart
Remove-Item Env:WORKOUT_CAPTURE
```

For the reference, use the pinned checkout at `workout_tmp/requested-reference`, install frontend dependencies with `npm ci --ignore-scripts`, run Vite on port 8091 and a dedicated Chrome instance with debugging on port 64423. Then run `node backend/scripts/captureWorkoutReference.mjs`. It creates/disposes an isolated fixture context and does not modify SIRVYA users, tokens or MySQL data. Use a separate browser profile. Reference source is retained; rebuildable reference dependencies and inactive temporary capture-browser profiles were cleared to recover verification storage. Reinstall reference dependencies before regenerating those captures.

The native visual suite also verifies 320px layout and that a running timer remains available across tabs and Resume does not recreate the active screen. The broader responsive suite covers English/French/Spanish and enlarged text. Other tested flows include personal autosave/retry/stable IDs, real prior-performance prefill, daily weight/goal, check-in save/skip/cancel, timed target/early Done/Cancel, and superset rest boundaries.

Backend verification uses `npm test` from `backend/` with `WORKOUT_TEST_MYSQL=1` for real local MySQL integration. Flutter verification uses all thirteen `test/workout*_test.dart` suites. The optional legacy screenshot test remains skipped without `WORKOUT_CAPTURE_SCREENSHOTS=1`; paired capture suites run independently with `WORKOUT_CAPTURE=1`. Local logs under `workout_tmp/` separate compilation, logic and visual evidence.

Earlier recovery validation on 2026-10-04 (superseded by the reinspection below where applicable):

- Backend: 76 total, 73 passed, 3 skipped, 0 failed. Includes the local MySQL lifecycle and saved-view migration.
- Flutter: final ten-suite run passed, 54 passed, 1 optional legacy capture skipped, 0 failed (4m57s). Includes personal reorder, legacy saved-view migration and refreshed native captures. A preceding attempt failed because C: had no space for `output.dill`; generated build/reference caches were cleared before the successful retries.
- Final analysis: no issues found (33.7 seconds), covering all Workout screens/models, the Workout API/preference cache, notification/file services and the two new test suites.
- Web build: the preceding recovery build passed (`build/web`, 319.7 seconds); a fresh build after the saved-view migration is still pending. Initial attempts hit Windows memory exhaustion; temporary reference helpers were stopped and validation rerun sequentially.
- Android arm64 debug build: initial Flutter invocation failed because the globally configured Java 25 is incompatible with Gradle 8.14. The direct Gradle retry uses installed Microsoft Java 17, a 1 GB heap, one worker and no persistent daemon. A stalled Windows Flutter launcher is bypassed with a temporary Gradle init override invoking the existing Dart/Flutter snapshot; global SDK/Flutter/Java settings and project build files are preserved. Dart, Java/Kotlin/Dex and ARM64 native compilation passed; final packaging is pending.
- Physical notification/sound/vibration/keep-awake/process-kill behavior: not verified; no device attached.

Historical raw logs were kept under `.git/`; current check logs are in `workout_tmp/`: `recovery-finish-backend.log`, `recovery-finish-all-flutter.log`, `recovery-final-responsive.log`, `recovery-host-final.log`, `recovery-host-analysis.log`, `recovery-finish-web-build.log` and `recovery-web-smoke.json`. Test pass and compilation are distinct from feature/UI/UX parity.

Reinspection validation on 2026-10-04: backend **76 passed, 3 skipped, 0 failed** (79 total), including real MySQL Chosen ranking/isolation, fractional RIR, minimal custom exercises and duplicate visible names. Flutter library/recovery **8 passed**; completion/visual/responsive **14 passed**. The latter checks early finish → locked summary → Home, actual totals, stopped rest timer and fresh active state, and refreshes native captures with anatomical muscle contours. A fresh combined suite/build remains pending after these last visual changes. Physical device behavior remains unverified. Reference frontend dependencies/profile were retained when automatic approval review rejected the temporary cleanup; application source was preserved.
