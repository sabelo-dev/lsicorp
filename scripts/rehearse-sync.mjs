// Rehearses a sync file against the state the live database is in now.
//
// tests/sync.test.mjs proves a sync file applies to a fresh install. The live
// database is not fresh: it already holds whatever the previous sync file put
// there. This installs the schema in an in-process Postgres, applies the sync
// file as last committed (the live state), then the one in the working tree,
// twice, and prints what a visitor would see before and after.
//
//   node scripts/rehearse-sync.mjs gold-digger
import { execFileSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { PGlite } from '@electric-sql/pglite';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const slug = process.argv[2];
if (!slug) {
  console.error('Usage: node scripts/rehearse-sync.mjs <product-slug>');
  process.exit(2);
}
const file = `supabase/sync/${slug}.sql`;
const sql = (path) => readFileSync(join(root, path), 'utf8');
const committed = execFileSync('git', ['show', `HEAD:${file}`], { cwd: root, encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });

const db = new PGlite();
await db.exec(sql('tests/supabase-stub.sql'));
await db.exec(sql('supabase/install.sql'));

/** The releases and status note as an anonymous visitor's query returns them. */
async function visible() {
  return db.transaction(async (tx) => {
    await tx.query(`select set_config('request.jwt.claim.sub', '', true)`);
    await tx.exec('set local role anon');
    const releases = await tx.query(
      `select version, channel, status, superseded_by, artifact_filename, artifact_size_bytes::int as bytes, left(artifact_sha256, 12) as sha
       from lsicorp.releases where product_slug = $1 order by version`,
      [slug],
    );
    const product = await tx.query('select status, status_note from lsicorp.products where slug = $1', [slug]);
    return { releases: releases.rows, product: product.rows[0] };
  });
}
const show = (title, state) => {
  console.log(`\n${title}\n  ${state.product.status}: ${state.product.status_note}`);
  for (const r of state.releases) {
    console.log(`  ${r.version} (${r.channel}) ${r.status}${r.superseded_by ? ` by ${r.superseded_by}` : ''}  ${r.artifact_filename ?? 'no file'}  ${r.bytes ?? ''}  ${r.sha ?? ''}`);
  }
};

await db.exec(committed);
show('Live now (the sync file as last committed):', await visible());

await db.exec(sql(file));
const once = await visible();
await db.exec(sql(file));
const twice = await visible();
show('After the sync file in the working tree:', once);

const offered = once.releases.filter((r) => r.status === 'available');
const problems = [];
if (JSON.stringify(once) !== JSON.stringify(twice)) problems.push('running it a second time changed something');
const channels = offered.map((r) => r.channel);
if (new Set(channels).size !== channels.length) problems.push('two releases are offered on the same channel');
if (problems.length) {
  console.error(`\nFAILED: ${problems.join('; ')}`);
  process.exit(1);
}
console.log(`\nok: applies on top of the live state, is safe to run twice, and offers ${offered.map((r) => r.version).join(', ') || 'nothing'}`);
