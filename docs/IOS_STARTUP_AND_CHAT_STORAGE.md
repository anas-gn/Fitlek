# iOS startup and local chat media

Build 32 replaces the intro video with the session screen directly when playback completes or fails. Skip intro always works, and a 25-second watchdog handles a stalled native player or missing completion events. The route no longer waits for an unscheduled post-frame navigation callback. These changes apply to Android and iOS.

Photos and voice notes live under Application Support/chat_media/USER_ID, with an SQLite index. New entries store relative filenames. Legacy absolute paths are resolved against the current account folder and migrated once, preserving existing files after a container relocation without rewriting metadata on every scroll. Explicit deletion tombstones are preserved.

Text history remains on the server. Chat media is removed from the temporary server storage after both participants save or explicitly delete it. Deleting the mobile app removes its private local files; reinstalling the app does not restore those attachments. An expired attachment is shown as Not on this device, while a temporary download failure remains retryable. No iCloud sync or automatic reinstall recovery is implemented.

Apple distinguishes Offload App, which keeps documents and data, from Delete App, which removes them: https://support.apple.com/en-au/108429 . Recovering a deleted attachment requires a remaining backup/server copy or resending it from another device.

Verification includes native video completion, initialization/playback failures, a stalled player, skipping initialization, disposal, legacy folder relocation, relative paths, expired media and the existing chat layout tests. The GitHub iOS workflow runs startup and storage regressions before signing. On the physical iPhone, check a fresh install, normal video completion, Skip intro, background/resume, existing photos/audio and logout/login without deleting the app.