# A. Executive Summary

Exercise-media work performed after this audit is recorded separately in the
[media follow-up](WORKOUT_MEDIA_2026-10-10.md). The command counts below describe
the original audit run; the follow-up preserves its own retest evidence.

SIRVYA Workout is a substantial native product integration, not just an exercise import.
The existing single Flutter app, SIRVYA authentication/users, Express API and MySQL are retained.
Two realistic Push Day sessions verify prescribed versus performed data, previous sets and progression.
This audit fixes statistics/date/PR defects, history totals, wake-lock cleanup and private chat attachments.
Dependency advisories fell from 17 to zero; Firebase was migrated to its supported modular API.
Final local checks: backend 137 passed; Flutter 83 passed plus one optional capture skipped; reference 192 passed.
Release web build passed; real built-app/API/MySQL browser journey verifies 13 checks with provider fixtures disclosed.
Inventory: 81 DONE, 11 PARTIAL, two MISSING, one BLOCKED — LICENSE, one identity replacement, four exclusions.
Visual parity, physical-device/provider testing and historical credential rotation prevent production readiness.
Verdict: FUNCTIONALLY READY — NEEDS PARITY WORK; overall assessment 7.5/10.

# B. Architecture

```text
Single app: PASS
Authentication reuse: PASS
Users reused: PASS
MySQL reuse: PASS
Backend integration: PASS
Workout architecture: PARTIAL
```

Initial snapshot: Master at f81eb0d9c776c6a9410e629be9ca73859eca7686, clean status, empty diff; first 20 commits preserved in [snapshot](verification/audit-2026-10-10/snapshot.json). No reset/discard/removal of working product code. [Current implementation map](verification/audit-2026-10-10/IMPLEMENTATION_MAP.md) lists Flutter, backend, migrations, tests and host paths. [Final command results](verification/audit-2026-10-10/results.json) distinguish successful checks, interrupted runs, native/provider limitations and live preview readiness. Audit changes are uncommitted; they have not been pushed.

Flutter uses the existing SessionRouter/Client Home/Coach layout, with one nested Workout navigator and five native tabs. Existing APIService carries the existing JWT. WorkoutService coordinates request contracts/preferences and scoped recovery; WorkoutRecovery maintains account-scoped drafts/outbox with idempotent replay. Widget state and shared controllers manage active rows and a single timer host. NotificationService is the existing host local-notification/FCM service. Workout translations are EN/FR/ES. Tokens still reside in host SharedPreferences; secure native credential storage remains a useful improvement. No React WebView, separate openGym app/auth/users or second production database was found. Disposable MySQL schemas used by tests are isolation fixtures, not a new product database.

Express mounts /api/workout inside backend/index.js. requireAuth verifies signature, persisted user identity/role/token version and bans; role/link/ownership checks run server-side. A large router handles endpoints, service modules handle validation, queries, progression/statistics/muscles/import/export/reminders. mysql2 pool uses parameterized values, transactions and bounded failures. Schema compatibility migrations finish before listen; readiness checks MySQL. There is no separate ORM/repository layer. Architecture remains PARTIAL because the route and several widgets are large and responsibilities are mixed, not because another identity stack exists.

Domain: one existing Client owns many WorkoutPlans; Coach-owned plans also reference the existing Coach and authorized coachclients relationship. Personal plans have nullable coachID. Plan has many Days; Day has ordered WorkoutExercises referencing Exercises. Session belongs to Client/Plan and optionally Day; many actual WorkoutSets belong to Session. Session prescription is an immutable JSON snapshot, execution is a separate editable snapshot, and sets contain actual load/reps/time/effort. Snapshot workoutExerciseID intentionally has no FK to mutable plan slots. The original 60 kg × 3 × 10 remains preserved when actual sets are 60×10, 60×9, 57.5×10, and the Coach can compare both. That invariant is tested through actual HTTP/MySQL.

Database audit covers exercises, plans/days/slots, sessions/sets, preferences, exercise preferences, week assignments, dated overrides, alerts, imports/matching, media, backup restore fingerprints and existing weighthistory/coachclients. Private chat_uploads was added in this pass. Final live local audit: 20 tables, 34 foreign keys, all primary keys present, no relational orphans. Existing application catalog: 1,324 imported identities, 24 SIRVYA seeds and 221 retained custom entries; no dataset reimport. [Schema evidence](verification/workout-schema-audit.json) includes PKs, FKs, types, nullability, indexes, deletion rules, source counts and EXPLAIN. Unique source identity, unique session/slot/set number and one-active-client uniqueness protect key invariants. Loads use DECIMAL; effort upgrades preserve fractional RIR; timestamps use UTC DATETIME with millisecond session chronology. Numeric range constraints primarily live in validated API code, not MySQL CHECK clauses. Runtime idempotent migrations still do more schema work at boot than a versioned migration runner should. API archives/deletes safely; direct hard SQL deletion of a plan could cascade sessions and must remain restricted operationally.

