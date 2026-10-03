// Base API URL. Override at build/run time for local web testing, e.g.:
//   flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000/api
// Retains the existing backend by default; local testing requires the override.
const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://51.170.143.251/api',
);
