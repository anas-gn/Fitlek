// Production HTTPS endpoint. Development builds can override API_BASE_URL.
const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://api.sirvya.com/api',
);
