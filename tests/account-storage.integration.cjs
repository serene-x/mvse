// Temporary accounts only. No email is sent; cleanup always runs.
require('dotenv').config({ quiet: true });
const { createClient } = require('@supabase/supabase-js');
const { randomUUID } = require('node:crypto');
const assert = require('node:assert/strict');
const options = { auth: { persistSession: false, autoRefreshToken: false } };
const admin = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY,
  options,
);
(async () => {
  const ids = [];
  try {
    const clients = [];
    for (let i = 0; i < 2; i++) {
      const email = `mvse-test-${randomUUID()}@example.invalid`,
        password = randomUUID() + 'aA!8';
      const { data, error } = await admin.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
      });
      assert.ifError(error);
      ids.push(data.user.id);
      const client = createClient(
        process.env.SUPABASE_URL,
        process.env.SUPABASE_ANON_KEY,
        options,
      );
      const login = await client.auth.signInWithPassword({ email, password });
      assert.ifError(login.error);
      clients.push(client);
    }
    const book = {
      season: 'Soft Autumn',
      depth: 'Light',
      undertone: 'Neutral',
      notes: [],
    };
    const write = await clients[0]
      .from('user_beauty_data')
      .upsert({ user_id: ids[0], kind: 'book', data: book });
    assert.ifError(write.error);
    const mine = await clients[0]
      .from('user_beauty_data')
      .select('data')
      .eq('user_id', ids[0])
      .eq('kind', 'book')
      .single();
    assert.ifError(mine.error);
    assert.deepEqual(mine.data.data, book);
    const other = await clients[1]
      .from('user_beauty_data')
      .select('data')
      .eq('user_id', ids[0]);
    assert.ifError(other.error);
    assert.equal(other.data.length, 0);
    const blocked = await clients[1]
      .from('user_beauty_data')
      .upsert({ user_id: ids[0], kind: 'shelf', data: { keys: [] } });
    assert.ok(blocked.error);
    const shelf = await clients[0].from('user_beauty_data').upsert({
      user_id: ids[0],
      kind: 'shelf',
      data: { keys: ['test|product'] },
    });
    assert.ifError(shelf.error);
    const publicRead = await clients[0]
      .from('reviewed_shade_reports')
      .select('source_url')
      .limit(1);
    assert.ifError(publicRead.error);
    const publicWrite = await clients[0].from('reviewed_shade_reports').insert({
      source_url: 'https://www.tiktok.com/@test/video/123',
      person: 'test',
      shades: { a: '1', b: '2' },
      evidence_note: 'test',
    });
    assert.ok(publicWrite.error);
    console.log(
      'PASS: email/password sign-in, persisted profile and shelf, cross-account isolation, reviewed-report write protection.',
    );
  } finally {
    for (const id of ids) {
      const { error } = await admin.auth.admin.deleteUser(id);
      assert.ifError(error);
    }
    console.log('Temporary test accounts removed.');
  }
})().catch(() => {
  console.error(
    'Account storage verification failed. No credentials were logged.',
  );
  process.exit(1);
});
