const String baseUrl = 'http://51.170.143.251/api';
// const String baseUrl = 'https://sirvya-1c5de0abe34c.herokuapp.com/api';

/// Origin of the openGym workout server whose frontend the embedded WebView loads.
/// This is where the Sirvya app talks to the workout backend (POST /api/auth/sirvya-login)
/// and where `frontend/` is served from. Override per environment if the workout server
/// lives elsewhere.
const String workoutBaseUrl = 'http://localhost:5173';