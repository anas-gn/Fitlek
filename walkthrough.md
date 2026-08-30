# Walkthrough: App Version Checker

The app version checker has been successfully implemented on both the backend and frontend.

## What was changed

### Backend
- **Database**: A new table `app_versions` is automatically created on startup by `ensureSchema.js`. It tracks `latest_version`, `min_required_version`, and `store_url` for both iOS and Android. Default values are inserted automatically.
- **Endpoint**: A new public API endpoint `GET /api/app-version?platform=ios` (or android) is now available. It queries the `app_versions` table and returns the version rules.

### Frontend
- **Dependencies**: Added `package_info_plus` to the Flutter app to retrieve the native app version on startup.
- **AppVersionChecker**: Created a new `AppVersionChecker` component. This component serves as the `home` widget for the app. It intercepts the startup sequence, compares the local app version with the backend rules, and decides how to proceed:
  - If the user's version is strictly less than `min_required_version`, they receive a non-dismissible dialog that forces them to go to the store.
  - If the user's version is less than `latest_version` (but above the minimum), they receive a dismissible dialog asking if they'd like to update.
  - Otherwise, they proceed seamlessly into the app (`SessionRouter`).

## How to test

To see it in action, you can modify the database values directly or wait for the backend to recreate them.
1. Start the Node.js backend (`npm run dev`).
2. Start the Flutter app (`flutter run`).
3. You will see it smoothly transition to the main app if your versions match.
4. If you want to test the update dialogues, temporarily adjust the backend logic in `app_version_checker.dart` (or better, change the `min_required_version` / `latest_version` in your MySQL database) and restart the Flutter app.

> [!NOTE]
> You will need to update the `store_url` fields in the `app_versions` database table with the real App Store and Google Play Store URLs once your app is published.