Reference inspection used the actual requested repository at [c42ba6b](https://github.com/arvids-unavailable/openGym/tree/c42ba6b98e3776af5981f20c05ba392238799670), re-fetched without SHA change. Read App/router/views, sheets, stores, API/server, history/progression/onerm/effort/muscles/import/plan-share/timers/mobile/push, chart/body-map components and responsive CSS. Ran its actual Vitest suite and rendered its actual React UI. The neighboring 1.3.9 checkout is a different reference and was not used for these parity claims.

# C. What Is DONE

Verified major behavior:

- Existing imported exercise identities/instructions, paged search, debounce, combined filters, empty/loading states, selected-exercise filtering and builder picker.
- Owned custom exercises, safe updates/deletion, routine use, actual logging, history and statistics.
- Personal routines and Coach assigned plans, days/ordered slots, typed prescriptions, notes, units, supersets and muscle preview.
- Recurring weekly assignments, dated overrides/rest/reset, atomic workout move without corrupting the base week.
- Native active cards/set rows, actual set persistence, bodyweight/weighted/timed/cardio/per-side fields, effort, working-weight confirmation and completion/cancellation guards.
- Real previous performance and prefill; off/linear/Greyskull/double/time/bodyweight progression policies with controlled tests.
- Immutable original prescription separate from actual execution and Coach comparison.
- Completed history/details, true history count, actual PRs, Epley estimates, valid volume, activity heatmap, anatomical muscle maps, effort metrics and bodyweight trend/goal.
- Plan v1 portability, native plan PDF, CSV training imports, streamed Health measurement import, versioned atomic training backup and duplicate-safe restore.
- SIRVYA Workout entry/return, authenticated Client isolation and authorized Coach access.

Every DONE row in section I identifies supporting checks. These are verified implementation claims within their stated scope, not proof of every hardware condition or identical source pixels.

# D. What Is PARTIAL

| Feature | What works | What remains |
| --- | --- | --- |
| Dashboard | Real week/today, weigh-in, goal, streak and actions | Card height, spacing, dates and extra tools differ |
| Active workout parity | Rich default cards and tested actual set workflow | Four-exercise real-phone UX, keyboard and complete visual equivalence |
| Offline/recovery | Browser offline set queues and reconnects; account-scoped outbox tests | Android background, force-stop/restart, quotas and long outages |
| Wake lock | Finish/cancel/dispose ownership cleanup now tested | Physical Android screen-awake behavior |
| Timer completion cues | Sound/vibration/flash integration exists | Physical delivery and background behavior |
| Planned reminder | Valid preferences, worker/timezone/idempotency logic | Real FCM/OS permission and delivery |
| Rest notification | Existing local notification APIs and timer actions | Physical background/action delivery |
| Assignment notification | Actual in-app assignment notification path | External push delivery |
| Languages | EN/FR/ES UI; metadata instruction translations preserved | Remaining source UI languages and locale-specific review |
| Timezone parity | Profile timezone consistently groups labels/week/statistics; tested midnight/DST | Source defaults to device timezone; native still defaults UTC until profile choice |
| Mobile/accessibility | 320/396/1100 layouts; long names and 1.4 text scale tested | Actual keyboard, TalkBack, focus, OS SafeArea and three phone classes |

Host regression: password login, signup/profile routes, Coaches/Client links, reservations, existing sessions, HTTP messaging, notifications, favorites and Workout return have passing targeted checks. Actual Google/Apple sign-in, email and push delivery are not established by fixture substitution. Flutter logout/token handling has relevant service tests; a manual full-host logout/login roundtrip was not run for every platform. Existing Flutter SocketService has no matching server-side Socket.IO implementation, so host realtime messaging is still incomplete independently of Workout. Signed chat media works over HTTP, but links need renewal after their 15-minute validity in long-lived chat views.

# E. What Is MISSING

| Feature | openGym behavior | SIRVYA now | Required implementation | Priority |
| --- | --- | --- | --- | --- |
| Raw openGym full backup adapter | Restore raw source S including training state | Own versioned backup and compatible plan v1 work; raw full-state file rejected | Preview and explicit source-to-native adapter for training-only fields; resolve active-session policy | P2 MEDIUM |
| Bulk training-only reset | Reset plan/workouts/bodyweight in Workout settings | Individual deletion/archive only | Scoped transactional reset, preview, ownership checks and confirmation; preserve host account/Coach boundaries | P2 MEDIUM |
| Full original demonstration coverage | Catalog GymVisual demonstrations | Licensed originals intentionally absent; replacement media covers 24 identities | Obtain compatible rights or make/curate additional licensed media | P1 HIGH; BLOCKED — LICENSE |

Not source parity gaps: no source Coach system, no source assisted negative-weight exercise support, no source requirement for a public 1RM formula selector. The onerm utility contains multiple formulas, but the rendered requested source product uses Epley. Routine duplication, warmups/drops/rest-pause, historical editing, multi-routine days and advanced Coach balance tools are SIRVYA extensions.

# F. What Is BROKEN

Fixed in this audit:

| Problem | Severity/root cause | Fix | Retest |
| --- | --- | --- | --- |
| False weekly PRs | P1; stats discarded pre-week history before record comparison | Retain lifetime baseline, then apply profile calendar-week filter | Stats regression and two-session Push Day pass |
| Wrong date/week near midnight | P1; UTC server window and device-local Flutter labels disagreed with profile timezone | Profile calendar range and shared Flutter timezone date helpers; bare dates stay calendar dates | Date-line, Casablanca midnight and New York DST tests pass |
| Weighted bodyweight PR missed | P1; bodyweight classified only as reps even with external load | Use load/e1RM/volume metrics when actual external load exists | Controlled weighted/unloaded record tests pass |
| History total understated | P1; response omitted total, frontend used loaded page length | Scoped count query and response total | HTTP/MySQL history and final browser checks pass |
| Screen remains awake | P1; cleanup consulted a changed preference and waited for summary dismissal | Track acquired lock; release on successful finish/cancel/dispose; cancel elapsed ticker | Two focused widget regressions pass |
| Public private-chat attachments | P0; broad public /uploads mount and guessable filenames | Private mount before static; UUID names; ownership records; scoped expiring capability, user/token-version recheck | Private-media HTTP tests, wrong-user/unauthenticated/revoked cases pass |
| HTML accepted as audio | P0; unsanitized upload extension reached public static hosting | Restricted audio extensions and private attachment delivery | HTML rejected; valid WAV range request returns 206 |
| Vulnerable/unused dependencies | P0/P1; 17 production advisories including one critical | Remove unused cloudinary/storage/google-auth packages; upgrade patched dependencies; remove nodemon and use node --watch | Live full npm audit: zero vulnerabilities; full backend 137 pass |
| Firebase upgrade compatibility | Upgrade regression; legacy admin namespace removed in v14 | Modular getApps/initializeApp/cert/getAuth/getMessaging; single initializer | Initially 16 suite files failed; final full run 137 pass |
| Existing password could be overwritten | P0; initial setup accepted any existing authenticated account and overwrote passwordHash | Require passwordless linked-provider identity, reject existing hash, atomic WHERE passwordHash IS NULL, matched 8-character/72-byte limits | Two new security regressions pass; full backend 137 pass |
| Completion N+1 query | P2; previous PR sets queried once per exercise | Batch all involved exercise IDs into one prior-set query | Full backend and Push Day pass |

Important unresolved problems: historical backend.tar.gz contains credential material; real host realtime transport is absent; selected tab/completion backdrop remains visually stale. Historical credentials cannot be repaired by merely editing the current tree. Provider credential rotation and coordinated Git-history cleanup are required. No working feature or history was deleted to hide the finding.

# G. What Is DIFFERENT FROM OPENGYM

Functional difference: SIRVYA adds authorized Coaches, relational server persistence, original-versus-actual comparisons, stronger ownership and duplicate-safe data portability. Native backup merges selected training data rather than replacing the source store; active drafts/media are excluded. Source workouts are personal/local-first; SIRVYA needs server connectivity for plans and finishing, with offline set recovery rather than fully offline plan management.

UI difference: native typography/icons/steppers/scrims, combined weekly card, numeric history dates, centered desktop catalog, lower-chart treatment, larger check-in/configuration sheets and additional tools. Source backdrop blur becomes native dimming. Anatomy contours are licensed source geometry, but placement and controls differ. Original licensed-restricted demonstration media is not present. Blank reference image slots in QA captures are not evidence that the production source has no demonstrations.

UX difference: source personal routine edits are live; native personal autosave matches that while Coach save is explicit. Native atomic move combines two source date-override actions. Extra guided/compact modes, advanced tools and training imports add choices. Current native active route highlights Home, and completion keeps the active backdrop until Nice is dismissed; both should be polished.

Training logic difference: source Epley UI has a 12-rep cap and one-rep measured load, matching the native formula/eligibility. Native canonical-unit conversion improves on source raw-number relabeling. Personal double progression follows the last actual target; Coach double progression is intentionally stricter against the original upper-range prescription. Native PRs use logged actual sets, excluding source confirmed-but-unlogged load behavior. Native adds volume/repetition/timed records and excludes warmups from applicable performance calculations.

# H. Improvements

| Priority/category | Improvement | Why/impact | Effort |
| --- | --- | --- | --- |
| P0 Security | Rotate archived Firebase/environment credentials; coordinate history cleanup | Historical exposure remains reachable; prevents reuse of leaked material | MEDIUM; owner/provider access required |
| P0 Security/release | Verify HTTPS deployment, current secrets and token revocation after rotation | Local HTTP is development only; host default mobile URL still needs release configuration | MEDIUM |
| P1 Client/testing | Real Android Push Day twice, background/force-stop/offline replay and timers | Confirms data survival and OS-dependent controls beyond mocks | MEDIUM |
| P1 Coach/testing | Browser/phone build-and-assign four-exercise plan, then review actual versus planned | Current full assignment proof is HTTP; browser verifies reception/review | MEDIUM |
| P1 Security/notifications | Real Google/Apple/email/FCM permission and delivery checks | Provider fixtures establish contracts, not live identity/delivery | MEDIUM |
| P1 Data/media | Expand licensed demonstration coverage with attribution | Most catalog exercises lack native instructional animation | HIGH |
| P2 UX | Match weekly cards, option rows, sheet proportions, active tab and completion backdrop | Reduces visible source/native differences and confusing active state | MEDIUM |
| P2 Architecture/performance | Split active widget/builder/progress and large router; version migrations | Improves maintainability without replacing working flows | MEDIUM |
| P2 Performance | Batch session-start history/prefill; bound/statistically aggregate long histories | Start still queries per exercise; stats loads all user history | MEDIUM |
| P2 Security/client | Secure native token storage; refresh signed media URLs before playback | Reduces persistent credential exposure and expired-media failures | MEDIUM |
| P2 Data portability | Raw source full-backup adapter and scoped training reset | Closes the two explicit discovered product gaps | MEDIUM |
| P2 Coach UX | Explain progression policies and compare targets in review | Makes stricter Coach policy understandable | LOW |
| P2 Data quality | Source/provenance labels for similar exercise seeds/imports; more UI languages | Avoids confusing near-duplicates and closes language parity | MEDIUM |
| P3 Maintainability | Consolidate duplicate Google route and label/date/icon inconsistencies | Removes dead duplication; does not justify a full rewrite | LOW |

MUST FIX before production: historical credential exposure, release HTTPS/current-secret verification, real device recovery/timers and live provider validation. NICE TO HAVE after parity: extra plate/equipment/favorite/balance tools. Existing extra features need not be deleted; keep them behind optional controls so they do not dominate the primary workout flow.

# I. Full Feature Parity Matrix

The full Step-4 format is [the master matrix](WORKOUT_MASTER_PARITY_2026-10-10.md); [machine rows](verification/audit-2026-10-10/parity.json) include source paths and exact supporting test files. This is a 100-row current inventory, not a calculated 82% product-completion score. Individual row weights differ. Coach-only extension and infrastructure exclusions are identified explicitly. Scores are conservative expert judgments supported by source/tests/captures; they are not automated pixel or test-coverage measurements. No feature receives 10/10.

| Feature | openGym | SIRVYA | Status | Functional score | UI score | UX score | Test | Priority |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Workout navigation | Five tabs; persistent Start/Resume | Native five tabs and Back to SIRVYA | DONE | 9 | 7 | 8 | docs/verification/workout-live-journey.json; test/workout_visual_parity_test.dart; reviewed docs/verification/parity images | P2 MEDIUM |
| Dashboard hierarchy | Week/today, weight, goal and streak | All present; adds recent workouts and tools | PARTIAL | 9 | 7 | 7 | docs/verification/workout-live-journey.json; test/workout_visual_parity_test.dart; reviewed docs/verification/parity images | P2 MEDIUM |
| Week browsing and markers | Seven dates with planned/completed/override markers | Browsable weeks with real schedule and activity | DONE | 9 | 7 | 8 | backend/tests/workout.integration.test.js; test/workout_visual_parity_test.dart; reviewed docs/verification/parity images | P2 MEDIUM |
| Today and current workout | Effective routine or rest; active workout takes precedence | Today's schedule with Start/Resume precedence | DONE | 9 | 7 | 8 | docs/verification/workout-live-journey.json; test/workout_recovery_parity_test.dart; test/workout_continuation_test.dart | P2 MEDIUM |
| Empty-state starter program | Load PPL starter or create routine | Starter identity/specification assertions and installation work | DONE | 9 | 7 | 8 | backend/tests/workout.integration.test.js; backend/tests/workout.product-parity.test.js; backend/tests/workout.experience.test.js | P2 MEDIUM |
| Workout chooser | Select routine instead of today's routine | Chooser and retained exercise picker | DONE | 9 | 7 | 8 | test/workout_logging_test.dart; test/workout_visual_parity_test.dart; reviewed docs/verification/parity images | P2 MEDIUM |
| Pre-workout weigh-in | Save and start, skip, or choose another workout | All three actions; real browser optional check-in | DONE | 9 | 7 | 8 | docs/verification/workout-live-journey.json; test/workout_visual_parity_test.dart; reviewed docs/verification/parity images | P2 MEDIUM |
| Week streak | Consecutive trained weeks; current-week grace | Calculated from stored completed sessions | DONE | 9 | 7 | 8 | backend/tests/workout.stats.test.js; test/workout_visual_parity_test.dart; reviewed docs/verification/parity images | P2 MEDIUM |
| Training calendar | Month totals and trained/planned/rescheduled dates | Real month drilldown and date actions | DONE | 9 | 7 | 8 | backend/tests/workout.stats.test.js; test/workout_visual_parity_test.dart; reviewed docs/verification/parity images | P2 MEDIUM |
| Weekly assignment | Sunday-indexed recurring routine/rest assignments | Monday-Sunday native assignments persisted separately | DONE | 9 | 6 | 8 | backend/tests/workout.integration.test.js; test/workout_visual_parity_test.dart; reviewed docs/verification/parity images | P2 MEDIUM |
| Dated override | Replace just one date; reset to recurring plan | One-tap override/rest/reset; base week preserved | DONE | 9 | 7 | 8 | backend/tests/workout.integration.test.js; test/workout_visual_parity_test.dart; reviewed docs/verification/parity images | P2 MEDIUM |
| Reschedule workout | Source uses separate source/destination overrides | Native atomic move updates two dates, preserves base program | DONE | 9 | 7 | 8 | backend/tests/workout.integration.test.js | P2 MEDIUM |
| Create/edit routine | Reusable named routine with live updates | Personal routine autosave, stable IDs/retry; Coach explicit save | DONE | 9 | 7 | 8 | test/workout_recovery_parity_test.dart; test/workout_continuation_test.dart; backend/tests/workout.integration.test.js; test/workout_visual_parity_test.dart; reviewed docs/verification/parity images | P2 MEDIUM |
| Delete routine | Clear schedule references; retain old logs | Archive/cleanup preserves snapshots and history | DONE | 9 | 7 | 8 | backend/tests/workout.integration.test.js | P2 MEDIUM |
| Routine names and glyphs | Editable label and icon | Validated label and persisted glyph configuration | DONE | 9 | 7 | 8 | backend/tests/workout.product-parity.test.js; backend/tests/workout.experience.test.js; test/workout_visual_parity_test.dart; reviewed docs/verification/parity images | P3 LOW |
| Add/remove exercises | Picker selection and removal from routine | Search picker, save/cancel retention and stable slots | DONE | 9 | 7 | 8 | test/workout_library_test.dart; test/workout_custom_flow_test.dart; test/workout_recovery_parity_test.dart; test/workout_continuation_test.dart | P2 MEDIUM |
| Exercise reordering | Move exercises; repair invalid superset links | Personal swap and group cleanup; Coach group controls | DONE | 9 | 7 | 8 | backend/tests/workout.product-parity.test.js; backend/tests/workout.experience.test.js; test/workout_recovery_parity_test.dart; test/workout_continuation_test.dart | P2 MEDIUM |
| Sets/reps/load configuration | Set counts, rep totals, working load | Validated prescription fields persisted in MySQL | DONE | 9 | 6 | 8 | backend/tests/workout.domain.test.js; backend/tests/workout.push-day.integration.test.js; test/workout_visual_parity_test.dart; reviewed docs/verification/parity images | P2 MEDIUM |
| Timed prescription | Held seconds and optional external load | Timed mode target/actual stored separately | DONE | 9 | 6 | 8 | backend/tests/workout.domain.test.js; backend/tests/workout.push-day.integration.test.js; test/workout_logging_test.dart | P2 MEDIUM |
| Bodyweight prescription | Optional added load; per-side rep option | Unloaded and weighted bodyweight supported | DONE | 9 | 6 | 8 | backend/tests/workout.domain.test.js; backend/tests/workout.product-parity.test.js; backend/tests/workout.experience.test.js | P2 MEDIUM |
| Superset configuration | Link adjacent exercises; clean singleton links | Adjacent grouping and round-robin execution | DONE | 9 | 7 | 8 | backend/tests/workout.product-parity.test.js; backend/tests/workout.experience.test.js; test/workout_logging_test.dart | P2 MEDIUM |
| Routine muscle preview | Planned effective sets on front/back body | Native MIT anatomy with planned-set intensity and chips | DONE | 9 | 7 | 8 | test/workout_anatomy_test.dart; backend/tests/workout.stats.test.js; test/workout_visual_parity_test.dart; reviewed docs/verification/parity images | P2 MEDIUM |
| Routine unit preference | Routine/history display respects kg/lb | Canonical kg with actual kg/lb conversion | DONE | 9 | 7 | 8 | backend/tests/workout.product-parity.test.js; backend/tests/workout.experience.test.js; test/workout_logging_test.dart | P2 MEDIUM |
| Plan sharing/import | openGym v1 plan with routines/customs/week | Compatible v1 and native plan import/export | DONE | 9 | 6 | 8 | backend/tests/workout.product-parity.test.js; backend/tests/workout.experience.test.js; backend/tests/workout.import.test.js; backend/tests/workout.backup.integration.test.js; test/workout_transfer_flow_test.dart | P2 MEDIUM |
| Printable program | Browser print/PDF workout plan | Flutter training PDF generation | DONE | 8 | 6 | 7 | test/workout_tools_test.dart | P2 MEDIUM |
| Exercise metadata identities | 1324 exercise identities and instructions | 1324 imported identities plus 24 SIRVYA seeds; existing custom exercises retained | DONE | 9 | 7 | 8 | backend/tests/workout.integration.test.js; test/workout_library_test.dart; test/workout_custom_flow_test.dart | P2 MEDIUM |
| Exercise list | Searchable catalog and workout selection | Paged native catalog and picker | DONE | 9 | 7 | 8 | test/workout_library_test.dart; test/workout_custom_flow_test.dart; docs/verification/workout-live-journey.json | P2 MEDIUM |
| Search debounce | Filtered search while typing | Debounced query; bounded 50-row pages | DONE | 9 | 7 | 8 | test/workout_library_test.dart; test/workout_custom_flow_test.dart | P2 MEDIUM |
| Body-part and equipment filters | Combined body-part/equipment chips | Combined chips plus extra type/muscle filtering | DONE | 9 | 7 | 8 | test/workout_library_test.dart; test/workout_custom_flow_test.dart | P2 MEDIUM |
| Chosen exercises filter | Filter to exercises already in routines | Chosen identities retained with filter reset | DONE | 9 | 7 | 8 | test/workout_library_test.dart; test/workout_custom_flow_test.dart; backend/tests/workout.product-parity.test.js; backend/tests/workout.experience.test.js | P2 MEDIUM |
| Loading/empty/pagination | Results, no matches, bounded rendering | Loading/error/empty states and 50-to-100 paging tested | DONE | 9 | 7 | 8 | test/workout_library_test.dart; test/workout_custom_flow_test.dart | P2 MEDIUM |
| Instructions/details | Exercise information and translated instructions | Metadata/instructions visible with native detail and history | DONE | 8 | 6 | 7 | test/workout_library_test.dart; test/workout_custom_flow_test.dart; backend/tests/workout.domain.test.js | P2 MEDIUM |
| Original catalog demonstration media | GymVisual GIF/image catalog | Restricted original media omitted; replacement coverage limited | BLOCKED — LICENSE | 3 | 3 | 4 | pinned reference source inspection | P1 HIGH |
| Licensed replacement demonstrations | Reference loads demonstrative media | 19 reviewed demos cover 24 identities; 38 CC BY-SA frames | DONE | 8 | 6 | 7 | backend/tests/workout.demonstrations.test.js | P2 MEDIUM |
| Media size/show preference | Demonstration visibility and sizing | Persisted visibility/size with licensed playback | DONE | 8 | 6 | 7 | backend/tests/workout.product-parity.test.js; backend/tests/workout.experience.test.js; test/workout_logging_test.dart | P2 MEDIUM |
| Create custom exercise | Name/body part/description; cardio default from body part | Private owned custom, minimal form and optional advanced fields | DONE | 9 | 7 | 8 | test/workout_library_test.dart; test/workout_custom_flow_test.dart; backend/tests/workout.product-parity.test.js; backend/tests/workout.experience.test.js | P2 MEDIUM |
| Edit/delete custom exercise | Owned custom updates/removal; historical behavior retained | Authorization, archive/in-use safety, existing history preserved | DONE | 9 | 7 | 8 | backend/tests/workout.integration.test.js; test/workout_library_test.dart; test/workout_custom_flow_test.dart | P2 MEDIUM |
| Custom routine/log/history/stats | Customs behave as normal exercises | Stable custom IDs used across plan, actual sets and statistics | DONE | 9 | 7 | 8 | backend/tests/workout.integration.test.js; test/workout_library_test.dart; test/workout_custom_flow_test.dart; backend/tests/workout.stats.test.js | P2 MEDIUM |
| Active workout hierarchy | Exercise cards, demonstration, targets, last time, set grid | Rich default cards, actual previous values, targets and set rows | PARTIAL | 9 | 7 | 8 | docs/verification/workout-live-journey.json; test/workout_logging_test.dart; test/workout_visual_parity_test.dart; reviewed docs/verification/parity images | P1 HIGH |
| Set weight/reps editing | Inline stepper inputs and completion check | Inline native rows with validated load/reps and completion | DONE | 9 | 7 | 8 | docs/verification/workout-live-journey.json; test/workout_logging_test.dart; backend/tests/workout.push-day.integration.test.js | P2 MEDIUM |
| Complete/undo/add/remove set | Edit live completed state and set count | Persisted actual sets with stable slot identity and retries | DONE | 9 | 7 | 8 | backend/tests/workout.integration.test.js; test/workout_logging_test.dart | P2 MEDIUM |
| Previous performance | Actual most recent sets, dates and loads | Database previous sets; second Push Day checks real values | DONE | 9 | 7 | 8 | backend/tests/workout.push-day.integration.test.js; backend/tests/workout.product-parity.test.js; backend/tests/workout.experience.test.js; test/workout_logging_test.dart | P1 HIGH |
| Prefill precedence | Previous working performance, progression, then target | Personal source policy plus stricter assigned Coach prescription | DONE | 9 | 7 | 8 | backend/tests/workout.push-day.integration.test.js; backend/tests/workout.product-parity.test.js; backend/tests/workout.experience.test.js | P1 HIGH |
| Working weight confirmation | Confirm learned working load; unconfirmed actual load remains usable | Stored preference plus real previous-load precedence | DONE | 9 | 7 | 8 | docs/verification/workout-live-journey.json; backend/tests/workout.product-parity.test.js; backend/tests/workout.experience.test.js | P2 MEDIUM |
| Superset sequencing | A1/A2 back-to-back; rest only after last member | Round-robin set sequence and appropriate rest boundary | DONE | 9 | 7 | 8 | test/workout_logging_test.dart; backend/tests/workout.product-parity.test.js; backend/tests/workout.experience.test.js | P1 HIGH |
| Unloaded/weighted bodyweight | Reps without mandatory external load; added load optional | Saved reps/load and appropriate records; weighted PR fix included | DONE | 9 | 7 | 8 | backend/tests/workout.domain.test.js; backend/tests/workout.stats.test.js | P1 HIGH |
| Per-side reps | Even total-rep prescription with per-side interpretation | Even targets validated; adds unequal-side actual logging | DONE | 9 | 7 | 8 | backend/tests/workout.product-parity.test.js; backend/tests/workout.experience.test.js; test/workout_logging_test.dart | P2 MEDIUM |
| Cardio logging | Duration and speed; derives distance | Duration/distance/speed persisted and reported separately | DONE | 9 | 6 | 7 | backend/tests/workout.domain.test.js; backend/tests/workout.product-parity.test.js; backend/tests/workout.experience.test.js | P2 MEDIUM |
| RIR/RPE effort | Optional chosen scale; half-point RIR; no effect on progression/1RM | Validated optional effort retained in sets/history/stats | DONE | 9 | 7 | 8 | backend/tests/workout.product-parity.test.js; backend/tests/workout.experience.test.js; backend/tests/workout.push-day.integration.test.js | P1 HIGH |
| Exercise descriptions and training notes | Custom descriptions/setup cues are shown during training | Plan/exercise/session notes and historical notes extend source behavior | DONE | 9 | 6 | 7 | backend/tests/workout.integration.test.js; backend/tests/workout.import.test.js; backend/tests/workout.backup.integration.test.js; test/workout_transfer_flow_test.dart | P2 MEDIUM |
| Finish prompt and summary | Incomplete confirmation; duration/sets/volume/PR/muscles | Persisted finish, incomplete/cancel guards, real summary | DONE | 9 | 7 | 8 | docs/verification/workout-live-journey.json; backend/tests/workout.push-day.integration.test.js; test/workout_visual_parity_test.dart; reviewed docs/verification/parity images | P1 HIGH |
| Cancellation/exit | Confirm cancellation; retained live workout across navigation | Confirmation, Resume and separate cancelled status | DONE | 9 | 7 | 8 | backend/tests/workout.integration.test.js; test/workout_recovery_parity_test.dart; test/workout_continuation_test.dart | P1 HIGH |
| Offline completed-set recovery | Local active state persists; server sync failure handled | Account-scoped draft/outbox, idempotent set replay and retry | PARTIAL | 8 | 6 | 7 | docs/verification/workout-live-journey.json; test/workout_recovery_parity_test.dart; test/workout_continuation_test.dart | P0 CRITICAL |
| Automatic rest | Starts after correct working set/superset boundary | Independent rest controller with boundary rules | DONE | 9 | 7 | 8 | test/workout_logging_test.dart; backend/tests/workout.product-parity.test.js; backend/tests/workout.experience.test.js | P1 HIGH |
| Rest deadline stability | Wall-clock countdown survives background throttling | Absolute deadlines; restore remaining time and single global host | DONE | 9 | 7 | 8 | test/workout_recovery_parity_test.dart; test/workout_continuation_test.dart; test/workout_logging_test.dart | P1 HIGH |
| Rest add/skip controls | Add/subtract time and skip | Add/subtract/skip plus native pause/resume | DONE | 9 | 7 | 8 | test/workout_logging_test.dart | P2 MEDIUM |
| Timed work set | Start hold, auto-complete target, early-stop actual duration | Independent work timer and persisted actual seconds | DONE | 9 | 7 | 8 | test/workout_logging_test.dart; backend/tests/workout.push-day.integration.test.js | P1 HIGH |
| Work/rest conflict prevention | One working timer; rest starts after completed hold | Separate work/rest state with global timer ownership | DONE | 9 | 7 | 8 | test/workout_logging_test.dart; test/workout_recovery_parity_test.dart; test/workout_continuation_test.dart | P1 HIGH |
| Sound/vibration/flash | Optional completion cues | Existing SIRVYA local notification/haptic/audio APIs | PARTIAL | 7 | 6 | 7 | test/workout_logging_test.dart | P1 HIGH |
| Screen awake | Wake lock while actively training | Ownership cleanup fixed at finish/cancel/dispose | PARTIAL | 8 | 7 | 8 | test/workout_wakelock_test.dart | P1 HIGH |
| No progression | Repeat prescribed/remembered target | Explicit off policy | DONE | 9 | 7 | 8 | backend/tests/workout.product-parity.test.js; backend/tests/workout.experience.test.js | P1 HIGH |
| Linear progression | Increase successful load; repeated misses deload | Actual working-set success, source increments and miss/deload rules | DONE | 9 | 7 | 8 | backend/tests/workout.product-parity.test.js; backend/tests/workout.experience.test.js; backend/tests/workout.push-day.integration.test.js | P1 HIGH |
| Greyskull progression | AMRAP/last-set threshold affects load increase | Configured Greyskull policy with controlled-value tests | DONE | 9 | 6 | 7 | backend/tests/workout.product-parity.test.js; backend/tests/workout.experience.test.js | P1 HIGH |
| Double progression | Rep range; judge most recent actual target; add load on success | Personal source rule; Coach retains original upper-range requirement | DONE | 9 | 6 | 7 | backend/tests/workout.product-parity.test.js; backend/tests/workout.experience.test.js | P1 HIGH |
| Timed progression | Increase hold seconds on success; deload after misses | Time policy with 45-to-50-second Push Day proof | DONE | 9 | 6 | 7 | backend/tests/workout.push-day.integration.test.js; backend/tests/workout.product-parity.test.js; backend/tests/workout.experience.test.js | P1 HIGH |
| Bodyweight progression | Increase reps or sets at configured ceiling | Rep ceiling/set cap with per-side step normalization | DONE | 9 | 6 | 7 | backend/tests/workout.product-parity.test.js; backend/tests/workout.experience.test.js | P1 HIGH |
| Policy/configuration change | Changed prescription should reset relevant progression | Original targets/policy checked; notes-only edits keep history | DONE | 9 | 6 | 7 | backend/tests/workout.product-parity.test.js; backend/tests/workout.experience.test.js | P1 HIGH |
| Chronological history and true count | Reverse completed workouts; detail entry | Paged real history, actual total count fixed this audit | DONE | 9 | 7 | 8 | docs/verification/workout-live-journey.json; backend/tests/workout.push-day.integration.test.js; backend/tests/workout.integration.test.js | P1 HIGH |
| Workout detail | Date/duration/sets/reps/load/time/effort/notes | Original versus actual snapshots and all performed fields | DONE | 9 | 7 | 8 | backend/tests/workout.push-day.integration.test.js; test/workout_history_detail_test.dart | P1 HIGH |
| Exercise history and progression | Exercise records, load/rep/duration points | Real previous sessions and exercise charts | DONE | 8 | 6 | 7 | backend/tests/workout.stats.test.js; backend/tests/workout.integration.test.js | P2 MEDIUM |
| Personal records | Heaviest load and estimated 1RM at completion | Actual-only load/e1RM; adds reps/volume/timed records | DONE | 9 | 7 | 8 | backend/tests/workout.stats.test.js; backend/tests/workout.push-day.integration.test.js | P1 HIGH |
| Period PR baseline | Period metrics must compare with earlier lifetime performance | Weekly false-PR defect fixed; prior baseline retained | DONE | 9 | 7 | 8 | backend/tests/workout.stats.test.js; backend/tests/workout.push-day.integration.test.js | P1 HIGH |
| Estimated 1RM | UI uses Epley, rep cap 12; one rep returns measured load | Same eligibility/formula; warmups/timed/unloaded excluded | DONE | 9 | 6 | 7 | backend/tests/workout.domain.test.js; backend/tests/workout.stats.test.js | P1 HIGH |
| Training volume | Load multiplied by completed reps; no fake timed volume | Actual weighted rep volume; timed/cardio volume zero | DONE | 9 | 7 | 8 | backend/tests/workout.domain.test.js; backend/tests/workout.push-day.integration.test.js | P1 HIGH |
| Overview counters | Workouts, month count, streak, bodyweight delta | Real stored-session counters and weight delta | DONE | 9 | 7 | 8 | backend/tests/workout.stats.test.js; test/workout_visual_parity_test.dart; reviewed docs/verification/parity images; docs/verification/workout-live-journey.json | P2 MEDIUM |
| Activity heatmap | 12-month duration intensity and day drilldown | Actual dates and duration intensity; drilldown/calendar | DONE | 9 | 7 | 8 | backend/tests/workout.stats.test.js; test/workout_visual_parity_test.dart; reviewed docs/verification/parity images | P2 MEDIUM |
| Muscle map front/back | Gender-specific anatomical contours and trained intensity | Native four MIT figures; actual weighted muscle contributions | DONE | 9 | 7 | 8 | test/workout_anatomy_test.dart; backend/tests/workout.stats.test.js; test/workout_visual_parity_test.dart; reviewed docs/verification/parity images | P2 MEDIUM |
| Muscle periods and effort filters | Week/30d/90d/all and effort context | Actual local-week windows, weighted effective/hard sets | DONE | 9 | 7 | 8 | backend/tests/workout.stats.test.js; backend/tests/workout.product-parity.test.js; backend/tests/workout.experience.test.js | P1 HIGH |
| Effort distribution and trend | RPE/RIR distribution, hard sets and weekly trend | Stored effort used for distributions; no invented zeros | DONE | 9 | 6 | 7 | backend/tests/workout.product-parity.test.js; backend/tests/workout.experience.test.js; backend/tests/workout.stats.test.js | P2 MEDIUM |
| Exercise performance charts | Loads/reps/time/1RM where eligible | Actual exercise points and record source data | DONE | 8 | 6 | 7 | backend/tests/workout.stats.test.js; backend/tests/workout.integration.test.js | P2 MEDIUM |
| Bodyweight trend and goal | Dated readings, last 30 points, goal-aware change | Existing weighthistory reused; goal and trends from actual readings | DONE | 9 | 7 | 8 | backend/tests/workout.import.test.js; backend/tests/workout.backup.integration.test.js; test/workout_transfer_flow_test.dart; test/workout_visual_parity_test.dart; reviewed docs/verification/parity images | P2 MEDIUM |
| Units | Workout-specific kg/lb display | Explicit canonical-unit conversion and persisted preference | DONE | 9 | 7 | 8 | backend/tests/workout.product-parity.test.js; backend/tests/workout.experience.test.js; backend/tests/workout.import.test.js; backend/tests/workout.backup.integration.test.js; test/workout_transfer_flow_test.dart | P2 MEDIUM |
| Timezone and calendar grouping | Device local workout day | Profile IANA timezone now shared by labels/week/stats; bare dates preserved | PARTIAL | 8 | 7 | 8 | test/workout_timezone_test.dart; backend/tests/workout.stats.test.js | P2 MEDIUM |
| Workout history CSV import | Strong/Hevy/FitNotes matching and conversions | Preview, validate, match/custom-create, transaction and duplicate handling | DONE | 9 | 6 | 8 | backend/tests/workout.import.test.js; backend/tests/workout.backup.integration.test.js; test/workout_transfer_flow_test.dart; backend/tests/workout.integration.test.js | P1 HIGH |
| Bodyweight CSV/Health import | CSV and Apple Health weight records | Streaming browser Health import over 8 MiB, date/unit/duplicate validation | DONE | 9 | 6 | 8 | docs/verification/workout-live-journey.json; backend/tests/workout.import.test.js; backend/tests/workout.backup.integration.test.js; test/workout_transfer_flow_test.dart | P1 HIGH |
| Workout training backup/export | JSON state backup and restore | Atomic versioned Workout-only backup, full history paging and restore | DONE | 9 | 6 | 8 | docs/verification/workout-live-journey.json; backend/tests/workout.import.test.js; backend/tests/workout.backup.integration.test.js; test/workout_transfer_flow_test.dart | P1 HIGH |
| Raw openGym full-state migration | Restore raw source S including active/preferences | Compatible plan v1 only; own full backup has a different schema | MISSING | 0 | 0 | 0 | pinned reference source inspection; backend/tests/workout.import.test.js; backend/tests/workout.backup.integration.test.js; test/workout_transfer_flow_test.dart | P2 MEDIUM |
| Training-only reset | Reset routines/workouts/bodyweight from settings | Individual deletion exists; no atomic bulk Workout reset | MISSING | 0 | 0 | 0 | pinned reference source inspection | P2 MEDIUM |
| Workout-specific settings | Rest, effort scale, media, units, wake lock and reminders | Preferences stored per existing user | DONE | 9 | 6 | 8 | backend/tests/workout.product-parity.test.js; backend/tests/workout.experience.test.js; backend/tests/workout.integration.test.js | P2 MEDIUM |
| Training language coverage | 12 UI languages; 10 instruction languages including English | Workout UI EN/FR/ES; imported metadata translations retained | PARTIAL | 6 | 6 | 6 | pinned reference source inspection; test/workout_library_test.dart; test/workout_custom_flow_test.dart | P2 MEDIUM |
| Planned workout reminder | Scheduled reminder in device timezone with permission flow | Existing SIRVYA reminder worker/FCM and workout preferences | PARTIAL | 7 | 6 | 7 | backend/tests/workout.product-parity.test.js; backend/tests/workout.experience.test.js; backend/tests/workout.integration.test.js | P1 HIGH |
| Rest completion notification | Source web/mobile notification integration | Existing native local notification service and timer controls | PARTIAL | 7 | 6 | 7 | test/workout_logging_test.dart; test/workout_recovery_parity_test.dart; test/workout_continuation_test.dart | P1 HIGH |
| Assigned-plan notification | No Coach assignment feature in source | SIRVYA in-app assignment notification, existing push delivery path | PARTIAL | 8 | 6 | 7 | backend/tests/workout.push-day.integration.test.js; backend/tests/app.integration.test.js; test/workout_host_navigation_test.dart | P1 HIGH |
| Responsive workout UI | Mobile sheets and desktop layouts | 320/396/1100 widths and 1.4 text-scale widget checks | PARTIAL | 8 | 7 | 7 | test/workout_visual_parity_test.dart; reviewed docs/verification/parity images | P2 MEDIUM |
| Error/network feedback | Local active state plus server failure handling | Loading/error/retry and offline queued sets | DONE | 8 | 6 | 7 | docs/verification/workout-live-journey.json; test/workout_recovery_parity_test.dart; test/workout_continuation_test.dart | P1 HIGH |
| Authentication/login/register | Source has separate auth/passkeys | Existing SIRVYA authentication is reused | EXCLUDED — AUTH | — | — | — | backend/tests/app.integration.test.js; test/workout_host_navigation_test.dart | P0 CRITICAL |
| Account/admin/user system | Source users/account/admin routes | Existing SIRVYA users/roles retained | EXCLUDED — ACCOUNT | — | — | — | backend/tests/app.integration.test.js; test/workout_host_navigation_test.dart | P0 CRITICAL |
| General theme/account settings | General source settings outside workout controls | Host settings remain separate | EXCLUDED — GENERAL SETTINGS | — | — | — | pinned reference source inspection | P3 LOW |
| Standalone hosting/store build | Reference web/native hosting architecture | One Flutter app plus existing Express/MySQL backend | EXCLUDED — NON-WORKOUT | — | — | — | pinned reference source inspection | P3 LOW |
| Persistence/identity replacement | Source store, authentication and remote sync | SIRVYA authenticated API, scoped local recovery, MySQL ownership | REPLACED BY SIRVYA | 9 | 7 | 8 | backend/tests/app.integration.test.js; test/workout_host_navigation_test.dart; backend/tests/workout.integration.test.js; docs/verification/workout-live-journey.json | P0 CRITICAL |

Rendered-screen assessment (F/UI/UX out of ten):

| Screen | F | UI | UX | Concrete basis/limit |
| --- | --- | --- | --- | --- |
| Workout Home | 9 | 7 | 8 | Paired 396px: same week/Today/weight/streak hierarchy, taller native cards and extra tools |
| Weekly Plan | 9 | 6 | 7 | Source seven weekday cards/badges; native combined weekly list and additional controls |
| Exercise Library | 9 | 7 | 8 | Combined chips/search/add match; native narrower desktop content and replacement-image icons |
| Exercise Details | 8 | 6 | 7 | Instructions/history implemented; no dedicated fresh matched detail capture |
| Routine Builder | 9 | 7 | 8 | Paired compact exercise cards and body map; icons, progression controls and text differ |
| Active Workout | 9 | 7 | 8 | Rich target/last/set hierarchy verified; source blank restricted-media slots not equivalent to native images |
| Set Rows | 9 | 7 | 8 | Actual inline editing/completion works; input proportions and stepper controls differ |
| Rest Timer | 9 | 6 | 7 | Logic/control tests and timer fixture; no dedicated paired rendered review in this pass |
| Work Timer | 9 | 6 | 7 | Target/early stop/data tests; hardware countdown/OS behavior unverified |
| Workout Summary | 9 | 7 | 7 | Paired metrics/PR/body map/Nice; native dimming and stale active backdrop differ |
| History | 9 | 7 | 8 | Compact reverse list/details; numeric dates and added transfer actions |
| Statistics | 9 | 7 | 8 | Paired 396/1100 counters/heatmap/anatomy; narrower heatmap and segment styling |
| Exercise Progress | 8 | 6 | 7 | Real exercise record points; lower chart visual evidence weaker than upper Stats |
| Body Weight | 9 | 7 | 8 | Paired Home/check-in trend/goal and real import; slider/date/axis spacing differs |
| Activity Heatmap | 9 | 7 | 8 | Real duration intensity and drilldown; month label clipping at small width |
| Muscle Map | 9 | 7 | 8 | Front/back MIT contours reviewed at both widths; controls/body sizing differ |
| Date Override | 9 | 7 | 8 | Reviewed pair: native numeric header/combined choices/extra Move instead of source separated cards |
| Calendar | 9 | 7 | 8 | Reviewed pair: correct totals/markers; source tiled cells versus native plain dates |
| Custom Exercise | 9 | 7 | 8 | Reviewed desktop pair: same name/bodypart/notes; native taller dialog and More options |
| Check-in | 9 | 7 | 8 | Reviewed pair: three actions match; native slider, goal text, scrim and dimensions differ |

Paired deterministic fixtures render real screens with controlled data and fonts, not real accounts. The separate release browser journey uses actual local routes/MySQL. [Capture index](verification/parity/README.md) preserves 15 pairs at 396/1100; review in this pass covered Home, active, editor, configuration, summary, library, history, Plan, Stats, check-in, custom, calendar and date override. Assignment/picker pairs exist, but do not claim they were all manually re-reviewed this pass. Neither screenshot pairs nor responsive widgets establish Android accessibility/keyboard/OS permissions.

# J. Client Flow Status

| Step | Status | Evidence/limit |
| --- | --- | --- |
| Login | PASS | Actual local password login; live Google/Apple still unverified |
| Workout Home | PASS | Release browser entry and deterministic layouts |
| Plan | PASS | Real assigned-plan reception; HTTP schedule checks |
| Exercise | PASS | Search/picker/details widgets and actual exercise IDs |
| Active Workout | PASS | Actual release UI set logging; richer four-exercise program via HTTP |
| Set | PASS | Real MySQL writes, validation, idempotency and offline replay |
| Rest | PARTIAL | Logic/widgets pass; physical sound/action delivery unverified |
| Next exercise | PASS | Sequence/superset widgets and two complete HTTP Push Days |
| Finish | PASS | Real UI/API completion and preserved targets |
| History | PASS | Real browser data and two-session detail/count assertions |
| Stats | PASS | Real browser stats plus PR/calendar/volume regressions |
| Progress | PASS | Controlled progression/previous-data/exercise points; not every chart manually exercised |

Realistic program was Bench Press 3×10@60, Incline Dumbbell Press 3×10@25, Lateral Raise 3×12@8, Plank 3×45s. First bench actual was 60×10, 60×9, 57.5×10. Second session retains bench 60, advances incline to 27.5 and plank to 50 seconds. After second success a third start proposes bench 62.5, then cancels. Across the two completed sessions: 24 sets, 191 reps, 5,666 kg external-load volume and 4,800 seconds duration. This four-exercise flow uses real HTTP/MySQL, not manual timed phone execution. The release browser separately proves actual set editing/completion, offline replay, weight check-in, history/stats and data transfers; it logs a shorter routine. Provider verification/delivery is substituted explicitly.

# K. Coach Flow Status

| Step | Status | Evidence/limit |
| --- | --- | --- |
| Select Client | PASS | Existing authorized link, Coach UI/review tests and HTTP |
| Create Plan | PASS | Real four-exercise HTTP creation; builder widget coverage |
| Add Day | PASS | Real plan/day persistence and builder tests |
| Add Exercise | PASS | Actual exercise IDs plus search/picker widgets |
| Configure | PASS | Validated prescriptions/supersets/modes and builder widgets |
| Assign | PASS | Actual MySQL assignment and Client browser reception |
| Client performs | PASS | Two HTTP Push Days and separate release browser workout |
| Coach reviews | PASS | Real release Coach UI completed workout and HTTP details |
| Prescribed vs performed | PASS | Original bench target remains 60; actual varying sets visible separately |

These PASS entries describe verified capabilities, not a claim that one manual Coach UI session executed all steps end to end. Full Coach creation/configuration/assignment exclusively through the release UI, then Client on physical Android, remains a P1 acceptance test. Unauthorized Coach and other Client access are denied server-side; frontend role is not trusted.

# L. Test Commands

| Command/check | Initial result | Fix/retest result |
| --- | --- | --- |
| git status; git diff; git log --oneline -20 | Clean baseline captured | Current additive changes preserved; diff check clean |
| flutter pub get | Completed with available SDK/cache | Dependency resolution passed |
| flutter analyze --no-pub | Baseline no issues | Final full analysis no issues, 33.7s |
| flutter test --no-pub --concurrency=1 | Baseline 78 pass, one optional capture skipped; post-security parallel rerun stalled at 57 passes and was stopped, not counted as a pass | Final serial run 83 pass, one optional capture skipped, zero failure |
| Focused timezone tests | New helper initially failed before timezone DB initialization | Fixed initialization without changing notification local zone; all three pass |
| Focused wake-lock tests | Both failed initially; first failure also leaked teardown into second | Acquisition-owned cleanup and timer stop; both pass, full suite confirms |
| flutter build web --release --no-pub --no-wasm-dry-run --dart-define=API_BASE_URL=http://localhost:3201/api | Earlier release builds pass | Final build after all Dart fixes passes, 57.9s; JavaScript web, not Wasm validation |
| npm ci --offline (backend) | EPERM locked sharp DLL from our running API | Stopped owned helper, retry installed successfully |
| node --import ./tests/providerFixtures.js --test --test-concurrency=1 tests/*.test.js | Firebase modular upgrade initially broke 16 suite files; old media fixture then failed new policy | Corrected SDK migration and fixture; final 137 pass, zero skipped/fail, real local MySQL |
| Initial-password security regressions | Two child checks failed plus parent failure: existing password overwritten and invalid limits | Both checks pass with initial-setup restriction and atomic guard; Google-only setup still works |
| node --test tests/workout.stats.test.js | Five pass, two reproducible product failures | Eight pass after calendar/PR fixes and date-boundary case |
| Push Day HTTP/MySQL test | Two incorrect test expectations (DECIMAL string and rep sum), not product failures | Five checks pass; included in full 137 |
| Private chat media HTTP/MySQL test | New privacy regression coverage | Eight checks pass including valid WAV 206 and HTML rejection |
| npm audit --omit=dev --json | 17 production vulnerabilities: ten moderate, six high, one critical | Patched/removed dependencies; final full npm audit zero vulnerabilities |
| Reference npm ci --offline; npx vitest run | Cached install completed | 192 pass across seven test files |
| node scripts/verifyWorkoutJourney.mjs with provider preload/local CI schema | Real built UI/API/MySQL | Final 13 checks pass, zero API errors/JS exceptions; providers explicitly mocked |
| node scripts/auditWorkoutSchema.mjs | Existing PK/FK/orphan/index report | Final report includes new private-upload table and filter indexes |
| node scripts/auditWorkoutRepository.mjs | Current tree clear; historical credential archive found | Nonzero exit retained deliberately; rotation unresolved |
| Live Google certificate/invalid-signature probe | Earlier sandbox network prevented certificate fetch | Live certificates 200; known-kid invalid signature 401; valid OAuth account not tested |
| adb devices -l / emulator inspection | No attached debug device or installed emulator | Physical run remains unavailable |
| flutter build apk --debug | Prior pass has debug APK; current audit did not rebuild native APK | Latest native rebuild unverified due low disk/no-device environment; old APK targets legacy API and is not current local-workout proof |

Flutter was invoked through the installed SDK's dart executable/flutter_tools.snapshot on Windows; commands above name the corresponding Flutter operation. Backend package scripts define start/dev/test only; no backend lint or compile/build script exists, so none is invented. Changed JS syntax is checked with node --check. Fresh MySQL test bootstrap uses the checked-in schema and compatibility migrations in a disposable local schema; application data is not reset. CI now uses numeric-suffixed sirvya_ci_1 to satisfy the realistic-test safety guard. Remote Actions has not been run. Raw local logs are under ignored workout_tmp/audit-*; structured evidence and reviewed screenshots are tracked in docs/verification.

# M. Security

| Area | Result | Evidence/remaining risk |
| --- | --- | --- |
| Authentication | PASS | Existing JWT/current identity, bans/token-version checks and password login/reset tests; real external OAuth not proven |
| Authorization | PASS | Server role/link/ownership checks, not frontend role |
| Client isolation | PASS | Other Client cannot read/mutate plans/sessions/sets/statistics in integration cases |
| Coach isolation | PASS | Linked Coach succeeds; unrelated Coach denied; supplied clientID cannot grant ownership |
| Input validation | PASS | Malformed IDs, missing exercises, negative/absurd/nonfinite values, mixed effort, timed/bodyweight modes, duplicate-set idempotency tested |
| Secret exposure | FAIL | No current-tree secret values found, but historical backend.tar.gz retains credentials; rotate and coordinate history cleanup |

Private chat media now requires a short-lived capability derived with a separate key context; recipient identity/token version and conversation access are checked at read time. Media tokens cannot act as API tokens. Expired messages do not expose an attachment URL. Existing public profile/avatar assets stay public. Audio extension validation rejects executable HTML. Signed URLs deliberately expire after 15 minutes; refresh in long-lived views remains needed. No live device audio playback is claimed.

Dependency audit was live, not the earlier offline install's cached advisory result. Patched versions include proxy-addr; the [official critical advisory](https://github.com/advisories/GHSA-jqcg-44mw-7w3h) covers unsafe IPv4-mapped proxy trust handling. Existing numeric trust-hop configuration avoids that specific policy form, but the vulnerable package was patched anyway. Unused cloudinary/storage/google-auth dependencies were removed only after zero code/config/script references were found. Firebase v14 modular migration follows the [official release notes](https://firebase.google.com/support/release-notes/admin/node); Node >=22 is now required. No secret value is printed in this audit.

License/security release check: reference application is AGPL; [openGym NOTICE](https://raw.githubusercontent.com/arvids-unavailable/openGym/main/NOTICE.md) distinguishes application code, MIT anatomy and media rights. [Dataset LICENSE](https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main/LICENSE) covers code/metadata/instructions and explicitly excludes separate GymVisual media. Native replacement Everkinetic frames use CC BY-SA attribution documented in docs/THIRD_PARTY_WORKOUT.md; bundled Roboto has Apache 2.0 provenance. Media availability is therefore not declared complete. Review copied/translated behavior and any source-derived code for AGPL distribution/source obligations before proprietary release; this technical review is not a legal clearance and does not assert that a rewrite eliminates obligations. No working licensed functionality was deleted.

# N. Performance

- Fixed completion previous-record N+1 queries by loading prior sets for all involved exercise IDs in one query.
- Added equipment/type/archived and body-part/archived indexes; EXPLAIN evidence records chosen indexes. Substring LIKE %query% still cannot exploit a standard name B-tree directly. Do not claim indexed substring search.
- Search debounce, 50-row paging, filter reset, bounded scrolling, history paging and streamed Health input remain verified.
- Stats still reads all completed history and calculates multiple windows in memory; session-start previous/prefill remains partly per exercise. Aggregate/cache or batch only after preserving lifetime PR semantics.
- Several native widgets and router remain large: active about 1,800 lines, builder about 1,600, library about 1,180, progress about 1,080, workout router about 750. Split responsibilities around tested components/services instead of rewriting.
- One timer host/deadline model remains; successful workout completion now also cancels the elapsed ticker immediately.
- Existing host socket setup still has unfinished realtime transport/listener lifecycle. It is not counted as proven performance or messaging parity.
- No production throughput benchmark, slow-device frame profiling, thousand-session stats latency budget or media CDN benchmark was run. No measured claim is invented.

The verified full web preview is running at http://localhost:8082, using http://localhost:3201/api and existing fitlekdb. Web returns 200, /api/ready confirms MySQL and CORS permits this exact local origin. Scheduled outbound Workout reminders are disabled for local review. No Android ADB device is attached. Local generated browser/test caches and a hash-identical duplicate APK were removed to recover disk space; the main prior APK, sources and user data were retained.

# O. Files Changed During Audit

**Flutter**

- `lib/screens/ENG/login.dart`
- `lib/screens/ENG/workout/active_workout.dart`
- `lib/screens/ENG/workout/workout_home.dart`
- `lib/screens/ENG/workout/workout_progress.dart`
- `lib/screens/ENG/workout/workout_ui.dart`
- `lib/services/workout_service.dart`
- `lib/services/workout_dates.dart`

**Backend**

- `backend/config/appCompatibilitySchema.js`
- `backend/config/firebase.js`
- `backend/index.js`
- `backend/routes/anas/auth.js`
- `backend/routes/anas/messages.js`
- `backend/routes/anas/upload.js`
- `backend/routes/anas/workout.js`
- `backend/routes/pahae/coachChat.js`
- `backend/scripts/auditWorkoutSchema.mjs`
- `backend/scripts/verifyWorkoutJourney.mjs`
- `backend/services/pushNotificationService.js`
- `backend/services/workoutStats.js`
- `backend/services/chatMedia.js`

**Database**

- `backend/migrations/2026_workout_audit_indexes.sql`

**Tests**

- `backend/tests/app.integration.test.js`
- `backend/tests/google-auth.integration.test.js`
- `backend/tests/providerFixtures.js`
- `backend/tests/workout.stats.test.js`
- `backend/tests/chat-media.integration.test.js`
- `backend/tests/workout.push-day.integration.test.js`
- `test/workout_timezone_test.dart`
- `test/workout_wakelock_test.dart`

**Configuration**

- `backend/package-lock.json`
- `backend/package.json`

**Documentation**

- `github/workflows/release-checks.yml`
- `README.md`
- `docs/THIRD_PARTY_WORKOUT.md`
- `docs/WORKOUT_COMPLETION_2026-10-10.md`
- `docs/WORKOUT_END_TO_END_AUDIT_2026-10-10.md`
- `docs/WORKOUT_MASTER_PARITY_2026-10-10.md`

**Evidence**

- `docs/verification/journey/client-summary.png`
- `docs/verification/parity/README.md`
- `docs/verification/parity/opengym-active-1100.png`
- `docs/verification/parity/opengym-checkin-396.png`
- `docs/verification/parity/opengym-configuration-1100.png`
- `docs/verification/parity/opengym-configuration-396.png`
- `docs/verification/parity/opengym-custom-1100.png`
- `docs/verification/parity/opengym-day-assignment-1100.png`
- `docs/verification/parity/opengym-day-override-396.png`
- `docs/verification/workout-live-journey.json`
- `docs/verification/workout-repository-audit.json`
- `docs/verification/workout-schema-audit.json`
- `docs/verification/audit-2026-10-10/IMPLEMENTATION_MAP.md`
- `docs/verification/audit-2026-10-10/live-provider-probe.json`
- `docs/verification/audit-2026-10-10/parity.json`
- `docs/verification/audit-2026-10-10/results.json`
- `docs/verification/audit-2026-10-10/snapshot.json`

New report and matrix artifacts are included here even if generated after the initial changed-file snapshot. Local generated SDK/dependency/browser outputs remain ignored. Removed npm packages were unused; no native Workout functionality or source dataset was removed.

# P. Remaining Work

1. Rotate credentials present in historical backend.tar.gz, revoke old credentials, and agree a coordinated Git-history cleanup; keep secret values out of reports.
2. Deploy/check HTTPS and current production origins/secrets; configure the mobile API endpoint explicitly instead of the legacy HTTP default.
3. Attach an authorized Android debug device and execute both complete Push Days through the native UI, including app background, force-stop/restart, offline replay, timed early stop, rest actions and screen awake.
4. Run Coach create/day/exercise/configure/assign entirely in the release UI; Client performs on-device; Coach compares actual versus prescribed.
5. Verify real Google/Apple sign-in, reset email and workout/rest/assignment push/local notifications with actual provider/device permissions.
6. Obtain compatible full-catalog demonstration licensing or expand attributed original/replacement media coverage.
7. Match weekly-card layout, configuration option rows, active selected tab, summary backdrop, calendar tiles and chart proportions; capture exercise detail/rest/work/lower charts directly.
8. Implement previewed raw openGym training-backup migration and scoped bulk training reset.
9. Add remaining Workout UI translations and profile timezone onboarding/detection while preserving manual timezone choice.
10. Refresh expiring chat media links, complete authenticated realtime messaging transport/listener cleanup, and regression-test existing conversation UI/audio playback.
11. Batch session-start previous/prefill queries, bound or aggregate stats safely, and benchmark long training history with real query/frame measurements.
12. Extract active/builder/progress/router responsibilities and move runtime schema DDL to versioned migrations after behavior/contract tests stay green.

# Q. Recommended Next Development Order

1. Credential rotation and HTTPS/current-release configuration (P0).
2. Real-device recovery/timers and two-session Client plus Coach UI acceptance (P1).
3. Actual OAuth/email/FCM/local-notification delivery, then close any device-discovered defects (P1).
4. Licensed instructional media expansion (P1; rights-dependent).
5. Primary screen/sheet/chart parity fixes and explicit Coach progression explanations (P2).
6. Source full-training backup adapter and scoped reset (P2).
7. Locale coverage/timezone onboarding and private-media renewal/realtime completion (P2).
8. Measured history/startup performance improvements, then incremental component/migration refactoring (P2).
9. Icon/date/text polish and optional extra tools (P3).

# R. Final Score

```text
Architecture: 8.5/10
Backend: 8/10
Database: 8/10
Flutter quality: 8/10
Workout functionality: 8/10
openGym feature parity: 7.5/10
UI parity: 6.5/10
UX parity: 7/10
Coach integration: 8/10
Security: 5.5/10
Testing: 8/10

OVERALL: 7.5/10
```

These are evidence-based engineering judgments, not averages of identical-value feature rows or coverage percentages. The biggest blockers to 10/10 are historical secret exposure, unavailable physical/provider proof, limited licensed demonstration coverage, two explicit portability/reset gaps, visibly different controls/layouts and remaining large/unbounded code paths. Passing hundreds of checks does not eliminate these limitations.

# S. Final Verdict

**FUNCTIONALLY READY — NEEDS PARITY WORK**

The tested native Workout lifecycle is coherent and persisted through the existing SIRVYA stack. This audit made important direct fixes and retested them. It is more than an exercise dataset, but it is not full openGym visual/interaction equivalence and is not production-ready until credential/provider/device release requirements are closed. Current audit changes remain local and reviewable; no Git reset, automatic publication or new push occurred.
