// Runs the real migrations and seed in an in-process Postgres (PGlite) and
// exercises row-level security and the release workflow as different users.
// Supabase's own pieces (auth schema, roles, storage tables) are stubbed in
// tests/supabase-stub.sql, so this checks our SQL, not Supabase itself.
import assert from 'node:assert/strict';
import { readFileSync, readdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { before, test } from 'node:test';
import { fileURLToPath } from 'node:url';
import { PGlite } from '@electric-sql/pglite';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const sql = (path) => readFileSync(join(root, path), 'utf8');

const EDITOR = '00000000-0000-0000-0000-00000000000e';
const MANAGER_A = '00000000-0000-0000-0000-00000000000a';
const MANAGER_B = '00000000-0000-0000-0000-00000000000b';
const ADMIN = '00000000-0000-0000-0000-0000000000ad';
const OUTSIDER = '00000000-0000-0000-0000-0000000000ff';

let db;

/** Runs `fn` in a transaction as a signed-in user, or as an anonymous visitor when `user` is null. */
function as(user, fn) {
  return db.transaction(async (tx) => {
    await tx.query(`select set_config('request.jwt.claim.sub', $1, true)`, [user ?? '']);
    await tx.exec(`set local role ${user ? 'authenticated' : 'anon'}`);
    return fn(tx);
  });
}

const rows = async (tx, text, params = []) => (await tx.query(text, params)).rows;

const draft = (over = {}) => ({
  product_slug: '1145hz',
  platform: 'windows',
  version: '1.0.0',
  channel: 'stable',
  release_date: '2026-10-06',
  destination_type: 'file',
  destination_url: 'https://downloads.lsi.test/1145hz/player-1.0.0.exe',
  artifact_filename: 'player-1.0.0.exe',
  artifact_file_type: 'Windows installer',
  artifact_size_bytes: 1048576,
  artifact_sha256: 'a'.repeat(64),
  compat_minimum: 'Windows 10',
  compat_device_class: 'Desktop and laptop',
  steps: ['Run the installer'],
  notes: ['First release'],
  licence: 'Proprietary',
  support_route: 'See Support',
  ...over,
});

// A record that is valid with the seeded allowlist, for checking who may write.
const storeDraft = () =>
  draft({
    platform: 'android',
    destination_type: 'store',
    destination_url: 'https://play.google.com/store/apps/details?id=test',
    artifact_filename: null,
    artifact_file_type: null,
    artifact_size_bytes: null,
    artifact_sha256: null,
  });

function insertRelease(tx, record) {
  const columns = Object.keys(record);
  return tx.query(
    `insert into lsicorp.releases (${columns.join(', ')}) values (${columns.map((_, i) => `$${i + 1}`).join(', ')}) returning *`,
    Object.values(record),
  );
}

const setStatus = (tx, version, status, extra = '') =>
  tx.query(`update lsicorp.releases set status = $2 ${extra} where product_slug = '1145hz' and platform = 'windows' and version = $1`, [
    version,
    status,
  ]);

before(async () => {
  db = new PGlite();
  await db.exec(sql('tests/supabase-stub.sql'));
  for (const file of readdirSync(join(root, 'supabase/migrations')).sort()) {
    await db.exec(sql(`supabase/migrations/${file}`));
  }
  await db.exec(sql('supabase/seed.sql'));
  await db.exec(sql('supabase/seed.sql')); // running the seed twice must be harmless
  await db.exec(`
    insert into auth.users (id) values ('${EDITOR}'), ('${MANAGER_A}'), ('${MANAGER_B}'), ('${ADMIN}'), ('${OUTSIDER}');
    insert into lsicorp.staff (user_id, display_name, role) values
      ('${EDITOR}', 'Edith Editor', 'editor'),
      ('${MANAGER_A}', 'Ann Manager', 'release_manager'),
      ('${MANAGER_B}', 'Ben Manager', 'release_manager'),
      ('${ADMIN}', 'Ada Admin', 'admin');
  `);
});

test('the seed loads once and visitors can read published content', async () => {
  await as(null, async (tx) => {
    assert.equal((await rows(tx, 'select slug from lsicorp.products')).length, 4);
    assert.equal((await rows(tx, 'select 1 from lsicorp.doc_pages')).length, 14);
    assert.equal((await rows(tx, 'select 1 from lsicorp.faqs')).length, 18);
    assert.equal((await rows(tx, 'select 1 from lsicorp.pages')).length, 4);
    assert.equal((await rows(tx, 'select 1 from lsicorp.site_settings')).length, 1);
    assert.equal((await rows(tx, 'select 1 from lsicorp.services')).length, 4);
    assert.equal((await rows(tx, 'select 1 from lsicorp.releases')).length, 0);
  });
});

test('visitors and signed-in non-staff cannot write or read staff-only data', async () => {
  for (const user of [null, OUTSIDER]) {
    await as(user, async (tx) => {
      const changed = await tx.query(`update lsicorp.products set tagline = 'hacked'`);
      assert.equal(changed.affectedRows, 0);
    }).catch((error) => assert.match(error.message, /permission denied/));
    await assert.rejects(as(user, (tx) => insertRelease(tx, storeDraft())), /row-level security|permission denied/);
  }
  await assert.rejects(as(null, (tx) => tx.query('select 1 from lsicorp.audit_log')), /permission denied/);
  await assert.rejects(as(null, (tx) => tx.query('select 1 from lsicorp.staff')), /permission denied/);
  await as(OUTSIDER, async (tx) => {
    assert.equal((await rows(tx, 'select 1 from lsicorp.audit_log')).length, 0);
    assert.equal((await rows(tx, 'select 1 from lsicorp.staff')).length, 0);
  });
});

test('an editor edits content but not releases, settings or roles', async () => {
  await as(EDITOR, async (tx) => {
    const changed = await tx.query(`update lsicorp.products set tagline = tagline || ' ' where slug = '1145'`);
    assert.equal(changed.affectedRows, 1);
    assert.equal((await tx.query(`update lsicorp.site_settings set name = 'x'`)).affectedRows, 0);
    assert.equal((await tx.query(`update lsicorp.staff set role = 'admin' where user_id = '${EDITOR}'`)).affectedRows, 0);
    assert.equal((await tx.query(`delete from lsicorp.products where slug = '1145'`)).affectedRows, 0);
  });
  await assert.rejects(as(EDITOR, (tx) => insertRelease(tx, storeDraft())), /row-level security/);
});

test('unpublished documentation and hidden FAQs are visible to staff only', async () => {
  await as(EDITOR, (tx) => tx.query(`update lsicorp.doc_pages set status = 'draft' where product_slug = '1145' and slug = 'services'`));
  await as(null, async (tx) => assert.equal((await rows(tx, `select 1 from lsicorp.doc_pages where product_slug = '1145'`)).length, 2));
  await as(EDITOR, async (tx) => assert.equal((await rows(tx, `select 1 from lsicorp.doc_pages where product_slug = '1145'`)).length, 3));
  await as(EDITOR, (tx) => tx.query(`update lsicorp.doc_pages set status = 'published' where product_slug = '1145' and slug = 'services'`));
});

test('a release destination must be an allowlisted https URL', async () => {
  await assert.rejects(as(MANAGER_A, (tx) => insertRelease(tx, draft())), /not in the allowed external domains/);
  await as(ADMIN, (tx) =>
    tx.query(`update lsicorp.site_settings set allowed_external_domains = array_append(allowed_external_domains, 'downloads.lsi.test')`),
  );
  for (const [url, message] of [
    ['http://downloads.lsi.test/1145hz/player-1.0.0.exe', /must be an https URL/],
    ['https://user:pw@downloads.lsi.test/1145hz/player-1.0.0.exe', /must be an https URL/],
    ['https://downloads.lsi.test/1145hz/player-1.0.0.exe?X-Amz-Signature=1', /signed or credentialed/],
    ['https://downloads.lsi.test/1145hz/other.exe', /does not end with the artifact filename/],
  ]) {
    await assert.rejects(as(MANAGER_A, (tx) => insertRelease(tx, draft({ destination_url: url }))), message, url);
  }
  await assert.rejects(as(MANAGER_A, (tx) => insertRelease(tx, draft({ artifact_sha256: null }))), /SHA-256 checksum/);
  await assert.rejects(as(MANAGER_A, (tx) => insertRelease(tx, draft({ status: 'available' }))), /starts as a draft|product status/);
});

test('draft, review and publish, with a second person approving', async () => {
  const created = await as(MANAGER_A, (tx) => insertRelease(tx, draft({ prepared_by: MANAGER_B })));
  assert.equal(created.rows[0].prepared_by, MANAGER_A, 'the preparer is taken from the session, not the request');

  await as(null, async (tx) => assert.equal((await rows(tx, 'select 1 from lsicorp.releases')).length, 0));

  await assert.rejects(as(MANAGER_A, (tx) => setStatus(tx, '1.0.0', 'available')), /Set it to "available" before publishing/);
  await as(MANAGER_A, (tx) => setStatus(tx, '1.0.0', 'in-review'));
  await as(null, async (tx) => assert.equal((await rows(tx, 'select 1 from lsicorp.releases')).length, 0));

  await as(EDITOR, (tx) => tx.query(`update lsicorp.products set status = 'available', status_note = 'Released.' where slug = '1145hz'`));

  await as(MANAGER_A, (tx) => setStatus(tx, '1.0.0', 'draft'));
  await assert.rejects(as(MANAGER_A, (tx) => setStatus(tx, '1.0.0', 'available')), /cannot move from "draft" to "available"/);
  await as(MANAGER_A, (tx) => setStatus(tx, '1.0.0', 'in-review'));
  await assert.rejects(as(MANAGER_A, (tx) => setStatus(tx, '1.0.0', 'available')), /approved by a different person/);
  await as(MANAGER_B, (tx) => setStatus(tx, '1.0.0', 'available'));

  await as(null, async (tx) => {
    const [live] = await rows(tx, 'select status, reviewed_by, reviewed_at from lsicorp.releases');
    assert.equal(live.status, 'available');
    assert.equal(live.reviewed_by, MANAGER_B);
    assert.ok(live.reviewed_at);
  });
});

test('a reviewer who edits the details cannot then approve them', async () => {
  await as(MANAGER_A, (tx) => insertRelease(tx, draft({ platform: 'macos', destination_url: 'https://downloads.lsi.test/1145hz/player-1.0.0.dmg', artifact_filename: 'player-1.0.0.dmg' })));
  const mac = `product_slug = '1145hz' and platform = 'macos'`;
  await as(MANAGER_A, (tx) => tx.query(`update lsicorp.releases set status = 'in-review' where ${mac}`));
  await as(MANAGER_B, (tx) => tx.query(`update lsicorp.releases set compat_minimum = 'macOS 14' where ${mac}`));
  await assert.rejects(as(MANAGER_B, (tx) => tx.query(`update lsicorp.releases set status = 'available' where ${mac}`)), /different person/);
  await as(MANAGER_A, (tx) => tx.query(`update lsicorp.releases set status = 'available' where ${mac}`));
});

test('published details are frozen and the product cannot be un-released under them', async () => {
  await assert.rejects(
    as(MANAGER_A, (tx) => tx.query(`update lsicorp.releases set destination_url = 'https://downloads.lsi.test/x/player-1.0.0.exe' where version = '1.0.0' and platform = 'windows'`)),
    /frozen/,
  );
  await assert.rejects(
    as(EDITOR, (tx) => tx.query(`update lsicorp.products set status = 'coming-soon' where slug = '1145hz'`)),
    /has a published release/,
  );
  await assert.rejects(
    as(ADMIN, async (tx) => {
      const removed = await tx.query(`delete from lsicorp.releases where version = '1.0.0' and platform = 'windows'`);
      assert.equal(removed.affectedRows, 0);
      throw new Error('not deleted');
    }),
    /not deleted/,
  );
});

test('publishing a new version supersedes the old one in the same step', async () => {
  const next = draft({ version: '1.1.0', destination_url: 'https://downloads.lsi.test/1145hz/player-1.1.0.exe', artifact_filename: 'player-1.1.0.exe', notes: ['Fixes'] });
  await as(MANAGER_B, (tx) => insertRelease(tx, next));
  await as(MANAGER_B, (tx) => setStatus(tx, '1.1.0', 'in-review'));
  await as(MANAGER_A, (tx) => setStatus(tx, '1.1.0', 'available'));

  await as(null, async (tx) => {
    const all = await rows(tx, `select version, status, superseded_by from lsicorp.releases where platform = 'windows' order by version`);
    assert.deepEqual(all, [
      { version: '1.0.0', status: 'superseded', superseded_by: '1.1.0' },
      { version: '1.1.0', status: 'available', superseded_by: null },
    ]);
  });
});

test('withdrawing needs a reason and leaves no live download', async () => {
  await assert.rejects(as(MANAGER_A, (tx) => setStatus(tx, '1.1.0', 'withdrawn')), /gives a reason/);
  await as(MANAGER_A, (tx) => setStatus(tx, '1.1.0', 'withdrawn', `, withdrawn_reason = 'Installer fault'`));
  await as(null, async (tx) => {
    assert.equal((await rows(tx, `select 1 from lsicorp.releases where status = 'available' and platform = 'windows'`)).length, 0);
    assert.equal((await rows(tx, `select 1 from lsicorp.releases where platform = 'windows'`)).length, 2);
  });
});

test('every change is recorded with who made it, and the log cannot be altered', async () => {
  await as(ADMIN, async (tx) => {
    const log = await rows(
      tx,
      `select actor_name, action, old_data ->> 'status' as was, new_data ->> 'status' as now
       from lsicorp.audit_log where table_name = 'releases' and record_key = '1145hz/windows-1.1.0' order by id`,
    );
    assert.deepEqual(log, [
      { actor_name: 'Ben Manager', action: 'insert', was: null, now: 'draft' },
      { actor_name: 'Ben Manager', action: 'update', was: 'draft', now: 'in-review' },
      { actor_name: 'Ann Manager', action: 'update', was: 'in-review', now: 'available' },
      { actor_name: 'Ann Manager', action: 'update', was: 'available', now: 'withdrawn' },
    ]);
  });
  await assert.rejects(as(ADMIN, (tx) => tx.query('delete from lsicorp.audit_log')), /permission denied/);
});

test('a deactivated staff member loses access', async () => {
  await as(ADMIN, (tx) => tx.query(`update lsicorp.staff set active = false where user_id = '${EDITOR}'`));
  await as(EDITOR, async (tx) => {
    assert.equal((await tx.query(`update lsicorp.products set tagline = 'x' where slug = '1145'`)).affectedRows, 0);
  });
});

test('another application sharing the database is left untouched', async () => {
  await as(null, async (tx) => {
    assert.deepEqual(await rows(tx, 'select note from public.other_app_orders'), [{ note: 'untouched' }]);
    await tx.query(`insert into public.other_app_orders values (2, 'still writable')`);
  });
  const ours = await db.query(`select count(*)::int as n from pg_tables where schemaname = 'public' and tablename <> 'other_app_orders'`);
  assert.equal(ours.rows[0].n, 0, 'the site must not create tables in the public schema');
  const functions = await db.query(`select count(*)::int as n from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public'`);
  assert.equal(functions.rows[0].n, 0, 'the site must not create functions in the public schema');
});

test('a visitor can send an enquiry but can never read one', async () => {
  const enquiry = `insert into lsicorp.enquiries (name, email, organisation, service_slug, message, consent)
                   values ('Thandi M', 'thandi@example.test', 'Acme', 'digital-platforms', 'We would like a marketplace built.', true)`;
  await as(null, (tx) => tx.query(enquiry));
  await assert.rejects(as(null, (tx) => tx.query('select 1 from lsicorp.enquiries')), /permission denied/);
  await as(OUTSIDER, async (tx) => assert.equal((await rows(tx, 'select 1 from lsicorp.enquiries')).length, 0));

  // A visitor cannot pre-set how the enquiry is handled, skip consent, or send junk.
  await assert.rejects(
    as(null, (tx) => tx.query(`insert into lsicorp.enquiries (name, email, message, consent, status) values ('x', 'x@example.test', 'A long enough message.', true, 'closed')`)),
    /permission denied/,
  );
  for (const [values, reason] of [
    [`('x', 'x@example.test', 'A long enough message.', false)`, 'consent'],
    [`('x', 'not-an-email', 'A long enough message.', true)`, 'email'],
    [`('x', 'x@example.test', 'short', true)`, 'message'],
  ]) {
    await assert.rejects(as(null, (tx) => tx.query(`insert into lsicorp.enquiries (name, email, message, consent) values ${values}`)), /check constraint/, reason);
  }

  await as(ADMIN, async (tx) => {
    const [seen] = await rows(tx, 'select name, status from lsicorp.enquiries');
    assert.deepEqual(seen, { name: 'Thandi M', status: 'new' });
    assert.equal((await tx.query(`update lsicorp.enquiries set status = 'in-progress', notes = 'Called back'`)).affectedRows, 1);
  });
});

test('services are public to read and staff-only to change, and products can only list real ones', async () => {
  await as(null, async (tx) => {
    assert.equal((await rows(tx, `select 1 from lsicorp.products where 'logistics-technology' = any (services)`)).length, 1);
  });
  await assert.rejects(as(null, (tx) => tx.query(`update lsicorp.services set name = 'x'`)), /permission denied/);
  await as(ADMIN, (tx) => tx.query(`update lsicorp.services set tagline = tagline || '' where slug = 'digital-platforms'`));
  await assert.rejects(
    as(ADMIN, (tx) => tx.query(`update lsicorp.products set services = array['no-such-service'] where slug = '1145'`)),
    /only list services that exist/,
  );
});

test('only release managers can add files to the release bucket', async () => {
  const add = (tx) => tx.query(`insert into storage.objects (bucket_id, name) values ('lsicorp-release-files', 'a.exe')`);
  await as(MANAGER_A, add);
  await assert.rejects(as(OUTSIDER, add), /row-level security/);
});
