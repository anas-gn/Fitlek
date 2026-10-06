# SIRVYA end-to-end release audit — 2026-10-06

The current native Workout implementation is committed. Automated functional checks pass, but this snapshot has confirmed security defects and is not ready for a production release. This review covers the Flutter client, Express API, local MySQL, authentication, authorization, coaching, reservations, messaging, Workout, transfers, media, configuration and release setup. Production infrastructure and live external providers were not changed or certified.

## Fresh verification

| Check | Result | Evidence |
| --- | --- | --- |
| Backend suite with `WORKOUT_TEST_MYSQL=1`, `APP_TEST_MYSQL=1`, `AUTH_TEST_MYSQL=1` | 97 passed, 0 failed, 0 skipped | `workout_tmp/master-audit-backend.log` |
| All Flutter tests, `--no-pub --concurrency=1` | 69 passed, 0 failed, 1 optional legacy capture skipped | `workout_tmp/master-audit-flutter.log` |
| Full `flutter analyze --no-pub` | No issues found | `workout_tmp/master-audit-analysis.log` |
| Release web build with local API override | Passed | `workout_tmp/master-audit-web-build.log` |
| Built-app headless browser smoke | Passed: Workout entry, Plan/Stats/Exercises and return to SIRVYA; synthetic API fixtures | [browser evidence](verification/release-browser-smoke.json) |
| Local MySQL schema audit | 14 tables with primary keys, 26 foreign keys, no relational orphans | [schema evidence](verification/workout-schema-audit.json) |
| Isolated HTTP security probes with synthetic local accounts | Five unsafe behaviors reproduced; all fixture accounts removed | [security evidence](verification/release-security-probe.json) |
| Repository credential scan | No matching literals found in the scanned current files; known credential archive still reachable in history | [repository evidence](verification/workout-repository-audit.json) |

The backend integration tests exercise real local MySQL and HTTP routes. Identity verification and push delivery are simulated inside their test servers. Flutter tests use fixtures. Passing these checks does not establish live Google/Apple sign-in, email delivery, real-time chat, production TLS, native notifications or store readiness. Android and iOS release builds were not rerun in this audit.

## What works in the covered flows

- Client, Coach and selected Manager API reads; account registration/login and Google account compatibility in local integration tests.
- Profile edits, coach invitations, reservation/calendar/conflict handling, messaging persistence, unread counters and notification persistence in covered integration flows.
- Workout library/filtering/custom exercises, reusable routines, recurring week plans, date overrides, starter plans, coach assignment and review.
- Starting/resuming sessions, set logging, warmups/supersets/timed work, fractional effort, progression, completion/history/stats, bodyweight and muscle views.
- Account-scoped drafts/outbox/read caches, retained pickers, import/export, private Workout media and navigation back into SIRVYA in the covered tests.

Coverage is uneven: the positive app integration checks did not detect the legacy password-reset and cross-account authorization defects below.

## Work remaining, in order

### 1. Close password-reset account takeover paths — critical

Evidence: [auth routes](../backend/routes/anas/auth.js), particularly `/forgot-password`, `/verify-forgot-otp`, `/reset-password-otp` and `/reset-password`; [reproduced results](verification/release-security-probe.json).

The unauthenticated legacy forgot-password route returns `_devToken` to its caller. The OTP reset endpoint accepts only an email and a new password when a recently verified OTP row exists. It ignores the supplied `otp`, does not require caller-bound proof and leaves the verified row reusable. Both behaviors were reproduced against synthetic accounts.

Required work: remove token disclosure; retire the unused legacy routes or complete a safe email reset flow. Require an unpredictable, short-lived reset capability issued after successful OTP verification. Consume that capability atomically with the password update, enforce expiry and password policy, and revoke refresh sessions. Apply bounded OTP/reset request and verification attempts.

Acceptance: missing, wrong, expired, replayed and another account's proof all fail; concurrent reset submissions allow only one success; no reset proof appears in API responses before verification or in logs. Verify actual email delivery separately with an owned test inbox.

### 2. Enforce role and account ownership across the legacy API — critical

Evidence: [coach/client links](../backend/routes/anas/coachClients.js), [bans](../backend/routes/anas/bans.js), [client profiles](../backend/routes/anas/client.js), [advisor profiles](../backend/routes/anas/advisorProfiles.js), [uploads](../backend/routes/anas/upload.js), and the mounts in [backend startup](../backend/index.js).

