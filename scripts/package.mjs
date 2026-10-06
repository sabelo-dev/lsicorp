// Assembles dist/ from a finished WebAssembly build: exactly the files to
// deploy, arranged for a CDN such as AWS Amplify Hosting (CloudFront).
//
//   - The two large files get their content hash in their names, so they can
//     be cached for a year and a new build is picked up at once.
//   - The module is also written gzip-compressed. CloudFront does not compress
//     files over 10 MB, so the page downloads this copy and unpacks it itself.
//   - config.js is written from SUPABASE_URL and SUPABASE_ANON_KEY when they
//     are set (per-branch environment variables on Amplify).
//   - robots.txt blocks indexing unless SITE_ENV is "production" (or unset,
//     for a local build).
//
//   node scripts/package.mjs [build directory]      default: build/wasm
import { createHash } from 'node:crypto';
import { copyFileSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { gzipSync } from 'node:zlib';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const build = resolve(process.argv[2] ?? join(root, 'build', 'wasm'));
const dist = join(root, 'dist');

rmSync(dist, { recursive: true, force: true });
mkdirSync(dist);

for (const file of [
  'shell.css', 'shell.js', 'qtloader.js', 'favicon.png', 'icon-192.png', 'icon-512.png',
  'apple-touch-icon.png', 'logo-mark.png', 'manifest.webmanifest',
]) {
  copyFileSync(join(build, file), join(dist, file));
}

const hashed = (name, extension, bytes) => `${name}.${createHash('sha256').update(bytes).digest('hex').slice(0, 12)}.${extension}`;

const script = readFileSync(join(build, 'lsitools.js'));
const wasm = readFileSync(join(build, 'lsitools.wasm'));
const gz = gzipSync(wasm, { level: 9 });
const scriptName = hashed('app', 'js', script);
const wasmName = hashed('app', 'wasm', wasm);
const gzName = `${wasmName}.gz`;
writeFileSync(join(dist, scriptName), script);
writeFileSync(join(dist, wasmName), wasm);
writeFileSync(join(dist, gzName), gz);

const page = readFileSync(join(build, 'index.html'), 'utf8');
const rewritten = page
  .replace('src="lsitools.js"', `src="${scriptName}"`)
  .replace('data-wasm="lsitools.wasm" data-wasm-gz=""', `data-wasm="${wasmName}" data-wasm-gz="${gzName}"`);
if (rewritten === page || !rewritten.includes(gzName)) throw new Error('index.html no longer has the file names this script rewrites');
writeFileSync(join(dist, 'index.html'), rewritten);

// A local build can keep its settings in a git-ignored .env file; real
// environment variables (as set on Amplify) take precedence.
const local = {};
try {
  for (const line of readFileSync(join(root, '.env'), 'utf8').split(/\r?\n/)) {
    const match = line.match(/^\s*([A-Z_]+)\s*=\s*"?([^"]*)"?\s*$/);
    if (match) local[match[1]] = match[2];
  }
} catch {}

const url = process.env.SUPABASE_URL ?? local.SUPABASE_URL ?? '';
const key = process.env.SUPABASE_ANON_KEY ?? local.SUPABASE_ANON_KEY ?? '';
if (/service_role/.test(Buffer.from(key.split('.')[1] ?? '', 'base64url').toString())) {
  throw new Error('SUPABASE_ANON_KEY holds a service-role key. Only the public anon key may be deployed.');
}
if (url && key) {
  writeFileSync(
    join(dist, 'config.js'),
    `// Written by scripts/package.mjs from SUPABASE_URL and SUPABASE_ANON_KEY.\nwindow.LSI_CONFIG = ${JSON.stringify({ supabaseUrl: url, supabaseKey: key }, null, 2)};\n`,
  );
} else {
  copyFileSync(join(build, 'config.js'), join(dist, 'config.js'));
}

const environment = process.env.SITE_ENV ?? 'local';
const indexable = environment === 'production' || environment === 'local';
writeFileSync(
  join(dist, 'robots.txt'),
  indexable ? 'User-agent: *\nAllow: /\n' : '# Staging and preview copies are not for search engines.\nUser-agent: *\nDisallow: /\n',
);

const mb = (bytes) => `${(bytes / 1048576).toFixed(1)} MB`;
console.log(`Site written to ${dist}`);
console.log(`  module: ${mb(wasm.length)}, ${mb(gz.length)} compressed (${gzName})`);
console.log(`  content: ${url && key ? `Supabase project ${url}` : 'bundled preview data (SUPABASE_URL and SUPABASE_ANON_KEY not set)'}`);
console.log(`  search indexing: ${indexable ? 'allowed' : 'blocked'} (SITE_ENV=${environment})`);
