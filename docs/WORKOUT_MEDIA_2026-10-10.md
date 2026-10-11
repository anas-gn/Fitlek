# Exercise media follow-up — 2026-10-10

October 11 correction: see [current media loading and pack import](WORKOUT_MEDIA_IMPORT.md).
The three unfinished downloads were completed; duplicate/mislabeled wger 70
was excluded after comparing its bytes with ordinary pull-up 71. The shipped
bundle now has 28 distinct clips / 33 identities. Supplied GIF/video URLs and
actual image thumbnails render in-app; full 1,324-exercise media is still absent.
The counts below describe the earlier planned 29-clip mapping.

The exercise metadata import already existed. The missing full video/GIF catalog
is a separate product gap. The user confirmed that SIRVYA has no GymVisual
license, so this change uses reviewed open media and preserves existing features.

## Where to see videos

At `http://localhost:8082`, sign in with an existing SIRVYA account, open
**Workout → Exercises**, and enable **Video demos**. Open an exercise to see its
demonstration. The same player appears during active workouts. Thumbnails use
real video posters with a play badge. Entries distinguish **Video**,
**Illustrated demo**, and **No demo yet**.

Videos support play/pause, scrubbing, minimize/expand, looping, silent autoplay,
reduced-motion preferences and attribution links. Playback pauses when the app
is backgrounded or its route is hidden; the player is released when removed.
Failed initialization retains the poster and offers retry. Demo size uses the
existing Workout preference; existing illustration controls remain available.

## Exact coverage and limits

| Collection | Assets | Exercise identities |
| --- | --- | --- |
| New real videos | 29 H.264 MP4 clips, 29 JPEG posters | 34: 29 imported, five SIRVYA |
| Existing illustrations | 38 PNG frames / 19 demonstrations | 24 |
| Combined, with overlaps removed | Both collections | 41: 35 imported, six SIRVYA |

Only **29 of the 1324 imported exercises have real videos**. Coverage includes
bench/incline presses, shoulder/lateral raises, barbell/dumbbell/cable curls,
front/Smith/hack squats, lunges, Romanian deadlift, leg curls, calf raises,
triceps extensions, pull-ups and hip adduction. Unmatched imported/custom
exercises retain instructions and optional user demonstration uploads.

The complete GymVisual catalog remains **BLOCKED — LICENSE**. The upstream
[dataset notice](https://github.com/hasaneyldrm/exercises-dataset/blob/main/NOTICE.md)
separates MIT metadata from media rights. The replacement videos are attributed
to Goulart through wger and retain
[CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/). Source identities,
author history, byte hashes, license and technical changes are stored in
[catalog.json](../assets/workout/videos/catalog.json) and
[the third-party notice](THIRD_PARTY_WORKOUT.md).

## Implementation

- Flutter: bundled media catalog, native `video_player` panel, poster thumbnails,
  media labels and video-only library filter; existing authentication reused.
- Backend: authenticated `video=true` search using reviewed source/ID pairs,
  preserving ownership, equipment, search and pagination. The API identity map
  is packaged inside `backend/`; it does not require Flutter assets at startup.
- Maintenance: resumable public video downloads, strict author/license/source
  checks, H.264 transcoding, poster extraction and source/output hash verification.
- Database: no new exercise import, user system, media provider or schema change.

## Verification

Retesting is in progress. Results will be recorded here after completion.

Confirmed so far: Flutter analysis has no issues; the full Flutter suite passes
87 checks with one optional capture skipped. All 138 backend functional checks
pass against disposable local MySQL. Video asset integrity and the rebuilt
browser journey will be checked after the remaining downloads finish.

Initial implementation checks found six analyzer issues, now corrected. One
focused test attempt failed during compilation because the disk filled; no pass
is claimed for that run. Temporary generated test/compiler files were cleaned
and downloads were resumed. The first official license URL returned 404; the
verified current text URL is used instead. Completed source downloads/assets
were preserved across retries.

Visual review also caught incorrect upstream equipment metadata: wger video 2
is listed under a barbell exercise but shows a dumbbell Romanian deadlift.
It maps only to imported **1459**, the dumbbell variation. The original exercise
dataset was preserved. The mapping rationale is retained in both catalogs and
protected by an asset regression assertion. Temporary source connection failures
are retried; unfinished downloads resume from verified-size byte-range files.

[Reviewed frame](verification/media/romanian-dumbbell.png): extracted from
[Goulart's wger video 2](https://wger.de/media/exercise-video/507/307e7276-a14d-4ea0-b579-f5b0dbc6f5af.MOV),
CC BY-SA 4.0; scaled during video conversion, then exported as a PNG for review.

Physical Android playback remains unverified because no authorized ADB device
or emulator is available. The older debug APK does not contain these new videos;
no updated native build or device result is claimed.