Global JWT authentication does not authorize a caller to mutate someone else's records. An unrelated Client successfully created a Coach/Client link and a ban while supplying another actor ID in the local probe. This is especially serious because Workout access trusts Coach/Client relationships. Static review also found profile writes driven by caller-supplied `userID`, gallery writes driven by `coachID`, and avatar filenames driven by a query ID without ownership checks.

Required work: derive acting identity from `req.user`; add explicit roles, ownership and intended link/consent rules; limit bans to authorized staff and derive `bannedBy`/`liftedBy` on the server. Review every protected route, including reads of personal data, rather than assuming a valid JWT is sufficient. Apply the same rules to avatar/gallery writes.

Acceptance: a role-by-operation test matrix covers Client, linked/unlinked Coach, Advisor, Manager and Admin. Cross-account read/write attempts fail. A forged link cannot grant Workout history access. Existing valid invitation, booking and coaching flows still work.

### 3. Rotate credentials previously committed to Git — high

The repository audit still detects a historical `backend.tar.gz` containing Firebase private-key/backend environment material. Deleting the file from the current tree did not remove that history. The scan is a targeted detector, not a complete credential inventory.

Required work: have credential owners rotate/revoke the exposed service-account and environment credentials, inventory other historical secret/data artifacts, then coordinate history cleanup across affected branches/tags/clones. Preserve a recovery plan and document which credentials were replaced. This audit did not rotate credentials or rewrite remote history.

Acceptance: revoked credentials no longer authenticate, the app uses replacements, and sensitive blobs are absent from the agreed published refs.

### 4. Establish production HTTPS and operational configuration — high

Evidence: [API default](../lib/constants/urls.dart) uses `http://51.170.143.251/api`; [reverse proxy](../sirvya.conf) shows port 80 only. This audit did not probe or certify the deployed endpoint. [Backend startup](../backend/index.js) allows all CORS origins even though `.env.example` documents `CORS_ORIGINS`.

Required work: configure a certificate-backed HTTPS hostname and use `API_BASE_URL` for release builds; apply the intended web-origin policy; validate required environment variables at startup; bound authentication/upload/request traffic and avoid exposing database/internal error strings. Configure proxy handling deliberately so generated media URLs use the correct public HTTPS origin.

Confirm the hosting connection limit against [the pool](../backend/config/db.js): it currently permits 10 connections while the startup comment describes a five-connection hosting constraint. Separate service liveness from database/schema readiness; several legacy schema errors are logged while startup continues. Rehearse migration and persistent-media backup/restore on staging.

Acceptance: clients authenticate and load media over HTTPS; missing configuration fails predictably; readiness rejects traffic during failed migrations; backup restore succeeds; logs/alerts surface database and delivery failures.

### 5. Complete real-time chat and protect chat attachments — high

Evidence: [socket server](../backend/config/socket.js), [Flutter socket client](../lib/services/socketService.dart), [message route](../backend/routes/anas/messages.js), [coach chat route](../backend/routes/pahae/coachChat.js), [backend startup](../backend/index.js).

The Flutter client connects and listens for `new_message`, but startup does not call `initSocket`, the backend manifest does not declare `socket.io`, and the inspected message routes do not broadcast socket events. The existing socket implementation allows room joins without JWT verification or conversation membership checks. Database messaging and push persistence passing tests do not prove live socket delivery.

Required work: wire a declared socket dependency into the actual HTTP server; authenticate the handshake, authorize every conversation room, emit messages after persistence, and handle reconnect/rejoin and duplicate delivery. Chat image/audio uploads currently live under public `/uploads/chat_media`; use authorized attachment access or scoped expiring URLs and server-side file validation. Keep ordinary public avatars separate where intended.

Acceptance: two authorized accounts exchange text/image/audio immediately, reconnect correctly and get accurate read/unread state; unrelated accounts cannot join rooms or fetch attachments; failures do not lose persisted messages.

### 6. Run native Android/iOS and external-provider checks — high

Exercise real Google/Apple sign-in, account completion, OTP email delivery, notification permissions, FCM/APNs, timed/background rest alerts, notification actions, sound/vibration, wake lock, app suspension/process termination, offline recovery, private uploads, camera/QR, voice recording, video codecs and PDF/file sharing on hardware.

Static iOS review found no `NSMicrophoneUsageDescription` in [Info.plist](../ios/Runner/Info.plist), although both chat screens use `AudioRecorder`. The checked-in [entitlements](../ios/Runner/Runner.entitlements) show Apple sign-in but no push entitlement; verify the complete APNs capability/provisioning/background setup on macOS. These are native configuration gaps to resolve and validate, not successful device checks.

