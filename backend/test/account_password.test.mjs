import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import bcrypt from 'bcrypt';

test('account password handler rejects incorrect credentials and stores a working replacement hash', async () => {
  const source = await fs.readFile(new URL('../routes/anas/auth.js', import.meta.url), 'utf8');
  const start = source.indexOf("router.put('/account/password'");
  const end = source.indexOf("router.use('/account/email-change'", start);
  let handler;
  let passwordHash = await bcrypt.hash(' old password ', 4);
  let updates = 0;
  const db = {query: async (sql, args) => {
    assert.equal(args.at(-1), 42, 'Password changes must use authenticated user ID');
    if (sql.startsWith('SELECT')) return [[{passwordHash, authProvider: 'email'}]];
    passwordHash = args[0]; updates++; return [{affectedRows: 1}];
  }};
  new Function('router', 'requireAuth', 'db', 'bcrypt', source.slice(start, end))(
    {put: (_path, _auth, fn) => {handler=fn;}}, () => {}, db, bcrypt);
  const call = async (body) => {
    let status = 200, result;
    await handler({user: {id: 42}, body}, {status(code) {status=code; return this;}, json(value) {result=value;}});
    return {status, result};
  };
  assert.equal((await call({currentPassword: 'incorrect', newPassword: 'newPassword123'})).status, 401);
  assert.equal(updates, 0);
  assert.equal((await call({currentPassword: ' old password ', newPassword: 'newPassword123'})).status, 200);
  assert.equal(updates, 1);
  assert.equal(await bcrypt.compare('newPassword123', passwordHash), true);
  assert.equal(await bcrypt.compare(' old password ', passwordHash), false);
});
