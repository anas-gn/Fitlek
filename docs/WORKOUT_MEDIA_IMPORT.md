# Exercise media catalog

The app renders exercise-specific `imageUrl` and `videoUrl` values in the
library, exercise detail and active workout. `gifUrl` / `gif_url` are accepted
as animation aliases. Supported inline animations are GIF, MP4, MOV and WebM.
HTTP(S) locations, backend paths starting with `/`, and bundled
`assets/workout/` paths are supported. Other video links remain external links.
GIF thumbnails use the first frame; GIF demonstrations support pause, background
and hidden-route suspension, and reduced-motion preferences.

The reviewed open-media bundle contains **28 real clips**, mapped to **33
exercise identities**, plus the existing 19 illustrated demonstrations. Three
unfinished downloads were completed on 2026-10-11. Source 70, labeled assisted
pull-ups, was then excluded: its source and converted hashes exactly duplicate
ordinary pull-up 71, so it cannot establish a separate assisted demonstration.
Pull-ups and hip adduction remain included. The complete 1,324-exercise animation pack is **not present**.
Hosted demonstrations are now integrated for all 1,324 imported identities; an
offline full-catalog pack is still optional. The reviewed local bundle remains
available when a matching bundled demonstration exists.
Missing media is labeled `No demo yet`; generic exercise icons are no longer
presented as demonstration thumbnails.

## Hosted AscendAPI integration

AscendAPI's [ExerciseDB V1](https://docs.ascendapi.com/products/edb-v1/overview)
is integrated through `GET /api/workout/exercises/:id/demonstration`. Requests
use the existing authenticated exercise visibility rules. The library's video
filter includes hosted identities when the provider is enabled. The same GIFs
render as first-frame thumbnails and controlled animations in exercise details
and active workouts, with AscendAPI attribution and reload controls.
The web renderer embeds the CDN image directly because the OSS GIF CDN does
not send CORS headers. A display-only canvas holds the first frame for
thumbnails, reduced motion and pause; replay restarts the GIF. Native apps
decode frames locally and pause on the current frame. Neither path rehosts media.

All 1,324 imported IDs were found in the live 1,500-exercise OSS catalog on
2026-10-11. The stable opaque IDs come from the already licensed MIT metadata
revision, not from downloaded GIFs or cached API responses. Twenty starter
exercise aliases also map to the matching movements; unmatched static holds
retain their existing illustrations or honest missing-media state. Provider
renames such as `air bike` → `Bicycle Crunch` do not break verified OSS IDs.
Paid lookup uses its own IDs and validates exact name and equipment.

Development defaults to the **noncommercial, 180p OSS preview** if no paid key
is configured. Production defaults to bundled media only without a paid key;
explicit free mode is also disabled in production. For commercial use, subscribe
to the provider's paid V1 plan and configure only the backend:

```dotenv
WORKOUT_MEDIA_PROVIDER=ascend
ASCENDAPI_KEY=your-paid-rapidapi-key
```

Restart the backend after changing configuration. `RAPIDAPI_KEY` is also
accepted. Use `WORKOUT_MEDIA_PROVIDER=off` to disable hosted lookup. No provider
key is shipped to Flutter, browser assets, or API responses. The paid tier could
not be exercised live without a subscribed key; its schema is covered by mocked
contract tests, and matching failures return no demonstration.

Per the provider's [caching policy](https://docs.ascendapi.com/guides/caching),
the integration resolves URLs fresh and does not persist API responses, store
them in SharedPreferences, download a GIF pack, or proxy/rehost CDN files.
Simultaneous lookups coalesce while in flight; each displayed exercise retains
its lookup across parent rebuilds. Provider requests are paced with a bounded
queue. Network failures and throttling produce a retryable response; bundled
media remains available. The free preview is unsuitable for commercial traffic.

Thumbnail loading waits until the row is visible and has settled for 180 ms.
The media-type label reads existing metadata instead of making another hosted
lookup. Thumbnail requests use `?priority=preview`; opening a demonstration uses
foreground priority and promotes any matching pending lookup ahead of other
queued previews. The provider's OSS endpoint rejected faster request bursts in
live testing, so its 1,100 ms spacing remains in place. Provider `Retry-After`
responses stop queued requests, with bounded concurrency and a maximum backlog
of 32. Resolved URLs are still never cached or persisted.

The loading changes pass 13 provider contract tests, 34 HTTP/MySQL checks,
12 Flutter media tests and scoped Dart analysis. The full release web app was
rebuilt and its local API restarted. An isolated browser with a temporary local
test account verified real thumbnails and the Air Bike demonstration in the
rebuilt app: the first hosted thumbnail appeared in 1,324 ms and the opened
demonstration in 1,537 ms during that run. Accessibility mode retained a still
frame. The test account and browser profile were removed afterward. See
[loading-2026-10-11.json](verification/media/loading-2026-10-11.json).

