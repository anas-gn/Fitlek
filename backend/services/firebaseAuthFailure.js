// Reject unverified tokens in every case, but do not describe provider outages
// or server configuration failures as invalid user credentials.
const invalidTokenCodes = new Set([
  'auth/argument-error',
  'auth/invalid-argument',
  'auth/invalid-id-token',
  'auth/id-token-expired',
  'auth/id-token-revoked',
  'auth/user-disabled',
]);

export function firebaseAuthFailure(error) {
  if (invalidTokenCodes.has(error?.code)) {
    return {status: 401, body: {error: 'Invalid or expired Google token. Please try again.'}};
  }
  return {
    status: 503,
    body: {error: 'Google sign-in is temporarily unavailable. Please try again shortly.'},
  };
}
