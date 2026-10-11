# Workout third-party resources

Exercise metadata and English/French/Spanish instructions from https://github.com/hasaneyldrm/exercises-dataset, revision 7455efae41b330c265e7cd4b78dfa848e7ce5ebd. 1324 records imported directly from upstream under MIT. Full license: [exercises-dataset-LICENSE.txt](licenses/exercises-dataset-LICENSE.txt). Stable identity is source + upstream ID. No media from that dataset is imported.

Media exception rechecked against the current upstream
[LICENSE](https://github.com/hasaneyldrm/exercises-dataset/blob/main/LICENSE)
and [NOTICE](https://github.com/hasaneyldrm/exercises-dataset/blob/main/NOTICE.md)
on 2026-10-05: MIT covers metadata, code and instruction translations;
the exercise thumbnails/GIFs belong to Gym visual and require a separate
license. The repository maintainer's permission does not grant downstream
redistribution rights. The app now uses hosted AscendAPI demonstrations instead
of copying the upstream GIFs. The existing MIT metadata import and reviewed
Everkinetic assets remain intact. Commercial hosted use requires a subscribed
AscendAPI plan; the no-key endpoint is enabled for development previews only.

AscendAPI ExerciseDB V1 is accessed at runtime through the authenticated
backend. All 1,324 imported source IDs have mappings to the provider's stable
OSS IDs, taken from the pinned MIT metadata's `media_id` fields. All mapped IDs
were found in the live OSS catalog on 2026-10-11. Twenty reviewed starter aliases
reuse matching identities. The provider's media remains hosted on its CDN,
unmodified, with AscendAPI attribution in the demonstration controls. API keys
remain server-side. Responses/rotating media URLs are not persistently cached.
The paid schema uses different IDs and is resolved separately by exact movement
and equipment. See [configuration and limitations](WORKOUT_MEDIA_IMPORT.md)
and the provider's [documentation](https://docs.ascendapi.com/products/edb-v1/overview),
[caching policy](https://docs.ascendapi.com/guides/caching), and
[OSS usage restrictions](https://oss.exercisedb.dev/docs).

openGym is the product/visual reference; its AGPL application code, translated strings, branding and fonts are not included. Native UI and behavior are independently implemented. The separately MIT-licensed MuscleMap coordinates used by that reference are now bundled with their own notice, as described below.

The October 10 [end-to-end audit](WORKOUT_END_TO_END_AUDIT_2026-10-10.md) uses the requested c42ba6b source and rendered UI to compare behavior. This notice records intended asset/code provenance; it is not an independent legal clearance of every implementation or translation. Before proprietary distribution, review any copied or source-derived material against openGym's AGPL/source-distribution obligations. The separately licensed metadata, anatomy and reviewed media retain their notices and attribution.

Muscle-map coordinate data by Melih Colpan is bundled in
`assets/workout/anatomy/musclemap.json`, under MIT. The full notice is in
`assets/workout/anatomy/LICENSE.txt`; provenance and the generated asset SHA-256
are recorded in `provenance.json` in the same directory. The inspected source is
the geometry-only export in the requested openGym commit
`c42ba6b98e3776af5981f20c05ba392238799670`, whose `NOTICE.md` explicitly retains
the geometry's MIT license. Upstream author/project:
[MuscleMap](https://github.com/melihcolpan/MuscleMap),
[upstream MIT license](https://github.com/melihcolpan/MuscleMap/blob/main/LICENSE).
No upstream renderer or application code is included. Four coordinate views
(male/female, front/back) are rendered, shaded and hit-tested with native Flutter
code. The license is also registered in Flutter's license registry. Regenerate
only this asset with `node backend/scripts/syncWorkoutAnatomy.mjs`; this command
does not import or change exercise records or media.

38 unmodified Everkinetic PNG illustrations were obtained from the individual
image entries in the [wger API](https://wger.de/api/v2/exerciseimage/) on
2026-10-03. Each entry explicitly identifies Everkinetic and CC BY-SA 3.0.
Full license: [CC-BY-SA-3.0.txt](licenses/CC-BY-SA-3.0.txt).
The illustrations retain that license; no additional restrictions are imposed.
The complete per-image source URL, author history, title, license URL and SHA-256
are preserved in [catalog.json](../assets/workout/demonstrations/catalog.json).
Exercise details display author/license credits with links to the original
image and license; the license is also registered with Flutter's license registry.
19 demonstrations map to 24 reviewed, stable SIRVYA/dataset exercise identities.
Names are never used for runtime matching. No wger application code is included.

To restore the pinned images, run `node scripts/syncWorkoutDemonstrations.mjs`
from backend. The command checks author/license metadata and preserves audited
byte hashes; changed sources require review. The application makes no wger API
calls at runtime. Other catalog exercises retain their instructions and optional
private demonstration uploads; there is no invented illustration for an
unmatched exercise.

Real exercise videos were added on 2026-10-10 from the public
[wger video API](https://wger.de/api/v2/video/). The reviewed entries identify
Goulart as the author and **CC BY-SA 4.0** as their license. The video files and
derived posters retain that license, including SIRVYA's technical modifications.
Full license: [CC-BY-SA-4.0.txt](licenses/CC-BY-SA-4.0.txt). No additional
restrictions are imposed on these media assets.

The 28 clips map to 33 reviewed stable exercise identities, including 28 of the
1324 imported exercise records and five existing SIRVYA exercises. The original
illustrations remain available; together both collections cover 40 identities
(34 imported records and six SIRVYA exercises). This is limited demonstration
coverage, not a full exercise video/GIF catalog.

On October 11, unfinished pull-up and hip-adduction downloads were completed.
The additional source 70 was excluded: its source and converted hashes exactly
duplicate ordinary pull-up 71, despite being labeled as an assisted machine
variation upstream. No assisted pull-up mapping is claimed for those bytes.

The complete source URL, wger ID/UUID, author history, original source size and
SHA-256, output/poster hashes, license and modification notice are preserved in
[the video catalog](../assets/workout/videos/catalog.json). Videos were converted
to silent H.264 MP4 at 24 fps and at most 640 pixels per dimension, retaining
movement speed; JPEG posters were extracted. In-app credits link the original
video and license, describe these changes, and register the license with Flutter.

To restore the pinned videos, install FFmpeg/ffprobe and run
`node scripts/syncWorkoutVideos.mjs` from `backend/`. Optional `FFMPEG_PATH` and
`FFPROBE_PATH` variables select their executables. Downloads use verified public
byte ranges and resumable scratch files. The command checks the source author,
license and exact exercise identity; changed source metadata or audited asset
hashes require review. It does not import exercises or change database records.
Videos and posters are bundled with Flutter; playback makes no wger requests.
The backend ships only the reviewed identity map needed for the video filter.
No wger application code is included.

Roboto Regular/Bold are bundled for Workout typography and offline native PDF
export, from the Flutter SDK's material_fonts distribution. They are licensed
under Apache-2.0; full notice: [Roboto-LICENSE.txt](licenses/Roboto-LICENSE.txt).
No openGym font assets are used. Native screenshots use these same bundled fonts.

Runtime packages added for this module: timezone 0.11.1 (BSD-2-Clause),
wakelock_plus 1.5.2 (BSD-3-Clause), pdf 3.13.1 and printing 5.15.1 (Apache-2.0).
Package licenses remain in their upstream distributions and Flutter license registry.
Existing SIRVYA file_picker, video_player and flutter_local_notifications are reused.
Sources: https://pub.dev/packages/timezone, https://pub.dev/packages/wakelock_plus,
https://pub.dev/packages/pdf and https://pub.dev/packages/printing.