Regenerate only the MIT identity map with:

```powershell
node backend/scripts/syncHostedWorkoutIdentities.mjs
```

This command verifies every name, equipment value, and exact string ID against
the existing catalog. It does not change exercise records or import media.

The optional live CDN browser check runs separately from offline tests:

```powershell
flutter test --platform chrome --dart-define=WORKOUT_GIF_URL=https://static.exercisedb.dev/media/EIeI8Vf.gif test/workout_gif_web_test.dart
```

Verification is recorded in
[hosted-catalog-2026-10-11.json](verification/media/hosted-catalog-2026-10-11.json).
The installed Windows SDK's browser runner could not complete reliably; the
actual GIF widget was instead built as a release page and checked in headless
Chromium. Real CDN thumbnails, playback, pause and reduced motion all passed.
The full app's release web build, 19 native Flutter tests, 34 HTTP/MySQL checks
and 15 media contract/import checks also passed. The paid endpoint still needs
a subscribed key before live commercial coverage can be verified.

## Import a locally supplied pack

For an extracted purchased ExerciseDB pack containing numeric GIF filenames
and its EULA/LICENSE text, no hand-written manifest is needed:

```powershell
node backend/scripts/importExerciseDbPack.mjs C:\media-pack --check-only
node backend/scripts/importExerciseDbPack.mjs C:\media-pack
```

The first command reports exactly which of this app's IDs have matching files.
The second requires all 1,324 IDs before changing any app assets, then imports
the pack. It defaults to 360px GIFs; use `--resolution 180` for 180px files.
Multiple candidate clips or changed names in the provider's `exercises.json`
fail for review. Source files remain untouched. The command does not purchase
or download a pack and does not treat a downloaded sample as a complete catalog.

The provider's [Starter package](https://exercisedb.io/pricing) currently lists
1,394 exercises with GIFs and a commercial app license for a one-time $199.
Coverage of this app's exact IDs still must pass the local file check.
The [free Flow preview](https://github.com/ozansozuozgit/flow-exercise-dataset)
lists only 1,257 animations and explicitly documents missing media and artwork
quality limitations; it is not a complete replacement catalog.

For other providers or layouts, use an explicit manifest as follows.

Install FFmpeg/ffprobe. Put the licensed files, license text and a manifest in
one folder. Use exact existing exercise IDs as strings, retaining leading zeros.
Names are never used to attach a clip to an exercise. For example:

```json
{
  "author": "Your media provider",
  "license": "Your provider's license name",
  "licenseUrl": "https://your-provider.example/license",
  "sourceUrl": "https://your-provider.example/exercise-library",
  "licenseFile": "LICENSE.txt",
  "videos": [
    {"externalId": "0025", "media": "videos/0025.gif"},
    {"externalId": "0031", "media": "videos/0031.mp4"}
  ]
}
```

`externalSource` defaults to `exercises-dataset`. To explicitly map one clip to
multiple identities, replace `externalId` with
`"targets": [["exercises-dataset", "0025"], ["sirvya", "bench-press"]]`.
The manifest's author and license apply to every clip in that pack.

From the repository root:

```powershell
node backend/scripts/importWorkoutMedia.mjs C:\media-pack\manifest.json --require-full
```

`--require-full` rejects a catalog unless all 1,324 imported exercise identities
have playable media, counting existing reviewed clips. Validation runs before
conversion. Unknown IDs, numeric IDs, duplicate mappings, missing files and
paths outside the pack folder are rejected. Omit `--require-full` to explicitly
import a partial pack; the output reports the actual coverage and missing IDs.

GIFs and videos become silent H.264 MP4 files and real JPEG thumbnails. Source
and output hashes, provider credits, license text and modification notices are
preserved. Output goes to `assets/workout/exercise_media/`; the matching backend
identity map is written to `backend/data/workoutMediaSources.json`. The database
and existing wger catalogs are unchanged. Subsequent packs preserve earlier
unrelated mappings. These imported files need to be committed/shipped together.

Rebuild Flutter and restart the backend after import. The video filter includes
both bundled catalog entries and directly supplied playable URLs; all existing
account visibility and exercise-search rules still apply.

The original GymVisual files require their separate media license as documented
in [the upstream notice](https://github.com/hasaneyldrm/exercises-dataset/blob/main/NOTICE.md).
No full GymVisual pack is downloaded by the importer.

## Verification on 2026-10-11

- 17 Flutter checks passed for media controls, GIF pause/reduced motion,
  supplied thumbnails, exercise library and existing demonstration preferences.
- 39 backend checks passed: six asset/import checks plus 33 local MySQL/HTTP
  checks, including GIF filtering and private-exercise visibility.
- Analysis of changed Flutter files and tests reported no issues.
- Release web build succeeded with the existing local API override
  `http://localhost:3201/api`; the generated bundle includes the additional
  media manifest and completed pull-up/hip-adduction videos.
