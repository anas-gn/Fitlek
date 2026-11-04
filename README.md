# Sirvya mobile app

Flutter app for Sirvya clients and coaches. This repository contains the mobile frontend; the API is maintained in [Sirvya_Backend](https://github.com/mehdi-bouderna/Sirvya_Backend).

## Production

- API: https://api.sirvya.com/api
- App version: 1.0.2+32
- Flutter: 3.44.6
- iOS bundle / Android application ID: com.sirvya.app
- iOS minimum version: 15.0

Clients can book coaches, use live chat and voice notes, scan meals, track daily nutrition and weight, and manage their nutrition goals. Meal photos and received chat media are stored locally on the device; saved meal metadata and chat history use authenticated backend APIs. Coaches have their dashboard, calendar, client management and messaging.

## Development

```sh
flutter pub get
flutter test --timeout 60s
flutter run
```

An explicit API_BASE_URL build define can point a test build at a testing server. Production is the source default. Public Firebase and OAuth client configuration is included. Azure, database, signing and service-account private credentials must never be put in the app.

## iOS deployment

The Flutter project is at the repository root. Run the **SIRVYA iOS - Build and TestFlight** GitHub Actions workflow on main. It validates the existing Apple signing credentials, chooses an unused build number, builds on macOS and optionally uploads to TestFlight. It does not submit the app for public App Store review. Select the upload option explicitly for the desired run.

See [GitHub iOS builds](docs/GITHUB_IOS_BUILDS.md) for signing secrets and workflow details, and [production builds](docs/PRODUCTION_BUILDS.md) for Android, Codemagic and device verification. Final iPhone permission, camera, audio, push and sign-in checks require a physical device.