[Android release configuration](../android/app/build.gradle.kts) falls back to debug signing when `key.properties` is absent. Make release signing fail explicitly when production credentials are missing; verify the intended upload key, package ID, version and store artifacts. Run an iOS release archive/TestFlight check on macOS.

Acceptance: signed builds install and pass a documented Client/Coach journey on Android and iOS, including background alerts, voice recording and recovery after termination. Record provider delivery evidence and permission-denied behavior.

### 7. Finish Workout presentation and interaction verification — medium

Use [the current recovery matrix](WORKOUT_RECOVERY_CURRENT.md), which supersedes the earlier parity conclusions. Its recorded 2026-10-05 assessment is 39 acceptable rows, 27 partial rows, one media-license blocker and four exclusions out of 71 rows. These are historical product-review results, not a fresh parity percentage from this audit.

Remaining items include Home/week/weight-chart spacing, routine-editor density, guided-workout/detail/lower-statistics presentation, full picker page boundaries and external training-file UX. Recheck matched phone/desktop layouts, enlarged text, reduced motion and the supported languages after each focused change.

Acceptance: each outstanding row has an explicit product decision, interaction evidence and updated paired captures. Avoid declaring full parity solely because tests pass.

### 8. Expand exercise demonstrations and transfer coverage — medium

Current reviewed bundled demonstrations cover 24 exercise identities, with full catalog animation coverage still blocked in [the media review](THIRD_PARTY_WORKOUT.md). Obtain independently reviewed media/rights and maintain stable IDs, hashes and attribution; do not assume the metadata license permits distributing the source GIFs.

Confirm the desired scope for a versioned Workout backup covering preferences, plans and history, and a bounded import path for large Apple Health exports. Current documented Health input is limited to 8 MiB. Verify actual file selection, export, import preview, rollback, round-trip fidelity and unsupported/version-mismatch errors on supported platforms.

Acceptance: every shipped demonstration has recorded provenance and correct identity; transfer limitations are visible; supported backups round-trip and invalid imports leave existing data intact.

### 9. Resolve the product/role scope and stale documentation — medium

The current Premium status and access middleware intentionally grant access for free; no live checkout/webhook route exists in startup despite Stripe instructions in README. Decide whether the release is free or paid, then align UI/API/docs. Payment work is conditional on a paid product decision.

README describes `mobile/`, a separate Next.js advisor portal and admin routes that do not match this tree. `web/` is the Flutter web runner. [Session routing](../lib/sessionRouter.dart) handles Client and Coach; other roles fall back to Welcome. The placeholder `MainLayout` class is not referenced by the active router. Decide which Advisor/Manager/Admin workflows must ship in this app or in a separate portal, then implement and verify that agreed scope.

Acceptance: setup commands work from a clean checkout; roles/features advertised to users exist and have navigable tested flows; free/paid behavior is deliberate and documented.

### 10. Add repeatable release checks and scale validation — medium

There is no checked-in `.github` workflow, and `backend/package-lock.json` is ignored. After the security fixes, establish a reproducible backend dependency lock and CI for backend/MySQL integration, Flutter analysis/tests and release builds. Add the missing security regressions and provider/device checks to the release procedure.

Profile stats and history queries with large real-shaped synthetic histories; bound pagination/import/media work and verify database/storage limits. Fix or re-encode the existing intro video if browser/device codec checks reproduce its unsupported-format warning. Maintain the supported Android JDK/Gradle toolchain.

Acceptance: clean checkout checks are reproducible, failures block release, large histories remain responsive, and a staging smoke/backup/rollback procedure passes before deployment.

## Git publication

The requested existing remote branch is `Master` (capital M); no lowercase `master` existed. Current changes were saved in a feature commit, then joined with the existing `Master` history using an explicit merge that retains the current native implementation. The older standalone Workout tree is retained in history rather than restored into the working tree. The local chat upload remains on disk and is excluded by `.gitignore`. No force push or published-history rewrite was used.

The fresh built-app browser smoke passed with synthetic API fixtures and no JavaScript exceptions. It does not establish live authentication or provider delivery. The initial GitHub push returned HTTP 408; retrying with HTTP/1.1 and a larger local POST buffer reached GitHub's email-privacy check. The commits created during this audit were updated to use the authenticated account's GitHub noreply address, preserving their code and messages. Publication requires a successful push and comparison of the remote branch tip with local HEAD.
