import assert from 'node:assert/strict';
import { test } from 'node:test';
import * as Rules from '../app/qml/rules.mjs';

const allowed = ['play.google.com', 'downloads.lsi.test'];

const release = (over = {}) => ({
  product_slug: 'player',
  platform: 'windows',
  version: '1.0.0',
  channel: 'stable',
  status: 'available',
  release_date: '2026-01-10',
  destination_type: 'file',
  destination_url: 'https://downloads.lsi.test/player/player-1.0.0.exe',
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
  prepared_by: 'user-a',
  ...over,
});

test('an allowlisted https URL passes', () => {
  assert.deepEqual(Rules.checkExternalUrl('https://play.google.com/store/apps/details?id=x', allowed), []);
});

test('unsafe destinations are rejected', () => {
  const bad = [
    'http://play.google.com/app',
    'https://evil.example/app',
    'https://play.google.com.evil.example/app',
    'https://user:pass@play.google.com/app',
    'https://play.google.com@evil.example/app',
    'https://downloads.lsi.test/a.exe?X-Amz-Signature=abc',
    'https://downloads.lsi.test/a.exe?token=abc',
    'javascript:alert(1)',
    '//play.google.com/app',
    '',
  ];
  for (const url of bad) assert.notEqual(Rules.checkExternalUrl(url, allowed).length, 0, url);
});

test('product links may be site paths but not protocol-relative URLs', () => {
  assert.deepEqual(Rules.checkProductLink('/support', allowed), []);
  assert.notEqual(Rules.checkProductLink('//evil.example', allowed).length, 0);
});

test('markdown may not contain raw HTML or unapproved links', () => {
  assert.deepEqual(Rules.checkMarkdown('See [support](/support) and [the store](https://play.google.com/x).', allowed), []);
  assert.deepEqual(Rules.checkMarkdown('Use `<b>` in code only.', allowed), []);
  assert.notEqual(Rules.checkMarkdown('Hello <script>alert(1)</script>', allowed).length, 0);
  assert.notEqual(Rules.checkMarkdown('[x](javascript:alert(1))', allowed).length, 0);
  assert.notEqual(Rules.checkMarkdown('[x](https://evil.example/)', allowed).length, 0);
  assert.notEqual(Rules.checkMarkdown('<https://evil.example/>', allowed).length, 0);
});

test('a complete release record passes', () => {
  assert.deepEqual(Rules.checkRelease(release(), allowed), []);
});

test('a direct file must carry its checksum, size and matching filename', () => {
  assert.match(Rules.checkRelease(release({ artifact_sha256: null }), allowed).join(), /checksum/);
  assert.match(Rules.checkRelease(release({ artifact_sha256: 'ABC' }), allowed).join(), /64 lowercase hex/);
  assert.match(Rules.checkRelease(release({ artifact_filename: 'other.exe' }), allowed).join(), /does not end with/);
});

test('platform and destination type must agree', () => {
  assert.match(Rules.checkRelease(release({ platform: 'web' }), allowed).join(), /used together/);
  const store = release({
    platform: 'android',
    destination_type: 'store',
    destination_url: 'https://play.google.com/store/apps/details?id=x',
  });
  assert.match(Rules.checkRelease(store, allowed).join(), /only apply to a direct file/);
});

test('only an available release produces an action, with the right wording', () => {
  const releases = [
    release(),
    release({ version: '0.9.0', status: 'superseded', release_date: '2025-12-01' }),
    release({ version: '1.1.0', status: 'draft', release_date: '2026-02-01' }),
    release({ version: '1.1.0-beta', channel: 'beta', release_date: '2026-01-20' }),
    release({ product_slug: 'shop', platform: 'web', destination_type: 'web-app' }),
  ];
  const mine = Rules.availableReleases(releases, 'player', 'windows');
  assert.deepEqual(mine.map((r) => r.version), ['1.0.0', '1.1.0-beta']);
  assert.equal(Rules.actionLabel(mine[0], '1145Hz Player'), 'Download for Windows');
  assert.equal(Rules.actionLabel(releases[4], '1145 Lifestyle'), 'Open 1145 Lifestyle');
  assert.deepEqual(Rules.availableReleases(releases, 'player', 'macos'), []);
});

test('drafts and releases in review are never public', () => {
  const shown = Rules.publicReleases([
    release({ status: 'draft' }),
    release({ status: 'in-review', version: '1.0.1' }),
    release({ status: 'withdrawn', version: '0.8.0', release_date: '2025-11-01' }),
    release({ version: '1.10.0' }),
    release({ version: '1.9.0' }),
  ]);
  assert.deepEqual(shown.map((r) => r.version), ['1.10.0', '1.9.0', '0.8.0']);
});

test('platforms listed for a product include any with a public release', () => {
  const product = { slug: 'player', platforms: ['windows'] };
  assert.deepEqual(Rules.platformsFor(product, [release({ platform: 'macos' }), release({ platform: 'linux', status: 'draft' })]), [
    'windows',
    'macos',
  ]);
});

