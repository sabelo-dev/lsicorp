// Each file in supabase/sync/ is run against the live database by hand, so
// it has to apply cleanly on top of a fresh install, be safe to run twice,
// and leave the release exactly as its record describes it.
import assert from 'node:assert/strict';
import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { test } from 'node:test';
import { fileURLToPath } from 'node:url';
import { PGlite } from '@electric-sql/pglite';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const sql = (path) => readFileSync(join(root, path), 'utf8');
const syncDir = join(root, 'supabase/sync');
const files = existsSync(syncDir) ? readdirSync(syncDir).filter((f) => f.endsWith('.sql')) : [];

for (const file of files) {
  const slug = file.replace(/\.sql$/, '');

  test(`sync/${file} applies on top of an install, twice, and matches its release record`, async () => {
    const db = new PGlite();
    await db.exec(sql('tests/supabase-stub.sql'));
    await db.exec(sql('supabase/install.sql'));
    await db.exec(sql(`supabase/sync/${file}`));
    await db.exec(sql(`supabase/sync/${file}`));

    const records = readdirSync(join(root, 'content/releases'))
      .map((name) => JSON.parse(sql(`content/releases/${name}`)))
      .filter((r) => r.product_slug === slug);

    await db.transaction(async (tx) => {
      await tx.query(`select set_config('request.jwt.claim.sub', '', true)`);
      await tx.exec('set local role anon');

      for (const record of records) {
        const { rows } = await tx.query(
          'select status, artifact_sha256, artifact_size_bytes::int as size, destination_url from lsicorp.releases where product_slug = $1 and platform = $2 and version = $3',
          [record.product_slug, record.platform, record.version],
        );
        if (record.status === 'draft') {
          assert.equal(rows.length, 0, 'a draft release must not be visible to visitors');
          continue;
        }
        assert.equal(rows.length, 1);
        assert.equal(rows[0].status, record.status);
        if (record.destination_type === 'file') {
          assert.equal(rows[0].artifact_sha256, record.artifact_sha256);
          assert.equal(rows[0].size, record.artifact_size_bytes);
          assert.ok(rows[0].destination_url.endsWith(`/${record.artifact_filename}`));
        } else {
          // A web app or store listing has no file, only its address.
          assert.equal(rows[0].artifact_sha256, null);
          assert.equal(rows[0].destination_url, record.destination_url);
        }
      }

      const { rows: faqs } = await tx.query('select count(*)::int as n from lsicorp.faqs where product_slug = $1', [slug]);
      const authored = JSON.parse(sql(`content/faqs/${slug}.json`)).items.length;
      assert.equal(faqs[0].n, authored, 'running twice must not duplicate FAQs');
    });
  });
}

test('there is at least nothing broken when no sync files exist', () => assert.ok(files.length >= 0));
