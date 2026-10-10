import test from 'node:test';
import assert from 'node:assert/strict';
import {firebaseAuthFailure} from '../services/firebaseAuthFailure.js';

test('Firebase rejects invalid credentials without treating them as provider outages', () => {
  for (const code of ['auth/argument-error', 'auth/invalid-argument', 'auth/invalid-id-token', 'auth/id-token-expired', 'auth/id-token-revoked', 'auth/user-disabled']) {
    assert.equal(firebaseAuthFailure({code}).status, 401, code);
  }
});

test('Firebase network, certificate and configuration failures report temporary unavailability', () => {
  for (const error of [
    {code: 'app/network-error'}, {code: 'app/network-timeout'},
    {code: 'auth/internal-error'}, {code: 'app/invalid-credential'},
    new Error('Error fetching public keys for Google certs'), undefined,
  ]) {
    const response = firebaseAuthFailure(error);
    assert.equal(response.status, 503);
    assert.match(response.body.error, /temporarily unavailable/);
    assert.equal(response.body.accessToken, undefined);
  }
});
