// supabase/install.sql is what a person pastes into the SQL editor of a
// project that already runs another application. It must install cleanly in
// one go, refuse to run twice, leave the other application alone, and be
// fully removable.
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { test } from 'node:test';
import { fileURLToPath } from 'node:url';
import { PGlite } from '@electric-sql/pglite';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const sql = (path) => readFileSync(join(root, path), 'utf8');
const count = async (db, query) => (await db.query(`select count(*)::int as n from ${query}`)).rows[0].n;

test('install.sql installs once, touches nothing else, and uninstall.sql removes it', async () => {
  const db = new PGlite();
  await db.exec(sql('tests/supabase-stub.sql'));
  const policiesBefore = await count(db, 'pg_policies');

  await db.exec(sql('supabase/install.sql'));
  assert.equal(await count(db, 'lsicorp.products'), 4);
  assert.equal(await count(db, 'lsicorp.services'), 4);
  assert.equal(await count(db, `pg_tables where schemaname = 'public'`), 1, 'only the other application has tables in public');
  assert.equal(await count(db, 'public.other_app_orders'), 1);

  await assert.rejects(db.exec(sql('supabase/install.sql')), /already exists/);
  await db.exec('rollback');
  assert.equal(await count(db, 'lsicorp.products'), 4, 'a refused second run changes nothing');

  await db.exec(sql('supabase/uninstall.sql'));
  assert.equal(await count(db, `pg_namespace where nspname = 'lsicorp'`), 0);
  assert.equal(await count(db, 'pg_policies'), policiesBefore, 'no policies are left behind');
  assert.equal(await count(db, 'public.other_app_orders'), 1);
});

test('install.sql is up to date with the migrations and seed', () => {
  const installed = sql('supabase/install.sql');
  for (const part of ['supabase/seed.sql', 'supabase/migrations/20261006000003_security.sql']) {
    assert.ok(installed.includes(sql(part).trim()), `${part} has changed: run "npm run seed"`);
  }
});
