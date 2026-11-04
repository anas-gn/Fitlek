import test from 'node:test';
import assert from 'node:assert/strict';
import worker from '../cloudflare/invite-worker.js';

test('invitation route rejects invalid codes and write requests', async () => {
  assert.equal((await worker.fetch(new Request('https://sirvya.com/invite/a'))).status, 404);
  assert.equal((await worker.fetch(new Request('https://sirvya.com/invite/ABCD1234', {method: 'POST'}))).status, 405);
});

test('invitation route serves personalized content without forwarding cookies', async () => {
  const original = globalThis.fetch;
  globalThis.fetch = async (url, options) => {
    assert.equal(url, 'https://api.sirvya.com/api/invite/ABCD1234');
    assert.equal(options.redirect, 'manual');
    assert.deepEqual(options.headers, {Accept: 'text/html'});
    return new Response('<strong>Coach Name</strong> has invited you', {
      headers: {'Content-Type': 'text/html', 'Set-Cookie': 'unexpected=1'},
    });
  };
  try {
    const result = await worker.fetch(new Request('https://sirvya.com/invite/ABCD1234'));
    assert.equal(result.status, 200);
    assert.match(await result.text(), /Coach Name/);
    assert.equal(result.headers.get('Cache-Control'), 'no-store');
    assert.equal(result.headers.get('Set-Cookie'), null);
  } finally { globalThis.fetch = original; }
});

test('invitation route does not expose an upstream redirect', async () => {
  const original = globalThis.fetch;
  globalThis.fetch = async () => new Response(null, {status: 302, headers: {Location: 'https://api.sirvya.com/'}});
  try {
    const result = await worker.fetch(new Request('https://sirvya.com/invite/ABCD1234'));
    assert.equal(result.status, 503);
    assert.equal(result.headers.get('Location'), null);
  } finally { globalThis.fetch = original; }
});