test('a preparer cannot approve their own release', () => {
  const inReview = release({ status: 'in-review' });
  const labels = (role, user) => Rules.releaseSteps(inReview, role, user).map((s) => s.to);
  assert.deepEqual(labels('release_manager', 'user-a'), ['draft']);
  assert.deepEqual(labels('release_manager', 'user-b'), ['available', 'draft']);
  assert.deepEqual(labels('editor', 'user-b'), []);
});

test('formatting helpers', () => {
  assert.equal(Rules.formatDate('2026-10-06'), '6 October 2026');
  assert.equal(Rules.formatDate('2026-10-06T09:30:00+00:00'), '6 October 2026');
  assert.equal(Rules.formatBytes(512), '512 bytes');
  assert.equal(Rules.formatBytes(1572864), '1.5 MB');
  assert.equal(Rules.hostOf('https://Play.Google.com/x'), 'play.google.com');
});

const catalog = [
  { slug: 'shop', public_name: 'Shop', internal_name: 'Shop', category: 'Commerce', tagline: 'Buy things', summary: 'A marketplace.', status: 'available', platforms: ['web'], services: ['platforms'] },
  { slug: 'player', public_name: 'Audio Player', internal_name: 'LSI Player', category: 'Media', tagline: 'Listen', summary: 'Plays music.', status: 'in-development', platforms: [], services: ['platforms'] },
  { slug: 'charts', public_name: 'Charts', internal_name: 'Charts', category: 'Research', tagline: 'Analyse', summary: 'Market charts.', status: 'available', platforms: ['windows'], services: ['intelligence'] },
];
const catalogServices = [{ slug: 'platforms', name: 'Digital platforms' }, { slug: 'intelligence', name: 'Market intelligence' }];
const catalogReleases = [
  release({ product_slug: 'charts' }),
  release({ product_slug: 'shop', platform: 'web', destination_type: 'web-app', destination_url: 'https://downloads.lsi.test/' }),
];
const slugs = (state) => Rules.filterCatalog(catalog, catalogReleases, catalogServices, state).map((p) => p.slug);

test('a route splits into its path and query, and builds back', () => {
  assert.deepEqual(Rules.parseRoute('/work?q=gold%20digger&status=available'), { path: '/work', query: { q: 'gold digger', status: 'available' } });
  assert.deepEqual(Rules.parseRoute('/work/'), { path: '/work', query: {} });
  assert.deepEqual(Rules.parseRoute('/work?q=%E0%A4%A&sort=name').query, { sort: 'name' });
  assert.equal(Rules.buildRoute('/work', { q: 'gold digger', service: '', sort: 'name' }), '/work?q=gold%20digger&sort=name');
  assert.equal(Rules.buildRoute('/work', { q: '' }), '/work');
  assert.deepEqual(Rules.parseRoute(Rules.buildRoute('/work', { q: 'a&b=c?d' })).query, { q: 'a&b=c?d' });
});

test('the catalogue is searched by name, category, status, platform and service', () => {
  assert.deepEqual(slugs({}), ['shop', 'player', 'charts']);
  assert.deepEqual(slugs({ q: 'lsi player' }), ['player']);
  assert.deepEqual(slugs({ q: 'windows' }), ['charts']);
  assert.deepEqual(slugs({ q: 'market intelligence' }), ['charts']);
  assert.deepEqual(slugs({ q: 'in development' }), ['player']);
  assert.deepEqual(slugs({ q: 'web app' }), ['shop']);
  assert.deepEqual(slugs({ q: 'nothing here' }), []);
});

test('filters combine, and sorting by name does not disturb the stored order', () => {
  assert.deepEqual(slugs({ service: 'platforms' }), ['shop', 'player']);
  assert.deepEqual(slugs({ service: 'platforms', status: 'available' }), ['shop']);
  assert.deepEqual(slugs({ platform: 'windows' }), ['charts']);
  assert.deepEqual(slugs({ sort: 'name' }), ['player', 'charts', 'shop']);
  assert.deepEqual(catalog.map((p) => p.slug), ['shop', 'player', 'charts']);
  assert.equal(Rules.activeFilterCount({ q: 'x', sort: 'name', service: 'platforms', status: 'available' }), 2);
});

test('only filter values that occur are offered, and access comes from available releases', () => {
  assert.deepEqual(Rules.catalogFacets(catalog, catalogReleases), { platforms: ['web', 'windows'], statuses: ['available', 'in-development'] });
  assert.deepEqual(Rules.accessFor(catalog[2], catalogReleases), ['Windows download']);
  assert.deepEqual(Rules.accessFor(catalog[0], catalogReleases), ['Web app']);
  assert.deepEqual(Rules.accessFor(catalog[2], [release({ product_slug: 'charts', status: 'withdrawn' })]), []);
});

