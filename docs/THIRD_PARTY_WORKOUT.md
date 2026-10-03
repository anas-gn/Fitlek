# Workout third-party resources

Exercise metadata and English/French/Spanish instructions from https://github.com/hasaneyldrm/exercises-dataset, revision 7455efae41b330c265e7cd4b78dfa848e7ce5ebd. 1324 records imported directly from upstream under MIT. Full license: [exercises-dataset-LICENSE.txt](licenses/exercises-dataset-LICENSE.txt). Stable identity is source + upstream ID. No media from that dataset is imported.

openGym is a product/visual reference only; no AGPL source, translated strings, branding, fonts or assets are included. Native UI and behavior are independently implemented.

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
