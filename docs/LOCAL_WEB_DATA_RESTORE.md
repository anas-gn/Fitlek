# Local web data restoration

The web preview at http://localhost:8080 was connected to the local SIRVYA API
at http://localhost:3000/api. Its existing MySQL database contained two Clients
and no Coach profiles, so the successful Coach-list response was empty.

The existing ignored `workout_tmp/local-backups/sirvya_backup.sql` was merged
into that same database. No schema or Workout records were replaced. Existing
accounts were matched by email and their stored credentials/roles were preserved.
Conflicting legacy IDs were remapped, including Coach/Client relationships,
reservations and conversations. The dump is UTF-16; its data is parsed as literals
and inserted with parameterized queries. Dump SQL, DROP statements and database
creation are never executed.

Legacy `authProvider=email` becomes `local`; MAD price strings become decimal
amounts; missing conversation activity dates use the latest saved message or
conversation creation date. Foreign-key validation stays enabled and all inserts
use a transaction. Failed attempts rolled back before the successful merge.

The merge inserted 43 users, reused one existing account, and inserted nine Coach
profiles, seven Advisor profiles, four Coach/Client relationships and the related
legacy application records. Approval states were preserved: seven Coaches are
approved and returned by the existing listing API. Historical login/OTP/reset
tokens, notifications, deleted-account records and application configuration were
excluded. Restored users have no old device push tokens.

The original backup and ID-only restore manifest remain ignored local files.
They are not bundled into the web application or committed. Repeating the merge
checks that manifest and returns `already-restored`, without duplicating records.
Missing previously restored rows cause a failure requiring inspection.

Commands, run from `backend/`:

```powershell
node scripts/restoreLocalAppData.mjs          # read-only preview
node scripts/restoreLocalAppData.mjs --apply  # local merge / idempotency check
$env:WORKOUT_TEST_MYSQL='1'
$env:APP_TEST_MYSQL='1'
$env:AUTH_TEST_MYSQL='1'
npm test
```

Verification after restoration:

- Authenticated `GET /api/coaches?limit=20`: HTTP 200, seven Coaches; prices parse.
- Authenticated `GET /api/advisors`: HTTP 200, seven Advisors.
- Authenticated `GET /api/categories`: HTTP 200, ten categories.
- Repeat restore: `already-restored`, no additional writes.
- Full backend suite: 72 passed, zero failed, zero skipped.
- Dedicated merge test: existing account preservation, remapped ownership,
  legacy data conversion, cleared push tokens and invalid-relationship rollback.
- Web preview: HTTP 200. No Flutter rebuild is required for this database change.

Refresh the web preview to load the restored data. The prior architecture audit's
historical-credential and production HTTPS findings remain unresolved.
