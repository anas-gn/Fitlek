# Sirvya production builds

The Flutter application lives at the root of the `sirvya_app` GitHub repository. In the local V3 workspace it lives in `mobile_app/`. The backend is deployed separately from `Sirvya_Backend`.

## Current configuration

- Android application ID and iOS bundle ID: `com.sirvya.app`.
- Apple signing team: `NBG9FA33WF`.
- Production API: `https://api.sirvya.com/api`; realtime uses the same HTTPS host.
- Flutter version validated locally: `3.44.6`, Dart `3.12.2`.
- App version: `1.0.2+32`. GitHub Actions selects an unused App Store Connect build number automatically.
- Android release builds require the existing upload keystore and a complete `android/key.properties`. They fail instead of silently using debug signing.
- Firebase client configuration and public OAuth client IDs are included. Backend credentials, private Apple keys and Android signing keys are excluded.

## Android

Keep the existing keystore and passwords in a private location. Configure `android/key.properties` locally or restore it from Codemagic's secure signing variables. Never commit it.

```sh
flutter pub get
flutter test --timeout 60s
flutter build apk --release --dart-define=API_BASE_URL=https://api.sirvya.com/api
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.sirvya.com/api
```

The APK is in `build/app/outputs/flutter-apk/app-release.apk`; the Play Store bundle is in `build/app/outputs/bundle/release/app-release.aab`.

Register the upload certificate SHA-1/SHA-256, and the Google Play App Signing certificate when distributing through Play, in Firebase's Android app settings. Google login needs the fingerprint matching the installed build.

## iOS on Codemagic

The existing Codemagic Workflow Editor setup is retained. No root `codemagic.yaml` overrides its saved signing configuration.

1. Select `sirvya_app`, branch `main`, and the latest commit. The Flutter project path is the repository root, not `mobile_app`.
2. Select Flutter `3.44.6` (or a compatible newer stable version), Xcode and CocoaPods. iOS minimum deployment target is 15.0.
3. Check signing uses team `NBG9FA33WF`, bundle `com.sirvya.app`, and an App Store distribution certificate/profile for TestFlight. Refresh the profile after enabling Push Notifications and Sign in with Apple.
4. Configure the release build argument `--dart-define=API_BASE_URL=https://api.sirvya.com/api`. The same URL is the source default.
5. Run `flutter pub get`, `pod install` in `ios/`, and `flutter build ipa --release` with the signing profile applied by Codemagic. Enable the workflow's TestFlight publishing if wanted.
6. Verify the App Store Connect integration if automatic signing or TestFlight upload requests it. Its API key is separate from the APNs and Sign in with Apple keys. Reuse your existing valid integration rather than creating replacement keys unnecessarily.

Codemagic documentation: https://docs.codemagic.io/flutter-code-signing/ios-code-signing/ and https://docs.codemagic.io/publishing/publishing-to-app-store/ .

## Device checks before a public release

The Android build can be compiled on Windows. iOS compilation/signing and physical iPhone verification must finish on Codemagic and an iPhone.

Test client and coach registration/login, returning Apple/Google login and role-first social signup; camera/gallery and voice uploads; notification permissions, background push sound and tap destinations; realtime messages/reservations; pricing acceptance/expiry; location consent, distance and map; referrals and QR links. Test each platform with the app open, backgrounded and closed, and with permissions denied.

The current map uses public OpenStreetMap tiles. Before broad distribution, confirm usage meets https://operations.osmfoundation.org/policies/tiles/ or configure a suitable hosted tile provider. Public tiles have no service guarantee. Background location refresh is scheduled by the OS and cannot guarantee exactly 15-minute intervals.

Private chat media is local and has no reinstall backup yet; server text/history remains. Do not treat compiling successfully as proof that all device flows or store requirements have passed.
